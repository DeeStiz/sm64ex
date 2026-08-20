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

private func row(_ output: SM64MantaRayWaterRingOutput) -> [UInt64] {
    [UInt64(bitPattern: Int64(output.action)), UInt64(bitPattern: Int64(output.timer)), UInt64(bitPattern: Int64(output.opacity)), output.shouldDelete ? 1 : 0, output.collected ? 1 : 0]
}

@main
struct SM64MantaRayWaterRingSmoke {
    static func main() {
        let idle = SM64MantaRayWaterRingBehavior.update(.init(action: 0, timer: 0, opacity: 150, averageScale: 0.1, marioNear: false, crossedRingPlane: false))
        let collect = SM64MantaRayWaterRingBehavior.update(.init(action: 0, timer: 0, opacity: 150, averageScale: 0.1, marioNear: true, crossedRingPlane: true))
        let fade = SM64MantaRayWaterRingBehavior.update(.init(action: 1, timer: 21, opacity: 150, averageScale: 0.1, marioNear: false, crossedRingPlane: false))
        precondition(idle.timer == 1 && idle.opacity == 150 && idle.averageScale == 0.1)
        precondition(collect.action == 1 && collect.timer == 0 && collect.collected)
        precondition(fade.opacity == 140 && fade.shouldDelete)
        var fingerprint = offset
        for output in [idle, collect, fade] { for value in row(output) { fingerprint = hash(fingerprint, value) } }
        print(String(format: "mantaRayWaterRingFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Manta Ray water ring smoke passed")
    }
}
