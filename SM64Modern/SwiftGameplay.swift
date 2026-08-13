import Foundation
import OSLog

private let swiftGameplayLogger = Logger(
    subsystem: "io.github.deestiz.sm64modern",
    category: "SwiftGameplay"
)

private func swiftGameplayService(
    from context: UnsafeMutableRawPointer?
) -> SwiftGameplayService? {
    guard let context else { return nil }
    return Unmanaged<SwiftGameplayService>.fromOpaque(context).takeUnretainedValue()
}

private let swiftMarioButtonUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioButtonInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioButtonOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioButtons(input: input.pointee, output: output)
}

private let swiftMarioGroundSpeedUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioGroundSpeedInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioGroundSpeedOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioGroundSpeed(input: input.pointee, output: output)
}

private let swiftBobombReleaseUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernBobombReleaseInputV1>?,
    UnsafeMutablePointer<SM64ModernBobombReleaseOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateBobombRelease(input: input.pointee, output: output)
}

private let swiftGameplayCandidateTransform: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernGameplayTraceRecordV1>?,
    UnsafeMutablePointer<SM64ModernGameplayTraceRecordV1>?
) -> SM64ModernStatus = { context, actual, candidate in
    guard let service = swiftGameplayService(from: context), let actual, let candidate else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.transformCandidate(actual: actual.pointee, output: candidate)
}

struct SwiftGameplayEvidence {
    let marioButtonUpdates: UInt64
    let marioGroundSpeedUpdates: UInt64
    let bobombReleaseUpdates: UInt64

    func exercised(subsystem: SM64ModernGameplaySubsystem) -> Bool {
        switch subsystem {
        case SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO:
            marioButtonUpdates > 0 || marioGroundSpeedUpdates > 0
        case SM64_MODERN_GAMEPLAY_SUBSYSTEM_ACTOR_BOBOMB_BATTLEFIELD:
            bobombReleaseUpdates > 0
        default:
            false
        }
    }
}

final class SwiftGameplayService: @unchecked Sendable {
    private struct MarioCandidate {
        let tick: UInt64
        let ownedInputMask: UInt32
        let output: SM64ModernMarioButtonOutputV1
    }

    private struct MarioGroundSpeedCandidate {
        let tick: UInt64
        let output: SM64ModernMarioGroundSpeedOutputV1
    }

    private struct BobombCandidate {
        let tick: UInt64
        let output: SM64ModernBobombReleaseOutputV1
    }

    private var candidateTick: UInt64 = 0
    private var marioCandidate: MarioCandidate?
    private var marioGroundSpeedCandidate: MarioGroundSpeedCandidate?
    private var bobombCandidates: [UInt32: BobombCandidate] = [:]
    private var marioButtonUpdates: UInt64 = 0
    private var marioGroundSpeedUpdates: UInt64 = 0
    private var bobombReleaseUpdates: UInt64 = 0

    func resetEvidence() {
        precondition(!Thread.isMainThread, "Gameplay migration is engine-owner-thread state")
        candidateTick = 0
        marioCandidate = nil
        marioGroundSpeedCandidate = nil
        bobombCandidates.removeAll(keepingCapacity: true)
        marioButtonUpdates = 0
        marioGroundSpeedUpdates = 0
        bobombReleaseUpdates = 0
    }

    func evidence() -> SwiftGameplayEvidence {
        SwiftGameplayEvidence(
            marioButtonUpdates: marioButtonUpdates,
            marioGroundSpeedUpdates: marioGroundSpeedUpdates,
            bobombReleaseUpdates: bobombReleaseUpdates
        )
    }

    fileprivate func updateMarioButtons(
        input: SM64ModernMarioButtonInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioButtonOutputV1>
    ) -> SM64ModernStatus {
        precondition(!Thread.isMainThread, "Swift gameplay callbacks require the engine owner thread")
        advanceCandidateTick(to: input.simulation_tick)

        var result = SM64ModernMarioButtonOutputV1()
        result.header.abi_version = SM64_MODERN_ABI_VERSION_1
        result.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioButtonOutputV1>.size)
        result.input = input.input
        result.frames_since_a = input.frames_since_a
        result.frames_since_b = input.frames_since_b

