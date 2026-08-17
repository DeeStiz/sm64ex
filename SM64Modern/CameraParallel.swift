import Foundation

struct SM64CameraParallelInput: Equatable, Sendable {
    let marioPosition: SM64ObjectVector3
    let cameraPosition: SM64ObjectVector3
    let pathStart: SM64ObjectVector3
    let pathEnd: SM64ObjectVector3
    let distanceThreshold: Float
    let zoom: Float
    let marioFloorOffset: Float
    let transitionOffset: SM64ObjectVector3
}

struct SM64CameraParallelResult: Equatable, Sendable {
    let focus: SM64ObjectVector3
    let position: SM64ObjectVector3
    let yaw: Int16
}

/// Stable-segment value kernel for parallel-tracking camera mode 12. The C
/// adapter supplies a bounded path segment and immutable floor/transition
/// facts; path-index switching remains an explicit C fallback until its
/// complete path-window contract is promoted.
enum SM64CameraParallel {
    static func update(
        _ input: SM64CameraParallelInput
    ) -> SM64CameraParallelResult? {
        guard finite(input.marioPosition), finite(input.cameraPosition),
              finite(input.pathStart), finite(input.pathEnd),
              finite(input.transitionOffset), input.distanceThreshold.isFinite,
              input.zoom.isFinite, input.marioFloorOffset.isFinite else {
            return nil
        }
        guard let pathAngles = SM64CameraPrimitives.calculateAngles(
            from: input.pathStart, to: input.pathEnd
        ) else { return nil }

        let midpoint = SM64ObjectVector3(
            x: input.pathStart.x + (input.pathEnd.x - input.pathStart.x) * 0.5,
            y: input.pathStart.y + (input.pathEnd.y - input.pathStart.y) * 0.5,
            z: input.pathStart.z + (input.pathEnd.z - input.pathStart.z) * 0.5
        )
        let marioPosition = SM64ObjectVector3(
            x: input.marioPosition.x,
            y: input.marioPosition.y + 150 + input.marioFloorOffset,
            z: input.marioPosition.z
        )
        var marioOffset = subtract(marioPosition, midpoint)
        var cameraOffset = subtract(input.cameraPosition, midpoint)
        guard let rotatedMario = rotateToPath(
            marioOffset, pitch: pathAngles.pitch, yaw: pathAngles.yaw
        ), let rotatedCamera = rotateToPath(
            cameraOffset, pitch: pathAngles.pitch, yaw: pathAngles.yaw
        ) else { return nil }
        marioOffset = rotatedMario
        cameraOffset = rotatedCamera

        if marioOffset.z > cameraOffset.z {
            if marioOffset.z - cameraOffset.z > input.distanceThreshold {
                cameraOffset.z = marioOffset.z - input.distanceThreshold
            }
        } else if marioOffset.z - cameraOffset.z < -input.distanceThreshold {
            cameraOffset.z = marioOffset.z + input.distanceThreshold
        }

        marioOffset.x = -marioOffset.x * input.zoom
        marioOffset.y *= input.zoom
        marioOffset.z = cameraOffset.z
        marioOffset.z = pathAngles.distance / 2 - marioOffset.z

        var position = offsetRotated(
            from: input.pathStart,
            offset: marioOffset,
            pitch: pathAngles.pitch,
            yaw: pathAngles.yaw &+ Int16(bitPattern: 0x8000)
        )
        position = add(position, input.transitionOffset)
        let focus = marioPosition
        guard let resultAngles = SM64CameraPrimitives.calculateAngles(
            from: focus, to: position
        ), finite(position) else { return nil }
        return SM64CameraParallelResult(
            focus: focus, position: position, yaw: resultAngles.yaw
        )
    }

    private static func subtract(
        _ lhs: SM64ObjectVector3, _ rhs: SM64ObjectVector3
    ) -> SM64ObjectVector3 {
        SM64ObjectVector3(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }

    private static func add(
        _ lhs: SM64ObjectVector3, _ rhs: SM64ObjectVector3
    ) -> SM64ObjectVector3 {
        SM64ObjectVector3(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }

    private static func rotateToPath(
        _ vector: SM64ObjectVector3, pitch: Int16, yaw: Int16
    ) -> SM64ObjectVector3? {
        guard let yawRotated = rotateInXZ(vector, yaw: -yaw) else { return nil }
        return rotateInYZ(yawRotated, pitch: -pitch)
    }

    private static func rotateInXZ(
        _ vector: SM64ObjectVector3, yaw: Int16
    ) -> SM64ObjectVector3? {
        guard finite(vector) else { return nil }
        return SM64ObjectVector3(
            x: vector.z * SM64CanonicalTrig.sins(yaw)
                + vector.x * SM64CanonicalTrig.coss(yaw),
            y: vector.y,
            z: vector.z * SM64CanonicalTrig.coss(yaw)
                - vector.x * SM64CanonicalTrig.sins(yaw)
        )
    }

    private static func rotateInYZ(
        _ vector: SM64ObjectVector3, pitch: Int16
    ) -> SM64ObjectVector3 {
        SM64ObjectVector3(
            x: vector.x,
            y: vector.z * SM64CanonicalTrig.sins(pitch)
                + vector.y * SM64CanonicalTrig.coss(pitch),
            z: -(vector.z * SM64CanonicalTrig.coss(pitch)
                - vector.y * SM64CanonicalTrig.sins(pitch))
        )
    }

    private static func offsetRotated(
        from: SM64ObjectVector3,
        offset: SM64ObjectVector3,
        pitch: Int16,
        yaw: Int16
    ) -> SM64ObjectVector3 {
        let pitchRotated = rotateInYZ(offset, pitch: pitch)
        return SM64ObjectVector3(
            x: from.x + pitchRotated.z * SM64CanonicalTrig.sins(yaw)
                + pitchRotated.x * SM64CanonicalTrig.coss(yaw),
            y: from.y + pitchRotated.y,
            z: from.z + pitchRotated.z * SM64CanonicalTrig.coss(yaw)
                - pitchRotated.x * SM64CanonicalTrig.sins(yaw)
        )
    }

    private static func finite(_ vector: SM64ObjectVector3) -> Bool {
        vector.x.isFinite && vector.y.isFinite && vector.z.isFinite
    }
}
