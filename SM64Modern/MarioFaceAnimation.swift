import Foundation

enum SM64MarioFaceAnimationType: UInt32, Sendable {
    case empty = 0
    case matrix = 1
    case triangleF2 = 2
    case nineHalf = 3
    case triangleF4 = 4
    case stub = 5
    case threeHScaled = 6
    case threeH = 7
    case sixHScaled = 8
    case matrixVector = 9
    case camera = 11
}

/// A pointer-free copy of one `AnimDataInfo` pair from the Goddard Mario
/// master dynlist. The source has a third negative-count sentinel; the
/// sentinel is represented by the catalog itself rather than a fake channel.
struct SM64MarioFaceAnimationChannel: Equatable, Sendable {
    let componentID: UInt32
    let animatorID: UInt32
    let primaryCount: UInt32
    let primaryType: SM64MarioFaceAnimationType
    let secondaryCount: UInt32
    let secondaryType: SM64MarioFaceAnimationType
}

struct SM64MarioFaceAnimationSample: Equatable, Sendable {
    let componentID: UInt32
    let bank: UInt32
    let sourceFrame: Int32
    let normalizedFrame: UInt32
    let currentIndex: UInt32
    let nextIndex: UInt32
    let interpolationQ16: UInt32
    let count: UInt32
    let type: SM64MarioFaceAnimationType
}

struct SM64MarioFaceEyeTimelineSample: Equatable, Sendable {
    let actionTimer: UInt32
    let hasOverride: Bool
    let eyeState: UInt32
    let source: UInt32
}

/// Swift 6 value model for the copied Goddard face animation table and the
/// explicit cutscene eye overrides. It deliberately stops before the actual
/// halfword animation payloads and graph-node mutation; those remain a later
/// resource/renderer milestone.
enum SM64MarioFaceAnimationTimeline {
    static let catalog: [SM64MarioFaceAnimationChannel] = [
        .init(componentID: 0x07, animatorID: 0x08, primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled),
        .init(componentID: 0x10, animatorID: 0x11, primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled),
        .init(componentID: 0x20, animatorID: 0x21, primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled),
        .init(componentID: 0x29, animatorID: 0x2A, primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled),
        .init(componentID: 0x32, animatorID: 0x33, primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled),
        .init(componentID: 0x3F, animatorID: 0x40, primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 0, secondaryType: .empty),
        .init(componentID: 0x42, animatorID: 0x43, primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled),
        .init(componentID: 0x48, animatorID: 0x49, primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 0, secondaryType: .empty),
        .init(componentID: 0x4B, animatorID: 0x4C, primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled),
        .init(componentID: 0x54, animatorID: 0x55, primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 0, secondaryType: .empty),
        .init(componentID: 0x6B, animatorID: 0x6C, primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled),
        .init(componentID: 0x7B, animatorID: 0x7C, primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled),
        .init(componentID: 0x84, animatorID: 0x85, primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled),
        .init(componentID: 0x96, animatorID: 0x97, primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled),
        .init(componentID: 0x9F, animatorID: 0xA0, primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled),
        .init(componentID: 0xA8, animatorID: 0xA9, primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 0, secondaryType: .empty),
        .init(componentID: 0xB1, animatorID: 0xB2, primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 0, secondaryType: .empty),
        .init(componentID: 0xBA, animatorID: 0xBB, primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled),
        .init(componentID: 0xC3, animatorID: 0xC4, primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled),
        .init(componentID: 0xC6, animatorID: 0xC7, primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled),
        .init(componentID: 0xCF, animatorID: 0xD0, primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled),
        .init(componentID: 0xD8, animatorID: 0xD9, primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled),
        .init(componentID: 0xE2, animatorID: 0xE3, primaryCount: 820, primaryType: .sixHScaled, secondaryCount: 166, secondaryType: .sixHScaled),
        .init(componentID: 0xE5, animatorID: 0xE6, primaryCount: 820, primaryType: .sixHScaled, secondaryCount: 166, secondaryType: .sixHScaled),
        .init(componentID: 0xE8, animatorID: 0xE9, primaryCount: 820, primaryType: .sixHScaled, secondaryCount: 166, secondaryType: .sixHScaled),
    ]

    // MARIO_EYES_HALF_CLOSED, CLOSED, OPEN, and the source's 75/76 edges are
    // intentionally represented with the raw body-state values from the C
    // enum mirrored by SM64MarioFaceEyeState.
    static let peachKissBlinkOverride: [UInt32] = [
        SM64MarioFaceEyeState.halfClosed.rawValue, SM64MarioFaceEyeState.halfClosed.rawValue,
        SM64MarioFaceEyeState.closed.rawValue, SM64MarioFaceEyeState.closed.rawValue,
        SM64MarioFaceEyeState.halfClosed.rawValue, SM64MarioFaceEyeState.halfClosed.rawValue,
        SM64MarioFaceEyeState.open.rawValue, SM64MarioFaceEyeState.open.rawValue,
        SM64MarioFaceEyeState.halfClosed.rawValue, SM64MarioFaceEyeState.halfClosed.rawValue,
        SM64MarioFaceEyeState.closed.rawValue, SM64MarioFaceEyeState.closed.rawValue,
        SM64MarioFaceEyeState.halfClosed.rawValue, SM64MarioFaceEyeState.halfClosed.rawValue,
        SM64MarioFaceEyeState.open.rawValue, SM64MarioFaceEyeState.open.rawValue,
        SM64MarioFaceEyeState.halfClosed.rawValue, SM64MarioFaceEyeState.halfClosed.rawValue,
        SM64MarioFaceEyeState.closed.rawValue, SM64MarioFaceEyeState.closed.rawValue,
    ]