        if input.button_pressed & UInt32(SM64_MODERN_N64_BUTTON_A) != 0 {
            result.input |= UInt32(SM64_MODERN_MARIO_INPUT_A_PRESSED)
        }
        if input.button_down & UInt32(SM64_MODERN_N64_BUTTON_A) != 0 {
            result.input |= UInt32(SM64_MODERN_MARIO_INPUT_A_DOWN)
        }
        if input.squish_timer == 0 {
            if input.button_pressed & UInt32(SM64_MODERN_N64_BUTTON_B) != 0 {
                result.input |= UInt32(SM64_MODERN_MARIO_INPUT_B_PRESSED)
            }
            if input.button_down & UInt32(SM64_MODERN_N64_BUTTON_Z) != 0 {
                result.input |= UInt32(SM64_MODERN_MARIO_INPUT_Z_DOWN)
            }
            if input.button_pressed & UInt32(SM64_MODERN_N64_BUTTON_Z) != 0 {
                result.input |= UInt32(SM64_MODERN_MARIO_INPUT_Z_PRESSED)
            }
        }

        if result.input & UInt32(SM64_MODERN_MARIO_INPUT_A_PRESSED) != 0 {
            result.frames_since_a = 0
        } else if result.frames_since_a < UInt8.max {
            result.frames_since_a += 1
        }
        if result.input & UInt32(SM64_MODERN_MARIO_INPUT_B_PRESSED) != 0 {
            result.frames_since_b = 0
        } else if result.frames_since_b < UInt8.max {
            result.frames_since_b += 1
        }

