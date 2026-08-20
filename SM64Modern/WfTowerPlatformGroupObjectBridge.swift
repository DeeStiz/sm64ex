import Foundation

struct SM64WfTowerPlatformGroupObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64WfTowerPlatformGroupOutput
    let spawnedChildren: [SM64ObjectID]
}

/// Owner bridge for the WF tower group spawner. It delegates child ownership
/// to the already-registered solid/tower bridges, keeping one scheduler.
final class SM64WfTowerPlatformGroupObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_777467
    static let defaultModel: UInt32 = 0

    private let solidBridge: SM64WfSolidTowerPlatformObjectBridge
    private let towerBridge: SM64WfTowerPlatformObjectBridge
    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64WfTowerPlatformGroupObjectEffectRecord] = []

    init(
        solidBridge: SM64WfSolidTowerPlatformObjectBridge,
        towerBridge: SM64WfTowerPlatformObjectBridge
    ) {
        self.solidBridge = solidBridge
        self.towerBridge = towerBridge
    }

    var registeredIDs: [SM64ObjectID] {
        registered.sorted {
            if $0.slot != $1.slot { return $0.slot < $1.slot }
            return $0.generation < $1.generation
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnGroup(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        model: UInt32 = SM64WfTowerPlatformGroupObjectBridge.defaultModel
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .spawner, model: model,
                                             behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned WF tower group could not attach")
        }
        return id
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3 = .zero,
                in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        registered.insert(id)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState)
        -> SM64WfTowerPlatformGroupObjectEffectRecord?
    {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else { return nil }
        let marioY = engineState.globals.marioObject.flatMap {
            engineState.objects.record(for: $0)?.position.y
        } ?? record.homePosition.y - 2000
        let output = SM64WfTowerPlatformGroupBehavior.update(
            SM64WfTowerPlatformGroupInput(
                action: record.action,
                marioY: marioY,
                homeY: record.homePosition.y
            )
        )
        var spawned: [SM64ObjectID] = []
        if output.spawnChildren {
            let yawStep: Int32 = 0x2000
            for index in 0..<6 {
                let yaw = Int32(index) * yawStep
                let position = SM64ObjectVector3(
                    x: record.position.x + 704 * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: yaw)),
                    y: record.position.y + Float(index * 100),
                    z: record.position.z + 704 * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: yaw))
                )
                if index.isMultiple(of: 2) {
                    if let child = try? solidBridge.spawnPlatform(
                        in: engineState, parent: id, position: position
                    ) { spawned.append(child) }
                } else if let child = try? towerBridge.spawnSliding(
                    in: engineState, parent: id, position: position,
                    moveYaw: Int16(truncatingIfNeeded: yaw), distance: 380, speed: 3
                ) { spawned.append(child) }
            }
            let elevatorPosition = SM64ObjectVector3(
                x: record.position.x + 704 * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: 6 * yawStep)),
                y: record.position.y + 600,
                z: record.position.z + 704 * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: 6 * yawStep))
            )
            if let elevator = try? towerBridge.spawnElevator(
                in: engineState, parent: id, position: elevatorPosition
            ) { spawned.append(elevator) }
        }
        if output.spawnChildren { _ = engineState.objects.markForDeletion(id) }
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.timer = output.action == record.action ? record.timer &+ 1 : 0
        }
        let effect = SM64WfTowerPlatformGroupObjectEffectRecord(
            objectID: id, output: output, spawnedChildren: spawned
        )
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { registered.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
