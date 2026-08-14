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
    for index in 0..<8 {
        bytes[index] = UInt8(truncatingIfNeeded: raw)
        raw >>= 8
    }
    return bytes
}

private func segmentedProgram() -> Data {
    var data = Data()
    data.append(contentsOf: word(0x13, 0x04, 7))
    data.append(contentsOf: word(0x0c, 0x0c, 2))
    data.append(contentsOf: word(7, 0))
    data.append(contentsOf: pointer(0x0100_0020))
    data.append(contentsOf: word(0x02, 0x04))
    return data
}

@main
enum SM64ModernLevelScriptContentSmoke {
    static func main() throws {
        let key = SM64ContentResourceKey(kind: .levelScripts, relativePath: "fixture.bin")
        let bytes = segmentedProgram()
        let file = SM64ContentPackFile(relativePath: key.relativePath, bytes: bytes, sha256: Data())
        let sections = SM64ContentPackSectionKind.allCases.map { kind in
            SM64ContentPackSection(
                kind: kind,
                files: kind == .levelScripts ? [file] : [],
                payloadHash: Data()
            )
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
            try SM64SegmentMapping(
                segment: 1,
                segmentOffset: 0,
                resource: key,
                length: UInt32(bytes.count)
            )
        ])
        let resolved = try runtime.resolve(rawAddress: 0x0100_0020)
        require(resolved.resource == key && resolved.resourceOffset == 32, "segmented target resolution")
        let program = try runtime.levelScript(resource: key)
        let resolver = try runtime.levelScriptTargetResolver(program: program, resource: key)
        var vm = try SM64LevelScriptVM(program: program, targetResolver: resolver)
        try vm.runToHalt()
        require(vm.snapshot.status == .halted, "segmented script halted")
        require(vm.snapshot.register == 7, "segmented jump target executed")
        print("SM64 Modern level-script content integration smoke passed resourceBytes=\(bytes.count)")
    }
}
