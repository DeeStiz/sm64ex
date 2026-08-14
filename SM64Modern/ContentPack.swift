import CryptoKit
import Foundation

enum SM64ContentPackError: Error, CustomStringConvertible {
    case invalidArgument(String)
    case invalidMagic
    case unsupportedVersion(UInt32)
    case malformed(String)
    case missingROM
    case invalidROMHash(expected: String, actual: String)
    case invalidPath(String)
    case hashMismatch(String)
    case missingSection(String)
    case duplicateResource(String)
    case unknownSegment(UInt8)
    case segmentedRangeOutOfBounds(String)
    case resourceNotFound(String)

    var description: String {
        switch self {
        case .invalidArgument(let message): "invalid argument: \(message)"
        case .invalidMagic: "content pack magic is invalid"
        case .unsupportedVersion(let version): "content pack version \(version) is unsupported"
        case .malformed(let message): "malformed content pack: \(message)"
        case .missingROM: "a US ROM is required unless source-only mode is explicitly selected"
        case .invalidROMHash(let expected, let actual): "US ROM SHA-1 mismatch: expected \(expected), found \(actual)"
        case .invalidPath(let path): "unsafe content path: \(path)"
        case .hashMismatch(let path): "content hash mismatch: \(path)"
        case .missingSection(let kind): "content pack section is missing: \(kind)"
        case .duplicateResource(let path): "duplicate content resource: \(path)"
        case .unknownSegment(let segment): "unknown segmented resource \(String(format: "0x%02x", segment))"
        case .segmentedRangeOutOfBounds(let detail): "segmented resource range is out of bounds: \(detail)"
        case .resourceNotFound(let path): "content resource not found: \(path)"
        }
    }
}

enum SM64ContentPackSectionKind: String, CaseIterable, Sendable {
    case levelScripts = "level_scripts"
    case geometry = "geometry"
    case behaviorBytecode = "behavior_bytecode"
    case displayLists = "display_lists"
    case text = "text"
    case audioTables = "audio_tables"
    case romDerivedAssets = "rom_derived_assets"
    case sourceManifest = "source_manifest"
}

struct SM64ContentPackFile: Sendable {
    let relativePath: String
    let bytes: Data
    let sha256: Data
}

struct SM64ContentPackSection: Sendable {
    let kind: SM64ContentPackSectionKind
    let files: [SM64ContentPackFile]
    let payloadHash: Data
}

struct SM64ContentPackMetadata: Sendable {
    static let currentVersion: UInt32 = 1
    static let sourceOnlyFlag: UInt32 = 1 << 0

    let version: UInt32
    let flags: UInt32
    let region: String
    let romSHA1: Data
    let sourceFingerprint: Data

    var isSourceOnly: Bool { (flags & Self.sourceOnlyFlag) != 0 }
}

struct SM64ContentPack: Sendable {
    static let magic = Data([0x53, 0x4D, 0x36, 0x34, 0x43, 0x50, 0x4B, 0x00]) // SM64CPK\0
    static let headerSize = 92
    static let directoryEntrySize = 88

    let metadata: SM64ContentPackMetadata
    let sections: [SM64ContentPackSection]

    static func build(
        rootURL: URL,
        outputURL: URL,
        romURL: URL?,
        sourceOnly: Bool
    ) throws -> SM64ContentPack {
        let root = rootURL.standardizedFileURL
        let output = outputURL.standardizedFileURL
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw SM64ContentPackError.invalidArgument("content root does not exist: \(root.path)")
        }
        if !sourceOnly && romURL == nil { throw SM64ContentPackError.missingROM }

        let romSHA1: Data
        if let romURL {
            let rom = try Data(contentsOf: romURL.standardizedFileURL, options: [.mappedIfSafe])
            romSHA1 = Data(Insecure.SHA1.hash(data: rom))
            let expected = try expectedUSROMHash(root: root)
            let actual = hex(romSHA1)
            guard actual == expected else {
                throw SM64ContentPackError.invalidROMHash(expected: expected, actual: actual)
            }
        } else {
            romSHA1 = Data(repeating: 0, count: 20)
        }

