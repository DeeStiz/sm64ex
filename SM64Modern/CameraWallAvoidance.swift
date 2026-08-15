import Foundation

struct SM64CameraWallAvoidanceInput: Equatable, Sendable {
    let marioPosition: SM64ObjectVector3
    let cameraPosition: SM64ObjectVector3
    let avoidYaw: Int16
    let yawRange: Int16
    let statusFlags: UInt16
    let world: SM64SurfaceCollisionWorld
}

struct SM64CameraWallAvoidanceResult: Equatable, Sendable {
    let status: Int16
    let avoidYaw: Int16
    let statusFlags: UInt16
    let checkedSteps: Int16
    let coarseRadius: Float
    let fineRadius: Float
    let lastCoarseWallID: UInt32?
    let lastFineWallID: UInt32?
}

/// Value counterpart of rotate_camera_around_walls and its geometry helpers.
/// Collision queries are performed against an immutable world; the owner
/// thread applies the resulting camera status and yaw intent.
enum SM64CameraWallAvoidance {
    static let nearWallFlag: UInt16 = 0x0020
    static let wallMiscType: Int16 = 0x0028

    static func calculateAvoidYaw(
        yawFromMario: Int16, wallYaw: Int16
    ) -> Int16 {
        let yawDiff = Int32(wallYaw) - Int32(yawFromMario) + 0x4000
        let value = yawDiff < 0
            ? Int32(wallYaw)
            : Int32(wallYaw) + 0x8000
        return Int16(truncatingIfNeeded: value)
    }

    static func rotate(
        _ input: SM64CameraWallAvoidanceInput
    ) -> SM64CameraWallAvoidanceResult? {
        guard finite(input.marioPosition), finite(input.cameraPosition),
              input.yawRange >= 0 else { return nil }
        guard let angles = SM64CameraPrimitives.calculateAngles(
            from: input.marioPosition, to: input.cameraPosition
        ) else { return nil }

        var statusFlags = input.statusFlags & ~nearWallFlag
        var status: Int16 = 0
        var avoidYaw = input.avoidYaw
        var coarseRadius: Float = 150
        var fineRadius: Float = 100
        var lastCoarseWallID: UInt32?
        var lastFineWallID: UInt32?
        var checkedSteps: Int16 = 0

        for step in 0..<8 {
            checkedSteps &+= 1
            let checkDistance = Float(step) * 0.125
            let checkPosition = SM64ObjectVector3(
                x: input.marioPosition.x
                    + (input.cameraPosition.x - input.marioPosition.x) * checkDistance,
                y: input.marioPosition.y
                    + (input.cameraPosition.y - input.marioPosition.y) * checkDistance,
                z: input.marioPosition.z
                    + (input.cameraPosition.z - input.marioPosition.z) * checkDistance
            )
            let coarse = input.world.findWallCollisions(
                SM64WallCollisionInput(
                    x: checkPosition.x, y: checkPosition.y, z: checkPosition.z,
                    offsetY: 100, radius: coarseRadius
                )
            )
            coarseRadius = SM64CameraPrimitives.cameraApproachF32Symmetric(
                current: coarseRadius, target: 250, increment: 30
            ).value

            guard coarse.totalCollisions != 0 else { continue }
            lastCoarseWallID = coarse.surfaceIDs.last
            guard let coarseWall = surface(
                id: lastCoarseWallID, world: input.world
            ) else { continue }

            if step >= 5 {
                statusFlags |= nearWallFlag
                if status <= 0 {
                    status = 1
                    let wallYaw = wallYaw(for: coarseWall)
                    avoidYaw = Int16(
                        truncatingIfNeeded: Int32(calculateAvoidYaw(
                            yawFromMario: angles.yaw, wallYaw: wallYaw
                        )) + 0x8000
                    )
                }
            }

            let fine = input.world.findWallCollisions(
                SM64WallCollisionInput(
                    x: checkPosition.x, y: checkPosition.y, z: checkPosition.z,
                    offsetY: 100, radius: fineRadius
                )
            )
            fineRadius = SM64CameraPrimitives.cameraApproachF32Symmetric(
                current: fineRadius, target: 200, increment: 20
            ).value
            guard fine.totalCollisions != 0 else { continue }
            lastFineWallID = fine.surfaceIDs.last
            guard let fineWall = surface(id: lastFineWallID, world: input.world) else {
                continue
            }

            let wallYaw = wallYaw(for: fineWall)
            let rangeBehind = isRangeBehindSurface(
                from: input.marioPosition,
                to: input.cameraPosition,
                surface: fineWall,
                range: input.yawRange
            )
            if !rangeBehind,
               isBehindSurface(input.marioPosition, surface: fineWall),
               !isSurfaceWithinBoundingBox(
                    fineWall, xMax: -1, yMax: 150, zMax: -1
               ) {
                let rawAvoid = calculateAvoidYaw(
                    yawFromMario: angles.yaw, wallYaw: wallYaw
                )
                let target = Int16(truncatingIfNeeded: Int32(rawAvoid) + 0x8000)
                avoidYaw = SM64CameraPrimitives.cameraApproachS16Symmetric(
                    current: target, target: wallYaw, increment: input.yawRange
                ).value
                status = 3
                break
            }
        }

        return SM64CameraWallAvoidanceResult(
            status: status, avoidYaw: avoidYaw, statusFlags: statusFlags,
            checkedSteps: checkedSteps, coarseRadius: coarseRadius,
            fineRadius: fineRadius, lastCoarseWallID: lastCoarseWallID,
            lastFineWallID: lastFineWallID
        )
    }

