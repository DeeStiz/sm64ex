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
    let normalX: Float?
    let normalY: Float?
    let normalZ: Float?

    static let miss = SM64SurfaceQueryResult(height: -11_000, surface: nil)

    init(height: Float, surface: SM64Surface?) {
        self.height = height
        self.surfaceID = surface?.id
        self.type = surface?.type
        self.flags = surface?.flags
        self.normalX = surface?.normal.x
        self.normalY = surface?.normal.y
        self.normalZ = surface?.normal.z
    }
}

struct SM64WallCollisionInput: Equatable, Sendable {
    var x: Float
    var y: Float
    var z: Float
    var offsetY: Float
    var radius: Float
}

struct SM64WallCollisionResult: Equatable, Sendable {
    let x: Float
    let y: Float
    let z: Float
    let totalCollisions: Int
    let surfaceIDs: [UInt32]
}

struct SM64SurfaceRayHit: Equatable, Sendable {
    let surfaceID: UInt32
    let position: SM64SurfaceVec3f
    let distance: Float
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
/// Queries use the C-ordered static/dynamic partition candidates while the
/// source surface arrays remain the authoritative storage for exact tests.
struct SM64SurfaceCollisionWorld: Equatable, Sendable {
    static let levelBoundaryMax: Int32 = 0x2000
    static let missHeight: Float = -11_000
    static let noCameraCollisionFlag: Int8 = 1 << 1
    static let xProjectionFlag: Int8 = 1 << 3
    static let intangibleType: Int16 = 0x12
    static let cameraBoundaryType: Int16 = 0x72
    static let vanishCapWallsType: Int16 = 0x7B

    private(set) var staticSurfaces: [SM64Surface]
    private(set) var dynamicSurfaces: [SM64Surface]
    private var staticSurfaceIndices: [UInt32: Int]
    private var dynamicSurfaceIndices: [UInt32: Int]
    var waterRegions: [SM64WaterRegion]
    var checkingForCamera: Bool
    var includeIntangibleOnce: Bool
    var passThroughVanishCapWalls: Bool
    private(set) var partition: SM64SurfacePartitionGrid

    init(
        staticSurfaces: [SM64Surface] = [],
        dynamicSurfaces: [SM64Surface] = [],
        waterRegions: [SM64WaterRegion] = [],
        checkingForCamera: Bool = false,
        includeIntangibleOnce: Bool = false,
        passThroughVanishCapWalls: Bool = false
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
        self.staticSurfaceIndices = Self.indexSurfaces(staticSurfaces)
        self.dynamicSurfaceIndices = Self.indexSurfaces(dynamicSurfaces)
        self.waterRegions = waterRegions
        self.checkingForCamera = checkingForCamera
        self.includeIntangibleOnce = includeIntangibleOnce
        self.passThroughVanishCapWalls = passThroughVanishCapWalls
        self.partition = SM64SurfacePartitionGrid(
            staticSurfaces: staticSurfaces,
            dynamicSurfaces: dynamicSurfaces
        )
    }

    mutating func replaceDynamicSurfaces(_ surfaces: [SM64Surface]) throws {
        let combined = staticSurfaces + surfaces
        guard Set(combined.map { $0.id }).count == combined.count else {
            throw SM64SurfaceCollisionError.invalidSurface(0)
        }
        dynamicSurfaces = surfaces
        dynamicSurfaceIndices = Self.indexSurfaces(surfaces)
        partition = SM64SurfacePartitionGrid(
            staticSurfaces: staticSurfaces,
            dynamicSurfaces: dynamicSurfaces
        )
    }

