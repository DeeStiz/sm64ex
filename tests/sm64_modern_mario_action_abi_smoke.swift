import Foundation

private func seeded(_ action: UInt32) -> SM64ModernMarioActionInputV1 {
    SM64ModernMarioActionInputV1(
        header: SM64ModernAbiHeader(
            abi_version: SM64_MODERN_ABI_VERSION_1,
            struct_size: UInt32(MemoryLayout<SM64ModernMarioActionInputV1>.size)
        ),
        simulation_tick: 1,
        requested_action: action,
        action_argument: 0,
        current_action: 0x0C400201,
        flags: 0x00070000,
        floor_class: 0,
        facing_downhill: 0,
        held_object_present: 0,
        ridden_object_present: 0,
        squish_timer: 0,
        quicksand_depth_bits: Float(0).bitPattern,
        intended_magnitude_bits: Float(6).bitPattern,
        forward_velocity_bits: Float(2).bitPattern,
        intended_yaw: 0x3000,
        face_pitch: 0x111,
        face_yaw: 0x2000,
        face_roll: -0x222,
        velocity_x_bits: Float(3).bitPattern,
        velocity_y_bits: Float(4).bitPattern,
        velocity_z_bits: Float(5).bitPattern,
        position_y_bits: Float(37).bitPattern,
        peak_height_bits: Float(11).bitPattern,
        wall_kick_timer: 0,
        hurt_counter: 0,
        reserved: 0
    )
}

private func equal(
    _ lhs: SM64ModernMarioActionOutputV1,
    _ rhs: SM64ModernMarioActionOutputV1
) -> Bool {
    lhs.action == rhs.action
        && lhs.previous_action == rhs.previous_action
        && lhs.action_argument == rhs.action_argument
        && lhs.action_state == rhs.action_state
        && lhs.action_timer == rhs.action_timer
        && lhs.flags == rhs.flags
        && lhs.forward_velocity_bits == rhs.forward_velocity_bits
        && lhs.face_pitch == rhs.face_pitch
        && lhs.face_yaw == rhs.face_yaw
        && lhs.face_roll == rhs.face_roll
        && lhs.velocity_x_bits == rhs.velocity_x_bits
        && lhs.velocity_y_bits == rhs.velocity_y_bits
        && lhs.velocity_z_bits == rhs.velocity_z_bits
        && lhs.wall_kick_timer == rhs.wall_kick_timer
        && lhs.peak_height_bits == rhs.peak_height_bits
        && lhs.dropped_held_object == rhs.dropped_held_object
        && lhs.dropped_ridden_object == rhs.dropped_ridden_object
        && lhs.hurt_counter == rhs.hurt_counter
        && lhs.reserved == rhs.reserved
}

@main
enum SM64ModernMarioActionABISmoke {
    static func main() {
        let service = SwiftGameplayService()
        service.resetEvidence()
        var api = makeSwiftMarioActionAPI(service: service)
        precondition(sm64_modern_install_mario_action_api(&api) == SM64_MODERN_STATUS_OK)

        let actions: [UInt32] = [
            SM64MarioActionID.walking,
            SM64MarioActionID.beginSliding,
            SM64MarioActionID.doubleJump,
            SM64MarioActionID.backflip,
            SM64MarioActionID.longJump,
            SM64MarioActionID.sideFlip,
            SM64MarioActionID.metalWaterJump,
            SM64MarioActionID.jumpKick
        ]
        for action in actions {
            var input = seeded(action)
            if action == SM64MarioActionID.doubleJump {
                input.forward_velocity_bits = Float(20).bitPattern
            }
            var swiftOutput = SM64ModernMarioActionOutputV1()
            var cOutput = SM64ModernMarioActionOutputV1()
            precondition(
                sm64_modern_gameplay_update_mario_action(&input, &swiftOutput)
                    == SM64_MODERN_STATUS_OK
            )
            precondition(
                sm64_modern_gameplay_reference_mario_action(&input, &cOutput)
                    == SM64_MODERN_STATUS_OK
            )
            precondition(equal(swiftOutput, cOutput), "action ABI output diverged")
        }

        let evidence = service.evidence()
        precondition(evidence.marioActionUpdates == UInt64(actions.count))
        sm64_modern_uninstall_mario_action_api()
        print("SM64 Modern Mario action C-to-Swift ABI smoke passed updates=\(evidence.marioActionUpdates)")
    }
}
