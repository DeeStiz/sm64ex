import Foundation

/// Errors produced while decoding the compact `COL_*` collision stream used by
/// the original engine. The decoder is deliberately bounds checked: malformed
/// ROM/content-pack bytes must fail before they can mutate the collision world.
enum SM64CollisionMeshDecodeError: Error, Equatable, Sendable, CustomStringConvertible {
    case missingVerticesCommand
    case truncated(offset: Int)
    case invalidVertexCount(Int)
    case invalidSurfaceCommand(value: Int16, offset: Int)
    case invalidTriangleCount(Int, offset: Int)
    case invalidVertexIndex(Int, offset: Int)
    case surfaceIDOverflow(base: UInt32, count: Int)
    case noTerminator

    var description: String {
        switch self {
        case .missingVerticesCommand:
            "collision stream does not begin with COL_INIT"
        case let .truncated(offset):
            "collision stream truncated at word \(offset)"
        case let .invalidVertexCount(count):
            "invalid collision vertex count \(count)"
        case let .invalidSurfaceCommand(value, offset):
            "invalid collision surface command \(value) at word \(offset)"
        case let .invalidTriangleCount(count, offset):
            "invalid collision triangle count \(count) at word \(offset)"
        case let .invalidVertexIndex(index, offset):
            "invalid collision vertex index \(index) at word \(offset)"
        case let .surfaceIDOverflow(base, count):
            "collision surface IDs overflow from \(base) for \(count) surfaces"
        case .noTerminator:
            "collision stream has no COL_TRI_STOP or COL_END terminator"
        }
    }
}

/// The object transform captured at the collision-load boundary. C transforms
/// vertices into signed 16-bit storage before calculating normals and bounds;
/// preserving that truncation point is important for floor heights and wall
/// projections.
struct SM64CollisionMeshTransform: Equatable, Sendable {
    private let matrix: [Float]

    init(
        position: SM64ObjectVector3,
        faceAngles: SM64ObjectAngles,
        scale: SM64ObjectVector3
    ) {
        let unscaled = SM64ObjectTransform.rotateZXYAndTranslate(
            translation: position,
            angles: faceAngles
        )
        self.matrix = SM64ObjectTransform.applyingScale(unscaled, scale: scale)
    }

    init(record: SM64ObjectRecord) {
        self.init(
            position: record.position,
            faceAngles: record.faceAngles,
            scale: record.scale
        )
    }

    func apply(_ vertex: SM64SurfaceVec3s) -> SM64SurfaceVec3s {
        let x = matrix[0] * Float(vertex.x)
            + matrix[4] * Float(vertex.y)
            + matrix[8] * Float(vertex.z)
            + matrix[12]
        let y = matrix[1] * Float(vertex.x)
            + matrix[5] * Float(vertex.y)
            + matrix[9] * Float(vertex.z)
            + matrix[13]
        let z = matrix[2] * Float(vertex.x)
            + matrix[6] * Float(vertex.y)
            + matrix[10] * Float(vertex.z)
            + matrix[14]
        return SM64SurfaceVec3s(
            x: Self.truncatingInt16(x),
            y: Self.truncatingInt16(y),
            z: Self.truncatingInt16(z)
        )
    }

    private static func truncatingInt16(_ value: Float) -> Int16 {
        precondition(value.isFinite, "collision transform must produce finite coordinates")
        return Int16(truncatingIfNeeded: Int(value.rounded(.towardZero)))
    }
}

/// Swift counterpart of `read_surface_data`, `load_object_surfaces`, and the
/// collision portion of `load_object_collision_model`. Surface IDs are local
/// deterministic tokens supplied by the owner-thread binding route; C pointer
/// identity never crosses into Swift.
enum SM64CollisionMeshDecoder {
    static let verticesCommand: Int16 = 0x0040
    static let continueCommand: Int16 = 0x0041
    static let endCommand: Int16 = 0x0042
    static let objectsCommand: Int16 = 0x0043
    static let environmentCommand: Int16 = 0x0044
    static let dynamicFlag: Int8 = 1 << 0
    static let noCameraCollisionFlag: Int8 = 1 << 1
    static let xProjectionFlag: Int8 = 1 << 3

