import Foundation

enum SM64MarioFacePayloadBundleError: Error, Equatable, Sendable {
    case invalidMagic
    case unsupportedVersion(UInt32)
    case invalidBankCount(UInt32)
    case truncated
    case invalidAnimationType(UInt32)
    case invalidBank(UInt32)
    case invalidMetadata(UInt32)
    case invalidValueCount(UInt32)
    case trailingBytes
}

struct SM64MarioFacePayloadBank: Equatable, Sendable {
    let componentID: UInt32
    let bank: UInt32
    let count: UInt32
    let type: SM64MarioFaceAnimationType
    let stride: UInt32
    let rawValues: [Int16]

    var byteCount: UInt64 {
        UInt64(rawValues.count) * 2
    }

    func frame(_ sourceFrame: UInt32) -> [Int16]? {
        guard count > 0, stride > 0,
              sourceFrame > 0, sourceFrame <= count else { return nil }
        let start = Int(sourceFrame - 1) * Int(stride)
        let end = start + Int(stride)
        guard end <= rawValues.count else { return nil }
        return Array(rawValues[start..<end])
    }
}

/// Canonical transport for every Mario-face/intro/star animation bank. The
/// bytes are source-backed and may be placed in a source-only content pack;
/// they remain immutable values until a later owner-thread renderer consumes
/// them.
struct SM64MarioFacePayloadBundle: Equatable, Sendable {
    static let magic = Data([0x4D, 0x46, 0x50, 0x42]) // MFPB
    static let version: UInt32 = 1
    static let maximumBanks: UInt32 = 50

    let version: UInt32
    let banks: [SM64MarioFacePayloadBank]

    var totalRawBytes: UInt64 {
        banks.reduce(0) { $0 + $1.byteCount }
    }

    func bank(componentID: UInt32, bank: UInt32) -> SM64MarioFacePayloadBank? {
        banks.first { $0.componentID == componentID && $0.bank == bank }
    }

    func frame(componentID: UInt32, bank: UInt32, sourceFrame: UInt32) -> [Int16]? {
        self.bank(componentID: componentID, bank: bank)?.frame(sourceFrame)
    }

    /// Decodes a resident Q16.16 frame with the source `move_animator`
    /// interpolation and scaled-channel convention. A frame whose adjacent
    /// source value is not resident fails closed.
    func decode(componentID: UInt32, bank: UInt32, frameQ16: UInt32) -> SM64MarioFaceAnimationDecodedFrame? {
        guard let payloadBank = self.bank(componentID: componentID, bank: bank),
              payloadBank.count > 1,
              let payloadType = SM64MarioFaceAnimationPayloadType(rawValue: payloadBank.type.rawValue) else {
            return nil
        }
        let currentFrame = frameQ16 >> 16
        let fractionQ16 = frameQ16 & 0xFFFF
        guard currentFrame > 0, currentFrame < payloadBank.count,
              let current = payloadBank.frame(currentFrame),
              let next = payloadBank.frame(currentFrame + 1) else { return nil }
        let fraction = Float(fractionQ16) / 65_536.0
        var values: [Float] = []
        values.reserveCapacity(current.count)
        for index in current.indices {
            let interpolated = Float(current[index])
                + (Float(next[index]) - Float(current[index])) * fraction
            values.append(index < 3 ? interpolated * 0.1 : interpolated)
        }
        return SM64MarioFaceAnimationDecodedFrame(
            componentID: componentID,
            bank: bank,
            frameQ16: frameQ16,
            currentSourceFrame: currentFrame,
            nextSourceFrame: currentFrame + 1,
            fractionQ16: fractionQ16,
            type: payloadType,
            values: values
        )
    }

    func canonicalBytes() -> Data {
        Self.encode(banks)
    }

    static func encode(_ banks: [SM64MarioFacePayloadBank]) -> Data {
        var data = magic
        appendUInt32(version, to: &data)
        appendUInt32(UInt32(banks.count), to: &data)
        for bank in banks {
            appendUInt32(bank.componentID, to: &data)
            appendUInt32(bank.bank, to: &data)
            appendUInt32(bank.count, to: &data)
            appendUInt32(bank.type.rawValue, to: &data)
            appendUInt32(bank.stride, to: &data)
            appendUInt32(UInt32(bank.rawValues.count), to: &data)
            for value in bank.rawValues {
                appendUInt16(UInt16(bitPattern: value), to: &data)
            }
        }
        return data
    }

