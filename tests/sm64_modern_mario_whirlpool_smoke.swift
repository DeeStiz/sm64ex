import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func hFloat(_ h: UInt64, _ v: Float) -> UInt64 { h32(h, v.bitPattern) }

private func hash(_ h: UInt64, _ r: SM64MarioWhirlpoolActionResult) -> UInt64 {
    var x = h8(h, r.intent.rawValue)
    x = hFloat(x, r.position.x); x = hFloat(x, r.position.y); x = hFloat(x, r.position.z)
    x = hFloat(x, r.whirlpoolOffsetY); x = hFloat(x, r.velocityY)
    x = h16(x, UInt16(bitPattern: r.faceYaw)); x = h16(x, r.actionTimer)
    x = h16(x, r.animationID); x = h8(x, r.shouldSyncGraphics ? 1 : 0)
    x = h8(x, r.shouldResetRumble ? 1 : 0)
    return h8(x, r.shouldTriggerDeathWarp ? 1 : 0)
}

private func input(
    position: SM64ObjectVector3 = .init(x: 40, y: 120, z: -25),
    whirlpoolPosition: SM64ObjectVector3 = .init(x: 0, y: 100, z: 0),
    whirlpoolOffsetY: Float = 20,
    velocityY: Float = -2,
    faceYaw: Int16 = 0x2000,
    actionTimer: UInt16 = 0
) -> SM64MarioWhirlpoolActionInput {
    SM64MarioWhirlpoolActionInput(
        position: position, whirlpoolPosition: whirlpoolPosition,
        whirlpoolOffsetY: whirlpoolOffsetY, velocityY: velocityY,
        faceYaw: faceYaw, actionTimer: actionTimer
    )
}

@main
enum SM64ModernMarioWhirlpoolSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let orbit = SM64MarioWhirlpoolAction.update(input())!
        precondition(orbit.intent == .continueAction)
        precondition(orbit.animationID == 0x56)
        precondition(orbit.shouldSyncGraphics && orbit.shouldResetRumble)
        precondition(orbit.position.y == 118)
        fingerprint = hash(fingerprint, orbit)

        let inner = SM64MarioWhirlpoolAction.update(input(
            position: .init(x: 8, y: 100, z: 4), whirlpoolOffsetY: -2,
            velocityY: -1, actionTimer: 16
        ))!
        precondition(inner.intent == .deathWarp && inner.shouldTriggerDeathWarp)
        precondition(inner.actionTimer == 17 && inner.whirlpoolOffsetY == 0)
        fingerprint = hash(fingerprint, inner)

        let center = SM64MarioWhirlpoolAction.update(input(
            position: .init(x: 0, y: 100, z: 0), whirlpoolOffsetY: 1,
            velocityY: -2, faceYaw: 0
        ))!
        precondition(center.position.x.isFinite && center.position.z.isFinite)
        precondition(center.position.y == 100)
        fingerprint = hash(fingerprint, center)

        let distant = SM64MarioWhirlpoolAction.update(input(
            position: .init(x: 400, y: 0, z: 0), whirlpoolOffsetY: 0,
            velocityY: 0
        ))!
        precondition(distant.velocityY < 0 && distant.intent == .continueAction)
        fingerprint = hash(fingerprint, distant)

        precondition(SM64MarioWhirlpoolAction.update(input(
            position: .init(x: .infinity, y: 0, z: 0)
        )) == nil)

        print(String(format: "marioWhirlpoolFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario whirlpool smoke passed")
    }
}
