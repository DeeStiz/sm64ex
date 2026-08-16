import Foundation

enum SM64BehaviorDispatchRoute: UInt8, Equatable, Sendable {
    case decorativePendulum = 0
    case respawner = 1
    case amp = 2
    case boo = 3
    case bobomb = 4
    case bird = 5
    case swoop = 6
    case piranhaPlant = 7
    case bigBoo = 8
    case flyGuy = 9
    case unmigrated = 255
}

struct SM64BehaviorDispatchEvent: Equatable, Sendable {
    let objectID: SM64ObjectID
    let behaviorIdentity: UInt64
    let route: SM64BehaviorDispatchRoute
}

struct SM64BehaviorDispatchTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let events: [SM64BehaviorDispatchEvent]
    let decorativePendulumEffects: [SM64DecorativePendulumObjectEffectRecord]
    let decorativePendulumDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let respawnerEffects: [SM64RespawnerObjectEffectRecord]
    let respawnerDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let ampEffects: [SM64AmpObjectEffectRecord]
    let booEffects: [SM64BooObjectEffectRecord]
    let booDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let bobombEffects: [SM64BobombObjectEffectRecord]
    let bobombDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let birdEffects: [SM64BirdObjectEffectRecord]
    let birdDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let swoopEffects: [SM64SwoopObjectEffectRecord]
    let swoopDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let piranhaPlantEffects: [SM64PiranhaPlantObjectEffectRecord]
    let piranhaPlantDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let bigBooEffects: [SM64BigBooObjectEffectRecord]
    let bigBooDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let flyGuyEffects: [SM64FlyGuyObjectEffectRecord]
    let flyGuyDeliveries: [SM64OwnerThreadEffectDeliveryResult]
}

/// First shared behavior-identity dispatch pass. It intentionally owns only
/// routes with a live Swift owner bridge; unknown identities are recorded as
/// `unmigrated` instead of silently falling through to a fake Swift callback.
final class SM64BehaviorDispatchBridge {
    private let scheduler: SM64ObjectScheduler
    let decorativePendulum: SM64DecorativePendulumObjectBridge
    let respawner: SM64RespawnerObjectBridge
    let amp: SM64AmpObjectBridge
    let boo: SM64BooObjectBridge
    let bobomb: SM64BobombObjectBridge
    let bird: SM64BirdObjectBridge
    let swoop: SM64SwoopObjectBridge
    let piranhaPlant: SM64PiranhaPlantObjectBridge
    let bigBoo: SM64BigBooObjectBridge
    let flyGuy: SM64FlyGuyObjectBridge
    private(set) var eventLog: [SM64BehaviorDispatchEvent] = []

    init(scheduler: SM64ObjectScheduler = SM64ObjectScheduler()) {
        self.scheduler = scheduler
        self.decorativePendulum = SM64DecorativePendulumObjectBridge(scheduler: scheduler)
        self.respawner = SM64RespawnerObjectBridge(scheduler: scheduler)
        self.amp = SM64AmpObjectBridge(scheduler: scheduler)
        self.boo = SM64BooObjectBridge(scheduler: scheduler)
        self.bobomb = SM64BobombObjectBridge(scheduler: scheduler)
        self.bird = SM64BirdObjectBridge(scheduler: scheduler)
        self.swoop = SM64SwoopObjectBridge(scheduler: scheduler)
        self.piranhaPlant = SM64PiranhaPlantObjectBridge(scheduler: scheduler)
        self.bigBoo = SM64BigBooObjectBridge(scheduler: scheduler)
        self.flyGuy = SM64FlyGuyObjectBridge(scheduler: scheduler)
    }

    static func route(for behaviorIdentity: UInt64) -> SM64BehaviorDispatchRoute {
        switch behaviorIdentity {
        case SM64DecorativePendulumObjectBridge.defaultBehaviorIdentity:
            return .decorativePendulum
        case SM64RespawnerObjectBridge.defaultBehaviorIdentity:
            return .respawner
        case SM64AmpObjectBridge.defaultBehaviorIdentity:
            return .amp
        case SM64BooObjectBridge.defaultBehaviorIdentity:
            return .boo
        case SM64BobombObjectBridge.defaultBehaviorIdentity:
            return .bobomb
        case SM64BirdObjectBridge.defaultBehaviorIdentity:
            return .bird
        case SM64SwoopObjectBridge.defaultBehaviorIdentity:
            return .swoop
        case SM64PiranhaPlantObjectBridge.defaultBehaviorIdentity:
            return .piranhaPlant
        case SM64BigBooObjectBridge.defaultBehaviorIdentity:
            return .bigBoo
        case SM64FlyGuyObjectBridge.defaultBehaviorIdentity:
            return .flyGuy
        default:
            return .unmigrated
        }
    }

