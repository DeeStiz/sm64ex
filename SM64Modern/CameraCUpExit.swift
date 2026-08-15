import Foundation

struct SM64CameraCUpExitInput: Equatable, Sendable {
    let state: SM64CameraCUpState
    let lastMode: Int16
    let marioPosition: SM64ObjectVector3
    let cameraPosition: SM64ObjectVector3
    let cameraFocus: SM64ObjectVector3
    let zoomDistance: Float
    let world: SM64SurfaceCollisionWorld
}

struct SM64CameraCUpExitResult: Equatable, Sendable {
    let state: SM64CameraCUpState
    let usedSearch: Bool
    let foundOpening: Bool
    let selectedYaw: Int16
    let transitionFrames: Int16
    let soundRequested: Bool
}

/// Value counterpart of `exit_c_up`. The owner thread supplies an immutable
/// collision snapshot and applies the resulting mode flags, transition, and
/// audio intent. Search order and the intentionally asymmetric C-sector walk
/// are retained exactly.
enum SM64CameraCUpExit {
    static let transitionFrames: Int16 = 15
    static let searchModes: Set<Int16> = [
        SM64CameraMode.close.rawValue,
        SM64CameraMode.freeRoam.rawValue,
        SM64CameraMode.spiralStairs.rawValue
    ]

    static func update(_ input: SM64CameraCUpExitInput) -> SM64CameraCUpExitResult? {
        guard input.zoomDistance.isFinite, input.zoomDistance >= 80,
              finite(input.marioPosition), finite(input.cameraPosition),
              finite(input.cameraFocus) else { return nil }
        guard input.state.active, !input.state.startedExiting else {
            return SM64CameraCUpExitResult(
                state: input.state, usedSearch: false, foundOpening: false,
                selectedYaw: 0, transitionFrames: 0, soundRequested: false
            )
        }

        let checkFocus = SM64ObjectVector3(
            x: input.marioPosition.x,
            y: input.cameraFocus.y,
            z: input.marioPosition.z
        )
        guard let angles = SM64CameraPrimitives.calculateAngles(
            from: checkFocus, to: input.cameraPosition
        ) else { return nil }

        guard searchModes.contains(input.lastMode) else {
            var state = input.state
            state = SM64CameraCUpState(
                active: false, startedExiting: false,
                pitch: state.pitch, modeOffsetYaw: state.modeOffsetYaw,
                headPitch: state.headPitch, headYaw: state.headYaw,
                storedPosition: state.storedPosition,
                storedFocusOffsetY: state.storedFocusOffsetY
            )
            return SM64CameraCUpExitResult(
                state: state, usedSearch: false, foundOpening: false,
                selectedYaw: 0, transitionFrames: 0, soundRequested: true
            )
        }

        var checkYaw: Int16 = 0
        var foundOpening = false
        for _ in 0..<16 {
            if isOpening(
                focus: checkFocus,
                yaw: angles.yaw &+ checkYaw,
                zoomDistance: input.zoomDistance,
                world: input.world
            ) {
                foundOpening = true
                break
            }
            // This is the source's alternating-sector update, including its
            // first zero step and the resulting 0, +1, -2, +3 ... sequence.
            checkYaw = -checkYaw
            if checkYaw < 0 {
                checkYaw &-= 0x1000
            } else {
                checkYaw &+= 0x1000
            }
        }

        var state = input.state
        if foundOpening,
           let selected = setDistanceAndAngle(
                from: checkFocus,
                distance: input.zoomDistance,
                pitch: 0,
                yaw: angles.yaw &+ checkYaw
           ) {
            state = SM64CameraCUpState(
                active: state.active, startedExiting: true,
                pitch: state.pitch, modeOffsetYaw: state.modeOffsetYaw,
                headPitch: state.headPitch, headYaw: state.headYaw,
                storedPosition: SM64ObjectVector3(
                    x: selected.x - input.marioPosition.x,
                    y: selected.y - input.marioPosition.y,
                    z: selected.z - input.marioPosition.z
                ),
                storedFocusOffsetY: checkFocus.y - input.marioPosition.y
            )
        } else {
            state = SM64CameraCUpState(
                active: state.active, startedExiting: true,
                pitch: state.pitch, modeOffsetYaw: state.modeOffsetYaw,
                headPitch: state.headPitch, headYaw: state.headYaw,
                storedPosition: state.storedPosition,
                storedFocusOffsetY: state.storedFocusOffsetY
            )
        }
        return SM64CameraCUpExitResult(
            state: state, usedSearch: true, foundOpening: foundOpening,
            selectedYaw: checkYaw, transitionFrames: transitionFrames,
            soundRequested: true
        )
    }

    private static func isOpening(
        focus: SM64ObjectVector3,
        yaw: Int16,
        zoomDistance: Float,
        world: SM64SurfaceCollisionWorld
    ) -> Bool {
        guard var position = setDistanceAndAngle(
            from: focus, distance: 80, pitch: 0, yaw: yaw
        ) else { return false }
        var distance: Float = 80
        while distance < zoomDistance {
            guard let next = setDistanceAndAngle(
                from: focus, distance: distance, pitch: 0, yaw: yaw
            ) else { return false }
            position = next
            let ceiling = world.findCeil(
                x: position.x, y: position.y - 150, z: position.z
            )
            if ceiling.surfaceID != nil, ceiling.height - 10 < position.y {
                return false
            }
            let floor = world.findFloor(
                x: position.x, y: position.y + 150, z: position.z
            )
            if floor.surfaceID != nil, floor.height + 10 > position.y {
                return false
            }
            if world.findWallCollisions(
                SM64WallCollisionInput(
                    x: position.x, y: position.y, z: position.z,
                    offsetY: 20, radius: 50
                )
            ).totalCollisions != 0 {
                return false
            }
            distance += 20
        }
        return distance >= zoomDistance
    }

    private static func setDistanceAndAngle(
        from: SM64ObjectVector3,
        distance: Float,
        pitch: Int16,
        yaw: Int16
    ) -> SM64ObjectVector3? {
        guard distance.isFinite, distance >= 0, finite(from) else { return nil }
        let cosinePitch = SM64CanonicalTrig.coss(pitch)
        return SM64ObjectVector3(
            x: from.x + distance * cosinePitch * SM64CanonicalTrig.sins(yaw),
            y: from.y + distance * SM64CanonicalTrig.sins(pitch),
            z: from.z + distance * cosinePitch * SM64CanonicalTrig.coss(yaw)
        )
    }

    private static func finite(_ vector: SM64ObjectVector3) -> Bool {
        vector.x.isFinite && vector.y.isFinite && vector.z.isFinite
    }
}
