import Foundation

struct SM64CameraHeightApproachResult: Equatable, Sendable {
    let y: Float
    let moving: Bool
}

struct SM64CameraWallResolution: Equatable, Sendable {
    let position: SM64ObjectVector3
    let collisionCount: Int
    let wallIDs: [UInt32]
    let collided: Bool
}

/// Owner-thread camera collision composition over immutable surface queries.
/// The world remains value-typed; this seam is where a camera tick chooses
/// whether a wall push sets the camera-collided status bit.
enum SM64CameraCollision {
    static func approachHeight(
        current: Float,
        goal: Float,
        increment: Float,
        smoothMovement: Bool
    ) -> SM64CameraHeightApproachResult? {
        guard current.isFinite, goal.isFinite, increment.isFinite,
              increment >= 0 else { return nil }
        guard smoothMovement else {
            return SM64CameraHeightApproachResult(y: goal, moving: false)
        }
        if current < goal {
            let next = min(current + increment, goal)
            return SM64CameraHeightApproachResult(y: next, moving: next != goal)
        }
        let next = max(current - increment, goal)
        return SM64CameraHeightApproachResult(y: next, moving: next != goal)
    }

    static func resolveWalls(
        position: SM64ObjectVector3,
        offsetY: Float,
        radius: Float,
        world: SM64SurfaceCollisionWorld
    ) -> SM64CameraWallResolution? {
        guard finite(position), offsetY.isFinite, radius.isFinite,
              radius >= 0 else { return nil }
        let query = world.findWallCollisions(
            SM64WallCollisionInput(
                x: position.x, y: position.y, z: position.z,
                offsetY: offsetY, radius: radius
            )
        )
        let resolved = SM64ObjectVector3(x: query.x, y: query.y, z: query.z)
        return SM64CameraWallResolution(
            position: resolved,
            collisionCount: query.totalCollisions,
            wallIDs: query.surfaceIDs,
            collided: query.totalCollisions != 0
        )
    }

    private static func finite(_ vector: SM64ObjectVector3) -> Bool {
        vector.x.isFinite && vector.y.isFinite && vector.z.isFinite
    }
}
