import Foundation

/// The exact value boundary for the Mario face-shine `G_TEXTURE_GEN` path.
/// Goddard first builds a normalized face normal, averages those normals for
/// every source vertex, quantizes the result to the signed 8-bit RSP normal,
/// and only then derives the generated S/T values.
struct SM64MarioFaceMetalGeneratedCoordinate: Equatable, Sendable {
    let sourceIndex: UInt32
    let normalQ8: [Int8]
    let generatedST: [Int32]

    var normalizedUV: [Float] {
        precondition(generatedST.count == 2)
        // `gDPSetHilite1Tile` uses a 32x32 tile and the PC RDP path converts
        // S/T from 10.5-ish units with an 8-unit tile origin and a 32-unit
        // texel scale. The default origin is the source fallback used when
        // the active Goddard light vector is unavailable.
        let originS: Float = 64 * 8
        let originT: Float = 64 * 8
        let texelScale: Float = 32 * 32
        let bilinearHalfTexel: Float = 0.5 / 32.0
        return [
            (Float(generatedST[0]) - originS) / texelScale + bilinearHalfTexel,
            (Float(generatedST[1]) - originT) / texelScale + bilinearHalfTexel,
        ]
    }
}

struct SM64MarioFaceMetalTextureCoordinatePacket: Equatable, Sendable {
    let schemaVersion: UInt32
    let meshID: UInt32
    let textureID: UInt32
    let textureScaleS: UInt32
    let textureScaleT: UInt32
    let hiliteOriginS: Int32
    let hiliteOriginT: Int32
    let tileWidth: UInt32
    let tileHeight: UInt32
    let vertices: [SM64MarioFaceMetalGeneratedCoordinate]

    var fingerprint: UInt64 {
        SM64MarioFaceMetalTextureCoordinateFingerprint.packet(self)
    }
}

enum SM64MarioFaceMetalTextureCoordinateBuilder {
    static let textureID: UInt32 = 0x300
    static let textureScaleS: UInt32 = 0x07C0
    static let textureScaleT: UInt32 = 0x07C0
    static let hiliteOriginS: Int32 = 64
    static let hiliteOriginT: Int32 = 64
    static let tileWidth: UInt32 = 32
    static let tileHeight: UInt32 = 32

    static func make(
        source: SM64MarioFaceSourceMeshPacket,
        textureID: UInt32 = Self.textureID
    ) -> SM64MarioFaceMetalTextureCoordinatePacket? {
        guard source.schemaVersion == 2,
              source.meshID == 1,
              source.sourceVertexCount == 440,
              source.sourceFaceCount == 877,
              source.vertices.count == Int(source.sourceVertexCount),
              source.triangles.count == Int(source.sourceFaceCount),
              textureID == Self.textureID else {
            return nil
        }

        let positions = Dictionary(uniqueKeysWithValues: source.vertices.map {
            ($0.sourceIndex, SIMD3<Float>(Float($0.x), Float($0.y), Float($0.z)))
        })
        var accumulated = Dictionary(
            uniqueKeysWithValues: source.vertices.map { ($0.sourceIndex, SIMD3<Float>(repeating: 0)) }
        )
        for triangle in source.triangles {
            guard triangle.indices.count == 3,
                  let p0 = positions[triangle.indices[0]],
                  let p1 = positions[triangle.indices[1]],
                  let p2 = positions[triangle.indices[2]] else {
                return nil
            }
            // This deliberately mirrors calc_face_normal: the source uses
            // (p1-p0) x (p2-p1), multiplies by 1000, then normalizes.
            let a = p1 - p0
            let b = p2 - p1
            let cross = SIMD3<Float>(
                (a.y * b.z - a.z * b.y) * 1000,
                (a.z * b.x - a.x * b.z) * 1000,
                (a.x * b.y - a.y * b.x) * 1000
            )
            let faceNormal = normalize(cross)
            for index in triangle.indices {
                accumulated[index, default: SIMD3<Float>(repeating: 0)] += faceNormal
            }
        }

        var coordinates: [SM64MarioFaceMetalGeneratedCoordinate] = []
        coordinates.reserveCapacity(source.vertices.count)
        for vertex in source.vertices {
            let normal = normalize(accumulated[vertex.sourceIndex] ?? SIMD3<Float>(repeating: 0))
            // `set_Vtx_norm_buf_2` uses a C cast to s8, i.e. truncation toward
            // zero rather than rounding. The signed range is guaranteed by a
            // normalized vector, but keep the clamp explicit at the boundary.
            let quantized = [
                Int8(clamping: Int(normal.x * 127.0)),
                Int8(clamping: Int(normal.y * 127.0)),
                Int8(clamping: Int(normal.z * 127.0)),
            ]
            let dotS = Float(quantized[0])
            let dotT = Float(quantized[1])
            let generatedS = Int32(((dotS / 127.0 + 1.0) / 4.0 * Float(textureScaleS)))
            let generatedT = Int32(((dotT / 127.0 + 1.0) / 4.0 * Float(textureScaleT)))
            coordinates.append(.init(
                sourceIndex: vertex.sourceIndex,
                normalQ8: quantized,
                generatedST: [generatedS, generatedT]
            ))
        }
        return .init(
            schemaVersion: 1,
            meshID: source.meshID,
            textureID: textureID,
            textureScaleS: textureScaleS,
            textureScaleT: textureScaleT,
            hiliteOriginS: hiliteOriginS,
            hiliteOriginT: hiliteOriginT,
            tileWidth: tileWidth,
            tileHeight: tileHeight,
            vertices: coordinates
        )
    }

