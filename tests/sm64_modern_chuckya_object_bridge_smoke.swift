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

private func hashState(_ initial: UInt64, _ result: SM64ChuckyaTickResult) -> UInt64 {
    let s = result.state
    let values: [UInt64] = [
        UInt64(result.effects.rawValue), UInt64(s.action.rawValue),
        UInt64(s.heldState.rawValue),
        UInt64(s.homeX.bitPattern), UInt64(s.homeY.bitPattern), UInt64(s.homeZ.bitPattern),
        UInt64(s.positionX.bitPattern), UInt64(s.positionY.bitPattern), UInt64(s.positionZ.bitPattern),
        UInt64(UInt16(bitPattern: s.moveYaw)), UInt64(s.forwardVelocity.bitPattern), UInt64(s.velocityY.bitPattern),
        UInt64(s.subAction), UInt64(UInt32(bitPattern: s.actionCounter)),
        UInt64(UInt32(bitPattern: s.escapeCounter)), UInt64(s.throwState),
        UInt64(UInt32(bitPattern: s.animationState)),
        s.tangible ? 1 : 0, s.hidden ? 1 : 0, s.markedForDeletion ? 1 : 0, UInt64(s.timer)
    ]
    return values.reduce(initial, hashU64)
}

private func hashAnchor(_ initial: UInt64, _ result: SM64ChuckyaAnchorResult) -> UInt64 {
    let s = result.state
    let values: [UInt64] = [
        UInt64(result.effects.rawValue), UInt64(s.positionX.bitPattern),
        UInt64(s.positionY.bitPattern), UInt64(s.positionZ.bitPattern),
        UInt64(UInt16(bitPattern: s.moveYaw)), s.throwConsumed ? 1 : 0
    ]
    return values.reduce(initial, hashU64)
}

private func hashEffect(_ initial: UInt64, _ effect: SM64ChuckyaObjectEffectRecord) -> UInt64 {
    let values: [UInt64] = [
        UInt64(effect.objectID.traceSubject), UInt64(effect.kind.rawValue),
        UInt64(effect.effects.rawValue), UInt64(effect.action?.rawValue ?? 255),
        UInt64(effect.throwState ?? 255), effect.throwConsumed ? 1 : 0,
        effect.markedForDeletion ? 1 : 0
    ]
    return values.reduce(initial, hashU64)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernChuckyaObjectBridgeSmoke {
    static func main() throws {
        var fingerprint = fnvOffset
        var chuckya = SM64ChuckyaState(homeX: 10, homeY: 20, homeZ: 30)

        let idle = SM64ChuckyaKernel.tick(
            SM64ChuckyaTickInput(distanceFromMarioHome: 3_000), state: &chuckya
        )
        require(idle.state.action == .patrol, "Chuckya patrol")
        fingerprint = hashState(fingerprint, idle)

        let approach = SM64ChuckyaKernel.tick(
            SM64ChuckyaTickInput(distanceFromMarioHome: 1_000, angleToMario: 0), state: &chuckya
        )
        require(approach.state.subAction == 1 && approach.state.forwardVelocity == 4,
                "Chuckya approach")
        fingerprint = hashState(fingerprint, approach)

        let grabbed = SM64ChuckyaKernel.tick(
            SM64ChuckyaTickInput(grabbedMario: true), state: &chuckya
        )
        require(grabbed.state.action == .grab && grabbed.state.throwState == 1,
                "Chuckya grab")
        fingerprint = hashState(fingerprint, grabbed)

        chuckya.subAction = 1
        let released = SM64ChuckyaKernel.tick(
            SM64ChuckyaTickInput(animationFrame: 18), state: &chuckya
        )
        require(released.state.action == .throwMario && released.state.throwState == 2,
                "Chuckya release")
        fingerprint = hashState(fingerprint, released)

        var anchor = SM64ChuckyaAnchorState()
        let anchorResult = SM64ChuckyaKernel.tickAnchor(parent: chuckya, state: &anchor)
        require(anchorResult.effects.contains(.throwMario) && anchorResult.state.positionZ > 150,
                "Chuckya anchor")
        fingerprint = hashAnchor(fingerprint, anchorResult)

        chuckya.action = .death
        let death = SM64ChuckyaKernel.tick(
            SM64ChuckyaTickInput(floorCollisionFlags: SM64ChuckyaKernel.hitWallFlag),
            state: &chuckya
        )
        require(death.state.markedForDeletion && death.effects.contains(.coins),
                "Chuckya collision death")
        fingerprint = hashState(fingerprint, death)

        let engineState = SM64SwiftEngineState(objectCapacity: 64)
        let bridge = SM64ChuckyaObjectBridge()
        let parentID = try bridge.spawnChuckya(in: engineState, homeX: 5, homeY: 10, homeZ: 15)
        require(parentID.traceSubject == 1, "stable Chuckya slot")
        let bridgeTick = bridge.tick(
            state: engineState,
            inputs: [parentID: SM64ChuckyaTickInput(distanceFromMarioHome: 1_000, angleToMario: 0)]
        )
        guard let parentEffect = bridgeTick.effects.first(where: {
            $0.objectID == parentID && $0.kind == .chuckya
        }) else { preconditionFailure("Chuckya bridge parent missing") }
        fingerprint = hashEffect(fingerprint, parentEffect)
        guard let anchorID = bridge.registeredIDs.first(where: { $0 != parentID }),
              let anchorEffect = bridgeTick.effects.first(where: { $0.objectID == anchorID }) else {
            preconditionFailure("Chuckya bridge anchor missing")
        }
        fingerprint = hashEffect(fingerprint, anchorEffect)

        print(String(format: "chuckyaObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Chuckya object bridge smoke passed")
    }
}
