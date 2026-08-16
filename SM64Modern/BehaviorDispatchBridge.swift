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
    case bulletBill = 10
    case goomba = 11
    case spiny = 12
    case snufit = 13
    case whomp = 14
    case heaveHo = 15
    case chuckya = 16
    case skeeter = 17
    case bully = 18
    case enemyLakitu = 19
    case chainChomp = 20
    case chainChompRelease = 21
    case pokey = 22
    case scuttlebug = 23
    case bobombBuddy = 24
    case bowserShockWave = 25
    case bowserKey = 26
    case bouncingFireball = 27
    case kingBobomb = 28
    case slWalkingPenguin = 29
    case smallPenguin = 30
    case koopaShell = 31
    case bowserKeyCutscene = 32
    case explosion = 33
    case moneybag = 34
    case waterBomb = 35
    case eyerok = 36
    case mrI = 37
    case racingPenguin = 38
    case yoshi = 39
    case bowserBomb = 40
    case tuxiesMother = 41
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
    let bulletBillEffects: [SM64BulletBillObjectEffectRecord]
    let bulletBillDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let goombaEffects: [SM64GoombaObjectEffectRecord]
    let goombaRespawnRequests: [SM64GoombaRespawnRequest]
    let goombaDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let spinyEffects: [SM64SpinyObjectEffectRecord]
    let spinyDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let snufitEffects: [SM64SnufitObjectEffectRecord]
    let snufitDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let whompEffects: [SM64WhompObjectEffectRecord]
    let whompDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let heaveHoEffects: [SM64HeaveHoObjectEffectRecord]
    let heaveHoDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let chuckyaEffects: [SM64ChuckyaObjectEffectRecord]
    let chuckyaDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let skeeterEffects: [SM64SkeeterObjectEffectRecord]
    let skeeterDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let bullyEffects: [SM64BullyObjectEffectRecord]
    let bullyDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let enemyLakituEffects: [SM64EnemyLakituObjectEffectRecord]
    let chainChompEffects: [SM64ChainChompObjectEffectRecord]
    let chainChompDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let chainChompReleaseEffects: [SM64ChainChompReleaseObjectEffectRecord]
    let chainChompReleaseRequests: [SM64ObjectID]
    let chainChompReleaseDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let pokeyEffects: [SM64PokeyObjectEffectRecord]
    let pokeyDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let scuttlebugEffects: [SM64ScuttlebugObjectEffectRecord]
    let scuttlebugDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let bobombBuddyEffects: [SM64BobombBuddyObjectEffect]
    let bobombBuddyDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let bowserShockWaveEffects: [SM64BowserShockWaveObjectEffectRecord]
    let bowserKeyEffects: [SM64BowserKeyObjectEffectRecord]
    let bouncingFireballEffects: [SM64BouncingFireballObjectEffectRecord]
    let kingBobombEffects: [SM64KingBobombObjectEffect]
    let kingBobombDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let slWalkingPenguinEffects: [SM64SLWalkingPenguinObjectEffect]
    let smallPenguinEffects: [SM64SmallPenguinObjectEffect]
    let smallPenguinDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let koopaShellEffects: [SM64KoopaShellObjectEffectRecord]
    let koopaShellDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let bowserKeyCutsceneEffects: [SM64BowserKeyCutsceneObjectEffectRecord]
    let explosionEffects: [SM64ExplosionObjectEffectRecord]
    let explosionDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let moneybagEffects: [SM64MoneybagObjectEffectRecord]
    let moneybagDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let waterBombEffects: [SM64WaterBombObjectEffectRecord]
    let waterBombDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let eyerokEffects: [SM64EyerokObjectEffectRecord]
    let eyerokDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let mrIEffects: [SM64MrIObjectEffectRecord]
    let mrIDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let racingPenguinEffects: [SM64RacingPenguinObjectEffect]
    let racingPenguinDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let yoshiEffects: [SM64YoshiObjectEffect]
    let yoshiDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let bowserBombEffects: [SM64BowserBombObjectEffectRecord]
    let bowserBombDeliveries: [SM64OwnerThreadEffectDeliveryResult]
    let tuxiesMotherEffects: [SM64TuxiesMotherObjectEffect]
    let tuxiesMotherDeliveries: [SM64OwnerThreadEffectDeliveryResult]
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
    let bulletBill: SM64BulletBillObjectBridge
    let goomba: SM64GoombaObjectBridge
    let spiny: SM64SpinyObjectBridge
    let snufit: SM64SnufitObjectBridge
    let whomp: SM64WhompObjectBridge
    let heaveHo: SM64HeaveHoObjectBridge
    let chuckya: SM64ChuckyaObjectBridge
    let skeeter: SM64SkeeterObjectBridge
    let bully: SM64BullyObjectBridge
    let enemyLakitu: SM64EnemyLakituObjectBridge
    let chainChomp: SM64ChainChompObjectBridge
    let chainChompRelease: SM64ChainChompReleaseObjectBridge
    let pokey: SM64PokeyObjectBridge
    let scuttlebug: SM64ScuttlebugObjectBridge
    let bobombBuddy: SM64BobombBuddyObjectBridge
    let bowserShockWave: SM64BowserShockWaveObjectBridge
    let bowserKey: SM64BowserKeyObjectBridge
    let bouncingFireball: SM64BouncingFireballObjectBridge
    let kingBobomb: SM64KingBobombObjectBridge
    let slWalkingPenguin: SM64SLWalkingPenguinObjectBridge
    let smallPenguin: SM64SmallPenguinObjectBridge
    let koopaShell: SM64KoopaShellObjectBridge
    let bowserKeyCutscene: SM64BowserKeyCutsceneObjectBridge
    let explosion: SM64ExplosionObjectBridge
    let moneybag: SM64MoneybagObjectBridge
    let waterBomb: SM64WaterBombObjectBridge
    let eyerok: SM64EyerokObjectBridge
    let mrI: SM64MrIObjectBridge
    let racingPenguin: SM64RacingPenguinObjectBridge
    let yoshi: SM64YoshiObjectBridge
    let bowserBomb: SM64BowserBombObjectBridge
    let tuxiesMother: SM64TuxiesMotherObjectBridge
    private(set) var eventLog: [SM64BehaviorDispatchEvent] = []

    init(scheduler: SM64ObjectScheduler = SM64ObjectScheduler()) {
        self.scheduler = scheduler
        self.decorativePendulum = SM64DecorativePendulumObjectBridge(scheduler: scheduler)
        let sharedRespawner = SM64RespawnerObjectBridge(scheduler: scheduler)
        self.respawner = sharedRespawner
        self.amp = SM64AmpObjectBridge(scheduler: scheduler)
        self.boo = SM64BooObjectBridge(scheduler: scheduler)
        self.bobomb = SM64BobombObjectBridge(scheduler: scheduler)
        self.bird = SM64BirdObjectBridge(scheduler: scheduler)
        self.swoop = SM64SwoopObjectBridge(scheduler: scheduler)
        self.piranhaPlant = SM64PiranhaPlantObjectBridge(scheduler: scheduler)
        self.bigBoo = SM64BigBooObjectBridge(scheduler: scheduler)
        self.flyGuy = SM64FlyGuyObjectBridge(scheduler: scheduler)
        self.bulletBill = SM64BulletBillObjectBridge(scheduler: scheduler)
        self.goomba = SM64GoombaObjectBridge(scheduler: scheduler)
        let sharedSpiny = SM64SpinyObjectBridge(scheduler: scheduler)
        self.spiny = sharedSpiny
        self.snufit = SM64SnufitObjectBridge(scheduler: scheduler)
        self.whomp = SM64WhompObjectBridge(scheduler: scheduler)
        self.heaveHo = SM64HeaveHoObjectBridge(scheduler: scheduler)
        self.chuckya = SM64ChuckyaObjectBridge(scheduler: scheduler)
        self.skeeter = SM64SkeeterObjectBridge(scheduler: scheduler)
        self.bully = SM64BullyObjectBridge(scheduler: scheduler)
        self.enemyLakitu = SM64EnemyLakituObjectBridge(scheduler: scheduler, spinyBridge: sharedSpiny)
        self.chainChomp = SM64ChainChompObjectBridge(scheduler: scheduler)
        self.chainChompRelease = SM64ChainChompReleaseObjectBridge(scheduler: scheduler)
        self.pokey = SM64PokeyObjectBridge(scheduler: scheduler)
        self.scuttlebug = SM64ScuttlebugObjectBridge(scheduler: scheduler)
        self.bobombBuddy = SM64BobombBuddyObjectBridge(scheduler: scheduler)
        self.bowserShockWave = SM64BowserShockWaveObjectBridge(scheduler: scheduler)
        self.bowserKey = SM64BowserKeyObjectBridge(scheduler: scheduler)
        self.bouncingFireball = SM64BouncingFireballObjectBridge(scheduler: scheduler)
        self.kingBobomb = SM64KingBobombObjectBridge(scheduler: scheduler)
        self.slWalkingPenguin = SM64SLWalkingPenguinObjectBridge(scheduler: scheduler)
        self.smallPenguin = SM64SmallPenguinObjectBridge(scheduler: scheduler)
        self.koopaShell = SM64KoopaShellObjectBridge(scheduler: scheduler)
        self.bowserKeyCutscene = SM64BowserKeyCutsceneObjectBridge(scheduler: scheduler)
        self.explosion = SM64ExplosionObjectBridge(scheduler: scheduler)
        self.moneybag = SM64MoneybagObjectBridge(scheduler: scheduler)
        self.waterBomb = SM64WaterBombObjectBridge(scheduler: scheduler)
        self.eyerok = SM64EyerokObjectBridge(scheduler: scheduler)
        self.mrI = SM64MrIObjectBridge(scheduler: scheduler)
        self.racingPenguin = SM64RacingPenguinObjectBridge(scheduler: scheduler)
        self.yoshi = SM64YoshiObjectBridge(scheduler: scheduler, respawnerBridge: sharedRespawner)
        self.bowserBomb = SM64BowserBombObjectBridge(scheduler: scheduler)
        self.tuxiesMother = SM64TuxiesMotherObjectBridge(scheduler: scheduler)
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
        case SM64BigBooObjectBridge.defaultBehaviorIdentity,
             SM64BigBooObjectBridge.staircaseBehaviorIdentity:
            return .bigBoo
        case SM64FlyGuyObjectBridge.defaultBehaviorIdentity,
             SM64FlyGuyObjectBridge.flameBehaviorIdentity:
            return .flyGuy
        case SM64BulletBillObjectBridge.defaultBehaviorIdentity:
            return .bulletBill
        case SM64GoombaObjectBridge.defaultBehaviorIdentity,
             SM64GoombaObjectBridge.defaultTripletSpawnerBehaviorIdentity:
            return .goomba
        case SM64SpinyObjectBridge.defaultBehaviorIdentity:
            return .spiny
        case SM64SnufitObjectBridge.defaultSnufitBehaviorIdentity,
             SM64SnufitObjectBridge.defaultBulletBehaviorIdentity:
            return .snufit
        case SM64WhompObjectBridge.defaultBehaviorIdentity:
            return .whomp
        case SM64HeaveHoObjectBridge.defaultBehaviorIdentity,
             SM64HeaveHoObjectBridge.throwChildBehaviorIdentity:
            return .heaveHo
        case SM64ChuckyaObjectBridge.defaultBehaviorIdentity,
             SM64ChuckyaObjectBridge.anchorBehaviorIdentity:
            return .chuckya
        case SM64SkeeterObjectBridge.defaultBehaviorIdentity,
             SM64SkeeterObjectBridge.defaultWaveBehaviorIdentity:
            return .skeeter
        case SM64BullyObjectBridge.defaultBehaviorIdentity,
             SM64BullyObjectBridge.starBehaviorIdentity,
             SM64BullyObjectBridge.bridgeBehaviorIdentity,
             SM64BullyObjectBridge.coinBehaviorIdentity:
            return .bully
        case SM64EnemyLakituObjectBridge.defaultBehaviorIdentity:
            return .enemyLakitu
        case SM64ChainChompObjectBridge.defaultBehaviorIdentity,
             SM64ChainChompObjectBridge.segmentBehaviorIdentity:
            return .chainChomp
        case SM64ChainChompReleaseObjectBridge.postBehaviorIdentity,
             SM64ChainChompReleaseObjectBridge.gateBehaviorIdentity:
            return .chainChompRelease
        case SM64PokeyObjectBridge.defaultBehaviorIdentity,
             SM64PokeyObjectBridge.defaultBodyBehaviorIdentity:
            return .pokey
        case SM64ScuttlebugObjectBridge.defaultSpawnerBehaviorIdentity,
             SM64ScuttlebugObjectBridge.defaultBugBehaviorIdentity:
            return .scuttlebug
        case SM64BobombBuddyObjectBridge.defaultBehaviorIdentity,
             SM64BobombBuddyObjectBridge.cannonClosedBehaviorIdentity:
            return .bobombBuddy
        case SM64BowserShockWaveObjectBridge.defaultBehaviorIdentity:
            return .bowserShockWave
        case SM64BowserKeyObjectBridge.defaultBehaviorIdentity:
            return .bowserKey
        case SM64BouncingFireballObjectBridge.fireballBehaviorIdentity,
             SM64BouncingFireballObjectBridge.flameBehaviorIdentity:
            return .bouncingFireball
        case SM64KingBobombObjectBridge.defaultBehaviorIdentity:
            return .kingBobomb
        case SM64SLWalkingPenguinObjectBridge.defaultBehaviorIdentity:
            return .slWalkingPenguin
        case SM64SmallPenguinObjectBridge.defaultBehaviorIdentity,
             SM64SmallPenguinObjectBridge.babyBehaviorIdentity:
            return .smallPenguin
        case SM64KoopaShellObjectBridge.defaultShellBehaviorIdentity,
             SM64KoopaShellObjectBridge.defaultUnderwaterBehaviorIdentity:
            return .koopaShell
        case SM64BowserKeyCutsceneObjectBridge.unlockDoorBehaviorIdentity,
             SM64BowserKeyCutsceneObjectBridge.courseExitBehaviorIdentity:
            return .bowserKeyCutscene
        case SM64ExplosionObjectBridge.defaultBehaviorIdentity,
             SM64ExplosionObjectBridge.bubbleBehaviorIdentity,
             SM64ExplosionObjectBridge.groundSmokeBehaviorIdentity:
            return .explosion
        case SM64MoneybagObjectBridge.moneybagBehaviorIdentity,
             SM64MoneybagObjectBridge.hiddenBehaviorIdentity:
            return .moneybag
        case SM64WaterBombObjectBridge.defaultSpawnerBehaviorIdentity,
             SM64WaterBombObjectBridge.defaultBombBehaviorIdentity:
            return .waterBomb
        case SM64EyerokObjectBridge.defaultBehaviorIdentity,
             SM64EyerokObjectBridge.handBehaviorIdentity:
            return .eyerok
        case SM64MrIObjectBridge.defaultEyeBehaviorIdentity,
             SM64MrIObjectBridge.bodyBehaviorIdentity,
             SM64MrIObjectBridge.particleBehaviorIdentity:
            return .mrI
        case SM64RacingPenguinObjectBridge.defaultBehaviorIdentity,
             SM64RacingPenguinObjectBridge.finishLineBehaviorIdentity,
             SM64RacingPenguinObjectBridge.shortcutBehaviorIdentity,
             SM64RacingPenguinObjectBridge.smokeBehaviorIdentity:
            return .racingPenguin
        case SM64YoshiObjectBridge.defaultBehaviorIdentity:
            return .yoshi
        case SM64BowserBombObjectBridge.bombBehaviorIdentity,
             SM64BowserBombObjectBridge.explosionBehaviorIdentity,
             SM64BowserBombObjectBridge.smokeBehaviorIdentity:
            return .bowserBomb
        case SM64TuxiesMotherObjectBridge.defaultMotherBehaviorIdentity:
            return .tuxiesMother
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
        for id in bulletBill.registeredIDs { bulletBill.remove(id) }
        for id in goomba.registeredIDs { goomba.remove(id) }
        for id in spiny.registeredIDs { spiny.remove(id) }
        for id in snufit.registeredIDs { snufit.remove(id) }
        for id in whomp.registeredIDs { whomp.remove(id) }
        for id in heaveHo.registeredIDs { heaveHo.remove(id) }
        for id in chuckya.registeredIDs { chuckya.remove(id) }
        for id in skeeter.registeredIDs { skeeter.remove(id) }
        for id in bully.registeredIDs { bully.remove(id) }
        for id in enemyLakitu.registeredIDs { enemyLakitu.remove(id) }
        for id in chainChomp.registeredIDs { chainChomp.remove(id) }
        for id in chainChompRelease.registeredIDs { chainChompRelease.remove(id) }
        for id in pokey.registeredIDs { pokey.remove(id) }
        for id in scuttlebug.registeredIDs { scuttlebug.remove(id) }
        for id in bobombBuddy.registeredIDs { bobombBuddy.remove(id) }
        for id in bowserShockWave.registeredIDs { bowserShockWave.remove(id) }
        for id in bowserKey.registeredIDs { bowserKey.remove(id) }
        for id in bouncingFireball.registeredIDs { bouncingFireball.remove(id) }
        for id in kingBobomb.registeredIDs { kingBobomb.remove(id) }
        for id in slWalkingPenguin.registeredIDs { slWalkingPenguin.remove(id) }
        for id in smallPenguin.registeredIDs { smallPenguin.remove(id) }
        for id in koopaShell.registeredIDs { koopaShell.remove(id) }
        for id in bowserKeyCutscene.registeredIDs { bowserKeyCutscene.remove(id) }
        for id in explosion.registeredIDs { explosion.remove(id) }
        for id in moneybag.registeredIDs { moneybag.remove(id) }
        for id in waterBomb.registeredIDs { waterBomb.remove(id) }
        for id in eyerok.registeredIDs { eyerok.remove(id) }
        for id in mrI.registeredIDs { mrI.remove(id) }
        for id in racingPenguin.registeredIDs { racingPenguin.remove(id) }
        for id in yoshi.registeredIDs { yoshi.remove(id) }
        for id in bowserBomb.registeredIDs { bowserBomb.remove(id) }
        for id in tuxiesMother.registeredIDs { tuxiesMother.remove(id) }
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
        bulletBill.beginExternalTick()
        goomba.beginExternalTick()
        snufit.beginExternalTick()
        whomp.beginExternalTick()
        heaveHo.beginExternalTick()
        chuckya.beginExternalTick()
        skeeter.beginExternalTick()
        bully.beginExternalTick()
        enemyLakitu.beginExternalTick()
        chainChomp.beginExternalTick()
        chainChompRelease.beginExternalTick()
        pokey.beginExternalTick()
        scuttlebug.beginExternalTick()
        bobombBuddy.beginExternalTick()
        bowserShockWave.beginExternalTick()
        bowserKey.beginExternalTick()
        bowserKey.beginExternalTick()
        bouncingFireball.beginExternalTick()
        kingBobomb.beginExternalTick()
        slWalkingPenguin.beginExternalTick()
        smallPenguin.beginExternalTick()
        koopaShell.beginExternalTick()
        bowserKeyCutscene.beginExternalTick()
        explosion.beginExternalTick()
        moneybag.beginExternalTick()
        waterBomb.beginExternalTick()
        eyerok.beginExternalTick()
        mrI.beginExternalTick()
        racingPenguin.beginExternalTick()
        yoshi.beginExternalTick()
        bowserBomb.beginExternalTick()
        tuxiesMother.beginExternalTick()
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
    func spawnBulletBill(
        in engineState: SM64SwiftEngineState,
        initialMoveYaw: Int16 = 0,
        moveYaw: Int16? = nil
    ) throws -> SM64ObjectID {
        try bulletBill.spawnBulletBill(
            in: engineState,
            initialMoveYaw: initialMoveYaw,
            moveYaw: moveYaw
        )
    }

    @discardableResult
    func spawnGoomba(
        in engineState: SM64SwiftEngineState,
        size: SM64GoombaSize = .regular,
        moveAngleYaw: Int16 = 0
    ) throws -> SM64ObjectID {
        try goomba.spawnGoomba(
            in: engineState,
            size: size,
            moveAngleYaw: moveAngleYaw
        )
    }

    @discardableResult
    func spawnGoombaTripletSpawner(
        in engineState: SM64SwiftEngineState,
        size: SM64GoombaSize = .regular,
        extraGoombas: UInt8 = 0
    ) throws -> SM64ObjectID {
        try goomba.spawnTripletSpawner(
            in: engineState,
            size: size,
            extraGoombas: extraGoombas
        )
    }

    @discardableResult
    func spawnSpiny(
        in engineState: SM64SwiftEngineState,
        action: SM64SpinyAction = .walk,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        try spiny.spawnSpiny(
            in: engineState,
            action: action,
            parent: parent
        )
    }

    @discardableResult
    func spawnSnufit(
        in engineState: SM64SwiftEngineState,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        moveYaw: Int16 = 0
    ) throws -> SM64ObjectID {
        try snufit.spawnSnufit(
            in: engineState,
            positionX: positionX,
            positionY: positionY,
            positionZ: positionZ,
            moveYaw: moveYaw
        )
    }

    @discardableResult
    func spawnWhomp(
        in engineState: SM64SwiftEngineState,
        size: SM64WhompSize = .normal,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        action: SM64WhompAction = .initialize
    ) throws -> SM64ObjectID {
        try whomp.spawnWhomp(
            in: engineState,
            size: size,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw,
            action: action
        )
    }

    @discardableResult
    func spawnHeaveHo(
        in engineState: SM64SwiftEngineState,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0
    ) throws -> SM64ObjectID {
        try heaveHo.spawnHeaveHo(
            in: engineState,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw
        )
    }

    @discardableResult
    func spawnChuckya(
        in engineState: SM64SwiftEngineState,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0
    ) throws -> SM64ObjectID {
        try chuckya.spawnChuckya(
            in: engineState,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw
        )
    }

    @discardableResult
    func spawnSkeeter(
        in engineState: SM64SwiftEngineState,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0
    ) throws -> SM64ObjectID {
        try skeeter.spawnSkeeter(
            in: engineState,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw
        )
    }

    @discardableResult
    func spawnBully(
        in engineState: SM64SwiftEngineState,
        size: SM64BullySize,
        subtype: SM64BullySubtype = .generic,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        action: SM64BullyAction = .patrol
    ) throws -> SM64ObjectID {
        try bully.spawnBully(
            in: engineState,
            size: size,
            subtype: subtype,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw,
            action: action
        )
    }

    @discardableResult
    func spawnEnemyLakitu(
        in engineState: SM64SwiftEngineState,
        model: UInt32 = SM64EnemyLakituObjectBridge.defaultLakituModel,
        behaviorIdentity: UInt64 = SM64EnemyLakituObjectBridge.defaultBehaviorIdentity,
        drawingDistance: Float = 4_000
    ) throws -> SM64ObjectID {
        try enemyLakitu.spawnLakitu(
            in: engineState,
            model: model,
            behaviorIdentity: behaviorIdentity,
            drawingDistance: drawingDistance
        )
    }

    @discardableResult
    func spawnChainChomp(
        in engineState: SM64SwiftEngineState,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0
    ) throws -> SM64ObjectID {
        try chainChomp.spawnChainChomp(
            in: engineState,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw
        )
    }

    @discardableResult
    func spawnChainChompPost(
        in engineState: SM64SwiftEngineState,
        parent: SM64ObjectID,
        homeY: Float = 0
    ) throws -> SM64ObjectID {
        try chainChompRelease.spawnWoodenPost(in: engineState, parent: parent, homeY: homeY)
    }

    @discardableResult
    func spawnChainChompGate(
        in engineState: SM64SwiftEngineState,
        parent: SM64ObjectID,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try chainChompRelease.spawnGate(in: engineState, parent: parent, position: position)
    }

    @discardableResult
    func spawnPokey(
        in engineState: SM64SwiftEngineState,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0
    ) throws -> SM64ObjectID {
        try pokey.spawnPokey(
            in: engineState,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw
        )
    }

    @discardableResult
    func spawnScuttlebugSpawner(
        in engineState: SM64SwiftEngineState,
        model: UInt32 = SM64ScuttlebugObjectBridge.spawnerModel,
        behaviorIdentity: UInt64 = SM64ScuttlebugObjectBridge.defaultSpawnerBehaviorIdentity
    ) throws -> SM64ObjectID {
        try scuttlebug.spawnSpawner(
            in: engineState,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
    }

    @discardableResult
    func spawnScuttlebug(
        in engineState: SM64SwiftEngineState,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        parent: SM64ObjectID? = nil,
        model: UInt32 = SM64ScuttlebugObjectBridge.bugModel,
        behaviorIdentity: UInt64 = SM64ScuttlebugObjectBridge.defaultBugBehaviorIdentity
    ) throws -> SM64ObjectID {
        try scuttlebug.spawnBug(
            in: engineState,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw,
            parent: parent,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
    }

    @discardableResult
    func spawnBobombBuddy(
        in engineState: SM64SwiftEngineState,
        role: Int32 = SM64BobombBuddyBehavior.adviceRole,
        action: Int32 = SM64BobombBuddyBehavior.idleAction,
        cannonStatus: Int32 = SM64BobombBuddyBehavior.cannonUnopened,
        hasTalked: Bool = false,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int16 = 0,
        behaviorIdentity: UInt64 = SM64BobombBuddyObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        try bobombBuddy.spawnBuddy(
            in: engineState,
            role: role,
            action: action,
            cannonStatus: cannonStatus,
            hasTalked: hasTalked,
            position: position,
            moveYaw: moveYaw,
            behaviorIdentity: behaviorIdentity
        )
    }

    @discardableResult
    func spawnBowserShockWave(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        model: UInt32 = SM64BowserShockWaveObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64BowserShockWaveObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        try bowserShockWave.spawnShockWave(
            in: engineState,
            position: position,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
    }

    @discardableResult
    func spawnBowserKey(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        faceYaw: Int16 = 0,
        angleVelocityYaw: Int16 = 0,
        model: UInt32 = SM64BowserKeyObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64BowserKeyObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        try bowserKey.spawnKey(
            in: engineState,
            position: position,
            faceYaw: faceYaw,
            angleVelocityYaw: angleVelocityYaw,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
    }

    @discardableResult
    func spawnBouncingFireball(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        behaviorIdentity: UInt64 = SM64BouncingFireballObjectBridge.fireballBehaviorIdentity
    ) throws -> SM64ObjectID {
        try bouncingFireball.spawnFireball(
            in: engineState,
            position: position,
            behaviorIdentity: behaviorIdentity
        )
    }

    @discardableResult
    func spawnBouncingFireballFlame(
        in engineState: SM64SwiftEngineState,
        parent: SM64ObjectID? = nil,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try bouncingFireball.spawnFlame(
            in: engineState,
            parent: parent,
            position: position
        )
    }

    @discardableResult
    func spawnKingBobomb(
        in engineState: SM64SwiftEngineState,
        homeY: Float = 0,
        positionY: Float? = nil,
        position: SM64ObjectVector3? = nil,
        homePosition: SM64ObjectVector3? = nil,
        wallHitboxRadius: Float = SM64KingBobombObjectBridge.defaultWallHitboxRadius,
        action: Int32 = SM64KingBobombBehavior.initializeAction,
        model: UInt32 = SM64KingBobombObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64KingBobombObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        try kingBobomb.spawnKingBobomb(
            in: engineState,
            homeY: homeY,
            positionY: positionY,
            position: position,
            homePosition: homePosition,
            wallHitboxRadius: wallHitboxRadius,
            action: action,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
    }

    @discardableResult
    func spawnSLWalkingPenguin(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int16 = 0,
        wallHitboxRadius: Float = 0,
        model: UInt32 = SM64SLWalkingPenguinObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64SLWalkingPenguinObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        try slWalkingPenguin.spawnPenguin(
            in: engineState,
            position: position,
            moveYaw: moveYaw,
            wallHitboxRadius: wallHitboxRadius,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
    }

    @discardableResult
    func spawnSmallPenguin(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int16 = 0,
        wallHitboxRadius: Float = 0,
        model: UInt32 = SM64SmallPenguinObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64SmallPenguinObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        try smallPenguin.spawnPenguin(
            in: engineState,
            position: position,
            moveYaw: moveYaw,
            wallHitboxRadius: wallHitboxRadius,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
    }

    @discardableResult
    func spawnKoopaShell(
        in engineState: SM64SwiftEngineState,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        moveYaw: Int16 = 0,
        forwardVelocity: Float = 0,
        parent: SM64ObjectID? = nil,
        model: UInt32 = SM64KoopaShellObjectBridge.shellModel,
        behaviorIdentity: UInt64 = SM64KoopaShellObjectBridge.defaultShellBehaviorIdentity
    ) throws -> SM64ObjectID {
        try koopaShell.spawnShell(
            in: engineState,
            positionX: positionX,
            positionY: positionY,
            positionZ: positionZ,
            moveYaw: moveYaw,
            forwardVelocity: forwardVelocity,
            parent: parent,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
    }

    @discardableResult
    func spawnKoopaUnderwaterShell(
        in engineState: SM64SwiftEngineState,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        model: UInt32 = SM64KoopaShellObjectBridge.shellModel,
        behaviorIdentity: UInt64 = SM64KoopaShellObjectBridge.defaultUnderwaterBehaviorIdentity
    ) throws -> SM64ObjectID {
        try koopaShell.spawnUnderwaterShell(
            in: engineState,
            positionX: positionX,
            positionY: positionY,
            positionZ: positionZ,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
    }

    @discardableResult
    func spawnBowserKeyCutscene(
        kind: SM64BowserKeyCutsceneKind,
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        model: UInt32 = SM64BowserKeyCutsceneObjectBridge.defaultModel
    ) throws -> SM64ObjectID {
        try bowserKeyCutscene.spawn(
            kind: kind,
            in: engineState,
            position: position,
            model: model
        )
    }

    @discardableResult
    func spawnExplosion(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        model: UInt32 = SM64ExplosionObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64ExplosionObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        try explosion.spawnExplosion(
            in: engineState,
            position: position,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
    }

    @discardableResult
    func spawnMoneybag(
        in engineState: SM64SwiftEngineState,
        action: SM64MoneybagAction = .appear,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        floorHeight: Float = 0,
        moveYaw: Int16 = 0
    ) throws -> SM64ObjectID {
        try moneybag.spawnMoneybag(
            in: engineState,
            action: action,
            positionX: positionX,
            positionY: positionY,
            positionZ: positionZ,
            floorHeight: floorHeight,
            moveYaw: moveYaw
        )
    }

    @discardableResult
    func spawnHiddenMoneybagCoin(
        in engineState: SM64SwiftEngineState,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0
    ) throws -> SM64ObjectID {
        try moneybag.spawnHiddenCoin(
            in: engineState,
            positionX: positionX,
            positionY: positionY,
            positionZ: positionZ
        )
    }

    @discardableResult
    func spawnWaterBombSpawner(
        in engineState: SM64SwiftEngineState,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        radiusParameter: UInt16 = 0
    ) throws -> SM64ObjectID {
        try waterBomb.spawnSpawner(
            in: engineState,
            positionX: positionX,
            positionY: positionY,
            positionZ: positionZ,
            radiusParameter: radiusParameter
        )
    }

    @discardableResult
    func spawnWaterBomb(
        in engineState: SM64SwiftEngineState,
        action: SM64WaterBombAction = .initialize,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        try waterBomb.spawnBomb(
            in: engineState,
            action: action,
            positionX: positionX,
            positionY: positionY,
            positionZ: positionZ,
            parent: parent
        )
    }

    @discardableResult
    func spawnEyerok(
        in engineState: SM64SwiftEngineState,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        action: SM64EyerokBossAction = .sleep
    ) throws -> SM64ObjectID {
        try eyerok.spawnBoss(
            in: engineState,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            action: action
        )
    }

    @discardableResult
    func spawnMrI(
        in engineState: SM64SwiftEngineState,
        isKing: Bool = false,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        model: UInt32 = SM64MrIObjectBridge.eyeModel,
        behaviorIdentity: UInt64 = SM64MrIObjectBridge.defaultEyeBehaviorIdentity
    ) throws -> SM64ObjectID {
        try mrI.spawnMrI(
            in: engineState,
            isKing: isKing,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
    }

    @discardableResult
    func spawnRacingPenguin(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int16 = 0,
        model: UInt32 = SM64RacingPenguinObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64RacingPenguinObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        try racingPenguin.spawnPenguin(
            in: engineState,
            position: position,
            moveYaw: moveYaw,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
    }

    @discardableResult
    func spawnYoshi(
        in engineState: SM64SwiftEngineState,
        action: Int32 = SM64YoshiBehavior.idleAction,
        position: SM64ObjectVector3 = SM64ObjectVector3(x: 0, y: 3_174, z: -5_625),
        moveYaw: Int16 = 0,
        model: UInt32 = SM64YoshiObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64YoshiObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        try yoshi.spawnYoshi(
            in: engineState,
            action: action,
            position: position,
            moveYaw: moveYaw,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
    }

    @discardableResult
    func spawnBowserBomb(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        model: UInt32 = SM64BowserBombObjectBridge.bombModel,
        behaviorIdentity: UInt64 = SM64BowserBombObjectBridge.bombBehaviorIdentity
    ) throws -> SM64ObjectID {
        try bowserBomb.spawnBomb(
            in: engineState,
            position: position,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
    }

    @discardableResult
    func spawnTuxiesMother(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int16 = 0,
        model: UInt32 = SM64TuxiesMotherObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64TuxiesMotherObjectBridge.defaultMotherBehaviorIdentity
    ) throws -> SM64ObjectID {
        try tuxiesMother.spawnMother(
            in: engineState,
            position: position,
            moveYaw: moveYaw,
            model: model,
            behaviorIdentity: behaviorIdentity
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
        bulletBill.beginExternalTick()
        goomba.beginExternalTick()
        snufit.beginExternalTick()
        whomp.beginExternalTick()
        heaveHo.beginExternalTick()
        chuckya.beginExternalTick()
        skeeter.beginExternalTick(globalFrame: engineState.globals.frame)
        bully.beginExternalTick()
        enemyLakitu.beginExternalTick()
        chainChomp.beginExternalTick()
        chainChompRelease.beginExternalTick()
        pokey.beginExternalTick(globalFrame: engineState.globals.frame)
        scuttlebug.beginExternalTick()
        bobombBuddy.beginExternalTick()
        bowserShockWave.beginExternalTick()
        bouncingFireball.beginExternalTick()
        kingBobomb.beginExternalTick()
        slWalkingPenguin.beginExternalTick()
        smallPenguin.beginExternalTick()
        koopaShell.beginExternalTick()
        bowserKeyCutscene.beginExternalTick()
        explosion.beginExternalTick()
        moneybag.beginExternalTick()
        waterBomb.beginExternalTick()
        eyerok.beginExternalTick()
        mrI.beginExternalTick()
        racingPenguin.beginExternalTick(state: engineState)
        yoshi.beginExternalTick()
        bowserBomb.beginExternalTick()
        tuxiesMother.beginExternalTick()

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
            case .bulletBill:
                _ = self.bulletBill.updateInline(id, pool: pool)
            case .goomba:
                _ = self.goomba.updateInline(id, pool: pool)
            case .spiny:
                _ = self.spiny.updateInline(id, pool: pool)
            case .snufit:
                _ = self.snufit.updateInline(id, pool: pool)
            case .whomp:
                _ = self.whomp.updateInline(id, pool: pool)
            case .heaveHo:
                _ = self.heaveHo.updateInline(id, pool: pool)
            case .chuckya:
                _ = self.chuckya.updateInline(id, pool: pool)
            case .skeeter:
                _ = self.skeeter.updateInline(id, pool: pool)
            case .bully:
                _ = self.bully.updateInline(id, pool: pool)
            case .enemyLakitu:
                _ = self.enemyLakitu.updateInline(id, pool: pool)
            case .chainChomp:
                _ = self.chainChomp.updateInline(id, pool: pool)
            case .chainChompRelease:
                _ = self.chainChompRelease.updateInline(id, pool: pool)
            case .pokey:
                _ = self.pokey.updateInline(id, pool: pool)
            case .scuttlebug:
                _ = self.scuttlebug.updateInline(id, pool: pool)
            case .bobombBuddy:
                _ = self.bobombBuddy.updateInline(id, state: engineState, pool: pool)
            case .bowserShockWave:
                _ = self.bowserShockWave.updateInline(
                    id,
                    pool: pool,
                    marioID: engineState.globals.marioObject
                )
            case .bowserKey:
                _ = self.bowserKey.updateInline(id, pool: pool)
            case .bouncingFireball:
                _ = self.bouncingFireball.updateInline(id, pool: pool)
            case .kingBobomb:
                _ = self.kingBobomb.updateInline(id, state: engineState, pool: pool)
            case .slWalkingPenguin:
                _ = self.slWalkingPenguin.updateInline(id, pool: pool)
            case .smallPenguin:
                _ = self.smallPenguin.updateInline(id, pool: pool)
            case .koopaShell:
                _ = self.koopaShell.updateInline(id, pool: pool)
            case .bowserKeyCutscene:
                _ = self.bowserKeyCutscene.updateInline(id, pool: pool)
            case .explosion:
                _ = self.explosion.updateInline(id, pool: pool)
            case .moneybag:
                _ = self.moneybag.updateInline(id, pool: pool)
            case .waterBomb:
                _ = self.waterBomb.updateInline(id, pool: pool)
            case .eyerok:
                _ = self.eyerok.updateInline(id, pool: pool)
            case .mrI:
                _ = self.mrI.updateInline(id, pool: pool)
            case .racingPenguin:
                _ = self.racingPenguin.updateInline(id, pool: pool)
            case .yoshi:
                _ = self.yoshi.updateInline(id, state: engineState, pool: pool)
            case .bowserBomb:
                _ = self.bowserBomb.updateInline(id, pool: pool)
            case .tuxiesMother:
                _ = self.tuxiesMother.updateInline(id, pool: pool)
            case .unmigrated:
                break
            }
        }

        enemyLakitu.finalizeExternalTick(pool: engineState.objects)

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
            bulletBill.remove(id)
            goomba.remove(id)
            spiny.remove(id)
            snufit.remove(id)
            whomp.remove(id)
            heaveHo.remove(id)
            chuckya.remove(id)
            skeeter.remove(id)
            bully.remove(id)
            enemyLakitu.remove(id)
            chainChomp.remove(id)
            chainChompRelease.remove(id)
            pokey.remove(id)
            scuttlebug.remove(id)
            bobombBuddy.remove(id)
            bowserShockWave.remove(id)
            bowserKey.remove(id)
            bouncingFireball.remove(id)
            kingBobomb.remove(id)
            slWalkingPenguin.remove(id)
            smallPenguin.remove(id)
            koopaShell.remove(id)
            bowserKeyCutscene.remove(id)
            explosion.remove(id)
            moneybag.remove(id)
            waterBomb.remove(id)
            eyerok.remove(id)
            mrI.remove(id)
            racingPenguin.remove(id, pool: engineState.objects)
            yoshi.remove(id)
            bowserBomb.remove(id)
            tuxiesMother.remove(id)
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
        for id in bulletBill.registeredIDs where engineState.objects.record(for: id) == nil {
            bulletBill.remove(id)
        }
        for id in goomba.registeredIDs where engineState.objects.record(for: id) == nil {
            goomba.remove(id)
        }
        for id in spiny.registeredIDs where engineState.objects.record(for: id) == nil {
            spiny.remove(id)
        }
        for id in snufit.registeredIDs where engineState.objects.record(for: id) == nil {
            snufit.remove(id)
        }
        for id in whomp.registeredIDs where engineState.objects.record(for: id) == nil {
            whomp.remove(id)
        }
        for id in heaveHo.registeredIDs where engineState.objects.record(for: id) == nil {
            heaveHo.remove(id)
        }
        for id in chuckya.registeredIDs where engineState.objects.record(for: id) == nil {
            chuckya.remove(id)
        }
        for id in skeeter.registeredIDs where engineState.objects.record(for: id) == nil {
            skeeter.remove(id)
        }
        for id in bully.registeredIDs where engineState.objects.record(for: id) == nil {
            bully.remove(id)
        }
        enemyLakitu.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        chainChomp.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        chainChompRelease.finalizeExternalTick(pool: engineState.objects)
        chainChompRelease.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        pokey.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        scuttlebug.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        bobombBuddy.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        bowserShockWave.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        bowserKey.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        bouncingFireball.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        kingBobomb.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        slWalkingPenguin.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        smallPenguin.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        koopaShell.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        bowserKeyCutscene.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        explosion.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        moneybag.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        waterBomb.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        eyerok.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        mrI.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        racingPenguin.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        yoshi.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        bowserBomb.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        tuxiesMother.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)

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
            flyGuyDeliveries: flyGuy.deliveryLog,
            bulletBillEffects: bulletBill.effectLog,
            bulletBillDeliveries: bulletBill.deliveryLog,
            goombaEffects: goomba.effectLog,
            goombaRespawnRequests: goomba.respawnRequests,
            goombaDeliveries: goomba.deliveryLog,
            spinyEffects: spiny.effectLog,
            spinyDeliveries: spiny.deliveryLog,
            snufitEffects: snufit.effectLog,
            snufitDeliveries: snufit.deliveryLog,
            whompEffects: whomp.effectLog,
            whompDeliveries: whomp.deliveryLog,
            heaveHoEffects: heaveHo.effectLog,
            heaveHoDeliveries: heaveHo.deliveryLog,
            chuckyaEffects: chuckya.effectLog,
            chuckyaDeliveries: chuckya.deliveryLog,
            skeeterEffects: skeeter.effectLog,
            skeeterDeliveries: skeeter.deliveryLog,
            bullyEffects: bully.effectLog,
            bullyDeliveries: bully.deliveryLog,
            enemyLakituEffects: enemyLakitu.effectLog,
            chainChompEffects: chainChomp.effectLog,
            chainChompDeliveries: chainChomp.deliveryLog,
            chainChompReleaseEffects: chainChompRelease.effectLog,
            chainChompReleaseRequests: chainChompRelease.releaseRequestLog,
            chainChompReleaseDeliveries: chainChompRelease.deliveryLog,
            pokeyEffects: pokey.effectLog,
            pokeyDeliveries: pokey.deliveryLog,
            scuttlebugEffects: scuttlebug.effectLog,
            scuttlebugDeliveries: scuttlebug.deliveryLog,
            bobombBuddyEffects: bobombBuddy.effectLog,
            bobombBuddyDeliveries: bobombBuddy.deliveryLog,
            bowserShockWaveEffects: bowserShockWave.effectLog,
            bowserKeyEffects: bowserKey.effectLog,
            bouncingFireballEffects: bouncingFireball.effectLog,
            kingBobombEffects: kingBobomb.effectLog,
            kingBobombDeliveries: kingBobomb.deliveryLog,
            slWalkingPenguinEffects: slWalkingPenguin.effectLog,
            smallPenguinEffects: smallPenguin.effectLog,
            smallPenguinDeliveries: smallPenguin.deliveryLog,
            koopaShellEffects: koopaShell.effectLog,
            koopaShellDeliveries: koopaShell.deliveryLog,
            bowserKeyCutsceneEffects: bowserKeyCutscene.effectLog,
            explosionEffects: explosion.effectLog,
            explosionDeliveries: explosion.deliveryLog,
            moneybagEffects: moneybag.effectLog,
            moneybagDeliveries: moneybag.deliveryLog,
            waterBombEffects: waterBomb.effectLog,
            waterBombDeliveries: waterBomb.deliveryLog,
            eyerokEffects: eyerok.effectLog,
            eyerokDeliveries: eyerok.deliveryLog,
            mrIEffects: mrI.effectLog,
            mrIDeliveries: mrI.deliveryLog,
            racingPenguinEffects: racingPenguin.effectLog,
            racingPenguinDeliveries: racingPenguin.deliveryLog,
            yoshiEffects: yoshi.effectLog,
            yoshiDeliveries: yoshi.deliveryLog,
            bowserBombEffects: bowserBomb.effectLog,
            bowserBombDeliveries: bowserBomb.deliveryLog,
            tuxiesMotherEffects: tuxiesMother.effectLog,
            tuxiesMotherDeliveries: tuxiesMother.deliveryLog
        )
    }
}
