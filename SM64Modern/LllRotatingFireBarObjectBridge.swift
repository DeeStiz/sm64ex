import Foundation

struct SM64LllRotatingFireBarObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64LllRotatingFireBarOutput
    let spawnedFlames: [SM64ObjectID]
}

/// Owner bridge for the fire-bar parent; flame children reuse the common
/// `LllRotatingHexFlameObjectBridge` route.
final class SM64LllRotatingFireBarObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6C6662
    static let defaultModel: UInt32 = 0
    private let flameBridge: SM64LllRotatingHexFlameObjectBridge
    private var behaviorBytes: [SM64ObjectID: UInt8] = [:]
    private(set) var effectLog: [SM64LllRotatingFireBarObjectEffectRecord] = []

    init(flameBridge: SM64LllRotatingHexFlameObjectBridge) { self.flameBridge = flameBridge }
    var registeredIDs: [SM64ObjectID] { behaviorBytes.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnFireBar(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero,
                     behaviorByte: UInt8 = 0, model: UInt32 = SM64LllRotatingFireBarObjectBridge.defaultModel) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, model: model, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, behaviorByte: behaviorByte, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned LLL fire bar could not attach") }
        return id
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3 = .zero,
                behaviorByte: UInt8, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        behaviorBytes[id] = behaviorByte
        return pool.mutate(id) { record in
            record.position = position; record.homePosition = position
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64LllRotatingFireBarObjectEffectRecord? {
        guard let behaviorByte = behaviorBytes[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64LllRotatingFireBarBehavior.update(
            SM64LllRotatingFireBarInput(action: record.action, distanceToMario: record.distanceToMario,
                                        behaviorByte: behaviorByte, moveYaw: record.moveAngles.yaw)
        )
        var flames: [SM64ObjectID] = []
        if output.spawnFlames {
            let countPerBar = Int(output.flameCount / 2)
            for bar in 0..<2 {
                let sign: Float = bar == 0 ? 1 : -1
                for index in 0..<countPerBar {
                    if let flame = try? flameBridge.spawnFlame(
                        in: engineState, parent: id, leftOffset: 0,
                        forwardOffset: sign * (200 + Float(index * 150))
                    ) { flames.append(flame) }
                }
            }
        }
        let nextTimer = output.action == record.action ? record.timer &+ 1 : 0
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action; next.timer = nextTimer
            next.moveAngles.yaw = output.moveYaw; next.faceAngles.yaw = output.moveYaw
            next.angleVelocity.yaw = output.angleVelocityYaw
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64LllRotatingFireBarObjectEffectRecord(objectID: id, output: output, spawnedFlames: flames)
        effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { behaviorBytes.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