    func findFloor(x: Float, y: Float, z: Float) -> SM64SurfaceQueryResult {
        guard inBounds(x: x, z: z) else { return .miss }
        let ix = Int32(x)
        let iy = Int32(y)
        let iz = Int32(z)
        var staticResult = findFloor(
            in: staticSurfaces,
            indices: staticSurfaceIndices,
            ids: partition.candidateIDs(x: x, z: z, dynamic: false, kind: .floor),
            x: ix,
            y: iy,
            z: iz
        )
        if includeIntangibleOnce, staticResult.type == Self.intangibleType {
            staticResult = findFloor(
                in: staticSurfaces,
                indices: staticSurfaceIndices,
                ids: partition.candidateIDs(x: x, z: z, dynamic: false, kind: .floor),
                x: ix,
                y: Int32(staticResult.height - 200),
                z: iz
            )
        }
        let dynamicResult = findFloor(
            in: dynamicSurfaces,
            indices: dynamicSurfaceIndices,
            ids: partition.candidateIDs(x: x, z: z, dynamic: true, kind: .floor),
            x: ix,
            y: iy,
            z: iz
        )
        return dynamicResult.surfaceID != nil && dynamicResult.height > staticResult.height
            ? dynamicResult
            : staticResult
    }

    func findCeil(x: Float, y: Float, z: Float) -> SM64SurfaceQueryResult {
        guard inBounds(x: x, z: z) else { return .miss }
        let staticResult = findCeil(
            in: staticSurfaces,
            indices: staticSurfaceIndices,
            ids: partition.candidateIDs(x: x, z: z, dynamic: false, kind: .ceiling),
            x: Int32(x),
            y: Int32(y),
            z: Int32(z)
        )
        let dynamicResult = findCeil(
            in: dynamicSurfaces,
            indices: dynamicSurfaceIndices,
            ids: partition.candidateIDs(x: x, z: z, dynamic: true, kind: .ceiling),
            x: Int32(x),
            y: Int32(y),
            z: Int32(z)
        )
        return dynamicResult.surfaceID != nil && dynamicResult.height < staticResult.height
            ? dynamicResult
            : staticResult
    }

    func findWaterLevel(x: Float, z: Float) -> Float {
        for region in waterRegions where region.value < 50
            && region.lowX < x && x < region.highX
            && region.lowZ < z && z < region.highZ {
            return region.level
        }
        return Self.missHeight
    }

    func findPoisonGasLevel(x: Float, z: Float) -> Float {
        for region in waterRegions where region.value >= 50
            && region.value % 10 == 0
            && region.lowX < x && x < region.highX
            && region.lowZ < z && z < region.highZ {
            return region.level
        }
        return Self.missHeight
    }

    func findWallCollisions(_ input: SM64WallCollisionInput) -> SM64WallCollisionResult {
        var x = input.x
        var z = input.z
        let y = input.y + input.offsetY
        let radius = min(input.radius, 200)
        var total = 0
        var ids: [UInt32] = []
        collideWallList(
            dynamicSurfaces,
            indices: dynamicSurfaceIndices,
            candidateIDs: partition.candidateIDs(x: x, z: z, dynamic: true, kind: .wall),
            baseX: x,
            baseZ: z,
            y: y,
            radius: radius,
            x: &x,
            z: &z,
            total: &total,
            ids: &ids
        )
        collideWallList(
            staticSurfaces,
            indices: staticSurfaceIndices,
            candidateIDs: partition.candidateIDs(x: x, z: z, dynamic: false, kind: .wall),
            baseX: x,
            baseZ: z,
            y: y,
            radius: radius,
            x: &x,
            z: &z,
            total: &total,
            ids: &ids
        )
        return SM64WallCollisionResult(x: x, y: input.y, z: z, totalCollisions: total, surfaceIDs: ids)
    }

