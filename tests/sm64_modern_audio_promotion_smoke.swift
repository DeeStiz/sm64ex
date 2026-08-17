import Foundation

@main
enum SM64ModernAudioPromotionSmoke {
    static func main() {
        let ownerToken: UInt64 = 0xA0D10
        var promotion = SM64AudioOwnerPromotion(ownerToken: ownerToken)
        var receipts: [SM64AudioPromotionTick] = []
        for tick in 1...3 {
            let receipt = promotion.tick(ownerToken: ownerToken, simulationTick: UInt64(tick))
            precondition(!receipt.admissionFailed)
            precondition(receipt.frameCount == 4)
            precondition(receipt.recordsAdded > 0)
            precondition(receipt.frameFingerprint != 0)
            receipts.append(receipt)
        }

        let activeSummary = promotion.summary()
        precondition(activeSummary.ticks == 3)
        precondition(activeSummary.pcmFrames == 3)
        precondition(activeSummary.traceRecords > 3)
        precondition(!activeSummary.admissionFailed)
        precondition(activeSummary.lastFrameFingerprint == receipts.last?.frameFingerprint)

        let foreign = promotion.tick(ownerToken: 0xBAD, simulationTick: 4)
        precondition(foreign.admissionFailed)
        precondition(foreign.frameCount == 0)
        let fencedSummary = promotion.summary()
        precondition(fencedSummary.admissionFailed)
        precondition(fencedSummary.ticks == 3)
        precondition(fencedSummary.pcmFrames == 3)
        precondition(fencedSummary.traceRecords == activeSummary.traceRecords)

        let fingerprint = SM64AudioPromotionFingerprint.receipts(receipts)
        print("audioPromotionFingerprint=0x\(String(fingerprint, radix: 16))")
        print("audioPromotionFrameFingerprints=" + receipts.map { String($0.frameFingerprint, radix: 16) }.joined(separator: ","))
        print("audioPromotionRecords=" + receipts.map { String($0.recordsAdded) }.joined(separator: ","))
        print("audioPromotionClipped=" + receipts.map { String($0.clippedSamples) }.joined(separator: ","))
        print("audioPromotionTraceRecords=\(activeSummary.traceRecords)")
        print("SM64 Modern audio owner-promotion smoke passed")
    }
}
