import Foundation

private func input(
    friction: Float,
    floorClass: SM64MarioFloorClass,
    terrainSlide: UInt32,
    normalX: Float,
    normalY: Float,
    normalZ: Float,
    floorAngle: Int32,
    faceYaw: Int32,
    forwardVelocity: Float,
    action: UInt32
) -> SM64ModernMarioLandingAccelerationInputV1 {
    SM64ModernMarioLandingAccelerationInputV1(
        header: SM64ModernAbiHeader(
            abi_version: SM64_MODERN_ABI_VERSION_1,
            struct_size: UInt32(MemoryLayout<SM64ModernMarioLandingAccelerationInputV1>.size)
        ),
        simulation_tick: 1,
        friction_factor_bits: friction.bitPattern,
        floor_class: Int32(floorClass.rawValue),
        terrain_is_slide: terrainSlide,
        floor_normal_x_bits: normalX.bitPattern,
        floor_normal_y_bits: normalY.bitPattern,
        floor_normal_z_bits: normalZ.bitPattern,
        floor_angle: floorAngle,
        face_yaw: faceYaw,
        forward_velocity_bits: forwardVelocity.bitPattern,
        action: action,
        reserved: 0
    )
}

private func equal(
    _ lhs: SM64ModernMarioLandingAccelerationOutputV1,
    _ rhs: SM64ModernMarioLandingAccelerationOutputV1
) -> Bool {
    lhs.stopped == rhs.stopped
        && lhs.forward_velocity_bits == rhs.forward_velocity_bits
        && lhs.slide_yaw == rhs.slide_yaw
        && lhs.slide_velocity_x_bits == rhs.slide_velocity_x_bits
        && lhs.slide_velocity_z_bits == rhs.slide_velocity_z_bits
        && lhs.velocity_x_bits == rhs.velocity_x_bits
        && lhs.velocity_y_bits == rhs.velocity_y_bits
        && lhs.velocity_z_bits == rhs.velocity_z_bits
        && lhs.floor_is_slope == rhs.floor_is_slope
        && lhs.update_moving_sand == rhs.update_moving_sand
        && lhs.update_windy_ground == rhs.update_windy_ground
        && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioLandingAccelerationABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioLandingAccelerationAPI(service: service)
        precondition(sm64_modern_install_mario_landing_acceleration_api(&api) == SM64_MODERN_STATUS_OK)

        let cases = [
            input(friction: 0.8, floorClass: .defaultClass, terrainSlide: 0,
                  normalX: 0, normalY: 1, normalZ: 0, floorAngle: 0, faceYaw: 0,
                  forwardVelocity: 3, action: SM64MarioActionID.idle),
            input(friction: 0.5, floorClass: .defaultClass, terrainSlide: 0,
                  normalX: 0, normalY: 1, normalZ: 0, floorAngle: 0, faceYaw: 0,
                  forwardVelocity: 0.5, action: SM64MarioActionID.idle),
            input(friction: 0.95, floorClass: .defaultClass, terrainSlide: 0,
                  normalX: 0.6, normalY: 0.8, normalZ: 0, floorAngle: 0, faceYaw: 0,
                  forwardVelocity: 12, action: SM64MarioActionID.idle),
            input(friction: 0.7, floorClass: .verySlippery, terrainSlide: 0,
                  normalX: 0.4, normalY: 0.99, normalZ: 0.2, floorAngle: 0x1000,
                  faceYaw: 0, forwardVelocity: 8, action: SM64MarioActionID.idle),
            input(friction: 0.8, floorClass: .notSlippery, terrainSlide: 1,
                  normalX: 0.1, normalY: 0.99, normalZ: 0.1, floorAngle: 0,
                  faceYaw: 0x2000, forwardVelocity: 1, action: SM64MarioActionID.idle),
            input(friction: 1.1, floorClass: .slippery, terrainSlide: 0,
                  normalX: 0.3, normalY: 0.95, normalZ: 0.4, floorAngle: 0,
                  faceYaw: Int32(Int16(bitPattern: 0x8000)), forwardVelocity: 20,
                  action: SM64MarioActionID.idle)
        ]
        for (caseIndex, var value) in cases.enumerated() {
            var swiftOutput = SM64ModernMarioLandingAccelerationOutputV1()
            var cOutput = SM64ModernMarioLandingAccelerationOutputV1()
            let swiftStatus = sm64_modern_gameplay_update_mario_landing_acceleration(&value, &swiftOutput)
            let cStatus = sm64_modern_gameplay_reference_mario_landing_acceleration(&value, &cOutput)
            precondition(swiftStatus == SM64_MODERN_STATUS_OK && cStatus == SM64_MODERN_STATUS_OK,
                         "landing-acceleration status case=\(caseIndex)")
            precondition(equal(swiftOutput, cOutput), "landing-acceleration ABI output case=\(caseIndex)")
        }
        let evidence = service.evidence()
        precondition(evidence.marioLandingAccelerationUpdates == UInt64(cases.count))
        sm64_modern_uninstall_mario_landing_acceleration_api()
        print("SM64 Modern Mario landing-acceleration C-to-Swift ABI smoke passed updates=\(evidence.marioLandingAccelerationUpdates)")
    }
}