    func findSurfaceOnRay(origin: SM64SurfaceVec3f, direction: SM64SurfaceVec3f) -> SM64SurfaceRayHit? {
        let directionLength = sqrt(direction.x * direction.x + direction.y * direction.y + direction.z * direction.z)
        guard directionLength > 0 else { return nil }
        let ray = SM64SurfaceVec3f(x: direction.x / directionLength, y: direction.y / directionLength, z: direction.z / directionLength)
        let top = ray.y >= 0 ? origin.y + ray.y * directionLength : origin.y
        let bottom = ray.y >= 0 ? origin.y : origin.y + ray.y * directionLength
        var best: SM64SurfaceRayHit?
        for surface in dynamicSurfaces + staticSurfaces {
            guard Float(surface.lowerY) <= top, Float(surface.upperY) >= bottom, acceptsRay(surface) else { continue }
            guard let hit = rayIntersection(origin: origin, direction: ray, length: directionLength, surface: surface) else { continue }
            if best == nil || hit.distance <= best!.distance { best = hit }
        }
        return best
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

    private func acceptsWall(_ surface: SM64Surface) -> Bool {
        guard accepts(surface) else { return false }
        return !(passThroughVanishCapWalls && surface.type == Self.vanishCapWallsType)
    }

    private func acceptsRay(_ surface: SM64Surface) -> Bool {
        if checkingForCamera { return (surface.flags & Self.noCameraCollisionFlag) == 0 }
        return true
    }

    private func collideWallList(
        _ surfaces: [SM64Surface],
        indices: [UInt32: Int],
        candidateIDs: [UInt32],
        baseX: Float,
        baseZ: Float,
        y: Float,
        radius: Float,
        x: inout Float,
        z: inout Float,
        total: inout Int,
        ids: inout [UInt32]
    ) {
        let candidates: [SM64Surface] = candidateIDs.compactMap { id -> SM64Surface? in
            guard let index = indices[id], surfaces.indices.contains(index) else { return nil }
            return surfaces[index]
        }
        for surface in candidates {
            guard y >= Float(surface.lowerY), y <= Float(surface.upperY) else { continue }
            let offset = surface.normal.x * baseX + surface.normal.y * y + surface.normal.z * baseZ + surface.originOffset
            guard offset >= -radius, offset <= radius else { continue }
            guard wallPointInside(surface, x: baseX, y: y, z: baseZ), acceptsWall(surface) else { continue }
            x += surface.normal.x * (radius - offset)
            z += surface.normal.z * (radius - offset)
            total += 1
            if ids.count < 4 { ids.append(surface.id) }
        }
    }

    private func rayIntersection(origin: SM64SurfaceVec3f, direction: SM64SurfaceVec3f, length: Float, surface: SM64Surface) -> SM64SurfaceRayHit? {
        let v0 = SM64SurfaceVec3f(x: Float(surface.vertex1.x), y: Float(surface.vertex1.y), z: Float(surface.vertex1.z))
        let v1 = SM64SurfaceVec3f(x: Float(surface.vertex2.x), y: Float(surface.vertex2.y), z: Float(surface.vertex2.z))
        let v2 = SM64SurfaceVec3f(x: Float(surface.vertex3.x), y: Float(surface.vertex3.y), z: Float(surface.vertex3.z))
        let e1 = SM64SurfaceVec3f(x: v1.x - v0.x, y: v1.y - v0.y, z: v1.z - v0.z)
        let e2 = SM64SurfaceVec3f(x: v2.x - v0.x, y: v2.y - v0.y, z: v2.z - v0.z)
        let h = SM64SurfaceVec3f(
            x: direction.y * e2.z - direction.z * e2.y,
            y: direction.z * e2.x - direction.x * e2.z,
            z: direction.x * e2.y - direction.y * e2.x
        )
        let a = e1.x * h.x + e1.y * h.y + e1.z * h.z
        guard a <= -0.00001 || a >= 0.00001 else { return nil }
        let f = 1 / a
        let s = SM64SurfaceVec3f(x: origin.x - v0.x, y: origin.y - v0.y, z: origin.z - v0.z)
        let u = f * (s.x * h.x + s.y * h.y + s.z * h.z)
        guard u >= 0, u <= 1 else { return nil }
        let q = SM64SurfaceVec3f(
            x: s.y * e1.z - s.z * e1.y,
            y: s.z * e1.x - s.x * e1.z,
            z: s.x * e1.y - s.y * e1.x
        )
        let v = f * (direction.x * q.x + direction.y * q.y + direction.z * q.z)
        guard v >= 0, u + v <= 1 else { return nil }
        let distance = f * (e2.x * q.x + e2.y * q.y + e2.z * q.z)
        guard distance > 0.00001, distance <= length else { return nil }
        return SM64SurfaceRayHit(
            surfaceID: surface.id,
            position: SM64SurfaceVec3f(x: origin.x + direction.x * distance, y: origin.y + direction.y * distance, z: origin.z + direction.z * distance),
            distance: distance
        )
    }

    private func wallPointInside(_ surface: SM64Surface, x: Float, y: Float, z: Float) -> Bool {
        let w1: Float
        let w2: Float
        let w3: Float
        let y1 = Float(surface.vertex1.y)
        let y2 = Float(surface.vertex2.y)
        let y3 = Float(surface.vertex3.y)
        let point: Float
        if (surface.flags & Self.xProjectionFlag) != 0 {
            w1 = -Float(surface.vertex1.z); w2 = -Float(surface.vertex2.z); w3 = -Float(surface.vertex3.z)
            point = -z
        } else {
            w1 = Float(surface.vertex1.x); w2 = Float(surface.vertex2.x); w3 = Float(surface.vertex3.x)
            point = x
        }
        let first = (y1 - y) * (w2 - w1) - (w1 - point) * (y2 - y1)
        let second = (y2 - y) * (w3 - w2) - (w2 - point) * (y3 - y2)
        let third = (y3 - y) * (w1 - w3) - (w3 - point) * (y1 - y3)
        if surface.normal.x > 0 && (surface.flags & Self.xProjectionFlag) != 0 {
            return first <= 0 && second <= 0 && third <= 0
        }
        if surface.normal.z > 0 && (surface.flags & Self.xProjectionFlag) == 0 {
            return first <= 0 && second <= 0 && third <= 0
        }
        return first >= 0 && second >= 0 && third >= 0
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

    private func findFloor(
        in surfaces: [SM64Surface],
        indices: [UInt32: Int],
        ids: [UInt32],
        x: Int32,
        y: Int32,
        z: Int32
    ) -> SM64SurfaceQueryResult {
        for surface in ids.compactMap({ id -> SM64Surface? in
            guard let index = indices[id], surfaces.indices.contains(index) else { return nil }
            return surfaces[index]
        }) {
            guard contains(surface, x: x, z: z), accepts(surface) else { continue }
            let ny = surface.normal.y
            guard ny > 0 else { continue }
            let height = -(Float(x) * surface.normal.x + Float(z) * surface.normal.z + surface.originOffset) / ny
            guard Float(y) - (height - 78) >= 0 else { continue }
            return SM64SurfaceQueryResult(height: height, surface: surface)
        }
        return .miss
    }

    private func findCeil(
        in surfaces: [SM64Surface],
        indices: [UInt32: Int],
        ids: [UInt32],
        x: Int32,
        y: Int32,
        z: Int32
    ) -> SM64SurfaceQueryResult {
        for surface in ids.compactMap({ id -> SM64Surface? in
            guard let index = indices[id], surfaces.indices.contains(index) else { return nil }
            return surfaces[index]
        }) {
            guard contains(surface, x: x, z: z), accepts(surface) else { continue }
            let ny = surface.normal.y
            guard ny < 0 else { continue }
            let height = -(Float(x) * surface.normal.x + Float(z) * surface.normal.z + surface.originOffset) / ny
            guard Float(y) - (height + 78) <= 0 else { continue }
            return SM64SurfaceQueryResult(height: height, surface: surface)
        }
        return .miss
    }

    private static func indexSurfaces(_ surfaces: [SM64Surface]) -> [UInt32: Int] {
        Dictionary(uniqueKeysWithValues: surfaces.enumerated().map { ($0.element.id, $0.offset) })
    }
}
