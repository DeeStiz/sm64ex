import Foundation

private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211

private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 {
    var result = seed
    for index in 0..<8 {
        result ^= (value >> UInt64(index * 8)) & 255
        result &*= prime
    }
    return result
}

private func hashID(_ seed: UInt64, _ id: SM64ObjectID) -> UInt64 {
    var result = hash(seed, UInt64(id.slot))
    result = hash(result, UInt64(id.generation))
    return result
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
struct SM64SnowmanBottomSmoke {
    static func main() throws {
        let start = SM64SnowmanBottomBehavior.update(.init(
            action: 0, timer: 4, position: .zero, forwardVelocity: 0,
            moveYaw: 0, facePitch: 0, scale: 0.4, pathComplete: false,
            nearBouncePoint: false, movementFlags: 0, dialogTriggered: true
        ))
        let path = SM64SnowmanBottomBehavior.update(.init(
            action: 1, timer: 8, position: .zero, forwardVelocity: 80,
            moveYaw: 0, facePitch: 0, scale: 0.4, pathComplete: true,
            nearBouncePoint: false, movementFlags: 0, dialogTriggered: false
        ))
        let bounce = SM64SnowmanBottomBehavior.update(.init(
            action: 2, timer: 12, position: .zero, forwardVelocity: 20,
            moveYaw: 0, facePitch: 0, scale: 0.5, pathComplete: false,
            nearBouncePoint: true, movementFlags: 0, dialogTriggered: false
        ))
        let timeout = SM64SnowmanBottomBehavior.update(.init(
            action: 2, timer: 200, position: .zero, forwardVelocity: 20,
            moveYaw: 0, facePitch: 0, scale: 0.5, pathComplete: false,
            nearBouncePoint: false, movementFlags: 0, dialogTriggered: false
        ))
        let intangible = SM64SnowmanBottomBehavior.update(.init(
            action: 3, timer: 9, position: .init(x: 4, y: 5, z: 6),
            forwardVelocity: 15, moveYaw: 0, facePitch: 0, scale: 0.7,
            pathComplete: false, nearBouncePoint: false, movementFlags: 0x09,
            dialogTriggered: false
        ))
        precondition(start.action == 1 && start.forwardVelocity == 10)
        precondition(path.action == 2 && path.forwardVelocity == 70)
        precondition(bounce.action == 3 && bounce.verticalVelocity == 80 && bounce.parentBounce)
        precondition(timeout.deactivated)
        precondition(intangible.action == 4 && !intangible.tangible && intangible.pushMario)

        var fingerprint = offset
        for output in [start, path, bounce, timeout, intangible] {
            fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.action)))
            fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.timer)))
            fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.facePitch)))
            fingerprint = hash(fingerprint, UInt64(output.verticalVelocity.bitPattern))
            fingerprint = hash(fingerprint, output.deactivated ? 1 : 0)
        }

        // The route owner creates the checkpoint in a separate object-list
        // record, then updates the parent before the child. A trigger retires
        // only the child, while a parent unload retires both generations.
        let engineState = SM64SwiftEngineState(objectCapacity: 8)
        let owner = SM64SnowmanBottomRouteOwner()
        let head = try engineState.spawnObject(
            in: .generalActor,
            behaviorIdentity: 0x6268_765F_736865
        )
        let bottom = try owner.spawn(
            in: engineState,
            position: .init(x: 10, y: 20, z: 30),
            parentHead: head
        )
        guard let checkpoint = owner.checkpointID(for: bottom),
              let checkpointRecord = engineState.objects.record(for: checkpoint) else {
            preconditionFailure("Snowman Bottom checkpoint missing")
        }
        require(checkpointRecord.parent == bottom, "checkpoint keeps exact parent generation")
        require(owner.registeredIDs == [bottom], "bottom owner registration")
        require(owner.checkpointIDs == [checkpoint], "checkpoint owner registration")

        owner.beginExternalTick()
        _ = engineState.objects.mutate(checkpoint) { $0.distanceToMario = 799 }
        require(owner.updateInline(bottom, state: engineState), "parent then checkpoint update")
        require(owner.checkpointCounter(for: bottom) == 1, "checkpoint increments parent counter")
        guard let triggeredCheckpoint = engineState.objects.record(for: checkpoint) else {
            preconditionFailure("triggered checkpoint disappeared before unload")
        }
        require(
            triggeredCheckpoint.activeFlags & SM64ObjectPool.activeFlagActive == 0,
            "triggered checkpoint retires"
        )
        let checkpointUnload = engineState.objects.unloadDeactivated()
        owner.pruneExternal(unloaded: checkpointUnload, pool: engineState.objects)
        require(engineState.objects.record(for: checkpoint) == nil, "triggered checkpoint unload")
        require(owner.checkpointID(for: bottom) == nil, "stale child mapping pruned")
        require(!owner.updateInline(bottom, state: engineState), "missing child fails closed")

        // Reuse the parent's slot with a new generation before pruning the
        // old mapping. The stale child must be removed without touching the
        // replacement object.
        let staleBottom = try owner.spawn(in: engineState)
        guard let staleCheckpoint = owner.checkpointID(for: staleBottom) else {
            preconditionFailure("stale lifecycle checkpoint missing")
        }
        require(engineState.objects.despawn(staleBottom), "external parent unload")
        let replacement = try engineState.spawnObject(
            in: .generalActor,
            behaviorIdentity: 0x6268_765F_726570
        )
        require(replacement.slot == staleBottom.slot, "parent slot reused")
        require(replacement.generation != staleBottom.generation, "parent generation advanced")
        owner.pruneExternal(unloaded: [], pool: engineState.objects)
        require(engineState.objects.record(for: staleCheckpoint) == nil, "stale child retired")
        require(engineState.objects.record(for: replacement) != nil, "replacement parent preserved")
        require(owner.checkpointID(for: staleBottom) == nil, "stale parent mapping pruned")

        let childStaleBottom = try owner.spawn(in: engineState)
        guard let childStaleCheckpoint = owner.checkpointID(for: childStaleBottom) else {
            preconditionFailure("child generation checkpoint missing")
        }
        require(engineState.objects.despawn(childStaleCheckpoint), "external child unload")
        let childReplacement = try engineState.spawnObject(
            in: .generalActor,
            behaviorIdentity: 0x6268_765F_726570
        )
        require(childReplacement.slot == childStaleCheckpoint.slot, "child slot reused")
        require(childReplacement.generation != childStaleCheckpoint.generation, "child generation advanced")
        owner.pruneExternal(unloaded: [], pool: engineState.objects)
        require(engineState.objects.record(for: childReplacement) != nil, "replacement child preserved")
        require(owner.checkpointID(for: childStaleBottom) == nil, "stale child mapping pruned")

        let retiringBottom = try owner.spawn(in: engineState)
        guard let retiringCheckpoint = owner.checkpointID(for: retiringBottom) else {
            preconditionFailure("retiring checkpoint missing")
        }
        _ = engineState.objects.mutate(retiringBottom) { record in
            record.action = 2
            record.timer = 200
        }
        owner.beginExternalTick()
        require(owner.updateInline(retiringBottom, state: engineState), "parent-first retirement update")
        guard let retiredParent = engineState.objects.record(for: retiringBottom),
              let retiredChild = engineState.objects.record(for: retiringCheckpoint) else {
            preconditionFailure("retirement records disappeared before unload")
        }
        require(
            retiredParent.activeFlags & SM64ObjectPool.activeFlagActive == 0,
            "parent timeout retires bottom"
        )
        require(
            retiredChild.activeFlags & SM64ObjectPool.activeFlagActive == 0,
            "child observes retired parent"
        )
        let pairedUnload = engineState.objects.unloadDeactivated()
        owner.pruneExternal(unloaded: pairedUnload, pool: engineState.objects)
        require(engineState.objects.record(for: retiringBottom) == nil, "retired parent unload")
        require(engineState.objects.record(for: retiringCheckpoint) == nil, "retired child unload")

        var lifecycleFingerprint = offset
        lifecycleFingerprint = hashID(lifecycleFingerprint, bottom)
        lifecycleFingerprint = hashID(lifecycleFingerprint, checkpoint)
        lifecycleFingerprint = hashID(lifecycleFingerprint, staleBottom)
        lifecycleFingerprint = hashID(lifecycleFingerprint, staleCheckpoint)
        lifecycleFingerprint = hashID(lifecycleFingerprint, replacement)
        lifecycleFingerprint = hashID(lifecycleFingerprint, childStaleBottom)
        lifecycleFingerprint = hashID(lifecycleFingerprint, childStaleCheckpoint)
        lifecycleFingerprint = hashID(lifecycleFingerprint, childReplacement)
        lifecycleFingerprint = hashID(lifecycleFingerprint, retiringBottom)
        lifecycleFingerprint = hashID(lifecycleFingerprint, retiringCheckpoint)
        lifecycleFingerprint = hash(lifecycleFingerprint, UInt64(owner.checkpointCounter(for: bottom)))

        print(String(format: "snowmanBottomFingerprint=0x%016llx", fingerprint))
        print(String(format: "snowmanBottomLifecycleFingerprint=0x%016llx", lifecycleFingerprint))
        print("SM64 Modern snowman bottom smoke passed")
    }
}
