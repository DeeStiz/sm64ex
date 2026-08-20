import Foundation

private func input(
    floorAngle: Int16,
    faceYaw: Int16,
    action: UInt32 = 0x1234,
    argument: UInt32 = 7
) -> SM64ModernMarioSteepPushInputV1 {
    SM64ModernMarioSteepPushInputV1(
        header: SM64ModernAbiHeader(
            abi_version: SM64_MODERN_ABI_VERSION_1,
            struct_size: UInt32(MemoryLayout<SM64ModernMarioSteepPushInputV1>.size)
        ),
        simulation_tick: 1,
        floor_angle: Int32(floorAngle),
        face_yaw: Int32(faceYaw),
        action: action,
        action_argument: argument,
        reserved: 0
    )
}

private func equal(
    _ lhs: SM64ModernMarioSteepPushOutputV1,
    _ rhs: SM64ModernMarioSteepPushOutputV1
) -> Bool {
    lhs.forward_velocity_bits == rhs.forward_velocity_bits
        && lhs.face_yaw == rhs.face_yaw
        && lhs.action == rhs.action
        && lhs.action_argument == rhs.action_argument
        && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioSteepPushABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioSteepPushAPI(service: service)
        precondition(sm64_modern_install_mario_steep_push_api(&api) == SM64_MODERN_STATUS_OK)

        let cases = [
            input(floorAngle: 0, faceYaw: 0),
            input(floorAngle: 0x2000, faceYaw: 0),
            input(floorAngle: 0x4000, faceYaw: 0),
            input(floorAngle: Int16(bitPattern: 0x8000), faceYaw: 0),
            input(floorAngle: 0x7000, faceYaw: Int16(bitPattern: 0xF000), action: 0xDEAD, argument: 2)
        ]
        for (caseIndex, var value) in cases.enumerated() {
            var swiftOutput = SM64ModernMarioSteepPushOutputV1()
            var cOutput = SM64ModernMarioSteepPushOutputV1()
            let swiftStatus = sm64_modern_gameplay_update_mario_steep_push(&value, &swiftOutput)
            let cStatus = sm64_modern_gameplay_reference_mario_steep_push(&value, &cOutput)
            precondition(swiftStatus == SM64_MODERN_STATUS_OK && cStatus == SM64_MODERN_STATUS_OK,
                         "steep-push status case=\(caseIndex)")
            precondition(equal(swiftOutput, cOutput), "steep-push ABI output case=\(caseIndex)")
        }
        let evidence = service.evidence()
        precondition(evidence.marioSteepPushUpdates == UInt64(cases.count))
        sm64_modern_uninstall_mario_steep_push_api()
        print("SM64 Modern Mario steep-push C-to-Swift ABI smoke passed updates=\(evidence.marioSteepPushUpdates)")
    }
}
