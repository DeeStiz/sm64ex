import Foundation

private func input(
    intended: Float,
    intendedYaw: Int32,
    faceYaw: Int32,
    forward: Float,
    floorSlow: UInt32,
    normalY: Float,
    floorClass: SM64MarioFloorClass,
    terrainSlide: UInt32,
    normalX: Float,
    normalZ: Float,
    floorAngle: Int32,
    action: UInt32
) -> SM64ModernMarioShellSpeedInputV1 {
    SM64ModernMarioShellSpeedInputV1(
        header: SM64ModernAbiHeader(
            abi_version: SM64_MODERN_ABI_VERSION_1,
            struct_size: UInt32(MemoryLayout<SM64ModernMarioShellSpeedInputV1>.size)
        ),
        simulation_tick: 1,
        intended_magnitude_bits: intended.bitPattern,
        intended_yaw: intendedYaw,
        face_yaw: faceYaw,
        forward_velocity_bits: forward.bitPattern,
        floor_is_slow: floorSlow,
        floor_normal_y_bits: normalY.bitPattern,
        floor_class: Int32(floorClass.rawValue),
        terrain_is_slide: terrainSlide,
        floor_normal_x_bits: normalX.bitPattern,
        floor_normal_z_bits: normalZ.bitPattern,
        floor_angle: floorAngle,
        action: action,
        reserved: 0
    )
}

private func equal(
    _ lhs: SM64ModernMarioShellSpeedOutputV1,
    _ rhs: SM64ModernMarioShellSpeedOutputV1
) -> Bool {
    lhs.forward_velocity_bits == rhs.forward_velocity_bits
        && lhs.face_yaw == rhs.face_yaw
        && lhs.slide_yaw == rhs.slide_yaw
        && lhs.slide_velocity_x_bits == rhs.slide_velocity_x_bits
        && lhs.slide_velocity_z_bits == rhs.slide_velocity_z_bits
        && lhs.velocity_x_bits == rhs.velocity_x_bits
        && lhs.velocity_y_bits == rhs.velocity_y_bits
        && lhs.velocity_z_bits == rhs.velocity_z_bits
        && lhs.facing_downhill == rhs.facing_downhill
        && lhs.floor_is_slope == rhs.floor_is_slope
        && lhs.floor_is_steep == rhs.floor_is_steep
        && lhs.update_moving_sand == rhs.update_moving_sand
        && lhs.update_windy_ground == rhs.update_windy_ground
        && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioShellSpeedABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioShellSpeedAPI(service: service)
        precondition(sm64_modern_install_mario_shell_speed_api(&api) == SM64_MODERN_STATUS_OK)

        let cases = [
            input(intended: 10, intendedYaw: 0, faceYaw: 0, forward: 0,
                  floorSlow: 0, normalY: 0.8, floorClass: .defaultClass,
                  terrainSlide: 0, normalX: 0.6, normalZ: 0, floorAngle: 0,
                  action: SM64MarioActionID.ridingShellGround),
            input(intended: 30, intendedYaw: 0x2000, faceYaw: 0, forward: 40,
                  floorSlow: 1, normalY: 1, floorClass: .defaultClass,
                  terrainSlide: 0, normalX: 0, normalZ: 0, floorAngle: 0,
                  action: SM64MarioActionID.ridingShellGround),
            input(intended: 4, intendedYaw: 0, faceYaw: 0x2000, forward: -2,
                  floorSlow: 0, normalY: 0.95, floorClass: .slippery,
                  terrainSlide: 0, normalX: 0.4, normalZ: 0.2, floorAngle: 0,
                  action: SM64MarioActionID.ridingShellGround),
            input(intended: 12, intendedYaw: 0x4000, faceYaw: 0, forward: 20,
                  floorSlow: 0, normalY: 0.8, floorClass: .verySlippery,
                  terrainSlide: 0, normalX: 0.6, normalZ: 0.2, floorAngle: 0,
                  action: SM64MarioActionID.ridingShellGround),
            input(intended: 2, intendedYaw: Int32(Int16(bitPattern: 0x8000)),
                  faceYaw: 0, forward: 10, floorSlow: 0, normalY: 1,
                  floorClass: .notSlippery, terrainSlide: 1, normalX: 0.1,
                  normalZ: 0.1, floorAngle: 0, action: SM64MarioActionID.ridingShellGround),
            input(intended: 20, intendedYaw: 0x1000, faceYaw: 0x3000, forward: 24,
                  floorSlow: 0, normalY: 0.9, floorClass: .slippery,
                  terrainSlide: 0, normalX: 0.3, normalZ: 0.5, floorAngle: 0x1000,
                  action: SM64MarioActionID.ridingShellGround)
        ]
        for (caseIndex, var value) in cases.enumerated() {
            var swiftOutput = SM64ModernMarioShellSpeedOutputV1()
            var cOutput = SM64ModernMarioShellSpeedOutputV1()
            let swiftStatus = sm64_modern_gameplay_update_mario_shell_speed(&value, &swiftOutput)
            let cStatus = sm64_modern_gameplay_reference_mario_shell_speed(&value, &cOutput)
            precondition(swiftStatus == SM64_MODERN_STATUS_OK && cStatus == SM64_MODERN_STATUS_OK,
                         "shell-speed status case=\(caseIndex)")
            precondition(equal(swiftOutput, cOutput), "shell-speed ABI output case=\(caseIndex)")
        }
        let evidence = service.evidence()
        precondition(evidence.marioShellSpeedUpdates == UInt64(cases.count))
        sm64_modern_uninstall_mario_shell_speed_api()
        print("SM64 Modern Mario shell-speed C-to-Swift ABI smoke passed updates=\(evidence.marioShellSpeedUpdates)")
    }
}
