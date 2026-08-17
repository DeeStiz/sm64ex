import Foundation

struct SM64CameraBossInput: Equatable, Sendable {
    let marioPosition: SM64ObjectVector3
    let secondFocus: SM64ObjectVector3
    let focusDistance: Float
    let yaw: Int16
    let heldState: Int16
    let angleVelocity: Float
    let floorHeight: Float?
    let forceHeight: Bool
    let lakituDistance: Float
    let lakituPitch: Int16
}

struct SM64CameraBossResult: Equatable, Sendable {
    let focus: SM64ObjectVector3
    let position: SM64ObjectVector3
    let yaw: Int16
    let distance: Float
}

/// Value-only counterpart of the Bowser/boss camera callback. C supplies the
/// object and floor-query snapshots; Swift owns the focus blend, arena-height
/// placement, and Lakitu zoom offset.
enum SM64CameraBoss {
    static func update(
        _ input: SM64CameraBossInput
    ) -> SM64CameraBossResult? {
        guard finite(input.marioPosition), finite(input.secondFocus),
              input.focusDistance.isFinite, input.focusDistance >= 0,
              input.angleVelocity.isFinite,
              input.floorHeight?.isFinite ?? true,
              input.lakituDistance.isFinite else { return nil }

        var focus = SM64ObjectVector3(
            x: (input.marioPosition.x + input.secondFocus.x) / 2,
            y: (input.marioPosition.y + input.secondFocus.y) / 2 + 100,
            z: (input.marioPosition.z + input.secondFocus.z) / 2
        )
        if input.heldState == 1 {
            let rawVelocity = Int32(input.angleVelocity.rounded(.towardZero))
            let magnitude = Int16(truncatingIfNeeded: abs(rawVelocity))
            focus.y += 300 * SM64CanonicalTrig.sins(magnitude)
        }

        var position = setDistanceAndAngle(
            from: focus,
            distance: input.focusDistance,
            pitch: 0x1000,
            yaw: input.yaw
        )
        if let floorHeight = input.floorHeight {
            position.y = floorHeight
        }
        if input.forceHeight {
            position.y = 2047
        }

        let zoomPitch = input.lakituPitch &+ 0x1000
        let cosinePitch = SM64CanonicalTrig.coss(zoomPitch)
        position = SM64ObjectVector3(
            x: position.x
                + input.lakituDistance * cosinePitch
                    * SM64CanonicalTrig.sins(input.yaw),
            y: position.y
                + input.lakituDistance * SM64CanonicalTrig.sins(zoomPitch),
            z: position.z
                + input.lakituDistance * cosinePitch
                    * SM64CanonicalTrig.coss(input.yaw)
        )
        guard finite(focus), finite(position) else { return nil }
        return SM64CameraBossResult(
            focus: focus,
            position: position,
            yaw: input.yaw,
            distance: input.focusDistance
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

    private static func finite(_ vector: SM64ObjectVector3) -> Bool {
        vector.x.isFinite && vector.y.isFinite && vector.z.isFinite
    }
}
