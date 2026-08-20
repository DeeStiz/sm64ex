import Foundation

private func input(flags: UInt32, forwardVelocity: Float) -> SM64ModernMarioTripleJumpSelectorInputV1 {
    SM64ModernMarioTripleJumpSelectorInputV1(
        header: SM64ModernAbiHeader(
            abi_version: SM64_MODERN_ABI_VERSION_1,
            struct_size: UInt32(MemoryLayout<SM64ModernMarioTripleJumpSelectorInputV1>.size)
        ),
        simulation_tick: 1,
        mario_flags: flags,
        forward_velocity_bits: forwardVelocity.bitPattern,
        reserved: 0
    )
}

private func equal(
    _ lhs: SM64ModernMarioTripleJumpSelectorOutputV1,
    _ rhs: SM64ModernMarioTripleJumpSelectorOutputV1
) -> Bool {
    lhs.action == rhs.action
        && lhs.action_argument == rhs.action_argument
        && lhs.intent == rhs.intent
        && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioTripleJumpSelectorABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioTripleJumpSelectorAPI(service: service)
        precondition(sm64_modern_install_mario_triple_jump_selector_api(&api) == SM64_MODERN_STATUS_OK)

        let cases = [
            input(flags: 0x00000008, forwardVelocity: 0),
            input(flags: 0, forwardVelocity: 20.01),
            input(flags: 0, forwardVelocity: 20),
            input(flags: 0, forwardVelocity: -5)
        ]
        for (caseIndex, var value) in cases.enumerated() {
            var swiftOutput = SM64ModernMarioTripleJumpSelectorOutputV1()
            var cOutput = SM64ModernMarioTripleJumpSelectorOutputV1()
            let swiftStatus = sm64_modern_gameplay_update_mario_triple_jump_selector(&value, &swiftOutput)
            let cStatus = sm64_modern_gameplay_reference_mario_triple_jump_selector(&value, &cOutput)
            precondition(swiftStatus == SM64_MODERN_STATUS_OK && cStatus == SM64_MODERN_STATUS_OK,
                         "triple-jump status case=\(caseIndex)")
            precondition(equal(swiftOutput, cOutput), "triple-jump ABI output case=\(caseIndex)")
        }
        let evidence = service.evidence()
        precondition(evidence.marioTripleJumpSelectorUpdates == UInt64(cases.count))
        sm64_modern_uninstall_mario_triple_jump_selector_api()
        print("SM64 Modern Mario triple-jump-selector C-to-Swift ABI smoke passed updates=\(evidence.marioTripleJumpSelectorUpdates)")
    }
}
