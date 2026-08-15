import Foundation

@main
struct SM64ModernRouteShardLedgerSmoke {
    static func main() throws {
        let manifest = """
        # sm64-modern-route-shards-v1
        # shard_id|domain|identity|source|input_seed|save_seed|expected_domains|status|notes
        0x0000000000000001|oracle_hook|input|fixture|0x0000000000000011|0x0000000000000022|input|planned|fixture
        """
        var ledger = try SM64RouteShardExecutionLedger(manifest: manifest)
        precondition(ledger.count == 1)
        precondition(ledger.plannedCount == 1)
        precondition(!ledger.allTerminal)
        try ledger.begin(id: 1)
        let runningState = try ledger.state(for: 1)
        precondition(runningState == .running)

        do {
            try ledger.finish(
                id: 1,
                state: .passed,
                evidence: SM64RouteShardExecutionEvidence(
                    expectedRecords: 0,
                    actualRecords: 0,
                    matchedRecords: 0
                )
            )
            preconditionFailure("partial evidence was accepted as passed")
        } catch let error as SM64RouteShardExecutionError {
            guard case .invalidTransition = error else { preconditionFailure("wrong failure: \(error)") }
        }

        try ledger.finish(
            id: 1,
            state: .passed,
            evidence: SM64RouteShardExecutionEvidence(
                expectedRecords: 1,
                actualRecords: 1,
                matchedRecords: 1
            )
        )
        let passedState = try ledger.state(for: 1)
        precondition(passedState == .passed)
        precondition(ledger.plannedCount == 0)
        precondition(ledger.terminalCount == 1)
        precondition(ledger.allTerminal)
        precondition(ledger.report().contains("0x0000000000000001|passed|1|1|1|"))

        do {
            try ledger.begin(id: 1)
            preconditionFailure("terminal shard was allowed to rerun")
        } catch let error as SM64RouteShardExecutionError {
            guard case .invalidTransition = error else { preconditionFailure("wrong terminal failure: \(error)") }
        }
        print("SM64 Modern route-shard ledger smoke passed transition_fence=1 partial_pass_rejected=1")
    }
}
