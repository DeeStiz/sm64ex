import Foundation

struct SM64CameraFixedInput: Equatable, Sendable {
    let marioPosition: SM64ObjectVector3
    let cameraPosition: SM64ObjectVector3
    let basePosition: SM64ObjectVector3
    let scaleToMario: Float
    let heightOffset: Float
    let floorHeight: Float?
    let ceilingHeight: Float?
    let goalHeight: Float
    let focusFloorOffset: Float
    let smoothMovement: Bool
}

struct SM64CameraFixedResult: Equatable, Sendable {
    let focus: SM64ObjectVector3
    let position: SM64ObjectVector3
    let yaw: Int16
    let pitch: Int16
    let distance: Float
}

/// Value-only counterpart of update_fixed_camera. The owner thread supplies
/// the fixed anchor and scalar collision results; Swift owns the interpolation
/// and distance clamp without retaining any C camera or surface pointers.
enum SM64CameraFixed {
    static func update(
        _ input: SM64CameraFixedInput
    ) -> SM64CameraFixedResult? {
        guard finite(input.marioPosition), finite(input.cameraPosition),
              finite(input.basePosition), input.scaleToMario.isFinite,
              input.heightOffset.isFinite, input.goalHeight.isFinite,
              input.focusFloorOffset.isFinite,
              input.floorHeight?.isFinite ?? true,
              input.ceilingHeight?.isFinite ?? true else { return nil }

        let focus = SM64ObjectVector3(
            x: input.marioPosition.x,
            y: input.marioPosition.y + input.focusFloorOffset + 125,
            z: input.marioPosition.z
        )
        guard let currentAngles = SM64CameraPrimitives.calculateAngles(
            from: focus, to: input.cameraPosition
        ) else { return nil }

        var goalHeight: Float
        if let floorHeight = input.floorHeight {
            goalHeight = floorHeight + input.basePosition.y + input.heightOffset
        } else {
            goalHeight = input.goalHeight
        }
        if currentAngles.distance < 300 {
            goalHeight += 300 - currentAngles.distance
        }
        if let ceilingHeight = input.ceilingHeight {
            let clampedCeiling = ceilingHeight - 125
            if goalHeight > clampedCeiling {
                goalHeight = clampedCeiling
            }
        }

        let y: Float
        if input.smoothMovement {
            y = SM64CameraPrimitives.cameraApproachF32Symmetric(
                current: input.cameraPosition.y,
                target: goalHeight,
                increment: 15
            ).value
        } else {
            y = max(goalHeight, input.marioPosition.y - 500)
        }

        var position = SM64ObjectVector3(
            x: input.basePosition.x
                + (input.marioPosition.x - input.basePosition.x)
                    * input.scaleToMario,
            y: y,
            z: input.basePosition.z
                + (input.marioPosition.z - input.basePosition.z)
                    * input.scaleToMario
        )

        if input.scaleToMario != 0, currentAngles.distance > 1000,
           let clamped = setDistanceAndAngle(
                from: focus,
                distance: 1000,
                pitch: currentAngles.pitch,
                yaw: currentAngles.yaw
           ) {
            position = clamped
        }
        guard finite(position) else { return nil }
        return SM64CameraFixedResult(
            focus: focus,
            position: position,
            yaw: currentAngles.yaw,
            pitch: currentAngles.pitch,
            distance: currentAngles.distance
        )
    }

    private static func setDistanceAndAngle(
        from: SM64ObjectVector3,
        distance: Float,
        pitch: Int16,
        yaw: Int16
    ) -> SM64ObjectVector3? {
        guard distance.isFinite, finite(from) else { return nil }
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
