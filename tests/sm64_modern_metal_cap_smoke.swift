import Foundation
private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 255; result &*= prime }; return result }
private func row(_ output: SM64MetalCapOutput) -> [UInt64] { [UInt64(bitPattern: Int64(output.action)), UInt64(bitPattern: Int64(output.timer)), UInt64(bitPattern: Int64(output.faceYaw)), UInt64(output.gravity.bitPattern), UInt64(output.friction.bitPattern), UInt64(output.buoyancy.bitPattern), UInt64(bitPattern: Int64(output.opacity)), output.tangible ? 1 : 0, output.deactivated ? 1 : 0] }
@main struct SM64MetalCapSmoke {
    static func main() {
        let rolling = SM64MetalCapBehavior.update(.init(action: 0, timer: 0, faceYaw: 100, forwardVelocity: 2, interacted: false))
        let tangible = SM64MetalCapBehavior.update(.init(action: 0, timer: 21, faceYaw: 0, forwardVelocity: 0, interacted: false))
        let retired = SM64MetalCapBehavior.update(.init(action: 0, timer: 301, faceYaw: 0, forwardVelocity: 0, interacted: false))
        precondition(rolling.faceYaw == 356 && !rolling.tangible && tangible.tangible && retired.deactivated)
        var fingerprint = offset; for output in [rolling, tangible, retired] { for value in row(output) { fingerprint = hash(fingerprint, value) } }
        print(String(format: "metalCapFingerprint=0x%016llx", fingerprint)); print("SM64 Modern metal cap smoke passed")
    }
}
