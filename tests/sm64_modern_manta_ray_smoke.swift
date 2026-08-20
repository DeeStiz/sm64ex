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

private func row(_ output: SM64MantaRayOutput) -> [UInt64] {
    [UInt64(bitPattern: Int64(output.action)), UInt64(bitPattern: Int64(output.timer)), UInt64(bitPattern: Int64(output.trajectoryIndex)), output.spawnRing ? 1 : 0, output.spawnStar ? 1 : 0]
}

@main
struct SM64MantaRaySmoke {
    static func main() {
        let first = SM64MantaRayBehavior.update(.init(action: 0, timer: 0, position: .zero, moveYaw: 0, movePitch: 0, faceRoll: 0, trajectoryIndex: 0, ringsCollected: 0))
        let solved = SM64MantaRayBehavior.update(.init(action: 0, timer: 50, position: .zero, moveYaw: 0, movePitch: 0, faceRoll: 0, trajectoryIndex: 1, ringsCollected: 5))
        precondition(first.position == .init(x: -4500, y: -1380, z: -40) && first.spawnRing && first.timer == 1)
        precondition(solved.action == 1 && solved.spawnStar && solved.trajectoryIndex == 2)
        var fingerprint = offset
        for output in [first, solved] { for value in row(output) { fingerprint = hash(fingerprint, value) } }
        print(String(format: "mantaRayFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Manta Ray smoke passed")
    }
}
