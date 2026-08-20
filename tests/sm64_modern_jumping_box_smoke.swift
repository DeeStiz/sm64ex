import Foundation

private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211

private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 {
    var result = seed
    for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 255; result &*= prime }
    return result
}

private func row(_ output: SM64JumpingBoxOutput) -> [UInt64] {
    [UInt64(bitPattern: Int64(output.action)), UInt64(bitPattern: Int64(output.timer)), UInt64(bitPattern: Int64(output.subAction)), UInt64(output.position.y.bitPattern), UInt64(output.velocityY.bitPattern), UInt64(output.model), output.visible ? 1 : 0, output.shouldDelete ? 1 : 0, output.explode ? 1 : 0, output.jump ? 1 : 0]
}

@main
struct SM64JumpingBoxSmoke {
    static func main() {
        let free = SM64JumpingBoxBehavior.update(.init(action: 0, timer: 0, subAction: 0, heldState: 0, position: .zero, marioPosition: .zero, velocityY: 0, countdown: 30, threshold: 60, onGround: false, hitWall: false, inWater: false, landed: false, stopRiding: false))
        let jump = SM64JumpingBoxBehavior.update(.init(action: 0, timer: 61, subAction: 0, heldState: 0, position: .zero, marioPosition: .zero, velocityY: 0, countdown: 30, threshold: 60, onGround: false, hitWall: false, inWater: false, landed: false, stopRiding: false))
        let held = SM64JumpingBoxBehavior.update(.init(action: 0, timer: 0, subAction: 0, heldState: 1, position: .zero, marioPosition: .init(x: 1, y: 2, z: 3), velocityY: 0, countdown: 30, threshold: 60, onGround: false, hitWall: false, inWater: false, landed: false, stopRiding: false))
        let dead = SM64JumpingBoxBehavior.update(.init(action: 1, timer: 3, subAction: 0, heldState: 0, position: .zero, marioPosition: .zero, velocityY: 0, countdown: 0, threshold: 60, onGround: false, hitWall: true, inWater: false, landed: false, stopRiding: false))
        precondition(free.action == 0 && free.velocityY == -4)
        precondition(jump.jump && jump.velocityY == 15)
        precondition(held.model == 0x3A && !held.visible && held.position == .init(x: 1, y: 2, z: 3))
        precondition(dead.shouldDelete)
        var fingerprint = offset
        for output in [free, jump, held, dead] { for value in row(output) { fingerprint = hash(fingerprint, value) } }
        print(String(format: "jumpingBoxFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Jumping Box smoke passed")
    }
}
