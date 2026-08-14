import Foundation

enum SM64MarioWalkAnimationID {
    static let walking: UInt16 = 0x48
    static let running: UInt16 = 0x72
    static let tiptoe: UInt16 = 0x92
    static let startTiptoe: UInt16 = 0xCA
    static let moveInQuicksand: UInt16 = 0x78
}

enum SM64MarioWalkSoundKind: UInt8, Equatable, Sendable {
    case none = 0
    case terrain = 1
    case terrainTiptoe = 2
    case quicksand = 3
    case metal = 4
    case metalTiptoe = 5
}

struct SM64MarioWalkAnimationInput: Equatable, Sendable {
    let intendedMagnitude: Float
    let forwardVelocity: Float
    let quicksandDepth: Float
    let actionTimer: UInt16
    let animationPastFrame23: Bool
    let animationPastFrame1: Bool
    let animationPastFrame2: Bool
    let metalCap: Bool
    let walkingPitch: Int16
    let runningPitch: Int16
}

struct SM64MarioWalkAnimationResult: Equatable, Sendable {
    let animationID: UInt16
    let animationAcceleration: Int32
    let actionTimer: UInt16
    let walkingPitch: Int16
    let sound: SM64MarioWalkSoundKind
    let soundFrame1: Int16
    let soundFrame2: Int16
}

/// Value counterpart of `anim_and_audio_for_walk`. Animation playback and
/// audio delivery remain effects; this kernel emits their deterministic IDs,
/// acceleration, frame windows, and the eased walking pitch.
enum SM64MarioWalkAnimation {
    static func update(_ input: SM64MarioWalkAnimationInput) -> SM64MarioWalkAnimationResult? {
        guard input.intendedMagnitude.isFinite,
              input.forwardVelocity.isFinite,
              input.quicksandDepth.isFinite,
              input.actionTimer <= 3 else {
            return nil
        }

        var speed = max(input.intendedMagnitude, input.forwardVelocity)
        if speed < 4 { speed = 4 }

        var actionTimer = input.actionTimer
        var animationID: UInt16
        var animationAcceleration: Int32
        var frame1: Int16 = 0
        var frame2: Int16 = 0
        var targetPitch: Int32 = 0

        if input.quicksandDepth > 50 {
            animationID = SM64MarioWalkAnimationID.moveInQuicksand
            guard let acceleration = fixedAnimationAcceleration(speed / 4) else { return nil }
            animationAcceleration = acceleration
            frame1 = 19
            frame2 = 93
            actionTimer = 0
        } else {
            while true {
                switch actionTimer {
                case 0:
                    if speed > 8 {
                        actionTimer = 2
                    } else {
                        animationID = SM64MarioWalkAnimationID.startTiptoe
                        guard let raw = fixedAnimationAcceleration(speed / 4) else { return nil }
                        animationAcceleration = max(raw, 0x1000)
                        frame1 = 7
                        frame2 = 22
                        if input.animationPastFrame23 { actionTimer = 2 }
                        return finish(
                            input: input,
                            animationID: animationID,
                            animationAcceleration: animationAcceleration,
                            actionTimer: actionTimer,
                            targetPitch: targetPitch,
                            frame1: frame1,
                            frame2: frame2
                        )
                    }

                case 1:
                    if speed > 8 {
                        actionTimer = 2
                    } else {
                        animationID = SM64MarioWalkAnimationID.tiptoe
                        guard let raw = fixedAnimationAcceleration(speed) else { return nil }
                        animationAcceleration = max(raw, 0x1000)
                        frame1 = 14
                        frame2 = 72
                        return finish(
                            input: input,
                            animationID: animationID,
                            animationAcceleration: animationAcceleration,
                            actionTimer: actionTimer,
                            targetPitch: targetPitch,
                            frame1: frame1,
                            frame2: frame2
                        )
                    }

                case 2:
                    if speed < 5 {
                        actionTimer = 1
                    } else if speed > 22 {
                        actionTimer = 3
                    } else {
                        animationID = SM64MarioWalkAnimationID.walking
                        guard let raw = fixedAnimationAcceleration(speed / 4) else { return nil }
                        animationAcceleration = raw
                        frame1 = 10
                        frame2 = 49
                        return finish(
                            input: input,
                            animationID: animationID,
                            animationAcceleration: animationAcceleration,
                            actionTimer: actionTimer,
                            targetPitch: targetPitch,
                            frame1: frame1,
                            frame2: frame2
                        )
                    }

                case 3:
                    if speed < 18 {
                        actionTimer = 2
                    } else {
                        animationID = SM64MarioWalkAnimationID.running
                        guard let raw = fixedAnimationAcceleration(speed / 4) else { return nil }
                        animationAcceleration = raw
                        frame1 = 9
                        frame2 = 45
                        targetPitch = Int32(input.runningPitch)
                        return finish(
                            input: input,
                            animationID: animationID,
                            animationAcceleration: animationAcceleration,
                            actionTimer: actionTimer,
                            targetPitch: targetPitch,
                            frame1: frame1,
                            frame2: frame2
                        )
                    }

                default:
                    return nil
                }
            }
        }

        return finish(
            input: input,
            animationID: animationID,
            animationAcceleration: animationAcceleration,
            actionTimer: actionTimer,
            targetPitch: targetPitch,
            frame1: frame1,
            frame2: frame2
        )
    }

    private static func finish(
        input: SM64MarioWalkAnimationInput,
        animationID: UInt16,
        animationAcceleration: Int32,
        actionTimer: UInt16,
        targetPitch: Int32,
        frame1: Int16,
        frame2: Int16
    ) -> SM64MarioWalkAnimationResult {
        let sound: SM64MarioWalkSoundKind
        if input.animationPastFrame1 || input.animationPastFrame2 {
            if input.metalCap {
                sound = animationID == SM64MarioWalkAnimationID.tiptoe
                    ? .metalTiptoe
                    : .metal
            } else if input.quicksandDepth > 50 {
                sound = .quicksand
            } else {
                sound = animationID == SM64MarioWalkAnimationID.tiptoe
                    ? .terrainTiptoe
                    : .terrain
            }
        } else {
            sound = .none
        }

        let easedPitch = SM64DeterministicPrimitives.approachS32(
            current: Int32(input.walkingPitch),
            target: targetPitch,
            increment: 0x800,
            decrement: 0x800
        )
        return SM64MarioWalkAnimationResult(
            animationID: animationID,
            animationAcceleration: animationAcceleration,
            actionTimer: actionTimer,
            walkingPitch: Int16(truncatingIfNeeded: easedPitch),
            sound: sound,
            soundFrame1: frame1,
            soundFrame2: frame2
        )
    }

    private static func fixedAnimationAcceleration(_ value: Float) -> Int32? {
        guard value.isFinite else { return nil }
        let scaled = Double(value) * 65_536
        guard scaled >= Double(Int32.min), scaled <= Double(Int32.max) else { return nil }
        return Int32(scaled)
    }
}
