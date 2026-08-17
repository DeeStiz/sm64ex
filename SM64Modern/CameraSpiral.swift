import Foundation

struct SM64CameraSpiralInput: Equatable, Sendable {
    let marioPosition: SM64ObjectVector3
    let cameraPosition: SM64ObjectVector3
    let cameraFocus: SM64ObjectVector3
    let basePosition: SM64ObjectVector3
    let focusFloorOffset: Float
    let floorHeight: Float?
    let currentFloorHeight: Float
}

struct SM64CameraSpiralResult: Equatable, Sendable {
    let focus: SM64ObjectVector3
    let position: SM64ObjectVector3
    let yaw: Int16
    let yawOffset: Int16
}

/// Value-only counterpart of the castle spiral-stairs camera. C provides the
/// immutable floor-query result; Swift owns the staircase-relative angle,
/// camera height approach, focus approach, and returned yaw.
enum SM64CameraSpiral {
    static func update(
        _ input: SM64CameraSpiralInput
    ) -> SM64CameraSpiralResult? {
        guard finite(input.marioPosition), finite(input.cameraPosition),
              finite(input.cameraFocus), finite(input.basePosition),
              input.focusFloorOffset.isFinite,
              input.floorHeight?.isFinite ?? true,
              input.currentFloorHeight.isFinite else { return nil }

        let workingFocus = SM64ObjectVector3(
            x: input.marioPosition.x,
            y: input.cameraFocus.y,
            z: input.marioPosition.z
        )
        guard let focusAngles = SM64CameraPrimitives.calculateAngles(
            from: input.basePosition, to: workingFocus
        ), let cameraAngles = SM64CameraPrimitives.calculateAngles(
            from: input.basePosition, to: input.cameraPosition
        ) else { return nil }

        var yawOffset = cameraAngles.yaw &- focusAngles.yaw
        yawOffset = min(max(yawOffset, -0x4000), 0x4000)
        let staircaseYaw = focusAngles.yaw &+ yawOffset
        let staircasePosition = setDistanceAndAngle(
            from: input.basePosition,
            distance: 300,
            pitch: 0,
            yaw: staircaseYaw
        )

        var positionY = input.cameraPosition.y
        if let floorHeight = input.floorHeight {
            let targetFloor = max(floorHeight, input.currentFloorHeight) + 125
            positionY = approach(
                current: positionY, target: targetFloor,
                increment: 30
            )
        }
        let focusTargetY = input.marioPosition.y + 125
            + input.focusFloorOffset
        let focusY = SM64CameraPrimitives.cameraApproachF32Symmetric(
            current: input.cameraFocus.y,
            target: focusTargetY,
            increment: 30
        ).value
        let focus = SM64ObjectVector3(
            x: input.marioPosition.x,
            y: focusY,
            z: input.marioPosition.z
        )
        let position = SM64ObjectVector3(
            x: staircasePosition.x,
            y: positionY,
            z: staircasePosition.z
        )
        guard let returnedAngles = SM64CameraPrimitives.calculateAngles(
            from: focus, to: position
        ), finite(focus), finite(position) else { return nil }
        return SM64CameraSpiralResult(
            focus: focus,
            position: position,
            yaw: returnedAngles.yaw,
            yawOffset: yawOffset
        )
    }

    private static func setDistanceAndAngle(
        from: SM64ObjectVector3,
        distance: Float,
        pitch: Int16,
        yaw: Int16
    ) -> SM64ObjectVector3 {
        let cosinePitch = SM64CanonicalTrig.coss(pitch)
        return SM64ObjectVector3(
            x: from.x + distance * cosinePitch * SM64CanonicalTrig.sins(yaw),
            y: from.y + distance * SM64CanonicalTrig.sins(pitch),
            z: from.z + distance * cosinePitch * SM64CanonicalTrig.coss(yaw)
        )
    }

    private static func approach(
        current: Float, target: Float, increment: Float
    ) -> Float {
        if current < target {
            return min(current + increment, target)
        }
        return max(current - increment, target)
    }

    private static func finite(_ vector: SM64ObjectVector3) -> Bool {
        vector.x.isFinite && vector.y.isFinite && vector.z.isFinite
    }
}