    static func decode(
        words: [Int16],
        transform: SM64CollisionMeshTransform = SM64CollisionMeshTransform(
            position: .zero,
            faceAngles: .zero,
            scale: .one
        ),
        surfaceIDBase: UInt32 = 1,
        room: Int8 = 0,
        dynamic: Bool = true
    ) throws -> [SM64Surface] {
        var cursor = 0
        guard read(words, cursor: &cursor) == verticesCommand else {
            throw SM64CollisionMeshDecodeError.missingVerticesCommand
        }

        let vertexCount = Int(try readRequired(words, cursor: &cursor))
        guard vertexCount >= 0 else {
            throw SM64CollisionMeshDecodeError.invalidVertexCount(vertexCount)
        }
        var vertices: [SM64SurfaceVec3s] = []
        vertices.reserveCapacity(vertexCount)
        for _ in 0..<vertexCount {
            let x = try readRequired(words, cursor: &cursor)
            let y = try readRequired(words, cursor: &cursor)
            let z = try readRequired(words, cursor: &cursor)
            vertices.append(transform.apply(SM64SurfaceVec3s(x: x, y: y, z: z)))
        }

        var surfaces: [SM64Surface] = []
        var terminated = false
        while cursor < words.count {
            let commandOffset = cursor
            let command = try readRequired(words, cursor: &cursor)
            if command == continueCommand || command == endCommand {
                terminated = true
                break
            }
            guard command < verticesCommand || command >= 0x0065 else {
                if command == objectsCommand || command == environmentCommand {
                    throw SM64CollisionMeshDecodeError.invalidSurfaceCommand(
                        value: command, offset: commandOffset
                    )
                }
                throw SM64CollisionMeshDecodeError.invalidSurfaceCommand(
                    value: command, offset: commandOffset
                )
            }

            let triangleCountOffset = cursor
            let triangleCount = Int(try readRequired(words, cursor: &cursor))
            guard triangleCount >= 0 else {
                throw SM64CollisionMeshDecodeError.invalidTriangleCount(
                    triangleCount, offset: triangleCountOffset
                )
            }
            let hasForce = Self.surfaceHasForce(command)
            for _ in 0..<triangleCount {
                let indexOffset = cursor
                let index1 = Int(try readRequired(words, cursor: &cursor))
                let index2 = Int(try readRequired(words, cursor: &cursor))
                let index3 = Int(try readRequired(words, cursor: &cursor))
                guard vertices.indices.contains(index1) else {
                    throw SM64CollisionMeshDecodeError.invalidVertexIndex(index1, offset: indexOffset)
                }
                guard vertices.indices.contains(index2) else {
                    throw SM64CollisionMeshDecodeError.invalidVertexIndex(index2, offset: indexOffset + 1)
                }
                guard vertices.indices.contains(index3) else {
                    throw SM64CollisionMeshDecodeError.invalidVertexIndex(index3, offset: indexOffset + 2)
                }
                let force = hasForce ? try readRequired(words, cursor: &cursor) : 0
                guard surfaceIDBase <= UInt32.max - UInt32(surfaces.count) else {
                    throw SM64CollisionMeshDecodeError.surfaceIDOverflow(
                        base: surfaceIDBase, count: surfaces.count + 1
                    )
                }
                if let surface = makeSurface(
                    id: surfaceIDBase + UInt32(surfaces.count),
                    type: command,
                    force: force,
                    room: room,
                    vertex1: vertices[index1],
                    vertex2: vertices[index2],
                    vertex3: vertices[index3],
                    dynamic: dynamic
                ) {
                    surfaces.append(surface)
                }
            }
        }
        guard terminated else { throw SM64CollisionMeshDecodeError.noTerminator }
        return surfaces
    }

