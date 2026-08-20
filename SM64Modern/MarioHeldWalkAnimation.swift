import Foundation

enum SM64MarioHeldWalkAnimationVariant: UInt8, Equatable, Sendable {
    case light = 0
    case heavy = 1
}

struct SM64MarioHeldWalkAnimationInput: Equatable, Sendable {
    let variant: SM64MarioHeldWalkAnimationVariant
    let intendedMagnitude: Float
    let forwardVelocity: Float
    let quicksandDepth: Float
    let actionTimer: UInt16
    let animationPastFrame1: Bool
    let animationPastFrame2: Bool
    let metalCap: Bool
}

struct SM64MarioHeldWalkAnimationResult: Equatable, Sendable {
    let animationID: UInt16
    let animationAcceleration: Int32
    let actionTimer: UInt16
    let sound: SM64MarioWalkSoundKind
    let soundFrame1: Int16
    let soundFrame2: Int16
}

/// Value counterpart of the two C held-object animation helpers. Animation
/// installation and step-sound delivery remain owner-thread effects.
enum SM64MarioHeldWalkAnimation {
    private static let slowWalkWithLightObject: UInt16 = 0x18
    private static let walkWithLightObject: UInt16 = 0x16
    private static let runWithLightObject: UInt16 = 0x17
    private static let walkWithHeavyObject: UInt16 = 0xBB

    static func update(
        _ input: SM64MarioHeldWalkAnimationInput
    ) -> SM64MarioHeldWalkAnimationResult? {
        guard input.intendedMagnitude.isFinite,
              input.forwardVelocity.isFinite,
              input.quicksandDepth.isFinite else { return nil }

        switch input.variant {
        case .light:
            var speed = max(input.intendedMagnitude, input.forwardVelocity)
            if speed < 2 { speed = 2 }
            var timer = input.actionTimer
            let animation: (UInt16, Float, UInt16, Int16, Int16)
            while true {
                switch timer {
                case 0:
                    if speed > 6 {
                        timer = 1
                    } else {
                        animation = (slowWalkWithLightObject, speed, timer, 12, 62)
                        return finish(input: input, animation: animation)
                    }
                case 1:
                    if speed < 3 {
                        timer = 0
                    } else if speed > 11 {
                        timer = 2
                    } else {
                        animation = (walkWithLightObject, speed, timer, 12, 62)
                        return finish(input: input, animation: animation)
                    }
                case 2:
                    if speed < 8 {
                        timer = 1
                    } else {
                        animation = (runWithLightObject, speed / 2, timer, 10, 49)
                        return finish(input: input, animation: animation)
                    }
                default:
                    return nil
                }
            }

        case .heavy:
            let speed = input.intendedMagnitude * 0.1
            return finish(
                input: input,
                animation: (walkWithHeavyObject, speed, input.actionTimer, 26, 79)
            )
        }
    }

    private static func finish(
        input: SM64MarioHeldWalkAnimationInput,
        animation: (UInt16, Float, UInt16, Int16, Int16)
    ) -> SM64MarioHeldWalkAnimationResult? {
        let (animationID, speed, timer, frame1, frame2) = animation
        let scaled = Double(speed) * 65_536
        guard scaled.isFinite,
              scaled >= Double(Int32.min),
              scaled <= Double(Int32.max) else { return nil }

        let sound: SM64MarioWalkSoundKind
        if input.animationPastFrame1 || input.animationPastFrame2 {
            if input.metalCap {
                sound = .metal
            } else if input.quicksandDepth > 50 {
                sound = .quicksand
            } else {
                sound = .terrain
            }
        } else {
            sound = .none
        }
        return SM64MarioHeldWalkAnimationResult(
            animationID: animationID,
            animationAcceleration: Int32(scaled),
            actionTimer: timer,
            sound: sound,
            soundFrame1: frame1,
            soundFrame2: frame2
        )
    }
}
