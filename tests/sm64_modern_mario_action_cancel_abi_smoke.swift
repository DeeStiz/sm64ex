import Foundation

private func input(
    flags: UInt32,
    health: Int32 = 0x880,
    quicksand: Float = 0,
    floorNormalY: Float = 1,
    actionState: UInt32 = 0,
    snow: UInt32 = 0,
    held: UInt32 = 0
) -> SM64ModernMarioActionCancelInputV1 {
    SM64ModernMarioActionCancelInputV1(
        header: SM64ModernAbiHeader(
            abi_version: SM64_MODERN_ABI_VERSION_1,
            struct_size: UInt32(MemoryLayout<SM64ModernMarioActionCancelInputV1>.size)
        ),
        simulation_tick: 1,
        family: SM64_MODERN_MARIO_ACTION_CANCEL_IDLE,
        current_action: SM64MarioActionID.idle,
        action_argument: 0,
        action_state: actionState,
        input: flags,
        health: health,
        quicksand_depth_bits: quicksand.bitPattern,
        floor_normal_y_bits: floorNormalY.bitPattern,
        terrain_is_snow: snow,
        held_object_present: held,
        intended_yaw: 0x3000,
        reserved: 0
    )
}

private func equal(
    _ lhs: SM64ModernMarioActionCancelOutputV1,
    _ rhs: SM64ModernMarioActionCancelOutputV1
) -> Bool {
    lhs.action == rhs.action
        && lhs.action_argument == rhs.action_argument
        && lhs.face_yaw == rhs.face_yaw
        && lhs.face_yaw_valid == rhs.face_yaw_valid
        && lhs.should_drop_held_object == rhs.should_drop_held_object
        && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioActionCancelABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioActionCancelAPI(service: service)
        precondition(sm64_modern_install_mario_action_cancel_api(&api) == SM64_MODERN_STATUS_OK)

        let cases: [SM64ModernMarioActionCancelInputV1] = [
            input(flags: 0x0002, held: 1),
            input(flags: 0x0001),
            input(flags: 0x0100),
            input(flags: 0, health: 0x200),
            input(flags: 0, quicksand: 31),
            input(flags: 0, floorNormalY: 0.2),
            input(flags: 0, actionState: 3, snow: 1),
            input(flags: 0x4000)
        ]
        for var input in cases {
            var swiftOutput = SM64ModernMarioActionCancelOutputV1()
            var cOutput = SM64ModernMarioActionCancelOutputV1()
            precondition(
                sm64_modern_gameplay_update_mario_action_cancel(&input, &swiftOutput)
                    == SM64_MODERN_STATUS_OK
            )
            precondition(
                sm64_modern_gameplay_reference_mario_action_cancel(&input, &cOutput)
                    == SM64_MODERN_STATUS_OK
            )
            precondition(equal(swiftOutput, cOutput), "action-cancel ABI output diverged")
        }
        let evidence = service.evidence()
        precondition(evidence.marioActionCancelUpdates == UInt64(cases.count))
        sm64_modern_uninstall_mario_action_cancel_api()
        print("SM64 Modern Mario action-cancel C-to-Swift ABI smoke passed updates=\(evidence.marioActionCancelUpdates)")
    }
}