    static func decode(_ data: Data) throws -> SM64MarioFacePayloadBundle {
        var reader = Reader(bytes: Array(data))
        guard reader.take(magic.count) == Array(magic) else {
            throw SM64MarioFacePayloadBundleError.invalidMagic
        }
        guard let version = reader.uint32() else {
            throw SM64MarioFacePayloadBundleError.truncated
        }
        guard version == Self.version else {
            throw SM64MarioFacePayloadBundleError.unsupportedVersion(version)
        }
        guard let bankCount = reader.uint32() else {
            throw SM64MarioFacePayloadBundleError.truncated
        }
        guard bankCount == Self.maximumBanks else {
            throw SM64MarioFacePayloadBundleError.invalidBankCount(bankCount)
        }

        var banks: [SM64MarioFacePayloadBank] = []
        banks.reserveCapacity(Int(bankCount))
        for _ in 0..<bankCount {
            guard let componentID = reader.uint32(), let bank = reader.uint32(),
                  let count = reader.uint32(), let typeRaw = reader.uint32(),
                  let stride = reader.uint32(), let valueCount = reader.uint32() else {
                throw SM64MarioFacePayloadBundleError.truncated
            }
            guard bank < 2 else {
                throw SM64MarioFacePayloadBundleError.invalidBank(bank)
            }
            guard let type = SM64MarioFaceAnimationType(rawValue: typeRaw),
                  type == .empty || type == .threeHScaled || type == .sixHScaled else {
                throw SM64MarioFacePayloadBundleError.invalidAnimationType(typeRaw)
            }
            guard let manifest = SM64MarioFaceAnimationResourceManifest.entry(componentID: componentID) else {
                throw SM64MarioFacePayloadBundleError.invalidMetadata(componentID)
            }
            let expectedCount = bank == 0 ? manifest.primaryCount : manifest.secondaryCount
            let expectedType = bank == 0 ? manifest.primaryType : manifest.secondaryType
            let expectedStride = bank == 0 ? manifest.primaryStride : manifest.secondaryStride
            guard count == expectedCount, type == expectedType, stride == expectedStride else {
                throw SM64MarioFacePayloadBundleError.invalidMetadata(componentID)
            }
            let expectedValueCount = count * stride
            guard valueCount == expectedValueCount else {
                throw SM64MarioFacePayloadBundleError.invalidValueCount(valueCount)
            }
            var rawValues: [Int16] = []
            rawValues.reserveCapacity(Int(valueCount))
            for _ in 0..<valueCount {
                guard let raw = reader.uint16() else {
                    throw SM64MarioFacePayloadBundleError.truncated
                }
                rawValues.append(Int16(bitPattern: raw))
            }
            banks.append(.init(
                componentID: componentID,
                bank: bank,
                count: count,
                type: type,
                stride: stride,
                rawValues: rawValues
            ))
        }
        guard reader.offset == reader.bytes.count else {
            throw SM64MarioFacePayloadBundleError.trailingBytes
        }
        let expectedOrder = SM64MarioFaceAnimationResourceManifest.entries.flatMap { entry in
            [
                (entry.componentID, UInt32(0)),
                (entry.componentID, UInt32(1)),
            ]
        }
        guard banks.count == expectedOrder.count,
              zip(banks, expectedOrder).allSatisfy({ bank, expected in
                  bank.componentID == expected.0 && bank.bank == expected.1
              }) else {
            throw SM64MarioFacePayloadBundleError.invalidMetadata(0)
        }
        return .init(version: version, banks: banks)
    }

    private static func appendUInt16(_ value: UInt16, to data: inout Data) {
        var littleEndian = value.littleEndian
        withUnsafeBytes(of: &littleEndian) { data.append(contentsOf: $0) }
    }

    private static func appendUInt32(_ value: UInt32, to data: inout Data) {
        var littleEndian = value.littleEndian
        withUnsafeBytes(of: &littleEndian) { data.append(contentsOf: $0) }
    }

    private struct Reader {
        let bytes: [UInt8]
        var offset: Int = 0

        mutating func take(_ count: Int) -> [UInt8]? {
            guard count >= 0, offset <= bytes.count, count <= bytes.count - offset else { return nil }
            defer { offset += count }
            return Array(bytes[offset..<(offset + count)])
        }

        mutating func uint16() -> UInt16? {
            guard let bytes = take(2) else { return nil }
            return UInt16(bytes[0]) | UInt16(bytes[1]) << 8
        }

        mutating func uint32() -> UInt32? {
            guard let bytes = take(4) else { return nil }
            return UInt32(bytes[0])
                | UInt32(bytes[1]) << 8
                | UInt32(bytes[2]) << 16
                | UInt32(bytes[3]) << 24
        }
    }
}

enum SM64MarioFacePayloadBundleFingerprint {
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
