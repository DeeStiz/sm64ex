import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 {
    var result = seed
    for index in 0..<8 {
        result ^= (value >> UInt64(index * 8)) & 0xff
        result &*= fnvPrime
    }
    return result
}

private func cloudInput(
    kind: SM64CloudKind = .fwoosh,
    action: SM64CloudAction = .spawnParts,
    parentActive: Bool = true,
    distanceToMario: Float = 1_000,
    scale: Float = 3,
    movementRadius: Int32 = 0,
    globalFrame: UInt64 = 0,
    timer: Int32 = 0,
    blowing: Bool = false,
    growSpeed: Float = 0
) -> SM64CloudInput {
    let position = SM64ObjectVector3(x: 10, y: 20, z: -4)
    return .init(
        kind: kind,
        action: action,
        position: position,
        homePosition: position,
        parentPosition: .init(x: 100, y: 200, z: 300),
        parentActive: parentActive,
        parentFaceYaw: 0x1000,
        distanceToMario: distanceToMario,
        scale: scale,
        movementRadius: movementRadius,
        globalFrame: globalFrame,
        timer: timer,
        blowing: blowing,
        growSpeed: growSpeed
    )
}

@main
struct SM64CloudSmoke {
    static func main() {
        let spawn = SM64CloudBehavior.update(cloudInput())
        precondition(spawn.action == .main && spawn.childPartCount == 6 && spawn.scale == 3 && !spawn.shouldDelete)

        let startBlow = SM64CloudBehavior.update(cloudInput(action: .main, distanceToMario: 999, timer: 101))
        precondition(startBlow.blowing && startBlow.growSpeed == 0.14 && startBlow.movementRadius == 200)

        let blow = SM64CloudBehavior.update(cloudInput(action: .main, scale: 3, globalFrame: 1, timer: 9, blowing: true, growSpeed: -0.11))
        precondition(blow.soundIntent == .blow && blow.spawnWindParticles && blow.scale == 2.89 && blow.growSpeed == -0.115)

        let stop = SM64CloudBehavior.update(cloudInput(action: .main, scale: 2, timer: 5, blowing: true, growSpeed: -0.159))
        precondition(!stop.blowing && stop.timer == 0 && stop.growSpeed == 0)

        let far = SM64CloudBehavior.update(cloudInput(action: .main, distanceToMario: 2_501))
        precondition(far.action == .fwooshHidden && far.hidden && far.position == SM64ObjectVector3(x: 10, y: 20, z: -4))

        let hiddenClose = SM64CloudBehavior.update(cloudInput(action: .fwooshHidden, distanceToMario: 1_999))
        precondition(hiddenClose.action == .spawnParts && !hiddenClose.hidden)

        let lakituUnload = SM64CloudBehavior.update(cloudInput(kind: .lakitu, action: .main, parentActive: false))
        precondition(lakituUnload.shouldDelete && lakituUnload.action == .unload)

        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, UInt64(spawn.childPartCount))
        fingerprint = hash(fingerprint, UInt64(spawn.action.rawValue))
        fingerprint = hash(fingerprint, UInt64(spawn.scale.bitPattern))
        fingerprint = hash(fingerprint, UInt64(startBlow.blowing ? 1 : 0))
        fingerprint = hash(fingerprint, UInt64(startBlow.growSpeed.bitPattern))
        fingerprint = hash(fingerprint, UInt64(startBlow.movementRadius))
        fingerprint = hash(fingerprint, UInt64(blow.soundIntent.rawValue))
        fingerprint = hash(fingerprint, UInt64(blow.spawnWindParticles ? 1 : 0))
        fingerprint = hash(fingerprint, UInt64(blow.scale.bitPattern))
        fingerprint = hash(fingerprint, UInt64(blow.growSpeed.bitPattern))
        fingerprint = hash(fingerprint, UInt64(stop.blowing ? 1 : 0))
        fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(stop.timer)))
        fingerprint = hash(fingerprint, UInt64(stop.growSpeed.bitPattern))
        fingerprint = hash(fingerprint, UInt64(far.action.rawValue))
        fingerprint = hash(fingerprint, UInt64(far.hidden ? 1 : 0))
        fingerprint = hash(fingerprint, UInt64(hiddenClose.action.rawValue))
        fingerprint = hash(fingerprint, UInt64(lakituUnload.shouldDelete ? 1 : 0))
        print(String(format: "cloudFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern cloud smoke passed")
    }
}