    private static func read(_ words: [Int16], cursor: inout Int) -> Int16? {
        guard cursor < words.count else { return nil }
        defer { cursor += 1 }
        return words[cursor]
    }

    private static func readRequired(_ words: [Int16], cursor: inout Int) throws -> Int16 {
        guard let value = read(words, cursor: &cursor) else {
            throw SM64CollisionMeshDecodeError.truncated(offset: cursor)
        }
        return value
    }

    private static func surfaceHasForce(_ type: Int16) -> Bool {
        switch type {
        case 0x0004, 0x000E, 0x0024, 0x0025, 0x0027, 0x002C, 0x002D:
            return true
        default:
            return false
        }
    }

    private static func surfaceHasNoCameraCollision(_ type: Int16) -> Bool {
        switch type {
        case 0x0076, 0x0077, 0x0078, 0x0079, 0x007A:
            return true
        default:
            return false
        }
    }

    private static func makeSurface(
        id: UInt32,
        type: Int16,
        force: Int16,
        room: Int8,
        vertex1: SM64SurfaceVec3s,
        vertex2: SM64SurfaceVec3s,
        vertex3: SM64SurfaceVec3s,
        dynamic: Bool
    ) -> SM64Surface? {
        let x1 = Float(vertex1.x)
        let y1 = Float(vertex1.y)
        let z1 = Float(vertex1.z)

        // C performs the cross-product arithmetic in integer temporaries and
        // converts to f32 only after subtraction. Keep that sequencing so a
        // mathematically zero component does not acquire a signed zero.
        let nxInteger = (Int(vertex2.y) - Int(vertex1.y))
            * (Int(vertex3.z) - Int(vertex2.z))
            - (Int(vertex2.z) - Int(vertex1.z))
            * (Int(vertex3.y) - Int(vertex2.y))
        let nyInteger = (Int(vertex2.z) - Int(vertex1.z))
            * (Int(vertex3.x) - Int(vertex2.x))
            - (Int(vertex2.x) - Int(vertex1.x))
            * (Int(vertex3.z) - Int(vertex2.z))
        let nzInteger = (Int(vertex2.x) - Int(vertex1.x))
            * (Int(vertex3.y) - Int(vertex2.y))
            - (Int(vertex2.y) - Int(vertex1.y))
            * (Int(vertex3.x) - Int(vertex2.x))
        let nx = Float(nxInteger)
        let ny = Float(nyInteger)
        let nz = Float(nzInteger)
        let magnitude = sqrt(nx * nx + ny * ny + nz * nz)
        guard magnitude >= 0.0001 else { return nil }
        let normal = SM64SurfaceVec3f(
            x: nx / magnitude,
            y: ny / magnitude,
            z: nz / magnitude
        )

        var flags: Int8 = dynamic ? dynamicFlag : 0
        if surfaceHasNoCameraCollision(type) { flags |= noCameraCollisionFlag }
        if normal.y <= 0.01 && normal.y >= -0.01
            && (normal.x < -0.707 || normal.x > 0.707) {
            flags |= xProjectionFlag
        }

        let minY = min(Int(vertex1.y), Int(vertex2.y), Int(vertex3.y))
        let maxY = max(Int(vertex1.y), Int(vertex2.y), Int(vertex3.y))
        return SM64Surface(
            id: id,
            type: type,
            force: force,
            flags: flags,
            room: room,
            lowerY: Int16(truncatingIfNeeded: minY - 5),
            upperY: Int16(truncatingIfNeeded: maxY + 5),
            vertex1: vertex1,
            vertex2: vertex2,
            vertex3: vertex3,
            normal: normal,
            originOffset: -(normal.x * x1 + normal.y * y1 + normal.z * z1)
        )
    }
}

