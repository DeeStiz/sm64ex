import Foundation

private func input(
    bPressed: UInt32,
    forwardVelocity: Float,
    stickMagnitude: Float,
    velocityY: Float
) -> SM64ModernMarioGroundDivePunchInputV1 {
    SM64ModernMarioGroundDivePunchInputV1(
        header: SM64ModernAbiHeader(
            abi_version: SM64_MODERN_ABI_VERSION_1,
            struct_size: UInt32(MemoryLayout<SM64ModernMarioGroundDivePunchInputV1>.size)
        ),
        simulation_tick: 1,
        b_pressed: bPressed,
        forward_velocity_bits: forwardVelocity.bitPattern,
        stick_magnitude_bits: stickMagnitude.bitPattern,
        velocity_y_bits: velocityY.bitPattern,
        reserved: 0
    )
}

private func equal(
    _ lhs: SM64ModernMarioGroundDivePunchOutputV1,
    _ rhs: SM64ModernMarioGroundDivePunchOutputV1
) -> Bool {
    lhs.triggered == rhs.triggered
        && lhs.action == rhs.action
        && lhs.action_argument == rhs.action_argument
        && lhs.velocity_y_bits == rhs.velocity_y_bits
        && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioGroundDivePunchABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioGroundDivePunchAPI(service: service)
        precondition(sm64_modern_install_mario_ground_dive_punch_api(&api) == SM64_MODERN_STATUS_OK)

        let cases = [
            input(bPressed: 0, forwardVelocity: 40, stickMagnitude: 60, velocityY: 1),
            input(bPressed: 1, forwardVelocity: 28.99, stickMagnitude: 60, velocityY: 2),
            input(bPressed: 1, forwardVelocity: 29, stickMagnitude: 48, velocityY: 3),
            input(bPressed: 1, forwardVelocity: 29, stickMagnitude: 48.01, velocityY: -4)
        ]
        for (caseIndex, var value) in cases.enumerated() {
            var swiftOutput = SM64ModernMarioGroundDivePunchOutputV1()
            var cOutput = SM64ModernMarioGroundDivePunchOutputV1()
            let swiftStatus = sm64_modern_gameplay_update_mario_ground_dive_punch(&value, &swiftOutput)
            let cStatus = sm64_modern_gameplay_reference_mario_ground_dive_punch(&value, &cOutput)
            precondition(swiftStatus == SM64_MODERN_STATUS_OK && cStatus == SM64_MODERN_STATUS_OK,
                         "ground-dive-punch status case=\(caseIndex)")
            precondition(equal(swiftOutput, cOutput), "ground-dive-punch ABI output case=\(caseIndex)")
        }
        let evidence = service.evidence()
        precondition(evidence.marioGroundDivePunchUpdates == UInt64(cases.count))
        sm64_modern_uninstall_mario_ground_dive_punch_api()
        print("SM64 Modern Mario ground-dive-punch C-to-Swift ABI smoke passed updates=\(evidence.marioGroundDivePunchUpdates)")
    }
}
