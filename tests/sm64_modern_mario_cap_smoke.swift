import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU8(_ initial: UInt64, _ value: UInt8) -> UInt64 {
    var hash = initial; hash ^= UInt64(value); hash &*= fnvPrime; return hash
}

private func hashU16(_ initial: UInt64, _ value: UInt16) -> UInt64 {
    var hash = initial
    for byte in 0..<2 { hash ^= UInt64((value >> UInt16(byte * 8)) & 0xff); hash &*= fnvPrime }
    return hash
}

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for byte in 0..<4 { hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff); hash &*= fnvPrime }
    return hash
}

private func hashMutation(_ initial: UInt64, _ mutation: SM64MarioCapMutation) -> UInt64 {
    var hash = hashU16(initial, mutation.capTimer)
    hash = hashU32(hash, mutation.flags)
    hash = hashU32(hash, mutation.renderFlags)
    hash = hashU8(hash, mutation.didExpire ? 1 : 0)
    hash = hashU8(hash, mutation.shouldFadeOutMusic ? 1 : 0)
    return hashU8(hash, mutation.didFlicker ? 1 : 0)
}

@main
enum SM64ModernMarioCapSmoke {
    static func main() {
        var fingerprint = fnvOffset

        var initialMetal = SM64MarioState()
        fingerprint = hashMutation(
            fingerprint,
            initialMetal.applyInitialCapPowerup(courseIndex: 20)!
        )
        precondition(initialMetal.capTimer == 600)
        precondition(initialMetal.flags == 0x14, "metal course flags")

        var initialWing = SM64MarioState()
        fingerprint = hashMutation(
            fingerprint,
            initialWing.applyInitialCapPowerup(courseIndex: 21)!
        )
        precondition(initialWing.capTimer == 1200)
        precondition(initialWing.flags == 0x18, "wing course flags")

        var initialVanish = SM64MarioState()
        fingerprint = hashMutation(
            fingerprint,
            initialVanish.applyInitialCapPowerup(courseIndex: 22)!
        )
        precondition(initialVanish.capTimer == 600)
        precondition(initialVanish.flags == 0x12, "vanish course flags")

        var paused = SM64MarioState()
        paused.flags = SM64MarioCapFlags.metal.rawValue | SM64MarioCapFlags.onHead.rawValue
        paused.capTimer = 100
        paused.action = 0x20001305 // ACT_READING_AUTOMATIC_DIALOG
        let pausedMutation = paused.tickCapTimer()
        fingerprint = hashMutation(fingerprint, pausedMutation)
        precondition(pausedMutation.capTimer == 100 && !pausedMutation.didFlicker)

        var fading = SM64MarioState()
        fading.flags = SM64MarioCapFlags.metal.rawValue | SM64MarioCapFlags.onHead.rawValue
        fading.capTimer = 61
        let fadingMutation = fading.tickCapTimer()
        fingerprint = hashMutation(fingerprint, fadingMutation)
        precondition(fadingMutation.capTimer == 60 && fadingMutation.shouldFadeOutMusic)

        var expiring = SM64MarioState()
        expiring.flags = SM64MarioCapFlags.metal.rawValue | SM64MarioCapFlags.onHead.rawValue
        expiring.capTimer = 1
        let expiringMutation = expiring.tickCapTimer()
        fingerprint = hashMutation(fingerprint, expiringMutation)
        precondition(expiringMutation.capTimer == 0 && expiringMutation.didExpire)
        precondition(expiring.flags == 0 && expiringMutation.renderFlags == 0, "temporary cap expiration")

        var pickup = SM64MarioState()
        pickup.flags = SM64MarioCapFlags.normal.rawValue | SM64MarioCapFlags.onHead.rawValue
        pickup.capTimer = 10
        let pickupMutation = pickup.applyCapPowerup(.wing)
        fingerprint = hashMutation(fingerprint, pickupMutation)
        precondition(pickup.capTimer == 1800 && pickup.flags == 0x09, "pickup timer and flags")

        var unsupported = SM64MarioState()
        precondition(unsupported.applyInitialCapPowerup(courseIndex: 19) == nil)
        print(String(format: "marioCapFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario cap smoke passed")
    }
}