        output.pointee = result
        marioCandidate = MarioCandidate(
            tick: input.simulation_tick,
            ownedInputMask: input.owned_input_mask,
            output: result
        )
        marioButtonUpdates += 1
        if marioButtonUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_buttons")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioGroundSpeed(
        input: SM64ModernMarioGroundSpeedInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioGroundSpeedOutputV1>
    ) -> SM64ModernStatus {
        precondition(!Thread.isMainThread, "Swift gameplay callbacks require the engine owner thread")
        advanceCandidateTick(to: input.simulation_tick)

        let intendedMagnitude = Float(bitPattern: input.intended_magnitude_bits)
        let quicksandDepth = Float(bitPattern: input.quicksand_depth_bits)
        let floorNormalY = Float(bitPattern: input.floor_normal_y_bits)
        var forwardVelocity = Float(bitPattern: input.forward_velocity_bits)
        guard intendedMagnitude.isFinite, quicksandDepth.isFinite,
              floorNormalY.isFinite, forwardVelocity.isFinite,
              input.floor_is_slow <= 1, input.responsive_cheat <= 1,
              input.cheats_enabled <= 1 else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }

        let maxTargetSpeed: Float = input.floor_is_slow != 0 ? 24 : 32
        var targetSpeed = intendedMagnitude < maxTargetSpeed ? intendedMagnitude : maxTargetSpeed
        if quicksandDepth > 10 {
            targetSpeed = Float(Double(targetSpeed) * (6.25 / Double(quicksandDepth)))
        }
        if forwardVelocity <= 0 {
            forwardVelocity += 1.1
        } else if forwardVelocity <= targetSpeed {
            forwardVelocity += 1.1 - forwardVelocity / 43
        } else if floorNormalY >= 0.95 {
            forwardVelocity -= 1
        }
        if forwardVelocity > 48 { forwardVelocity = 48 }

        let intendedYaw = Int32(Int16(truncatingIfNeeded: input.intended_yaw))
        let faceYaw = Int32(Int16(truncatingIfNeeded: input.face_yaw))
        let nextFaceYaw: Int32
        if input.responsive_cheat != 0 && input.cheats_enabled != 0 {
            nextFaceYaw = intendedYaw
        } else {
            let delta = Int32(Int16(truncatingIfNeeded: intendedYaw - faceYaw))
            nextFaceYaw = intendedYaw - approachS32(delta, target: 0, increment: 0x800, decrement: 0x800)
        }

        var result = SM64ModernMarioGroundSpeedOutputV1()
        result.header.abi_version = SM64_MODERN_ABI_VERSION_1
        result.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioGroundSpeedOutputV1>.size)
        result.forward_velocity_bits = forwardVelocity.bitPattern
        result.face_yaw = Int32(Int16(truncatingIfNeeded: nextFaceYaw))
        output.pointee = result
        marioGroundSpeedCandidate = MarioGroundSpeedCandidate(
            tick: input.simulation_tick,
            output: result
        )
        marioGroundSpeedUpdates += 1
        if marioGroundSpeedUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_ground_speed")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateBobombRelease(
        input: SM64ModernBobombReleaseInputV1,
        output: UnsafeMutablePointer<SM64ModernBobombReleaseOutputV1>
    ) -> SM64ModernStatus {
        precondition(!Thread.isMainThread, "Swift gameplay callbacks require the engine owner thread")
        guard input.subsystem == SM64_MODERN_GAMEPLAY_SUBSYSTEM_ACTOR_BOBOMB_BATTLEFIELD,
              input.held_state == UInt32(SM64_MODERN_BOBOMB_HELD_THROWN)
                || input.held_state == UInt32(SM64_MODERN_BOBOMB_HELD_DROPPED) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        advanceCandidateTick(to: input.simulation_tick)

        var result = SM64ModernBobombReleaseOutputV1()
        result.header.abi_version = SM64_MODERN_ABI_VERSION_1
        result.header.struct_size = UInt32(MemoryLayout<SM64ModernBobombReleaseOutputV1>.size)
        result.held_state = UInt32(SM64_MODERN_BOBOMB_HELD_FREE)
        result.object_flags = input.object_flags
        result.graph_flags = input.graph_flags & ~UInt32(SM64_MODERN_GRAPH_RENDER_INVISIBLE)
        if input.held_state == UInt32(SM64_MODERN_BOBOMB_HELD_THROWN) {
            result.action = Int32(SM64_MODERN_BOBOMB_ACTION_LAUNCHED)
            result.object_flags &= ~UInt32(SM64_MODERN_BOBOMB_OBJECT_THROW_MATRIX_FLAG)
            result.forward_velocity_bits = Float(25).bitPattern
            result.velocity_y_bits = Float(20).bitPattern
        } else {
            result.action = Int32(SM64_MODERN_BOBOMB_ACTION_PATROL)
            result.forward_velocity_bits = Float(0).bitPattern
            result.velocity_y_bits = Float(0).bitPattern
        }

        output.pointee = result
        bobombCandidates[input.subject_id] = BobombCandidate(
            tick: input.simulation_tick,
            output: result
        )
        bobombReleaseUpdates += 1
        if bobombReleaseUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=bobomb_release")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func transformCandidate(
        actual: SM64ModernGameplayTraceRecordV1,
        output: UnsafeMutablePointer<SM64ModernGameplayTraceRecordV1>
    ) -> SM64ModernStatus {
        precondition(!Thread.isMainThread, "Candidate transforms require the engine owner thread")
        var candidate = actual
        let tick = actual.envelope.simulation_tick

        if actual.envelope.subsystem == SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO {
            if let marioCandidate, marioCandidate.tick == tick {
                switch actual.record_id {
                case UInt32(SM64_MODERN_FIELD_MARIO_INPUT):
                    let actualInput = UInt32(truncatingIfNeeded: actual.values.0)
                    candidate.values.0 = UInt64(
                        (actualInput & ~marioCandidate.ownedInputMask)
                            | (marioCandidate.output.input & marioCandidate.ownedInputMask)
                    )
                case UInt32(SM64_MODERN_FIELD_MARIO_FRAMES_SINCE_A):
                    candidate.values.0 = UInt64(marioCandidate.output.frames_since_a)
                case UInt32(SM64_MODERN_FIELD_MARIO_FRAMES_SINCE_B):
                    candidate.values.0 = UInt64(marioCandidate.output.frames_since_b)
                default:
                    break
                }
            }
            if let marioGroundSpeedCandidate, marioGroundSpeedCandidate.tick == tick {
                switch actual.record_id {
                case UInt32(SM64_MODERN_FIELD_MARIO_FORWARD_VELOCITY):
                    candidate.values.0 = UInt64(marioGroundSpeedCandidate.output.forward_velocity_bits)
                case UInt32(SM64_MODERN_FIELD_MARIO_FACE_ANGLE):
                    // The C snapshot stores each angle component as a
                    // zero-extended N64 s16. Preserve that POD encoding when
                    // replacing the candidate value; sign-extending the
                    // Swift Int32 would diverge for headings above 0x7FFF.
                    let faceYaw = Int16(truncatingIfNeeded: marioGroundSpeedCandidate.output.face_yaw)
                    // Face angle is the three-component POD snapshot
                    // (pitch, yaw, roll); the ground-speed kernel owns yaw.
                    candidate.values.1 = UInt64(UInt16(bitPattern: faceYaw))
                default:
                    break
                }
            }
        } else if actual.envelope.subsystem
                    == SM64_MODERN_GAMEPLAY_SUBSYSTEM_ACTOR_BOBOMB_BATTLEFIELD,
                  let bobombCandidate = bobombCandidates[actual.subject_id],
                  bobombCandidate.tick == tick {
            switch actual.record_id {
            case UInt32(SM64_MODERN_FIELD_ACTOR_ACTION):
                candidate.values.0 = UInt64(UInt32(bitPattern: bobombCandidate.output.action))
            case UInt32(SM64_MODERN_FIELD_ACTOR_HELD_STATE):
                candidate.values.0 = UInt64(bobombCandidate.output.held_state)
            case UInt32(SM64_MODERN_FIELD_ACTOR_FLAGS):
                candidate.values.0 = UInt64(bobombCandidate.output.object_flags)
            case UInt32(SM64_MODERN_FIELD_ACTOR_FORWARD_VELOCITY):
                candidate.values.0 = UInt64(bobombCandidate.output.forward_velocity_bits)
            case UInt32(SM64_MODERN_FIELD_ACTOR_GRAPH_FLAGS):
                candidate.values.0 = UInt64(bobombCandidate.output.graph_flags)
            case UInt32(SM64_MODERN_FIELD_ACTOR_VELOCITY):
                candidate.values.1 = UInt64(bobombCandidate.output.velocity_y_bits)
            default:
                break
            }
        }

        // The core recomputes the canonical hash after validating record identity.
        candidate.canonical_hash = 0
        output.pointee = candidate
        return SM64_MODERN_STATUS_OK
    }

    private func advanceCandidateTick(to tick: UInt64) {
        guard tick != candidateTick else { return }
        candidateTick = tick
        marioCandidate = nil
        marioGroundSpeedCandidate = nil
        bobombCandidates.removeAll(keepingCapacity: true)
    }

    private func approachS32(
        _ current: Int32,
        target: Int32,
        increment: Int32,
        decrement: Int32
    ) -> Int32 {
        if current < target {
            let next = current + increment
            return next > target ? target : next
        }
        let next = current - decrement
        return next < target ? target : next
    }
}

func makeSwiftMarioGroundSpeedAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioGroundSpeedApiV1 {
    var api = SM64ModernMarioGroundSpeedApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioGroundSpeedApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioGroundSpeedUpdate
    return api
}

func makeSwiftGameplayMigrationAPI(
    service: SwiftGameplayService
) -> SM64ModernGameplayMigrationApiV1 {
    var api = SM64ModernGameplayMigrationApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernGameplayMigrationApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update_mario_buttons = swiftMarioButtonUpdate
    api.update_bobomb_release = swiftBobombReleaseUpdate
    api.transform_candidate = swiftGameplayCandidateTransform
    return api
}
