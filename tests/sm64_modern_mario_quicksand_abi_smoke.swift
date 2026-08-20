import Foundation

private func input(
    floorType: UInt32,
    depth: Float = 0,
    sinkingSpeed: Float = 1,
    ridingShell: UInt32 = 0
) -> SM64ModernMarioQuicksandInputV1 {
    SM64ModernMarioQuicksandInputV1(
        header: SM64ModernAbiHeader(
            abi_version: SM64_MODERN_ABI_VERSION_1,
            struct_size: UInt32(MemoryLayout<SM64ModernMarioQuicksandInputV1>.size)
        ),
        simulation_tick: 1,
        floor_type: floorType,
        riding_shell: ridingShell,
        quicksand_depth_bits: depth.bitPattern,
        sinking_speed_bits: sinkingSpeed.bitPattern,
        reserved: 0
    )
}

private func equal(
    _ lhs: SM64ModernMarioQuicksandOutputV1,
    _ rhs: SM64ModernMarioQuicksandOutputV1
) -> Bool {
    lhs.quicksand_depth_bits == rhs.quicksand_depth_bits
        && lhs.action == rhs.action
        && lhs.action_argument == rhs.action_argument
        && lhs.update_sound_camera == rhs.update_sound_camera
        && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioQuicksandABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioQuicksandAPI(service: service)
        precondition(sm64_modern_install_mario_quicksand_api(&api) == SM64_MODERN_STATUS_OK)

        let cases = [
            input(floorType: 0x0021),
            input(floorType: 0x0021, depth: 9, sinkingSpeed: 2),
            input(floorType: 0x0025, depth: 24, sinkingSpeed: 2),
            input(floorType: 0x0026, depth: 59, sinkingSpeed: 2),
            input(floorType: 0x0022, depth: 10, sinkingSpeed: 1),
            input(floorType: 0x0022, depth: 159, sinkingSpeed: 1),
            input(floorType: 0x0023),
            input(floorType: 0, depth: 30),
            input(floorType: 0x0022, depth: 150, ridingShell: 1)
        ]
        for (caseIndex, var value) in cases.enumerated() {
            var swiftOutput = SM64ModernMarioQuicksandOutputV1()
            var cOutput = SM64ModernMarioQuicksandOutputV1()
            let swiftStatus = sm64_modern_gameplay_update_mario_quicksand(&value, &swiftOutput)
            let cStatus = sm64_modern_gameplay_reference_mario_quicksand(&value, &cOutput)
            precondition(swiftStatus == SM64_MODERN_STATUS_OK && cStatus == SM64_MODERN_STATUS_OK,
                         "quicksand status case=\(caseIndex)")
            precondition(equal(swiftOutput, cOutput), "quicksand ABI output case=\(caseIndex)")
        }
        let evidence = service.evidence()
        precondition(evidence.marioQuicksandUpdates == UInt64(cases.count))
        sm64_modern_uninstall_mario_quicksand_api()
        print("SM64 Modern Mario quicksand C-to-Swift ABI smoke passed updates=\(evidence.marioQuicksandUpdates)")
    }
}
