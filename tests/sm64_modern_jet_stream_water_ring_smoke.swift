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

private func row(_ output: SM64JetStreamWaterRingOutput) -> [UInt64] {
    [UInt64(bitPattern: Int64(output.action)), UInt64(bitPattern: Int64(output.timer)), UInt64(bitPattern: Int64(output.opacity)), output.shouldDelete ? 1 : 0, output.collected ? 1 : 0]
}

@main
struct SM64JetStreamWaterRingSmoke {
    static func main() {
        let idle = SM64JetStreamWaterRingBehavior.update(.init(action: 0, timer: 0, opacity: 70, averageScale: 0.5, position: .zero, faceYaw: 0, marioNear: false, crossedRingPlane: false))
        let collect = SM64JetStreamWaterRingBehavior.update(.init(action: 0, timer: 0, opacity: 70, averageScale: 0.5, position: .zero, faceYaw: 0, marioNear: true, crossedRingPlane: true))
        let fade = SM64JetStreamWaterRingBehavior.update(.init(action: 1, timer: 21, opacity: 70, averageScale: 0.5, position: .zero, faceYaw: 0, marioNear: false, crossedRingPlane: false))
        precondition(idle.action == 0 && idle.timer == 1 && idle.position.y == 10)
        precondition(collect.action == 1 && collect.timer == 0 && collect.collected)
        precondition(fade.shouldDelete && fade.opacity == 60)
        var fingerprint = offset
        for output in [idle, collect, fade] {
            for value in row(output) { fingerprint = hash(fingerprint, value) }
        }
        print(String(format: "jetStreamWaterRingFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Jet Stream water ring smoke passed")
    }
}
