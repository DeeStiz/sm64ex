import Darwin
import Foundation

private func ownerThreadToken() -> UInt64 {
    var identifier: UInt64 = 0
    precondition(pthread_threadid_np(nil, &identifier) == 0)
    return identifier
}

private func makeInput(
    tick: UInt64,
    start: Bool = false,
    confirm: Bool = false,
    delta: Int16 = 0
) -> SM64ModernFrontEndInputV1 {
    var input = SM64ModernFrontEndInputV1()
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1
    input.header.struct_size = UInt32(MemoryLayout<SM64ModernFrontEndInputV1>.size)
    input.simulation_tick = tick
    input.advance_legacy_domain = 1
    input.start_pressed = start ? 1 : 0
    input.confirm_pressed = confirm ? 1 : 0
    input.back_pressed = 0
    input.has_activity = (start || confirm || delta != 0) ? 1 : 0
    input.debug_level_select = 0
    input.demo_complete = 0
    input.credits_complete = 0
    input.ending_complete = 0
    input.demo_count = 8
    input.selection_delta = delta
    input.reserved = 0
    return input
}

@main
enum SM64ModernFrontEndMigrationSmoke {
    static func main() {
        let service = SwiftFrontEndMigrationService(ownerThreadToken: ownerThreadToken())
        var api = service.makeAPI()
        precondition(sm64_modern_install_frontend_migration_api(&api) == SM64_MODERN_STATUS_OK)

        let inputs = [
            makeInput(tick: 1),
            makeInput(tick: 2, start: true),
            makeInput(tick: 3, delta: 1),
            makeInput(tick: 4, confirm: true),
            makeInput(tick: 5, delta: 2),
            makeInput(tick: 6, confirm: true)
        ]
        var output = SM64ModernFrontEndOutputV1()
        for var input in inputs {
            precondition(
                sm64_modern_frontend_evaluate(&input, &output)
                    == SM64_MODERN_STATUS_OK
            )
        }
        precondition(output.screen == SM64_MODERN_FRONT_END_SCREEN_GAMEPLAY)
        precondition(output.transition == SM64_MODERN_FRONT_END_TRANSITION_START_LEVEL)
        precondition(output.selected_course == 3)
        precondition(output.selected_level == 3)
        let summary = service.summary()
        precondition(summary.events == inputs.count)
        precondition(summary.transitions == 3)
        sm64_modern_uninstall_frontend_migration_api()

        print("frontEndMigrationFingerprint=0x\(String(summary.fingerprint, radix: 16))")
        print("frontEndMigrationEvents=\(summary.events)")
        print("frontEndMigrationTransitions=\(summary.transitions)")
        print("SM64 Modern front-end migration smoke passed")
    }
}
