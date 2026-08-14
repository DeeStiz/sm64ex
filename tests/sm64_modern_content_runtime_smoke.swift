import Foundation

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernContentRuntimeSmoke {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            preconditionFailure("usage: content-runtime-smoke PACK")
        }
        let pack = try SM64ContentPack.load(from: URL(fileURLWithPath: CommandLine.arguments[1]))
        let index = try SM64ContentPackIndex(pack: pack)
        require(index.metadata.region == "US" && index.metadata.isSourceOnly, "pack metadata")
        require(index.fileCount(for: .levelScripts) == 1, "level section count")
        require(index.fileCount(for: .geometry) == 2, "geometry section count")
        require(index.fileCount(for: .behaviorBytecode) == 1, "behavior section count")
        require(index.fileCount(for: .displayLists) == 2, "display section count")
        require(index.fileCount(for: .text) == 1, "text section count")
        require(index.fileCount(for: .audioTables) == 1, "audio section count")
        require(index.fileCount(for: .romDerivedAssets) == 2, "asset section count")
        require(index.fileCount(for: .sourceManifest) == 1, "manifest section count")

        let levelKey = SM64ContentResourceKey(kind: .levelScripts, relativePath: "levels/fixture/script.c")
        let geometryKey = SM64ContentResourceKey(kind: .geometry, relativePath: "actors/fixture/model.inc.c")
        let levelBytes = try index.bytes(kind: levelKey.kind, relativePath: levelKey.relativePath)
        let geometryBytes = try index.bytes(kind: geometryKey.kind, relativePath: geometryKey.relativePath)
        require(levelBytes == Data("fixture-level-script\n".utf8), "level bytes")
        require(geometryBytes == Data("fixture-actor-model\n".utf8), "geometry bytes")
        let resources = index.allResources()
        require(resources == resources.sorted {
            if $0.kind.rawValue != $1.kind.rawValue {
                return $0.kind.rawValue < $1.kind.rawValue
            }
            return $0.relativePath.utf8.lexicographicallyPrecedes($1.relativePath.utf8)
        }, "canonical resource sort")

        let levelMapping = try SM64SegmentMapping(
            segment: 0x02,
            segmentOffset: 0,
            resource: levelKey,
            length: UInt32(levelBytes.count)
        )
        let geometryMapping = try SM64SegmentMapping(
            segment: 0x03,
            segmentOffset: 0x100,
            resource: geometryKey,
            resourceOffset: 4,
            length: UInt32(geometryBytes.count - 4)
        )
        let runtime = try SM64ContentPackRuntime(index: index, mappings: [levelMapping, geometryMapping])
        let resolved = try runtime.resolve(rawAddress: 0x0200_0005)
        require(resolved.segment == 0x02 && resolved.segmentOffset == 5, "segment decode")
        require(resolved.resource == levelKey && resolved.resourceOffset == 5, "resource offset")
        let levelRead = try runtime.read(rawAddress: 0x0200_0000, byteCount: 7)
        require(levelRead == Data("fixture".utf8), "segmented read")
        let geometryRead = try runtime.read(rawAddress: 0x0300_0100, byteCount: 5)
        require(geometryRead == Data("ure-a".utf8), "mapped resource offset")

        do {
            _ = try runtime.resolve(rawAddress: 0x0400_0000)
            preconditionFailure("unknown segment should fail")
        } catch let error as SM64ContentPackError {
            if case .unknownSegment(0x04) = error {} else { preconditionFailure("wrong unknown segment error") }
        }
        do {
            _ = try runtime.read(rawAddress: 0x0200_0014, byteCount: 2)
            preconditionFailure("out-of-bounds segmented read should fail")
        } catch let error as SM64ContentPackError {
            if case .segmentedRangeOutOfBounds = error {} else { preconditionFailure("wrong segmented range error") }
        }
        do {
            _ = try SM64ContentPackRuntime(index: index, mappings: [
                levelMapping,
                try SM64SegmentMapping(
                    segment: 0x02,
                    segmentOffset: 4,
                    resource: levelKey,
                    length: 4
                ),
            ])
            preconditionFailure("overlapping segment mapping should fail")
        } catch let error as SM64ContentPackError {
            if case .segmentedRangeOutOfBounds = error {} else { preconditionFailure("wrong overlap error") }
        }
        do {
            _ = try index.bytes(kind: .text, relativePath: "missing.txt")
            preconditionFailure("missing resource should fail")
        } catch let error as SM64ContentPackError {
            if case .resourceNotFound = error {} else { preconditionFailure("wrong missing resource error") }
        }

        let missingSectionPack = SM64ContentPack(
            metadata: pack.metadata,
            sections: Array(pack.sections.dropLast())
        )
        do {
            _ = try SM64ContentPackIndex(pack: missingSectionPack)
            preconditionFailure("missing section should fail")
        } catch let error as SM64ContentPackError {
            if case .missingSection = error {} else { preconditionFailure("wrong missing section error") }
        }
        do {
            _ = try SM64SegmentMapping(
                segment: 0x02,
                segmentOffset: 0x0100_0000,
                resource: levelKey,
                length: 1
            )
            preconditionFailure("24-bit segment overflow should fail")
        } catch let error as SM64ContentPackError {
            if case .segmentedRangeOutOfBounds = error {} else { preconditionFailure("wrong segment overflow error") }
        }

        print("SM64 Modern content runtime smoke passed resources=\(index.allResources().count)")
    }
}
