import Darwin
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

private let swiftMarioActionUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioActionInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioActionOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioAction(input: input.pointee, output: output)
}

private let swiftMarioActionCancelUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioActionCancelInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioActionCancelOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioActionCancel(input: input.pointee, output: output)
}

private let swiftMarioGroundStepUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioGroundStepInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioGroundStepOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioGroundStep(input: input.pointee, output: output)
}

private let swiftMarioAirStepUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioAirStepInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioAirStepOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioAirStep(input: input.pointee, output: output)
}

private let swiftMarioWaterStepUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioWaterStepInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioWaterStepOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioWaterStep(input: input.pointee, output: output)
}

private let swiftMarioBonkUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioBonkInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioBonkOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioBonk(input: input.pointee, output: output)
}

private let swiftMarioTerrainImpulseUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioTerrainImpulseInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioTerrainImpulseOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioTerrainImpulse(input: input.pointee, output: output)
}

private let swiftMarioQuicksandUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioQuicksandInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioQuicksandOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioQuicksand(input: input.pointee, output: output)
}

private let swiftMarioSteepPushUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioSteepPushInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioSteepPushOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioSteepPush(input: input.pointee, output: output)
}

private let swiftMarioTerrainSoundUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioTerrainSoundInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioTerrainSoundOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioTerrainSound(input: input.pointee, output: output)
}

private let swiftMarioFloorPredicatesUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioFloorPredicatesInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioFloorPredicatesOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioFloorPredicates(input: input.pointee, output: output)
}

private let swiftMarioForwardVelocityUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioForwardVelocityInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioForwardVelocityOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioForwardVelocity(input: input.pointee, output: output)
}

private let swiftMarioVelocityDerivationUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioVelocityDerivationInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioVelocityDerivationOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioVelocityDerivation(input: input.pointee, output: output)
}

private let swiftMarioPunchUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioPunchInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioPunchOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioPunch(input: input.pointee, output: output)
}

private let swiftMarioWallResponseUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioWallResponseInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioWallResponseOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioWallResponse(input: input.pointee, output: output)
}

private let swiftMarioWalkAnimationUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioWalkAnimationInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioWalkAnimationOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioWalkAnimation(input: input.pointee, output: output)
}

private let swiftMarioHeldWalkAnimationUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioHeldWalkAnimationInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioHeldWalkAnimationOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioHeldWalkAnimation(input: input.pointee, output: output)
}

private let swiftMarioSlopeAccelerationUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioSlopeAccelerationInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioSlopeAccelerationOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioSlopeAcceleration(input: input.pointee, output: output)
}

private let swiftMarioSlopeDecelerationUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioSlopeDecelerationInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioSlopeDecelerationOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioSlopeDeceleration(input: input.pointee, output: output)
}

private let swiftMarioDeceleratingSpeedUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioDeceleratingSpeedInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioDeceleratingSpeedOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioDeceleratingSpeed(input: input.pointee, output: output)
}

private let swiftMarioShellSpeedUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioShellSpeedInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioShellSpeedOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioShellSpeed(input: input.pointee, output: output)
}

private let swiftMarioLandingAccelerationUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioLandingAccelerationInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioLandingAccelerationOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioLandingAcceleration(input: input.pointee, output: output)
}

private let swiftMarioGravityUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioGravityInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioGravityOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioGravity(input: input.pointee, output: output)
}

private let swiftMarioVerticalWindUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioVerticalWindInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioVerticalWindOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioVerticalWind(input: input.pointee, output: output)
}

private let swiftMarioSlidingUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioSlidingInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioSlidingOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioSliding(input: input.pointee, output: output)
}

private let swiftMarioGroundDivePunchUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioGroundDivePunchInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioGroundDivePunchOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioGroundDivePunch(input: input.pointee, output: output)
}

private let swiftMarioSlidePredicatesUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioSlidePredicatesInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioSlidePredicatesOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioSlidePredicates(input: input.pointee, output: output)
}

private let swiftMarioBeginBrakingUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioBeginBrakingInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioBeginBrakingOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioBeginBraking(input: input.pointee, output: output)
}

private let swiftMarioTripleJumpSelectorUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioTripleJumpSelectorInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioTripleJumpSelectorOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioTripleJumpSelector(input: input.pointee, output: output)
}

private let swiftMarioYVelocityUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioYVelocityInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioYVelocityOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioYVelocity(input: input.pointee, output: output)
}

private let swiftMarioSteepJumpUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernMarioSteepJumpInputV1>?,
    UnsafeMutablePointer<SM64ModernMarioSteepJumpOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = swiftGameplayService(from: context), let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.updateMarioSteepJump(input: input.pointee, output: output)
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
    let marioActionUpdates: UInt64
    let marioActionCancelUpdates: UInt64
    let marioGroundStepUpdates: UInt64
    let marioAirStepUpdates: UInt64
    let marioWaterStepUpdates: UInt64
    let marioBonkUpdates: UInt64
    let marioTerrainImpulseUpdates: UInt64
    let marioQuicksandUpdates: UInt64
    let marioSteepPushUpdates: UInt64
    let marioTerrainSoundUpdates: UInt64
    let marioFloorPredicateUpdates: UInt64
    let marioForwardVelocityUpdates: UInt64
    let marioVelocityDerivationUpdates: UInt64
    let marioPunchUpdates: UInt64
    let marioWallResponseUpdates: UInt64
    let marioWalkAnimationUpdates: UInt64
    let marioHeldWalkAnimationUpdates: UInt64
    let marioSlopeAccelerationUpdates: UInt64
    let marioSlopeDecelerationUpdates: UInt64
    let marioDeceleratingSpeedUpdates: UInt64
    let marioShellSpeedUpdates: UInt64
    let marioLandingAccelerationUpdates: UInt64
    let marioGravityUpdates: UInt64
    let marioVerticalWindUpdates: UInt64
    let marioSlidingUpdates: UInt64
    let marioGroundDivePunchUpdates: UInt64
    let marioSlidePredicatesUpdates: UInt64
    let marioBeginBrakingUpdates: UInt64
    let marioTripleJumpSelectorUpdates: UInt64
    let marioYVelocityUpdates: UInt64
    let marioSteepJumpUpdates: UInt64
    let bobombReleaseUpdates: UInt64
    let cheatPolicyUpdates: UInt64

    func exercised(subsystem: SM64ModernGameplaySubsystem) -> Bool {
        switch subsystem {
        case SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO:
            marioButtonUpdates > 0 || marioGroundSpeedUpdates > 0 || marioActionUpdates > 0
                || marioActionCancelUpdates > 0
                || marioGroundStepUpdates > 0
                || marioAirStepUpdates > 0
                || marioWaterStepUpdates > 0
                || marioBonkUpdates > 0
                || marioTerrainImpulseUpdates > 0
                || marioQuicksandUpdates > 0
                || marioSteepPushUpdates > 0
                || marioTerrainSoundUpdates > 0
                || marioFloorPredicateUpdates > 0
                || marioForwardVelocityUpdates > 0
                || marioVelocityDerivationUpdates > 0
                || marioPunchUpdates > 0
                || marioWallResponseUpdates > 0
                || marioWalkAnimationUpdates > 0
                || marioHeldWalkAnimationUpdates > 0
                || marioSlopeAccelerationUpdates > 0
                || marioSlopeDecelerationUpdates > 0
                || marioDeceleratingSpeedUpdates > 0
                || marioShellSpeedUpdates > 0
                || marioLandingAccelerationUpdates > 0
                || marioGravityUpdates > 0
                || marioVerticalWindUpdates > 0
                || marioSlidingUpdates > 0
                || marioGroundDivePunchUpdates > 0
                || marioSlidePredicatesUpdates > 0
                || marioBeginBrakingUpdates > 0
                || marioTripleJumpSelectorUpdates > 0
                || marioYVelocityUpdates > 0
                || marioSteepJumpUpdates > 0
        case SM64_MODERN_GAMEPLAY_SUBSYSTEM_ACTOR_BOBOMB_BATTLEFIELD:
            bobombReleaseUpdates > 0
        default:
            false
        }
    }
}

/// Owner-thread gameplay migration state. The C callbacks are the only unsafe
/// leaf; mutable candidate snapshots never cross into a Swift concurrency
/// domain and the first owner-thread reset binds the service to its engine
/// thread.
final class SwiftGameplayService {
    private struct MarioCandidate {
        let tick: UInt64
        let ownedInputMask: UInt32
        let output: SM64ModernMarioButtonOutputV1
    }

    private struct MarioGroundSpeedCandidate {
        let tick: UInt64
        let output: SM64ModernMarioGroundSpeedOutputV1
    }

    private struct MarioActionCandidate {
        let tick: UInt64
        let output: SM64ModernMarioActionOutputV1
    }

    private struct MarioGroundStepCandidate {
        let tick: UInt64
        let output: SM64ModernMarioGroundStepOutputV1
    }

    private struct MarioAirStepCandidate {
        let tick: UInt64
        let output: SM64ModernMarioAirStepOutputV1
    }

    private struct MarioWaterStepCandidate {
        let tick: UInt64
        let output: SM64ModernMarioWaterStepOutputV1
    }

    private struct MarioBonkCandidate {
        let tick: UInt64
        let output: SM64ModernMarioBonkOutputV1
    }

    private struct MarioTerrainImpulseCandidate {
        let tick: UInt64
        let output: SM64ModernMarioTerrainImpulseOutputV1
    }

    private struct BobombCandidate {
        let tick: UInt64
        let output: SM64ModernBobombReleaseOutputV1
    }

