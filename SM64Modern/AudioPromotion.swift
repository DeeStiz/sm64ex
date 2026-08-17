import Foundation

/// One owner-thread result from the bounded M28e audio promotion envelope.
/// The receipt is value-only: it can be logged or compared without exposing
/// an AVAudio object or a pointer owned by the native realtime leaf.
struct SM64AudioPromotionTick: Equatable, Sendable {
    let simulationTick: UInt64
    let recordsAdded: Int
    let frameCount: Int
    let clippedSamples: Int
    let frameFingerprint: UInt64
    let admissionFailed: Bool
}

struct SM64AudioPromotionSummary: Equatable, Sendable {
    let ownerToken: UInt64
    let ticks: UInt64
    let traceRecords: Int
    let pcmFrames: UInt64
    let lastFrameFingerprint: UInt64
    let traceFingerprint: UInt64
    let admissionFailed: Bool
}

/// Cross-boundary value fingerprinting for the promoted audio window. The
/// fields are deliberately fixed-width so the C contract can independently
/// reproduce the receipt fingerprint without linking Swift implementation
/// details.
enum SM64AudioPromotionFingerprint {
    static let offset: UInt64 = 1_469_598_103_934_665_603
    static let prime: UInt64 = 1_099_511_628_211

    static func hash(_ hash: UInt64, _ value: UInt64) -> UInt64 {
        var result = hash
        for shift in stride(from: 0, through: 56, by: 8) {
            result ^= (value >> UInt64(shift)) & 0xFF
            result &*= prime
        }
        return result
    }

    static func hashSigned(_ hash: UInt64, _ value: Int64) -> UInt64 {
        Self.hash(hash, UInt64(bitPattern: value))
    }

    static func hashInt16Array(_ hash: UInt64, _ values: [Int16]) -> UInt64 {
        var result = Self.hash(hash, UInt64(values.count))
        for value in values {
            result = hashSigned(result, Int64(value))
        }
        return result
    }

    static func hashInt32Array(_ hash: UInt64, _ values: [Int32]) -> UInt64 {
        var result = Self.hash(hash, UInt64(values.count))
        for value in values {
            result = hashSigned(result, Int64(value))
        }
        return result
    }

    static func frame(_ frame: SM64AudioPCMFrame) -> UInt64 {
        var result = hash(offset, UInt64(frame.sampleRateHz))
        result = hash(result, UInt64(frame.frameCount))
        result = hashInt16Array(result, frame.interleavedStereo)
        result = hashInt16Array(result, frame.dryLeft)
        result = hashInt16Array(result, frame.dryRight)
        result = hashInt16Array(result, frame.wetLeft)
        result = hashInt16Array(result, frame.wetRight)
        result = hash(result, UInt64(frame.voiceOrder.count))
        for noteID in frame.voiceOrder {
            result = hashSigned(result, Int64(noteID))
        }
        result = hash(result, UInt64(frame.clippedSamples))
        result = hashInt32Array(result, frame.nextReverb.left)
        result = hashInt32Array(result, frame.nextReverb.right)
        result = hash(result, UInt64(frame.nextReverb.writeIndex))
        result = hash(result, UInt64(frame.nextReverb.feedbackQ15))
        return hash(result, UInt64(frame.nextReverb.gainQ15))
    }

    static func trace(_ session: SM64AudioPreSynthesisTraceSession) -> UInt64 {
        var result = hash(offset, UInt64(session.records.count))
        for record in session.records {
            result = hash(result, record.canonicalHash)
        }
        return hash(result, session.admissionFailed ? 1 : 0)
    }

    static func receipts(_ receipts: [SM64AudioPromotionTick]) -> UInt64 {
        var result = hash(offset, UInt64(receipts.count))
        for receipt in receipts {
            result = hash(result, receipt.simulationTick)
            result = hash(result, UInt64(receipt.recordsAdded))
            result = hash(result, UInt64(receipt.frameCount))
            result = hash(result, UInt64(receipt.clippedSamples))
            result = hash(result, receipt.frameFingerprint)
            result = hash(result, receipt.admissionFailed ? 1 : 0)
        }
        return result
    }
}