    func reset() {
        eventLog.removeAll(keepingCapacity: true)
        for id in decorativePendulum.registeredIDs { decorativePendulum.remove(id) }
        for id in respawner.registeredIDs { respawner.remove(id) }
        for id in amp.registeredIDs { amp.remove(id) }
        for id in boo.registeredIDs { boo.remove(id) }
        for id in bobomb.registeredIDs { bobomb.remove(id) }
        for id in bird.registeredIDs { bird.remove(id) }
        for id in swoop.registeredIDs { swoop.remove(id) }
        for id in piranhaPlant.registeredIDs { piranhaPlant.remove(id) }
        for id in bigBoo.registeredIDs { bigBoo.remove(id) }
        for id in flyGuy.registeredIDs { flyGuy.remove(id) }
        decorativePendulum.beginExternalTick()
        respawner.beginExternalTick()
        amp.beginExternalTick()
        boo.beginExternalTick()
        bobomb.beginExternalTick()
        bird.beginExternalTick()
        swoop.beginExternalTick()
        piranhaPlant.beginExternalTick()
        bigBoo.beginExternalTick()
        flyGuy.beginExternalTick()
    }

    @discardableResult
    func spawnPendulum(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        faceRoll: Int32 = 0
    ) throws -> SM64ObjectID {
        try decorativePendulum.spawnPendulum(
            in: engineState,
            position: position,
            faceRoll: faceRoll
        )
    }

    @discardableResult
    func spawnRespawner(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        modelToRespawn: UInt32,
        behaviorToRespawn: UInt64,
        minSpawnDistance: Float,
        behaviorParams: Int32 = 0
    ) throws -> SM64ObjectID {
        try respawner.spawnRespawner(
            in: engineState,
            position: position,
            modelToRespawn: modelToRespawn,
            behaviorToRespawn: behaviorToRespawn,
            minSpawnDistance: minSpawnDistance,
            behaviorParams: behaviorParams
        )
    }

    @discardableResult
    func spawnAmp(
        in engineState: SM64SwiftEngineState,
        kind: SM64AmpKind,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        rotationRadius: Float = 0,
        initialMoveYaw: Int16 = 0,
        initialPhase: Int32 = 0
    ) throws -> SM64ObjectID {
        try amp.spawnAmp(
            in: engineState,
            kind: kind,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            rotationRadius: rotationRadius,
            initialMoveYaw: initialMoveYaw,
            initialPhase: initialPhase
        )
    }

    @discardableResult
    func spawnBoo(
        in engineState: SM64SwiftEngineState,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0
    ) throws -> SM64ObjectID {
        try boo.spawnBoo(
            in: engineState,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw
        )
    }

    @discardableResult
    func spawnBobomb(
        in engineState: SM64SwiftEngineState,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        floorHeight: Float = 0,
        moveYaw: Int16 = 0
    ) throws -> SM64ObjectID {
        try bobomb.spawnBobomb(
            in: engineState,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            floorHeight: floorHeight,
            moveYaw: moveYaw
        )
    }

    @discardableResult
    func spawnBird(
        in engineState: SM64SwiftEngineState,
        kind: SM64BirdKind,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0
    ) throws -> SM64ObjectID {
        try bird.spawnBird(
            in: engineState,
            kind: kind,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            positionX: nil,
            positionY: nil,
            positionZ: nil
        )
    }

    @discardableResult
    func spawnSwoop(
        in engineState: SM64SwiftEngineState,
        positionY: Float = 0,
        homeY: Float? = nil,
        moveYaw: Int16 = 0
    ) throws -> SM64ObjectID {
        try swoop.spawnSwoop(
            in: engineState,
            positionY: positionY,
            homeY: homeY,
            moveYaw: moveYaw
        )
    }

    @discardableResult
    func spawnPiranhaPlant(
        in engineState: SM64SwiftEngineState,
        action: SM64PiranhaPlantAction = .idle,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        moveYaw: Int16 = 0
    ) throws -> SM64ObjectID {
        try piranhaPlant.spawnPlant(
            in: engineState,
            action: action,
            positionX: positionX,
            positionY: positionY,
            positionZ: positionZ,
            moveYaw: moveYaw
        )
    }

    @discardableResult
    func spawnBigBoo(
        in engineState: SM64SwiftEngineState,
        variant: SM64BigBooVariant = .ghostHunt,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        action: SM64BigBooAction = .initialize
    ) throws -> SM64ObjectID {
        try bigBoo.spawnBigBoo(
            in: engineState,
            variant: variant,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw,
            action: action
        )
    }

    @discardableResult
    func spawnFlyGuy(
        in engineState: SM64SwiftEngineState,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0
    ) throws -> SM64ObjectID {
        try flyGuy.spawnFlyGuy(
            in: engineState,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw
        )
    }

