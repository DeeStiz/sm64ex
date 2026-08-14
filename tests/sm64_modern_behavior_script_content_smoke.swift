import Foundation

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func appendWord(_ word: UInt32, to data: inout Data) {
    data.append(UInt8(truncatingIfNeeded: word))
    data.append(UInt8(truncatingIfNeeded: word >> 8))
    data.append(UInt8(truncatingIfNeeded: word >> 16))
    data.append(UInt8(truncatingIfNeeded: word >> 24))
}

private func segmentedProgram() -> Data {
    var data = Data()
    appendWord(0x0001_0000, to: &data) // BEGIN(1)
    appendWord(0x0200_0000, to: &data) // CALL
    appendWord(0x0100_0014, to: &data) // segmented target at byte 20 (word 5)
    appendWord(0x1002_0007, to: &data) // SET_INT(field 2, 7)
    appendWord(0x0a00_0000, to: &data) // BREAK
    appendWord(0x1002_0009, to: &data) // subroutine SET_INT(field 2, 9)
    appendWord(0x0300_0000, to: &data) // RETURN
    return data
}

@main
enum SM64ModernBehaviorScriptContentSmoke {
    static func main() throws {
        let key = SM64ContentResourceKey(kind: .behaviorBytecode, relativePath: "fixture.bin")
        let bytes = segmentedProgram()
        let file = SM64ContentPackFile(relativePath: key.relativePath, bytes: bytes, sha256: Data())
        let sections = SM64ContentPackSectionKind.allCases.map { kind in
            SM64ContentPackSection(
                kind: kind,
                files: kind == .behaviorBytecode ? [file] : [],
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
        let resolved = try runtime.resolve(rawAddress: 0x0100_0014)
        require(resolved.resource == key && resolved.resourceOffset == 20, "segmented behavior target resolution")
        let program = try runtime.behaviorScript(resource: key)
        let resolver = try runtime.behaviorScriptTargetResolver(program: program, resource: key)
        var vm = try SM64BehaviorVM(program: program, targetResolver: resolver)
        try vm.executeTick()
        require(vm.snapshot.status == SM64BehaviorVMStatus.break && vm.snapshot.currentOffset == 4, "segmented behavior break")
        require(vm.snapshot.object.getInt(2) == 7, "segmented behavior subroutine returned")
        print("SM64 Modern behavior-script content integration smoke passed resourceBytes=\(bytes.count)")
    }
}
