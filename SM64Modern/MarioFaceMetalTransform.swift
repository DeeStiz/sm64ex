import Foundation

/// Render-facing transform values for one source Mario-face route. Matrices
/// are column-major so the packet can be copied directly into a Metal
/// `float4x4`; all source animation/camera/light facts remain value-only.
struct SM64MarioFaceMetalTransformPacket: Equatable, Sendable {
    let schemaVersion: UInt32
    let routeID: UInt32
    let sourceMeshID: UInt32
    let viewportWidth: UInt32
    let viewportHeight: UInt32
    let animationFrameQ16: UInt32
    let animationComponentID: UInt32
    let animationValues: [Float]
    let modelMatrix: [Float]
    let viewMatrix: [Float]
    let projectionMatrix: [Float]
    let clipMatrix: [Float]
    let lightDirection: [Float]
    let lightColor: [Float]

    var gpuUniformFloats: [Float] {
        clipMatrix + lightDirection + lightColor
    }
}

/// Builds the first render-consumable transform packet from the already
/// qualified M30j/M30m values. The root `0xE2` six-halfword channel is the
/// authored Mario intro/master attachment: its first three values are
/// degrees (the source 0.1 scale has already been decoded) and its last three
/// values are source-space translation. The route camera metadata supplies
/// viewport/scale/light direction; no C graph pointer or Metal handle enters
/// this packet.
enum SM64MarioFaceMetalTransformPacketBuilder {
    /// The first authored `animdata_mario_intro_1` frame from
    /// `src/goddard/dynlists/anim_group_2.c`, decoded with the source's 0.1
    /// scale for the first three (rotation) values. This fallback keeps the
    /// native source-geometry gate independent of a generated content-pack
    /// file while still fencing the exact checked-in source value.
    static let sourceMarioIntroFrame1: [Float] = [112.8, 0, 0, 0, 0, -20_010]

    static func make(
        routeID: SM64MarioFaceGoddardRouteID,
        face: SM64MarioFaceRenderFramePacket
    ) -> SM64MarioFaceMetalTransformPacket? {
        let animation = face.animations.first(where: {
            $0.componentID == 0xE2 && $0.available && $0.values.count == 6
        })
        return make(
            routeID: routeID,
            animationFrameQ16: face.animationFrameQ16,
            animationValues: animation?.values ?? sourceMarioIntroFrame1
        )
    }

    static func make(
        routeID: SM64MarioFaceGoddardRouteID,
        animationFrameQ16: UInt32,
        animationValues: [Float] = sourceMarioIntroFrame1
    ) -> SM64MarioFaceMetalTransformPacket? {
        guard let route = SM64MarioFaceRouteResourceCatalog.route(routeID),
              animationValues.count == 6 else { return nil }
        let camera = SM64MarioFaceRouteResourceCatalog.camera(for: route)
        let rotationDegrees = Array(animationValues[0..<3])
        let translation = Array(animationValues[3..<6])
        let model = multiply(
            multiply(rotationX(degrees: rotationDegrees[0]), rotationY(degrees: rotationDegrees[1])),
            multiply(rotationZ(degrees: rotationDegrees[2]), translationMatrix(translation))
        )

        // M30m's route record is a 320x240 authored view. The main renderer
        // scale is applied to the source-unit normalization; the view cancels
        // the authored root translation so the face remains in camera space.
        let scale = Float(camera.mainScale100000) / 100_000.0
        let unit = scale / 1024.0
        let projection = diagonalMatrix(x: unit, y: unit, z: 1.0 / 32_768.0)
        let view = translationMatrix(
            [-translation[0], -translation[1], -translation[2]]
        )
        let clip = multiply(projection, multiply(view, model))

        let direction = normalize(camera.lightDirection.map(Float.init))
        let catalogLightColors = SM64MarioFaceResourceCatalog.lights.map {
            $0.diffuseRGB1000.map { Float($0) / 1000.0 }
        }
        let lightColor: [Float]
        if catalogLightColors.isEmpty {
            lightColor = [1, 1, 1, 1]
        } else {
            let count = Float(catalogLightColors.count)
            lightColor = [
                catalogLightColors.reduce(0) { $0 + $1[0] } / count,
                catalogLightColors.reduce(0) { $0 + $1[1] } / count,
                catalogLightColors.reduce(0) { $0 + $1[2] } / count,
                1,
            ]
        }
        return SM64MarioFaceMetalTransformPacket(
            schemaVersion: 1,
            routeID: routeID.rawValue,
            sourceMeshID: 1,
            viewportWidth: camera.viewportWidth,
            viewportHeight: camera.viewportHeight,
            animationFrameQ16: animationFrameQ16,
            animationComponentID: 0xE2,
            animationValues: animationValues,
            modelMatrix: model,
            viewMatrix: view,
            projectionMatrix: projection,
            clipMatrix: clip,
            lightDirection: direction + [0],
            lightColor: lightColor
        )
    }

    private static func normalize(_ values: [Float]) -> [Float] {
        let length = sqrt(values.reduce(0) { $0 + $1 * $1 })
        guard length > 0 else { return [0, 0, 1] }
        return values.map { $0 / length }
    }

    private static func identityMatrix() -> [Float] {
        [
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1,
        ]
    }

    private static func diagonalMatrix(x: Float, y: Float, z: Float) -> [Float] {
        [
            x, 0, 0, 0,
            0, y, 0, 0,
            0, 0, z, 0,
            0, 0, 0, 1,
        ]
    }

