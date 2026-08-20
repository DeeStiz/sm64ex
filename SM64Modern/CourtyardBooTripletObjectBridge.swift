import Foundation

struct SM64CourtyardBooTripletObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64CourtyardBooTripletOutput
    let spawnedChildren: [SM64ObjectID]
}

final class SM64CourtyardBooTripletObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_636274
    private let booBridge: SM64BooObjectBridge
    private var stars: [SM64ObjectID: Int32] = [:]
    private var yawSeeds: [SM64ObjectID: [Int16]] = [:]
    private(set) var effectLog: [SM64CourtyardBooTripletObjectEffectRecord] = []

    init(booBridge: SM64BooObjectBridge) { self.booBridge = booBridge }

    var registeredIDs: [SM64ObjectID] {
        stars.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnTriplet(in engineState: SM64SwiftEngineState, totalStars: Int32 = 12, position: SM64ObjectVector3 = .zero, yawSeeds: [Int16] = [0, 0x4000, Int16(bitPattern: 0x8000)]) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, totalStars: totalStars, position: position, yawSeeds: yawSeeds, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned courtyard Boo triplet could not attach")
        }
        return id
    }

    @discardableResult
    private func attach(_ id: SM64ObjectID, totalStars: Int32, position: SM64ObjectVector3, yawSeeds: [Int16], in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        stars[id] = totalStars
        self.yawSeeds[id] = Array(yawSeeds.prefix(3)) + Array(repeating: 0, count: max(0, 3 - yawSeeds.count))
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.graphFlags |= 0x10
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
        }
    }

    @discardableResult
    func setTotalStars(_ totalStars: Int32, for id: SM64ObjectID) -> Bool {
        guard stars[id] != nil else { return false }
        stars[id] = totalStars
        return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let totalStars = stars[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64CourtyardBooTripletBehavior.update(timer: record.timer, totalStars: totalStars)
        var children: [SM64ObjectID] = []
        if output.spawnCount > 0 {
            let seeds = yawSeeds[id] ?? [0, 0x4000, Int16(bitPattern: 0x8000)]
            for index in 0..<output.spawnCount {
                let relative = SM64CourtyardBooTripletBehavior.relativePositions[index]
                if let child = try? engineState.spawnObject(in: .generalActor, model: SM64BooObjectBridge.defaultModel, behaviorIdentity: SM64BooObjectBridge.ghostHuntBehaviorIdentity, parent: id) {
                    _ = booBridge.attach(
                        child,
                        homeX: record.position.x + relative.x,
                        homeY: record.position.y + relative.y,
                        homeZ: record.position.z + relative.z,
                        moveYaw: seeds[index],
                        in: engineState.objects
                    )
                    _ = engineState.objects.setParent(child, parent: id)
                    children.append(child)
                }
            }
        }
        _ = engineState.objects.mutate(id) { next in
            next.timer &+= 1
            if output.shouldDeactivate { next.activeFlags = 0 }
        }
        effectLog.append(.init(objectID: id, output: output, spawnedChildren: children))
        return true
    }

    func remove(_ id: SM64ObjectID) { stars.removeValue(forKey: id); yawSeeds.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
