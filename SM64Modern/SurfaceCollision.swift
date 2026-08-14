import Foundation

struct SM64SurfaceVec3s: Equatable, Sendable {
    let x: Int16
    let y: Int16
    let z: Int16
}

struct SM64SurfaceVec3f: Equatable, Sendable {
    let x: Float
    let y: Float
    let z: Float
}

struct SM64Surface: Equatable, Sendable {
    let id: UInt32
    let type: Int16
    let force: Int16
    let flags: Int8
    let room: Int8
    let lowerY: Int16
    let upperY: Int16
    let vertex1: SM64SurfaceVec3s
    let vertex2: SM64SurfaceVec3s
    let vertex3: SM64SurfaceVec3s
    let normal: SM64SurfaceVec3f
    let originOffset: Float

    init(
        id: UInt32,
        type: Int16 = 0,
        force: Int16 = 0,
        flags: Int8 = 0,
        room: Int8 = 0,
        lowerY: Int16 = -32_767,
        upperY: Int16 = 32_767,
        vertex1: SM64SurfaceVec3s,
        vertex2: SM64SurfaceVec3s,
        vertex3: SM64SurfaceVec3s,
        normal: SM64SurfaceVec3f,
        originOffset: Float
    ) {
        self.id = id
        self.type = type
        self.force = force
        self.flags = flags
        self.room = room
        self.lowerY = lowerY
        self.upperY = upperY
        self.vertex1 = vertex1
        self.vertex2 = vertex2
        self.vertex3 = vertex3
        self.normal = normal
        self.originOffset = originOffset
    }
}

struct SM64SurfaceQueryResult: Equatable, Sendable {
    let height: Float
    let surfaceID: UInt32?
    let type: Int16?
    let flags: Int8?
    let normalY: Float?

    static let miss = SM64SurfaceQueryResult(height: -11_000, surface: nil)

    init(height: Float, surface: SM64Surface?) {
        self.height = height
        self.surfaceID = surface?.id
        self.type = surface?.type
        self.flags = surface?.flags
        self.normalY = surface?.normal.y
    }
}

struct SM64WaterRegion: Equatable, Sendable {
    let value: Int16
    let lowX: Float
    let lowZ: Float
    let highX: Float
    let highZ: Float
    let level: Float
}

enum SM64SurfaceCollisionError: Error, Equatable, Sendable {
    case invalidSurface(UInt32)
    case invalidWaterRegion
}

/// Value-type collision world matching the legacy surface query contract.
/// Spatial partitioning is intentionally a later optimization; insertion
/// order and dynamic-over-static selection are preserved here first.
struct SM64SurfaceCollisionWorld: Equatable, Sendable {
    static let levelBoundaryMax: Int32 = 0x2000
    static let missHeight: Float = -11_000
    static let noCameraCollisionFlag: Int8 = 1 << 1
    static let intangibleType: Int16 = 0x12
    static let cameraBoundaryType: Int16 = 0x72

    var staticSurfaces: [SM64Surface]
    var dynamicSurfaces: [SM64Surface]
    var waterRegions: [SM64WaterRegion]
    var checkingForCamera: Bool
    var includeIntangibleOnce: Bool

    init(
        staticSurfaces: [SM64Surface] = [],
        dynamicSurfaces: [SM64Surface] = [],
        waterRegions: [SM64WaterRegion] = [],
        checkingForCamera: Bool = false,
        includeIntangibleOnce: Bool = false
    ) throws {
        let surfaces = staticSurfaces + dynamicSurfaces
        guard Set(surfaces.map { $0.id }).count == surfaces.count else {
            throw SM64SurfaceCollisionError.invalidSurface(0)
        }
        for region in waterRegions {
            guard region.lowX < region.highX, region.lowZ < region.highZ else {
                throw SM64SurfaceCollisionError.invalidWaterRegion
            }
        }
        self.staticSurfaces = staticSurfaces
        self.dynamicSurfaces = dynamicSurfaces
        self.waterRegions = waterRegions
        self.checkingForCamera = checkingForCamera
        self.includeIntangibleOnce = includeIntangibleOnce
    }

