import CryptoKit
import Foundation

/// A pointer-free slice of the authored Goddard Mario-face mesh.  The packet
/// deliberately carries the complete source counts while exposing only a
/// bounded first-face window; this is a proof boundary, not a replacement for
/// the full C dynlist render authority.
struct SM64MarioFaceSourceVertex: Equatable, Sendable {
    let sourceIndex: UInt32
    let x: Int16
    let y: Int16
    let z: Int16
}

struct SM64MarioFaceSourceTriangle: Equatable, Sendable {
    let materialID: UInt32
    let indices: [UInt32]
}

struct SM64MarioFaceSourceMaterial: Equatable, Sendable {
    let materialGroupID: UInt32
    let materialID: UInt32
    let ambientRGB1000: [UInt32]
    let diffuseRGB1000: [UInt32]
}

struct SM64MarioFaceSourceMeshPacket: Equatable, Sendable {
    let schemaVersion: UInt32
    let sourcePath: String
    let sourceDigestWords: [UInt64]
    let meshID: UInt32
    let shapeID: UInt32
    let vertexGroupID: UInt32
    let planeGroupID: UInt32
    let materialGroupID: UInt32
    let sourceVertexCount: UInt32
    let sourceFaceCount: UInt32
    let sourceMaterialCount: UInt32
    let faceWindowStart: UInt32
    let vertices: [SM64MarioFaceSourceVertex]
    let triangles: [SM64MarioFaceSourceTriangle]
    let materials: [SM64MarioFaceSourceMaterial]

    var faceWindowCount: UInt32 { UInt32(triangles.count) }

    /// The bounded source window expanded into the generic SM64 vertex packet
    /// layout: clip position (4 floats) followed by one RGB input (3 floats).
    /// The projection is explicitly debug-only until the source camera and
    /// transform route are migrated; it does not claim visual parity.
    func debugMetalVertexFloats() -> [Float] {
        let byIndex = Dictionary(uniqueKeysWithValues: vertices.map { ($0.sourceIndex, $0) })
        let materialByID = Dictionary(uniqueKeysWithValues: materials.map { ($0.materialID, $0) })
        let projectionScale: Float = 1.0 / 1024.0
        let depthScale: Float = 1.0 / 2048.0
        var result: [Float] = []
        result.reserveCapacity(triangles.count * 3 * 7)
        for triangle in triangles {
            let material = materialByID[triangle.materialID]
            let color = (material?.diffuseRGB1000 ?? [0, 0, 0]).map { Float($0) / 1000.0 }
            for index in triangle.indices {
                guard let vertex = byIndex[index] else { continue }
                result.append(Float(vertex.x) * projectionScale)
                result.append(Float(vertex.y) * projectionScale)
                result.append(Float(vertex.z) * depthScale)
                result.append(1.0)
                result.append(contentsOf: color)
            }
        }
        return result
    }
}

enum SM64MarioFaceSourceGeometry {
    static let sourcePath = "src/goddard/dynlists/dynlist_mario_face.c"

    // SHA-256 of the checked-in source file at the time this packet was
    // admitted.  The digest is split into words so the value contract does
    // not depend on a platform crypto implementation.
    static let sourceDigestWords: [UInt64] = [
        0xa5bb_e2b6_c2a9_9313,
        0x10ac_eb2a_27cb_862b,
        0x1041_1d72_155a_b25d,
        0xa70e_721e_75a9_cc0e,
    ]

    static let sourceDigestBytes: [UInt8] = [
        0xa5, 0xbb, 0xe2, 0xb6, 0xc2, 0xa9, 0x93, 0x13,
        0x10, 0xac, 0xeb, 0x2a, 0x27, 0xcb, 0x86, 0x2b,
        0x10, 0x41, 0x1d, 0x72, 0x15, 0x5a, 0xb2, 0x5d,
        0xa7, 0x0e, 0x72, 0x1e, 0x75, 0xa9, 0xcc, 0x0e,
    ]