    static func channel(componentID: UInt32) -> SM64MarioFaceAnimationChannel? {
        catalog.first { $0.componentID == componentID }
    }

    /// Mirrors the integer boundary of `move_animator`: frame 1 addresses
    /// element 0, the last frame interpolates to element 0, an overrun wraps
    /// to frame 1, and a negative frame wraps to the bank's last frame. Frame 0
    /// is rejected because the original's one-based animator would address
    /// before the allocated array.
    static func sample(componentID: UInt32, bank: UInt32, frame: Int32) -> SM64MarioFaceAnimationSample? {
        guard let channel = channel(componentID: componentID) else { return nil }
        let count: UInt32
        let type: SM64MarioFaceAnimationType
        switch bank {
        case 0:
            count = channel.primaryCount
            type = channel.primaryType
        case 1:
            count = channel.secondaryCount
            type = channel.secondaryType
        default:
            return nil
        }
        guard count > 0, type != .empty else { return nil }

        let normalized: UInt32
        if frame > Int32(count) {
            normalized = 1
        } else if frame < 0 {
            normalized = count
        } else {
            normalized = UInt32(frame)
        }
        guard normalized > 0 else { return nil }
        return SM64MarioFaceAnimationSample(
            componentID: componentID,
            bank: bank,
            sourceFrame: frame,
            normalizedFrame: normalized,
            currentIndex: normalized - 1,
            nextIndex: normalized == count ? 0 : normalized,
            interpolationQ16: 0,
            count: count,
            type: type
        )
    }

    static func peachKissEyeState(actionTimer: UInt32) -> UInt32? {
        if actionTimer == 75 {
            return SM64MarioFaceEyeState.halfClosed.rawValue
        }
        if actionTimer == 76 {
            return SM64MarioFaceEyeState.closed.rawValue
        }
        guard actionTimer >= 90 else { return nil }
        if actionTimer < 110 {
            return peachKissBlinkOverride[Int(actionTimer - 90)]
        }
        return SM64MarioFaceEyeState.halfClosed.rawValue
    }

    static func creditsOpeningEyeState(actionTimer: UInt32) -> UInt32? {
        actionTimer < 52 ? SM64MarioFaceEyeState.halfClosed.rawValue : nil
    }

    static func eyeTimelineSample(actionTimer: UInt32, peachKiss: Bool) -> SM64MarioFaceEyeTimelineSample {
        let state = peachKiss
            ? peachKissEyeState(actionTimer: actionTimer)
            : creditsOpeningEyeState(actionTimer: actionTimer)
        return SM64MarioFaceEyeTimelineSample(
            actionTimer: actionTimer,
            hasOverride: state != nil,
            eyeState: state ?? 0xFFFF_FFFF,
            source: state == nil ? 0 : (peachKiss ? 1 : 2)
        )
    }
}

enum SM64MarioFaceAnimationFingerprint {
    static let offset: UInt64 = 1_469_598_103_934_665_603
    static let prime: UInt64 = 1_099_511_628_211

    private static func hash(_ initial: UInt64, _ value: UInt64) -> UInt64 {
        var result = initial
        for byte in 0..<8 {
            result ^= (value >> UInt64(byte * 8)) & 0xFF
            result &*= prime
        }
        return result
    }

    static func catalog(_ channels: [SM64MarioFaceAnimationChannel]) -> UInt64 {
        var result = hash(offset, UInt64(channels.count))
        for channel in channels {
            for value in [
                channel.componentID, channel.animatorID, channel.primaryCount,
                channel.primaryType.rawValue, channel.secondaryCount,
                channel.secondaryType.rawValue,
            ] {
                result = hash(result, UInt64(value))
            }
        }
        return result
    }

    static func sample(_ initial: UInt64, _ sample: SM64MarioFaceAnimationSample?) -> UInt64 {
        var result = hash(initial, sample == nil ? 0 : 1)
        guard let sample else { return result }
        for value in [
            sample.componentID, sample.bank, UInt32(bitPattern: sample.sourceFrame),
            sample.normalizedFrame, sample.currentIndex, sample.nextIndex,
            sample.interpolationQ16, sample.count, sample.type.rawValue,
        ] {
            result = hash(result, UInt64(value))
        }
        return result
    }

    static func eye(_ initial: UInt64, _ sample: SM64MarioFaceEyeTimelineSample) -> UInt64 {
        var result = hash(initial, UInt64(sample.actionTimer))
        result = hash(result, sample.hasOverride ? 1 : 0)
        result = hash(result, UInt64(sample.eyeState))
        return hash(result, UInt64(sample.source))
    }
}
