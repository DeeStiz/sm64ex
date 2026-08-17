import Foundation

struct SM64AudioADPCMBook: Equatable, Sendable {
    let order: Int
    let predictors: [[[Int32]]]

    init(order: Int, predictors: [[[Int32]]]) {
        self.order = max(order, 1)
        self.predictors = predictors
    }

    func row(predictor: Int, sample: Int) -> [Int32]? {
        guard predictors.indices.contains(predictor), predictors[predictor].indices.contains(sample),
              predictors[predictor][sample].count >= order + 8 else { return nil }
        return predictors[predictor][sample]
    }
}

struct SM64AudioADPCMDecoder: Equatable, Sendable {
    let book: SM64AudioADPCMBook

    init(book: SM64AudioADPCMBook) {
        self.book = book
    }

    /// Decodes one nine-byte Nintendo VADPCM frame into sixteen signed samples.
    /// State is the last `order` decoded samples from the preceding frame.
    func decode(block: [UInt8], state: inout [Int32]) -> [Int32]? {
        guard block.count >= 9, state.count >= book.order else { return nil }
        let header = block[0]
        let scale = Int32(1) << Int32(header >> 4)
        let predictor = Int(header & 0x0F)
        guard book.predictors.indices.contains(predictor) else { return nil }

        var residuals = Array(repeating: Int32(0), count: 16)
        for byteIndex in 0..<8 {
            let byte = block[byteIndex + 1]
            let high = Int32(byte >> 4)
            let low = Int32(byte & 0x0F)
            residuals[byteIndex * 2] = (high <= 7 ? high : high - 16) * scale
            residuals[byteIndex * 2 + 1] = (low <= 7 ? low : low - 16) * scale
        }

        var output = Array(repeating: Int32(0), count: 16)
        var input = Array(repeating: Int32(0), count: book.order + 8)
        for half in 0..<2 {
            if half == 0 {
                for index in 0..<book.order {
                    input[index] = state[state.count - book.order + index]
                }
            } else {
                for index in 0..<book.order {
                    input[index] = output[8 - book.order + index]
                }
            }
            for index in 0..<8 {
                input[book.order + index] = residuals[half * 8 + index]
                guard let coefficients = book.row(predictor: predictor, sample: index) else { return nil }
                output[half * 8 + index] = Self.floorDivide(
                    coefficients.enumerated().reduce(Int64(0)) { partial, item in
                        partial + Int64(item.element) * Int64(input[item.offset])
                    }, by: 1 << 11
                )
            }
        }
        state = Array(output.suffix(book.order))
        return output
    }

    private static func floorDivide(_ value: Int64, by divisor: Int64) -> Int32 {
        let quotient = value / divisor
        return Int32(clamping: value - quotient * divisor < 0 ? quotient - 1 : quotient)
    }
}

enum SM64AudioADSRState: UInt8, Equatable, Sendable {
    case disabled = 0
    case initial = 1
    case startLoop = 2
    case loop = 3
    case fade = 4
    case hang = 5
    case decay = 6
    case release = 7
    case sustain = 8
}

struct SM64AudioADSRAction: OptionSet, Equatable, Sendable {
    let rawValue: UInt8

    static let release = Self(rawValue: 0x10)
    static let decay = Self(rawValue: 0x20)
    static let hang = Self(rawValue: 0x40)
}

struct SM64AudioEnvelopePoint: Equatable, Sendable {
    let delay: Int32
    let target: Int32
}

struct SM64AudioADSRFrame: Equatable, Sendable {
    let state: SM64AudioADSRState
    let action: SM64AudioADSRAction
    let current: Int32
    let target: Int32
    let delay: Int32
    let envelopeIndex: Int
}

/// US/JP fixed-point ADSR state. Envelope values and velocity follow the
/// 16.16 arithmetic used by `effects.c`; no floating point is involved.
struct SM64AudioADSR: Equatable, Sendable {
    let envelope: [SM64AudioEnvelopePoint]
    private(set) var action: SM64AudioADSRAction = []
    private(set) var state: SM64AudioADSRState = .disabled
    private(set) var initial: Int32 = 0
    private(set) var target: Int32 = 0
    private(set) var current: Int32 = 0
    private(set) var currentHiRes: Int64 = 0
    private(set) var envelopeIndex = 0
    private(set) var delay: Int32 = 0
    private(set) var velocity: Int32 = 0
    private(set) var fadeOutVelocity: Int32 = 0
    private(set) var sustain: Int32 = 0

    init(envelope: [SM64AudioEnvelopePoint]) {
        self.envelope = envelope
    }

    mutating func start(initial: Int32 = 0) {
        self.initial = initial
        current = initial
        target = initial
        currentHiRes = Int64(initial) << 16
        state = .initial
        action = []
        envelopeIndex = 0
        delay = 0
    }