        let files = try collectFiles(root: root, excluding: output)
        var grouped: [SM64ContentPackSectionKind: [SM64ContentPackFile]] = [:]
        for fileURL in files {
            let relative = relativePath(fileURL, root: root)
            guard let kind = classify(relative) else { continue }
            guard isSafeRelativePath(relative) else { throw SM64ContentPackError.invalidPath(relative) }
            let bytes = try Data(contentsOf: fileURL, options: [.mappedIfSafe])
            grouped[kind, default: []].append(
                SM64ContentPackFile(relativePath: relative, bytes: bytes, sha256: sha256(bytes))
            )
        }

        let sections = try SM64ContentPackSectionKind.allCases.map { kind in
            let files = (grouped[kind] ?? []).sorted {
                $0.relativePath.utf8.lexicographicallyPrecedes($1.relativePath.utf8)
            }
            return try makeSection(kind: kind, files: files)
        }
        let metadata = SM64ContentPackMetadata(
            version: SM64ContentPackMetadata.currentVersion,
            flags: sourceOnly ? SM64ContentPackMetadata.sourceOnlyFlag : 0,
            region: "US",
            romSHA1: romSHA1,
            sourceFingerprint: makeSourceFingerprint(sections: sections)
        )
        let pack = SM64ContentPack(metadata: metadata, sections: sections)
        try pack.write(to: output)
        return pack
    }

    func validate(
        expectedRegion: String = "US",
        expectedROMSHA1: Data? = nil,
        requireROM: Bool = false
    ) throws {
        guard metadata.region == expectedRegion else {
            throw SM64ContentPackError.malformed(
                "region is \(metadata.region), expected \(expectedRegion)"
            )
        }
        if requireROM && metadata.isSourceOnly { throw SM64ContentPackError.missingROM }
        if let expectedROMSHA1, metadata.romSHA1 != expectedROMSHA1 {
            throw SM64ContentPackError.invalidROMHash(
                expected: hex(expectedROMSHA1),
                actual: hex(metadata.romSHA1)
            )
        }
    }

    private static func expectedUSROMHash(root: URL) throws -> String {
        let url = root.appendingPathComponent("sm64.us.sha1")
        let text = try String(contentsOf: url, encoding: .utf8)
        guard let first = text.split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" }).first else {
            throw SM64ContentPackError.invalidArgument("sm64.us.sha1 is empty")
        }
        let expected = String(first).lowercased()
        let hexCharacters = CharacterSet(charactersIn: "0123456789abcdef")
        guard expected.count == 40,
              expected.unicodeScalars.allSatisfy({ hexCharacters.contains($0) }) else {
            throw SM64ContentPackError.invalidArgument("sm64.us.sha1 must contain a 40-character SHA-1")
        }
        return expected
    }

    private static func collectFiles(root: URL, excluding output: URL) throws -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles]
        ) else {
            throw SM64ContentPackError.invalidArgument("cannot enumerate content root")
        }
        let outputPath = output.path
        var result: [URL] = []
        for case let url as URL in enumerator {
            let path = url.standardizedFileURL.path
            if path == outputPath || path.hasPrefix(outputPath + "/") { continue }
            if path.contains("/.git/") || path.contains("/build/") { continue }
            let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
            guard values.isRegularFile == true, values.isSymbolicLink != true else { continue }
            result.append(url)
        }
        return result.sorted { $0.path.utf8.lexicographicallyPrecedes($1.path.utf8) }
    }

    private static func relativePath(_ url: URL, root: URL) -> String {
        let rootPath = root.path.hasSuffix("/") ? root.path : root.path + "/"
        return String(url.standardizedFileURL.path.dropFirst(rootPath.count))
    }

    private static func classify(_ path: String) -> SM64ContentPackSectionKind? {
        if path == "assets.json" || path.hasPrefix("assets/") { return .romDerivedAssets }
        if path.hasPrefix("levels/") {
            if path.contains("/areas/") || path.hasSuffix("/geo.c") || path.hasSuffix("/geo.inc.c") || path.hasSuffix("/model.inc.c") {
                return .geometry
            }
            return .levelScripts
        }
        if path.hasPrefix("actors/") { return .geometry }
        if path.hasPrefix("src/game/behaviors/")
            || path == "data/behavior_data.c"
            || path.hasPrefix("src/engine/behavior") {
            return .behaviorBytecode
        }
        if path.hasPrefix("bin/")
            || path == "src/engine/geo_layout.c"
            || path == "src/engine/graph_node.c"
            || path == "src/engine/graph_node_manager.c"
            || path == "src/game/rendering_graph_node.c" {
            return .displayLists
        }
        if path.hasPrefix("src/menu/")
            || path == "charmap_menu.txt"
            || path == "src/game/text_save.inc.h"
            || path.hasPrefix("bin/eu/translation_") {
            return .text
        }
        if path.hasPrefix("src/audio/") { return .audioTables }
        if path == "sm64.us.sha1" { return .sourceManifest }
        return nil
    }

    private static func makeSection(
        kind: SM64ContentPackSectionKind,
        files: [SM64ContentPackFile]
    ) throws -> SM64ContentPackSection {
        var writer = SM64ContentPackWriter()
        for file in files {
            let path = Data(file.relativePath.utf8)
            guard path.count <= UInt32.max else {
                throw SM64ContentPackError.invalidArgument("path is too long: \(file.relativePath)")
            }
            writer.appendUInt32(UInt32(path.count))
            writer.appendUInt64(UInt64(file.bytes.count))
            writer.append(file.sha256)
            writer.append(path)
            writer.append(file.bytes)
        }
        return SM64ContentPackSection(
            kind: kind,
            files: files,
            payloadHash: sha256(writer.data)
        )
    }

    private static func makeSourceFingerprint(sections: [SM64ContentPackSection]) -> Data {
        var writer = SM64ContentPackWriter()
        for section in sections.sorted(by: { $0.kind.rawValue < $1.kind.rawValue }) {
            writer.appendFixedString(section.kind.rawValue, count: 32)
            writer.appendUInt32(UInt32(section.files.count))
            for file in section.files.sorted(by: {
                $0.relativePath.utf8.lexicographicallyPrecedes($1.relativePath.utf8)
            }) {
                let path = Data(file.relativePath.utf8)
                writer.appendUInt32(UInt32(path.count))
                writer.appendUInt64(UInt64(file.bytes.count))
                writer.append(file.sha256)
                writer.append(path)
            }
        }
        return sha256(writer.data)
    }

    func write(to url: URL) throws {
        var payloads: [(kind: SM64ContentPackSectionKind, data: Data, fileCount: Int)] = []
        for section in sections.sorted(by: { $0.kind.rawValue < $1.kind.rawValue }) {
            var writer = SM64ContentPackWriter()
            for file in section.files.sorted(by: {
                $0.relativePath.utf8.lexicographicallyPrecedes($1.relativePath.utf8)
            }) {
                let path = Data(file.relativePath.utf8)
                writer.appendUInt32(UInt32(path.count))
                writer.appendUInt64(UInt64(file.bytes.count))
                writer.append(file.sha256)
                writer.append(path)
                writer.append(file.bytes)
            }
            payloads.append((section.kind, writer.data, section.files.count))
        }

        let payloadOffset = Self.headerSize + Self.directoryEntrySize * payloads.count
        var writer = SM64ContentPackWriter()
        writer.append(Self.magic)
        writer.appendUInt32(metadata.version)
        writer.appendUInt32(metadata.flags)
        writer.appendUInt32(UInt32(Self.headerSize))
        writer.appendUInt32(UInt32(payloads.count))
        writer.appendUInt64(UInt64(Self.headerSize))
        writer.append(metadata.romSHA1)
        writer.append(metadata.sourceFingerprint)
        writer.appendFixedString(metadata.region, count: 4)
        writer.appendUInt32(0)

        var offset = payloadOffset
        for payload in payloads {
            writer.appendFixedString(payload.kind.rawValue, count: 32)
            writer.appendUInt64(UInt64(offset))
            writer.appendUInt64(UInt64(payload.data.count))
            writer.append(sha256(payload.data))
            writer.appendUInt32(UInt32(payload.fileCount))
            writer.appendUInt32(0)
            offset += payload.data.count
        }
        for payload in payloads { writer.append(payload.data) }

        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try writer.data.write(to: url, options: [.atomic])
    }

    static func load(from url: URL) throws -> SM64ContentPack {
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        var reader = SM64ContentPackReader(data: data)
        guard try reader.readData(count: magic.count) == magic else {
            throw SM64ContentPackError.invalidMagic
        }
        let version = try reader.readUInt32()
        guard version == SM64ContentPackMetadata.currentVersion else {
            throw SM64ContentPackError.unsupportedVersion(version)
        }
        let flags = try reader.readUInt32()
        let headerSize = try reader.readUInt32()
        let sectionCount = try reader.readUInt32()
        let directoryOffset = try reader.readUInt64()
        guard headerSize == UInt32(Self.headerSize), directoryOffset == UInt64(Self.headerSize) else {
            throw SM64ContentPackError.malformed("unsupported header layout")
        }
        guard sectionCount == UInt32(SM64ContentPackSectionKind.allCases.count) else {
            throw SM64ContentPackError.malformed("section count must be \(SM64ContentPackSectionKind.allCases.count)")
        }
        let romSHA1 = try reader.readData(count: 20)
        let sourceFingerprint = try reader.readData(count: 32)
        let region = try reader.readFixedString(count: 4)
        _ = try reader.readUInt32()
        guard reader.offset == Self.headerSize else {
            throw SM64ContentPackError.malformed("header size accounting")
        }

        struct DirectoryEntry {
            let kind: SM64ContentPackSectionKind
            let offset: UInt64
            let length: UInt64
            let hash: Data
            let fileCount: UInt32
        }
        var directory: [DirectoryEntry] = []
        var seenKinds = Set<SM64ContentPackSectionKind>()
        for _ in 0..<sectionCount {
            let rawName = try reader.readFixedString(count: 32)
            guard let kind = SM64ContentPackSectionKind(rawValue: rawName) else {
                throw SM64ContentPackError.malformed("unknown section \(rawName)")
            }
            guard seenKinds.insert(kind).inserted else {
                throw SM64ContentPackError.malformed("duplicate section \(kind.rawValue)")
            }
            let offset = try reader.readUInt64()
            let length = try reader.readUInt64()
            let hash = try reader.readData(count: 32)
            let fileCount = try reader.readUInt32()
            _ = try reader.readUInt32()
            directory.append(DirectoryEntry(kind: kind, offset: offset, length: length, hash: hash, fileCount: fileCount))
        }

        let minimumPayloadOffset = UInt64(Self.headerSize + Self.directoryEntrySize * Int(sectionCount))
        var ranges: [(offset: UInt64, end: UInt64)] = []
        for entry in directory {
            guard entry.offset >= minimumPayloadOffset,
                  entry.offset <= UInt64(data.count),
                  entry.length <= UInt64(data.count) - entry.offset else {
                throw SM64ContentPackError.malformed("section bounds for \(entry.kind.rawValue)")
            }
            let end = entry.offset + entry.length
            guard !ranges.contains(where: { entry.offset < $0.end && end > $0.offset }) else {
                throw SM64ContentPackError.malformed("overlapping section payloads")
            }
            ranges.append((entry.offset, end))
        }

        var sections: [SM64ContentPackSection] = []
        for entry in directory.sorted(by: { $0.kind.rawValue < $1.kind.rawValue }) {
            let start = Int(entry.offset)
            let end = Int(entry.offset + entry.length)
            let payload = data.subdata(in: start..<end)
            guard sha256(payload) == entry.hash else {
                throw SM64ContentPackError.hashMismatch(entry.kind.rawValue)
            }
            var payloadReader = SM64ContentPackReader(data: payload)
            var files: [SM64ContentPackFile] = []
            var seenPaths = Set<String>()
            for _ in 0..<entry.fileCount {
                let pathLength = try payloadReader.readUInt32()
                let byteLength = try payloadReader.readUInt64()
                let fileHash = try payloadReader.readData(count: 32)
                guard pathLength <= 16_384,
                      byteLength <= UInt64(payload.count - payloadReader.offset) else {
                    throw SM64ContentPackError.malformed("file record size in \(entry.kind.rawValue)")
                }
                let path = try payloadReader.readUTF8(count: Int(pathLength))
                guard isSafeRelativePath(path) else {
                    throw SM64ContentPackError.invalidPath(path)
                }
                guard seenPaths.insert(path).inserted else {
                    throw SM64ContentPackError.malformed("duplicate file path \(path)")
                }
                let bytes = try payloadReader.readData(count: Int(byteLength))
                guard sha256(bytes) == fileHash else {
                    throw SM64ContentPackError.hashMismatch(path)
                }
                files.append(SM64ContentPackFile(relativePath: path, bytes: bytes, sha256: fileHash))
            }
            guard payloadReader.offset == payload.count else {
                throw SM64ContentPackError.malformed("trailing bytes in \(entry.kind.rawValue)")
            }
            sections.append(SM64ContentPackSection(kind: entry.kind, files: files, payloadHash: entry.hash))
        }

        let metadata = SM64ContentPackMetadata(
            version: version,
            flags: flags,
            region: region,
            romSHA1: romSHA1,
            sourceFingerprint: sourceFingerprint
        )
        let pack = SM64ContentPack(metadata: metadata, sections: sections)
        guard makeSourceFingerprint(sections: sections) == sourceFingerprint else {
            throw SM64ContentPackError.hashMismatch("source manifest")
        }
        return pack
    }
}

