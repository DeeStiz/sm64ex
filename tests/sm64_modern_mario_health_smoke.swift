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

private func hashMutation(_ initial: UInt64, _ mutation: SM64MarioHealthMutation) -> UInt64 {
    var hash = hashU16(initial, UInt16(bitPattern: mutation.health))
    hash = hashU8(hash, mutation.healCounter)
    hash = hashU8(hash, mutation.hurtCounter)
    return hashU8(hash, mutation.nearDrowningRumble ? 1 : 0)
}

@main
enum SM64ModernMarioHealthSmoke {
    static func main() {
        var poison = SM64MarioState()
        poison.health = 0x400
        poison.input = [.inPoisonGas]
        let poisonResult = poison.updateHealth(
            context: SM64MarioHealthContext(terrainType: 0, debugLevelSelect: false)
        )
        precondition(poisonResult.health == 0x3FC && !poisonResult.nearDrowningRumble, "poison damage")

        var surface = SM64MarioState()
        surface.action = SM64MarioAction.waterIdle
        surface.health = 0x870
        surface.position.y = 0
        surface.waterLevel = 100
        let surfaceResult = surface.updateHealth(
            context: SM64MarioHealthContext(terrainType: 0, debugLevelSelect: false)
        )
        precondition(surfaceResult.health == 0x880, "surface recovery clamp")

        var snow = SM64MarioState()
        snow.action = SM64MarioAction.waterIdle
        snow.health = 0x250
        snow.position.y = -200
        snow.waterLevel = 100
        let snowResult = snow.updateHealth(
            context: SM64MarioHealthContext(terrainType: 0x0002, debugLevelSelect: false)
        )
        precondition(snowResult.health == 0x24D && snowResult.nearDrowningRumble, "snow drain and rumble")

        var counters = SM64MarioState()
        counters.health = 0x500
        counters.healCounter = 2
        counters.hurtCounter = 1
        let counterResult = counters.updateHealth(
            context: SM64MarioHealthContext(terrainType: 0, debugLevelSelect: false)
        )
        precondition(counterResult.health == 0x500 && counterResult.healCounter == 1 && counterResult.hurtCounter == 0, "counter mutation")

        var terminal = SM64MarioState()
        terminal.action = SM64MarioAction.waterIdle
        terminal.health = 0xFF
        let terminalResult = terminal.updateHealth(
            context: SM64MarioHealthContext(terrainType: 0, debugLevelSelect: false)
        )
        precondition(terminalResult.health == 0xFF && !terminalResult.nearDrowningRumble, "terminal health guard")

        var fingerprint = fnvOffset
        fingerprint = hashMutation(fingerprint, poisonResult)
        fingerprint = hashMutation(fingerprint, surfaceResult)
        fingerprint = hashMutation(fingerprint, snowResult)
        fingerprint = hashMutation(fingerprint, counterResult)
        fingerprint = hashMutation(fingerprint, terminalResult)
        print(String(format: "marioHealthFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario health smoke passed")
    }
}
