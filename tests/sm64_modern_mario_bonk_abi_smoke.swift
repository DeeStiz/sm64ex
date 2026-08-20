import Foundation

private func input(
    faceYaw: Int16 = 0,
    forwardVelocity: Float = 10,
    velocity: (Float, Float) = (1, 2),
    wallPresent: UInt32 = 0,
    wallAngle: Int16 = 0,
    negateSpeed: UInt32 = 0,
    metalCap: UInt32 = 0
) -> SM64ModernMarioBonkInputV1 {
    SM64ModernMarioBonkInputV1(
        header: SM64ModernAbiHeader(
            abi_version: SM64_MODERN_ABI_VERSION_1,
            struct_size: UInt32(MemoryLayout<SM64ModernMarioBonkInputV1>.size)
        ),
        simulation_tick: 1,
        face_yaw: Int32(faceYaw),
        forward_velocity_bits: forwardVelocity.bitPattern,
        velocity_x_bits: velocity.0.bitPattern,
        velocity_z_bits: velocity.1.bitPattern,
        wall_present: wallPresent,
        wall_angle: Int32(wallAngle),
        negate_speed: negateSpeed,
        metal_cap: metalCap,
        reserved: 0
    )
}

private func equal(
    _ lhs: SM64ModernMarioBonkOutputV1,
    _ rhs: SM64ModernMarioBonkOutputV1
) -> Bool {
    lhs.face_yaw == rhs.face_yaw
        && lhs.forward_velocity_bits == rhs.forward_velocity_bits
        && lhs.velocity_x_bits == rhs.velocity_x_bits
        && lhs.velocity_z_bits == rhs.velocity_z_bits
        && lhs.sound_kind == rhs.sound_kind
        && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioBonkABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioBonkAPI(service: service)
        precondition(sm64_modern_install_mario_bonk_api(&api) == SM64_MODERN_STATUS_OK)

        let cases = [
            input(),
            input(wallPresent: 1),
            input(wallPresent: 1, negateSpeed: 1),
            input(wallPresent: 1, wallAngle: 0x4000, metalCap: 1),
            input(negateSpeed: 1),
            input(faceYaw: Int16(bitPattern: 0x7000), wallPresent: 1,
                  wallAngle: Int16(bitPattern: 0x9000), negateSpeed: 1)
        ]
        for (caseIndex, var value) in cases.enumerated() {
            var swiftOutput = SM64ModernMarioBonkOutputV1()
            var cOutput = SM64ModernMarioBonkOutputV1()
            let swiftStatus = sm64_modern_gameplay_update_mario_bonk(&value, &swiftOutput)
            let cStatus = sm64_modern_gameplay_reference_mario_bonk(&value, &cOutput)
            precondition(swiftStatus == SM64_MODERN_STATUS_OK && cStatus == SM64_MODERN_STATUS_OK,
                         "bonk status case=\(caseIndex)")
            precondition(equal(swiftOutput, cOutput), "bonk ABI output case=\(caseIndex)")
        }
        let evidence = service.evidence()
        precondition(evidence.marioBonkUpdates == UInt64(cases.count))
        sm64_modern_uninstall_mario_bonk_api()
        print("SM64 Modern Mario bonk C-to-Swift ABI smoke passed updates=\(evidence.marioBonkUpdates)")
    }
}
