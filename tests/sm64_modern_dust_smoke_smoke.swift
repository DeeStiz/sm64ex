import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 0xff; result &*= fnvPrime }; return result }

@main
struct SM64DustSmokeSmoke {
    static func main() {
        let delayed = SM64DustSmokeBehavior.update(.init(kind: .bobombFuse, position: .init(x: 10, y: 20, z: -4), velocity: .zero, moveYaw: 0, forwardVelocity: 0, timer: 0, smokeTimer: 0, animationState: -1, delayed: true, scale: 1.2))
        precondition(delayed.position == .init(x: 10, y: 20, z: -4) && !delayed.delayed && delayed.animationState == -1)
        let output = SM64DustSmokeBehavior.update(.init(kind: .smoke, position: .init(x: 10, y: 20, z: -4), velocity: .init(x: 1, y: 2, z: 3), moveYaw: 0, forwardVelocity: 2, timer: 1, smokeTimer: 0, animationState: -1, delayed: false, scale: 1))
        precondition(output.position == .init(x: 11, y: 22, z: 1) && output.smokeTimer == 1 && output.animationState == 0 && !output.shouldDelete)
        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, UInt64(output.position.x.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.position.y.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.position.z.bitPattern))
        fingerprint = hash(fingerprint, UInt64(output.smokeTimer))
        fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.animationState)))
        fingerprint = hash(fingerprint, output.shouldDelete ? 1 : 0)
        print(String(format: "dustSmokeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern dust smoke smoke passed")
    }
}