    @discardableResult
    func tick(state engineState: SM64SwiftEngineState) -> SM64BehaviorDispatchTickResult {
        eventLog.removeAll(keepingCapacity: true)
        decorativePendulum.beginExternalTick()
        respawner.beginExternalTick()
        amp.beginExternalTick()
        boo.beginExternalTick()
        bobomb.beginExternalTick()
        bird.beginExternalTick()
        swoop.beginExternalTick()
        piranhaPlant.beginExternalTick()
        bigBoo.beginExternalTick()
        flyGuy.beginExternalTick()

        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            guard let self, let record = pool.record(for: id) else { return }
            let route = Self.route(for: record.behaviorIdentity)
            self.eventLog.append(
                SM64BehaviorDispatchEvent(
                    objectID: id,
                    behaviorIdentity: record.behaviorIdentity,
                    route: route
                )
            )
            switch route {
            case .decorativePendulum:
                _ = self.decorativePendulum.updateInline(id, pool: pool)
            case .respawner:
                _ = self.respawner.updateInline(
                    id,
                    input: SM64RespawnerTickInput(distanceToMario: record.distanceToMario),
                    pool: pool
                )
            case .amp:
                _ = self.amp.updateInline(id, pool: pool)
            case .boo:
                _ = self.boo.updateInline(id, pool: pool)
            case .bobomb:
                _ = self.bobomb.updateInline(id, pool: pool)
            case .bird:
                _ = self.bird.updateInline(id, pool: pool)
            case .swoop:
                _ = self.swoop.updateInline(id, pool: pool)
            case .piranhaPlant:
                _ = self.piranhaPlant.updateInline(id, pool: pool)
            case .bigBoo:
                _ = self.bigBoo.updateInline(id, pool: pool)
            case .flyGuy:
                _ = self.flyGuy.updateInline(id, pool: pool)
            case .unmigrated:
                break
            }
        }

        for id in schedulerResult.unloaded {
            decorativePendulum.remove(id)
            respawner.remove(id)
            amp.remove(id)
            boo.remove(id)
            bobomb.remove(id)
            bird.remove(id)
            swoop.remove(id)
            piranhaPlant.remove(id)
            bigBoo.remove(id)
            flyGuy.remove(id)
        }
        for id in decorativePendulum.registeredIDs where engineState.objects.record(for: id) == nil {
            decorativePendulum.remove(id)
        }
        for id in respawner.registeredIDs where engineState.objects.record(for: id) == nil {
            respawner.remove(id)
        }
        for id in amp.registeredIDs where engineState.objects.record(for: id) == nil {
            amp.remove(id)
        }
        for id in boo.registeredIDs where engineState.objects.record(for: id) == nil {
            boo.remove(id)
        }
        for id in bobomb.registeredIDs where engineState.objects.record(for: id) == nil {
            bobomb.remove(id)
        }
        for id in bird.registeredIDs where engineState.objects.record(for: id) == nil {
            bird.remove(id)
        }
        for id in swoop.registeredIDs where engineState.objects.record(for: id) == nil {
            swoop.remove(id)
        }
        for id in piranhaPlant.registeredIDs where engineState.objects.record(for: id) == nil {
            piranhaPlant.remove(id)
        }
        for id in bigBoo.registeredIDs where engineState.objects.record(for: id) == nil {
            bigBoo.remove(id)
        }
        for id in flyGuy.registeredIDs where engineState.objects.record(for: id) == nil {
            flyGuy.remove(id)
        }

        return SM64BehaviorDispatchTickResult(
            scheduler: schedulerResult,
            events: eventLog,
            decorativePendulumEffects: decorativePendulum.effectLog,
            decorativePendulumDeliveries: decorativePendulum.deliveryLog,
            respawnerEffects: respawner.effectLog,
            respawnerDeliveries: respawner.deliveryLog,
            ampEffects: amp.effectLog,
            booEffects: boo.effectLog,
            booDeliveries: boo.deliveryLog,
            bobombEffects: bobomb.effectLog,
            bobombDeliveries: bobomb.deliveryLog,
            birdEffects: bird.effectLog,
            birdDeliveries: bird.deliveryLog,
            swoopEffects: swoop.effectLog,
            swoopDeliveries: swoop.deliveryLog,
            piranhaPlantEffects: piranhaPlant.effectLog,
            piranhaPlantDeliveries: piranhaPlant.deliveryLog,
            bigBooEffects: bigBoo.effectLog,
            bigBooDeliveries: bigBoo.deliveryLog,
            flyGuyEffects: flyGuy.effectLog,
            flyGuyDeliveries: flyGuy.deliveryLog
        )
    }
}
