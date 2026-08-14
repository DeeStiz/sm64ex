import Foundation

struct SM64ContentResourceKey: Hashable, Sendable {
    let kind: SM64ContentPackSectionKind
    let relativePath: String
}

struct SM64ContentPackIndex: Sendable {
    let metadata: SM64ContentPackMetadata
    private let resources: [SM64ContentResourceKey: SM64ContentPackFile]
    private let sectionCounts: [SM64ContentPackSectionKind: Int]

    init(pack: SM64ContentPack) throws {
        try pack.validate()
        let present = Set(pack.sections.map(\.kind))
        guard pack.sections.count == SM64ContentPackSectionKind.allCases.count,
              present == Set(SM64ContentPackSectionKind.allCases) else {
            if let missing = SM64ContentPackSectionKind.allCases.first(where: { !present.contains($0) }) {
                throw SM64ContentPackError.missingSection(missing.rawValue)
            }
            throw SM64ContentPackError.malformed("section inventory")
        }

        var resources: [SM64ContentResourceKey: SM64ContentPackFile] = [:]
        var counts: [SM64ContentPackSectionKind: Int] = [:]
        for section in pack.sections {
            counts[section.kind] = section.files.count
            for file in section.files {
                let key = SM64ContentResourceKey(kind: section.kind, relativePath: file.relativePath)
                guard resources.updateValue(file, forKey: key) == nil else {
                    throw SM64ContentPackError.duplicateResource(file.relativePath)
                }
            }
        }
        self.metadata = pack.metadata
        self.resources = resources
        self.sectionCounts = counts
    }

    func file(kind: SM64ContentPackSectionKind, relativePath: String) throws -> SM64ContentPackFile {
        let key = SM64ContentResourceKey(kind: kind, relativePath: relativePath)
        guard let file = resources[key] else {
            throw SM64ContentPackError.resourceNotFound("\(kind.rawValue):\(relativePath)")
        }
        return file
    }

    func bytes(kind: SM64ContentPackSectionKind, relativePath: String) throws -> Data {
        try file(kind: kind, relativePath: relativePath).bytes
    }

    func fileCount(for kind: SM64ContentPackSectionKind) -> Int {
        sectionCounts[kind, default: 0]
    }

    func allResources() -> [SM64ContentResourceKey] {
        resources.keys.sorted {
            if $0.kind.rawValue != $1.kind.rawValue {
                return $0.kind.rawValue < $1.kind.rawValue
            }
            return $0.relativePath.utf8.lexicographicallyPrecedes($1.relativePath.utf8)
        }
    }
}

struct SM64SegmentMapping: Hashable, Sendable {
    let segment: UInt8
    let segmentOffset: UInt32
    let resource: SM64ContentResourceKey
    let resourceOffset: UInt64
    let length: UInt32

    init(
        segment: UInt8,
        segmentOffset: UInt32,
        resource: SM64ContentResourceKey,
        resourceOffset: UInt64 = 0,
        length: UInt32
    ) throws {
        guard segment != 0, length > 0 else {
            throw SM64ContentPackError.segmentedRangeOutOfBounds("empty segment mapping")
        }
        guard segmentOffset <= 0x00ff_ffff,
              UInt64(segmentOffset) + UInt64(length) <= 0x0100_0000 else {
            throw SM64ContentPackError.segmentedRangeOutOfBounds("segment offset overflow")
        }
        self.segment = segment
        self.segmentOffset = segmentOffset
        self.resource = resource
        self.resourceOffset = resourceOffset
        self.length = length
    }

    var endOffset: UInt64 {
        UInt64(segmentOffset) + UInt64(length)
    }
}

struct SM64ResolvedSegmentAddress: Sendable {
    let rawAddress: UInt32
    let segment: UInt8
    let segmentOffset: UInt32
    let resource: SM64ContentResourceKey
    let resourceOffset: UInt64
}

/// Converts retained N64-style `0xSSOOOOOO` references into bounds-checked
/// Swift content resources. Mappings are explicit and immutable; a missing or
/// overlapping mapping is rejected before a VM can dereference it.
struct SM64ContentPackRuntime: Sendable {
    let index: SM64ContentPackIndex
    private let mappings: [UInt8: [SM64SegmentMapping]]

    init(index: SM64ContentPackIndex, mappings: [SM64SegmentMapping]) throws {
        var grouped: [UInt8: [SM64SegmentMapping]] = [:]
        for mapping in mappings {
            let bytes = try index.bytes(
                kind: mapping.resource.kind,
                relativePath: mapping.resource.relativePath
            )
            guard mapping.resourceOffset <= UInt64(bytes.count),
                  UInt64(mapping.length) <= UInt64(bytes.count) - mapping.resourceOffset else {
                throw SM64ContentPackError.segmentedRangeOutOfBounds(
                    "\(mapping.resource.kind.rawValue):\(mapping.resource.relativePath)"
                )
            }
            grouped[mapping.segment, default: []].append(mapping)
        }
        for (segment, entries) in grouped {
            let sorted = entries.sorted { $0.segmentOffset < $1.segmentOffset }
            for pair in zip(sorted, sorted.dropFirst()) where pair.0.endOffset > UInt64(pair.1.segmentOffset) {
                throw SM64ContentPackError.segmentedRangeOutOfBounds(
                    "overlap in segment \(String(format: "0x%02x", segment))"
                )
            }
            grouped[segment] = sorted
        }
        self.index = index
        self.mappings = grouped
    }

    func resolve(rawAddress: UInt32) throws -> SM64ResolvedSegmentAddress {
        let segment = UInt8(truncatingIfNeeded: rawAddress >> 24)
        let offset = rawAddress & 0x00ff_ffff
        guard let mapping = mappings[segment]?.first(where: {
            UInt64(offset) >= UInt64($0.segmentOffset) && UInt64(offset) < $0.endOffset
        }) else {
            throw SM64ContentPackError.unknownSegment(segment)
        }
        let delta = UInt64(offset) - UInt64(mapping.segmentOffset)
        return SM64ResolvedSegmentAddress(
            rawAddress: rawAddress,
            segment: segment,
            segmentOffset: offset,
            resource: mapping.resource,
            resourceOffset: mapping.resourceOffset + delta
        )
    }

    func read(rawAddress: UInt32, byteCount: Int) throws -> Data {
        guard byteCount >= 0 else {
            throw SM64ContentPackError.segmentedRangeOutOfBounds("negative byte count")
        }
        let resolved = try resolve(rawAddress: rawAddress)
        guard let mapping = mappings[resolved.segment]?.first(where: {
            UInt64(resolved.segmentOffset) >= UInt64($0.segmentOffset)
                && UInt64(resolved.segmentOffset) < $0.endOffset
        }) else {
            throw SM64ContentPackError.unknownSegment(resolved.segment)
        }
        let delta = UInt64(resolved.segmentOffset) - UInt64(mapping.segmentOffset)
        guard UInt64(byteCount) <= UInt64(mapping.length) - delta else {
            throw SM64ContentPackError.segmentedRangeOutOfBounds(
                "read \(byteCount) at 0x\(String(format: "%08x", rawAddress))"
            )
        }
        let bytes = try index.bytes(
            kind: resolved.resource.kind,
            relativePath: resolved.resource.relativePath
        )
        let start = Int(resolved.resourceOffset)
        return bytes.subdata(in: start..<(start + byteCount))
    }
}
