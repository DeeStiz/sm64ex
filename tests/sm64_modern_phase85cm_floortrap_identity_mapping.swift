import Foundation

private enum Phase85CMError: Error, CustomStringConvertible {
    case invalid(String)

    var description: String {
        switch self {
        case .invalid(let message): return message
        }
    }
}

private let expectedChild: UInt64 = 0xccb7_e7b3_ab11_7769
private let expectedParent: UInt64 = 0x0c68_8e3d_5e7a_403e

private func read(_ path: String) throws -> [SM64OracleTraceRecord] {
    try SM64OracleTraceFile.read(from: URL(fileURLWithPath: path)).records
}

private func require(_ path: String) throws {
    let records = try read(path)
    let child = records.first {
        $0.domain == 12 && $0.recordKind == 4 && $0.recordID == 4
            && $0.subjectID == 62 && $0.simulationTick == 1
            && $0.values == [0x35, expectedChild, 0x3c]
    }
    guard child != nil else {
        throw Phase85CMError.invalid("bhvFloorTrapInCastle identity missing in \(path)")
    }

    let parent = records.first {
        $0.domain == 3 && $0.recordKind == 1 && $0.recordID == 400
            && $0.subjectID == 60 && $0.simulationTick == 1
            && $0.values == [expectedParent]
    }
    guard parent != nil else {
        throw Phase85CMError.invalid("bhvCastleFloorTrap identity missing in \(path)")
    }

    print(
        "phase85cm_path=\(path) child_identity=0x\(String(expectedChild, radix: 16)) "
            + "parent_identity=0x\(String(expectedParent, radix: 16))"
    )
}

@main
struct SM64ModernPhase85CMFloorTrapIdentityMapping {
    static func main() {
        do {
            let paths = Array(CommandLine.arguments.dropFirst())
            guard paths.count >= 3 else {
                throw Phase85CMError.invalid("usage: phase85cm-floortrap-identity C ASAN RELEASE [RERUN]")
            }
            for path in paths {
                try require(path)
            }
            print("phase85cm_floortrap_source_identity_mapping=1")
        } catch {
            FileHandle.standardError.write(Data("phase85cm_floortrap_identity_failed=\(error)\n".utf8))
            exit(1)
        }
    }
}
