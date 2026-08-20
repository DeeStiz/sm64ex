import Foundation

struct SM64OrangeNumberObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64OrangeNumberOutput
    let spawnedSparkles: SM64ObjectID?
}

final class SM64OrangeNumberObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6F726E
    private let goldenCoinSparklesBridge: SM64GoldenCoinSparklesObjectBridge?
    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64OrangeNumberObjectEffectRecord] = []

    init(goldenCoinSparklesBridge: SM64GoldenCoinSparklesObjectBridge? = nil) {
        self.goldenCoinSparklesBridge = goldenCoinSparklesBridge
    }

    var registeredIDs: [SM64ObjectID] { registered.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, animationState: Int32 = 0, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, animationState: animationState, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id); preconditionFailure("newly spawned orange number could not attach")
        }
        return id
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, animationState: Int32, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        registered.insert(id)
        return pool.mutate(id) { record in
            record.position = position; record.homePosition = position; record.animationState = animationState; record.velocity.y = 26
            record.graphYOffset = 30; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else { return false }
        let output = SM64OrangeNumberBehavior.update(.init(timer: record.timer, animationState: record.animationState, position: record.position, velocityY: record.velocity.y))
        var sparkles: SM64ObjectID?
        if output.spawnGoldenSparkles, let goldenCoinSparklesBridge {
            sparkles = try? goldenCoinSparklesBridge.spawnSparkles(in: engineState, position: SM64ObjectVector3(x: output.position.x, y: output.position.y - 30, z: output.position.z))
        }
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position; next.velocity.y = output.velocityY; next.timer = output.timer; next.animationState = output.animationState
            if output.shouldDelete { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output, spawnedSparkles: sparkles)); return true
    }

    func remove(_ id: SM64ObjectID) { registered.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