    static let packet: SM64MarioFaceSourceMeshPacket = {
        let vertices = [
            SM64MarioFaceSourceVertex(sourceIndex: 43, x: 115, y: -178, z: 351),
            SM64MarioFaceSourceVertex(sourceIndex: 102, x: 50, y: -217, z: 325),
            SM64MarioFaceSourceVertex(sourceIndex: 112, x: 156, y: -150, z: 317),
            SM64MarioFaceSourceVertex(sourceIndex: 42, x: 63, y: -198, z: 357),
            SM64MarioFaceSourceVertex(sourceIndex: 188, x: -50, y: -217, z: 325),
            SM64MarioFaceSourceVertex(sourceIndex: 354, x: -115, y: -178, z: 351),
            SM64MarioFaceSourceVertex(sourceIndex: 356, x: -155, y: -149, z: 317),
            SM64MarioFaceSourceVertex(sourceIndex: 198, x: -63, y: -198, z: 357),
        ]
        let triangles = [
            SM64MarioFaceSourceTriangle(materialID: 0, indices: [43, 102, 112]),
            SM64MarioFaceSourceTriangle(materialID: 0, indices: [102, 42, 188]),
            SM64MarioFaceSourceTriangle(materialID: 0, indices: [354, 356, 188]),
            SM64MarioFaceSourceTriangle(materialID: 0, indices: [188, 198, 354]),
            SM64MarioFaceSourceTriangle(materialID: 0, indices: [198, 188, 42]),
            SM64MarioFaceSourceTriangle(materialID: 0, indices: [43, 42, 102]),
        ]
        let materials = [
            SM64MarioFaceSourceMaterial(
                materialGroupID: 0xE0,
                materialID: 0,
                ambientRGB1000: [1000, 1000, 1000],
                diffuseRGB1000: [1000, 1000, 1000]
            ),
        ]
        return SM64MarioFaceSourceMeshPacket(
            schemaVersion: 1,
            sourcePath: sourcePath,
            sourceDigestWords: sourceDigestWords,
            meshID: 1,
            shapeID: 0xE1,
            vertexGroupID: 0xDE,
            planeGroupID: 0xDF,
            materialGroupID: 0xE0,
            sourceVertexCount: 440,
            sourceFaceCount: 877,
            sourceMaterialCount: 8,
            faceWindowStart: 0,
            vertices: vertices,
            triangles: triangles,
            materials: materials
        )
    }()
}

enum SM64MarioFaceSourceGeometryProviderError: Error, Equatable, Sendable {
    case sourceUnavailable
    case invalidUTF8
    case sourceDigestMismatch
    case missingArray(String)
    case invalidArray(String)
    case invalidMaterialGroup
}

/// Development/content-pack boundary for the complete Goddard mesh.  The
/// parser is intentionally restricted to the two checked-in C arrays and the
/// `0xE0` material macro group; it never follows a C pointer or executes C.
enum SM64MarioFaceSourceGeometryProvider {
    static func load(rootURL: URL) throws -> SM64MarioFaceSourceMeshPacket {
        let sourceURL = rootURL.appendingPathComponent(
            SM64MarioFaceSourceGeometry.sourcePath,
            isDirectory: false
        )
        guard let data = try? Data(contentsOf: sourceURL, options: .mappedIfSafe) else {
            throw SM64MarioFaceSourceGeometryProviderError.sourceUnavailable
        }
        let digest = Array(SHA256.hash(data: data))
        guard digest == SM64MarioFaceSourceGeometry.sourceDigestBytes else {
            throw SM64MarioFaceSourceGeometryProviderError.sourceDigestMismatch
        }
        let text = String(decoding: data, as: UTF8.self)
        guard text.utf8.count == data.count else {
            throw SM64MarioFaceSourceGeometryProviderError.invalidUTF8
        }

        let vertexRows = try parseRows(
            text,
            marker: "static s16 mario_Face_VtxData[VTX_NUM][3]",
            width: 3,
            label: "vertices"
        )
        let faceRows = try parseRows(
            text,
            marker: "static u16 mario_Face_FaceData[FACE_NUM][4]",
            width: 4,
            label: "faces"
        )
        guard vertexRows.count == 440 else {
            throw SM64MarioFaceSourceGeometryProviderError.invalidArray("vertices")
        }
        guard faceRows.count == 877 else {
            throw SM64MarioFaceSourceGeometryProviderError.invalidArray("faces")
        }

        let materials = try parseMaterials(text)
        guard materials.count == 8 else {
            throw SM64MarioFaceSourceGeometryProviderError.invalidMaterialGroup
        }
        let vertices = vertexRows.enumerated().map { index, row in
            SM64MarioFaceSourceVertex(
                sourceIndex: UInt32(index),
                x: Int16(row[0]), y: Int16(row[1]), z: Int16(row[2])
            )
        }
        let triangles = faceRows.map { row in
            SM64MarioFaceSourceTriangle(
                materialID: UInt32(row[0]),
                indices: [UInt32(row[1]), UInt32(row[2]), UInt32(row[3])]
            )
        }
        return SM64MarioFaceSourceMeshPacket(
            schemaVersion: 2,
            sourcePath: SM64MarioFaceSourceGeometry.sourcePath,
            sourceDigestWords: SM64MarioFaceSourceGeometry.sourceDigestWords,
            meshID: 1,
            shapeID: 0xE1,
            vertexGroupID: 0xDE,
            planeGroupID: 0xDF,
            materialGroupID: 0xE0,
            sourceVertexCount: UInt32(vertices.count),
            sourceFaceCount: UInt32(triangles.count),
            sourceMaterialCount: UInt32(materials.count),
            faceWindowStart: 0,
            vertices: vertices,
            triangles: triangles,
            materials: materials
        )
    }

