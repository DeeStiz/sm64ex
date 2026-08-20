import Foundation

private func input(faceYaw: Int32, floorAngle: Int32, forward: Float) -> SM64ModernMarioSteepJumpInputV1 {
    SM64ModernMarioSteepJumpInputV1(
        header: SM64ModernAbiHeader(
            abi_version: SM64_MODERN_ABI_VERSION_1,
            struct_size: UInt32(MemoryLayout<SM64ModernMarioSteepJumpInputV1>.size)
        ),
        simulation_tick: 1,
        face_yaw: faceYaw,
        floor_angle: floorAngle,
        forward_velocity_bits: forward.bitPattern,
        reserved: 0
    )
}

private func equal(
    _ lhs: SM64ModernMarioSteepJumpOutputV1,
    _ rhs: SM64ModernMarioSteepJumpOutputV1
) -> Bool {
    lhs.action == rhs.action
        && lhs.steep_jump_yaw == rhs.steep_jump_yaw
        && lhs.forward_velocity_bits == rhs.forward_velocity_bits
        && lhs.face_yaw == rhs.face_yaw
        && lhs.should_drop_held_object == rhs.should_drop_held_object
        && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioSteepJumpABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioSteepJumpAPI(service: service)
        precondition(sm64_modern_install_mario_steep_jump_api(&api) == SM64_MODERN_STATUS_OK)
        let cases = [
            input(faceYaw: 0, floorAngle: -32768, forward: 12),
            input(faceYaw: 0x2000, floorAngle: -32768, forward: 12),
            input(faceYaw: -0x4000, floorAngle: 0x2000, forward: 0),
            input(faceYaw: -0x1000, floorAngle: 0x3000, forward: -8)
        ]
        for (caseIndex, var value) in cases.enumerated() {
            var swiftOutput = SM64ModernMarioSteepJumpOutputV1()
            var cOutput = SM64ModernMarioSteepJumpOutputV1()
            let swiftStatus = sm64_modern_gameplay_update_mario_steep_jump(&value, &swiftOutput)
            let cStatus = sm64_modern_gameplay_reference_mario_steep_jump(&value, &cOutput)
            precondition(swiftStatus == SM64_MODERN_STATUS_OK && cStatus == SM64_MODERN_STATUS_OK,
                         "steep-jump status case=\(caseIndex)")
            precondition(equal(swiftOutput, cOutput), "steep-jump ABI output case=\(caseIndex)")
        }
        let evidence = service.evidence()
        precondition(evidence.marioSteepJumpUpdates == UInt64(cases.count))
        sm64_modern_uninstall_mario_steep_jump_api()
        print("SM64 Modern Mario steep-jump C-to-Swift ABI smoke passed updates=\(evidence.marioSteepJumpUpdates)")
    }
}
