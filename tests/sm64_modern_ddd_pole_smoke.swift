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

private func row(_ output: SM64DDDPoleOutput) -> [UInt64] {
    [
        UInt64(bitPattern: Int64(output.timer)),
        UInt64(output.offset.bitPattern),
        UInt64(output.velocity.bitPattern),
        output.shouldDelete ? 1 : 0,
        output.bounced ? 1 : 0,
    ]
}

@main
struct SM64DDDPoleSmoke {
    static func main() {
        let locked = SM64DDDPoleBehavior.update(.init(timer: 0, offset: 0, velocity: 10, maxOffset: 100, saveUnlocked: false))
        let waiting = SM64DDDPoleBehavior.update(.init(timer: 20, offset: 0, velocity: 10, maxOffset: 100, saveUnlocked: true))
        let moving = SM64DDDPoleBehavior.update(.init(timer: 21, offset: 20, velocity: 10, maxOffset: 100, saveUnlocked: true))
        let bounce = SM64DDDPoleBehavior.update(.init(timer: 21, offset: 95, velocity: 10, maxOffset: 100, saveUnlocked: true))
        precondition(locked.shouldDelete && locked.hitboxDownOffset == 100)
        precondition(waiting.timer == 21 && waiting.offset == 0)
        precondition(moving.timer == 22 && moving.offset == 30 && moving.velocity == 10)
        precondition(bounce.timer == 0 && bounce.offset == 100 && bounce.velocity == -10 && bounce.bounced)
        var fingerprint = offset
        for output in [locked, waiting, moving, bounce] {
            for value in row(output) { fingerprint = hash(fingerprint, value) }
        }
        print(String(format: "dddPoleFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern DDD pole smoke passed")
    }
}