private struct SM64ContentPackWriter {
    var data = Data()

    mutating func append(_ bytes: Data) {
        data.append(bytes)
    }

    mutating func appendUInt32(_ value: UInt32) {
        var little = value.littleEndian
        withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
    }

    mutating func appendUInt64(_ value: UInt64) {
        var little = value.littleEndian
        withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
    }

    mutating func appendFixedString(_ value: String, count: Int) {
        let bytes = Array(value.utf8.prefix(count))
        data.append(contentsOf: bytes)
        if bytes.count < count {
            data.append(contentsOf: repeatElement(UInt8(0), count: count - bytes.count))
        }
    }
}

private struct SM64ContentPackReader {
    let data: Data
    var offset = 0

    mutating func readData(count: Int) throws -> Data {
        guard count >= 0, offset <= data.count, count <= data.count - offset else {
            throw SM64ContentPackError.malformed("truncated record")
        }
        let result = data.subdata(in: offset..<(offset + count))
        offset += count
        return result
    }

    mutating func readUInt32() throws -> UInt32 {
        let bytes = try [UInt8](readData(count: 4))
        return UInt32(bytes[0])
            | UInt32(bytes[1]) << 8
            | UInt32(bytes[2]) << 16
            | UInt32(bytes[3]) << 24
    }

