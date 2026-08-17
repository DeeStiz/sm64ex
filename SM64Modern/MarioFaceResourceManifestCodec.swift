import Foundation

enum SM64MarioFaceResourceManifestCodecError: Error, Equatable, Sendable {
    case invalidMagic
    case unsupportedVersion(UInt32)
    case invalidEntryCount(UInt32)
    case truncated
    case invalidUTF8
    case invalidAnimationType(UInt32)
    case trailingBytes
}

/// Canonical little-endian manifest transport used by a future content-pack
/// section. It carries metadata only; payload bytes are intentionally outside
/// this bounded codec.
enum SM64MarioFaceResourceManifestCodec {
    static let magic = Data([0x4D, 0x46, 0x52, 0x4D]) // MFRM
    static let version: UInt32 = 1
    static let maximumEntries: UInt32 = 25

    private static func appendUInt32(_ value: UInt32, to data: inout Data) {
        var littleEndian = value.littleEndian
        withUnsafeBytes(of: &littleEndian) { data.append(contentsOf: $0) }
    }

    private static func appendString(_ value: String, to data: inout Data) {
        let bytes = Array(value.utf8)
        appendUInt32(UInt32(bytes.count), to: &data)
        data.append(contentsOf: bytes)
    }

    static func encode(_ entries: [SM64MarioFaceAnimationResourceManifestEntry]) -> Data {
        var data = magic
        appendUInt32(version, to: &data)
        appendUInt32(UInt32(entries.count), to: &data)
        for entry in entries {
            for value in [
                entry.componentID, entry.animatorID, entry.primaryCount,
                entry.primaryType.rawValue, entry.secondaryCount,
                entry.secondaryType.rawValue, entry.primaryStride, entry.secondaryStride,
            ] {
                appendUInt32(value, to: &data)
            }
            appendString(entry.sourcePath, to: &data)
            appendString(entry.primarySymbol, to: &data)
            appendString(entry.secondarySymbol, to: &data)
        }
        return data
    }

    private struct Reader {
        let bytes: [UInt8]
        var offset: Int = 0

        mutating func take(_ count: Int) -> [UInt8]? {
            guard count >= 0, offset <= bytes.count, count <= bytes.count - offset else { return nil }
            defer { offset += count }
            return Array(bytes[offset..<(offset + count)])
        }

        mutating func uint32() -> UInt32? {
            guard let bytes = take(4) else { return nil }
            return UInt32(bytes[0]) | UInt32(bytes[1]) << 8 | UInt32(bytes[2]) << 16 | UInt32(bytes[3]) << 24
        }

        mutating func string() throws -> String {
            guard let length = uint32(), let bytes = take(Int(length)) else {
                throw SM64MarioFaceResourceManifestCodecError.truncated
            }
            guard let value = String(bytes: bytes, encoding: .utf8) else {
                throw SM64MarioFaceResourceManifestCodecError.invalidUTF8
            }
            return value
        }
    }

    static func decode(_ data: Data) throws -> [SM64MarioFaceAnimationResourceManifestEntry] {
        var reader = Reader(bytes: Array(data))
        guard reader.take(magic.count) == Array(magic) else {
            throw SM64MarioFaceResourceManifestCodecError.invalidMagic
        }
        guard let version = reader.uint32() else { throw SM64MarioFaceResourceManifestCodecError.truncated }
        guard version == Self.version else { throw SM64MarioFaceResourceManifestCodecError.unsupportedVersion(version) }
        guard let count = reader.uint32() else { throw SM64MarioFaceResourceManifestCodecError.truncated }
        guard count <= maximumEntries else { throw SM64MarioFaceResourceManifestCodecError.invalidEntryCount(count) }

        var entries: [SM64MarioFaceAnimationResourceManifestEntry] = []
        entries.reserveCapacity(Int(count))
        for _ in 0..<count {
            guard let componentID = reader.uint32(), let animatorID = reader.uint32(),
                  let primaryCount = reader.uint32(), let primaryTypeRaw = reader.uint32(),
                  let secondaryCount = reader.uint32(), let secondaryTypeRaw = reader.uint32(),
                  let primaryStride = reader.uint32(), let secondaryStride = reader.uint32() else {
                throw SM64MarioFaceResourceManifestCodecError.truncated
            }
            guard let primaryType = SM64MarioFaceAnimationType(rawValue: primaryTypeRaw),
                  let secondaryType = SM64MarioFaceAnimationType(rawValue: secondaryTypeRaw) else {
                throw SM64MarioFaceResourceManifestCodecError.invalidAnimationType(
                    primaryTypeRaw == 0 ? secondaryTypeRaw : primaryTypeRaw
                )
            }
            let sourcePath = try reader.string()
            let primarySymbol = try reader.string()
            let secondarySymbol = try reader.string()
            entries.append(.init(
                componentID: componentID,
                animatorID: animatorID,
                sourcePath: sourcePath,
                primarySymbol: primarySymbol,
                secondarySymbol: secondarySymbol,
                primaryCount: primaryCount,
                primaryType: primaryType,
                secondaryCount: secondaryCount,
                secondaryType: secondaryType,
                primaryStride: primaryStride,
                secondaryStride: secondaryStride
            ))
        }
        guard reader.offset == reader.bytes.count else {
            throw SM64MarioFaceResourceManifestCodecError.trailingBytes
        }
        return entries
    }
}

enum SM64MarioFaceResourceManifestCodecFingerprint {
    static let offset: UInt64 = 1_469_598_103_934_665_603
    static let prime: UInt64 = 1_099_511_628_211

    static func bytes(_ data: Data) -> UInt64 {
        var result = offset
        for byte in data {
            result ^= UInt64(byte)
            result &*= prime
        }
        return result
    }
}
