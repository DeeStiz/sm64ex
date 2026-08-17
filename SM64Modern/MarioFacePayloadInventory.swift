import Foundation

struct SM64MarioFacePayloadInventoryRow: Equatable, Sendable {
    let componentID: UInt32
    let bank: UInt32
    let count: Int32
    let type: UInt32
    let stride: UInt32
    let byteCount: UInt64
    let bankFingerprint: UInt64
}

struct SM64MarioFacePayloadInventory: Equatable, Sendable {
    let version: UInt32
    let channelCount: UInt32
    let rows: [SM64MarioFacePayloadInventoryRow]
    let totalBytes: UInt64
    let aggregateFingerprint: UInt64

    static func parse(_ text: String) throws -> SM64MarioFacePayloadInventory {
        let lines = text.split(whereSeparator: { $0.isNewline }).map(String.init)
        guard let header = lines.first?.split(separator: "|", omittingEmptySubsequences: false),
              header.count == 3, header[0] == "SM64FACEINV",
              let version = UInt32(header[1]), let channelCount = UInt32(header[2]) else {
            throw NSError(domain: "SM64MarioFacePayloadInventory", code: 1)
        }
        guard version == 1, channelCount == 25 else {
            throw NSError(domain: "SM64MarioFacePayloadInventory", code: 2)
        }
        guard lines.count == 1 + Int(channelCount) * 2 + 1 else {
            throw NSError(domain: "SM64MarioFacePayloadInventory", code: 3)
        }
        var rows: [SM64MarioFacePayloadInventoryRow] = []
        rows.reserveCapacity(Int(channelCount) * 2)
        for line in lines.dropFirst().dropLast() {
            let fields = line.split(separator: "|", omittingEmptySubsequences: false)
            guard fields.count == 8, fields[0] == "ROW",
                  let componentID = UInt32(fields[1]), let bank = UInt32(fields[2]),
                  let count = Int32(fields[3]), let type = UInt32(fields[4]),
                  let stride = UInt32(fields[5]), let byteCount = UInt64(fields[6]),
                  let bankFingerprint = parseHex(fields[7]) else {
                throw NSError(domain: "SM64MarioFacePayloadInventory", code: 4)
            }
            guard bank < 2, count >= 0, (count == 0 ? stride == 0 : stride > 0),
                  byteCount == UInt64(count) * UInt64(stride) * 2,
                  (count == 0 ? bankFingerprint == 0 : bankFingerprint != 0) else {
                throw NSError(domain: "SM64MarioFacePayloadInventory", code: 5)
            }
            rows.append(.init(
                componentID: componentID, bank: bank, count: count, type: type,
                stride: stride, byteCount: byteCount, bankFingerprint: bankFingerprint
            ))
        }
        guard let total = lines.last?.split(separator: "|", omittingEmptySubsequences: false),
              total.count == 4, total[0] == "TOTAL",
              let totalRows = UInt32(total[1]), let totalBytes = UInt64(total[2]),
              let aggregate = parseHex(total[3]), totalRows == rows.count,
              totalBytes == rows.reduce(0, { $0 + $1.byteCount }) else {
            throw NSError(domain: "SM64MarioFacePayloadInventory", code: 6)
        }
        return .init(version: version, channelCount: channelCount, rows: rows, totalBytes: totalBytes, aggregateFingerprint: aggregate)
    }

    func matchesManifest() -> Bool {
        guard rows.count == SM64MarioFaceAnimationResourceManifest.entries.count * 2 else { return false }
        for (index, entry) in SM64MarioFaceAnimationResourceManifest.entries.enumerated() {
            let primary = rows[index * 2]
            let secondary = rows[index * 2 + 1]
            guard primary.componentID == entry.componentID, primary.bank == 0,
                  primary.count == Int32(entry.primaryCount), primary.type == entry.primaryType.rawValue,
                  primary.stride == entry.primaryStride,
                  secondary.componentID == entry.componentID, secondary.bank == 1,
                  secondary.count == Int32(entry.secondaryCount), secondary.type == entry.secondaryType.rawValue,
                  secondary.stride == entry.secondaryStride else { return false }
        }
        return true
    }

    private static func parseHex(_ value: Substring) -> UInt64? {
        let text = String(value)
        guard text.hasPrefix("0x") else { return nil }
        return UInt64(text.dropFirst(2), radix: 16)
    }
}
