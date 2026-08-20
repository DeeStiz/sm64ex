import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 {
    var result = seed
    for index in 0..<8 {
        result ^= (value >> UInt64(index * 8)) & 0xff
        result &*= fnvPrime
    }
    return result
}

private func hash(_ seed: UInt64, _ value: Int32) -> UInt64 {
    hash(seed, UInt64(bitPattern: Int64(value)))
}

@main
struct SM64RedCoinSmoke {
    static func main() {
        let waiting = SM64HiddenRedCoinStarBehavior.update(.init(action: .waiting, timer: 0, redCoinCounter: 7))
        let reveal = SM64HiddenRedCoinStarBehavior.update(.init(action: .waiting, timer: 0, redCoinCounter: 8))
        let revealWait = SM64HiddenRedCoinStarBehavior.update(.init(action: .reveal, timer: 2, redCoinCounter: 8))
        let revealSpawn = SM64HiddenRedCoinStarBehavior.update(.init(action: .reveal, timer: 3, redCoinCounter: 8))
        precondition(waiting.action == .waiting && waiting.timer == 1 && waiting.redCoinsCollected == 7 && !waiting.spawnNoExitStar)
        precondition(reveal.action == .reveal && reveal.timer == 0 && reveal.redCoinsCollected == 8)
        precondition(revealWait.timer == 3 && !revealWait.spawnNoExitStar && !revealWait.shouldDeactivate)
        precondition(revealSpawn.timer == 4 && revealSpawn.spawnNoExitStar && revealSpawn.spawnMist && revealSpawn.shouldDeactivate)

        let marker0 = SM64RedCoinStarMarkerBehavior.update(.init(timer: 0, faceYaw: 0))
        let marker1 = SM64RedCoinStarMarkerBehavior.update(.init(timer: 1, faceYaw: 0x100))
        precondition(marker0.timer == 1 && marker0.faceYaw == 0x100 && marker1.timer == 2 && marker1.faceYaw == 0x200)

        let untouched = SM64RedCoinBehavior.update(.init(parentCounter: 7, interacted: false))
        let last = SM64RedCoinBehavior.update(.init(parentCounter: 7, interacted: true))
        let middle = SM64RedCoinBehavior.update(.init(parentCounter: 3, interacted: true))
        let orphan = SM64RedCoinBehavior.update(.init(parentCounter: nil, interacted: true))
        precondition(untouched.parentCounter == 7 && !untouched.spawnGoldenSparkles && !untouched.shouldDelete && untouched.clearInteraction)
        precondition(last.parentCounter == 8 && last.orangeNumber == nil && last.soundOrdinal == 7 && last.spawnGoldenSparkles && last.shouldDelete)
        precondition(middle.parentCounter == 4 && middle.orangeNumber == 4 && middle.soundOrdinal == 3)
        precondition(orphan.parentCounter == nil && orphan.orangeNumber == nil && orphan.soundOrdinal == nil && orphan.spawnGoldenSparkles && orphan.shouldDelete)

        var fingerprint = fnvOffset
        for output in [waiting, reveal, revealWait, revealSpawn] {
            fingerprint = hash(fingerprint, output.action.rawValue)
            fingerprint = hash(fingerprint, output.timer)
            fingerprint = hash(fingerprint, output.redCoinsCollected)
            fingerprint = hash(fingerprint, UInt64(output.spawnNoExitStar ? 1 : 0))
            fingerprint = hash(fingerprint, UInt64(output.spawnMist ? 1 : 0))
            fingerprint = hash(fingerprint, UInt64(output.shouldDeactivate ? 1 : 0))
        }
        for output in [marker0, marker1] {
            fingerprint = hash(fingerprint, output.timer)
            fingerprint = hash(fingerprint, output.faceYaw)
        }
        for output in [untouched, last, middle, orphan] {
            fingerprint = hash(fingerprint, output.parentCounter.map { UInt64(bitPattern: Int64($0)) } ?? UInt64.max)
            fingerprint = hash(fingerprint, output.orangeNumber.map { UInt64(bitPattern: Int64($0)) } ?? UInt64.max)
            fingerprint = hash(fingerprint, output.soundOrdinal.map { UInt64(bitPattern: Int64($0)) } ?? UInt64.max)
            fingerprint = hash(fingerprint, UInt64(output.spawnGoldenSparkles ? 1 : 0))
            fingerprint = hash(fingerprint, UInt64(output.shouldDelete ? 1 : 0))
            fingerprint = hash(fingerprint, UInt64(output.clearInteraction ? 1 : 0))
        }
        print(String(format: "redCoinFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern red-coin star smoke passed")
    }
}
