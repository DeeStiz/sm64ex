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

private func hashState(_ initial: UInt64, _ result: SM64HeaveHoTickResult) -> UInt64 {
    let s = result.state
    let values: [UInt64] = [
        UInt64(result.effects.rawValue),
        UInt64(s.action.rawValue),
        UInt64(s.heldState.rawValue),
        UInt64(s.homeX.bitPattern), UInt64(s.homeY.bitPattern), UInt64(s.homeZ.bitPattern),
        UInt64(s.positionX.bitPattern), UInt64(s.positionY.bitPattern), UInt64(s.positionZ.bitPattern),
        UInt64(UInt16(bitPattern: s.moveYaw)),
        UInt64(s.forwardVelocity.bitPattern), UInt64(s.velocityY.bitPattern),
        UInt64(UInt32(bitPattern: s.animationState)), UInt64(s.throwState),
        UInt64(UInt32(bitPattern: s.collidedObjectCount)),
        UInt64(s.animationRate.bitPattern),
        s.tangible ? 1 : 0, s.hidden ? 1 : 0,
        s.markedForDeletion ? 1 : 0, UInt64(s.timer)
    ]
    return values.reduce(initial, hashU64)
}

private func hashChild(_ initial: UInt64, _ result: SM64HeaveHoThrowChildResult) -> UInt64 {
    let s = result.state
    let values: [UInt64] = [
        UInt64(result.effects.rawValue),
        UInt64(s.positionX.bitPattern), UInt64(s.positionY.bitPattern), UInt64(s.positionZ.bitPattern),
        UInt64(UInt16(bitPattern: s.moveYaw)), s.throwConsumed ? 1 : 0
    ]
    return values.reduce(initial, hashU64)
}

private func hashEffect(_ initial: UInt64, _ effect: SM64HeaveHoObjectEffectRecord) -> UInt64 {
    let values: [UInt64] = [
        UInt64(effect.objectID.traceSubject),
        UInt64(effect.kind.rawValue),
        UInt64(effect.effects.rawValue),
        UInt64(effect.action?.rawValue ?? 255),
        UInt64(effect.heldState?.rawValue ?? 255),
        effect.throwConsumed ? 1 : 0
    ]
    return values.reduce(initial, hashU64)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernHeaveHoObjectBridgeSmoke {
    static func main() throws {
        var fingerprint = fnvOffset

        var heaveHo = SM64HeaveHoState(homeX: 10, homeY: 20, homeZ: 30)
        let submerged = SM64HeaveHoKernel.tick(
            SM64HeaveHoTickInput(waterLevelBelowObject: false), state: &heaveHo
        )
        require(submerged.state.action == .submerged && submerged.state.hidden,
                "Heave Ho submerged")
        fingerprint = hashState(fingerprint, submerged)

        let wake = SM64HeaveHoKernel.tick(
            SM64HeaveHoTickInput(waterLevelBelowObject: true, distanceToMario: 500),
            state: &heaveHo
        )
        require(wake.state.action == .windUp && wake.state.tangible,
                "Heave Ho wake")
        fingerprint = hashState(fingerprint, wake)

        heaveHo.timer = 118
        let chase = SM64HeaveHoKernel.tick(
            SM64HeaveHoTickInput(waterLevelBelowObject: true, angleToMario: 0x4000),
            state: &heaveHo
        )
        require(chase.state.action == .chase,
                "Heave Ho chase")
        fingerprint = hashState(fingerprint, chase)

        let grabbed = SM64HeaveHoKernel.tick(
            SM64HeaveHoTickInput(grabbedMario: true), state: &heaveHo
        )
        require(grabbed.state.action == .throwMario && grabbed.effects.contains(.throwAnimation),
                "Heave Ho grab")
        fingerprint = hashState(fingerprint, grabbed)

        heaveHo.timer = 0
        let throwStart = SM64HeaveHoKernel.tick(SM64HeaveHoTickInput(), state: &heaveHo)
        require(throwStart.state.throwState == 2 && throwStart.effects.contains(.throwMario),
                "Heave Ho throw signal")
        fingerprint = hashState(fingerprint, throwStart)

        var child = SM64HeaveHoThrowChildState()
        let childResult = SM64HeaveHoKernel.tickThrowChild(parent: heaveHo, state: &child)
        require(childResult.effects.contains(.marioThrown) && childResult.state.positionX == 210,
                "Heave Ho throw child")
        fingerprint = hashChild(fingerprint, childResult)

        let waterDeath = SM64HeaveHoKernel.tick(
            SM64HeaveHoTickInput(moveFlags: SM64HeaveHoKernel.inWaterFlag), state: &heaveHo
        )
        require(waterDeath.state.action == .submerged && waterDeath.effects.contains(.waterSubmerge),
                "Heave Ho water return")
        fingerprint = hashState(fingerprint, waterDeath)

        let engineState = SM64SwiftEngineState(objectCapacity: 64)
        let bridge = SM64HeaveHoObjectBridge()
        let parentID = try bridge.spawnHeaveHo(
            in: engineState, homeX: 5, homeY: 10, homeZ: 15
        )
        require(parentID.traceSubject == 1, "stable Heave Ho slot")
        let bridgeTick = bridge.tick(
            state: engineState,
            inputs: [parentID: SM64HeaveHoTickInput(waterLevelBelowObject: true, distanceToMario: 500)]
        )
        guard let parentEffect = bridgeTick.effects.first(where: {
            $0.objectID == parentID && $0.kind == .heaveHo
        }) else { preconditionFailure("Heave Ho bridge parent missing") }
        require(parentEffect.action == .windUp, "Heave Ho bridge wake")
        fingerprint = hashEffect(fingerprint, parentEffect)
        guard let childID = bridge.registeredIDs.first(where: { $0 != parentID }),
              let childEffect = bridgeTick.effects.first(where: { $0.objectID == childID }) else {
            preconditionFailure("Heave Ho bridge child missing")
        }
        fingerprint = hashEffect(fingerprint, childEffect)

        print(String(format: "heaveHoObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Heave Ho object bridge smoke passed")
    }
}
