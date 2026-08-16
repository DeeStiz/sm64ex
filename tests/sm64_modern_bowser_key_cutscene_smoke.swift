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

private func hashFloat(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU64(initial, UInt64(value.bitPattern))
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func hashValue(_ initial: UInt64, _ result: SM64BowserKeyCutsceneTickResult) -> UInt64 {
    var hash = hashU64(initial, UInt64(result.effects.rawValue))
    hash = hashU64(hash, UInt64(result.state.kind.rawValue))
    hash = hashU64(hash, UInt64(result.state.timer))
    hash = hashU64(hash, UInt64(bitPattern: Int64(result.state.animationFrame)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(result.state.animation)))
    hash = hashFloat(hash, result.state.scale)
    return hashU64(hash, result.state.markedForDeletion ? 1 : 0)
}

@main
enum SM64ModernBowserKeyCutsceneSmoke {
    static func main() throws {
        var fingerprint = fnvOffset
        var unlock = SM64BowserKeyCutsceneState(kind: .unlockDoor)
        let unlockHidden = SM64BowserKeyCutsceneKernel.tick(
            SM64BowserKeyCutsceneTickInput(animationFrame: 37),
            state: &unlock
        )
        require(unlockHidden.state.animation == 0 && unlockHidden.state.scale == 0, "unlock hidden scale")
        require(unlockHidden.effects.contains(.setAnimation), "unlock animation effect")
        fingerprint = hashValue(fingerprint, unlockHidden)

        let unlockGrow = SM64BowserKeyCutsceneKernel.tick(
            SM64BowserKeyCutsceneTickInput(animationFrame: 57),
            state: &unlock
        )
        require(abs(unlockGrow.state.scale - 0.675) < 0.0001, "unlock growth scale")
        fingerprint = hashValue(fingerprint, unlockGrow)

        unlock.timer = 151
        let unlockDelete = SM64BowserKeyCutsceneKernel.tick(
            SM64BowserKeyCutsceneTickInput(animationFrame: 60),
            state: &unlock
        )
        require(unlockDelete.state.scale == 1 && unlockDelete.state.markedForDeletion, "unlock final/delete")
        require(unlockDelete.effects.contains(.markForDeletion), "unlock delete effect")
        fingerprint = hashValue(fingerprint, unlockDelete)

        var courseExit = SM64BowserKeyCutsceneState(kind: .courseExit)
        let courseOpen = SM64BowserKeyCutsceneKernel.tick(
            SM64BowserKeyCutsceneTickInput(animationFrame: 51),
            state: &courseExit
        )
        require(courseOpen.state.animation == 1, "course exit animation")
        require(abs(courseOpen.state.scale - 0.585714) < 0.0001, "course exit growth")
        fingerprint = hashValue(fingerprint, courseOpen)

        let courseHold = SM64BowserKeyCutsceneKernel.tick(
            SM64BowserKeyCutsceneTickInput(animationFrame: 93),
            state: &courseExit
        )
        require(courseHold.state.scale == 0.8, "course exit hold")
        fingerprint = hashValue(fingerprint, courseHold)

        courseExit.timer = 139
        let courseDelete = SM64BowserKeyCutsceneKernel.tick(
            SM64BowserKeyCutsceneTickInput(animationFrame: 101),
            state: &courseExit
        )
        require(courseDelete.state.scale == 0.2 && courseDelete.state.markedForDeletion, "course exit delete")
        fingerprint = hashValue(fingerprint, courseDelete)

        let engine = SM64SwiftEngineState(objectCapacity: 8)
        let bridge = SM64BowserKeyCutsceneObjectBridge()
        let id = try bridge.spawn(
            kind: .courseExit,
            in: engine,
            position: SM64ObjectVector3(x: 4, y: 5, z: 6)
        )
        let tick = bridge.tick(
            state: engine,
            inputs: [id: SM64BowserKeyCutsceneTickInput(animationFrame: 93)]
        )
        guard let effect = tick.effects.first,
              let record = engine.objects.record(for: id) else {
            preconditionFailure("key cutscene owner record missing")
        }
        require(effect.kind == .courseExit && effect.animation == 1, "key cutscene owner animation")
        require(record.scale == SM64ObjectVector3(x: 0.8, y: 0.8, z: 0.8), "key cutscene owner scale")
        require(record.animationState == 1, "key cutscene owner animation record")
        fingerprint = hashU64(fingerprint, UInt64(effect.objectID.traceSubject))
        fingerprint = hashU64(fingerprint, UInt64(effect.effects.rawValue))
        fingerprint = hashFloat(fingerprint, record.scale.x)
        fingerprint = hashU64(fingerprint, UInt64(record.animationState))

        var dying = bridge.state(for: id)!
        dying.timer = 139
        require(bridge.setState(dying, for: id, in: engine.objects), "key cutscene dying state")
        let deleteTick = bridge.tick(
            state: engine,
            inputs: [id: SM64BowserKeyCutsceneTickInput(animationFrame: 101)]
        )
        require(deleteTick.scheduler.unloaded == [id], "key cutscene owner unload")
        require(deleteTick.effects.first?.markedForDeletion == true, "key cutscene owner deletion")
        fingerprint = hashU64(fingerprint, UInt64(deleteTick.effects.first!.effects.rawValue))
        fingerprint = hashU64(fingerprint, UInt64(deleteTick.scheduler.unloaded.count))

        print(String(format: "bowserKeyCutsceneFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Bowser key cutscene smoke passed")
    }
}