    func findFloor(x: Float, y: Float, z: Float) -> SM64SurfaceQueryResult {
        guard inBounds(x: x, z: z) else { return .miss }
        let ix = Int32(x)
        let iy = Int32(y)
        let iz = Int32(z)
        var staticResult = findFloor(in: staticSurfaces, x: ix, y: iy, z: iz)
        if includeIntangibleOnce, staticResult.type == Self.intangibleType {
            staticResult = findFloor(in: staticSurfaces, x: ix, y: Int32(staticResult.height - 200), z: iz)
        }
        let dynamicResult = findFloor(in: dynamicSurfaces, x: ix, y: iy, z: iz)
        return dynamicResult.surfaceID != nil && dynamicResult.height > staticResult.height
            ? dynamicResult
            : staticResult
    }

    func findCeil(x: Float, y: Float, z: Float) -> SM64SurfaceQueryResult {
        guard inBounds(x: x, z: z) else { return .miss }
        return findCeil(in: staticSurfaces, x: Int32(x), y: Int32(y), z: Int32(z))
    }

    func findWaterLevel(x: Float, z: Float) -> Float {
        for region in waterRegions where region.value < 50
            && region.lowX < x && x < region.highX
            && region.lowZ < z && z < region.highZ {
            return region.level
        }
        return Self.missHeight
    }

    private func inBounds(x: Float, z: Float) -> Bool {
        let ix = Int32(x)
        let iz = Int32(z)
        return ix > -Self.levelBoundaryMax && ix < Self.levelBoundaryMax
            && iz > -Self.levelBoundaryMax && iz < Self.levelBoundaryMax
    }

    private func accepts(_ surface: SM64Surface) -> Bool {
        if checkingForCamera {
            return (surface.flags & Self.noCameraCollisionFlag) == 0
        }
        return surface.type != Self.cameraBoundaryType
    }

    private func contains(_ surface: SM64Surface, x: Int32, z: Int32) -> Bool {
        let x1 = Int32(surface.vertex1.x)
        let z1 = Int32(surface.vertex1.z)
        let x2 = Int32(surface.vertex2.x)
        let z2 = Int32(surface.vertex2.z)
        let x3 = Int32(surface.vertex3.x)
        let z3 = Int32(surface.vertex3.z)
        if (z1 - z) * (x2 - x1) - (x1 - x) * (z2 - z1) < 0 { return false }
        if (z2 - z) * (x3 - x2) - (x2 - x) * (z3 - z2) < 0 { return false }
        if (z3 - z) * (x1 - x3) - (x3 - x) * (z1 - z3) < 0 { return false }
        return true
    }

    private func findFloor(in surfaces: [SM64Surface], x: Int32, y: Int32, z: Int32) -> SM64SurfaceQueryResult {
        for surface in surfaces {
            guard contains(surface, x: x, z: z), accepts(surface) else { continue }
            let ny = surface.normal.y
            guard ny != 0 else { continue }
            let height = -(Float(x) * surface.normal.x + Float(z) * surface.normal.z + surface.originOffset) / ny
            guard Float(y) - (height - 78) >= 0 else { continue }
            return SM64SurfaceQueryResult(height: height, surface: surface)
        }
        return .miss
    }

    private func findCeil(in surfaces: [SM64Surface], x: Int32, y: Int32, z: Int32) -> SM64SurfaceQueryResult {
        for surface in surfaces {
            guard contains(surface, x: x, z: z), accepts(surface) else { continue }
            let ny = surface.normal.y
            guard ny != 0 else { continue }
            let height = -(Float(x) * surface.normal.x + Float(z) * surface.normal.z + surface.originOffset) / ny
            guard Float(y) - (height + 78) <= 0 else { continue }
            return SM64SurfaceQueryResult(height: height, surface: surface)
        }
        return .miss
    }
}
