import Foundation

struct SM64NoOpObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64NoOpOutput }

final class SM64NoOpObjectBridge {
    static let unused05A8Identity: UInt64 = 0x6268_765F_7535_61
    static let unused1820Identity: UInt64 = 0x6268_765F_7531_3832
    static let unused1F30Identity: UInt64 = 0x6268_765F_7531_6633
    static let unused2A10Identity: UInt64 = 0x6268_765F_7532_6130
    static let unused2A54Identity: UInt64 = 0x6268_765F_7532_6134
    static let instantActiveWarpIdentity: UInt64 = 0x6268_765F_697761
    static let airborneWarpIdentity: UInt64 = 0x6268_765F_617761
    static let hardAirKnockBackWarpIdentity: UInt64 = 0x6268_765F_686B77
    static let spinAirborneCircleWarpIdentity: UInt64 = 0x6268_765F_736163
    static let deathWarpIdentity: UInt64 = 0x6268_765F_647761
    static let spinAirborneWarpIdentity: UInt64 = 0x6268_765F_736177
    static let flyingWarpIdentity: UInt64 = 0x6268_765F_667779
    static let paintingStarCollectWarpIdentity: UInt64 = 0x6268_765F_707363
    static let paintingDeathWarpIdentity: UInt64 = 0x6268_765F_706477
    static let airborneDeathWarpIdentity: UInt64 = 0x6268_765F_616477
    static let airborneStarCollectWarpIdentity: UInt64 = 0x6268_765F_617363
    static let launchStarCollectWarpIdentity: UInt64 = 0x6268_765F_6C7363
    static let launchDeathWarpIdentity: UInt64 = 0x6268_765F_6C6477
    static let swimmingWarpIdentity: UInt64 = 0x6268_765F_737761
    static let insideCannonIdentity: UInt64 = 0x6268_765F_696361
    static let snowBallIdentity: UInt64 = 0x6268_765F_736E63
    static let cutOutObjectIdentity: UInt64 = 0x6268_765F_636F75
    static let rotatingCounterClockwiseIdentity: UInt64 = 0x6268_765F_726363
    static let stubIdentity: UInt64 = 0x6268_765F_73747562
    static let stub1D0CIdentity: UInt64 = 0x6268_765F_737431
    static let stub1D70Identity: UInt64 = 0x6268_765F_737432
    static let unusedOneIdentity: UInt64 = 0x6268_765F_756E31
    static let staticObjectIdentity: UInt64 = 0x6268_765F_73746F
    static let yellowBallIdentity: UInt64 = 0x6268_765F_79626C
    static let carrySomething1Identity: UInt64 = 0x6268_765F_637331
    static let carrySomething2Identity: UInt64 = 0x6268_765F_637332
    static let carrySomething3Identity: UInt64 = 0x6268_765F_637333
    static let carrySomething4Identity: UInt64 = 0x6268_765F_637334
    static let carrySomething5Identity: UInt64 = 0x6268_765F_637335
    static let carrySomething6Identity: UInt64 = 0x6268_765F_637336
    static let iglooIdentity: UInt64 = 0x6268_765F_69676C
    static let bigSnowmanWholeIdentity: UInt64 = 0x6268_765F_62736D
    static let ukikiCageChildIdentity: UInt64 = 0x6268_765F_756363
    static let sunkenShipPart2Identity: UInt64 = 0x6268_765F_737332
    static let sunkenShipSetRotationIdentity: UInt64 = 0x6268_765F_737372
    static let towerIdentity: UInt64 = 0x6268_765F_747772
    static let bulletBillCannonIdentity: UInt64 = 0x6268_765F_62626E
    static let lllHexagonalMeshIdentity: UInt64 = 0x6268_765F_6C686D
    static let hiddenStaircaseStepIdentity: UInt64 = 0x6268_765F_687373
    static let pillarBaseIdentity: UInt64 = 0x6268_765F_70626C
    static let inSunkenShipIdentity: UInt64 = 0x6268_765F_697373
    static let inSunkenShip2Identity: UInt64 = 0x6268_765F_697332
    static let mantaRayRingManagerIdentity: UInt64 = 0x6268_765F_6D726D
    static let betaFishSplashSpawnerIdentity: UInt64 = 0x6268_765F_626673_31

