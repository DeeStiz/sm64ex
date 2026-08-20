import Foundation

private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211

private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 {
    var result = seed
    for index in 0..<8 {
        result ^= (value >> UInt64(index * 8)) & 255
        result &*= prime
    }
    return result
}

private func row(_ output: SM64CourtyardBooTripletOutput) -> [UInt64] {
    [UInt64(output.spawnCount), output.shouldDeactivate ? 1 : 0, output.starGatePassed ? 1 : 0]
}

@main
struct SM64CourtyardBooTripletSmoke {
    static func main() {
        let ready = SM64CourtyardBooTripletBehavior.update(timer: 0, totalStars: 12)
        let locked = SM64CourtyardBooTripletBehavior.update(timer: 0, totalStars: 11)
        let later = SM64CourtyardBooTripletBehavior.update(timer: 1, totalStars: 12)
        precondition(ready.spawnCount == 3 && ready.shouldDeactivate && ready.starGatePassed)
        precondition(locked.spawnCount == 0 && locked.shouldDeactivate && !locked.starGatePassed)
        precondition(later.spawnCount == 0 && later.shouldDeactivate && later.starGatePassed)
        var fingerprint = offset
        for output in [ready, locked, later] {
            for value in row(output) { fingerprint = hash(fingerprint, value) }
        }
        print(String(format: "courtyardBooTripletFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern courtyard Boo triplet smoke passed")
    }
}
