import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result=seed; for index in 0..<8 { result ^= (value >> UInt64(index*8)) & 0xff; result &*= fnvPrime }; return result }

@main
struct SM64BlueFlamesGroupSmoke {
    static func main() {
        let output = SM64BlueFlamesGroupBehavior.update(.init(position: .init(x: 10, y: 20, z: -4), timer: 0, moveYaw: 0, scale: 5))
        precondition(output.position == .init(x: 10, y: 20, z: -4) && output.spawnCount == 3 && output.scale == 5 && !output.shouldDeactivate)
        var fingerprint=fnvOffset; fingerprint=hash(fingerprint,UInt64(output.spawnCount)); fingerprint=hash(fingerprint,UInt64(output.scale.bitPattern)); fingerprint=hash(fingerprint,UInt64(output.position.y.bitPattern)); fingerprint=hash(fingerprint,output.shouldDeactivate ? 1:0)
        print(String(format:"blueFlamesGroupFingerprint=0x%016llx",fingerprint)); print("SM64 Modern blue-flames group smoke passed")
    }
}
