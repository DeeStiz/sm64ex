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

private func hashKernel(_ initial: UInt64, _ result: SM64BirdTickResult) -> UInt64 {
    let state = result.state
    var hash = hashU64(initial, UInt64(result.effects.rawValue))
    hash = hashU64(hash, UInt64(state.kind.rawValue))
    hash = hashU64(hash, UInt64(state.action.rawValue))
    hash = hashU64(hash, UInt64(state.positionX.bitPattern))
    hash = hashU64(hash, UInt64(state.positionY.bitPattern))
    hash = hashU64(hash, UInt64(state.positionZ.bitPattern))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.moveYaw)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.movePitch)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.faceRoll)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.targetYaw)))
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.targetPitch)))
    hash = hashU64(hash, UInt64(state.birdSpeed.bitPattern))
    hash = hashU64(hash, UInt64(state.forwardVelocity.bitPattern))
    hash = hashU64(hash, UInt64(state.velocityY.bitPattern))
    hash = hashU64(hash, UInt64(state.timer))
    hash = hashU64(hash, state.invisible ? 1 : 0)
    return hashU64(hash, state.markedForDeletion ? 1 : 0)
}

private func hashBridgeTick(
    _ initial: UInt64,
    _ tick: SM64BirdSchedulerTickResult,
    records: [SM64ObjectRecord?]
) -> UInt64 {
    let scheduler = tick.scheduler
    var hash = hashU64(initial, scheduler.frame)
    for count in scheduler.listCounts { hash = hashU64(hash, UInt64(count)) }
    hash = hashU64(hash, UInt64(scheduler.objectCounter))
    hash = hashU64(hash, UInt64(scheduler.updated.count))
    for id in scheduler.updated { hash = hashU64(hash, UInt64(id.traceSubject)) }
    hash = hashU64(hash, UInt64(scheduler.unloaded.count))
    for id in scheduler.unloaded { hash = hashU64(hash, UInt64(id.traceSubject)) }
    hash = hashU64(hash, UInt64(tick.effects.count))
    for effect in tick.effects {
        hash = hashU64(hash, UInt64(effect.objectID.traceSubject))
        hash = hashU64(hash, UInt64(effect.kind.rawValue))
        hash = hashU64(hash, UInt64(effect.effects.rawValue))
        hash = hashU64(hash, UInt64(effect.action.rawValue))
        hash = hashU64(hash, UInt64(effect.spawnedChildren.count))
        for child in effect.spawnedChildren {
            hash = hashU64(hash, UInt64(child.traceSubject))
        }
        hash = hashU64(hash, effect.markedForDeletion ? 1 : 0)
    }
    for record in records {
        guard let record else {
            hash = hashU64(hash, 0)
            continue
        }
        hash = hashU64(hash, 1)
        hash = hashU64(hash, UInt64(record.action))
        hash = hashU64(hash, UInt64(record.previousAction))
        hash = hashU64(hash, UInt64(record.timer))
        hash = hashU64(hash, UInt64(record.position.x.bitPattern))
        hash = hashU64(hash, UInt64(record.position.y.bitPattern))
        hash = hashU64(hash, UInt64(record.position.z.bitPattern))
        hash = hashU64(hash, UInt64(UInt32(bitPattern: record.moveAngles.yaw)))
        hash = hashU64(hash, UInt64(UInt32(bitPattern: record.moveAngles.pitch)))
        hash = hashU64(hash, UInt64(UInt32(bitPattern: record.faceAngles.roll)))
        hash = hashU64(hash, UInt64(record.graphFlags))
    }
    return hash
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernBirdObjectBridgeSmoke {
    static func main() throws {
        var fingerprint = fnvOffset

        var spawner = SM64BirdState(kind: .spawner, homeX: 100, homeY: 200, homeZ: 300)
        let far = SM64BirdKernel.tick(
            SM64BirdTickInput(distanceToMario: 2_000),
            state: &spawner
        )
        require(far.state.action == .inactive && far.state.invisible, "far bird remains inactive")
        fingerprint = hashKernel(fingerprint, far)

        let reveal = SM64BirdKernel.tick(
            SM64BirdTickInput(
                distanceToMario: 1_999,
                initialMoveYaw: 0x1000,
                initialMovePitch: 2_000,
                homeDistance: 300,
                homeYaw: 0x2000
            ),
            state: &spawner
        )
        require(reveal.state.action == .fly && !reveal.state.invisible, "spawner reveal")
        require(reveal.effects.contains(.spawnChildren) && reveal.effects.contains(.flyAwaySound), "bird spawn effects")
        require(reveal.state.homeX == -20 && reveal.state.homeZ == -3_990, "bird target home")
        fingerprint = hashKernel(fingerprint, reveal)

        let flight = SM64BirdKernel.tick(
            SM64BirdTickInput(homeDistance: 100, homeYaw: 0),
            state: &spawner
        )
        require(flight.state.forwardVelocity > 0 && flight.state.positionZ > 300, "bird flight movement")
        require(flight.state.targetYaw == 0, "bird home yaw")
        fingerprint = hashKernel(fingerprint, flight)

        var child = SM64BirdState(kind: .spawned, homeY: 500, positionY: 500, invisible: true)
        let childReveal = SM64BirdKernel.tick(
            SM64BirdTickInput(initialMoveYaw: 0x4000, initialMovePitch: 1_000),
            state: &child
        )
        require(childReveal.state.action == .fly && childReveal.state.birdSpeed == 40, "spawned bird reveal")
        fingerprint = hashKernel(fingerprint, childReveal)

        let parentDeath = SM64BirdKernel.tick(
            SM64BirdTickInput(parentAbove8000: true),
            state: &child
        )
        require(parentDeath.state.markedForDeletion, "parent-height deletion")
        require(parentDeath.effects.contains(.markForDeletion), "parent-height effect")
        fingerprint = hashKernel(fingerprint, parentDeath)

        let engineState = SM64SwiftEngineState(objectCapacity: 16)
        let bridge = SM64BirdObjectBridge()
        let spawnerID = try bridge.spawnBird(
            in: engineState,
            kind: .spawner,
            homeX: 100,
            homeY: 200,
            homeZ: 300,
            positionX: 100,
            positionY: 200,
            positionZ: 300
        )
        let mario = try engineState.spawnObject(in: .player, isMario: true)
        require(spawnerID.traceSubject == 1 && mario.traceSubject == 2, "stable bird slots")

        let bridgeSpawn = bridge.tick(
            state: engineState,
            inputs: [
                spawnerID: SM64BirdTickInput(
                    distanceToMario: 1_000,
                    initialMoveYaw: 0x1000,
                    initialMovePitch: 2_000,
                    homeDistance: 300,
                    homeYaw: 0x2000
                )
            ]
        )
        require(bridgeSpawn.effects.count == 7, "spawner plus six child effects")
        guard let parentEffect = bridgeSpawn.effects.first else {
            preconditionFailure("bird parent effect missing")
        }
        require(parentEffect.spawnedChildren.count == 6, "six spawned birds")
        require(bridgeSpawn.scheduler.listCounts[SM64ObjectList.generalActor.rawValue] == 7, "bird list count")
        require(parentEffect.objectID == spawnerID, "parent effect ordering")
        guard let parentRecord = engineState.objects.record(for: spawnerID) else {
            preconditionFailure("bird parent record missing")
        }
        fingerprint = hashBridgeTick(fingerprint, bridgeSpawn, records: [parentRecord])

        var deletionInputs: [SM64ObjectID: SM64BirdTickInput] = [
            spawnerID: SM64BirdTickInput(distanceToMario: 1_000)
        ]
        for childID in parentEffect.spawnedChildren {
            deletionInputs[childID] = SM64BirdTickInput(parentAbove8000: true)
        }
        let bridgeDelete = bridge.tick(state: engineState, inputs: deletionInputs)
        require(bridgeDelete.scheduler.unloaded.count == 6, "six child unloads")
        require(bridgeDelete.effects.dropFirst().allSatisfy { $0.markedForDeletion }, "child deletion effects")
        guard let remainingParentRecord = engineState.objects.record(for: spawnerID) else {
            preconditionFailure("bird parent disappeared")
        }
        fingerprint = hashBridgeTick(fingerprint, bridgeDelete, records: [remainingParentRecord])

        print(String(format: "birdObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Bird object bridge smoke passed")
    }
}
