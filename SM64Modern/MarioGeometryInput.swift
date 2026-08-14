import Foundation

struct SM64MarioGeometryInputResult: Equatable, Sendable {
    let position: SM64ObjectVector3
    let floor: SM64SurfaceQueryResult
    let ceiling: SM64SurfaceQueryResult
    let floorAngle: Int16
    let floorClass: Int16
    let terrainSoundAddend: UInt32
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
        world: SM64SurfaceCollisionWorld,
        terrainType: UInt16 = 0,
        isLavaLevel: Bool = false,
        isCrawling: Bool = false
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

        let floorAngle: Int16
        let floorClass: Int16
        let terrainSoundAddend: UInt32
        let slippery: Bool
        if let normalX = floor.normalX, let normalY = floor.normalY, let normalZ = floor.normalZ {
            floorAngle = SM64CanonicalTrig.atan2s(y: normalZ, x: normalX)
            floorClass = Self.floorClass(
                surfaceType: floor.type ?? 0,
                terrainType: terrainType,
                normalY: normalY,
                isCrawling: isCrawling
            )
            terrainSoundAddend = Self.terrainSoundAddend(
                surfaceType: floor.type ?? 0,
                floorHeight: floor.height,
                waterLevel: waterLevel,
                terrainType: terrainType,
                isLavaLevel: isLavaLevel
            )
            slippery = Self.isSlippery(
                floorClass: floorClass,
                terrainType: terrainType,
                normalY: normalY
            )
        } else {
            floorAngle = 0
            floorClass = Self.surfaceClassDefault
            terrainSoundAddend = 0
            slippery = false
        }

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
        if queryPosition.y > waterLevel - 40 && slippery { flags.insert(.aboveSlide) }
        if queryPosition.y < waterLevel - 10 { flags.insert(.inWater) }
        if queryPosition.y < poisonGasLevel - 100 { flags.insert(.inPoisonGas) }

        return SM64MarioGeometryInputResult(
            position: queryPosition,
            floor: floor,
            ceiling: ceiling,
            floorAngle: floorAngle,
            floorClass: floorClass,
            terrainSoundAddend: terrainSoundAddend,
            waterLevel: waterLevel,
            poisonGasLevel: poisonGasLevel,
            flags: flags,
            upperWall: upperWall,
            lowerWall: lowerWall
        )
    }

    private static let surfaceClassDefault: Int16 = 0x0000
    private static let surfaceClassVerySlippery: Int16 = 0x0013
    private static let surfaceClassSlippery: Int16 = 0x0014
    private static let surfaceClassNotSlippery: Int16 = 0x0015

    private static func floorClass(
        surfaceType: Int16,
        terrainType: UInt16,
        normalY: Float,
        isCrawling: Bool
    ) -> Int16 {
        var floorClass = (terrainType & 0x0007) == 0x0006
            ? surfaceClassVerySlippery
            : surfaceClassDefault
        switch surfaceType {
        case 0x0015, 0x0037, 0x007A:
            floorClass = surfaceClassNotSlippery
        case 0x0014, 0x002A, 0x0035, 0x0079:
            floorClass = surfaceClassSlippery
        case 0x0013, 0x002E, 0x0036, 0x0073, 0x0074, 0x0075, 0x0078:
            floorClass = surfaceClassVerySlippery
        default:
            break
        }
        if isCrawling && normalY > 0.5 && floorClass == surfaceClassDefault {
            floorClass = surfaceClassNotSlippery
        }
        return floorClass
    }

    private static func isSlippery(floorClass: Int16, terrainType: UInt16, normalY: Float) -> Bool {
        if (terrainType & 0x0007) == 0x0006 && normalY < 0.9998477 {
            return true
        }
        let limit: Float
        switch floorClass {
        case surfaceClassVerySlippery:
            limit = 0.9848077
        case surfaceClassSlippery:
            limit = 0.9396926
        case surfaceClassNotSlippery:
            limit = 0
        default:
            limit = 0.7880108
        }
        return normalY <= limit
    }

    private static func terrainSoundAddend(
        surfaceType: Int16,
        floorHeight: Float,
        waterLevel: Float,
        terrainType: UInt16,
        isLavaLevel: Bool
    ) -> UInt32 {
        if !isLavaLevel && floorHeight < waterLevel - 10 {
            return 2 << 16 // SOUND_TERRAIN_WATER
        }
        if (0x0021...0x0027).contains(surfaceType) {
            return 7 << 16 // SOUND_TERRAIN_SAND
        }
        let floorSoundType: Int
        switch surfaceType {
        case 0x0030, 0x0015, 0x0037, 0x007A:
            floorSoundType = 1 // hard / non-slippery
        case 0x0014, 0x0035, 0x0079:
            floorSoundType = 2 // slippery
        case 0x0013, 0x002E, 0x0036, 0x0073, 0x0074, 0x0075, 0x0078:
            floorSoundType = 3 // very slippery
        case 0x0029:
            floorSoundType = 4 // noisy default
        case 0x002A:
            floorSoundType = 5 // noisy slippery
        default:
            floorSoundType = 0
        }
        let sounds: [[UInt32]] = [
            [0, 3, 1, 1, 1, 0], // grass
            [3, 3, 3, 3, 1, 1], // stone
            [5, 6, 5, 6, 3, 3], // snow
            [7, 3, 7, 7, 3, 3], // sand
            [4, 4, 4, 4, 3, 3], // spooky
            [0, 3, 1, 6, 3, 6], // water
            [3, 3, 3, 3, 6, 6], // slide
        ]
        let terrainIndex = Int(terrainType & 0x0007)
        return sounds[terrainIndex][floorSoundType] << 16
    }
}