    private var candidateTick: UInt64 = 0
    private var marioCandidate: MarioCandidate?
    private var marioGroundSpeedCandidate: MarioGroundSpeedCandidate?
    private var marioActionCandidate: MarioActionCandidate?
    private var marioGroundStepCandidate: MarioGroundStepCandidate?
    private var marioAirStepCandidate: MarioAirStepCandidate?
    private var marioWaterStepCandidate: MarioWaterStepCandidate?
    private var marioBonkCandidate: MarioBonkCandidate?
    private var marioTerrainImpulseCandidate: MarioTerrainImpulseCandidate?
    private var bobombCandidates: [UInt32: BobombCandidate] = [:]
    private var marioButtonUpdates: UInt64 = 0
    private var marioGroundSpeedUpdates: UInt64 = 0
    private var marioActionUpdates: UInt64 = 0
    private var marioActionCancelUpdates: UInt64 = 0
    private var marioGroundStepUpdates: UInt64 = 0
    private var marioAirStepUpdates: UInt64 = 0
    private var marioWaterStepUpdates: UInt64 = 0
    private var marioBonkUpdates: UInt64 = 0
    private var marioTerrainImpulseUpdates: UInt64 = 0
    private var marioQuicksandUpdates: UInt64 = 0
    private var marioSteepPushUpdates: UInt64 = 0
    private var marioTerrainSoundUpdates: UInt64 = 0
    private var marioFloorPredicateUpdates: UInt64 = 0
    private var marioForwardVelocityUpdates: UInt64 = 0
    private var marioVelocityDerivationUpdates: UInt64 = 0
    private var marioPunchUpdates: UInt64 = 0
    private var marioWallResponseUpdates: UInt64 = 0
    private var marioWalkAnimationUpdates: UInt64 = 0
    private var marioHeldWalkAnimationUpdates: UInt64 = 0
    private var marioSlopeAccelerationUpdates: UInt64 = 0
    private var marioSlopeDecelerationUpdates: UInt64 = 0
    private var marioDeceleratingSpeedUpdates: UInt64 = 0
    private var marioShellSpeedUpdates: UInt64 = 0
    private var marioLandingAccelerationUpdates: UInt64 = 0
    private var marioGravityUpdates: UInt64 = 0
    private var marioVerticalWindUpdates: UInt64 = 0
    private var marioSlidingUpdates: UInt64 = 0
    private var marioGroundDivePunchUpdates: UInt64 = 0
    private var marioSlidePredicatesUpdates: UInt64 = 0
    private var marioBeginBrakingUpdates: UInt64 = 0
    private var marioTripleJumpSelectorUpdates: UInt64 = 0
    private var marioYVelocityUpdates: UInt64 = 0
    private var marioSteepJumpUpdates: UInt64 = 0
    private var bobombReleaseUpdates: UInt64 = 0
    private var cheatPolicyUpdates: UInt64 = 0
    private var ownerThreadIdentity: UInt64?

    func resetEvidence() {
        assertOwnerThread(bindIfMissing: true)
        candidateTick = 0
        marioCandidate = nil
        marioGroundSpeedCandidate = nil
        marioActionCandidate = nil
        marioGroundStepCandidate = nil
        marioAirStepCandidate = nil
        marioWaterStepCandidate = nil
        marioBonkCandidate = nil
        marioTerrainImpulseCandidate = nil
        bobombCandidates.removeAll(keepingCapacity: true)
        marioButtonUpdates = 0
        marioGroundSpeedUpdates = 0
        marioActionUpdates = 0
        marioActionCancelUpdates = 0
        marioGroundStepUpdates = 0
        marioAirStepUpdates = 0
        marioWaterStepUpdates = 0
        marioBonkUpdates = 0
        marioTerrainImpulseUpdates = 0
        marioQuicksandUpdates = 0
        marioSteepPushUpdates = 0
        marioTerrainSoundUpdates = 0
        marioFloorPredicateUpdates = 0
        marioForwardVelocityUpdates = 0
        marioVelocityDerivationUpdates = 0
        marioPunchUpdates = 0
        marioWallResponseUpdates = 0
        marioWalkAnimationUpdates = 0
        marioHeldWalkAnimationUpdates = 0
        marioSlopeAccelerationUpdates = 0
        marioSlopeDecelerationUpdates = 0
        marioDeceleratingSpeedUpdates = 0
        marioShellSpeedUpdates = 0
        marioLandingAccelerationUpdates = 0
        marioGravityUpdates = 0
        marioVerticalWindUpdates = 0
        marioSlidingUpdates = 0
        marioGroundDivePunchUpdates = 0
        marioSlidePredicatesUpdates = 0
        marioBeginBrakingUpdates = 0
        marioTripleJumpSelectorUpdates = 0
        marioYVelocityUpdates = 0
        marioSteepJumpUpdates = 0
        bobombReleaseUpdates = 0
        cheatPolicyUpdates = 0
    }

    func evidence() -> SwiftGameplayEvidence {
        assertOwnerThread()
        return SwiftGameplayEvidence(
            marioButtonUpdates: marioButtonUpdates,
            marioGroundSpeedUpdates: marioGroundSpeedUpdates,
            marioActionUpdates: marioActionUpdates,
            marioActionCancelUpdates: marioActionCancelUpdates,
            marioGroundStepUpdates: marioGroundStepUpdates,
            marioAirStepUpdates: marioAirStepUpdates,
            marioWaterStepUpdates: marioWaterStepUpdates,
            marioBonkUpdates: marioBonkUpdates,
            marioTerrainImpulseUpdates: marioTerrainImpulseUpdates,
            marioQuicksandUpdates: marioQuicksandUpdates,
            marioSteepPushUpdates: marioSteepPushUpdates,
            marioTerrainSoundUpdates: marioTerrainSoundUpdates,
            marioFloorPredicateUpdates: marioFloorPredicateUpdates,
            marioForwardVelocityUpdates: marioForwardVelocityUpdates,
            marioVelocityDerivationUpdates: marioVelocityDerivationUpdates,
            marioPunchUpdates: marioPunchUpdates,
            marioWallResponseUpdates: marioWallResponseUpdates,
            marioWalkAnimationUpdates: marioWalkAnimationUpdates,
            marioHeldWalkAnimationUpdates: marioHeldWalkAnimationUpdates,
            marioSlopeAccelerationUpdates: marioSlopeAccelerationUpdates,
            marioSlopeDecelerationUpdates: marioSlopeDecelerationUpdates,
            marioDeceleratingSpeedUpdates: marioDeceleratingSpeedUpdates,
            marioShellSpeedUpdates: marioShellSpeedUpdates,
            marioLandingAccelerationUpdates: marioLandingAccelerationUpdates,
            marioGravityUpdates: marioGravityUpdates,
            marioVerticalWindUpdates: marioVerticalWindUpdates,
            marioSlidingUpdates: marioSlidingUpdates,
            marioGroundDivePunchUpdates: marioGroundDivePunchUpdates,
            marioSlidePredicatesUpdates: marioSlidePredicatesUpdates,
            marioBeginBrakingUpdates: marioBeginBrakingUpdates,
            marioTripleJumpSelectorUpdates: marioTripleJumpSelectorUpdates,
            marioYVelocityUpdates: marioYVelocityUpdates,
            marioSteepJumpUpdates: marioSteepJumpUpdates,
            bobombReleaseUpdates: bobombReleaseUpdates,
            cheatPolicyUpdates: cheatPolicyUpdates
        )
    }

    fileprivate func updateMarioButtons(
        input: SM64ModernMarioButtonInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioButtonOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
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
        assertOwnerThread()
        advanceCandidateTick(to: input.simulation_tick)

        guard input.floor_is_slow <= 1, input.responsive_cheat <= 1,
              input.cheats_enabled <= 1 else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        let cheatState = SM64CheatState(
            legacyEnabled: input.cheats_enabled != 0,
            responsive: input.responsive_cheat != 0
        )
        let responsiveMovement = SM64CheatPolicy.responsiveMovementEnabled(
            for: cheatState
        )
        cheatPolicyUpdates += 1
        if cheatPolicyUpdates == 1 {
            swiftGameplayLogger.notice(
                "swift_cheat_policy_exercised policy=responsive_movement enabled=\(cheatState.enabled, privacy: .public) responsive=\(cheatState.responsive, privacy: .public)"
            )
        }
        guard let speed = SM64MarioGroundSpeed.update(
            SM64MarioGroundSpeedInput(
                intendedMagnitude: Float(bitPattern: input.intended_magnitude_bits),
                forwardVelocity: Float(bitPattern: input.forward_velocity_bits),
                quicksandDepth: Float(bitPattern: input.quicksand_depth_bits),
                floorNormalY: Float(bitPattern: input.floor_normal_y_bits),
                intendedYaw: input.intended_yaw,
                faceYaw: input.face_yaw,
                floorIsSlow: input.floor_is_slow != 0,
                responsiveCheat: responsiveMovement,
                cheatsEnabled: cheatState.enabled
            )
        ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }

        var result = SM64ModernMarioGroundSpeedOutputV1()
        result.header.abi_version = SM64_MODERN_ABI_VERSION_1
        result.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioGroundSpeedOutputV1>.size)
        result.forward_velocity_bits = speed.forwardVelocity.bitPattern
        result.face_yaw = Int32(speed.faceYaw)
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

