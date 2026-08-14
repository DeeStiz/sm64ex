import Foundation

struct SM64MarioGeometryInputResult: Equatable, Sendable {
    let position: SM64ObjectVector3
    let floor: SM64SurfaceQueryResult
    let ceiling: SM64SurfaceQueryResult
    let waterLevel: Float
    let poisonGasLevel: Float
    let flags: SM64MarioInputFlags
    let upperWall: SM64WallCollisionResult
    let lowerWall: SM64WallCollisionResult

}

/// Composes the collision domain into the geometry-derived portion of
/// `update_mario_inputs`, retaining the C fallback-to-graphics-position rule.
enum SM64MarioGeometryInput {
    static func update(
        position: SM64ObjectVector3,
        graphicsPosition: SM64ObjectVector3,
        world: SM64SurfaceCollisionWorld
    ) -> SM64MarioGeometryInputResult {
        var queryPosition = position
        var floor = world.findFloor(x: queryPosition.x, y: queryPosition.y, z: queryPosition.z)
        if floor.surfaceID == nil {
            queryPosition = graphicsPosition
            floor = world.findFloor(x: queryPosition.x, y: queryPosition.y, z: queryPosition.z)
        }

        let ceiling = world.findCeil(
            x: queryPosition.x,
            y: floor.height + 80,
            z: queryPosition.z
        )
        let waterLevel = world.findWaterLevel(x: queryPosition.x, z: queryPosition.z)
        let poisonGasLevel = world.findPoisonGasLevel(x: queryPosition.x, z: queryPosition.z)
        let upperWall = world.findWallCollisions(
            SM64WallCollisionInput(
                x: queryPosition.x,
                y: queryPosition.y,
                z: queryPosition.z,
                offsetY: 60,
                radius: 50
            )
        )
        let lowerWall = world.findWallCollisions(
            SM64WallCollisionInput(
                x: upperWall.x,
                y: queryPosition.y,
                z: upperWall.z,
                offsetY: 30,
                radius: 24
            )
        )

        var flags = SM64MarioInputFlags()
        let floorIsDynamic = (floor.flags ?? 0) & 1 != 0
        let ceilingIsDynamic = (ceiling.flags ?? 0) & 1 != 0
        let ceilingToFloorDistance = ceiling.height - floor.height
        if (floorIsDynamic || ceilingIsDynamic)
            && ceilingToFloorDistance >= 0
            && ceilingToFloorDistance <= 150 {
            flags.insert(.squished)
        }
        if queryPosition.y > floor.height + 100 { flags.insert(.offFloor) }
        if queryPosition.y < waterLevel - 10 { flags.insert(.inWater) }
        if queryPosition.y < poisonGasLevel - 100 { flags.insert(.inPoisonGas) }

        return SM64MarioGeometryInputResult(
            position: queryPosition,
            floor: floor,
            ceiling: ceiling,
            waterLevel: waterLevel,
            poisonGasLevel: poisonGasLevel,
            flags: flags,
            upperWall: upperWall,
            lowerWall: lowerWall
        )
    }
}
