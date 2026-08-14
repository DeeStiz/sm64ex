import Foundation

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func word(_ a: UInt8, _ b: UInt8, _ c: UInt8 = 0, _ d: UInt8 = 0) -> [UInt8] {
    [a, b, c, d, 0, 0, 0, 0]
}

private func pointer(_ value: UInt32) -> [UInt8] {
    var raw = UInt64(value)
    var bytes = Array(repeating: UInt8(0), count: 8)
    for index in 0..<8 { bytes[index] = UInt8(truncatingIfNeeded: raw); raw >>= 8 }
    return bytes
}

private func segmentedGeoLayout() -> Data {
    var data = Data()
    // BRANCH(type=0, 0x01000010) -> ROOT -> END.
    data.append(contentsOf: word(0x02, 0x00))
    data.append(contentsOf: pointer(0x0100_0010))
    data.append(contentsOf: word(0x08, 0x00, 0x00))
    data.append(contentsOf: word(0, 0))
    data.append(contentsOf: word(160, 120))
    data.append(contentsOf: word(0x01, 0x00))
    return data
}

@main
enum SM64ModernGeoLayoutContentSmoke {
    static func main() throws {
        let key = SM64ContentResourceKey(kind: .geometry, relativePath: "fixture.geo")
        let bytes = segmentedGeoLayout()
        let file = SM64ContentPackFile(relativePath: key.relativePath, bytes: bytes, sha256: Data())
        let sections = SM64ContentPackSectionKind.allCases.map { kind in
            SM64ContentPackSection(kind: kind, files: kind == .geometry ? [file] : [], payloadHash: Data())
        }
        let metadata = SM64ContentPackMetadata(
            version: SM64ContentPackMetadata.currentVersion,
            flags: SM64ContentPackMetadata.sourceOnlyFlag,
            region: "US",
            romSHA1: Data(repeating: 0, count: 20),
            sourceFingerprint: Data(repeating: 0, count: 32)
        )
        let index = try SM64ContentPackIndex(pack: SM64ContentPack(metadata: metadata, sections: sections))
        let runtime = try SM64ContentPackRuntime(index: index, mappings: [
            try SM64SegmentMapping(segment: 1, segmentOffset: 0, resource: key, length: UInt32(bytes.count))
        ])
        let program = try runtime.geoLayout(resource: key)
        let resolver = try runtime.geoLayoutTargetResolver(program: program, resource: key)
        var builder = SM64GeoLayoutBuilder(program: program, targetResolver: resolver)
        let scene = try builder.build()
        require(scene.root == 0, "segmented geo root")
        require(scene.nodes.count == 1 && scene.nodes[0].kind == .root, "segmented geo node")
        print("SM64 Modern geo-layout content integration smoke passed resourceBytes=\(bytes.count)")
    }
}