    fileprivate func updateMarioAction(
        input: SM64ModernMarioActionInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioActionOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        advanceCandidateTick(to: input.simulation_tick)
        guard input.facing_downhill <= 1,
              input.held_object_present <= 1,
              input.ridden_object_present <= 1,
              Self.supportedMarioAction(input.requested_action) else {
            return SM64_MODERN_STATUS_UNSUPPORTED_AUTHORITY
        }

        var state = SM64MarioState()
        state.action = input.current_action
        state.flags = input.flags
        state.actionArgument = input.action_argument
        state.intendedMagnitude = Float(bitPattern: input.intended_magnitude_bits)
        state.forwardVelocity = Float(bitPattern: input.forward_velocity_bits)
        state.intendedYaw = Int16(truncatingIfNeeded: input.intended_yaw)
        state.faceAngle = SM64ObjectAngles(
            pitch: input.face_pitch,
            yaw: input.face_yaw,
            roll: input.face_roll
        )
        state.velocity = SM64ObjectVector3(
            x: Float(bitPattern: input.velocity_x_bits),
            y: Float(bitPattern: input.velocity_y_bits),
            z: Float(bitPattern: input.velocity_z_bits)
        )
        state.position.y = Float(bitPattern: input.position_y_bits)
        state.peakHeight = Float(bitPattern: input.peak_height_bits)
        state.squishTimer = UInt8(truncatingIfNeeded: input.squish_timer)
        state.quicksandDepth = Float(bitPattern: input.quicksand_depth_bits)
        state.wallKickTimer = UInt8(truncatingIfNeeded: input.wall_kick_timer)
        state.hurtCounter = UInt8(truncatingIfNeeded: input.hurt_counter)
        if input.held_object_present != 0 {
            state.heldObjectID = SM64ObjectID(slot: 0, generation: 1)
        }
        if input.ridden_object_present != 0 {
            state.riddenObjectID = SM64ObjectID(slot: 1, generation: 1)
        }

        let mutation = state.setAction(
            input.requested_action,
            argument: input.action_argument,
            floorClass: Int16(truncatingIfNeeded: input.floor_class),
            facingDownhill: input.facing_downhill != 0
        )
        var result = SM64ModernMarioActionOutputV1()
        result.header.abi_version = SM64_MODERN_ABI_VERSION_1
        result.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioActionOutputV1>.size)
        result.action = mutation.action
        result.previous_action = mutation.previousAction
        result.action_argument = mutation.actionArgument
        result.action_state = UInt32(mutation.actionState)
        result.action_timer = UInt32(mutation.actionTimer)
        result.flags = mutation.flags
        result.forward_velocity_bits = mutation.forwardVelocity.bitPattern
        result.face_pitch = mutation.faceAngle.pitch
        result.face_yaw = mutation.faceAngle.yaw
        result.face_roll = mutation.faceAngle.roll
        result.velocity_x_bits = mutation.velocity.x.bitPattern
        result.velocity_y_bits = mutation.velocity.y.bitPattern
        result.velocity_z_bits = mutation.velocity.z.bitPattern
        result.wall_kick_timer = UInt32(mutation.wallKickTimer)
        result.peak_height_bits = mutation.peakHeight.bitPattern
        result.dropped_held_object = mutation.droppedHeldObject ? 1 : 0
        result.dropped_ridden_object = mutation.droppedRiddenObject ? 1 : 0
        result.hurt_counter = UInt32(mutation.hurtCounter)
        output.pointee = result
        marioActionCandidate = MarioActionCandidate(
            tick: input.simulation_tick,
            output: result
        )
        marioActionUpdates += 1
        if marioActionUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_action")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioActionCancel(
        input: SM64ModernMarioActionCancelInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioActionCancelOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard input.family == SM64_MODERN_MARIO_ACTION_CANCEL_IDLE,
              input.terrain_is_snow <= 1,
              input.held_object_present <= 1 else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        let quicksandDepth = Float(bitPattern: input.quicksand_depth_bits)
        let floorNormalY = Float(bitPattern: input.floor_normal_y_bits)
        guard quicksandDepth.isFinite, floorNormalY.isFinite else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }

        var state = SM64MarioState()
        state.action = input.current_action
        state.actionArgument = input.action_argument
        state.actionState = UInt16(truncatingIfNeeded: input.action_state)
        state.input = SM64MarioInputFlags(rawValue: UInt16(truncatingIfNeeded: input.input))
        state.health = Int16(truncatingIfNeeded: input.health)
        state.quicksandDepth = quicksandDepth
        state.intendedYaw = Int16(truncatingIfNeeded: input.intended_yaw)
        let decision = SM64MarioActionCancels.idle(
            state: state,
            context: SM64MarioActionCancelContext(
                floorNormalY: floorNormalY,
                terrainIsSnow: input.terrain_is_snow != 0,
                heldObjectPresent: input.held_object_present != 0
            )
        )
        var result = SM64ModernMarioActionCancelOutputV1()
        result.header.abi_version = SM64_MODERN_ABI_VERSION_1
        result.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioActionCancelOutputV1>.size)
        result.action = decision.action ?? 0
        result.action_argument = decision.argument
        if let faceYaw = decision.faceYaw {
            result.face_yaw = Int32(faceYaw)
            result.face_yaw_valid = 1
        }
        result.should_drop_held_object = decision.shouldDropHeldObject ? 1 : 0
        output.pointee = result
        marioActionCancelUpdates += 1
        if marioActionCancelUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_action_cancel")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioGroundStep(
        input: SM64ModernMarioGroundStepInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioGroundStepOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard input.riding_shell <= 1 else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }

        func floor(_ value: SM64ModernMarioGroundFloorProbeV1) -> SM64MarioGroundFloorProbe? {
            guard value.present <= 1 else { return nil }
            guard value.present != 0 else { return nil }
            return SM64MarioGroundFloorProbe(
                surfaceID: value.surface_id,
                height: Float(bitPattern: value.height_bits),
                normalY: Float(bitPattern: value.normal_y_bits)
            )
        }
        func wall(_ value: SM64ModernMarioGroundWallProbeV1) -> SM64MarioGroundWallProbe? {
            guard value.present <= 1 else { return nil }
            guard value.present != 0 else { return nil }
            return SM64MarioGroundWallProbe(
                surfaceID: value.surface_id,
                normalX: SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: value.wall_angle)),
                normalZ: SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: value.wall_angle))
            )
        }
        guard let initialFloor = floor(input.floor) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        var probes: [SM64MarioGroundQuarterProbe] = []
        probes.reserveCapacity(4)
        for index in 0..<4 {
            let probe: SM64ModernMarioGroundQuarterProbeV1
            switch index {
            case 0: probe = input.quarter_probes.0
            case 1: probe = input.quarter_probes.1
            case 2: probe = input.quarter_probes.2
            default: probe = input.quarter_probes.3
            }
            guard probe.floor.present <= 1 else {
                return SM64_MODERN_STATUS_INVALID_ARGUMENT
            }
            probes.append(SM64MarioGroundQuarterProbe(
                floor: floor(probe.floor),
                ceilingHeight: Float(bitPattern: probe.ceiling_height_bits),
                waterLevel: Float(bitPattern: probe.water_level_bits),
                upperWall: wall(probe.upper_wall)
            ))
        }
        let stepInput = SM64MarioGroundStepInput(
            position: SM64ObjectVector3(
                x: Float(bitPattern: input.position_x_bits),
                y: Float(bitPattern: input.position_y_bits),
                z: Float(bitPattern: input.position_z_bits)
            ),
            velocity: SM64ObjectVector3(
                x: Float(bitPattern: input.velocity_x_bits),
                y: Float(bitPattern: input.velocity_y_bits),
                z: Float(bitPattern: input.velocity_z_bits)
            ),
            floor: initialFloor,
            faceYaw: input.face_yaw,
            nativeStepScale: Float(bitPattern: input.native_step_scale_bits),
            ridingShell: input.riding_shell != 0,
            terrainSoundAddend: input.terrain_sound_addend,
            quarterProbes: probes
        )
        guard let result = SM64MarioGroundStep.update(stepInput) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        var value = SM64ModernMarioGroundStepOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioGroundStepOutputV1>.size)
        value.position_x_bits = result.position.x.bitPattern
        value.position_y_bits = result.position.y.bitPattern
        value.position_z_bits = result.position.z.bitPattern
        value.floor.present = result.floor.surfaceID == nil ? 0 : 1
        value.floor.surface_id = result.floor.surfaceID ?? 0
        value.floor.height_bits = result.floor.height.bitPattern
        value.floor.normal_y_bits = result.floor.normalY.bitPattern
        value.wall_present = result.wallSurfaceID == nil ? 0 : 1
        value.wall_surface_id = result.wallSurfaceID ?? 0
        value.result = UInt32(result.result.rawValue)
        value.quarter_steps = UInt32(result.quarterSteps)
        value.terrain_sound_addend = result.terrainSoundAddend
        output.pointee = value
        marioGroundStepCandidate = MarioGroundStepCandidate(
            tick: input.simulation_tick,
            output: value
        )
        marioGroundStepUpdates += 1
        if marioGroundStepUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_ground_step")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioAirStep(
        input: SM64ModernMarioAirStepInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioAirStepOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard input.riding_shell <= 1,
              input.ceil_present <= 1 else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }

        func floor(_ value: SM64ModernMarioGroundFloorProbeV1) -> SM64MarioGroundFloorProbe? {
            guard value.present <= 1, value.present != 0 else { return nil }
            return SM64MarioGroundFloorProbe(
                surfaceID: value.surface_id,
                height: Float(bitPattern: value.height_bits),
                normalY: Float(bitPattern: value.normal_y_bits)
            )
        }
        func wall(_ value: SM64ModernMarioAirWallProbeV1) -> SM64MarioAirWallProbe? {
            guard value.present <= 1, value.present != 0, value.reserved == 0 else { return nil }
            return SM64MarioAirWallProbe(
                surfaceID: value.surface_id,
                surfaceType: value.surface_type,
                normalX: Float(bitPattern: value.normal_x_bits),
                normalZ: Float(bitPattern: value.normal_z_bits),
                wallAngle: Int16(truncatingIfNeeded: value.wall_angle)
            )
        }
        func quarter(_ value: SM64ModernMarioAirQuarterProbeV1) -> SM64MarioAirQuarterProbe? {
            guard value.ledge_present <= 1 else {
                return nil
            }
            return SM64MarioAirQuarterProbe(
                floor: floor(value.floor),
                ceilingHeight: Float(bitPattern: value.ceiling_height_bits),
                waterLevel: Float(bitPattern: value.water_level_bits),
                upperWall: wall(value.upper_wall),
                lowerWall: wall(value.lower_wall),
                ledgeFloor: floor(value.ledge_floor),
                ledgePosition: SM64ObjectVector3(
                    x: Float(bitPattern: value.ledge_position_x_bits),
                    y: Float(bitPattern: value.ledge_position_y_bits),
                    z: Float(bitPattern: value.ledge_position_z_bits)
                ),
                ledgeFloorAngle: Int16(truncatingIfNeeded: value.ledge_floor_angle),
                ledgePresent: value.ledge_present != 0
            )
        }

        guard let initialFloor = floor(input.floor) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        var probes: [SM64MarioAirQuarterProbe] = []
        probes.reserveCapacity(4)
        for index in 0..<4 {
            let value: SM64ModernMarioAirQuarterProbeV1
            switch index {
            case 0: value = input.quarter_probes.0
            case 1: value = input.quarter_probes.1
            case 2: value = input.quarter_probes.2
            default: value = input.quarter_probes.3
            }
            guard let converted = quarter(value) else {
                return SM64_MODERN_STATUS_INVALID_ARGUMENT
            }
            probes.append(converted)
        }

        let stepInput = SM64MarioAirStepInput(
            position: SM64ObjectVector3(
                x: Float(bitPattern: input.position_x_bits),
                y: Float(bitPattern: input.position_y_bits),
                z: Float(bitPattern: input.position_z_bits)
            ),
            velocity: SM64ObjectVector3(
                x: Float(bitPattern: input.velocity_x_bits),
                y: Float(bitPattern: input.velocity_y_bits),
                z: Float(bitPattern: input.velocity_z_bits)
            ),
            floor: initialFloor,
            facePitch: input.face_pitch,
            faceYaw: input.face_yaw,
            faceRoll: input.face_roll,
            floorAngle: input.floor_angle,
            action: input.action,
            stepArg: input.step_arg,
            nativeStepScale: Float(bitPattern: input.native_step_scale_bits),
            ridingShell: input.riding_shell != 0,
            ceilPresent: input.ceil_present != 0,
            ceilType: input.ceil_type,
            quarterProbes: probes
        )
        guard let result = SM64MarioAirStep.update(stepInput) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }

        var value = SM64ModernMarioAirStepOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioAirStepOutputV1>.size)
        value.position_x_bits = result.position.x.bitPattern
        value.position_y_bits = result.position.y.bitPattern
        value.position_z_bits = result.position.z.bitPattern
        value.velocity_y_bits = result.velocityY.bitPattern
        value.floor.present = result.floor.surfaceID == nil ? 0 : 1
        value.floor.surface_id = result.floor.surfaceID ?? 0
        value.floor.height_bits = result.floor.height.bitPattern
        value.floor.normal_y_bits = result.floor.normalY.bitPattern
        if let wall = result.wall {
            value.wall.present = 1
            value.wall.surface_id = wall.surfaceID
            value.wall.surface_type = wall.surfaceType
            value.wall.normal_x_bits = wall.normalX.bitPattern
            value.wall.normal_z_bits = wall.normalZ.bitPattern
            value.wall.wall_angle = Int32(wall.wallAngle)
        }
        value.result = result.result.rawValue
        value.quarter_steps = UInt32(result.quarterSteps)
        value.flags_or = result.flagsOr
        value.face_pitch = result.facePitch
        value.face_yaw = result.faceYaw
        value.face_roll = result.faceRoll
        value.floor_angle = result.floorAngle
        value.terrain_sound_addend = result.terrainSoundAddend
        output.pointee = value
        marioAirStepCandidate = MarioAirStepCandidate(
            tick: input.simulation_tick,
            output: value
        )
        marioAirStepUpdates += 1
        if marioAirStepUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_air_step")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioWaterStep(
        input: SM64ModernMarioWaterStepInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioWaterStepOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()

        func floor(_ value: SM64ModernMarioWaterFloorProbeV1) -> SM64MarioWaterFloorProbe? {
            guard value.present <= 1, value.present != 0 else { return nil }
            return SM64MarioWaterFloorProbe(
                surfaceID: value.surface_id,
                height: Float(bitPattern: value.height_bits)
            )
        }
        func wall(_ value: SM64ModernMarioWaterWallProbeV1) -> SM64MarioWaterWallProbe? {
            guard value.present <= 1, value.present != 0, value.reserved == 0 else { return nil }
            return SM64MarioWaterWallProbe(surfaceID: value.surface_id)
        }
        guard let currentFloor = floor(input.current_floor) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }

        let stepInput = SM64MarioWaterStepInput(
            position: SM64ObjectVector3(
                x: Float(bitPattern: input.position_x_bits),
                y: Float(bitPattern: input.position_y_bits),
                z: Float(bitPattern: input.position_z_bits)
            ),
            nextPosition: SM64ObjectVector3(
                x: Float(bitPattern: input.next_position_x_bits),
                y: Float(bitPattern: input.next_position_y_bits),
                z: Float(bitPattern: input.next_position_z_bits)
            ),
            currentFloor: currentFloor,
            floor: floor(input.floor),
            ceilingHeight: Float(bitPattern: input.ceiling_height_bits),
            wall: wall(input.wall)
        )
        guard let result = SM64MarioWaterStep.update(stepInput) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }

        var value = SM64ModernMarioWaterStepOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioWaterStepOutputV1>.size)
        value.position_x_bits = result.position.x.bitPattern
        value.position_y_bits = result.position.y.bitPattern
        value.position_z_bits = result.position.z.bitPattern
        value.floor.present = result.floor.surfaceID == nil ? 0 : 1
        value.floor.surface_id = result.floor.surfaceID ?? 0
        value.floor.height_bits = result.floor.height.bitPattern
        value.result = result.result.rawValue
        output.pointee = value
        marioWaterStepCandidate = MarioWaterStepCandidate(
            tick: input.simulation_tick,
            output: value
        )
        marioWaterStepUpdates += 1
        if marioWaterStepUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_water_step")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioBonk(
        input: SM64ModernMarioBonkInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioBonkOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard input.wall_present <= 1,
              input.negate_speed <= 1,
              input.metal_cap <= 1 else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        let wallAngle = input.wall_present != 0
            ? Int16(truncatingIfNeeded: input.wall_angle)
            : nil
        let result = SM64MarioBonk.update(
            SM64MarioBonkInput(
                faceYaw: Int16(truncatingIfNeeded: input.face_yaw),
                forwardVelocity: Float(bitPattern: input.forward_velocity_bits),
                velocityX: Float(bitPattern: input.velocity_x_bits),
                velocityZ: Float(bitPattern: input.velocity_z_bits),
                wallAngle: wallAngle,
                negateSpeed: input.negate_speed != 0,
                metalCap: input.metal_cap != 0
            )
        )
        guard let result else { return SM64_MODERN_STATUS_INVALID_ARGUMENT }

        var value = SM64ModernMarioBonkOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioBonkOutputV1>.size)
        value.face_yaw = Int32(result.faceYaw)
        value.forward_velocity_bits = result.forwardVelocity.bitPattern
        value.velocity_x_bits = result.velocityX.bitPattern
        value.velocity_z_bits = result.velocityZ.bitPattern
        value.sound_kind = result.soundKind.rawValue
        output.pointee = value
        marioBonkCandidate = MarioBonkCandidate(
            tick: input.simulation_tick,
            output: value
        )
        marioBonkUpdates += 1
        if marioBonkUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_bonk")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioTerrainImpulse(
        input: SM64ModernMarioTerrainImpulseInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioTerrainImpulseOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard input.moving_action <= 1 else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        let family: SM64MarioTerrainImpulseFamily
        switch input.family {
        case SM64_MODERN_MARIO_TERRAIN_IMPULSE_MOVING_SAND:
            family = .movingSand
        case SM64_MODERN_MARIO_TERRAIN_IMPULSE_HORIZONTAL_WIND:
            family = .horizontalWind
        default:
            return SM64_MODERN_STATUS_UNSUPPORTED_AUTHORITY
        }
        guard let result = SM64MarioTerrainImpulse.update(
            SM64MarioTerrainImpulseInput(
                family: family,
                floorType: input.floor_type,
                force: Int16(truncatingIfNeeded: input.force),
                movingAction: input.moving_action != 0,
                faceYaw: Int16(truncatingIfNeeded: input.face_yaw),
                forwardVelocity: Float(bitPattern: input.forward_velocity_bits),
                globalTimer: input.global_timer,
                velocityX: Float(bitPattern: input.velocity_x_bits),
                velocityZ: Float(bitPattern: input.velocity_z_bits)
            )
        ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }

        var value = SM64ModernMarioTerrainImpulseOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioTerrainImpulseOutputV1>.size)
        value.velocity_x_bits = result.velocityX.bitPattern
        value.velocity_z_bits = result.velocityZ.bitPattern
        value.applied = result.applied ? 1 : 0
        value.sound_kind = result.soundKind
        output.pointee = value
        marioTerrainImpulseCandidate = MarioTerrainImpulseCandidate(
            tick: input.simulation_tick,
            output: value
        )
        marioTerrainImpulseUpdates += 1
        if marioTerrainImpulseUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_terrain_impulse")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioQuicksand(
        input: SM64ModernMarioQuicksandInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioQuicksandOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard input.riding_shell <= 1 else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        guard let result = SM64MarioQuicksand.update(
            SM64MarioQuicksandInput(
                floorType: input.floor_type,
                ridingShell: input.riding_shell != 0,
                quicksandDepth: Float(bitPattern: input.quicksand_depth_bits),
                sinkingSpeed: Float(bitPattern: input.sinking_speed_bits)
            )
        ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        var value = SM64ModernMarioQuicksandOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioQuicksandOutputV1>.size)
        value.quicksand_depth_bits = result.quicksandDepth.bitPattern
        value.action = result.action ?? 0
        value.action_argument = result.actionArgument
        value.update_sound_camera = result.updateSoundCamera ? 1 : 0
        output.pointee = value
        marioQuicksandUpdates += 1
        if marioQuicksandUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_quicksand")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioSteepPush(
        input: SM64ModernMarioSteepPushInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioSteepPushOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        let result = SM64MarioSteepPush.update(
            SM64MarioSteepPushInput(
                floorAngle: Int16(truncatingIfNeeded: input.floor_angle),
                faceYaw: Int16(truncatingIfNeeded: input.face_yaw),
                action: input.action,
                actionArgument: input.action_argument
            )
        )
        var value = SM64ModernMarioSteepPushOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioSteepPushOutputV1>.size)
        value.forward_velocity_bits = result.forwardVelocity.bitPattern
        value.face_yaw = Int32(result.faceYaw)
        value.action = result.action
        value.action_argument = result.actionArgument
        output.pointee = value
        marioSteepPushUpdates += 1
        if marioSteepPushUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_steep_push")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioTerrainSound(
        input: SM64ModernMarioTerrainSoundInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioTerrainSoundOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard input.floor_present <= 1, input.is_lava_level <= 1 else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        guard let result = SM64MarioTerrainSound.update(
            SM64MarioTerrainSoundInput(
                floorPresent: input.floor_present != 0,
                floorType: input.floor_type,
                floorHeight: Float(bitPattern: input.floor_height_bits),
                waterLevel: Float(bitPattern: input.water_level_bits),
                terrainType: UInt16(truncatingIfNeeded: input.terrain_type),
                isLavaLevel: input.is_lava_level != 0
            )
        ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        var value = SM64ModernMarioTerrainSoundOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioTerrainSoundOutputV1>.size)
        value.terrain_sound_addend = result.terrainSoundAddend
        output.pointee = value
        marioTerrainSoundUpdates += 1
        if marioTerrainSoundUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_terrain_sound")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioFloorPredicates(
        input: SM64ModernMarioFloorPredicatesInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioFloorPredicatesOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard input.floor_present <= 1, input.is_crawling <= 1 else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        guard let result = SM64MarioFloorPredicates.update(
            SM64MarioFloorPredicatesInput(
                floorPresent: input.floor_present != 0,
                floorType: input.floor_type,
                terrainType: UInt16(truncatingIfNeeded: input.terrain_type),
                normalY: Float(bitPattern: input.normal_y_bits),
                floorAngle: Int16(truncatingIfNeeded: input.floor_angle),
                faceYaw: Int16(truncatingIfNeeded: input.face_yaw),
                isCrawling: input.is_crawling != 0,
                turnYaw: Int16(truncatingIfNeeded: input.turn_yaw),
                forwardVelocity: Float(bitPattern: input.forward_velocity_bits)
            )
        ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        var value = SM64ModernMarioFloorPredicatesOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioFloorPredicatesOutputV1>.size)
        value.floor_class = result.floorClass
        value.is_slippery = result.isSlippery ? 1 : 0
        value.is_slope = result.isSlope ? 1 : 0
        value.is_steep = result.isSteep ? 1 : 0
        value.facing_downhill = result.facingDownhill ? 1 : 0
        output.pointee = value
        marioFloorPredicateUpdates += 1
        if marioFloorPredicateUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_floor_predicates")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioForwardVelocity(
        input: SM64ModernMarioForwardVelocityInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioForwardVelocityOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard let result = SM64MarioForwardVelocity.update(
            SM64MarioForwardVelocityInput(
                forwardVelocity: Float(bitPattern: input.forward_velocity_bits),
                faceYaw: Int16(truncatingIfNeeded: input.face_yaw)
            )
        ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        var value = SM64ModernMarioForwardVelocityOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioForwardVelocityOutputV1>.size)
        value.forward_velocity_bits = result.forwardVelocity.bitPattern
        value.slide_velocity_x_bits = result.slideVelocityX.bitPattern
        value.slide_velocity_z_bits = result.slideVelocityZ.bitPattern
        value.velocity_x_bits = result.velocityX.bitPattern
        value.velocity_z_bits = result.velocityZ.bitPattern
        output.pointee = value
        marioForwardVelocityUpdates += 1
        if marioForwardVelocityUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_forward_velocity")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioVelocityDerivation(
        input: SM64ModernMarioVelocityDerivationInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioVelocityDerivationOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        let family: SM64MarioVelocityDerivationFamily
        switch input.family {
        case SM64_MODERN_MARIO_VELOCITY_FROM_YAW: family = .yaw
        case SM64_MODERN_MARIO_VELOCITY_FROM_PITCH_YAW: family = .pitchYaw
        default: return SM64_MODERN_STATUS_UNSUPPORTED_AUTHORITY
        }
        guard let result = SM64MarioVelocityDerivation.update(
            SM64MarioVelocityDerivationInput(
                family: family,
                forwardVelocity: Float(bitPattern: input.forward_velocity_bits),
                facePitch: Int16(truncatingIfNeeded: input.face_pitch),
                faceYaw: Int16(truncatingIfNeeded: input.face_yaw)
            )
        ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        var value = SM64ModernMarioVelocityDerivationOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioVelocityDerivationOutputV1>.size)
        value.velocity_x_bits = result.velocity.x.bitPattern
        value.velocity_y_bits = result.velocity.y.bitPattern
        value.velocity_z_bits = result.velocity.z.bitPattern
        value.slide_velocity_x_bits = result.slideVelocityX.bitPattern
        value.slide_velocity_z_bits = result.slideVelocityZ.bitPattern
        output.pointee = value
        marioVelocityDerivationUpdates += 1
        if marioVelocityDerivationUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_velocity_derivation")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioPunch(
        input: SM64ModernMarioPunchInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioPunchOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard input.moving_action <= 1,
              input.animation_at_end <= 1,
              input.animation_past_end <= 1,
              input.b_pressed <= 1 else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        let sound: SM64MarioPunchSoundKind
        let result: SM64MarioPunchSequenceResult?
        switch input.action_argument {
        default:
            result = SM64MarioPunchSequence.update(
                SM64MarioPunchSequenceInput(
                    movingAction: input.moving_action != 0,
                    actionArgument: input.action_argument,
                    animationFrame: Int16(truncatingIfNeeded: input.animation_frame),
                    animationAtEnd: input.animation_at_end != 0,
                    animationPastEnd: input.animation_past_end != 0,
                    bPressed: input.b_pressed != 0
                )
            )
        }
        guard let result else { return SM64_MODERN_STATUS_UNSUPPORTED_AUTHORITY }
        sound = result.sound
        var value = SM64ModernMarioPunchOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioPunchOutputV1>.size)
        value.action_argument = result.actionArgument
        value.animation_id = UInt32(result.animationID)
        value.transition_action = result.transitionAction ?? 0
        value.flags = result.flags
        if let punchState = result.punchState {
            value.punch_state = UInt32(punchState)
            value.punch_state_valid = 1
        }
        value.sound_kind = UInt32(sound.rawValue)
        output.pointee = value
        marioPunchUpdates += 1
        if marioPunchUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_punch")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioWallResponse(
        input: SM64ModernMarioWallResponseInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioWallResponseOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        let wall = input.wall_present != 0
            ? SM64MarioWallResponseProbe(
                // `atan2s(y: normal.z, x: normal.x)` uses the engine's
                // quarter-turn convention.  Build the inverse pair so the
                // kernel recovers the ABI wall angle exactly rather than
                // applying a second 90-degree rotation.
                normalX: SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.wall_angle)),
                normalZ: SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.wall_angle))
            ) : nil
        guard let result = SM64MarioWallResponse.update(
            SM64MarioWallResponseInput(
                startPosition: SM64ObjectVector3(
                    x: Float(bitPattern: input.start_position_x_bits), y: 0,
                    z: Float(bitPattern: input.start_position_z_bits)
                ),
                position: SM64ObjectVector3(
                    x: Float(bitPattern: input.position_x_bits), y: 0,
                    z: Float(bitPattern: input.position_z_bits)
                ),
                velocity: SM64ObjectVector3(
                    x: Float(bitPattern: input.velocity_x_bits),
                    y: Float(bitPattern: input.velocity_y_bits),
                    z: Float(bitPattern: input.velocity_z_bits)
                ),
                forwardVelocity: Float(bitPattern: input.forward_velocity_bits),
                faceYaw: input.face_yaw,
                animationFrame: Int16(truncatingIfNeeded: input.animation_frame),
                animationPastFrame1: input.animation_past_frame1 != 0,
                animationPastFrame2: input.animation_past_frame2 != 0,
                terrainSoundAddend: input.terrain_sound_addend,
                floorSlopePitch: Int16(truncatingIfNeeded: input.floor_slope_pitch),
                wall: wall
            )
        ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        var value = SM64ModernMarioWallResponseOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioWallResponseOutputV1>.size)
        value.velocity_x_bits = result.velocity.x.bitPattern
        value.velocity_y_bits = result.velocity.y.bitPattern
        value.velocity_z_bits = result.velocity.z.bitPattern
        value.forward_velocity_bits = result.forwardVelocity.bitPattern
        value.flags = result.flags
        value.animation_id = UInt32(result.animationID)
        value.animation_acceleration = result.animationAcceleration
        value.sound_kind = UInt32(result.sound.rawValue)
        value.particle_dust = result.particleDust ? 1 : 0
        value.action_state = UInt32(result.actionState)
        value.action_argument = result.actionArgument
        value.gfx_pitch = result.gfxAngle.pitch
        value.gfx_yaw = result.gfxAngle.yaw
        value.gfx_roll = result.gfxAngle.roll
        output.pointee = value
        marioWallResponseUpdates += 1
        if marioWallResponseUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_wall_response")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioWalkAnimation(
        input: SM64ModernMarioWalkAnimationInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioWalkAnimationOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard input.action_timer <= 3,
              input.animation_past_frame23 <= 1,
              input.animation_past_frame1 <= 1,
              input.animation_past_frame2 <= 1,
              input.metal_cap <= 1 else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        guard let result = SM64MarioWalkAnimation.update(
            SM64MarioWalkAnimationInput(
                intendedMagnitude: Float(bitPattern: input.intended_magnitude_bits),
                forwardVelocity: Float(bitPattern: input.forward_velocity_bits),
                quicksandDepth: Float(bitPattern: input.quicksand_depth_bits),
                actionTimer: UInt16(truncatingIfNeeded: input.action_timer),
                animationPastFrame23: input.animation_past_frame23 != 0,
                animationPastFrame1: input.animation_past_frame1 != 0,
                animationPastFrame2: input.animation_past_frame2 != 0,
                metalCap: input.metal_cap != 0,
                walkingPitch: Int16(truncatingIfNeeded: input.walking_pitch),
                runningPitch: Int16(truncatingIfNeeded: input.running_pitch)
            )
        ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        var value = SM64ModernMarioWalkAnimationOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioWalkAnimationOutputV1>.size)
        value.animation_id = UInt32(result.animationID)
        value.animation_acceleration = result.animationAcceleration
        value.action_timer = UInt32(result.actionTimer)
        value.walking_pitch = Int32(result.walkingPitch)
        value.sound_kind = UInt32(result.sound.rawValue)
        value.sound_frame1 = Int32(result.soundFrame1)
        value.sound_frame2 = Int32(result.soundFrame2)
        output.pointee = value
        marioWalkAnimationUpdates += 1
        if marioWalkAnimationUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_walk_animation")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioHeldWalkAnimation(
        input: SM64ModernMarioHeldWalkAnimationInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioHeldWalkAnimationOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard input.variant <= SM64_MODERN_MARIO_HELD_WALK_HEAVY,
              input.action_timer <= 2,
              input.animation_past_frame1 <= 1,
              input.animation_past_frame2 <= 1,
              input.metal_cap <= 1 else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        let variant: SM64MarioHeldWalkAnimationVariant
        switch input.variant {
        case SM64_MODERN_MARIO_HELD_WALK_LIGHT:
            variant = .light
        case SM64_MODERN_MARIO_HELD_WALK_HEAVY:
            variant = .heavy
        default:
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        guard let result = SM64MarioHeldWalkAnimation.update(
            SM64MarioHeldWalkAnimationInput(
                variant: variant,
                intendedMagnitude: Float(bitPattern: input.intended_magnitude_bits),
                forwardVelocity: Float(bitPattern: input.forward_velocity_bits),
                quicksandDepth: Float(bitPattern: input.quicksand_depth_bits),
                actionTimer: UInt16(truncatingIfNeeded: input.action_timer),
                animationPastFrame1: input.animation_past_frame1 != 0,
                animationPastFrame2: input.animation_past_frame2 != 0,
                metalCap: input.metal_cap != 0
            )
        ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        var value = SM64ModernMarioHeldWalkAnimationOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioHeldWalkAnimationOutputV1>.size)
        value.animation_id = UInt32(result.animationID)
        value.animation_acceleration = result.animationAcceleration
        value.action_timer = UInt32(result.actionTimer)
        value.sound_kind = UInt32(result.sound.rawValue)
        value.sound_frame1 = Int32(result.soundFrame1)
        value.sound_frame2 = Int32(result.soundFrame2)
        output.pointee = value
        marioHeldWalkAnimationUpdates += 1
        if marioHeldWalkAnimationUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_held_walk_animation")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioSlopeAcceleration(
        input: SM64ModernMarioSlopeAccelerationInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioSlopeAccelerationOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard input.terrain_is_slide <= 1,
              let floorClass = SM64MarioFloorClass(
                rawValue: Int16(truncatingIfNeeded: input.floor_class)
              ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        guard let result = SM64MarioSlope.update(
            SM64MarioSlopeInput(
                floorClass: floorClass,
                terrainIsSlide: input.terrain_is_slide != 0,
                floorNormalX: Float(bitPattern: input.floor_normal_x_bits),
                floorNormalY: Float(bitPattern: input.floor_normal_y_bits),
                floorNormalZ: Float(bitPattern: input.floor_normal_z_bits),
                floorAngle: Int16(truncatingIfNeeded: input.floor_angle),
                faceYaw: Int16(truncatingIfNeeded: input.face_yaw),
                forwardVelocity: Float(bitPattern: input.forward_velocity_bits),
                action: input.action
            )
        ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        var value = SM64ModernMarioSlopeAccelerationOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioSlopeAccelerationOutputV1>.size)
        value.forward_velocity_bits = result.forwardVelocity.bitPattern
        value.slide_yaw = Int32(result.slideYaw)
        value.slide_velocity_x_bits = result.slideVelocityX.bitPattern
        value.slide_velocity_z_bits = result.slideVelocityZ.bitPattern
        value.velocity_x_bits = result.velocity.x.bitPattern
        value.velocity_y_bits = result.velocity.y.bitPattern
        value.velocity_z_bits = result.velocity.z.bitPattern
        value.facing_downhill = result.facingDownhill ? 1 : 0
        value.floor_is_slope = result.floorIsSlope ? 1 : 0
        value.floor_is_steep = result.floorIsSteep ? 1 : 0
        value.update_moving_sand = result.shouldUpdateMovingSand ? 1 : 0
        value.update_windy_ground = result.shouldUpdateWindyGround ? 1 : 0
        output.pointee = value
        marioSlopeAccelerationUpdates += 1
        if marioSlopeAccelerationUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_slope_acceleration")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioSlopeDeceleration(
        input: SM64ModernMarioSlopeDecelerationInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioSlopeDecelerationOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard input.terrain_is_slide <= 1,
              let floorClass = SM64MarioFloorClass(
                rawValue: Int16(truncatingIfNeeded: input.floor_class)
              ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        guard let result = SM64MarioSlopeDeceleration.update(
            SM64MarioSlopeDecelerationInput(
                coefficient: Float(bitPattern: input.coefficient_bits),
                floorClass: floorClass,
                terrainIsSlide: input.terrain_is_slide != 0,
                floorNormalX: Float(bitPattern: input.floor_normal_x_bits),
                floorNormalY: Float(bitPattern: input.floor_normal_y_bits),
                floorNormalZ: Float(bitPattern: input.floor_normal_z_bits),
                floorAngle: Int16(truncatingIfNeeded: input.floor_angle),
                faceYaw: Int16(truncatingIfNeeded: input.face_yaw),
                forwardVelocity: Float(bitPattern: input.forward_velocity_bits),
                action: input.action
            )
        ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        var value = SM64ModernMarioSlopeDecelerationOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioSlopeDecelerationOutputV1>.size)
        value.stopped = result.stopped ? 1 : 0
        value.forward_velocity_bits = result.slope.forwardVelocity.bitPattern
        value.slide_yaw = Int32(result.slope.slideYaw)
        value.slide_velocity_x_bits = result.slope.slideVelocityX.bitPattern
        value.slide_velocity_z_bits = result.slope.slideVelocityZ.bitPattern
        value.velocity_x_bits = result.slope.velocity.x.bitPattern
        value.velocity_y_bits = result.slope.velocity.y.bitPattern
        value.velocity_z_bits = result.slope.velocity.z.bitPattern
        value.facing_downhill = result.slope.facingDownhill ? 1 : 0
        value.floor_is_slope = result.slope.floorIsSlope ? 1 : 0
        value.floor_is_steep = result.slope.floorIsSteep ? 1 : 0
        value.update_moving_sand = result.slope.shouldUpdateMovingSand ? 1 : 0
        value.update_windy_ground = result.slope.shouldUpdateWindyGround ? 1 : 0
        output.pointee = value
        marioSlopeDecelerationUpdates += 1
        if marioSlopeDecelerationUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_slope_deceleration")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioDeceleratingSpeed(
        input: SM64ModernMarioDeceleratingSpeedInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioDeceleratingSpeedOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard let result = SM64MarioDeceleratingSpeed.update(
            SM64MarioDeceleratingSpeedInput(
                forwardVelocity: Float(bitPattern: input.forward_velocity_bits),
                faceYaw: Int16(truncatingIfNeeded: input.face_yaw),
                velocityY: Float(bitPattern: input.velocity_y_bits)
            )
        ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        var value = SM64ModernMarioDeceleratingSpeedOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioDeceleratingSpeedOutputV1>.size)
        value.stopped = result.stopped ? 1 : 0
        value.forward_velocity_bits = result.forwardVelocity.bitPattern
        value.velocity_x_bits = result.velocity.x.bitPattern
        value.velocity_y_bits = result.velocity.y.bitPattern
        value.velocity_z_bits = result.velocity.z.bitPattern
        value.update_moving_sand = result.shouldUpdateMovingSand ? 1 : 0
        value.update_windy_ground = result.shouldUpdateWindyGround ? 1 : 0
        output.pointee = value
        marioDeceleratingSpeedUpdates += 1
        if marioDeceleratingSpeedUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_decelerating_speed")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioShellSpeed(
        input: SM64ModernMarioShellSpeedInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioShellSpeedOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard input.floor_is_slow <= 1,
              input.terrain_is_slide <= 1,
              let floorClass = SM64MarioFloorClass(
                rawValue: Int16(truncatingIfNeeded: input.floor_class)
              ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        guard let result = SM64MarioShellSpeed.update(
            SM64MarioShellSpeedInput(
                intendedMagnitude: Float(bitPattern: input.intended_magnitude_bits),
                intendedYaw: Int16(truncatingIfNeeded: input.intended_yaw),
                faceYaw: Int16(truncatingIfNeeded: input.face_yaw),
                forwardVelocity: Float(bitPattern: input.forward_velocity_bits),
                floorIsSlow: input.floor_is_slow != 0,
                floorNormalY: Float(bitPattern: input.floor_normal_y_bits),
                floorClass: floorClass,
                terrainIsSlide: input.terrain_is_slide != 0,
                floorNormalX: Float(bitPattern: input.floor_normal_x_bits),
                floorNormalZ: Float(bitPattern: input.floor_normal_z_bits),
                floorAngle: Int16(truncatingIfNeeded: input.floor_angle),
                action: input.action
            )
        ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        var value = SM64ModernMarioShellSpeedOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioShellSpeedOutputV1>.size)
        value.forward_velocity_bits = result.forwardVelocity.bitPattern
        value.face_yaw = Int32(result.faceYaw)
        value.slide_yaw = Int32(result.slope.slideYaw)
        value.slide_velocity_x_bits = result.slope.slideVelocityX.bitPattern
        value.slide_velocity_z_bits = result.slope.slideVelocityZ.bitPattern
        value.velocity_x_bits = result.slope.velocity.x.bitPattern
        value.velocity_y_bits = result.slope.velocity.y.bitPattern
        value.velocity_z_bits = result.slope.velocity.z.bitPattern
        value.facing_downhill = result.slope.facingDownhill ? 1 : 0
        value.floor_is_slope = result.slope.floorIsSlope ? 1 : 0
        value.floor_is_steep = result.slope.floorIsSteep ? 1 : 0
        value.update_moving_sand = result.slope.shouldUpdateMovingSand ? 1 : 0
        value.update_windy_ground = result.slope.shouldUpdateWindyGround ? 1 : 0
        output.pointee = value
        marioShellSpeedUpdates += 1
        if marioShellSpeedUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_shell_speed")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioLandingAcceleration(
        input: SM64ModernMarioLandingAccelerationInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioLandingAccelerationOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard let floorClass = SM64MarioFloorClass(
            rawValue: Int16(truncatingIfNeeded: input.floor_class)
        ), input.terrain_is_slide <= 1 else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        guard let result = SM64MarioLandingAcceleration.update(
            SM64MarioLandingAccelerationInput(
                frictionFactor: Float(bitPattern: input.friction_factor_bits),
                floorClass: floorClass,
                terrainIsSlide: input.terrain_is_slide != 0,
                floorNormalX: Float(bitPattern: input.floor_normal_x_bits),
                floorNormalY: Float(bitPattern: input.floor_normal_y_bits),
                floorNormalZ: Float(bitPattern: input.floor_normal_z_bits),
                floorAngle: Int16(truncatingIfNeeded: input.floor_angle),
                faceYaw: Int16(truncatingIfNeeded: input.face_yaw),
                forwardVelocity: Float(bitPattern: input.forward_velocity_bits),
                action: input.action
            )
        ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        var value = SM64ModernMarioLandingAccelerationOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioLandingAccelerationOutputV1>.size)
        value.stopped = result.stopped ? 1 : 0
        value.forward_velocity_bits = result.forwardVelocity.bitPattern
        value.slide_yaw = Int32(result.slope.slideYaw)
        value.slide_velocity_x_bits = result.slope.slideVelocityX.bitPattern
        value.slide_velocity_z_bits = result.slope.slideVelocityZ.bitPattern
        value.velocity_x_bits = result.slope.velocity.x.bitPattern
        value.velocity_y_bits = result.slope.velocity.y.bitPattern
        value.velocity_z_bits = result.slope.velocity.z.bitPattern
        value.floor_is_slope = result.slope.floorIsSlope ? 1 : 0
        value.update_moving_sand = result.slope.shouldUpdateMovingSand ? 1 : 0
        value.update_windy_ground = result.slope.shouldUpdateWindyGround ? 1 : 0
        output.pointee = value
        marioLandingAccelerationUpdates += 1
        if marioLandingAccelerationUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_landing_acceleration")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioGravity(
        input: SM64ModernMarioGravityInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioGravityOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard let result = SM64MarioGravity.update(
            SM64MarioGravityInput(
                action: input.action,
                marioFlags: input.mario_flags,
                input: input.input,
                angleVelocityY: input.angle_velocity_y,
                velocityY: Float(bitPattern: input.velocity_y_bits),
                unkC4: Float(bitPattern: input.unk_c4_bits)
            )
        ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        var value = SM64ModernMarioGravityOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioGravityOutputV1>.size)
        value.velocity_y_bits = result.velocityY.bitPattern
        value.wing_flutter = result.wingFlutter ? 1 : 0
        output.pointee = value
        marioGravityUpdates += 1
        if marioGravityUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_gravity")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioVerticalWind(
        input: SM64ModernMarioVerticalWindInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioVerticalWindOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard let result = SM64MarioVerticalWind.update(
            SM64MarioVerticalWindInput(
                action: input.action,
                floorType: input.floor_type,
                positionY: Float(bitPattern: input.position_y_bits),
                velocityY: Float(bitPattern: input.velocity_y_bits)
            )
        ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        var value = SM64ModernMarioVerticalWindOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioVerticalWindOutputV1>.size)
        value.velocity_y_bits = result.velocityY.bitPattern
        value.active = result.active ? 1 : 0
        output.pointee = value
        marioVerticalWindUpdates += 1
        if marioVerticalWindUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_vertical_wind")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioSliding(
        input: SM64ModernMarioSlidingInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioSlidingOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard input.floor_is_slope <= 1,
              let floorClass = SM64MarioFloorClass(
                rawValue: Int16(truncatingIfNeeded: input.floor_class)
              ),
              let result = SM64MarioSliding.update(
                SM64MarioSlidingInput(
                    floorClass: floorClass,
                    floorIsSlope: input.floor_is_slope != 0,
                    floorNormalX: Float(bitPattern: input.floor_normal_x_bits),
                    floorNormalY: Float(bitPattern: input.floor_normal_y_bits),
                    floorNormalZ: Float(bitPattern: input.floor_normal_z_bits),
                    intendedYaw: Int16(truncatingIfNeeded: input.intended_yaw),
                    intendedMagnitude: Float(bitPattern: input.intended_magnitude_bits),
                    faceYaw: Int16(truncatingIfNeeded: input.face_yaw),
                    slideYaw: Int16(truncatingIfNeeded: input.slide_yaw),
                    forwardVelocity: Float(bitPattern: input.forward_velocity_bits),
                    slideVelocityX: Float(bitPattern: input.slide_velocity_x_bits),
                    slideVelocityZ: Float(bitPattern: input.slide_velocity_z_bits),
                    stopSpeed: Float(bitPattern: input.stop_speed_bits)
                )
              ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        var value = SM64ModernMarioSlidingOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioSlidingOutputV1>.size)
        value.stopped = result.stopped ? 1 : 0
        value.face_yaw = Int32(result.faceYaw)
        value.slide_yaw = Int32(result.slideYaw)
        value.forward_velocity_bits = result.forwardVelocity.bitPattern
        value.slide_velocity_x_bits = result.slideVelocityX.bitPattern
        value.slide_velocity_z_bits = result.slideVelocityZ.bitPattern
        value.velocity_x_bits = result.velocity.x.bitPattern
        value.velocity_y_bits = result.velocity.y.bitPattern
        value.velocity_z_bits = result.velocity.z.bitPattern
        value.update_moving_sand = result.shouldUpdateMovingSand ? 1 : 0
        value.update_windy_ground = result.shouldUpdateWindyGround ? 1 : 0
        output.pointee = value
        marioSlidingUpdates += 1
        if marioSlidingUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_sliding")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioGroundDivePunch(
        input: SM64ModernMarioGroundDivePunchInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioGroundDivePunchOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard input.b_pressed <= 1,
              let result = SM64MarioGroundDivePunch.update(
                SM64MarioGroundDivePunchInput(
                    bPressed: input.b_pressed != 0,
                    forwardVelocity: Float(bitPattern: input.forward_velocity_bits),
                    stickMagnitude: Float(bitPattern: input.stick_magnitude_bits),
                    velocityY: Float(bitPattern: input.velocity_y_bits)
                )
              ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        var value = SM64ModernMarioGroundDivePunchOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioGroundDivePunchOutputV1>.size)
        value.triggered = result.triggered ? 1 : 0
        value.action = result.action
        value.action_argument = result.actionArgument
        value.velocity_y_bits = result.velocityY.bitPattern
        output.pointee = value
        marioGroundDivePunchUpdates += 1
        if marioGroundDivePunchUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_ground_dive_punch")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioSlidePredicates(
        input: SM64ModernMarioSlidePredicatesInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioSlidePredicatesOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard input.terrain_is_slide <= 1,
              input.facing_downhill <= 1,
              let result = SM64MarioSlidePredicates.update(
                SM64MarioSlidePredicatesInput(
                    input: SM64MarioInputFlags(
                        rawValue: UInt16(truncatingIfNeeded: input.input)
                    ),
                    terrainIsSlide: input.terrain_is_slide != 0,
                    forwardVelocity: Float(bitPattern: input.forward_velocity_bits),
                    facingDownhill: input.facing_downhill != 0,
                    intendedYaw: Int16(truncatingIfNeeded: input.intended_yaw),
                    faceYaw: Int16(truncatingIfNeeded: input.face_yaw)
                )
              ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        var value = SM64ModernMarioSlidePredicatesOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioSlidePredicatesOutputV1>.size)
        value.should_begin_sliding = result.shouldBeginSliding ? 1 : 0
        value.analog_stick_held_back = result.analogStickHeldBack ? 1 : 0
        output.pointee = value
        marioSlidePredicatesUpdates += 1
        if marioSlidePredicatesUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_slide_predicates")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioBeginBraking(
        input: SM64ModernMarioBeginBrakingInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioBeginBrakingOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard let result = SM64MarioBeginBraking.update(
            SM64MarioBeginBrakingInput(
                actionState: UInt16(truncatingIfNeeded: input.action_state),
                actionArgument: input.action_argument,
                forwardVelocity: Float(bitPattern: input.forward_velocity_bits),
                floorNormalY: Float(bitPattern: input.floor_normal_y_bits),
                faceYaw: Int16(truncatingIfNeeded: input.face_yaw)
            )
        ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        var value = SM64ModernMarioBeginBrakingOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioBeginBrakingOutputV1>.size)
        value.action = result.action
        value.action_argument = result.actionArgument
        value.face_yaw = Int32(result.faceYaw)
        value.intent = UInt32(result.intent.rawValue)
        output.pointee = value
        marioBeginBrakingUpdates += 1
        if marioBeginBrakingUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_begin_braking")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioTripleJumpSelector(
        input: SM64ModernMarioTripleJumpSelectorInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioTripleJumpSelectorOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard let result = SM64MarioTripleJumpSelector.update(
            SM64MarioTripleJumpSelectorInput(
                marioFlags: input.mario_flags,
                forwardVelocity: Float(bitPattern: input.forward_velocity_bits)
            )
        ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        var value = SM64ModernMarioTripleJumpSelectorOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioTripleJumpSelectorOutputV1>.size)
        value.action = result.action
        value.action_argument = result.actionArgument
        value.intent = UInt32(result.intent.rawValue)
        output.pointee = value
        marioTripleJumpSelectorUpdates += 1
        if marioTripleJumpSelectorUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_triple_jump_selector")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioYVelocity(
        input: SM64ModernMarioYVelocityInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioYVelocityOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard input.squish_timer <= 1,
              let result = SM64MarioYVelocity.update(
                SM64MarioYVelocityInput(
                    initialVelocityY: Float(bitPattern: input.initial_velocity_y_bits),
                    forwardVelocity: Float(bitPattern: input.forward_velocity_bits),
                    multiplier: Float(bitPattern: input.multiplier_bits),
                    squishTimer: input.squish_timer != 0,
                    quicksandDepth: Float(bitPattern: input.quicksand_depth_bits)
                )
              ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        var value = SM64ModernMarioYVelocityOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioYVelocityOutputV1>.size)
        value.velocity_y_bits = result.velocityY.bitPattern
        value.half_speed_applied = result.halfSpeedApplied ? 1 : 0
        output.pointee = value
        marioYVelocityUpdates += 1
        if marioYVelocityUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_y_velocity")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateMarioSteepJump(
        input: SM64ModernMarioSteepJumpInputV1,
        output: UnsafeMutablePointer<SM64ModernMarioSteepJumpOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard input.face_yaw >= Int32(Int16.min), input.face_yaw <= Int32(Int16.max),
              input.floor_angle >= Int32(Int16.min), input.floor_angle <= Int32(Int16.max),
              let result = SM64MarioSteepJump.update(
                SM64MarioSteepJumpInput(
                    faceYaw: Int16(truncatingIfNeeded: input.face_yaw),
                    floorAngle: Int16(truncatingIfNeeded: input.floor_angle),
                    forwardVelocity: Float(bitPattern: input.forward_velocity_bits)
                )
              ) else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT
        }
        var value = SM64ModernMarioSteepJumpOutputV1()
        value.header.abi_version = SM64_MODERN_ABI_VERSION_1
        value.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioSteepJumpOutputV1>.size)
        value.action = result.action
        value.steep_jump_yaw = Int32(result.steepJumpYaw)
        value.forward_velocity_bits = result.forwardVelocity.bitPattern
        value.face_yaw = Int32(result.faceYaw)
        value.should_drop_held_object = result.shouldDropHeldObject ? 1 : 0
        output.pointee = value
        marioSteepJumpUpdates += 1
        if marioSteepJumpUpdates == 1 {
            swiftGameplayLogger.notice("swift_gameplay_slice_exercised slice=mario_steep_jump")
        }
        return SM64_MODERN_STATUS_OK
    }

    fileprivate func updateBobombRelease(
        input: SM64ModernBobombReleaseInputV1,
        output: UnsafeMutablePointer<SM64ModernBobombReleaseOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
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
        assertOwnerThread()
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
            if let marioActionCandidate, marioActionCandidate.tick == tick {
                switch actual.record_id {
                case UInt32(SM64_MODERN_FIELD_MARIO_ACTION):
                    candidate.values.0 = UInt64(marioActionCandidate.output.action)
                case UInt32(SM64_MODERN_FIELD_MARIO_PREVIOUS_ACTION):
                    candidate.values.0 = UInt64(marioActionCandidate.output.previous_action)
                case UInt32(SM64_MODERN_FIELD_MARIO_ACTION_STATE):
                    candidate.values.0 = UInt64(marioActionCandidate.output.action_state)
                case UInt32(SM64_MODERN_FIELD_MARIO_ACTION_TIMER):
                    candidate.values.0 = UInt64(marioActionCandidate.output.action_timer)
                case UInt32(SM64_MODERN_FIELD_MARIO_ACTION_ARGUMENT):
                    candidate.values.0 = UInt64(marioActionCandidate.output.action_argument)
                case UInt32(SM64_MODERN_FIELD_MARIO_FLAGS):
                    candidate.values.0 = UInt64(marioActionCandidate.output.flags)
                case UInt32(SM64_MODERN_FIELD_MARIO_FORWARD_VELOCITY):
                    candidate.values.0 = UInt64(marioActionCandidate.output.forward_velocity_bits)
                case UInt32(SM64_MODERN_FIELD_MARIO_FACE_ANGLE):
                    candidate.values.0 = UInt64(UInt16(truncatingIfNeeded: marioActionCandidate.output.face_pitch))
                    candidate.values.1 = UInt64(UInt16(truncatingIfNeeded: marioActionCandidate.output.face_yaw))
                    candidate.values.2 = UInt64(UInt16(truncatingIfNeeded: marioActionCandidate.output.face_roll))
                case UInt32(SM64_MODERN_FIELD_MARIO_VELOCITY):
                    candidate.values.0 = UInt64(marioActionCandidate.output.velocity_x_bits)
                    candidate.values.1 = UInt64(marioActionCandidate.output.velocity_y_bits)
                    candidate.values.2 = UInt64(marioActionCandidate.output.velocity_z_bits)
                default:
                    break
                }
            }
            if let marioGroundStepCandidate, marioGroundStepCandidate.tick == tick,
               actual.record_id == UInt32(SM64_MODERN_FIELD_MARIO_POSITION) {
                candidate.values.0 = UInt64(marioGroundStepCandidate.output.position_x_bits)
                candidate.values.1 = UInt64(marioGroundStepCandidate.output.position_y_bits)
                candidate.values.2 = UInt64(marioGroundStepCandidate.output.position_z_bits)
            }
            if let marioAirStepCandidate, marioAirStepCandidate.tick == tick {
                switch actual.record_id {
                case UInt32(SM64_MODERN_FIELD_MARIO_POSITION):
                    candidate.values.0 = UInt64(marioAirStepCandidate.output.position_x_bits)
                    candidate.values.1 = UInt64(marioAirStepCandidate.output.position_y_bits)
                    candidate.values.2 = UInt64(marioAirStepCandidate.output.position_z_bits)
                case UInt32(SM64_MODERN_FIELD_MARIO_VELOCITY):
                    candidate.values.1 = UInt64(marioAirStepCandidate.output.velocity_y_bits)
                case UInt32(SM64_MODERN_FIELD_MARIO_FACE_ANGLE):
                    candidate.values.0 = UInt64(UInt16(truncatingIfNeeded: marioAirStepCandidate.output.face_pitch))
                    candidate.values.1 = UInt64(UInt16(truncatingIfNeeded: marioAirStepCandidate.output.face_yaw))
                    candidate.values.2 = UInt64(UInt16(truncatingIfNeeded: marioAirStepCandidate.output.face_roll))
                case UInt32(SM64_MODERN_FIELD_MARIO_FLAGS):
                    candidate.values.0 |= UInt64(marioAirStepCandidate.output.flags_or)
                default:
                    break
                }
            }
            if let marioWaterStepCandidate, marioWaterStepCandidate.tick == tick,
               actual.record_id == UInt32(SM64_MODERN_FIELD_MARIO_POSITION) {
                candidate.values.0 = UInt64(marioWaterStepCandidate.output.position_x_bits)
                candidate.values.1 = UInt64(marioWaterStepCandidate.output.position_y_bits)
                candidate.values.2 = UInt64(marioWaterStepCandidate.output.position_z_bits)
            }
            if let marioBonkCandidate, marioBonkCandidate.tick == tick {
                switch actual.record_id {
                case UInt32(SM64_MODERN_FIELD_MARIO_FACE_ANGLE):
                    candidate.values.1 = UInt64(UInt16(truncatingIfNeeded: marioBonkCandidate.output.face_yaw))
                case UInt32(SM64_MODERN_FIELD_MARIO_FORWARD_VELOCITY):
                    candidate.values.0 = UInt64(marioBonkCandidate.output.forward_velocity_bits)
                case UInt32(SM64_MODERN_FIELD_MARIO_VELOCITY):
                    candidate.values.0 = UInt64(marioBonkCandidate.output.velocity_x_bits)
                    candidate.values.2 = UInt64(marioBonkCandidate.output.velocity_z_bits)
                default:
                    break
                }
            }
            if let marioTerrainImpulseCandidate, marioTerrainImpulseCandidate.tick == tick,
               actual.record_id == UInt32(SM64_MODERN_FIELD_MARIO_VELOCITY) {
                candidate.values.0 = UInt64(marioTerrainImpulseCandidate.output.velocity_x_bits)
                candidate.values.2 = UInt64(marioTerrainImpulseCandidate.output.velocity_z_bits)
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
        marioActionCandidate = nil
        marioGroundStepCandidate = nil
        marioAirStepCandidate = nil
        marioWaterStepCandidate = nil
        marioBonkCandidate = nil
        marioTerrainImpulseCandidate = nil
        bobombCandidates.removeAll(keepingCapacity: true)
    }

    private func assertOwnerThread(bindIfMissing: Bool = false) {
        let current = Self.currentThreadIdentity()
        if let ownerThreadIdentity {
            precondition(
                current == ownerThreadIdentity,
                "Swift gameplay migration must run on its owner thread"
            )
        } else {
            precondition(
                bindIfMissing,
                "Swift gameplay migration owner thread is not bound"
            )
            ownerThreadIdentity = current
        }
    }

    private static func currentThreadIdentity() -> UInt64 {
        var identifier: UInt64 = 0
        let result = pthread_threadid_np(nil, &identifier)
        precondition(result == 0, "pthread_threadid_np must produce an owner token")
        return identifier
    }

    private static func supportedMarioAction(_ action: UInt32) -> Bool {
        switch action {
        case SM64MarioActionID.walking,
             SM64MarioActionID.holdWalking,
             SM64MarioActionID.beginSliding,
             SM64MarioActionID.holdBeginSliding,
             SM64MarioActionID.doubleJump,
             SM64MarioActionID.backflip,
             SM64MarioActionID.tripleJump,
             SM64MarioActionID.flyingTripleJump,
             SM64MarioActionID.waterJump,
             SM64MarioActionID.holdWaterJump,
             SM64MarioActionID.jump,
             SM64MarioActionID.holdJump,
             SM64MarioActionID.wallKickAir,
             SM64MarioActionID.sideFlip,
             SM64MarioActionID.steepJump,
             SM64MarioActionID.lavaBoost,
             SM64MarioActionID.longJump,
             SM64MarioActionID.slideKick,
             SM64MarioActionID.jumpKick,
             SM64MarioActionID.metalWaterJump,
             SM64MarioActionID.emergeFromPipe,
             SM64MarioActionID.specialExitAirborne,
             SM64MarioActionID.specialDeathExit:
            true
        default:
            false
        }
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

func makeSwiftMarioActionAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioActionApiV1 {
    var api = SM64ModernMarioActionApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioActionApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioActionUpdate
    return api
}

func makeSwiftMarioActionCancelAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioActionCancelApiV1 {
    var api = SM64ModernMarioActionCancelApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioActionCancelApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioActionCancelUpdate
    return api
}

func makeSwiftMarioGroundStepAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioGroundStepApiV1 {
    var api = SM64ModernMarioGroundStepApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioGroundStepApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioGroundStepUpdate
    return api
}

func makeSwiftMarioAirStepAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioAirStepApiV1 {
    var api = SM64ModernMarioAirStepApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioAirStepApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioAirStepUpdate
    return api
}

func makeSwiftMarioWaterStepAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioWaterStepApiV1 {
    var api = SM64ModernMarioWaterStepApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioWaterStepApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioWaterStepUpdate
    return api
}

func makeSwiftMarioBonkAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioBonkApiV1 {
    var api = SM64ModernMarioBonkApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioBonkApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioBonkUpdate
    return api
}

func makeSwiftMarioTerrainImpulseAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioTerrainImpulseApiV1 {
    var api = SM64ModernMarioTerrainImpulseApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioTerrainImpulseApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioTerrainImpulseUpdate
    return api
}

func makeSwiftMarioQuicksandAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioQuicksandApiV1 {
    var api = SM64ModernMarioQuicksandApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioQuicksandApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioQuicksandUpdate
    return api
}

func makeSwiftMarioSteepPushAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioSteepPushApiV1 {
    var api = SM64ModernMarioSteepPushApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioSteepPushApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioSteepPushUpdate
    return api
}

func makeSwiftMarioTerrainSoundAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioTerrainSoundApiV1 {
    var api = SM64ModernMarioTerrainSoundApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioTerrainSoundApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioTerrainSoundUpdate
    return api
}

func makeSwiftMarioFloorPredicatesAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioFloorPredicatesApiV1 {
    var api = SM64ModernMarioFloorPredicatesApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioFloorPredicatesApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioFloorPredicatesUpdate
    return api
}

func makeSwiftMarioForwardVelocityAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioForwardVelocityApiV1 {
    var api = SM64ModernMarioForwardVelocityApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioForwardVelocityApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioForwardVelocityUpdate
    return api
}

func makeSwiftMarioVelocityDerivationAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioVelocityDerivationApiV1 {
    var api = SM64ModernMarioVelocityDerivationApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioVelocityDerivationApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioVelocityDerivationUpdate
    return api
}

func makeSwiftMarioPunchAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioPunchApiV1 {
    var api = SM64ModernMarioPunchApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioPunchApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioPunchUpdate
    return api
}

func makeSwiftMarioWallResponseAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioWallResponseApiV1 {
    var api = SM64ModernMarioWallResponseApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioWallResponseApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioWallResponseUpdate
    return api
}

func makeSwiftMarioWalkAnimationAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioWalkAnimationApiV1 {
    var api = SM64ModernMarioWalkAnimationApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioWalkAnimationApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioWalkAnimationUpdate
    return api
}

func makeSwiftMarioHeldWalkAnimationAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioHeldWalkAnimationApiV1 {
    var api = SM64ModernMarioHeldWalkAnimationApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioHeldWalkAnimationApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioHeldWalkAnimationUpdate
    return api
}

func makeSwiftMarioSlopeAccelerationAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioSlopeAccelerationApiV1 {
    var api = SM64ModernMarioSlopeAccelerationApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioSlopeAccelerationApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioSlopeAccelerationUpdate
    return api
}

func makeSwiftMarioSlopeDecelerationAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioSlopeDecelerationApiV1 {
    var api = SM64ModernMarioSlopeDecelerationApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioSlopeDecelerationApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioSlopeDecelerationUpdate
    return api
}

func makeSwiftMarioDeceleratingSpeedAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioDeceleratingSpeedApiV1 {
    var api = SM64ModernMarioDeceleratingSpeedApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioDeceleratingSpeedApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioDeceleratingSpeedUpdate
    return api
}

func makeSwiftMarioShellSpeedAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioShellSpeedApiV1 {
    var api = SM64ModernMarioShellSpeedApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioShellSpeedApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioShellSpeedUpdate
    return api
}

func makeSwiftMarioLandingAccelerationAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioLandingAccelerationApiV1 {
    var api = SM64ModernMarioLandingAccelerationApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioLandingAccelerationApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioLandingAccelerationUpdate
    return api
}

func makeSwiftMarioGravityAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioGravityApiV1 {
    var api = SM64ModernMarioGravityApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioGravityApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioGravityUpdate
    return api
}

func makeSwiftMarioVerticalWindAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioVerticalWindApiV1 {
    var api = SM64ModernMarioVerticalWindApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioVerticalWindApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioVerticalWindUpdate
    return api
}

func makeSwiftMarioSlidingAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioSlidingApiV1 {
    var api = SM64ModernMarioSlidingApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioSlidingApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioSlidingUpdate
    return api
}

func makeSwiftMarioGroundDivePunchAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioGroundDivePunchApiV1 {
    var api = SM64ModernMarioGroundDivePunchApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioGroundDivePunchApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioGroundDivePunchUpdate
    return api
}

func makeSwiftMarioSlidePredicatesAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioSlidePredicatesApiV1 {
    var api = SM64ModernMarioSlidePredicatesApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioSlidePredicatesApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioSlidePredicatesUpdate
    return api
}

func makeSwiftMarioBeginBrakingAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioBeginBrakingApiV1 {
    var api = SM64ModernMarioBeginBrakingApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioBeginBrakingApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioBeginBrakingUpdate
    return api
}

func makeSwiftMarioTripleJumpSelectorAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioTripleJumpSelectorApiV1 {
    var api = SM64ModernMarioTripleJumpSelectorApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioTripleJumpSelectorApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioTripleJumpSelectorUpdate
    return api
}

func makeSwiftMarioYVelocityAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioYVelocityApiV1 {
    var api = SM64ModernMarioYVelocityApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioYVelocityApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioYVelocityUpdate
    return api
}

func makeSwiftMarioSteepJumpAPI(
    service: SwiftGameplayService
) -> SM64ModernMarioSteepJumpApiV1 {
    var api = SM64ModernMarioSteepJumpApiV1()
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1
    api.header.struct_size = UInt32(MemoryLayout<SM64ModernMarioSteepJumpApiV1>.size)
    api.context = Unmanaged.passUnretained(service).toOpaque()
    api.update = swiftMarioSteepJumpUpdate
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
