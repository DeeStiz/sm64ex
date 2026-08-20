import Foundation

private func input(
    floorClass: SM64MarioFloorClass,
    floorIsSlope: UInt32,
    normalX: Float,
    normalY: Float,
    normalZ: Float,
    intendedYaw: Int32,
    intendedMagnitude: Float,
    faceYaw: Int32,
    slideYaw: Int32,
    forwardVelocity: Float,
    slideVelocityX: Float,
    slideVelocityZ: Float,
    stopSpeed: Float
) -> SM64ModernMarioSlidingInputV1 {
    SM64ModernMarioSlidingInputV1(
        header: SM64ModernAbiHeader(
            abi_version: SM64_MODERN_ABI_VERSION_1,
            struct_size: UInt32(MemoryLayout<SM64ModernMarioSlidingInputV1>.size)
        ),
        simulation_tick: 1,
        floor_class: Int32(floorClass.rawValue),
        floor_is_slope: floorIsSlope,
        floor_normal_x_bits: normalX.bitPattern,
        floor_normal_y_bits: normalY.bitPattern,
        floor_normal_z_bits: normalZ.bitPattern,
        intended_yaw: intendedYaw,
        intended_magnitude_bits: intendedMagnitude.bitPattern,
        face_yaw: faceYaw,
        slide_yaw: slideYaw,
        forward_velocity_bits: forwardVelocity.bitPattern,
        slide_velocity_x_bits: slideVelocityX.bitPattern,
        slide_velocity_z_bits: slideVelocityZ.bitPattern,
        stop_speed_bits: stopSpeed.bitPattern,
        reserved: 0
    )
}

private func equal(
    _ lhs: SM64ModernMarioSlidingOutputV1,
    _ rhs: SM64ModernMarioSlidingOutputV1
) -> Bool {
    lhs.stopped == rhs.stopped
        && lhs.face_yaw == rhs.face_yaw
        && lhs.slide_yaw == rhs.slide_yaw
        && lhs.forward_velocity_bits == rhs.forward_velocity_bits
        && lhs.slide_velocity_x_bits == rhs.slide_velocity_x_bits
        && lhs.slide_velocity_z_bits == rhs.slide_velocity_z_bits
        && lhs.velocity_x_bits == rhs.velocity_x_bits
        && lhs.velocity_y_bits == rhs.velocity_y_bits
        && lhs.velocity_z_bits == rhs.velocity_z_bits
        && lhs.update_moving_sand == rhs.update_moving_sand
        && lhs.update_windy_ground == rhs.update_windy_ground
        && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioSlidingABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioSlidingAPI(service: service)
        precondition(sm64_modern_install_mario_sliding_api(&api) == SM64_MODERN_STATUS_OK)

        let cases = [
            input(floorClass: .defaultClass, floorIsSlope: 0, normalX: 0, normalY: 1, normalZ: 0,
                  intendedYaw: 0, intendedMagnitude: 0, faceYaw: 0, slideYaw: 0,
                  forwardVelocity: 2, slideVelocityX: 2, slideVelocityZ: 0, stopSpeed: 5),
            input(floorClass: .defaultClass, floorIsSlope: 1, normalX: 0.5, normalY: 0.8660254, normalZ: 0,
                  intendedYaw: 0x2000, intendedMagnitude: 24, faceYaw: 0, slideYaw: 0x1000,
                  forwardVelocity: 20, slideVelocityX: 16, slideVelocityZ: 4, stopSpeed: 5),
            input(floorClass: .slippery, floorIsSlope: 0, normalX: 0.2, normalY: 0.98, normalZ: 0.1,
                  intendedYaw: 0x8000, intendedMagnitude: 32, faceYaw: 0x1000, slideYaw: 0,
                  forwardVelocity: 24, slideVelocityX: 22, slideVelocityZ: -6, stopSpeed: 1),
            input(floorClass: .verySlippery, floorIsSlope: 1, normalX: 0.6, normalY: 0.8, normalZ: 0.2,
                  intendedYaw: Int32(Int16(bitPattern: 0x9000)), intendedMagnitude: 40,
                  faceYaw: Int32(Int16(bitPattern: 0x7000)), slideYaw: Int32(Int16(bitPattern: 0x8000)),
                  forwardVelocity: -10, slideVelocityX: -12, slideVelocityZ: 30, stopSpeed: 6),
            input(floorClass: .notSlippery, floorIsSlope: 0, normalX: 0, normalY: 1, normalZ: 0,
                  intendedYaw: 0x4000, intendedMagnitude: 16, faceYaw: 0, slideYaw: 0x4000,
                  forwardVelocity: 0, slideVelocityX: 0.5, slideVelocityZ: 0.5, stopSpeed: 4),
            input(floorClass: .notSlippery, floorIsSlope: 1, normalX: -0.4, normalY: 0.9, normalZ: 0.3,
                  intendedYaw: 0x1000, intendedMagnitude: 8, faceYaw: 0x5000, slideYaw: 0x3000,
                  forwardVelocity: 8, slideVelocityX: 70, slideVelocityZ: 70, stopSpeed: 4)
        ]
        for (caseIndex, var value) in cases.enumerated() {
            var swiftOutput = SM64ModernMarioSlidingOutputV1()
            var cOutput = SM64ModernMarioSlidingOutputV1()
            let swiftStatus = sm64_modern_gameplay_update_mario_sliding(&value, &swiftOutput)
            let cStatus = sm64_modern_gameplay_reference_mario_sliding(&value, &cOutput)
            precondition(swiftStatus == SM64_MODERN_STATUS_OK && cStatus == SM64_MODERN_STATUS_OK,
                         "sliding status case=\(caseIndex)")
            precondition(equal(swiftOutput, cOutput), "sliding ABI output case=\(caseIndex)")
        }
        let evidence = service.evidence()
        precondition(evidence.marioSlidingUpdates == UInt64(cases.count))
        sm64_modern_uninstall_mario_sliding_api()
        print("SM64 Modern Mario sliding C-to-Swift ABI smoke passed updates=\(evidence.marioSlidingUpdates)")
    }
}
