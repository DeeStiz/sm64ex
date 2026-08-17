import Foundation

/// Complete source-backed draw commands for one Mario-face route. The packet
/// is intentionally value-only: a renderer may bind Metal handles later, but
/// the C↔Swift parity boundary compares every authored triangle first.
struct SM64MarioFaceMetalDrawCommand: Equatable, Sendable {
    let sequence: UInt32
    let materialID: UInt32
    let indices: [UInt32]
    let textureID: UInt32
    let samplerPacked: UInt32
}

struct SM64MarioFaceMetalDrawListPacket: Equatable, Sendable {
    let schemaVersion: UInt32
    let routeID: UInt32
    let meshID: UInt32
    let sourceFaceCount: UInt32
    let commands: [SM64MarioFaceMetalDrawCommand]
    let textureBinding: SM64MarioFaceMetalTextureBinding
    let transformFingerprint: UInt64

    var materialIndexCount: UInt32 { UInt32(commands.count * 3) }

    var materialIndexValues: [UInt16] {
        commands.flatMap { command in
            Array(repeating: UInt16(command.materialID), count: command.indices.count)
        }
    }
}

enum SM64MarioFaceMetalDrawListBuilder {
    static func make(
        source: SM64MarioFaceSourceMeshPacket,
        routeID: SM64MarioFaceGoddardRouteID,
        binding: SM64MarioFaceMetalBindingPacket,
        transform: SM64MarioFaceMetalTransformPacket
    ) -> SM64MarioFaceMetalDrawListPacket? {
        guard source.schemaVersion == 2,
              source.meshID == 1,
              source.sourceFaceCount == 877,
              source.triangles.count == 877,
              binding.route.routeID == routeID,
              transform.routeID == routeID.rawValue,
              transform.sourceMeshID == source.meshID,
              let texture = binding.textures.first(where: { $0.family == .faceShine }) else {
            return nil
        }
        let commands = source.triangles.enumerated().map { index, triangle in
            SM64MarioFaceMetalDrawCommand(
                sequence: UInt32(index),
                materialID: triangle.materialID,
                indices: triangle.indices,
                textureID: texture.textureID,
                samplerPacked: texture.sampler.packed
            )
        }
        return SM64MarioFaceMetalDrawListPacket(
            schemaVersion: 1,
            routeID: routeID.rawValue,
            meshID: source.meshID,
            sourceFaceCount: source.sourceFaceCount,
            commands: commands,
            textureBinding: texture,
            transformFingerprint: SM64MarioFaceMetalTransformFingerprint.packet(transform)
        )
    }
}

enum SM64MarioFaceMetalDrawListFingerprint {
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

    static func texture(_ binding: SM64MarioFaceMetalTextureBinding) -> UInt64 {
        var result = hash(offset, UInt64(binding.textureID))
        for value in [
            binding.formatCode, binding.dimensionsCode, binding.identityCode,
            binding.policyCode, binding.sampler.packed,
        ] {
            result = hash(result, UInt64(value))
        }
        return result
    }

    static func materialIndices(_ packet: SM64MarioFaceMetalDrawListPacket) -> UInt64 {
        packet.materialIndexValues.reduce(hash(offset, UInt64(packet.materialIndexCount))) {
            hash($0, UInt64($1))
        }
    }

    static func sourceIndices(_ packet: SM64MarioFaceMetalDrawListPacket) -> UInt64 {
        packet.commands.reduce(hash(offset, UInt64(packet.commands.count))) { result, command in
            command.indices.reduce(hash(result, UInt64(command.sequence))) {
                hash($0, UInt64($1))
            }
        }
    }

    static func drawList(_ packet: SM64MarioFaceMetalDrawListPacket) -> UInt64 {
        var result = hash(offset, UInt64(packet.schemaVersion))
        for value in [
            packet.routeID, packet.meshID, packet.sourceFaceCount,
            UInt32(packet.commands.count), packet.textureBinding.textureID,
            packet.textureBinding.sampler.packed,
        ] {
            result = hash(result, UInt64(value))
        }
        result = hash(result, transform(packet))
        result = hash(result, texture(packet.textureBinding))
        for command in packet.commands {
            result = hash(result, UInt64(command.sequence))
            result = hash(result, UInt64(command.materialID))
            result = hash(result, UInt64(command.indices.count))
            for index in command.indices { result = hash(result, UInt64(index)) }
            result = hash(result, UInt64(command.textureID))
            result = hash(result, UInt64(command.samplerPacked))
        }
        return result
    }

