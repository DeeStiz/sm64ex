import Foundation

enum SM64AudioVoiceEventKind: UInt8, Equatable, Sendable {
    case started = 1
    case disabled = 2
    case sampleUnavailable = 3
    case released = 4
    case looped = 5
    case finished = 6
    case active = 7
}

struct SM64AudioVoiceEvent: Equatable, Sendable {
    let kind: SM64AudioVoiceEventKind
    let value0: Int
    let value1: Int
}

/// Copied inputs for one US/JP note-synthesis window. The note and sample
/// descriptors originate at the M27 pool/residency boundary; `decoded` is a
/// bounded value window supplied by the M28a ADPCM decoder.
struct SM64AudioVoiceWindowInput: Equatable, Sendable {
    let note: SM64AudioNoteState
    let sample: SM64AudioSampleDescriptor
    let streamClass: SM64AudioStreamClass
    let decoded: [Int32]
    let pitchQ16: UInt32
    let envelopeQ15: [UInt16]
    let panQ15: UInt16
    let reverbQ15: UInt16
    let samplePositionQ16: UInt64
    let loopCount: Int
    let outputCount: Int
    let releaseRequested: Bool
}

struct SM64AudioVoiceWindowResult: Equatable, Sendable {
    let noteID: Int
    let streamClass: SM64AudioStreamClass
    let left: [Int16]
    let right: [Int16]
    let reverb: [Int16]
    let nextSamplePositionQ16: UInt64
    let loops: Int
    let finished: Bool
    let events: [SM64AudioVoiceEvent]
}

/// Projects one bounded note voice into dry stereo/reverb windows and
/// lifetime events. It intentionally stops at a value packet: the realtime
/// AVAudio queue and the hardware mixer remain separate audited leaves.
enum SM64AudioVoiceWindow {
    static func project(_ input: SM64AudioVoiceWindowInput) -> SM64AudioVoiceWindowResult {
        let count = max(input.outputCount, 0)
        let silence = Array(repeating: Int16(0), count: count)
        var events: [SM64AudioVoiceEvent] = []
        events.append(SM64AudioVoiceEvent(
            kind: .started,
            value0: input.note.id,
            value1: Int(input.streamClass.rawValue)
        ))

        guard input.note.priority != 0, input.note.list != .disabled,
              input.note.list != .detached else {
            events.append(SM64AudioVoiceEvent(kind: .disabled, value0: input.note.id, value1: Int(input.note.priority)))
            return SM64AudioVoiceWindowResult(
                noteID: input.note.id,
                streamClass: input.streamClass,
                left: silence,
                right: silence,
                reverb: silence,
                nextSamplePositionQ16: input.samplePositionQ16,
                loops: 0,
                finished: true,
                events: events
            )
        }

        guard input.sample.loaded, input.sample.sampleSize > 0,
              input.sample.loopStart >= 0,
              input.sample.loopEnd > input.sample.loopStart,
              input.sample.loopEnd <= input.decoded.count else {
            events.append(SM64AudioVoiceEvent(kind: .sampleUnavailable, value0: input.sample.id, value1: input.sample.loopEnd))
            return SM64AudioVoiceWindowResult(
                noteID: input.note.id,
                streamClass: input.streamClass,
                left: silence,
                right: silence,
                reverb: silence,
                nextSamplePositionQ16: input.samplePositionQ16,
                loops: 0,
                finished: true,
                events: events
            )
        }

        if input.releaseRequested {
            events.append(SM64AudioVoiceEvent(kind: .released, value0: input.note.id, value1: Int(input.note.priority)))
        }

        let pan = min(input.panQ15, UInt16(32_767))
        let leftPan = Int64(32_767 - pan)
        let rightPan = Int64(pan)
        let reverbGain = Int64(min(input.reverbQ15, UInt16(32_767)))
        let fallbackEnvelope = [UInt16(32_767)]
        let envelope = input.envelopeQ15.isEmpty ? fallbackEnvelope : input.envelopeQ15
        var left: [Int16] = []
        var right: [Int16] = []
        var reverb: [Int16] = []
        left.reserveCapacity(count)
        right.reserveCapacity(count)
        reverb.reserveCapacity(count)

        var position = input.samplePositionQ16
        var remainingLoops = input.loopCount
        var loops = 0
        var finished = false
        for outputIndex in 0..<count {
            if finished {
                left.append(0)
                right.append(0)
                reverb.append(0)
                continue
            }

            var sourceIndex = Int(position >> 16)
            while sourceIndex >= input.sample.loopEnd {
                if input.loopCount == 0 || (remainingLoops == 0 && input.loopCount > 0) {
                    finished = true
                    events.append(SM64AudioVoiceEvent(kind: .finished, value0: input.note.id, value1: outputIndex))
                    break
                }
                if remainingLoops > 0 {
                    remainingLoops -= 1
                }
                loops += 1
                events.append(SM64AudioVoiceEvent(kind: .looped, value0: loops, value1: input.sample.loopStart))
                position = UInt64(input.sample.loopStart) << 16
                sourceIndex = input.sample.loopStart
            }

            if finished {
                left.append(0)
                right.append(0)
                reverb.append(0)
                continue
            }

            let fraction = Int64(position & 0xFFFF)
            let nextIndex: Int
            if sourceIndex + 1 < input.sample.loopEnd {
                nextIndex = sourceIndex + 1
            } else if input.loopCount != 0 {
                nextIndex = input.sample.loopStart
            } else {
                nextIndex = input.sample.loopEnd - 1
            }
            let source = Int64(input.decoded[sourceIndex])
            let next = Int64(input.decoded[nextIndex])
            let interpolated = (source * (65_536 - fraction) + next * fraction) >> 16
            let gain = Int64(envelope[outputIndex % envelope.count])
            let envelopeSample = (interpolated * gain) / 32_767
            let leftSample = (envelopeSample * leftPan) / 32_767
            let rightSample = (envelopeSample * rightPan) / 32_767
            let reverbSample = (envelopeSample * reverbGain) / 32_767
            left.append(Int16(clamping: leftSample))
            right.append(Int16(clamping: rightSample))
            reverb.append(Int16(clamping: reverbSample))
            position &+= UInt64(input.pitchQ16)
        }

        if !finished {
            events.append(SM64AudioVoiceEvent(kind: .active, value0: input.note.id, value1: count))
        }
        return SM64AudioVoiceWindowResult(
            noteID: input.note.id,
            streamClass: input.streamClass,
            left: left,
            right: right,
            reverb: reverb,
            nextSamplePositionQ16: position,
            loops: loops,
            finished: finished,
            events: events
        )
    }
}
