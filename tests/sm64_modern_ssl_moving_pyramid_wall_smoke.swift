import Foundation
private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 255; result &*= prime }; return result }
private func row(_ output: SM64SslMovingPyramidWallOutput) -> [UInt64] { [UInt64(bitPattern: Int64(output.action)), UInt64(bitPattern: Int64(output.timer)), UInt64(output.positionY.bitPattern), UInt64(output.velocityY.bitPattern)] }
@main struct SM64SslMovingPyramidWallSmoke {
    static func main() {
        let high = SM64SslMovingPyramidWallBehavior.initialize(1_000, start: .high)
        let middle = SM64SslMovingPyramidWallBehavior.initialize(1_000, start: .middle)
        let low = SM64SslMovingPyramidWallBehavior.initialize(1_000, start: .low)
        let down = SM64SslMovingPyramidWallBehavior.update(.init(action: 0, timer: 0, positionY: 1_000))
        let turn = SM64SslMovingPyramidWallBehavior.update(.init(action: 1, timer: 100, positionY: 1_000))
        precondition(high.action == 0 && high.timer == 0 && high.positionY == 1_000)
        precondition(middle.timer == 50 && middle.positionY == 744)
        precondition(low.action == 1 && low.positionY == 488)
        precondition(down.velocityY == -5.12 && down.positionY == 994.88 && turn.action == 0)
        var fingerprint = offset; for output in [down, turn] { for value in row(output) { fingerprint = hash(fingerprint, value) } }
        print(String(format: "sslMovingPyramidWallFingerprint=0x%016llx", fingerprint)); print("SM64 Modern SSL moving pyramid wall smoke passed")
    }
}
