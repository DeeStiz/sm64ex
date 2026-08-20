import Foundation

struct SM64GiantPoleObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64GiantPoleOutput
    let spawnedTopBall: SM64ObjectID?
}

final class SM64GiantPoleObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_67706C
    static let defaultModel: UInt32 = 0
    static let yellowBallModel: UInt32 = 0x55
    static let poleInteractionType: UInt32 = 1 << 6
    private let noOpBridge: SM64NoOpObjectBridge
    private var topBalls: [SM64ObjectID: SM64ObjectID] = [:]
    private(set) var effectLog: [SM64GiantPoleObjectEffectRecord] = []

    init(noOpBridge: SM64NoOpObjectBridge) { self.noOpBridge = noOpBridge }

    var registeredIDs: [SM64ObjectID] {
        topBalls.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnPole(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, hitboxHeight: Float = 2_100) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .polelike, model: Self.defaultModel, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, hitboxHeight: hitboxHeight, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Giant Pole could not attach")
        }
        return id
    }

    @discardableResult
    private func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, hitboxHeight: Float, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.hitboxRadius = 80
            record.hitboxHeight = hitboxHeight
            record.interactionType = Self.poleInteractionType
            record.intangibleTimer = 0
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let record = engineState.objects.record(for: id) else { return false }
        let output = SM64GiantPoleBehavior.update(.init(
            timer: record.timer,
            position: record.position,
            hitboxHeight: record.hitboxHeight,
            topBallPresent: topBalls[id] != nil
        ))
        var topBall = topBalls[id]
        if output.spawnTopBall {
            if let child = try? engineState.spawnObject(in: .default, model: Self.yellowBallModel, behaviorIdentity: SM64NoOpObjectBridge.yellowBallIdentity, parent: id) {
                _ = noOpBridge.attach(child, position: output.topBallPosition, in: engineState.objects)
                topBall = child
                topBalls[id] = child
            }
        }
        _ = engineState.objects.mutate(id) { next in
            next.timer = output.timer
            next.hitboxRadius = output.hitboxRadius
            next.hitboxHeight = output.hitboxHeight
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output, spawnedTopBall: topBall))
        return true
    }

    func remove(_ id: SM64ObjectID) {
        topBalls.removeValue(forKey: id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