enum SM64PlatformCollisionRouteError: Error, Equatable, Sendable, CustomStringConvertible {
    case invalidOwner(SM64ObjectID)
    case ownerAlreadyBound(SM64ObjectID)
    case collision(SM64CollisionMeshDecodeError)
    case registry(SM64PlatformCollisionRegistryError)
    case world(SM64SurfaceCollisionError)

    var description: String {
        switch self {
        case let .invalidOwner(owner): "invalid collision owner \(owner)"
        case let .ownerAlreadyBound(owner): "collision owner already bound \(owner)"
        case let .collision(error): "collision decode failed: \(error)"
        case let .registry(error): "collision registry failed: \(error)"
        case let .world(error): "collision world failed: \(error)"
        }
    }
}

/// Owner-thread route that turns a behavior-selected collision stream into
/// transformed dynamic surfaces, atomically publishes it to the registry and
/// collision world, and records the owner-generation lease in engine state.
/// The candidate-copy commit keeps a malformed replacement from partially
/// replacing a live platform's previous collision.
final class SM64PlatformCollisionRuntime {
    private(set) var registry: SM64PlatformCollisionRegistry
    private(set) var world: SM64SurfaceCollisionWorld

    init(
        staticSurfaces: [SM64Surface] = [],
        waterRegions: [SM64WaterRegion] = []
    ) throws {
        self.registry = SM64PlatformCollisionRegistry()
        self.world = try SM64SurfaceCollisionWorld(
            staticSurfaces: staticSurfaces,
            waterRegions: waterRegions
        )
    }

    @discardableResult
    func bind(
        owner: SM64ObjectID,
        object: SM64ObjectRecord,
        collisionWords: [Int16],
        surfaceIDBase: UInt32,
        state: SM64SwiftEngineState
    ) throws -> [SM64Surface] {
        guard owner == object.id, state.objects.contains(owner) else {
            throw SM64PlatformCollisionRouteError.invalidOwner(owner)
        }
        let surfaces: [SM64Surface]
        do {
            surfaces = try SM64CollisionMeshDecoder.decode(
                words: collisionWords,
                transform: SM64CollisionMeshTransform(record: object),
                surfaceIDBase: surfaceIDBase
            )
        } catch let error as SM64CollisionMeshDecodeError {
            throw SM64PlatformCollisionRouteError.collision(error)
        }

        var candidateRegistry = registry
        do {
            try candidateRegistry.replace(owner: owner, surfaces: surfaces)
        } catch let error as SM64PlatformCollisionRegistryError {
            throw SM64PlatformCollisionRouteError.registry(error)
        }
        var candidateWorld = world
        do {
            try candidateRegistry.apply(to: &candidateWorld)
        } catch let error as SM64SurfaceCollisionError {
            throw SM64PlatformCollisionRouteError.world(error)
        }

        if state.platformCollisionOwners.contains(owner) {
            guard state.updatePlatformCollisionOwner(owner, surfaceIDs: surfaces.map(\.id)) else {
                throw SM64PlatformCollisionRouteError.ownerAlreadyBound(owner)
            }
        } else {
            guard state.bindPlatformCollisionOwner(owner, surfaceIDs: surfaces.map(\.id)) else {
                throw SM64PlatformCollisionRouteError.ownerAlreadyBound(owner)
            }
        }
        registry = candidateRegistry
        world = candidateWorld
        return surfaces
    }

    @discardableResult
    func remove(
        owner: SM64ObjectID,
        state: SM64SwiftEngineState
    ) throws -> Bool {
        var candidateRegistry = registry
        let removed = candidateRegistry.remove(owner: owner)
        var candidateWorld = world
        do {
            try candidateRegistry.apply(to: &candidateWorld)
        } catch let error as SM64SurfaceCollisionError {
            throw SM64PlatformCollisionRouteError.world(error)
        }
        registry = candidateRegistry
        world = candidateWorld
        _ = state.removePlatformCollisionOwner(owner)
        return removed
    }
}