    private static func parseRows(
        _ text: String,
        marker: String,
        width: Int,
        label: String
    ) throws -> [[Int]] {
        guard let markerRange = text.range(of: marker),
              let open = text[markerRange.upperBound...].firstIndex(of: "{"),
              let end = text[open...].range(of: "};")?.lowerBound else {
            throw SM64MarioFaceSourceGeometryProviderError.missingArray(label)
        }
        let bodyStart = text.index(after: open)
        let body = text[bodyStart..<end]
        var values: [Int] = []
        var token = ""
        func flush() {
            guard !token.isEmpty, let value = Int(token) else { return }
            values.append(value)
            token.removeAll(keepingCapacity: true)
        }
        for character in body {
            if character == "-" || character.isNumber {
                token.append(character)
            } else {
                flush()
            }
        }
        flush()
        guard !values.isEmpty, values.count.isMultiple(of: width) else {
            throw SM64MarioFaceSourceGeometryProviderError.invalidArray(label)
        }
        return stride(from: 0, to: values.count, by: width).map { start in
            Array(values[start..<(start + width)])
        }
    }

    private static func parseMaterials(
        _ text: String
    ) throws -> [SM64MarioFaceSourceMaterial] {
        guard let start = text.range(of: "StartGroup(0xE0)"),
              let end = text.range(of: "EndGroup(0xE0)", range: start.upperBound..<text.endIndex) else {
            throw SM64MarioFaceSourceGeometryProviderError.invalidMaterialGroup
        }
        let body = String(text[start.upperBound..<end.lowerBound])
        let pattern = #"SetId\(\s*(\d+)\s*\).*?SetAmbient\(\s*([0-9.]+)\s*,\s*([0-9.]+)\s*,\s*([0-9.]+)\s*\).*?SetDiffuse\(\s*([0-9.]+)\s*,\s*([0-9.]+)\s*,\s*([0-9.]+)\s*\)"#
        let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        let range = NSRange(body.startIndex..<body.endIndex, in: body)
        let matches = regex.matches(in: body, options: [], range: range)
        return try matches.map { match in
            guard match.numberOfRanges == 8 else {
                throw SM64MarioFaceSourceGeometryProviderError.invalidMaterialGroup
            }
            func capture(_ index: Int) throws -> String {
                let range = match.range(at: index)
                guard let swiftRange = Range(range, in: body) else {
                    throw SM64MarioFaceSourceGeometryProviderError.invalidMaterialGroup
                }
                return String(body[swiftRange])
            }
            func quantized(_ index: Int) throws -> UInt32 {
                guard let value = Double(try capture(index)) else {
                    throw SM64MarioFaceSourceGeometryProviderError.invalidMaterialGroup
                }
                return UInt32((value * 1000.0).rounded())
            }
            guard let materialID = UInt32(try capture(1)) else {
                throw SM64MarioFaceSourceGeometryProviderError.invalidMaterialGroup
            }
            return SM64MarioFaceSourceMaterial(
                materialGroupID: 0xE0,
                materialID: materialID,
                ambientRGB1000: [try quantized(2), try quantized(3), try quantized(4)],
                diffuseRGB1000: [try quantized(5), try quantized(6), try quantized(7)]
            )
        }
    }
}

enum SM64MarioFaceSourceGeometryFingerprint {
    static let offset: UInt64 = 1_469_598_103_934_665_603
    static let prime: UInt64 = 1_099_511_628_211

    private static func hash(_ initial: UInt64, _ value: UInt64) -> UInt64 {
        var result = initial
        for byte in 0..<8 {
            result ^= (value >> UInt64(byte * 8)) & 0xFF
            result &*= prime
        }
        return result
    }

