import Foundation

struct SM64MarioFaceComposedChannel: Equatable, Sendable {
    let componentID: UInt32
    let bank: UInt32
    let available: Bool
    let transformType: UInt32
    let currentSourceFrame: UInt32
    let nextSourceFrame: UInt32
    let fractionQ16: UInt32
    let values: [Float]
}

struct SM64MarioFaceExpressionCompositionPacket: Equatable, Sendable {
    let face: SM64MarioFaceRenderPacket
    let animationBank: UInt32
    let animationFrameQ16: UInt32
    let eyeOverrideState: UInt32
    let eyeOverrideSource: UInt32
    let channelMask: UInt64
    let residentChannelCount: UInt32
    let unavailableChannelCount: UInt32
    let channels: [SM64MarioFaceComposedChannel]
}

/// Composes every catalog channel from the immutable M30i resource provider.
/// The order is the source manifest order, and missing/empty/invalid banks
/// remain explicit unavailable channels rather than zero-valued transforms.
enum SM64MarioFaceExpressionComposition {
    static let channelCount = SM64MarioFaceAnimationResourceManifest.entries.count

    static func compose(
        input: SM64MarioFaceExpressionInput,
        bundle: SM64MarioFacePayloadBundle
    ) -> SM64MarioFaceExpressionCompositionPacket {
        let base = SM64MarioFaceExpression.resolve(input)
        var channels: [SM64MarioFaceComposedChannel] = []
        channels.reserveCapacity(channelCount)
        var channelMask: UInt64 = 0
        var residentCount: UInt32 = 0

        for (index, entry) in SM64MarioFaceAnimationResourceManifest.entries.enumerated() {
            let decoded = bundle.decode(
                componentID: entry.componentID,
                bank: input.animationBank,
                frameQ16: input.animationFrameQ16
            )
            if let decoded {
                channelMask |= UInt64(1) << UInt64(index)
                residentCount += 1
                channels.append(.init(
                    componentID: entry.componentID,
                    bank: input.animationBank,
                    available: true,
                    transformType: decoded.type.rawValue,
                    currentSourceFrame: decoded.currentSourceFrame,
                    nextSourceFrame: decoded.nextSourceFrame,
                    fractionQ16: decoded.fractionQ16,
                    values: decoded.values
                ))
            } else {
                channels.append(.init(
                    componentID: entry.componentID,
                    bank: input.animationBank,
                    available: false,
                    transformType: 0,
                    currentSourceFrame: 0,
                    nextSourceFrame: 0,
                    fractionQ16: input.animationFrameQ16 & 0xFFFF,
                    values: []
                ))
            }
        }

        return .init(
            face: base.face,
            animationBank: input.animationBank,
            animationFrameQ16: input.animationFrameQ16,
            eyeOverrideState: base.eyeOverrideState,
            eyeOverrideSource: base.eyeOverrideSource,
            channelMask: channelMask,
            residentChannelCount: residentCount,
            unavailableChannelCount: UInt32(channelCount) - residentCount,
            channels: channels
        )
    }
}

enum SM64MarioFaceExpressionCompositionFingerprint {
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

    static let seed: UInt64 = {
        var result = offset
        result = hash(result, UInt64(SM64MarioFaceExpressionComposition.channelCount))
        for entry in SM64MarioFaceAnimationResourceManifest.entries {
            result = hash(result, UInt64(entry.componentID))
        }
        return result
    }()

    static func packet(
        _ initial: UInt64,
        _ packet: SM64MarioFaceExpressionCompositionPacket
    ) -> UInt64 {
        var result = initial
        for value in [
            packet.animationBank,
            packet.animationFrameQ16,
            UInt32(truncatingIfNeeded: packet.channelMask),
            UInt32(truncatingIfNeeded: packet.channelMask >> 32),
            packet.residentChannelCount,
            packet.unavailableChannelCount,
        ] {
            result = hash(result, UInt64(value))
        }
        for channel in packet.channels {
            for value in [
                channel.componentID,
                channel.bank,
                channel.available ? 1 : 0,
                channel.transformType,
                channel.currentSourceFrame,
                channel.nextSourceFrame,
                channel.fractionQ16,
                UInt32(channel.values.count),
            ] {
                result = hash(result, UInt64(value))
            }
            for value in channel.values {
                result = hash(result, UInt64(value.bitPattern))
            }
        }
        return result
    }
}
