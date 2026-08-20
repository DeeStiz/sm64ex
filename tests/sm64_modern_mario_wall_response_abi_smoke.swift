import Foundation

private func input(
    startX: Float,
    startZ: Float,
    x: Float,
    z: Float,
    velocityX: Float,
    velocityY: Float,
    velocityZ: Float,
    forwardVelocity: Float,
    faceYaw: Int32,
    frame: Int32,
    past1: UInt32 = 0,
    past2: UInt32 = 0,
    slope: Int32 = 0,
    wallAngle: Int32 = 0,
    wall: UInt32 = 0
) -> SM64ModernMarioWallResponseInputV1 {
    SM64ModernMarioWallResponseInputV1(
        header: SM64ModernAbiHeader(
            abi_version: SM64_MODERN_ABI_VERSION_1,
            struct_size: UInt32(MemoryLayout<SM64ModernMarioWallResponseInputV1>.size)
        ),
        simulation_tick: 1,
        start_position_x_bits: startX.bitPattern,
        start_position_z_bits: startZ.bitPattern,
        position_x_bits: x.bitPattern,
        position_z_bits: z.bitPattern,
        velocity_x_bits: velocityX.bitPattern,
        velocity_y_bits: velocityY.bitPattern,
        velocity_z_bits: velocityZ.bitPattern,
        forward_velocity_bits: forwardVelocity.bitPattern,
        face_yaw: faceYaw,
        animation_frame: frame,
        animation_past_frame1: past1,
        animation_past_frame2: past2,
        terrain_sound_addend: 3,
        floor_slope_pitch: slope,
        wall_present: wall,
        wall_angle: wallAngle,
        reserved: 0
    )
}

private func equal(
    _ lhs: SM64ModernMarioWallResponseOutputV1,
    _ rhs: SM64ModernMarioWallResponseOutputV1
) -> Bool {
    lhs.velocity_x_bits == rhs.velocity_x_bits
        && lhs.velocity_y_bits == rhs.velocity_y_bits
        && lhs.velocity_z_bits == rhs.velocity_z_bits
        && lhs.forward_velocity_bits == rhs.forward_velocity_bits
        && lhs.flags == rhs.flags
        && lhs.animation_id == rhs.animation_id
        && lhs.animation_acceleration == rhs.animation_acceleration
        && lhs.sound_kind == rhs.sound_kind
        && lhs.particle_dust == rhs.particle_dust
        && lhs.action_state == rhs.action_state
        && lhs.action_argument == rhs.action_argument
        && lhs.gfx_pitch == rhs.gfx_pitch
        && lhs.gfx_yaw == rhs.gfx_yaw
        && lhs.gfx_roll == rhs.gfx_roll
        && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioWallResponseABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioWallResponseAPI(service: service)
        precondition(sm64_modern_install_mario_wall_response_api(&api) == SM64_MODERN_STATUS_OK)

        let cases = [
            input(startX: 0, startZ: 0, x: 3, z: 4, velocityX: 1, velocityY: 2,
                  velocityZ: 3, forwardVelocity: 4, faceYaw: 0, frame: 22),
            input(startX: 1, startZ: -2, x: 2, z: 2, velocityX: 9, velocityY: -1,
                  velocityZ: 4, forwardVelocity: 8, faceYaw: 0x4000, frame: 3),
            input(startX: -4, startZ: 2, x: -1, z: 4, velocityX: -2, velocityY: 1,
                  velocityZ: 6, forwardVelocity: 5, faceYaw: 0, frame: 5,
                  past1: 1, slope: -0x1234, wallAngle: 0, wall: 1),
            input(startX: -4, startZ: 2, x: -1, z: 4, velocityX: -2, velocityY: 1,
                  velocityZ: 6, forwardVelocity: 5, faceYaw: 0, frame: 30,
                  slope: 0x1234, wallAngle: 0, wall: 1),
            input(startX: 0, startZ: 0, x: 1, z: 0, velocityX: 2, velocityY: 3,
                  velocityZ: 4, forwardVelocity: 6, faceYaw: 0, frame: 10,
                  wallAngle: 0x8000, wall: 1),
            input(startX: 0, startZ: 0, x: 1, z: 1, velocityX: 2, velocityY: 3,
                  velocityZ: 4, forwardVelocity: 6, faceYaw: 0x4000, frame: 10,
                  past2: 1, wallAngle: -0x4000, wall: 1)
        ]
        for (caseIndex, var value) in cases.enumerated() {
            var swiftOutput = SM64ModernMarioWallResponseOutputV1()
            var cOutput = SM64ModernMarioWallResponseOutputV1()
            let swiftStatus = sm64_modern_gameplay_update_mario_wall_response(&value, &swiftOutput)
            let cStatus = sm64_modern_gameplay_reference_mario_wall_response(&value, &cOutput)
            precondition(swiftStatus == SM64_MODERN_STATUS_OK && cStatus == SM64_MODERN_STATUS_OK,
                         "wall-response status case=\(caseIndex)")
            precondition(equal(swiftOutput, cOutput), "wall-response ABI output case=\(caseIndex)")
        }
        let evidence = service.evidence()
        precondition(evidence.marioWallResponseUpdates == UInt64(cases.count))
        sm64_modern_uninstall_mario_wall_response_api()
        print("SM64 Modern Mario wall-response C-to-Swift ABI smoke passed updates=\(evidence.marioWallResponseUpdates)")
    }
}
