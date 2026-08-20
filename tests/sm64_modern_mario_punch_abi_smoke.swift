import Foundation

private func input(
    argument: UInt32,
    frame: Int32,
    atEnd: UInt32 = 0,
    pastEnd: UInt32 = 0,
    bPressed: UInt32 = 0,
    moving: UInt32 = 0
) -> SM64ModernMarioPunchInputV1 {
    SM64ModernMarioPunchInputV1(
        header: SM64ModernAbiHeader(
            abi_version: SM64_MODERN_ABI_VERSION_1,
            struct_size: UInt32(MemoryLayout<SM64ModernMarioPunchInputV1>.size)
        ),
        simulation_tick: 1,
        moving_action: moving,
        action_argument: argument,
        animation_frame: frame,
        animation_at_end: atEnd,
        animation_past_end: pastEnd,
        b_pressed: bPressed,
        reserved: 0
    )
}

private func equal(
    _ lhs: SM64ModernMarioPunchOutputV1,
    _ rhs: SM64ModernMarioPunchOutputV1
) -> Bool {
    lhs.action_argument == rhs.action_argument
        && lhs.animation_id == rhs.animation_id
        && lhs.transition_action == rhs.transition_action
        && lhs.flags == rhs.flags
        && lhs.punch_state == rhs.punch_state
        && lhs.punch_state_valid == rhs.punch_state_valid
        && lhs.sound_kind == rhs.sound_kind
        && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioPunchABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioPunchAPI(service: service)
        precondition(sm64_modern_install_mario_punch_api(&api) == SM64_MODERN_STATUS_OK)

        let cases = [
            input(argument: 0, frame: 2),
            input(argument: 1, frame: 0, pastEnd: 1),
            input(argument: 2, frame: 0, bPressed: 1),
            input(argument: 2, frame: 0, atEnd: 1, moving: 1),
            input(argument: 3, frame: 1, pastEnd: 1),
            input(argument: 5, frame: 0, atEnd: 1),
            input(argument: 6, frame: 0),
            input(argument: 6, frame: 9, atEnd: 1, moving: 1),
            input(argument: 9, frame: 3, atEnd: 1),
            input(argument: 4, frame: 0, pastEnd: 1, moving: 1)
        ]
        for (caseIndex, var value) in cases.enumerated() {
            var swiftOutput = SM64ModernMarioPunchOutputV1()
            var cOutput = SM64ModernMarioPunchOutputV1()
            let swiftStatus = sm64_modern_gameplay_update_mario_punch(&value, &swiftOutput)
            let cStatus = sm64_modern_gameplay_reference_mario_punch(&value, &cOutput)
            precondition(swiftStatus == SM64_MODERN_STATUS_OK && cStatus == SM64_MODERN_STATUS_OK,
                         "punch status case=\(caseIndex)")
            precondition(equal(swiftOutput, cOutput), "punch ABI output case=\(caseIndex)")
        }
        let evidence = service.evidence()
        precondition(evidence.marioPunchUpdates == UInt64(cases.count))
        sm64_modern_uninstall_mario_punch_api()
        print("SM64 Modern Mario punch C-to-Swift ABI smoke passed updates=\(evidence.marioPunchUpdates)")
    }
}