    mutating func setDecay(sustain: Int32, fadeOutVelocity: Int32) {
        self.sustain = max(sustain, 0)
        self.fadeOutVelocity = max(fadeOutVelocity, 0)
        action.insert(.decay)
    }

    mutating func requestRelease() {
        action.insert(.release)
    }

    mutating func tick() -> SM64AudioADSRFrame {
        // The US implementation returns immediately for a disabled note. In
        // particular, a late release/decay request remains pending rather than
        // reviving the voice from the disabled state.
        if state == .disabled {
            return SM64AudioADSRFrame(
                state: state,
                action: action,
                current: current,
                target: target,
                delay: delay,
                envelopeIndex: envelopeIndex
            )
        }
        let pending = action
        switch state {
        case .disabled:
            break
        case .initial:
            current = initial
            target = initial
            if action.contains(.hang) {
                state = .hang
                break
            }
            fallthrough
        case .startLoop:
            envelopeIndex = 0
            currentHiRes = Int64(current) << 16
            state = .loop
            fallthrough
        case .loop:
            guard envelope.indices.contains(envelopeIndex) else {
                state = .disabled
                break
            }
            delay = envelope[envelopeIndex].delay
            switch delay {
            case 0:
                state = .disabled
            case -1:
                state = .hang
            case -2:
                envelopeIndex = max(0, Int(envelope[envelopeIndex].target))
            case -3:
                state = .initial
            default:
                target = envelope[envelopeIndex].target
                velocity = Int32(clamping: ((Int64(target) - Int64(current)) << 16) / Int64(delay))
                state = .fade
                envelopeIndex += 1
            }
            guard state == .fade else { break }
            fallthrough
        case .fade:
            currentHiRes += Int64(velocity)
            current = Int32(clamping: currentHiRes >> 16)
            delay -= 1
            if delay <= 0 { state = .loop }
            fallthrough
        case .hang:
            break
        case .decay, .release:
            current -= fadeOutVelocity
            if sustain != 0, state == .decay {
                if current < sustain {
                    current = sustain
                    delay = sustain / 16
                    state = .sustain
                }
                break
            }
            if current < 100 {
                current = 0
                state = .disabled
            }
        case .sustain:
            delay -= 1
            if delay == 0 { state = .release }
        }

        if pending.contains(.decay) {
            state = .decay
            action.remove(.decay)
        }
        if pending.contains(.release) {
            state = .release
            action.remove([.release, .decay])
        }
        return SM64AudioADSRFrame(
            state: state,
            action: action,
            current: current,
            target: target,
            delay: delay,
            envelopeIndex: envelopeIndex
        )
    }
}

struct SM64AudioResampleWindow: Equatable, Sendable {
    let samples: [Int32]
    let phase: UInt32
}

enum SM64AudioLinearResampler {
    static func project(
        input: [Int32],
        pitchQ16: UInt32,
        outputCount: Int,
        phaseQ16: UInt32 = 0
    ) -> SM64AudioResampleWindow {
        guard !input.isEmpty, outputCount > 0 else {
            return SM64AudioResampleWindow(samples: [], phase: phaseQ16)
        }
        var output: [Int32] = []
        output.reserveCapacity(outputCount)
        for index in 0..<outputCount {
            let position = UInt64(phaseQ16) + UInt64(index) * UInt64(pitchQ16)
            let sourceIndex = Int(position >> 16)
            let fraction = Int64(position & 0xFFFF)
            let left = Int64(input[min(max(sourceIndex, 0), input.count - 1)])
            let right = Int64(input[min(max(sourceIndex + 1, 0), input.count - 1)])
            let interpolated = (left * (65_536 - fraction) + right * fraction) >> 16
            output.append(Int32(clamping: interpolated))
        }
        let nextPhase = UInt32((UInt64(phaseQ16) + UInt64(outputCount) * UInt64(pitchQ16)) & 0xFFFF)
        return SM64AudioResampleWindow(samples: output, phase: nextPhase)
    }
}

struct SM64AudioPCMWindow: Equatable, Sendable {
    let samples: [Int16]
    let resamplePhase: UInt32

    static func render(
        decoded: [Int32],
        pitchQ16: UInt32,
        envelopeQ15: [UInt16],
        phaseQ16: UInt32 = 0
    ) -> Self {
        let resampled = SM64AudioLinearResampler.project(
            input: decoded,
            pitchQ16: pitchQ16,
            outputCount: envelopeQ15.count,
            phaseQ16: phaseQ16
        )
        let samples = zip(resampled.samples, envelopeQ15).map { sample, gain in
            let value = (Int64(sample) * Int64(gain)) / 32_767
            return Int16(clamping: value)
        }
        return Self(samples: samples, resamplePhase: resampled.phase)
    }
}
