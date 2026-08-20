import Foundation

private func input(
    forwardVelocity: Float,
    faceYaw: Int32,
    velocityY: Float
) -> SM64ModernMarioDeceleratingSpeedInputV1 {
    SM64ModernMarioDeceleratingSpeedInputV1(
        header: SM64ModernAbiHeader(
            abi_version: SM64_MODERN_ABI_VERSION_1,
            struct_size: UInt32(MemoryLayout<SM64ModernMarioDeceleratingSpeedInputV1>.size)
        ),
        simulation_tick: 1,
        forward_velocity_bits: forwardVelocity.bitPattern,
        face_yaw: faceYaw,
        velocity_y_bits: velocityY.bitPattern,
        reserved: 0
    )
}

private func equal(
    _ lhs: SM64ModernMarioDeceleratingSpeedOutputV1,
    _ rhs: SM64ModernMarioDeceleratingSpeedOutputV1
) -> Bool {
    lhs.stopped == rhs.stopped
        && lhs.forward_velocity_bits == rhs.forward_velocity_bits
        && lhs.velocity_x_bits == rhs.velocity_x_bits
        && lhs.velocity_y_bits == rhs.velocity_y_bits
        && lhs.velocity_z_bits == rhs.velocity_z_bits
        && lhs.update_moving_sand == rhs.update_moving_sand
        && lhs.update_windy_ground == rhs.update_windy_ground
        && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioDeceleratingSpeedABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioDeceleratingSpeedAPI(service: service)
        precondition(sm64_modern_install_mario_decelerating_speed_api(&api) == SM64_MODERN_STATUS_OK)

        let cases = [
            input(forwardVelocity: 12, faceYaw: 0, velocityY: 3),
            input(forwardVelocity: 0.5, faceYaw: 0x4000, velocityY: -4),
            input(forwardVelocity: 0, faceYaw: Int32(Int16(bitPattern: 0x8000)), velocityY: 0),
            input(forwardVelocity: -0.5, faceYaw: 0x2000, velocityY: 7),
            input(forwardVelocity: -8, faceYaw: -0x1555, velocityY: -2),
            input(forwardVelocity: 1, faceYaw: 0x6000, velocityY: 0)
        ]
        for (caseIndex, var value) in cases.enumerated() {
            var swiftOutput = SM64ModernMarioDeceleratingSpeedOutputV1()
            var cOutput = SM64ModernMarioDeceleratingSpeedOutputV1()
            let swiftStatus = sm64_modern_gameplay_update_mario_decelerating_speed(&value, &swiftOutput)
            let cStatus = sm64_modern_gameplay_reference_mario_decelerating_speed(&value, &cOutput)
            precondition(swiftStatus == SM64_MODERN_STATUS_OK && cStatus == SM64_MODERN_STATUS_OK,
                         "decelerating-speed status case=\(caseIndex)")
            precondition(equal(swiftOutput, cOutput), "decelerating-speed ABI output case=\(caseIndex)")
        }
        let evidence = service.evidence()
        precondition(evidence.marioDeceleratingSpeedUpdates == UInt64(cases.count))
        sm64_modern_uninstall_mario_decelerating_speed_api()
        print("SM64 Modern Mario decelerating-speed C-to-Swift ABI smoke passed updates=\(evidence.marioDeceleratingSpeedUpdates)")
    }
}
