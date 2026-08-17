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
