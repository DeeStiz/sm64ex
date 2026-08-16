import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 {
        hash ^= (value >> UInt64(byte * 8)) & 0xff
        hash &*= fnvPrime
    }
    return hash
}

private func hashOutput(_ initial: UInt64, _ effect: SM64TuxiesMotherObjectEffect) -> UInt64 {
    var hash = hashU64(initial, UInt64(bitPattern: Int64(effect.output.action)))
    hash = hashU64(hash, UInt64(effect.output.forwardVelocity.bitPattern))
    return hashU64(hash, UInt64(bitPattern: Int64(effect.eyesSelectedCase)))
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func environment(
    childHeldState: Int32,
    dialogResult: Int32 = 0,
    nearbyHeldActor: Bool = false,
    lateralDistanceToMarioHome: Float = 600,
    globalTimer: UInt64 = 45
) -> SM64TuxiesMotherEnvironment {
    SM64TuxiesMotherEnvironment(
        motherBehaviorParam: 1,
        childBehaviorParam: 1,
        childExists: true,
        childDistance: childHeldState == 0 ? 600 : 250,
        childHeldState: childHeldState,
        nearbyHeldActor: nearbyHeldActor,
        lateralDistanceToMarioHome: lateralDistanceToMarioHome,
        dialogResult: dialogResult,
        globalTimer: globalTimer
    )
}

@main
enum SM64ModernTuxiesMotherEyesObjectBridgeSmoke {
    static func main() throws {
        let state = SM64SwiftEngineState(objectCapacity: 8)
        let bridge = SM64TuxiesMotherObjectBridge()
        let mother = try bridge.spawnMother(in: state)
        let child = try bridge.spawnSmallPenguin(in: state, parent: mother)
        require(bridge.attachChild(child, to: mother, in: state.objects), "eyes child attachment")
        var fingerprint = fnvOffset

        let carried = bridge.tick(
            state: state,
            environments: [mother: environment(childHeldState: 1)]
        )
        require(carried.effects.first?.eyesSelectedCase == SM64TuxiesMotherEyes.closedCase, "stationary blink case")
        fingerprint = hashOutput(fingerprint, carried.effects[0])

        _ = state.objects.mutate(child) { record in record.heldState = 1 }
        let accepted = bridge.tick(
            state: state,
            environments: [mother: environment(childHeldState: 1, dialogResult: 1)]
        )
        require(accepted.effects.first?.eyesSelectedCase == SM64TuxiesMotherEyes.closedCase, "carry dialog blink source")
        fingerprint = hashOutput(fingerprint, accepted.effects[0])

        _ = state.objects.mutate(child) { record in record.heldState = 0 }
        let chaseEntry = bridge.tick(
            state: state,
            environments: [mother: environment(childHeldState: 0)]
        )
        require(chaseEntry.effects.first?.output.action == SM64TuxiesMotherBehavior.chaseMario, "reward branch enters chase")
        require(chaseEntry.effects.first?.eyesSelectedCase == SM64TuxiesMotherEyes.closedCase, "chase entry has no velocity yet")
        fingerprint = hashOutput(fingerprint, chaseEntry.effects[0])

        let settle = bridge.tick(
            state: state,
            environments: [mother: environment(childHeldState: 0, nearbyHeldActor: true, lateralDistanceToMarioHome: 600)]
        )
        require(settle.effects.first?.output.forwardVelocity == 0, "chase subaction settles before walking")
        fingerprint = hashOutput(fingerprint, settle.effects[0])

        let angry = bridge.tick(
            state: state,
            environments: [mother: environment(childHeldState: 0, nearbyHeldActor: true, lateralDistanceToMarioHome: 900)]
        )
        guard let effect = angry.effects.first else { preconditionFailure("eyes bridge effect missing") }
        require(effect.output.forwardVelocity == 10, "chase walking velocity publication")
        require(effect.eyesSelectedCase == SM64TuxiesMotherEyes.angryCase, "owner bridge publishes angry eye case")
        fingerprint = hashOutput(fingerprint, effect)

        print(String(format: "tuxiesMotherEyesObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Tuxie's mother eyes object bridge smoke passed")
    }
}
