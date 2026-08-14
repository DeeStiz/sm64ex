import Foundation

enum SM64SurfaceCollisionDataError: Error, Equatable, Sendable {
    case empty
    case unaligned
    case truncated(Int)
    case invalidVertexCount(Int)
    case invalidTriangleCount(Int)
    case invalidVertexIndex(offset: Int, index: Int)
    case unsupportedCommand(UInt16, Int)
}

struct SM64DecodedCollisionData: Equatable, Sendable {
    let surfaces: [SM64Surface]
    let waterRegions: [SM64WaterRegion]
}

/// Decodes the little-endian s16 collision command stream used by
/// COL_VERTEX_INIT/COL_TRI_INIT/COL_WATER_BOX_INIT. Surface normals and
/// partition flags are derived exactly at load time, before any query runs.
struct SM64SurfaceCollisionDecoder: Sendable {
    let dynamic: Bool

    init(dynamic: Bool = false) {
        self.dynamic = dynamic
    }

    func decode(data: Data) throws -> SM64DecodedCollisionData {
        guard !data.isEmpty else { throw SM64SurfaceCollisionDataError.empty }
        guard data.count % 2 == 0 else { throw SM64SurfaceCollisionDataError.unaligned }
        var words: [Int16] = []
        words.reserveCapacity(data.count / 2)
        for offset in stride(from: 0, to: data.count, by: 2) {
            let raw = UInt16(data[offset]) | UInt16(data[offset + 1]) << 8
            words.append(Int16(bitPattern: raw))
        }
        var cursor = 0
        var vertices: [SM64SurfaceVec3s] = []
        var surfaces: [SM64Surface] = []
        var regions: [SM64WaterRegion] = []
        var nextID: UInt32 = 0
        while cursor < words.count {
            let commandOffset = cursor
            let command = UInt16(bitPattern: words[cursor])
            cursor += 1
            switch command {
            case 0x40:
                let count = try readUnsigned(&cursor, words: words)
                guard count <= 2_048 else { throw SM64SurfaceCollisionDataError.invalidVertexCount(count) }
                guard cursor + count * 3 <= words.count else { throw SM64SurfaceCollisionDataError.truncated(commandOffset) }
                vertices.removeAll(keepingCapacity: true)
                vertices.reserveCapacity(count)
                for _ in 0..<count {
                    vertices.append(SM64SurfaceVec3s(x: words[cursor], y: words[cursor + 1], z: words[cursor + 2]))
                    cursor += 3
                }
            case 0x41:
                continue
            case 0x42:
                return SM64DecodedCollisionData(surfaces: surfaces, waterRegions: regions)
            case 0x43:
                throw SM64SurfaceCollisionDataError.unsupportedCommand(command, commandOffset)
            case 0x44:
                let count = try readUnsigned(&cursor, words: words)
                guard count <= 256 else { throw SM64SurfaceCollisionDataError.invalidTriangleCount(count) }
                guard cursor + count * 6 <= words.count else { throw SM64SurfaceCollisionDataError.truncated(commandOffset) }
                for _ in 0..<count {
                    let value = words[cursor]
                    let lowX = Float(words[cursor + 1])
                    let lowZ = Float(words[cursor + 2])
                    let highX = Float(words[cursor + 3])
                    let highZ = Float(words[cursor + 4])
                    let level = Float(words[cursor + 5])
                    cursor += 6
                    regions.append(SM64WaterRegion(value: value, lowX: lowX, lowZ: lowZ, highX: highX, highZ: highZ, level: level))
                }
            default:
                let surfaceType = Int16(bitPattern: command)
                guard command < 0x40 || command >= 0x65 else {
                    throw SM64SurfaceCollisionDataError.unsupportedCommand(command, commandOffset)
                }
                let count = try readUnsigned(&cursor, words: words)
                guard count <= 10_000 else { throw SM64SurfaceCollisionDataError.invalidTriangleCount(count) }
                let hasForce = Self.surfaceHasForce(surfaceType)
                let stride = hasForce ? 4 : 3
                guard cursor + count * stride <= words.count else { throw SM64SurfaceCollisionDataError.truncated(commandOffset) }
                for _ in 0..<count {
                    let i0 = Int(words[cursor])
                    let i1 = Int(words[cursor + 1])
                    let i2 = Int(words[cursor + 2])
                    guard i0 >= 0, i1 >= 0, i2 >= 0,
                          i0 < vertices.count, i1 < vertices.count, i2 < vertices.count else {
                        throw SM64SurfaceCollisionDataError.invalidVertexIndex(offset: cursor, index: max(i0, max(i1, i2)))
                    }
                    let force = hasForce ? words[cursor + 3] : 0
                    cursor += stride
                    if let surface = makeSurface(
                        id: nextID,
                        type: surfaceType,
                        force: force,
                        vertex1: vertices[i0],
                        vertex2: vertices[i1],
                        vertex3: vertices[i2]
                    ) {
                        surfaces.append(surface)
                        nextID &+= 1
                    }
                }
            }
        }
        throw SM64SurfaceCollisionDataError.truncated(cursor)
    }

