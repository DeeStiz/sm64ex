import Foundation
private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for byte in 0..<8 { result ^= (value >> UInt64(byte * 8)) & 255; result &*= prime }; return result }
private func hash(_ seed: UInt64, _ value: Int32) -> UInt64 { hash(seed, UInt64(bitPattern: Int64(value))) }
private func hash(_ seed: UInt64, _ value: Float) -> UInt64 { hash(seed, UInt64(value.bitPattern)) }
@main struct SM64OrangeNumberSmoke {
    static func main() {
        let start = SM64OrangeNumberBehavior.update(.init(timer: 0, animationState: 4, position: .zero, velocityY: 26))
        let bounce = SM64OrangeNumberBehavior.update(.init(timer: 0, animationState: 4, position: .zero, velocityY: -21))
        let end = SM64OrangeNumberBehavior.update(.init(timer: 35, animationState: 4, position: .init(x: 1, y: 2, z: 3), velocityY: 0))
        precondition(start.position.y == 26 && start.velocityY == 24 && !start.shouldDelete, "orange number rise")
        precondition(bounce.velocityY == 14, "orange number bounce")
        precondition(end.shouldDelete && end.spawnGoldenSparkles && end.position == .init(x: 1, y: 2, z: 3), "orange number expiry")
        var fingerprint = offset
        for output in [start, bounce, end] {
            fingerprint = hash(fingerprint, output.timer); fingerprint = hash(fingerprint, output.animationState); fingerprint = hash(fingerprint, output.position.x); fingerprint = hash(fingerprint, output.position.y); fingerprint = hash(fingerprint, output.position.z); fingerprint = hash(fingerprint, output.velocityY); fingerprint = hash(fingerprint, UInt64(output.shouldDelete ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(output.spawnGoldenSparkles ? 1 : 0))
        }
        print(String(format: "orangeNumberFingerprint=0x%016llx", fingerprint)); print("SM64 Modern orange-number smoke passed")
    }
}