/// Owner-thread promotion envelope for the M27/M28 audio value graph.
///
/// This is intentionally not the realtime audio service. It copies sequence,
/// pool, residency, stream, voice, and mixer values on the EngineHost owner
/// thread, records a schema-4 trace, and returns a bounded PCM frame. The
/// existing AVAudio queue remains the default hardware-facing path until a
/// later milestone proves an audible/device gate.
struct SM64AudioOwnerPromotion: Equatable, Sendable {
    static let sample = SM64AudioSampleDescriptor(
        id: 7,
        loaded: true,
        encoded: true,
        loopStart: 0,
        loopEnd: 8,
        bookID: 0,
        sampleSize: 8
    )
    static let book: SM64AudioADPCMBook = {
        var row = Array(repeating: Int32(0), count: 9)
        row[0] = 2_048
        row[1] = 1_024
        return SM64AudioADPCMBook(order: 1, predictors: [[row]])
    }()
    static let encodedBlock: [UInt8] = [
        0x00, 0x12, 0x34, 0x56, 0x78, 0xF0, 0x0F, 0xAA, 0x55
    ]
    static let decodedWindow: [Int32] = [
        1_000, 2_000, 3_000, 4_000, 5_000, 6_000, 7_000, 8_000,
        7_000, 6_000, 5_000, 4_000, 3_000, 2_000, 1_000, 0
    ]

    let ownerToken: UInt64
    private(set) var traceSession: SM64AudioPreSynthesisTraceSession
    private var sequencePlayer: SM64AudioSequencePlayerModel
    private var poolModel: SM64AudioPoolModel
    private var residencyModel: SM64AudioResidencyModel
    private var reverbState: SM64AudioReverbState
    private var streamPosition = 0
    private var streamDecoderState = [Int32(0)]
    private var voicePositionQ16: UInt64 = 0
    private var poolReady = false
    private(set) var ticks: UInt64 = 0
    private(set) var pcmFrames: UInt64 = 0
    private(set) var lastFrameFingerprint: UInt64 = 0
    private(set) var admissionFailed = false

    init(ownerToken: UInt64) {
        self.ownerToken = ownerToken
        traceSession = SM64AudioPreSynthesisTraceSession(ownerToken: ownerToken)
        sequencePlayer = SM64AudioSequencePlayerModel(
            sequenceData: [0xD7, 0x00, 0x01, 0xFE, 0xFF],
            tempoInternalToExternal: 5_760
        )
        poolModel = SM64AudioPoolModel(layerCapacity: 2, channelCapacity: 1, noteCapacity: 2)
        var residency = SM64AudioResidencyModel(
            bankCapacity: 4,
            sequenceCapacity: 4,
            shortStreamCapacity: 1,
            longStreamCapacity: 1,
            shortBufferSize: 64,
            longBufferSize: 64
        )
        residency.register(Self.sample)
        residencyModel = residency
        reverbState = SM64AudioReverbState(
            left: [0, 0, 0, 0],
            right: [0, 0, 0, 0],
            writeIndex: 0,
            feedbackQ15: 8_192,
            gainQ15: 8_192
        )
    }

