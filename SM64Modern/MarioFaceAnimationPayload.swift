import Foundation

enum SM64MarioFaceAnimationPayloadType: UInt32, Sendable {
    case threeHScaled = 6
    case sixHScaled = 8
}

struct SM64MarioFaceAnimationPayloadWindow: Equatable, Sendable {
    let componentID: UInt32
    let bank: UInt32
    let frameStart: UInt32
    let stride: UInt32
    let type: SM64MarioFaceAnimationPayloadType
    let rawValues: [Int16]

    var frameCount: UInt32 {
        stride == 0 ? 0 : UInt32(rawValues.count) / stride
    }

    /// Returns one source frame using the same one-based frame numbering as
    /// `move_animator`, but only within this deliberately bounded copied
    /// window. Missing frames fail closed instead of implying full residency.
    func frame(_ sourceFrame: UInt32) -> [Int16]? {
        guard sourceFrame >= frameStart,
              sourceFrame < frameStart &+ frameCount,
              stride > 0 else { return nil }
        let offset = Int(sourceFrame &- frameStart) * Int(stride)
        return Array(rawValues[offset..<(offset + Int(stride))])
    }
}

struct SM64MarioFaceAnimationDecodedFrame: Equatable, Sendable {
    let componentID: UInt32
    let bank: UInt32
    let frameQ16: UInt32
    let currentSourceFrame: UInt32
    let nextSourceFrame: UInt32
    let fractionQ16: UInt32
    let type: SM64MarioFaceAnimationPayloadType
    let values: [Float]
}

/// Source-backed raw windows copied from the checked-in Goddard dynlist
/// tables. These are not ROM-derived generated assets and intentionally cover
/// only a few frames per channel until the complete content-pack importer is
/// qualified.
enum SM64MarioFaceAnimationPayload {
    static let windows: [SM64MarioFaceAnimationPayloadWindow] = [
        // anim_mario_mustache_right_1[820][3], frames 1...5.
        .init(
            componentID: 0x07, bank: 0, frameStart: 1, stride: 3, type: .threeHScaled,
            rawValues: [
                0, 154, 1506, 0, 154, 1506, 0, 154, 1507,
                0, 154, 1508, 0, 154, 1510,
            ]
        ),
        // anim_mario_lips_1_1[820][3], frames 1...5.
        .init(
            componentID: 0x20, bank: 0, frameStart: 1, stride: 3, type: .threeHScaled,
            rawValues: [
                -80, -6, 1818, -80, -6, 1818, -80, -6, 1818,
                -80, -6, 1817, -80, -6, 1817,
            ]
        ),
        // anim_mario_eyebrows_2_1[820][3], frames 1...5.
        .init(
            componentID: 0x42, bank: 0, frameStart: 1, stride: 3, type: .threeHScaled,
            rawValues: [
                28, 0, 1823, 28, 0, 1823, 28, 0, 1823,
                27, 0, 1822, 26, 0, 1821,
            ]
        ),
        // anim_mario_eyelid_left_1[820][3], frames 1...5.
        .init(
            componentID: 0xCF, bank: 0, frameStart: 1, stride: 3, type: .threeHScaled,
            rawValues: [
                0, 0, 1620, 0, 0, 1619, 0, 0, 1617,
                0, 0, 1614, 0, 0, 1611,
            ]
        ),
        // anim_mario_intro_1[820][6], frames 1...4.
        .init(
            componentID: 0xE2, bank: 0, frameStart: 1, stride: 6, type: .sixHScaled,
            rawValues: [
                1128, 0, 0, 0, 0, -20010,
                1123, 0, 0, 0, -2, -19891,
                1108, 0, 0, 0, -7, -19548,
                1085, 0, 0, 0, -16, -19000,
            ]
        ),
        // anim_silver_star_1[820][6], frames 1...4.
        .init(
            componentID: 0xE5, bank: 0, frameStart: 1, stride: 6, type: .sixHScaled,
            rawValues: Array(repeating: [0, 0, 0, -1300, 1500, 2600], count: 4).flatMap { $0 }
        ),
        // anim_red_star_2[166][6], frames 1...4.
        .init(
            componentID: 0xE8, bank: 1, frameStart: 1, stride: 6, type: .sixHScaled,
            rawValues: [
                0, 0, 0, 4291, 2080, 2392,
                0, 0, 0, 4290, 2079, 2391,
                0, 0, 0, 4289, 2079, 2389,
                0, 0, 0, 4287, 2078, 2385,
            ]
        ),
    ]

