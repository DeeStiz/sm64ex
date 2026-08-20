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

private func wall(_ id: UInt32, angle: Int16, type: UInt32 = 0) -> SM64ModernMarioAirWallProbeV1 {
    SM64ModernMarioAirWallProbeV1(
        present: 1,
        surface_id: id,
        surface_type: type,
        normal_x_bits: Float(0).bitPattern,
        normal_z_bits: Float(1).bitPattern,
        wall_angle: Int32(angle),
        reserved: 0
    )
}

private func quarter(
    floor: SM64ModernMarioGroundFloorProbeV1,
    ceiling: Float = 1_000,
    water: Float = -11_000,
    upper: SM64ModernMarioAirWallProbeV1 = SM64ModernMarioAirWallProbeV1(),
    lower: SM64ModernMarioAirWallProbeV1 = SM64ModernMarioAirWallProbeV1(),
    ledgeFloor: SM64ModernMarioGroundFloorProbeV1 = SM64ModernMarioGroundFloorProbeV1(),
    ledgePosition: (Float, Float, Float) = (0, 0, 0),
    ledgeAngle: Int16 = 0,
    ledgePresent: UInt32 = 0
) -> SM64ModernMarioAirQuarterProbeV1 {
    SM64ModernMarioAirQuarterProbeV1(
        floor: floor,
        ceiling_height_bits: ceiling.bitPattern,
        water_level_bits: water.bitPattern,
        upper_wall: upper,
        lower_wall: lower,
        ledge_floor: ledgeFloor,
        ledge_position_x_bits: ledgePosition.0.bitPattern,
        ledge_position_y_bits: ledgePosition.1.bitPattern,
        ledge_position_z_bits: ledgePosition.2.bitPattern,
        ledge_floor_angle: Int32(ledgeAngle),
        ledge_present: ledgePresent
    )
}

private func input(
    position: (Float, Float, Float) = (0, 0, 0),
    velocity: (Float, Float, Float) = (4, 10, 0),
    floor: SM64ModernMarioGroundFloorProbeV1 = floor(1, 0),
    probes: [SM64ModernMarioAirQuarterProbeV1],
    stepArg: UInt32 = 0,
    ceilPresent: UInt32 = 0,
    ceilType: UInt32 = 0,
    ridingShell: UInt32 = 0
) -> SM64ModernMarioAirStepInputV1 {
    precondition(probes.count == 4)
    var value = SM64ModernMarioAirStepInputV1()
    value.header.abi_version = SM64_MODERN_ABI_VERSION_1
    value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioAirStepInputV1>.size)
    value.simulation_tick = 1
    value.position_x_bits = position.0.bitPattern
    value.position_y_bits = position.1.bitPattern
    value.position_z_bits = position.2.bitPattern
    value.velocity_x_bits = velocity.0.bitPattern
    value.velocity_y_bits = velocity.1.bitPattern
    value.velocity_z_bits = velocity.2.bitPattern
    value.floor = floor
    value.face_pitch = 0
    value.face_yaw = 0
    value.face_roll = 0
    value.floor_angle = 0
    value.action = 0
    value.step_arg = stepArg
    value.native_step_scale_bits = Float(1).bitPattern
    value.riding_shell = ridingShell
    value.ceil_present = ceilPresent
    value.ceil_type = ceilType
    value.quarter_probes.0 = probes[0]
    value.quarter_probes.1 = probes[1]
    value.quarter_probes.2 = probes[2]
    value.quarter_probes.3 = probes[3]
    return value
}

