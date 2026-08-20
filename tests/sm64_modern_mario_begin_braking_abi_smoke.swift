import Foundation

private func input(
    actionState: UInt32,
    actionArgument: UInt32,
    forwardVelocity: Float,
    floorNormalY: Float,
    faceYaw: Int32
) -> SM64ModernMarioBeginBrakingInputV1 {
    SM64ModernMarioBeginBrakingInputV1(
        header: SM64ModernAbiHeader(
            abi_version: SM64_MODERN_ABI_VERSION_1,
            struct_size: UInt32(MemoryLayout<SM64ModernMarioBeginBrakingInputV1>.size)
        ),
        simulation_tick: 1,
        action_state: actionState,
        action_argument: actionArgument,
        forward_velocity_bits: forwardVelocity.bitPattern,
        floor_normal_y_bits: floorNormalY.bitPattern,
        face_yaw: faceYaw,
        reserved: 0
    )
}

private func equal(
    _ lhs: SM64ModernMarioBeginBrakingOutputV1,
    _ rhs: SM64ModernMarioBeginBrakingOutputV1
) -> Bool {
    lhs.action == rhs.action
        && lhs.action_argument == rhs.action_argument
        && lhs.face_yaw == rhs.face_yaw
        && lhs.intent == rhs.intent
        && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioBeginBrakingABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioBeginBrakingAPI(service: service)
        precondition(sm64_modern_install_mario_begin_braking_api(&api) == SM64_MODERN_STATUS_OK)

        let cases = [
            input(actionState: 1, actionArgument: 0x9000, forwardVelocity: 4, floorNormalY: 1, faceYaw: 0),
            input(actionState: 0, actionArgument: 0, forwardVelocity: 16, floorNormalY: 0.17364818, faceYaw: 0x1000),
            input(actionState: 0, actionArgument: 0, forwardVelocity: 15.99, floorNormalY: 1, faceYaw: -0x2000),
            input(actionState: 0, actionArgument: 0, forwardVelocity: 30, floorNormalY: 0.1, faceYaw: 0x4000)
        ]
        for (caseIndex, var value) in cases.enumerated() {
            var swiftOutput = SM64ModernMarioBeginBrakingOutputV1()
            var cOutput = SM64ModernMarioBeginBrakingOutputV1()
            let swiftStatus = sm64_modern_gameplay_update_mario_begin_braking(&value, &swiftOutput)
            let cStatus = sm64_modern_gameplay_reference_mario_begin_braking(&value, &cOutput)
            precondition(swiftStatus == SM64_MODERN_STATUS_OK && cStatus == SM64_MODERN_STATUS_OK,
                         "begin-braking status case=\(caseIndex)")
            precondition(equal(swiftOutput, cOutput), "begin-braking ABI output case=\(caseIndex)")
        }
        let evidence = service.evidence()
        precondition(evidence.marioBeginBrakingUpdates == UInt64(cases.count))
        sm64_modern_uninstall_mario_begin_braking_api()
        print("SM64 Modern Mario begin-braking C-to-Swift ABI smoke passed updates=\(evidence.marioBeginBrakingUpdates)")
    }
}