    static func transform(_ packet: SM64MarioFaceMetalDrawListPacket) -> UInt64 {
        packet.transformFingerprint
    }
}

enum SM64MarioFaceMetalDrawListOracle {
    static let domain: UInt32 = 11
    static let recordKind: UInt32 = 8
    static let headerRecordID: UInt64 = 0x4D46_7701
    static let textureRecordID: UInt64 = 0x4D46_7702
    static let trailerRecordID: UInt64 = 0x4D46_7703
    static let drawRecordBase: UInt64 = 0x4D46_7800

    static func records(
        packet: SM64MarioFaceMetalDrawListPacket,
        simulationTick: UInt64 = 1
    ) throws -> [SM64OracleTraceRecord] {
        let textureFingerprint = SM64MarioFaceMetalDrawListFingerprint.texture(packet.textureBinding)
        let drawFingerprint = SM64MarioFaceMetalDrawListFingerprint.drawList(packet)
        let materialIndexFingerprint = SM64MarioFaceMetalDrawListFingerprint.materialIndices(packet)
        let sourceIndexFingerprint = SM64MarioFaceMetalDrawListFingerprint.sourceIndices(packet)
        var records: [SM64OracleTraceRecord] = []
        records.reserveCapacity(packet.commands.count + 3)
        records.append(try SM64OracleTraceRecord(
            simulationTick: simulationTick, domain: domain, recordKind: recordKind,
            subjectID: UInt64(packet.routeID), recordID: headerRecordID, sequence: 0,
            values: [
                UInt64(packet.schemaVersion), UInt64(packet.routeID), UInt64(packet.meshID),
                UInt64(packet.sourceFaceCount), UInt64(packet.commands.count),
                UInt64(packet.textureBinding.textureID),
                UInt64(packet.textureBinding.sampler.packed), drawFingerprint,
            ]
        ))
        records.append(try SM64OracleTraceRecord(
            simulationTick: simulationTick, domain: domain, recordKind: recordKind,
            subjectID: UInt64(packet.routeID), recordID: textureRecordID, sequence: 1,
            values: [
                UInt64(packet.textureBinding.textureID),
                UInt64(packet.textureBinding.formatCode),
                UInt64(packet.textureBinding.dimensionsCode),
                UInt64(packet.textureBinding.identityCode),
                UInt64(packet.textureBinding.policyCode),
                UInt64(packet.textureBinding.sampler.packed),
                UInt64(packet.textureBinding.width * packet.textureBinding.height * 4),
                UInt64(packet.textureBinding.sourceBitsPerTexel),
            ]
        ))
        for command in packet.commands {
            records.append(try SM64OracleTraceRecord(
                simulationTick: simulationTick, domain: domain, recordKind: recordKind,
                subjectID: UInt64(packet.routeID),
                recordID: drawRecordBase | UInt64(command.sequence),
                sequence: command.sequence + 2,
                values: [
                    UInt64(command.sequence), UInt64(command.materialID),
                    UInt64(command.indices[0]), UInt64(command.indices[1]),
                    UInt64(command.indices[2]), UInt64(command.textureID),
                    UInt64(command.samplerPacked),
                ]
            ))
        }
        records.append(try SM64OracleTraceRecord(
            simulationTick: simulationTick, domain: domain, recordKind: recordKind,
            subjectID: UInt64(packet.routeID), recordID: trailerRecordID,
            sequence: UInt32(records.count),
            values: [
                UInt64(packet.commands.count), UInt64(packet.materialIndexCount),
                materialIndexFingerprint, sourceIndexFingerprint, textureFingerprint,
                drawFingerprint, packet.transformFingerprint, UInt64(records.count + 1),
            ]
        ))
        return records
    }

    static func fingerprint(_ records: [SM64OracleTraceRecord]) -> UInt64 {
        records.reduce(SM64MarioFaceMetalDrawListFingerprint.offset) {
            $0 ^ ($1.canonicalHash &* SM64MarioFaceMetalDrawListFingerprint.prime)
        }
    }
}