    mutating func readUInt64() throws -> UInt64 {
        let bytes = try [UInt8](readData(count: 8))
        return UInt64(bytes[0])
            | UInt64(bytes[1]) << 8
            | UInt64(bytes[2]) << 16
            | UInt64(bytes[3]) << 24
            | UInt64(bytes[4]) << 32
            | UInt64(bytes[5]) << 40
            | UInt64(bytes[6]) << 48
            | UInt64(bytes[7]) << 56
    }

    mutating func readFixedString(count: Int) throws -> String {
        let bytes = [UInt8](try readData(count: count))
        let end = bytes.firstIndex(of: 0) ?? bytes.endIndex
        guard let value = String(bytes: bytes[..<end], encoding: .utf8) else {
            throw SM64ContentPackError.malformed("invalid UTF-8")
        }
        return value
    }

    mutating func readUTF8(count: Int) throws -> String {
        guard let value = String(data: try readData(count: count), encoding: .utf8) else {
            throw SM64ContentPackError.malformed("invalid UTF-8 path")
        }
        return value
    }
}

private func sha256(_ data: Data) -> Data {
    Data(SHA256.hash(data: data))
}

private func hex(_ data: Data) -> String {
    data.map { String(format: "%02x", $0) }.joined()
}

private func isSafeRelativePath(_ path: String) -> Bool {
    !path.isEmpty
        && !path.hasPrefix("/")
        && !path.split(separator: "/").contains("..")
        && !path.contains("\\")
}
