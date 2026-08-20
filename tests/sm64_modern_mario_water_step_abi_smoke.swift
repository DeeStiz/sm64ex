import Foundation

private func floor(_ id: UInt32, _ height: Float, present: UInt32 = 1) -> SM64ModernMarioWaterFloorProbeV1 {
    SM64ModernMarioWaterFloorProbeV1(
        present: present,
        surface_id: id,
        height_bits: height.bitPattern
    )
}

private func wall(_ id: UInt32, present: UInt32 = 1) -> SM64ModernMarioWaterWallProbeV1 {
    SM64ModernMarioWaterWallProbeV1(present: present, surface_id: id, reserved: 0)
}

private func input(
    next: (Float, Float, Float),
    floorProbe: SM64ModernMarioWaterFloorProbeV1 = floor(1, 0),
    wall: SM64ModernMarioWaterWallProbeV1 = SM64ModernMarioWaterWallProbeV1(),
    ceiling: Float = 1_000
) -> SM64ModernMarioWaterStepInputV1 {
    var value = SM64ModernMarioWaterStepInputV1()
    value.header.abi_version = SM64_MODERN_ABI_VERSION_1
    value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioWaterStepInputV1>.size)
    value.simulation_tick = 1
    value.position_x_bits = Float(0).bitPattern
    value.position_y_bits = Float(10).bitPattern
    value.position_z_bits = Float(0).bitPattern
    value.next_position_x_bits = next.0.bitPattern
    value.next_position_y_bits = next.1.bitPattern
    value.next_position_z_bits = next.2.bitPattern
    value.current_floor = floor(1, 0)
    value.floor = floorProbe
    value.ceiling_height_bits = ceiling.bitPattern
    value.wall = wall
    return value
}

private func equal(
    _ lhs: SM64ModernMarioWaterStepOutputV1,
    _ rhs: SM64ModernMarioWaterStepOutputV1
) -> Bool {
    lhs.position_x_bits == rhs.position_x_bits
        && lhs.position_y_bits == rhs.position_y_bits
        && lhs.position_z_bits == rhs.position_z_bits
        && lhs.floor.present == rhs.floor.present
        && lhs.floor.surface_id == rhs.floor.surface_id
        && lhs.floor.height_bits == rhs.floor.height_bits
        && lhs.result == rhs.result
        && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioWaterStepABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioWaterStepAPI(service: service)
        precondition(sm64_modern_install_mario_water_step_api(&api) == SM64_MODERN_STATUS_OK)

        let cases = [
            input(next: (4, 20, 0)),
            input(next: (4, 20, 0), wall: wall(2)),
            input(next: (0, 20, 0), ceiling: 170),
            input(next: (0, -20, 0), ceiling: 200),
            input(next: (0, 20, 0), floorProbe: floor(0, 0, present: 0)),
            input(next: (0, 20, 0), floorProbe: floor(3, 0), ceiling: 150)
        ]
        for (caseIndex, var value) in cases.enumerated() {
            var swiftOutput = SM64ModernMarioWaterStepOutputV1()
            var cOutput = SM64ModernMarioWaterStepOutputV1()
            let swiftStatus = sm64_modern_gameplay_update_mario_water_step(&value, &swiftOutput)
            let cStatus = sm64_modern_gameplay_reference_mario_water_step(&value, &cOutput)
            precondition(swiftStatus == SM64_MODERN_STATUS_OK && cStatus == SM64_MODERN_STATUS_OK,
                         "water-step status case=\(caseIndex)")
            precondition(equal(swiftOutput, cOutput), "water-step ABI output case=\(caseIndex)")
        }
        let evidence = service.evidence()
        precondition(evidence.marioWaterStepUpdates == UInt64(cases.count))
        sm64_modern_uninstall_mario_water_step_api()
        print("SM64 Modern Mario water-step C-to-Swift ABI smoke passed updates=\(evidence.marioWaterStepUpdates)")
    }
}
