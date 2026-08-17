import Foundation

struct SM64MarioFaceExpressionInput: Equatable, Sendable {
    let face: SM64MarioFaceInput
    let animationBank: UInt32
    let animationFrameQ16: UInt32
    let peachKissTimeline: Bool
    let actionTimer: UInt32
}

struct SM64MarioFaceExpressionPacket: Equatable, Sendable {
    let face: SM64MarioFaceRenderPacket
    let animationBank: UInt32
    let animationFrameQ16: UInt32
    let eyeOverrideState: UInt32
    let eyeOverrideSource: UInt32
    let payloadWindowMask: UInt32
    let decodedPayloadWindowCount: UInt32
    let unavailableCatalogChannelCount: UInt32
}

/// Bounded owner-thread-ready expression packet. It composes the already
/// qualified geo-switch state with explicit cutscene eye overrides and reports
/// payload residency without mutating Goddard graph objects or Metal state.
enum SM64MarioFaceExpression {
    static let payloadWindowCount: UInt32 = UInt32(SM64MarioFaceAnimationPayload.windows.count)
    static let catalogChannelCount: UInt32 = UInt32(SM64MarioFaceAnimationTimeline.catalog.count)

    static func resolve(_ input: SM64MarioFaceExpressionInput) -> SM64MarioFaceExpressionPacket {
        let timeline = SM64MarioFaceAnimationTimeline.eyeTimelineSample(
            actionTimer: input.actionTimer,
            peachKiss: input.peachKissTimeline
        )
        let effectiveFaceInput: SM64MarioFaceInput
        if timeline.hasOverride {
            effectiveFaceInput = SM64MarioFaceInput(
                bodyIndex: input.face.bodyIndex,
                areaUpdateCounter: input.face.areaUpdateCounter,
                eyeState: timeline.eyeState,
                action: input.face.action,
                handState: input.face.handState,
                handSwitchCaseCount: input.face.handSwitchCaseCount,
                capState: input.face.capState,
                modelState: input.face.modelState
            )
        } else {
            effectiveFaceInput = input.face
        }

        var payloadWindowMask: UInt32 = 0
        for (index, window) in SM64MarioFaceAnimationPayload.windows.enumerated() {
            if SM64MarioFaceAnimationPayload.decode(
                componentID: window.componentID,
                bank: input.animationBank,
                frameQ16: input.animationFrameQ16
            ) != nil {
                payloadWindowMask |= UInt32(1) << UInt32(index)
            }
        }
        let decodedCount = UInt32(payloadWindowMask.nonzeroBitCount)
        return SM64MarioFaceExpressionPacket(
            face: SM64MarioFace.resolve(effectiveFaceInput),
            animationBank: input.animationBank,
            animationFrameQ16: input.animationFrameQ16,
            eyeOverrideState: timeline.eyeState,
            eyeOverrideSource: timeline.source,
            payloadWindowMask: payloadWindowMask,
            decodedPayloadWindowCount: decodedCount,
            unavailableCatalogChannelCount: catalogChannelCount - decodedCount
        )
    }
}

enum SM64MarioFaceExpressionFingerprint {
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

    static let payloadSelectionSeed: UInt64 = {
        var result = offset
        for value in [UInt32(7), 0x07, 0x20, 0x42, 0xCF, 0xE2, 0xE5, 0xE8] {
            result = hash(result, UInt64(value))
        }
        return result
    }()

    static func packet(_ initial: UInt64, _ packet: SM64MarioFaceExpressionPacket) -> UInt64 {
        var result = initial
        for value in [
            packet.face.blinkFrame, packet.face.eyeCase, packet.face.handCase,
            packet.face.standRunCase, packet.face.capEffectCase, packet.face.capOnOffCase,
            packet.face.wingActive, packet.face.alpha, packet.face.materialMode,
            packet.animationBank, packet.animationFrameQ16, packet.eyeOverrideState,
            packet.eyeOverrideSource, packet.payloadWindowMask,
            packet.decodedPayloadWindowCount, packet.unavailableCatalogChannelCount,
        ] {
            result = hash(result, UInt64(value))
        }
        return result
    }
}
