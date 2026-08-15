import Foundation

struct SM64CameraHeightInput: Equatable, Sendable {
    let marioY: Float
    let floorHeight: Float
    let waterHeight: Float?
    let isMetalWater: Bool
    let isOnPole: Bool
    let poleObjectY: Float?
    let poleObjectHitboxHeight: Float?
}

struct SM64CameraHeightOffsets: Equatable, Sendable {
    let position: Float
    let focus: Float
}

struct SM64CameraFocusPlacement: Equatable, Sendable {
    let focus: SM64ObjectVector3
    let position: SM64ObjectVector3
}

struct SM64CameraSlopeInput: Equatable, Sendable {
    let marioY: Float
    let floorHeight: Float?
    let floorType: Int16
    let floorNormalZ: Float
}

struct SM64CameraRadialInput: Equatable, Sendable {
    let marioPosition: SM64ObjectVector3
    let areaCenter: SM64ObjectVector3
    let modeOffsetYaw: Int16
    let lakituPitch: Int16
    let lakituDistance: Int16
    let height: SM64CameraHeightInput
    let slope: SM64CameraSlopeInput
}

struct SM64CameraRadialPlacement: Equatable, Sendable {
    let focus: SM64ObjectVector3
    let position: SM64ObjectVector3
    let cameraYaw: Int16
    let areaYaw: Int16
    let pitch: Int16
    let offsets: SM64CameraHeightOffsets
}

/// Pure geometry kernels shared by radial, eight-direction, and later camera
/// modes. Surface queries and owner-thread camera mutation are represented by
/// immutable snapshots at this boundary.
enum SM64CameraGeometry {
    static let wallMiscSurfaceType: Int16 = 0x0028

    static func calculateHeightOffsets(
        _ input: SM64CameraHeightInput,
        positionMultiplier: Float = 1,
        positionBound: Float = 200,
        focusMultiplier: Float = 0.9,
        focusBound: Float = 200
    ) -> SM64CameraHeightOffsets? {
        guard input.marioY.isFinite, input.floorHeight.isFinite,
              positionMultiplier.isFinite, positionBound.isFinite,
              focusMultiplier.isFinite, focusBound.isFinite,
              positionBound >= 0, focusBound >= 0 else { return nil }
        if let waterHeight = input.waterHeight, !waterHeight.isFinite { return nil }
        if let poleY = input.poleObjectY, !poleY.isFinite { return nil }
        if let hitbox = input.poleObjectHitboxHeight, !hitbox.isFinite { return nil }

        var floorHeight = input.floorHeight
        if !input.isMetalWater, let waterHeight = input.waterHeight {
            floorHeight = max(floorHeight, waterHeight)
        }

        var effectivePositionBound = positionBound
        if input.isOnPole,
           let poleY = input.poleObjectY,
           let hitbox = input.poleObjectHitboxHeight,
           input.floorHeight >= poleY,
           input.marioY < 0.7 * hitbox + poleY {
            effectivePositionBound = 1200
        }

        let position = clamp(
            (floorHeight - input.marioY) * positionMultiplier,
            bound: effectivePositionBound
        )
        let focus = clamp(
            (floorHeight - input.marioY) * focusMultiplier,
            bound: focusBound
        )
        return SM64CameraHeightOffsets(position: position, focus: focus)
    }

    static func focusOnMario(
        marioPosition: SM64ObjectVector3,
        positionYOffset: Float,
        focusYOffset: Float,
        distance: Float,
        pitch: Int16,
        yaw: Int16,
        lakituPitch: Int16 = 0
    ) -> SM64CameraFocusPlacement? {
        guard finite(marioPosition), positionYOffset.isFinite,
              focusYOffset.isFinite, distance.isFinite else { return nil }
        let origin = SM64ObjectVector3(
            x: marioPosition.x,
            y: marioPosition.y + positionYOffset,
            z: marioPosition.z
        )
        let combinedPitch = pitch &+ lakituPitch
        let cosinePitch = SM64CanonicalTrig.coss(combinedPitch)
        let position = SM64ObjectVector3(
            x: origin.x + distance * cosinePitch * SM64CanonicalTrig.sins(yaw),
            y: origin.y + distance * SM64CanonicalTrig.sins(combinedPitch),
            z: origin.z + distance * cosinePitch * SM64CanonicalTrig.coss(yaw)
        )
        let focus = SM64ObjectVector3(
            x: marioPosition.x,
            y: marioPosition.y + focusYOffset,
            z: marioPosition.z
        )
        guard finite(position), finite(focus) else { return nil }
        return SM64CameraFocusPlacement(focus: focus, position: position)
    }

    static func lookDownSlopes(_ input: SM64CameraSlopeInput) -> Int16? {
        guard input.marioY.isFinite, input.floorHeight?.isFinite ?? true,
              input.floorNormalZ.isFinite else { return nil }
        var pitch: Int16 = 0x05B0
        guard let floorHeight = input.floorHeight else { return pitch }
        let floorDelta = floorHeight - input.marioY
        if input.floorType != Self.wallMiscSurfaceType && floorDelta > 0 {
            if input.floorNormalZ != 0 || floorDelta >= 100 {
                pitch = pitch &+ SM64CanonicalTrig.atan2s(y: 40, x: floorDelta)
            }
        }
        return pitch
    }

    static func updateRadial(
        _ input: SM64CameraRadialInput
    ) -> SM64CameraRadialPlacement? {
        guard finite(input.marioPosition), finite(input.areaCenter) else { return nil }
        let centerX = input.marioPosition.x - input.areaCenter.x
        let centerZ = input.marioPosition.z - input.areaCenter.z
        let cameraYaw = SM64CanonicalTrig.atan2s(y: centerZ, x: centerX) &+ input.modeOffsetYaw
        guard let pitch = lookDownSlopes(input.slope),
              let offsets = calculateHeightOffsets(input.height) else { return nil }
        let distance = Float(input.lakituDistance) + 1000
        return focusOnMario(
            marioPosition: input.marioPosition,
            positionYOffset: offsets.position + 125,
            focusYOffset: offsets.focus + 125,
            distance: distance,
            pitch: pitch,
            yaw: cameraYaw,
            lakituPitch: input.lakituPitch
        ).map {
            SM64CameraRadialPlacement(
                focus: $0.focus,
                position: $0.position,
                cameraYaw: cameraYaw,
                areaYaw: cameraYaw &- input.modeOffsetYaw,
                pitch: pitch,
                offsets: offsets
            )
        }
    }

    private static func clamp(_ value: Float, bound: Float) -> Float {
        min(max(value, -bound), bound)
    }

    private static func finite(_ vector: SM64ObjectVector3) -> Bool {
        vector.x.isFinite && vector.y.isFinite && vector.z.isFinite
    }
}
