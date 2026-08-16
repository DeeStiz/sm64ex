import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hash(_ bytes: [UInt8]) -> UInt64 {
    bytes.reduce(fnvOffset) { ($0 ^ UInt64($1)) &* fnvPrime }
}

@main
enum SM64ModernSaveReplayArtifactSmoke {
    static func main() throws {
        guard CommandLine.arguments.count == 2 || CommandLine.arguments.count == 3 else {
            throw NSError(domain: "SM64ModernSaveReplayArtifactSmoke", code: 1)
        }

        if CommandLine.arguments[1] == "--read" {
            guard CommandLine.arguments.count == 3 else {
                throw NSError(domain: "SM64ModernSaveReplayArtifactSmoke", code: 2)
            }
            let artifact = try SM64SaveReplayArtifact.read(
                from: URL(fileURLWithPath: CommandLine.arguments[2])
            )
            precondition(artifact.authority == .cCompatibility)
            precondition(!artifact.requiresRestart)
            precondition(artifact.records.count == 3)
            precondition(artifact.records[0].direction == .swiftToC)
            precondition(artifact.records[2].direction == .cToSwift)
            print(String(
                format: "saveReplayArtifactReadFingerprint=0x%016llx",
                artifact.artifactHash
            ))
            return
        }

        let output = URL(fileURLWithPath: CommandLine.arguments[1])
        let records = [
            SM64SaveReplayRecord(
                sequence: 1, simulationTick: 17, direction: .cToSwift,
                operation: .mutation, saveFileIndex: 0, mutationKind: 3,
                mutationOperation: 0, sourceFileIndex: UInt32.max,
                saveRecoveryDecision: 0, menuRecoveryDecision: 0, status: 0,
                beforeSaveHash: hash([0x01]), beforeMenuHash: hash([0x02]),
                afterSaveHash: hash([0x03]), afterMenuHash: hash([0x04]),
                imageHash: hash([0x05])
            ),
            SM64SaveReplayRecord(
                sequence: 2, simulationTick: 18, direction: .cToSwift,
                operation: .recovery, saveFileIndex: 0, mutationKind: 0,
                mutationOperation: 0, sourceFileIndex: UInt32.max,
                saveRecoveryDecision: 2, menuRecoveryDecision: 1, status: 0,
                beforeSaveHash: hash([0x03]), beforeMenuHash: hash([0x04]),
                afterSaveHash: hash([0x03]), afterMenuHash: hash([0x04]),
                imageHash: hash([0x06])
            ),
            SM64SaveReplayRecord(
                sequence: 3, simulationTick: 19, direction: .swiftToC,
                operation: .persist, saveFileIndex: 0, mutationKind: 0,
                mutationOperation: 0, sourceFileIndex: UInt32.max,
                saveRecoveryDecision: 0, menuRecoveryDecision: 0, status: 0,
                beforeSaveHash: hash([0x03]), beforeMenuHash: hash([0x04]),
                afterSaveHash: hash([0x07]), afterMenuHash: hash([0x08]),
                imageHash: hash([0x09])
            ),
        ]
        let artifact = SM64SaveReplayArtifact(
            authority: .swift,
            requiresRestart: true,
            initialImageHash: hash([0x00]),
            finalImageHash: hash([0x09]),
            records: records
        )
        try artifact.write(to: output)
        let roundTrip = try SM64SaveReplayArtifact.read(from: output)
        precondition(roundTrip == artifact)
        precondition(roundTrip.records[1].saveRecoveryDecision == 2)
        print(String(
            format: "saveReplayArtifactFingerprint=0x%016llx",
            roundTrip.artifactHash
        ))
        print("SM64 Modern save replay artifact smoke passed")
    }
}