    private static func normalize(_ value: SIMD3<Float>) -> SIMD3<Float> {
        let length = sqrt(value.x * value.x + value.y * value.y + value.z * value.z)
        guard length > 0 else { return SIMD3<Float>(repeating: 0) }
        return value / length
    }
}

extension SM64MarioFaceSourceMeshPacket {
    /// Expands the source triangles into the renderer's non-indexed vertex
    /// stream while carrying the exact generated coordinates next to each
    /// source position. The material color remains the authored source input.
    func debugMetalTexturedVertexFloats(
        coordinates: SM64MarioFaceMetalTextureCoordinatePacket
    ) -> [Float] {
        let byIndex = Dictionary(uniqueKeysWithValues: vertices.map { ($0.sourceIndex, $0) })
        let coordinateByIndex = Dictionary(uniqueKeysWithValues: coordinates.vertices.map {
            ($0.sourceIndex, $0)
        })
        let materialByID = Dictionary(uniqueKeysWithValues: materials.map { ($0.materialID, $0) })
        let projectionScale: Float = 1.0 / 1024.0
        let depthScale: Float = 1.0 / 2048.0
        var result: [Float] = []
        result.reserveCapacity(triangles.count * 3 * 9)
        for triangle in triangles {
            let material = materialByID[triangle.materialID]
            let color = (material?.diffuseRGB1000 ?? [0, 0, 0]).map { Float($0) / 1000.0 }
            for index in triangle.indices {
                guard let vertex = byIndex[index],
                      let coordinate = coordinateByIndex[index] else { continue }
                result.append(Float(vertex.x) * projectionScale)
                result.append(Float(vertex.y) * projectionScale)
                result.append(Float(vertex.z) * depthScale)
                result.append(1.0)
                result.append(contentsOf: coordinate.normalizedUV)
                result.append(contentsOf: color)
            }
        }
        return result
    }
}

enum SM64MarioFaceMetalTextureCoordinateFingerprint {
    static let offset: UInt64 = 1_469_598_103_934_665_603
    static let prime: UInt64 = 1_099_511_628_211

    private static func hash(_ initial: UInt64, _ value: UInt64) -> UInt64 {
        var result = initial
        for byte in 0..<8 {
            result ^= (value >> UInt64(byte * 8)) & 0xff
            result &*= prime
        }
        return result
    }