    private static func translationMatrix(_ values: [Float]) -> [Float] {
        var result = identityMatrix()
        result[12] = values[0]
        result[13] = values[1]
        result[14] = values[2]
        return result
    }

    private static func rotationX(degrees: Float) -> [Float] {
        let radians = Double(degrees) * .pi / 180.0
        let c = Float(cos(radians))
        let s = Float(sin(radians))
        return [1, 0, 0, 0, 0, c, s, 0, 0, -s, c, 0, 0, 0, 0, 1]
    }

    private static func rotationY(degrees: Float) -> [Float] {
        let radians = Double(degrees) * .pi / 180.0
        let c = Float(cos(radians))
        let s = Float(sin(radians))
        return [c, 0, -s, 0, 0, 1, 0, 0, s, 0, c, 0, 0, 0, 0, 1]
    }

    private static func rotationZ(degrees: Float) -> [Float] {
        let radians = Double(degrees) * .pi / 180.0
        let c = Float(cos(radians))
        let s = Float(sin(radians))
        return [c, s, 0, 0, -s, c, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]
    }

    private static func multiply(_ lhs: [Float], _ rhs: [Float]) -> [Float] {
        precondition(lhs.count == 16 && rhs.count == 16)
        var result = Array(repeating: Float(0), count: 16)
        for column in 0..<4 {
            for row in 0..<4 {
                var value: Float = 0
                for index in 0..<4 {
                    value += lhs[index * 4 + row] * rhs[column * 4 + index]
                }
                result[column * 4 + row] = value
            }
        }
        return result
    }
}

enum SM64MarioFaceMetalTransformFingerprint {
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

    static func packet(_ packet: SM64MarioFaceMetalTransformPacket) -> UInt64 {
        var result = hash(offset, UInt64(packet.schemaVersion))
        result = hash(result, UInt64(packet.routeID))
        result = hash(result, UInt64(packet.sourceMeshID))
        result = hash(result, UInt64(packet.viewportWidth))
        result = hash(result, UInt64(packet.viewportHeight))
        result = hash(result, UInt64(packet.animationFrameQ16))
        result = hash(result, UInt64(packet.animationComponentID))
        result = hash(result, UInt64(packet.animationValues.count))
        for value in packet.animationValues { result = hash(result, UInt64(value.bitPattern)) }
        for matrix in [packet.modelMatrix, packet.viewMatrix, packet.projectionMatrix, packet.clipMatrix] {
            result = hash(result, UInt64(matrix.count))
            for value in matrix { result = hash(result, UInt64(value.bitPattern)) }
        }
        result = hash(result, UInt64(packet.lightDirection.count))
        for value in packet.lightDirection { result = hash(result, UInt64(value.bitPattern)) }
        result = hash(result, UInt64(packet.lightColor.count))
        for value in packet.lightColor { result = hash(result, UInt64(value.bitPattern)) }
        return result
    }
}

enum SM64MarioFaceMetalTransformOracle {
    static let domain: UInt32 = 11
    static let recordKind: UInt32 = 8
    static let packetRecordID: UInt64 = 0x4D46_7601
    static let matrixRecordID: UInt64 = 0x4D46_7602
    static let lightRecordID: UInt64 = 0x4D46_7604

    static func records(
        packet: SM64MarioFaceMetalTransformPacket,
        simulationTick: UInt64 = 1
    ) throws -> [SM64OracleTraceRecord] {
        let packetFingerprint = SM64MarioFaceMetalTransformFingerprint.packet(packet)
        let matrixBits = packet.clipMatrix.map { UInt64($0.bitPattern) }
        let lightBits = (packet.lightDirection + packet.lightColor).map { UInt64($0.bitPattern) }
        return try [
            SM64OracleTraceRecord(
                simulationTick: simulationTick, domain: domain, recordKind: recordKind,
                subjectID: UInt64(packet.routeID), recordID: packetRecordID, sequence: 0,
                values: [
                    UInt64(packet.schemaVersion), UInt64(packet.routeID),
                    UInt64(packet.sourceMeshID), UInt64(packet.viewportWidth),
                    UInt64(packet.viewportHeight), UInt64(packet.animationFrameQ16),
                    UInt64(packet.animationComponentID), packetFingerprint,
                ]
            ),
            SM64OracleTraceRecord(
                simulationTick: simulationTick, domain: domain, recordKind: recordKind,
                subjectID: UInt64(packet.routeID), recordID: matrixRecordID, sequence: 1,
                values: Array(matrixBits[0..<8])
            ),
            SM64OracleTraceRecord(
                simulationTick: simulationTick, domain: domain, recordKind: recordKind,
                subjectID: UInt64(packet.routeID), recordID: matrixRecordID + 1, sequence: 2,
                values: Array(matrixBits[8..<16])
            ),
            SM64OracleTraceRecord(
                simulationTick: simulationTick, domain: domain, recordKind: recordKind,
                subjectID: UInt64(packet.routeID), recordID: lightRecordID, sequence: 3,
                values: lightBits
            ),
        ]
    }

    static func fingerprint(_ records: [SM64OracleTraceRecord]) -> UInt64 {
        records.reduce(SM64MarioFaceMetalTransformFingerprint.offset) {
            $0 ^ $1.canonicalHash &* SM64MarioFaceMetalTransformFingerprint.prime
        }
    }
}
