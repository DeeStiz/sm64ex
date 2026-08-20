import Foundation

private func input(
    variant: UInt32,
    intended: Float,
    forward: Float,
    quicksand: Float = 0,
    timer: UInt32,
    past1: UInt32 = 0,
    past2: UInt32 = 0,
    metal: UInt32 = 0
) -> SM64ModernMarioHeldWalkAnimationInputV1 {
    SM64ModernMarioHeldWalkAnimationInputV1(
        header: SM64ModernAbiHeader(
            abi_version: SM64_MODERN_ABI_VERSION_1,
            struct_size: UInt32(MemoryLayout<SM64ModernMarioHeldWalkAnimationInputV1>.size)
        ),
        simulation_tick: 1,
        variant: variant,
        intended_magnitude_bits: intended.bitPattern,
        forward_velocity_bits: forward.bitPattern,
        quicksand_depth_bits: quicksand.bitPattern,
        action_timer: timer,
        animation_past_frame1: past1,
        animation_past_frame2: past2,
        metal_cap: metal,
        reserved: 0
    )
}

private func equal(
    _ lhs: SM64ModernMarioHeldWalkAnimationOutputV1,
    _ rhs: SM64ModernMarioHeldWalkAnimationOutputV1
) -> Bool {
    lhs.animation_id == rhs.animation_id
        && lhs.animation_acceleration == rhs.animation_acceleration
        && lhs.action_timer == rhs.action_timer
        && lhs.sound_kind == rhs.sound_kind
        && lhs.sound_frame1 == rhs.sound_frame1
        && lhs.sound_frame2 == rhs.sound_frame2
        && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioHeldWalkAnimationABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioHeldWalkAnimationAPI(service: service)
        precondition(sm64_modern_install_mario_held_walk_animation_api(&api) == SM64_MODERN_STATUS_OK)

        let cases = [
            input(variant: SM64_MODERN_MARIO_HELD_WALK_LIGHT, intended: 1, forward: 0, timer: 0),
            input(variant: SM64_MODERN_MARIO_HELD_WALK_LIGHT, intended: 7, forward: 0, timer: 0, past1: 1),
            input(variant: SM64_MODERN_MARIO_HELD_WALK_LIGHT, intended: 10, forward: 0, timer: 1, past2: 1, metal: 1),
            input(variant: SM64_MODERN_MARIO_HELD_WALK_LIGHT, intended: 13, forward: 0, timer: 1),
            input(variant: SM64_MODERN_MARIO_HELD_WALK_LIGHT, intended: 16, forward: 0, timer: 2, past1: 1),
            input(variant: SM64_MODERN_MARIO_HELD_WALK_HEAVY, intended: 30, forward: 0, timer: 0, past1: 1),
            input(variant: SM64_MODERN_MARIO_HELD_WALK_HEAVY, intended: 4, forward: 0, quicksand: 60, timer: 2, past2: 1),
            input(variant: SM64_MODERN_MARIO_HELD_WALK_LIGHT, intended: 2, forward: 12, timer: 2)
        ]
        for (caseIndex, var value) in cases.enumerated() {
            var swiftOutput = SM64ModernMarioHeldWalkAnimationOutputV1()
            var cOutput = SM64ModernMarioHeldWalkAnimationOutputV1()
            let swiftStatus = sm64_modern_gameplay_update_mario_held_walk_animation(&value, &swiftOutput)
            let cStatus = sm64_modern_gameplay_reference_mario_held_walk_animation(&value, &cOutput)
            precondition(swiftStatus == SM64_MODERN_STATUS_OK && cStatus == SM64_MODERN_STATUS_OK,
                         "held-walk-animation status case=\(caseIndex)")
            precondition(equal(swiftOutput, cOutput), "held-walk-animation ABI output case=\(caseIndex)")
        }
        let evidence = service.evidence()
        precondition(evidence.marioHeldWalkAnimationUpdates == UInt64(cases.count))
        sm64_modern_uninstall_mario_held_walk_animation_api()
        print("SM64 Modern Mario held-walk-animation C-to-Swift ABI smoke passed updates=\(evidence.marioHeldWalkAnimationUpdates)")
    }
}
