import Foundation

private enum Phase85CTError: Error, CustomStringConvertible {
    case invalid(String)

    var description: String {
        switch self { case .invalid(let message): return message }
    }
}

private let expectedDeathWarp: UInt64 = 0xa22b_7ff1_6730_e047

private func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else { throw Phase85CTError.invalid(message) }
}

private func subject31(in records: [SM64OracleTraceRecord]) -> SM64OracleTraceRecord? {
    records.first {
        $0.simulationTick == 1 && $0.domain == 3 && $0.recordKind == 1
            && $0.subjectID == 31 && $0.recordID == 400
    }
}

@main
struct SM64ModernPhase85CTSubject31Identity {
    static func main() {
        do {
            let arguments = Array(CommandLine.arguments.dropFirst())
            try require(arguments.count >= 4, "usage: phase85ct C ASAN RELEASE RERUN [SWIFT]")

            let source = try String(contentsOfFile: "levels/castle_inside/script.c", encoding: .utf8)
            try require(source.contains("0x00280000, /*beh*/ bhvDeathWarp"),
                        "Castle area-1 death-warp source entry missing")
            let owner = try String(contentsOfFile: "src/pc/sm64_modern_gameplay_parity.c", encoding: .utf8)
            try require(owner.contains("SOURCE_BEHAVIOR_IDENTITY(bhvDeathWarp)"),
                        "semantic owner mapping missing")

            for path in arguments {
                let file = try SM64OracleTraceFile.read(from: URL(fileURLWithPath: path))
                let record = try requireRecord(subject31(in: file.records), path: path)
                try require(record.values == [expectedDeathWarp],
                            "subject-31 semantic identity mismatch in (path)")
                print("phase85ct_path=\(path) records=\(file.records.count) subject31=0x\(String(expectedDeathWarp, radix: 16))")
            }
            print("phase85ct_subject31_source_behavior=bhvDeathWarp")
            print("phase85ct_subject31_source_identity_mapping=1")
            print("phase85ct_whole_trace_parity=0")
            print("phase85ct_canonical_promotion=0 manifest_mutation=0 ledger_mutation=0 shared_docs_mutation=0")
        } catch {
            FileHandle.standardError.write(Data("phase85ct_subject31_identity_failed=\(error)\n".utf8))
            exit(1)
        }
    }

    private static func requireRecord(
        _ record: SM64OracleTraceRecord?,
        path: String
    ) throws -> SM64OracleTraceRecord {
        guard let record else {
            throw Phase85CTError.invalid("subject-31 actor record missing in \(path)")
        }
        return record
    }
}