private func equal(
    _ lhs: SM64ModernMarioAirStepOutputV1,
    _ rhs: SM64ModernMarioAirStepOutputV1
) -> Bool {
    lhs.position_x_bits == rhs.position_x_bits
        && lhs.position_y_bits == rhs.position_y_bits
        && lhs.position_z_bits == rhs.position_z_bits
        && lhs.velocity_y_bits == rhs.velocity_y_bits
        && lhs.floor.present == rhs.floor.present
        && lhs.floor.surface_id == rhs.floor.surface_id
        && lhs.floor.height_bits == rhs.floor.height_bits
        && lhs.floor.normal_y_bits == rhs.floor.normal_y_bits
        && lhs.wall.present == rhs.wall.present
        && lhs.wall.surface_id == rhs.wall.surface_id
        && lhs.wall.surface_type == rhs.wall.surface_type
        && lhs.wall.normal_x_bits == rhs.wall.normal_x_bits
        && lhs.wall.normal_z_bits == rhs.wall.normal_z_bits
        && lhs.wall.wall_angle == rhs.wall.wall_angle
        && lhs.result == rhs.result
        && lhs.quarter_steps == rhs.quarter_steps
        && lhs.flags_or == rhs.flags_or
        && lhs.face_pitch == rhs.face_pitch
        && lhs.face_yaw == rhs.face_yaw
        && lhs.face_roll == rhs.face_roll
        && lhs.floor_angle == rhs.floor_angle
        && lhs.terrain_sound_addend == rhs.terrain_sound_addend
        && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioAirStepABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioAirStepAPI(service: service)
        precondition(sm64_modern_install_mario_air_step_api(&api) == SM64_MODERN_STATUS_OK)

        let flat = Array(repeating: quarter(floor: floor(2, 0)), count: 4)
        let cases = [
            input(probes: flat),
            input(position: (0, 20, 0), velocity: (4, -80, 0), probes: flat),
            input(velocity: (0, 80, 0), probes: Array(repeating: quarter(floor: floor(3, 0), ceiling: 170), count: 4)),
            input(velocity: (0, 80, 0), probes: Array(repeating: quarter(floor: floor(4, 0), ceiling: 170), count: 4),
                  stepArg: 2, ceilPresent: 1, ceilType: 5),
            input(probes: Array(repeating: quarter(floor: floor(5, 0), upper: wall(6, angle: Int16(bitPattern: 0x8000))), count: 4)),
            input(probes: Array(repeating: quarter(floor: floor(7, 0), upper: wall(8, angle: 0x4000, type: 1)), count: 4)),
            input(position: (0, 50, 0), velocity: (4, 0, 0), probes: Array(repeating: quarter(
                    floor: floor(9, 0),
                    lower: wall(10, angle: 0),
                    ledgeFloor: floor(11, 200),
                    ledgePosition: (-60, 200, 0),
                    ledgeAngle: 0x2000,
                    ledgePresent: 1
                  ), count: 4), stepArg: 1),
            input(position: (0, 20, 0), probes: Array(repeating: quarter(
                floor: floor(12, 0, present: 0)
            ), count: 4))
        ]

        for (caseIndex, var value) in cases.enumerated() {
            var swiftOutput = SM64ModernMarioAirStepOutputV1()
            var cOutput = SM64ModernMarioAirStepOutputV1()
            let swiftStatus = sm64_modern_gameplay_update_mario_air_step(&value, &swiftOutput)
            let cStatus = sm64_modern_gameplay_reference_mario_air_step(&value, &cOutput)
            if swiftStatus != SM64_MODERN_STATUS_OK || cStatus != SM64_MODERN_STATUS_OK {
                print("air-step ABI status mismatch case=\(caseIndex) swift=\(swiftStatus) c=\(cStatus)")
                preconditionFailure("air-step ABI status")
            }
            if !equal(swiftOutput, cOutput) {
                print("air-step ABI mismatch case=\(caseIndex) swift=(\(swiftOutput.position_x_bits),\(swiftOutput.position_y_bits),\(swiftOutput.position_z_bits),\(swiftOutput.velocity_y_bits),\(swiftOutput.wall.present),\(swiftOutput.wall.surface_id),\(swiftOutput.result),\(swiftOutput.quarter_steps),\(swiftOutput.flags_or),\(swiftOutput.face_yaw),\(swiftOutput.floor_angle)) c=(\(cOutput.position_x_bits),\(cOutput.position_y_bits),\(cOutput.position_z_bits),\(cOutput.velocity_y_bits),\(cOutput.wall.present),\(cOutput.wall.surface_id),\(cOutput.result),\(cOutput.quarter_steps),\(cOutput.flags_or),\(cOutput.face_yaw),\(cOutput.floor_angle))")
                preconditionFailure("air-step ABI output diverged")
            }
        }
        let evidence = service.evidence()
        precondition(evidence.marioAirStepUpdates == UInt64(cases.count))
        sm64_modern_uninstall_mario_air_step_api()
        print("SM64 Modern Mario air-step C-to-Swift ABI smoke passed updates=\(evidence.marioAirStepUpdates)")
    }
}
