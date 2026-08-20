import Foundation

private func floor(_ id: UInt32, _ height: Float, _ normalY: Float = 1,
                   present: UInt32 = 1) -> SM64ModernMarioGroundFloorProbeV1 {
    SM64ModernMarioGroundFloorProbeV1(
        present: present,
        surface_id: id,
        height_bits: height.bitPattern,
        normal_y_bits: normalY.bitPattern
    )
}

private func quarter(
    floor: SM64ModernMarioGroundFloorProbeV1,
    ceiling: Float = 1_000,
    water: Float = -11_000,
    wall: SM64ModernMarioGroundWallProbeV1 = SM64ModernMarioGroundWallProbeV1(
        present: 0, surface_id: 0, normal_x_bits: 0, normal_z_bits: 0, wall_angle: 0
    )
) -> SM64ModernMarioGroundQuarterProbeV1 {
    SM64ModernMarioGroundQuarterProbeV1(
        floor: floor,
        ceiling_height_bits: ceiling.bitPattern,
        water_level_bits: water.bitPattern,
        upper_wall: wall
    )
}

private func wall(_ id: UInt32, angle: Int16) -> SM64ModernMarioGroundWallProbeV1 {
    SM64ModernMarioGroundWallProbeV1(
        present: 1,
        surface_id: id,
        normal_x_bits: 0,
        normal_z_bits: 0,
        wall_angle: Int32(angle)
    )
}

private func input(
    position: (Float, Float, Float) = (0, 0, 0),
    velocity: (Float, Float, Float) = (4, 0, 0),
    floor: SM64ModernMarioGroundFloorProbeV1,
    probes: [SM64ModernMarioGroundQuarterProbeV1],
    ridingShell: UInt32 = 0
) -> SM64ModernMarioGroundStepInputV1 {
    precondition(probes.count == 4)
    var value = SM64ModernMarioGroundStepInputV1()
    value.header.abi_version = SM64_MODERN_ABI_VERSION_1
    value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioGroundStepInputV1>.size)
    value.simulation_tick = 1
    value.position_x_bits = position.0.bitPattern
    value.position_y_bits = position.1.bitPattern
    value.position_z_bits = position.2.bitPattern
    value.velocity_x_bits = velocity.0.bitPattern
    value.velocity_y_bits = velocity.1.bitPattern
    value.velocity_z_bits = velocity.2.bitPattern
    value.floor = floor
    value.face_yaw = 0
    value.native_step_scale_bits = Float(1).bitPattern
    value.riding_shell = ridingShell
    value.terrain_sound_addend = 0x30000
    value.quarter_probes.0 = probes[0]
    value.quarter_probes.1 = probes[1]
    value.quarter_probes.2 = probes[2]
    value.quarter_probes.3 = probes[3]
    return value
}

private func equal(
    _ lhs: SM64ModernMarioGroundStepOutputV1,
    _ rhs: SM64ModernMarioGroundStepOutputV1
) -> Bool {
    lhs.position_x_bits == rhs.position_x_bits
        && lhs.position_y_bits == rhs.position_y_bits
        && lhs.position_z_bits == rhs.position_z_bits
        && lhs.floor.present == rhs.floor.present
        && lhs.floor.surface_id == rhs.floor.surface_id
        && lhs.floor.height_bits == rhs.floor.height_bits
        && lhs.floor.normal_y_bits == rhs.floor.normal_y_bits
        && lhs.wall_present == rhs.wall_present
        && lhs.wall_surface_id == rhs.wall_surface_id
        && lhs.result == rhs.result
        && lhs.quarter_steps == rhs.quarter_steps
        && lhs.terrain_sound_addend == rhs.terrain_sound_addend
        && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioGroundStepABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioGroundStepAPI(service: service)
        precondition(sm64_modern_install_mario_ground_step_api(&api) == SM64_MODERN_STATUS_OK)

        let cases = [
            input(floor: floor(1, 0), probes: Array(repeating: quarter(floor: floor(2, 0)), count: 4)),
            input(floor: floor(1, 0), probes: Array(repeating: quarter(floor: floor(3, -200)), count: 4)),
            input(floor: floor(1, 0), probes: Array(repeating: quarter(floor: floor(4, 0), ceiling: 150), count: 4)),
            input(position: (0, 20, 0), floor: floor(9, 0), probes: Array(repeating: quarter(floor: floor(10, -20), water: 30), count: 4), ridingShell: 1),
            input(floor: floor(1, 0), probes: Array(repeating: quarter(floor: floor(0, 0, present: 0)), count: 4)),
            input(floor: floor(5, 0), probes: Array(repeating: quarter(floor: floor(5, 0), wall: wall(6, angle: 0)), count: 4)),
            input(floor: floor(7, 0), probes: Array(repeating: quarter(floor: floor(7, 0), wall: wall(8, angle: 0x4000)), count: 4))
        ]
        for var input in cases {
            var swiftOutput = SM64ModernMarioGroundStepOutputV1()
            var cOutput = SM64ModernMarioGroundStepOutputV1()
            precondition(sm64_modern_gameplay_update_mario_ground_step(&input, &swiftOutput) == SM64_MODERN_STATUS_OK)
            precondition(sm64_modern_gameplay_reference_mario_ground_step(&input, &cOutput) == SM64_MODERN_STATUS_OK)
            if !equal(swiftOutput, cOutput) {
                print("ground ABI mismatch swift=(\(swiftOutput.position_x_bits),\(swiftOutput.position_y_bits),\(swiftOutput.position_z_bits),\(swiftOutput.floor.present),\(swiftOutput.floor.surface_id),\(swiftOutput.wall_present),\(swiftOutput.wall_surface_id),\(swiftOutput.result),\(swiftOutput.quarter_steps)) c=(\(cOutput.position_x_bits),\(cOutput.position_y_bits),\(cOutput.position_z_bits),\(cOutput.floor.present),\(cOutput.floor.surface_id),\(cOutput.wall_present),\(cOutput.wall_surface_id),\(cOutput.result),\(cOutput.quarter_steps))")
            }
            if !equal(swiftOutput, cOutput) {
                print("ground-step ABI output diverged")
                return
            }
        }
        let evidence = service.evidence()
        precondition(evidence.marioGroundStepUpdates == UInt64(cases.count))
        sm64_modern_uninstall_mario_ground_step_api()
        print("SM64 Modern Mario ground-step C-to-Swift ABI smoke passed updates=\(evidence.marioGroundStepUpdates)")
    }
}
