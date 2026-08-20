import Foundation

private func input(
    family: UInt32,
    floorType: UInt32,
    force: Int32 = 0x0100,
    moving: UInt32 = 1,
    faceYaw: Int32 = 0,
    forwardVelocity: Float = 10,
    timer: UInt32 = 1,
    velocity: (Float, Float) = (1, 2)
) -> SM64ModernMarioTerrainImpulseInputV1 {
    SM64ModernMarioTerrainImpulseInputV1(
        header: SM64ModernAbiHeader(
            abi_version: SM64_MODERN_ABI_VERSION_1,
            struct_size: UInt32(MemoryLayout<SM64ModernMarioTerrainImpulseInputV1>.size)
        ),
        simulation_tick: 1,
        family: family,
        floor_type: floorType,
        force: force,
        moving_action: moving,
        face_yaw: faceYaw,
        forward_velocity_bits: forwardVelocity.bitPattern,
        global_timer: timer,
        velocity_x_bits: velocity.0.bitPattern,
        velocity_z_bits: velocity.1.bitPattern,
        reserved: 0
    )
}

private func equal(
    _ lhs: SM64ModernMarioTerrainImpulseOutputV1,
    _ rhs: SM64ModernMarioTerrainImpulseOutputV1
) -> Bool {
    lhs.velocity_x_bits == rhs.velocity_x_bits
        && lhs.velocity_z_bits == rhs.velocity_z_bits
        && lhs.applied == rhs.applied
        && lhs.sound_kind == rhs.sound_kind
        && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioTerrainABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioTerrainImpulseAPI(service: service)
        precondition(sm64_modern_install_mario_terrain_impulse_api(&api) == SM64_MODERN_STATUS_OK)

        let cases = [
            input(family: SM64_MODERN_MARIO_TERRAIN_IMPULSE_MOVING_SAND, floorType: 0x0024),
            input(family: SM64_MODERN_MARIO_TERRAIN_IMPULSE_MOVING_SAND, floorType: 0x0027, force: 0x0300),
            input(family: SM64_MODERN_MARIO_TERRAIN_IMPULSE_MOVING_SAND, floorType: 0x0000),
            input(family: SM64_MODERN_MARIO_TERRAIN_IMPULSE_HORIZONTAL_WIND, floorType: 0x002C,
                  moving: 0, timer: 2),
            input(family: SM64_MODERN_MARIO_TERRAIN_IMPULSE_HORIZONTAL_WIND, floorType: 0x002C,
                  moving: 1, faceYaw: 0, forwardVelocity: 12),
            input(family: SM64_MODERN_MARIO_TERRAIN_IMPULSE_HORIZONTAL_WIND, floorType: 0x0000),
            input(family: SM64_MODERN_MARIO_TERRAIN_IMPULSE_MOVING_SAND, floorType: 0x0024,
                  force: 0x0000, velocity: (0, 0))
        ]
        for (caseIndex, var value) in cases.enumerated() {
            var swiftOutput = SM64ModernMarioTerrainImpulseOutputV1()
            var cOutput = SM64ModernMarioTerrainImpulseOutputV1()
            let swiftStatus = sm64_modern_gameplay_update_mario_terrain_impulse(&value, &swiftOutput)
            let cStatus = sm64_modern_gameplay_reference_mario_terrain_impulse(&value, &cOutput)
            precondition(swiftStatus == SM64_MODERN_STATUS_OK && cStatus == SM64_MODERN_STATUS_OK,
                         "terrain status case=\(caseIndex)")
            precondition(equal(swiftOutput, cOutput), "terrain ABI output case=\(caseIndex)")
        }
        let evidence = service.evidence()
        precondition(evidence.marioTerrainImpulseUpdates == UInt64(cases.count))
        sm64_modern_uninstall_mario_terrain_impulse_api()
        print("SM64 Modern Mario terrain-impulse C-to-Swift ABI smoke passed updates=\(evidence.marioTerrainImpulseUpdates)")
    }
}
