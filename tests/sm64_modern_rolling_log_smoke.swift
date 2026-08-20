import Foundation
private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 255; result &*= prime }; return result }
private func row(_ output: SM64RollingLogOutput) -> [UInt64] { [UInt64(output.position.x.bitPattern), UInt64(output.position.z.bitPattern), UInt64(output.velocity.x.bitPattern), UInt64(output.velocity.z.bitPattern), UInt64(output.forwardVelocity.bitPattern), UInt64(bitPattern: Int64(output.angleVelocityPitch)), UInt64(bitPattern: Int64(output.facePitch)), output.hitBoundary ? 1 : 0, output.playRollSound ? 1 : 0] }
@main struct SM64RollingLogSmoke {
    static func main() {
        let platform = SM64RollingLogBehavior.update(.init(variant: .ttm, position: .init(x: 3_970, y: 0, z: 3_654), homePosition: .zero, moveYaw: 0, angleVelocityPitch: 0, facePitch: 0, marioIsPlatform: true, marioPosition: .init(x: 3_970, y: 0, z: 3_754), nearHome: false))
        let damping = SM64RollingLogBehavior.update(.init(variant: .lll, position: .init(x: 5_120, y: 0, z: 6_016), homePosition: .zero, moveYaw: 0, angleVelocityPitch: 0, facePitch: 0, marioIsPlatform: false, marioPosition: .zero, nearHome: false))
        let boundary = SM64RollingLogBehavior.update(.init(variant: .ttm, position: .init(x: 5_500, y: 0, z: 3_654), homePosition: .zero, moveYaw: 0, angleVelocityPitch: 0x200, facePitch: 0, marioIsPlatform: true, marioPosition: .init(x: 5_500, y: 0, z: 3_754), nearHome: false))
        precondition(platform.angleVelocityPitch == 0x10 && platform.position.z == 3_654.25 && platform.playRollSound && !platform.hitBoundary)
        precondition(damping.angleVelocityPitch == 0x10 && damping.position.z == 6_016.25 && !damping.hitBoundary)
        precondition(boundary.hitBoundary && boundary.velocity == .zero && boundary.position.x == 5_500)
        var fingerprint = offset
        for output in [platform, damping, boundary] { for value in row(output) { fingerprint = hash(fingerprint, value) } }
        print(String(format: "rollingLogFingerprint=0x%016llx", fingerprint)); print("SM64 Modern rolling log smoke passed")
    }
}
