import Foundation

enum SM64AudioADPCMStreamEventKind: UInt8, Equatable, Sendable {
    case started = 1
    case blockRequested = 2
    case blockDecoded = 3
    case historyRestarted = 4
    case looped = 5
    case finished = 6
    case sampleUnavailable = 7
    case malformed = 8
}

struct SM64AudioADPCMStreamEvent: Equatable, Sendable {
    let kind: SM64AudioADPCMStreamEventKind
    let value0: Int
    let value1: Int
}

/// Integer sample-window inputs for the M28c loop/refill boundary. The
/// residency model is passed in by the owner and is the only mutable value
/// touched by the projection; encoded blocks and loop history are copied.
struct SM64AudioADPCMStreamWindowInput: Equatable, Sendable {
    let sample: SM64AudioSampleDescriptor
    let book: SM64AudioADPCMBook
    let encodedBlocks: [[UInt8]]
    let loopState: [Int32]
    let loopCount: Int
    let samplePosition: Int
    let requestedSamples: Int
    let decoderState: [Int32]
    let restartFromLoopState: Bool
    let streamClass: SM64AudioStreamClass
    let deviceAddress: Int
}

struct SM64AudioADPCMStreamWindowResult: Equatable, Sendable {
    let samples: [Int32]
    let nextSamplePosition: Int
    let decoderState: [Int32]
    let loops: Int
    let finished: Bool
    let streamEvents: [SM64AudioADPCMStreamEvent]
    let residencyEvents: [SM64AudioResidencyEvent]
}

enum SM64AudioADPCMStreamWindow {
    static func project(
        _ input: SM64AudioADPCMStreamWindowInput,
        residency: inout SM64AudioResidencyModel
    ) -> SM64AudioADPCMStreamWindowResult {
        let count = max(input.requestedSamples, 0)
        var streamEvents: [SM64AudioADPCMStreamEvent] = [
            SM64AudioADPCMStreamEvent(kind: .started, value0: input.sample.id, value1: count)
        ]
        var residencyEvents: [SM64AudioResidencyEvent] = []
        var samples: [Int32] = []
        samples.reserveCapacity(count)
        var position = max(input.samplePosition, 0)
        var remainingLoops = input.loopCount
        var loops = 0
        var finished = false
        var decoderState = input.decoderState
        var currentBlockIndex: Int?
        var currentBlock: [Int32] = []
        var streamHint: Int?

        guard input.sample.loaded,
              input.sample.sampleSize > 0,
              input.sample.loopStart >= 0,
              input.sample.loopEnd > input.sample.loopStart,
              input.sample.loopEnd <= input.sample.sampleSize,
              decoderState.count >= input.book.order,
              input.loopState.count >= input.book.order else {
            streamEvents.append(SM64AudioADPCMStreamEvent(kind: .sampleUnavailable, value0: input.sample.id, value1: input.sample.loopEnd))
            return SM64AudioADPCMStreamWindowResult(
                samples: Array(repeating: 0, count: count),
                nextSamplePosition: position,
                decoderState: decoderState,
                loops: 0,
                finished: true,
                streamEvents: streamEvents,
                residencyEvents: residencyEvents
            )
        }

        if input.restartFromLoopState {
            decoderState = Array(input.loopState.prefix(input.book.order))
            streamEvents.append(SM64AudioADPCMStreamEvent(kind: .historyRestarted, value0: input.sample.loopStart, value1: input.book.order))
        }

        for outputIndex in 0..<count {
            if finished {
                samples.append(0)
                continue
            }

            while position >= input.sample.loopEnd {
                if input.loopCount == 0 || (remainingLoops == 0 && input.loopCount > 0) {
                    finished = true
                    streamEvents.append(SM64AudioADPCMStreamEvent(kind: .finished, value0: input.sample.id, value1: outputIndex))
                    break
                }
                if remainingLoops > 0 {
                    remainingLoops -= 1
                }
                loops += 1
                position = input.sample.loopStart
                decoderState = Array(input.loopState.prefix(input.book.order))
                currentBlockIndex = nil
                currentBlock.removeAll(keepingCapacity: true)
                streamHint = nil
                streamEvents.append(SM64AudioADPCMStreamEvent(kind: .historyRestarted, value0: position, value1: input.book.order))
                streamEvents.append(SM64AudioADPCMStreamEvent(kind: .looped, value0: loops, value1: position))
            }
            if finished {
                samples.append(0)
                continue
            }

            let blockIndex = position / 16
            let blockOffset = position & 15
            if currentBlockIndex != blockIndex {
                guard input.encodedBlocks.indices.contains(blockIndex), input.encodedBlocks[blockIndex].count >= 9 else {
                    finished = true
                    streamEvents.append(SM64AudioADPCMStreamEvent(kind: .malformed, value0: blockIndex, value1: outputIndex))
                    samples.append(0)
                    continue
                }
                let address = input.deviceAddress + blockIndex * 9
                let trace = residency.requestSample(
                    sampleID: input.sample.id,
                    deviceAddress: address,
                    size: 9,
                    streamClass: input.streamClass,
                    hint: streamHint
                )
                residencyEvents.append(contentsOf: trace.events)
                streamHint = trace.selectedID
                streamEvents.append(SM64AudioADPCMStreamEvent(
                    kind: .blockRequested,
                    value0: blockIndex,
                    value1: trace.failed ? -1 : (trace.selectedID ?? -1)
                ))
                guard !trace.failed else {
                    finished = true
                    streamEvents.append(SM64AudioADPCMStreamEvent(kind: .sampleUnavailable, value0: input.sample.id, value1: blockIndex))
                    samples.append(0)
                    continue
                }
                let decoder = SM64AudioADPCMDecoder(book: input.book)
                guard let decoded = decoder.decode(block: input.encodedBlocks[blockIndex], state: &decoderState) else {
                    finished = true
                    streamEvents.append(SM64AudioADPCMStreamEvent(kind: .malformed, value0: blockIndex, value1: outputIndex))
                    samples.append(0)
                    continue
                }
                currentBlock = decoded
                currentBlockIndex = blockIndex
                streamEvents.append(SM64AudioADPCMStreamEvent(kind: .blockDecoded, value0: blockIndex, value1: decoded.count))
            }

            guard currentBlock.indices.contains(blockOffset) else {
                finished = true
                streamEvents.append(SM64AudioADPCMStreamEvent(kind: .malformed, value0: blockIndex, value1: blockOffset))
                samples.append(0)
                continue
            }
            samples.append(currentBlock[blockOffset])
            position += 1
        }

        return SM64AudioADPCMStreamWindowResult(
            samples: samples,
            nextSamplePosition: position,
            decoderState: decoderState,
            loops: loops,
            finished: finished,
            streamEvents: streamEvents,
            residencyEvents: residencyEvents
        )
    }
}
