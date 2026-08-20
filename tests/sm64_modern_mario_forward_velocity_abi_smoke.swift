import Foundation

private func input(_ velocity: Float, yaw: Int16) -> SM64ModernMarioForwardVelocityInputV1 {
    SM64ModernMarioForwardVelocityInputV1(
        header: SM64ModernAbiHeader(
            abi_version: SM64_MODERN_ABI_VERSION_1,
            struct_size: UInt32(MemoryLayout<SM64ModernMarioForwardVelocityInputV1>.size)
        ),
        simulation_tick: 1,
        forward_velocity_bits: velocity.bitPattern,
        face_yaw: Int32(yaw),
        reserved: 0
    )
}

private func equal(
    _ lhs: SM64ModernMarioForwardVelocityOutputV1,
    _ rhs: SM64ModernMarioForwardVelocityOutputV1
) -> Bool {
    lhs.forward_velocity_bits == rhs.forward_velocity_bits
        && lhs.slide_velocity_x_bits == rhs.slide_velocity_x_bits
        && lhs.slide_velocity_z_bits == rhs.slide_velocity_z_bits
        && lhs.velocity_x_bits == rhs.velocity_x_bits
        && lhs.velocity_z_bits == rhs.velocity_z_bits
        && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioForwardVelocityABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioForwardVelocityAPI(service: service)
        precondition(sm64_modern_install_mario_forward_velocity_api(&api) == SM64_MODERN_STATUS_OK)

        let cases = [
            input(0, yaw: 0), input(10, yaw: 0), input(-16, yaw: 0x4000),
            input(32, yaw: Int16(bitPattern: 0x8000)), input(0.125, yaw: 0x1555),
            input(-3.5, yaw: Int16(bitPattern: 0xF000))
        ]
        for (caseIndex, var value) in cases.enumerated() {
            var swiftOutput = SM64ModernMarioForwardVelocityOutputV1()
            var cOutput = SM64ModernMarioForwardVelocityOutputV1()
            let swiftStatus = sm64_modern_gameplay_update_mario_forward_velocity(&value, &swiftOutput)
            let cStatus = sm64_modern_gameplay_reference_mario_forward_velocity(&value, &cOutput)
            precondition(swiftStatus == SM64_MODERN_STATUS_OK && cStatus == SM64_MODERN_STATUS_OK,
                         "forward-velocity status case=\(caseIndex)")
            precondition(equal(swiftOutput, cOutput), "forward-velocity ABI output case=\(caseIndex)")
        }
        let evidence = service.evidence()
        precondition(evidence.marioForwardVelocityUpdates == UInt64(cases.count))
        sm64_modern_uninstall_mario_forward_velocity_api()
        print("SM64 Modern Mario forward-velocity C-to-Swift ABI smoke passed updates=\(evidence.marioForwardVelocityUpdates)")
    }
}
