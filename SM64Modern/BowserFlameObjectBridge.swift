import Foundation

struct SM64BowserFlameObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64BowserFlameOutput
    let spawnedSmoke: SM64ObjectID?
}

final class SM64BowserFlameObjectBridge {
    static let normalBehaviorIdentity: UInt64 = 0x6268_765F_66626E
    static let largeBurningOutBehaviorIdentity: UInt64 = 0x6268_765F_66626C
    private struct State {
        let kind: SM64BowserFlameKind
        let moveYaw: Int32
        let gravity: Float
        let phase: Int32
        let globalTimer: Int32
        let landingScale: Float
        var forwardVelocity: Float
        var velocityY: Float
        var scaleFactor: Float
        var action: Int32
    }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64BowserFlameObjectEffectRecord] = []
    private let smokeBridge: SM64BlackSmokeUpwardObjectBridge

    init(smokeBridge: SM64BlackSmokeUpwardObjectBridge) { self.smokeBridge = smokeBridge }
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnFlame(
        in engineState: SM64SwiftEngineState,
        kind: SM64BowserFlameKind = .normal,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0,
        forwardVelocity: Float = 10,
        velocityY: Float = 20,
        gravity: Float = -1,
        scaleFactor: Float? = nil,
        phase: Int32 = 0,
        globalTimer: Int32 = 0,
        landingScale: Float? = nil
    ) throws -> SM64ObjectID {
        let identity = kind == .normal ? Self.normalBehaviorIdentity : Self.largeBurningOutBehaviorIdentity
        let id = try engineState.spawnObject(in: .level, behaviorIdentity: identity)
        let initialScale = scaleFactor ?? (kind == .normal ? 1 : 7)
        let landing = landingScale ?? (kind == .normal ? 7 : 8)
        guard attach(id, kind: kind, position: position, moveYaw: moveYaw, forwardVelocity: forwardVelocity, velocityY: velocityY, gravity: gravity, scaleFactor: initialScale, phase: phase, globalTimer: globalTimer, landingScale: landing, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned Bowser flame could not attach") }
        return id
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, kind: SM64BowserFlameKind, position: SM64ObjectVector3, moveYaw: Int32, forwardVelocity: Float, velocityY: Float, gravity: Float, scaleFactor: Float, phase: Int32, globalTimer: Int32, landingScale: Float, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(kind: kind, moveYaw: moveYaw, gravity: gravity, phase: phase, globalTimer: globalTimer, landingScale: landingScale, forwardVelocity: forwardVelocity, velocityY: velocityY, scaleFactor: scaleFactor, action: 0)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.moveAngles.yaw = moveYaw; record.forwardVelocity = forwardVelocity; record.velocity.y = velocityY; record.gravity = gravity; record.scale = .init(x: scaleFactor, y: scaleFactor, z: scaleFactor); record.interactionType = 1; record.hitboxRadius = 50; record.hitboxHeight = 25; record.hitboxDownOffset = 25; record.intangibleTimer = 0; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64BowserFlameObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64BowserFlameBehavior.update(.init(kind: state.kind, position: record.position, moveYaw: state.moveYaw, forwardVelocity: state.forwardVelocity, velocityY: state.velocityY, gravity: state.gravity, scaleFactor: state.scaleFactor, action: state.action, timer: record.timer, animationState: record.animationState, phase: state.phase, globalTimer: state.globalTimer, landingScale: state.landingScale, landed: record.moveFlags & 1 != 0, floorHazard: record.floorType == 1 || record.floorType == 10))
        state.forwardVelocity = output.forwardVelocity; state.velocityY = output.velocityY; state.scaleFactor = output.scaleFactor; state.action = output.action; states[id] = state
        var smoke: SM64ObjectID?
        if output.spawnSmoke { smoke = try? smokeBridge.spawnUpward(in: engineState, position: output.position, scale: 1, parent: id) }
        _ = engineState.objects.mutate(id) { next in next.position = output.position; next.forwardVelocity = output.forwardVelocity; next.velocity.y = output.velocityY; next.gravity = output.gravity; next.scale = .init(x: output.scaleFactor, y: output.scaleFactor, z: output.scaleFactor); next.animationState = output.animationState; next.timer = output.timer; if output.shouldDelete { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        let effect = SM64BowserFlameObjectEffectRecord(objectID: id, output: output, spawnedSmoke: smoke); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