    private static func hash(_ initial: UInt64, _ values: [UInt32]) -> UInt64 {
        values.reduce(initial) { hash($0, UInt64($1)) }
    }

    private static func hash(_ initial: UInt64, _ value: UInt32) -> UInt64 {
        hash(initial, UInt64(value))
    }

    static func packet(_ packet: SM64MarioFaceSourceMeshPacket = SM64MarioFaceSourceGeometry.packet) -> UInt64 {
        var result = hash(offset, UInt64(packet.schemaVersion))
        for word in packet.sourceDigestWords { result = hash(result, word) }
        result = hash(result, [
            packet.meshID, packet.shapeID, packet.vertexGroupID, packet.planeGroupID,
            packet.materialGroupID, packet.sourceVertexCount, packet.sourceFaceCount,
            packet.sourceMaterialCount, packet.faceWindowStart, packet.faceWindowCount,
            UInt32(packet.vertices.count), UInt32(packet.materials.count),
        ])
        for vertex in packet.vertices {
            result = hash(result, vertex.sourceIndex)
            result = hash(result, UInt64(bitPattern: Int64(vertex.x)))
            result = hash(result, UInt64(bitPattern: Int64(vertex.y)))
            result = hash(result, UInt64(bitPattern: Int64(vertex.z)))
        }
        for triangle in packet.triangles {
            result = hash(result, triangle.materialID)
            result = hash(result, UInt64(triangle.indices.count))
            for index in triangle.indices { result = hash(result, index) }
        }
        for material in packet.materials {
            result = hash(result, [material.materialGroupID, material.materialID])
            result = hash(result, material.ambientRGB1000)
            result = hash(result, material.diffuseRGB1000)
        }
        return result
    }
}

enum SM64MarioFaceSourceGeometryOracle {
    static let headerRecordID: UInt64 = 0x4d46_7401
    static let digestRecordID: UInt64 = 0x4d46_7402
    static let packetRecordID: UInt64 = 0x4d46_7403
    static let materialRecordID: UInt64 = 0x4d46_7404
    static let domain: UInt32 = 11
    static let kind: UInt32 = 8

    static func records(
        packet: SM64MarioFaceSourceMeshPacket = SM64MarioFaceSourceGeometry.packet,
        simulationTick: UInt64 = 1
    ) throws -> [SM64OracleTraceRecord] {
        let fingerprint = SM64MarioFaceSourceGeometryFingerprint.packet(packet)
        return try [
            SM64OracleTraceRecord(
                simulationTick: simulationTick, domain: domain, recordKind: kind,
                subjectID: UInt64(packet.meshID), recordID: headerRecordID, sequence: 0,
                values: [
                    UInt64(packet.meshID), UInt64(packet.shapeID), UInt64(packet.vertexGroupID),
                    UInt64(packet.planeGroupID), UInt64(packet.materialGroupID),
                    UInt64(packet.sourceVertexCount), UInt64(packet.sourceFaceCount), fingerprint,
                ]
            ),
            SM64OracleTraceRecord(
                simulationTick: simulationTick, domain: domain, recordKind: kind,
                subjectID: UInt64(packet.meshID), recordID: digestRecordID, sequence: 1,
                values: packet.sourceDigestWords
            ),
            SM64OracleTraceRecord(
                simulationTick: simulationTick, domain: domain, recordKind: kind,
                subjectID: UInt64(packet.meshID), recordID: packetRecordID, sequence: 2,
                values: [
                    UInt64(packet.sourceMaterialCount), UInt64(packet.faceWindowStart),
                    UInt64(packet.faceWindowCount), UInt64(packet.vertices.count),
                    UInt64(packet.materials.count),
                ]
            ),
            SM64OracleTraceRecord(
                simulationTick: simulationTick, domain: domain, recordKind: kind,
                subjectID: UInt64(packet.meshID), recordID: materialRecordID, sequence: 3,
                values: [0, 0xE0, 1000, 1000, 1000, 1000, 1000, 1000]
            ),
        ]
    }

    static func fingerprint(_ records: [SM64OracleTraceRecord]) -> UInt64 {
        records.reduce(offset) { $0 ^ $1.canonicalHash &* prime }
    }

    private static let offset = SM64MarioFaceSourceGeometryFingerprint.offset
    private static let prime = SM64MarioFaceSourceGeometryFingerprint.prime
}