    static func isBehindSurface(
        _ position: SM64ObjectVector3, surface: SM64Surface
    ) -> Bool {
        let v1 = surface.vertex1
        let v2 = surface.vertex2
        let v3 = surface.vertex3
        let normX = Float(v2.y - v1.y) * Float(v3.z - v2.z)
            - Float(v3.y - v2.y) * Float(v2.z - v1.z)
        let normY = Float(v2.z - v1.z) * Float(v3.x - v2.x)
            - Float(v3.z - v2.z) * Float(v2.x - v1.x)
        let normZ = Float(v2.x - v1.x) * Float(v3.y - v2.y)
            - Float(v3.x - v2.x) * Float(v2.y - v1.y)
        let dirX = Float(v1.x) - position.x
        let dirY = Float(v1.y) - position.y
        let dirZ = Float(v1.z) - position.z
        return dirX * normX + dirY * normY + dirZ * normZ < 0
    }

    static func isRangeBehindSurface(
        from: SM64ObjectVector3,
        to: SM64ObjectVector3,
        surface: SM64Surface?,
        range: Int16
    ) -> Bool {
        guard let surface, surface.type != wallMiscType else { return true }
        if range == 0 {
            return isBehindSurface(to, surface: surface)
        }
        guard let angles = SM64CameraPrimitives.calculateAngles(from: from, to: to),
              let left = setDistanceAndAngle(
                from: from, distance: angles.distance, pitch: angles.pitch,
                yaw: angles.yaw &+ range
              ),
              let right = setDistanceAndAngle(
                from: from, distance: angles.distance, pitch: angles.pitch,
                yaw: angles.yaw &- range
              ) else { return true }
        return isBehindSurface(left, surface: surface)
            && isBehindSurface(right, surface: surface)
    }

    static func isSurfaceWithinBoundingBox(
        _ surface: SM64Surface, xMax: Float, yMax: Float, zMax: Float
    ) -> Bool {
        let vertices = [surface.vertex1, surface.vertex2, surface.vertex3]
        var dxMax: Float = 0
        var dyMax: Float = 0
        var dzMax: Float = 0
        for index in 0..<3 {
            let next = (index + 1) % 3
            dxMax = max(dxMax, abs(Float(vertices[index].x - vertices[next].x)))
            dyMax = max(dyMax, abs(Float(vertices[index].y - vertices[next].y)))
            dzMax = max(dzMax, abs(Float(vertices[index].z - vertices[next].z)))
        }
        if yMax != -1, dyMax < yMax { return true }
        if xMax != -1, zMax != -1, dxMax < xMax, dzMax < zMax { return true }
        return false
    }

    private static func wallYaw(for surface: SM64Surface) -> Int16 {
        SM64CanonicalTrig.atan2s(
            y: surface.normal.z, x: surface.normal.x
        ) &+ 0x4000
    }

    private static func surface(
        id: UInt32?, world: SM64SurfaceCollisionWorld
    ) -> SM64Surface? {
        guard let id else { return nil }
        return (world.dynamicSurfaces + world.staticSurfaces).first { $0.id == id }
    }

    private static func setDistanceAndAngle(
        from: SM64ObjectVector3, distance: Float, pitch: Int16, yaw: Int16
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