    static func window(componentID: UInt32, bank: UInt32) -> SM64MarioFaceAnimationPayloadWindow? {
        windows.first { $0.componentID == componentID && $0.bank == bank }
    }

    /// Decodes a Q16.16 frame inside a copied window using the same linear
    /// interpolation and 0.1 scale used by `move_animator` for the source
    /// `GD_ANIM_*_SCALED` records. The next frame must also be resident in the
    /// bounded window; missing payload fails closed.
    static func decode(componentID: UInt32, bank: UInt32, frameQ16: UInt32) -> SM64MarioFaceAnimationDecodedFrame? {
        guard let window = window(componentID: componentID, bank: bank),
              window.frameCount > 1 else { return nil }
        let currentFrame = frameQ16 >> 16
        let fractionQ16 = frameQ16 & 0xFFFF
        guard currentFrame >= window.frameStart,
              currentFrame < window.frameStart &+ window.frameCount &- 1,
              let current = window.frame(currentFrame),
              let next = window.frame(currentFrame &+ 1) else { return nil }
        let fraction = Float(fractionQ16) / 65_536.0
        var values: [Float] = []
        values.reserveCapacity(current.count)
        for index in current.indices {
            let interpolated = Float(current[index]) + (Float(next[index]) - Float(current[index])) * fraction
            values.append(index < 3 ? interpolated * 0.1 : interpolated)
        }
        return SM64MarioFaceAnimationDecodedFrame(
            componentID: componentID,
            bank: bank,
            frameQ16: frameQ16,
            currentSourceFrame: currentFrame,
            nextSourceFrame: currentFrame &+ 1,
            fractionQ16: fractionQ16,
            type: window.type,
            values: values
        )
    }
}

enum SM64MarioFaceAnimationPayloadFingerprint {
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

    static func windows(_ windows: [SM64MarioFaceAnimationPayloadWindow]) -> UInt64 {
        var result = hash(offset, UInt64(windows.count))
        for window in windows {
            for value in [window.componentID, window.bank, window.frameStart, window.stride, window.type.rawValue, window.frameCount] {
                result = hash(result, UInt64(value))
            }
            result = hash(result, UInt64(window.rawValues.count))
            for value in window.rawValues {
                result = hash(result, UInt64(UInt16(bitPattern: value)))
            }
        }
        return result
    }

    static func frame(_ initial: UInt64, _ values: [Int16]?) -> UInt64 {
        var result = hash(initial, values == nil ? 0 : 1)
        guard let values else { return result }
        result = hash(result, UInt64(values.count))
        for value in values {
            result = hash(result, UInt64(UInt16(bitPattern: value)))
        }
        return result
    }

    static func decoded(_ initial: UInt64, _ frame: SM64MarioFaceAnimationDecodedFrame?) -> UInt64 {
        var result = hash(initial, frame == nil ? 0 : 1)
        guard let frame else { return result }
        for value in [
            frame.componentID, frame.bank, frame.frameQ16, frame.currentSourceFrame,
            frame.nextSourceFrame, frame.fractionQ16, frame.type.rawValue,
            UInt32(frame.values.count),
        ] {
            result = hash(result, UInt64(value))
        }
        for value in frame.values {
            result = hash(result, UInt64(value.bitPattern))
        }
        return result
    }
}