    /// Advances one owner-thread window. A foreign token permanently fences
    /// the promotion, and no model or PCM state is advanced after the fence.
    @discardableResult
    mutating func tick(ownerToken candidateToken: UInt64, simulationTick: UInt64) -> SM64AudioPromotionTick {
        let initialRecords = traceSession.records.count
        guard candidateToken == ownerToken, !admissionFailed else {
            admissionFailed = true
            _ = traceSession.append(
                ownerToken: candidateToken,
                simulationTick: simulationTick,
                source: .pcm,
                eventCode: 0xFFFF,
                subjectID: 0,
                values: [candidateToken]
            )
            return SM64AudioPromotionTick(
                simulationTick: simulationTick,
                recordsAdded: traceSession.records.count - initialRecords,
                frameCount: 0,
                clippedSamples: 0,
                frameFingerprint: 0,
                admissionFailed: true
            )
        }

        let sequencePacket = sequencePlayer.tick()
        guard traceSession.append(
            ownerToken: candidateToken,
            simulationTick: simulationTick,
            player: 0,
            packet: sequencePacket
        ) else {
            admissionFailed = true
            return failedTick(simulationTick: simulationTick, initialRecords: initialRecords)
        }
        guard traceSession.append(
            ownerToken: candidateToken,
            simulationTick: simulationTick,
            source: .sequence,
            eventCode: 0x7FFF,
            subjectID: 0,
            values: [
                UInt64(sequencePlayer.programCounter),
                UInt64(sequencePlayer.tempo),
                UInt64(sequencePlayer.delay),
                sequencePlayer.finished ? 1 : 0
            ]
        ) else {
            admissionFailed = true
            return failedTick(simulationTick: simulationTick, initialRecords: initialRecords)
        }

        var poolTrace: SM64AudioPoolTrace
        if !poolReady {
            var events = poolModel.initializeChannels(
                mask: 1,
                notePriority: 3,
                allocationPolicy: []
            ).events
            events.append(contentsOf: poolModel.setLayer(channelSlot: 0, layerIndex: 0).events)
            let noteTrace = poolModel.allocateNote(channelSlot: 0, layerIndex: 0, bankAvailable: true)
            events.append(contentsOf: noteTrace.events)
            poolTrace = SM64AudioPoolTrace(
                events: events,
                selectedNoteID: noteTrace.selectedNoteID,
                failed: noteTrace.failed
            )
            poolReady = !poolTrace.failed
        } else {
            poolModel.markLayerNoteReusable(channelSlot: 0, layerIndex: 0)
            poolTrace = poolModel.setLayer(channelSlot: 0, layerIndex: 0)
            if !poolTrace.failed {
                let noteTrace = poolModel.allocateNote(channelSlot: 0, layerIndex: 0, bankAvailable: true)
                poolTrace = SM64AudioPoolTrace(
                    events: poolTrace.events + noteTrace.events,
                    selectedNoteID: noteTrace.selectedNoteID,
                    failed: noteTrace.failed
                )
            }
        }
        for event in poolTrace.events {
            guard traceSession.append(
                ownerToken: candidateToken,
                simulationTick: simulationTick,
                channel: 0,
                event: event
            ) else {
                admissionFailed = true
                return failedTick(simulationTick: simulationTick, initialRecords: initialRecords)
            }
        }
        guard !poolTrace.failed,
              let noteID = poolTrace.selectedNoteID,
              poolModel.notes.indices.contains(noteID) else {
            admissionFailed = true
            return failedTick(simulationTick: simulationTick, initialRecords: initialRecords)
        }

        let streamResult = SM64AudioADPCMStreamWindow.project(
            SM64AudioADPCMStreamWindowInput(
                sample: Self.sample,
                book: Self.book,
                encodedBlocks: [Self.encodedBlock],
                loopState: [0],
                loopCount: 1,
                samplePosition: streamPosition,
                requestedSamples: 4,
                decoderState: streamDecoderState,
                restartFromLoopState: false,
                streamClass: .short,
                deviceAddress: 0x2_000
            ),
            residency: &residencyModel
        )
        streamPosition = streamResult.nextSamplePosition
        streamDecoderState = streamResult.decoderState
        for event in streamResult.streamEvents {
            guard traceSession.append(
                ownerToken: candidateToken,
                simulationTick: simulationTick,
                source: .stream,
                eventCode: 0x0100 | UInt32(event.kind.rawValue),
                subjectID: UInt64(Self.sample.id),
                values: [
                    UInt64(bitPattern: Int64(event.value0)),
                    UInt64(bitPattern: Int64(event.value1))
                ]
            ) else {
                admissionFailed = true
                return failedTick(simulationTick: simulationTick, initialRecords: initialRecords)
            }
        }
        for event in streamResult.residencyEvents {
            guard traceSession.append(
                ownerToken: candidateToken,
                simulationTick: simulationTick,
                subjectID: Self.sample.id,
                event: event,
                source: .stream
            ) else {
                admissionFailed = true
                return failedTick(simulationTick: simulationTick, initialRecords: initialRecords)
            }
        }

        let note = poolModel.notes[noteID]
        let voice = SM64AudioVoiceWindow.project(
            SM64AudioVoiceWindowInput(
                note: note,
                sample: Self.sample,
                streamClass: .short,
                decoded: Self.decodedWindow,
                pitchQ16: 65_536,
                envelopeQ15: [32_767, 30_000, 28_000, 26_000],
                panQ15: 12_000,
                reverbQ15: 6_000,
                samplePositionQ16: voicePositionQ16,
                loopCount: 1,
                outputCount: 4,
                releaseRequested: false
            )
        )
        voicePositionQ16 = voice.nextSamplePositionQ16
        let effectBase = Int16(clamping: 600 + Int(simulationTick % 3) * 50)
        let effectVoice = SM64AudioMixVoice(
            noteID: 99,
            priority: 2,
            source: .effect,
            left: Array(repeating: effectBase, count: 4),
            right: Array(repeating: Int16(clamping: -Int(effectBase)), count: 4),
            reverb: Array(repeating: 100, count: 4)
        )
        let musicVoice = SM64AudioMixVoice(
            noteID: voice.noteID,
            priority: note.priority,
            source: .music,
            left: voice.left,
            right: voice.right,
            reverb: voice.reverb
        )
        let frame = SM64AudioMixer.mix(
            voices: [musicVoice, effectVoice],
            frameCount: 4,
            reverb: reverbState,
            enableReverb: true
        )
        reverbState = frame.nextReverb
        let frameFingerprint = SM64AudioPromotionFingerprint.frame(frame)
        guard traceSession.append(
            ownerToken: candidateToken,
            simulationTick: simulationTick,
            source: .pcm,
            eventCode: 1,
            subjectID: UInt64(pcmFrames),
            values: [
                UInt64(frame.sampleRateHz),
                UInt64(frame.frameCount),
                UInt64(frame.clippedSamples),
                frameFingerprint,
                UInt64(frame.interleavedStereo.count),
                UInt64(frame.voiceOrder.count)
            ]
        ) else {
            admissionFailed = true
            return failedTick(simulationTick: simulationTick, initialRecords: initialRecords)
        }

        ticks &+= 1
        pcmFrames &+= 1
        lastFrameFingerprint = frameFingerprint
        return SM64AudioPromotionTick(
            simulationTick: simulationTick,
            recordsAdded: traceSession.records.count - initialRecords,
            frameCount: frame.frameCount,
            clippedSamples: frame.clippedSamples,
            frameFingerprint: frameFingerprint,
            admissionFailed: false
        )
    }

    func summary() -> SM64AudioPromotionSummary {
        SM64AudioPromotionSummary(
            ownerToken: ownerToken,
            ticks: ticks,
            traceRecords: traceSession.records.count,
            pcmFrames: pcmFrames,
            lastFrameFingerprint: lastFrameFingerprint,
            traceFingerprint: SM64AudioPromotionFingerprint.trace(traceSession),
            admissionFailed: admissionFailed || traceSession.admissionFailed
        )
    }

    private func failedTick(simulationTick: UInt64, initialRecords: Int) -> SM64AudioPromotionTick {
        SM64AudioPromotionTick(
            simulationTick: simulationTick,
            recordsAdded: traceSession.records.count - initialRecords,
            frameCount: 0,
            clippedSamples: 0,
            frameFingerprint: 0,
            admissionFailed: true
        )
    }
}