    private struct CollisionSpec: Equatable {
        let dataIdentity: UInt64
        let surfaceIdentity: UInt32
        let collisionDistance: Float
        let drawingDistance: Float
        let room: Int32
        let faceAngles: SM64ObjectAngles
    }

    private enum Mode: Equatable {
        case breakOnly
        case persistentNoOp
        case igloo
        case bigSnowmanWhole
        case ukikiCageChild
        case sunkenShipPart2
        case staticCollision(CollisionSpec)
    }

    static let registeredIdentities: [UInt64] = [
        unused05A8Identity,
        unused1820Identity,
        unused1F30Identity,
        unused2A10Identity,
        unused2A54Identity,
        instantActiveWarpIdentity,
        airborneWarpIdentity,
        hardAirKnockBackWarpIdentity,
        spinAirborneCircleWarpIdentity,
        deathWarpIdentity,
        spinAirborneWarpIdentity,
        flyingWarpIdentity,
        paintingStarCollectWarpIdentity,
        paintingDeathWarpIdentity,
        airborneDeathWarpIdentity,
        airborneStarCollectWarpIdentity,
        launchStarCollectWarpIdentity,
        launchDeathWarpIdentity,
        swimmingWarpIdentity,
        insideCannonIdentity,
        snowBallIdentity,
        cutOutObjectIdentity,
        rotatingCounterClockwiseIdentity,
        stubIdentity,
        stub1D0CIdentity,
        stub1D70Identity,
        unusedOneIdentity,
        staticObjectIdentity,
        yellowBallIdentity,
        carrySomething1Identity,
        carrySomething2Identity,
        carrySomething3Identity,
        carrySomething4Identity,
        carrySomething5Identity,
        carrySomething6Identity,
        iglooIdentity,
        bigSnowmanWholeIdentity,
        ukikiCageChildIdentity,
        sunkenShipPart2Identity,
        sunkenShipSetRotationIdentity,
        towerIdentity,
        bulletBillCannonIdentity,
        lllHexagonalMeshIdentity,
        hiddenStaircaseStepIdentity,
        pillarBaseIdentity,
        inSunkenShipIdentity,
        inSunkenShip2Identity,
        mantaRayRingManagerIdentity,
        betaFishSplashSpawnerIdentity
    ]
    private var registered: Set<SM64ObjectID> = []
    private var modes: [SM64ObjectID: Mode] = [:]
    private(set) var effectLog: [SM64NoOpObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { registered.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, behaviorIdentity: UInt64, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let objectList: SM64ObjectList = {
            if case .staticCollision = Self.mode(for: behaviorIdentity) { return .surface }
            return .default
        }()
        let id = try engineState.spawnObject(in: objectList, behaviorIdentity: behaviorIdentity)
        guard attach(id, position: position, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned no-op behavior could not attach") }
        return id
    }
    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard let existing = pool.record(for: id) else { return false }
        let mode = Self.mode(for: existing.behaviorIdentity)
        modes[id] = mode
        registered.insert(id)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            switch mode {
            case .igloo:
                record.interactionType = 1 << 30 // INTERACT_IGLOO_BARRIER
                record.hitboxRadius = 100
                record.hitboxHeight = 200
                record.intangibleTimer = 0
            case .bigSnowmanWhole:
                record.graphYOffset = 180
                record.interactionType = 1 << 23 // INTERACT_TEXT
                record.hitboxRadius = 210
                record.hitboxHeight = 550
                record.intangibleTimer = 0
            case .ukikiCageChild:
                record.position = SM64ObjectVector3(x: 2560, y: 1457, z: 1898)
                record.homePosition = record.position
            case .sunkenShipPart2:
                record.scale = .init(x: 1, y: 1, z: 1)
                record.drawingDistance = 6000
                record.faceAngles = .init(pitch: 0xE958, yaw: 0xEE6C, roll: 0x0C80)
            case .breakOnly:
                break
            case .persistentNoOp:
                break
            case let .staticCollision(spec):
                record.collisionDataIdentity = spec.dataIdentity
                record.collisionDistance = spec.collisionDistance
                record.drawingDistance = spec.drawingDistance
                record.room = spec.room
                record.faceAngles = spec.faceAngles
            }
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64NoOpObjectEffectRecord? {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else { return nil }
        let base = SM64NoOpBehavior.update(.init(position: record.position, faceAngles: record.faceAngles))
        let mode = modes[id] ?? .breakOnly
        let output = SM64NoOpOutput(position: base.position, faceAngles: base.faceAngles, scriptBreaks: mode == .breakOnly)
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.faceAngles = output.faceAngles
            switch mode {
            case .igloo:
                next.interactionStatus = 0
            case .bigSnowmanWhole:
                next.intangibleTimer = 0
            case .breakOnly, .persistentNoOp, .ukikiCageChild, .sunkenShipPart2:
                break
            case let .staticCollision(spec):
                next.collisionDataIdentity = spec.dataIdentity
                next.collisionDistance = spec.collisionDistance
                next.drawingDistance = spec.drawingDistance
                next.room = spec.room
                next.faceAngles = spec.faceAngles
                _ = engineState.bindPlatformCollisionOwner(id, surfaceIDs: [spec.surfaceIdentity])
            }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64NoOpObjectEffectRecord(objectID: id, output: output); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { registered.remove(id); modes.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }

    private static func mode(for behaviorIdentity: UInt64) -> Mode {
        switch behaviorIdentity {
        case Self.iglooIdentity: return .igloo
        case Self.bigSnowmanWholeIdentity: return .bigSnowmanWhole
        case Self.ukikiCageChildIdentity: return .ukikiCageChild
        case Self.sunkenShipPart2Identity, Self.sunkenShipSetRotationIdentity: return .sunkenShipPart2
        case Self.towerIdentity:
            return .staticCollision(.init(dataIdentity: 0x77665F746F776572, surfaceIdentity: 1, collisionDistance: 3000, drawingDistance: 20000, room: -1, faceAngles: .zero))
        case Self.bulletBillCannonIdentity:
            return .staticCollision(.init(dataIdentity: 0x77665F626263, surfaceIdentity: 2, collisionDistance: 300, drawingDistance: 4000, room: -1, faceAngles: .zero))
        case Self.lllHexagonalMeshIdentity:
            return .staticCollision(.init(dataIdentity: 0x6C6C6C5F686D, surfaceIdentity: 3, collisionDistance: 1000, drawingDistance: 4000, room: -1, faceAngles: .zero))
        case Self.hiddenStaircaseStepIdentity:
            return .staticCollision(.init(dataIdentity: 0x6262685F7374, surfaceIdentity: 4, collisionDistance: 1000, drawingDistance: 4000, room: 1, faceAngles: .zero))
        case Self.pillarBaseIdentity:
            return .staticCollision(.init(dataIdentity: 0x6A72625F7062, surfaceIdentity: 5, collisionDistance: 1000, drawingDistance: 4000, room: -1, faceAngles: .zero))
        case Self.inSunkenShipIdentity:
            return .staticCollision(.init(dataIdentity: 0x6A72625F73686970, surfaceIdentity: 6, collisionDistance: 4000, drawingDistance: 4000, room: -1, faceAngles: .init(pitch: 0xE958, yaw: 0xEE6C, roll: 0x0C80)))
        case Self.inSunkenShip2Identity:
            return .staticCollision(.init(dataIdentity: 0x6A72625F736832, surfaceIdentity: 7, collisionDistance: 4000, drawingDistance: 4000, room: -1, faceAngles: .init(pitch: 0xE958, yaw: 0xEE6C, roll: 0x0C80)))
        case Self.mantaRayRingManagerIdentity, Self.betaFishSplashSpawnerIdentity: return .persistentNoOp
        default: return .breakOnly
        }
    }
}
