import Foundation

private func input(_ family: UInt32, velocity: Float, pitch: Int16, yaw: Int16) -> SM64ModernMarioVelocityDerivationInputV1 {
    SM64ModernMarioVelocityDerivationInputV1(
        header: SM64ModernAbiHeader(
            abi_version: SM64_MODERN_ABI_VERSION_1,
            struct_size: UInt32(MemoryLayout<SM64ModernMarioVelocityDerivationInputV1>.size)
        ),
        simulation_tick: 1,
        family: family,
        forward_velocity_bits: velocity.bitPattern,
        face_pitch: Int32(pitch),
        face_yaw: Int32(yaw),
        reserved: 0
    )
}

private func equal(
    _ lhs: SM64ModernMarioVelocityDerivationOutputV1,
    _ rhs: SM64ModernMarioVelocityDerivationOutputV1
) -> Bool {
    lhs.velocity_x_bits == rhs.velocity_x_bits
        && lhs.velocity_y_bits == rhs.velocity_y_bits
        && lhs.velocity_z_bits == rhs.velocity_z_bits
        && lhs.slide_velocity_x_bits == rhs.slide_velocity_x_bits
        && lhs.slide_velocity_z_bits == rhs.slide_velocity_z_bits
        && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioVelocityDerivationABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioVelocityDerivationAPI(service: service)
        precondition(sm64_modern_install_mario_velocity_derivation_api(&api) == SM64_MODERN_STATUS_OK)

        let cases = [
            input(SM64_MODERN_MARIO_VELOCITY_FROM_YAW, velocity: 10, pitch: 0, yaw: 0),
            input(SM64_MODERN_MARIO_VELOCITY_FROM_YAW, velocity: -16, pitch: 0, yaw: 0x4000),
            input(SM64_MODERN_MARIO_VELOCITY_FROM_YAW, velocity: 32, pitch: 0, yaw: Int16(bitPattern: 0x8000)),
            input(SM64_MODERN_MARIO_VELOCITY_FROM_PITCH_YAW, velocity: 10, pitch: 0x4000, yaw: 0),
            input(SM64_MODERN_MARIO_VELOCITY_FROM_PITCH_YAW, velocity: 10, pitch: 0x2000, yaw: 0x4000),
            input(SM64_MODERN_MARIO_VELOCITY_FROM_PITCH_YAW, velocity: -3.5, pitch: Int16(bitPattern: 0xF000), yaw: 0x1555)
        ]
        for (caseIndex, var value) in cases.enumerated() {
            var swiftOutput = SM64ModernMarioVelocityDerivationOutputV1()
            var cOutput = SM64ModernMarioVelocityDerivationOutputV1()
            let swiftStatus = sm64_modern_gameplay_update_mario_velocity_derivation(&value, &swiftOutput)
            let cStatus = sm64_modern_gameplay_reference_mario_velocity_derivation(&value, &cOutput)
            precondition(swiftStatus == SM64_MODERN_STATUS_OK && cStatus == SM64_MODERN_STATUS_OK,
                         "velocity-derivation status case=\(caseIndex)")
            precondition(equal(swiftOutput, cOutput), "velocity-derivation ABI output case=\(caseIndex)")
        }
        let evidence = service.evidence()
        precondition(evidence.marioVelocityDerivationUpdates == UInt64(cases.count))
        sm64_modern_uninstall_mario_velocity_derivation_api()
        print("SM64 Modern Mario velocity-derivation C-to-Swift ABI smoke passed updates=\(evidence.marioVelocityDerivationUpdates)")
    }
}