    private func readUnsigned(_ cursor: inout Int, words: [Int16]) throws -> Int {
        guard cursor < words.count else { throw SM64SurfaceCollisionDataError.truncated(cursor) }
        let value = Int(UInt16(bitPattern: words[cursor]))
        cursor += 1
        return value
    }

    private func makeSurface(
        id: UInt32,
        type: Int16,
        force: Int16,
        vertex1: SM64SurfaceVec3s,
        vertex2: SM64SurfaceVec3s,
        vertex3: SM64SurfaceVec3s
    ) -> SM64Surface? {
        let y21 = Float(vertex2.y - vertex1.y)
        let z21 = Float(vertex2.z - vertex1.z)
        let x21 = Float(vertex2.x - vertex1.x)
        let y32 = Float(vertex3.y - vertex2.y)
        let z32 = Float(vertex3.z - vertex2.z)
        let x32 = Float(vertex3.x - vertex2.x)
        let nx = y21 * z32 - z21 * y32
        let ny = z21 * x32 - x21 * z32
        let nz = x21 * y32 - y21 * x32
        let magnitude = Foundation.sqrt(nx * nx + ny * ny + nz * nz)
        guard magnitude >= 0.0001 else { return nil }
        let normal = SM64SurfaceVec3f(x: nx / magnitude, y: ny / magnitude, z: nz / magnitude)
        let origin = -(normal.x * Float(vertex1.x) + normal.y * Float(vertex1.y) + normal.z * Float(vertex1.z))
        let minY = min(vertex1.y, min(vertex2.y, vertex3.y))
        let maxY = max(vertex1.y, max(vertex2.y, vertex3.y))
        var flags: Int8 = dynamic ? 1 : 0
        if Self.noCameraCollisionTypes.contains(type) { flags |= SM64SurfaceCollisionWorld.noCameraCollisionFlag }
        if abs(normal.y) <= 0.01, abs(normal.x) > 0.707 { flags |= SM64SurfaceCollisionWorld.xProjectionFlag }
        return SM64Surface(
            id: id,
            type: type,
            force: force,
            flags: flags,
            lowerY: minY - 5,
            upperY: maxY + 5,
            vertex1: vertex1,
            vertex2: vertex2,
            vertex3: vertex3,
            normal: normal,
            originOffset: origin
        )
    }

    private static let noCameraCollisionTypes: Set<Int16> = [0x76, 0x77, 0x78, 0x79, 0x7A]
    private static func surfaceHasForce(_ type: Int16) -> Bool {
        [0x0004, 0x000E, 0x0024, 0x0025, 0x0027, 0x002C, 0x002D].contains(type)
    }
}
