import Foundation

private enum Phase85CIError: Error, CustomStringConvertible {
    case invalid(String)

    var description: String {
        switch self {
        case .invalid(let message): return message
        }
    }
}

private let sourcePath = "sound/sequences/us/12_event_high_score.m64"
private let sourceSHA256 = "2e0170f20353d6ba772af9df92f2d53e8b8d807e2b5bca24ac87bc022f08fade"
private let expectedBehaviorIdentity: UInt64 = 0x58c5_c9f3_5461_4b2d
private let recordIndex = 355

private func fnv(_ value: String) -> UInt64 {
    value.utf8.reduce(SM64OracleTraceHash.offset) { partial, byte in
        (partial ^ UInt64(byte)) &* SM64OracleTraceHash.prime
    }
}

private func firstDifference(_ lhs: Data, _ rhs: Data) -> Int? {
    let limit = min(lhs.count, rhs.count)
    for offset in 0..<limit where lhs[offset] != rhs[offset] {
        return offset
    }
    return lhs.count == rhs.count ? nil : limit
}

private func load(_ path: String) throws -> (Data, [SM64OracleTraceRecord]) {
    let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
    let trace = try SM64OracleTraceFile.read(from: URL(fileURLWithPath: path))
    guard trace.configuration.mode == .record,
          trace.configuration.contentFingerprint == fnv("\(sourcePath)|sha256=\(sourceSHA256)"),
          trace.records.count > recordIndex else {
        throw Phase85CIError.invalid("source/header/record-count mismatch: \(path)")
    }
    let record = trace.records[recordIndex]
    guard record.simulationTick == 1,
          record.domain == 12,
          record.recordKind == 4,
          record.subjectID == 11,
          record.recordID == 4,
          record.sequence == 10,
          record.values == [0, expectedBehaviorIdentity, 0] else {
        throw Phase85CIError.invalid("subject-11 semantic mapping mismatch: \(path)")
    }
    return (data, trace.records)
}

@main
struct SM64ModernPhase85CIBehaviorSemanticMapping {
    static func main() {
        do {
            let paths = Array(CommandLine.arguments.dropFirst())
            guard paths.count == 4 else {
                throw Phase85CIError.invalid(
                    "usage: phase85ci-behavior-semantic-mapping DEBUG ASAN RELEASE RERUN"
                )
            }
            let artifacts = try paths.map(load)
            let debug = artifacts[0]
            let asan = artifacts[1]
            let release = artifacts[2]
            let rerun = artifacts[3]
            let nativeDifference = firstDifference(debug.0, asan.0)
                ?? firstDifference(debug.0, release.0)
            guard debug.0 == rerun.0 else {
                throw Phase85CIError.invalid("Debug rerun fence failed")
            }
            print("phase85ci_source_behavior=bhvSignOnWall")
            print("phase85ci_expected_semantic_identity=0x\(String(expectedBehaviorIdentity, radix: 16))")
            print("phase85ci_subject11_debug_asan_release_semantic_match=1")
            if let offset = nativeDifference {
                let traceRecord = offset >= 72 ? (offset - 72) / SM64OracleTraceRecord.encodedSize : -1
                let recordOffset = offset >= 72 ? (offset - 72) % SM64OracleTraceRecord.encodedSize : -1
                print("phase85ci_native_full_trace=blocked")
                print("phase85ci_first_divergence_byte=\(offset) record=\(traceRecord) record_offset=\(recordOffset)")
                print("phase85ci_full_trace_c_swift_asan_release_pair=deferred")
                print("phase85ci_canonical_promotion=0")
            } else {
                print("phase85ci_native_full_trace_c_asan_release_match=1")
            }
            print("phase85ci_debug_rerun_fence=1")
            _ = release
        } catch {
            FileHandle.standardError.write(Data("phase85ci_behavior_semantic_mapping_failed=\(error)\n".utf8))
            exit(1)
        }
    }
}