    static func packet(_ packet: SM64MarioFaceMetalTextureCoordinatePacket) -> UInt64 {
        var result = hash(offset, UInt64(packet.schemaVersion))
        for value in [
            packet.meshID, packet.textureID, packet.textureScaleS, packet.textureScaleT,
            packet.tileWidth, packet.tileHeight, UInt32(packet.vertices.count),
        ] {
            result = hash(result, UInt64(value))
        }
        result = hash(result, UInt64(bitPattern: Int64(packet.hiliteOriginS)))
        result = hash(result, UInt64(bitPattern: Int64(packet.hiliteOriginT)))
        for vertex in packet.vertices {
            result = hash(result, UInt64(vertex.sourceIndex))
            for value in vertex.normalQ8 {
                result = hash(result, UInt64(bitPattern: Int64(value)))
            }
            for value in vertex.generatedST {
                result = hash(result, UInt64(bitPattern: Int64(value)))
            }
        }
        return result
    }
}

enum SM64MarioFaceMetalTextureCoordinateOracle {
    static let domain: UInt32 = 11
    static let recordKind: UInt32 = 8
    static let headerRecordID: UInt64 = 0x4D46_7901
    static let vertexRecordBase: UInt64 = 0x4D46_7A00
    static let trailerRecordID: UInt64 = 0x4D46_7902

    static func records(
        packet: SM64MarioFaceMetalTextureCoordinatePacket,
        simulationTick: UInt64 = 1
    ) throws -> [SM64OracleTraceRecord] {
        var records: [SM64OracleTraceRecord] = []
        records.reserveCapacity(packet.vertices.count + 2)
        records.append(try SM64OracleTraceRecord(
            simulationTick: simulationTick, domain: domain, recordKind: recordKind,
            subjectID: UInt64(packet.meshID), recordID: headerRecordID, sequence: 0,
            values: [
                UInt64(packet.schemaVersion), UInt64(packet.meshID), UInt64(packet.textureID),
                UInt64(packet.textureScaleS), UInt64(packet.textureScaleT),
                UInt64(bitPattern: Int64(packet.hiliteOriginS)),
                UInt64(bitPattern: Int64(packet.hiliteOriginT)),
                packet.fingerprint,
            ]
        ))
        for (index, vertex) in packet.vertices.enumerated() {
            records.append(try SM64OracleTraceRecord(
                simulationTick: simulationTick, domain: domain, recordKind: recordKind,
                subjectID: UInt64(packet.meshID), recordID: vertexRecordBase | UInt64(index),
                sequence: UInt32(index + 1),
                values: [
                    UInt64(vertex.sourceIndex),
                    UInt64(bitPattern: Int64(vertex.normalQ8[0])),
                    UInt64(bitPattern: Int64(vertex.normalQ8[1])),
                    UInt64(bitPattern: Int64(vertex.normalQ8[2])),
                    UInt64(bitPattern: Int64(vertex.generatedST[0])),
                    UInt64(bitPattern: Int64(vertex.generatedST[1])),
                ]
            ))
        }
        records.append(try SM64OracleTraceRecord(
            simulationTick: simulationTick, domain: domain, recordKind: recordKind,
            subjectID: UInt64(packet.meshID), recordID: trailerRecordID,
            sequence: UInt32(records.count),
            values: [
                UInt64(packet.vertices.count), packet.fingerprint,
                UInt64(packet.textureScaleS), UInt64(packet.textureScaleT),
                UInt64(packet.tileWidth), UInt64(packet.tileHeight),
                UInt64(bitPattern: Int64(packet.hiliteOriginS)),
                UInt64(bitPattern: Int64(packet.hiliteOriginT)),
            ]
        ))
        return records
    }

    static func fingerprint(_ records: [SM64OracleTraceRecord]) -> UInt64 {
        records.reduce(SM64MarioFaceMetalTextureCoordinateFingerprint.offset) {
            $0 ^ ($1.canonicalHash &* SM64MarioFaceMetalTextureCoordinateFingerprint.prime)
        }
    }
}
