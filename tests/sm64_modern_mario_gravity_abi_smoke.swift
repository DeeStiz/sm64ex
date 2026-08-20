import Foundation

private func input(
    action: UInt32,
    marioFlags: UInt32 = 0,
    controllerInput: UInt32 = 0,
    angleVelocityY: Int32 = 0,
    velocityY: Float,
    unkC4: Float = 0
) -> SM64ModernMarioGravityInputV1 {
    SM64ModernMarioGravityInputV1(
        header: SM64ModernAbiHeader(
            abi_version: SM64_MODERN_ABI_VERSION_1,
            struct_size: UInt32(MemoryLayout<SM64ModernMarioGravityInputV1>.size)
        ),
        simulation_tick: 1,
        action: action,
        mario_flags: marioFlags,
        input: controllerInput,
        angle_velocity_y: angleVelocityY,
        velocity_y_bits: velocityY.bitPattern,
        unk_c4_bits: unkC4.bitPattern,
        reserved: 0
    )
}

private func equal(
    _ lhs: SM64ModernMarioGravityOutputV1,
    _ rhs: SM64ModernMarioGravityOutputV1
) -> Bool {
    lhs.velocity_y_bits == rhs.velocity_y_bits
        && lhs.wing_flutter == rhs.wing_flutter
        && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioGravityABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioGravityAPI(service: service)
        precondition(sm64_modern_install_mario_gravity_api(&api) == SM64_MODERN_STATUS_OK)

        let cases = [
            input(action: 0, velocityY: -74),
            input(action: SM64MarioActionID.shotFromCannon, velocityY: -74),
            input(action: SM64MarioActionID.longJump, velocityY: -74),
            input(action: SM64MarioActionID.lavaBoost, velocityY: -64),
            input(action: 0x010208B8, velocityY: -70, unkC4: 3.2),
            input(action: SM64MarioActionID.jump, marioFlags: 0x00000100, velocityY: 40),
            input(action: SM64MarioActionID.metalWaterWalking, velocityY: -15),
            input(action: 0, marioFlags: 0x00000008, controllerInput: SM64_MODERN_MARIO_INPUT_A_DOWN,
                  velocityY: -36),
            input(action: SM64MarioActionID.twirling, angleVelocityY: 2048, velocityY: -70),
            input(action: SM64MarioActionID.twirling, angleVelocityY: 0, velocityY: 5),
            input(action: SM64MarioActionID.fallAfterStarGrab, velocityY: -64)
        ]
        for (caseIndex, var value) in cases.enumerated() {
            var swiftOutput = SM64ModernMarioGravityOutputV1()
            var cOutput = SM64ModernMarioGravityOutputV1()
            let swiftStatus = sm64_modern_gameplay_update_mario_gravity(&value, &swiftOutput)
            let cStatus = sm64_modern_gameplay_reference_mario_gravity(&value, &cOutput)
            precondition(swiftStatus == SM64_MODERN_STATUS_OK && cStatus == SM64_MODERN_STATUS_OK,
                         "gravity status case=\(caseIndex)")
            precondition(equal(swiftOutput, cOutput), "gravity ABI output case=\(caseIndex)")
        }
        let evidence = service.evidence()
        precondition(evidence.marioGravityUpdates == UInt64(cases.count))
        sm64_modern_uninstall_mario_gravity_api()
        print("SM64 Modern Mario gravity C-to-Swift ABI smoke passed updates=\(evidence.marioGravityUpdates)")
    }
}
