import Foundation

private func input(
    initial: Float,
    forward: Float,
    multiplier: Float,
    squish: UInt32,
    quicksand: Float
) -> SM64ModernMarioYVelocityInputV1 {
    SM64ModernMarioYVelocityInputV1(
        header: SM64ModernAbiHeader(
            abi_version: SM64_MODERN_ABI_VERSION_1,
            struct_size: UInt32(MemoryLayout<SM64ModernMarioYVelocityInputV1>.size)
        ),
        simulation_tick: 1,
        initial_velocity_y_bits: initial.bitPattern,
        forward_velocity_bits: forward.bitPattern,
        multiplier_bits: multiplier.bitPattern,
        squish_timer: squish,
        quicksand_depth_bits: quicksand.bitPattern,
        reserved: 0
    )
}

private func equal(
    _ lhs: SM64ModernMarioYVelocityOutputV1,
    _ rhs: SM64ModernMarioYVelocityOutputV1
) -> Bool {
    lhs.velocity_y_bits == rhs.velocity_y_bits
        && lhs.half_speed_applied == rhs.half_speed_applied
        && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioYVelocityABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioYVelocityAPI(service: service)
        precondition(sm64_modern_install_mario_y_velocity_api(&api) == SM64_MODERN_STATUS_OK)
        let cases = [
            input(initial: 42, forward: 20, multiplier: 0.25, squish: 0, quicksand: 0),
            input(initial: 52, forward: 40, multiplier: 0.25, squish: 1, quicksand: 0),
            input(initial: 69, forward: 20, multiplier: 0, squish: 0, quicksand: 1.01),
            input(initial: -4, forward: -12, multiplier: 0.5, squish: 0, quicksand: 1)
        ]
        for (caseIndex, var value) in cases.enumerated() {
            var swiftOutput = SM64ModernMarioYVelocityOutputV1()
            var cOutput = SM64ModernMarioYVelocityOutputV1()
            let swiftStatus = sm64_modern_gameplay_update_mario_y_velocity(&value, &swiftOutput)
            let cStatus = sm64_modern_gameplay_reference_mario_y_velocity(&value, &cOutput)
            precondition(swiftStatus == SM64_MODERN_STATUS_OK && cStatus == SM64_MODERN_STATUS_OK,
                         "y-velocity status case=\(caseIndex)")
            precondition(equal(swiftOutput, cOutput), "y-velocity ABI output case=\(caseIndex)")
        }
        let evidence = service.evidence()
        precondition(evidence.marioYVelocityUpdates == UInt64(cases.count))
        sm64_modern_uninstall_mario_y_velocity_api()
        print("SM64 Modern Mario Y-velocity C-to-Swift ABI smoke passed updates=\(evidence.marioYVelocityUpdates)")
    }
}
