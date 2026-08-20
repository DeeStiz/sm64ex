import Foundation

enum SM64BehaviorDispatchRoute: UInt16, Equatable, Sendable {
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
    case arrowLift = 42
    case elevator = 43
    case seesawPlatform = 44
    case swingPlatform = 45
    case rotatingPlatform = 46
    case ttcMovingBar = 47
    case ttcSpinner = 48
    case ttcTreadmill = 49
    case ttcPendulum = 50
    case ttcElevator = 51
    case ttcRotatingSolid = 52
    case ttc2DRotator = 53
    case ttcCog = 54
    case pyramidElevator = 55
    case pyramidMarker = 56
    case ttcPitBlock = 57
    case staticCheckeredPlatform = 58
    case bbhTiltingTrapPlatform = 59
    case lllSinkingPlatform = 60
    case wfRotatingWoodenPlatform = 61
    case rotatingOctagonalPlatform = 62
    case wfSolidTowerPlatform = 63
    case wfTowerPlatform = 64
    case wfSlidingPlatform = 65
    case wdwExpressElevator = 66
    case lllSinkingRockBlock = 67
    case lllMovingOctagonalMesh = 68
    case ferrisWheel = 69
    case checkerboardPlatform = 70
    case wfTowerPlatformGroup = 71
    case lllRotatingHexagonalPlatform = 72
    case lllRotatingHexFlame = 73
    case lllRotatingFireBar = 74
    case activatedBackAndForthPlatform = 75
    case bitfsSinkingPlatform = 76
    case dddMovingPole = 77
    case lllRotatingHexagonalRing = 78
    case lllFloatingWoodBridge = 79
    case squishablePlatform = 80
    case lllDrawbridge = 81
    case idleWaterWave = 82
    case waterfallSoundLoop = 83
    case volcanoSoundLoop = 84
    case tumblingBridge = 85
    case floatingPlatform = 86
    case slidingPlatform2 = 87
    case smallWaterWave = 88
    case ambientSoundLoop = 89
    case rotatingExclamationMark = 90
    case waterAirBubble = 91
    case objectBubble = 92
    case waterDroplet = 93
    case waterMist = 94
    case waterMist2 = 95
    case waterSplash = 96
    case bubbleMaybe = 97
    case wind = 98
    case shallowWaterWave = 99
    case waterSplashSpawner = 100
    case bubbleParticleSpawner = 101
    case piranhaPlantWakingBubble = 102
    case piranhaPlantBubble = 103
    case waveTrail = 104
    case strongWindParticle = 105
    case waterParticle = 106
    case plungeBubble = 107
    case breathParticleSpawner = 108
    case mistParticle = 109
    case mistParticleSpawner = 110
    case tweesterSandParticle = 111
    case blackSmokeMario = 112
    case flameMario = 113
    case blackSmokeBowser = 114
    case blackSmokeUpward = 115
    case whitePuffSmoke = 116
    case whitePuffSmoke2 = 117
    case whitePuffExplosion = 118
    case dustSmoke = 119
    case starKeyPuffSpawner = 120
    case staticFlame = 121
    case flamethrowerFlame = 122
    case flameBouncing = 123
    case flameBowser = 124
    case flameLargeBurningOut = 125
    case blueFlamesGroup = 126
    case flameFloatingLanding = 127
    case blueBowserFlame = 128
    case volcanoFlames = 129
    case koopaShellFlame = 130
    case flameMovingForwardGrowing = 131
    case betaMovingFlamesSpawn = 132
    case betaMovingFlames = 133
    case bowserFlameSpawn = 134
    case smallPiranhaFlame = 135
    case fireSpitter = 136
    case firePiranhaPlant = 137
    case flamethrower = 138
    case celebrationStarSparkle = 139
    case dirtParticleSpawner = 140
    case snowParticleSpawner = 141
    case animatedTexture = 142
    case sparkle = 143
    case sparkleSpawner = 144
    case ambientSounds = 145
    case coinSparkles = 146
    case goldenCoinSparkles = 147
    case purpleParticle = 148
    case wallTinyStarParticle = 149
    case poundTinyStarParticle = 150
    case vertStarParticleSpawner = 151
    case horStarParticleSpawner = 152
    case triangleParticle = 153
    case triangleParticleSpawner = 154
    case treeLeaf = 155
    case treeSnow = 156
    case treeParticleSpawner = 157
    case mistCircParticleSpawner = 158
    case sparkleParticleSpawner = 159
    case randomAnimatedTexture = 160
    case unusedSimpleAnimation = 161
    case unusedFakeStar = 162
    case cloudPart = 163
    case breakBoxTriangle = 164
    case cannonBaseUnused = 165
    case noOp = 166
    case cannonBarrelBubbles = 167
    case cloud = 168
    case celebrationStar = 169
    case warp = 170
    case dddWarp = 171
    case actSelectorStarType = 172
    case collectStar = 173
    case starSpawnCoordinates = 174
    case spawnedStar = 175
    case spawnedStarNoLevelExit = 176
    case ccmTouchedStarSpawn = 177
    case hiddenStar = 178
    case hiddenStarTrigger = 179
    case castleCannonGrate = 180
    case blueCoinSwitch = 181
    case hiddenBlueCoin = 182
    case hiddenRedCoinStar = 183
    case redCoinStarMarker = 184
    case redCoin = 185
    case starDoor = 186
    case capSwitch = 187
    case capSwitchBase = 188
    case towerDoor = 189
    case openableGrill = 190
    case openableCageDoor = 191
    case door = 192
    case hiddenObject = 193
    case recoveryHeart = 194
    case coin = 195
    case movingCoin = 196
    case waterLevelDiamond = 197
    case changingWaterLevel = 198
    case waterPillar = 199
    case floorSwitch = 200
    case animatedFloorSwitch = 201
    case hiddenOneUp = 202
    case breakableBox = 203
    case exclamationBox = 204
    case orangeNumber = 205
    case soundSpawner = 206
    case rockSolid = 207
    case environmentGate = 208
    case clockArm = 209
    case castleFloorTrap = 210
    case castleFlag = 211
    case booCage = 212
    case booKey = 213
    case booInCastle = 214
    case merryGoRound = 215
    case musicTouch = 216
    case textSurface = 217
    case grandStar = 218
    case betaBowserAnchor = 219
    case bomp = 220
    case thwomp = 221
    case boulder = 222
    case horizontalGrindel = 223
    case unusedParticleSpawn = 224
    case snowmanCheckpoint = 225
    case bowserBodyAnchor = 226
    case bowserTailAnchor = 227
    case betaChest = 228
    case betaTrampoline = 229
    case betaHoldable = 230
    case seaweed = 231
    case shipPart3 = 232
    case fallingPillar = 233
    case coffin = 234
    case blueFish = 235
    case clamShell = 236
    case bobombAnchorMario = 237
    case bub = 238
    case butterfly = 239
    case tiltingPyramid = 240
    case bookend = 241
    case bookSwitch = 242
    case fish = 243
    case cannonBarrel = 244
    case cannon = 245
    case merryGoRoundBooManager = 246
    case bubba = 247
    case bowlingBall = 248
    case dddPole = 249
    case donutPlatform = 250
    case courtyardBooTriplet = 251
    case fallingBowserPlatform = 252
    case giantPole = 253
    case endCutsceneActor = 254
    case unmigrated = 255
    case snowmanHead = 256
    case madPiano = 257
    case actSelector = 258
    case sushiShark = 259
    case ukiki = 260
    case ukikiCage = 261
    case mips = 262
    case toadMessage = 263
    case menuButton = 264
    case squarishPathMoving = 265
    case pushableMetalBox = 266
    case tiltingBowserLavaPlatform = 267
    case lllBowserPuzzle = 268
}

struct SM64BehaviorDispatchEvent: Equatable, Sendable {
    let objectID: SM64ObjectID
    let behaviorIdentity: UInt64
    let route: SM64BehaviorDispatchRoute
}

struct SM64BehaviorDispatchTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let events: [SM64BehaviorDispatchEvent]
    let ukikiEffects: [SM64UkikiObjectEffect]
    let ukikiCageEffects: [SM64UkikiCageObjectEffect]
    let mipsEffects: [SM64MipsObjectEffect]
    let toadMessageEffects: [SM64ToadMessageObjectEffect]
    let menuButtonEffects: [SM64MenuButtonObjectEffect]
    let menuButtonManagerEffects: [SM64MenuButtonManagerObjectEffect]
    let squarishPathMovingEffects: [SM64SquarishPathMovingObjectEffectRecord]
    let pushableMetalBoxEffects: [SM64PushableMetalBoxObjectEffectRecord]
    let tiltingBowserLavaPlatformEffects: [SM64TiltingBowserLavaPlatformObjectEffectRecord]
    let lllBowserPuzzleEffects: [SM64LllBowserPuzzleObjectEffectRecord]
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
    let bompEffects: [SM64BompObjectEffectRecord]
    let thwompEffects: [SM64ThwompObjectEffectRecord]
    let boulderEffects: [SM64BoulderObjectEffectRecord]
    let boulderGeneratorEffects: [SM64BoulderGeneratorEffectRecord]
    let horizontalGrindelEffects: [SM64HorizontalGrindelObjectEffectRecord]
    let unusedParticleSpawnEffects: [SM64UnusedParticleSpawnEffectRecord]
    let snowmanCheckpointEffects: [SM64SnowmanCheckpointObjectEffectRecord]
    let bowserBodyAnchorEffects: [SM64BowserBodyAnchorObjectEffectRecord]
    let bowserTailAnchorEffects: [SM64BowserTailAnchorObjectEffectRecord]
    let snowmanHeadEffects: [SM64SnowmanHeadObjectEffectRecord]
    let betaChestEffects: [SM64BetaChestObjectEffectRecord]
    let betaTrampolineEffects: [SM64BetaTrampolineObjectEffectRecord]
    let betaHoldableEffects: [SM64BetaHoldableObjectEffectRecord]
    let seaweedEffects: [SM64SeaweedObjectEffectRecord]
    let shipPart3Effects: [SM64ShipPart3ObjectEffectRecord]
    let sunkenShipPartEffects: [SM64SunkenShipPartObjectEffectRecord]
    let jrbSlidingBoxEffects: [SM64JrbSlidingBoxObjectEffectRecord]
    let fallingPillarEffects: [SM64FallingPillarObjectEffectRecord]
    let coffinEffects: [SM64CoffinObjectEffectRecord]
    let blueFishEffects: [SM64BlueFishObjectEffectRecord]
    let tankFishGroupEffects: [SM64TankFishGroupObjectEffectRecord]
    let clamShellEffects: [SM64ClamShellObjectEffectRecord]
    let bobombAnchorMarioEffects: [SM64BobombAnchorMarioObjectEffectRecord]
    let bubEffects: [SM64BubObjectEffectRecord]
    let bubbaEffects: [SM64BubbaObjectEffectRecord]
    let bowlingBallEffects: [SM64BowlingBallObjectEffectRecord]
    let dddPoleEffects: [SM64DDDPoleObjectEffectRecord]
    let donutPlatformEffects: [SM64DonutPlatformObjectEffectRecord]
    let courtyardBooTripletEffects: [SM64CourtyardBooTripletObjectEffectRecord]
    let fallingBowserPlatformEffects: [SM64FallingBowserPlatformObjectEffectRecord]
    let giantPoleEffects: [SM64GiantPoleObjectEffectRecord]
    let koopaFlagEffects: [SM64KoopaFlagObjectEffectRecord]
    let koopaRaceEndpointEffects: [SM64KoopaRaceEndpointObjectEffectRecord]
    let wfBreakableWallEffects: [SM64WfBreakableWallObjectEffectRecord]
    let unusedPoundablePlatformEffects: [SM64UnusedPoundablePlatformObjectEffectRecord]
    let yellowBackgroundMenuEffects: [SM64YellowBackgroundMenuObjectEffectRecord]
    let snowMoundSlidingEffects: [SM64SlidingSnowMoundObjectEffectRecord]
    let snowMoundSpawnerEffects: [SM64SnowMoundSpawnerObjectEffectRecord]
    let rrCruiserWingEffects: [SM64RrCruiserWingObjectEffectRecord]
    let spindriftEffects: [SM64SpindriftObjectEffectRecord]
    let spindelEffects: [SM64SpindelObjectEffectRecord]
    let rrRotatingBridgePlatformEffects: [SM64RrRotatingBridgePlatformObjectEffectRecord]
    let snowmanWindEffects: [SM64SnowmanWindObjectEffectRecord]
    let mrBlizzardSnowballEffects: [SM64MrBlizzardSnowballObjectEffectRecord]
    let endCutsceneActorEffects: [SM64EndCutsceneActorObjectEffectRecord]
    let endBirdsEffects: [SM64EndBirdsObjectEffectRecord]
    let beginningPeachEffects: [SM64BeginningPeachObjectEffectRecord]
    let butterflyEffects: [SM64ButterflyObjectEffectRecord]
    let tiltingPyramidEffects: [SM64TiltingPyramidObjectEffectRecord]
    let bookendEffects: [SM64BookendObjectEffectRecord]
    let bookSwitchEffects: [SM64BookSwitchObjectEffectRecord]
    let hauntedBookshelfEffects: [SM64HauntedBookshelfObjectEffectRecord]
    let hauntedBookshelfManagerEffects: [SM64HauntedBookshelfManagerObjectEffectRecord]
    let hauntedChairEffects: [SM64HauntedChairObjectEffectRecord]
    let fishEffects: [SM64FishObjectEffectRecord]
    let cannonBarrelEffects: [SM64CannonBarrelObjectEffectRecord]
    let cannonEffects: [SM64CannonObjectEffectRecord]
    let merryGoRoundBooManagerEffects: [SM64MerryGoRoundBooManagerObjectEffectRecord]
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
    let arrowLiftEffects: [SM64ArrowLiftObjectEffectRecord]
    let elevatorEffects: [SM64ElevatorObjectEffectRecord]
    let seesawPlatformEffects: [SM64SeesawPlatformObjectEffectRecord]
    let swingPlatformEffects: [SM64SwingPlatformObjectEffectRecord]
    let rotatingPlatformEffects: [SM64RotatingPlatformObjectEffectRecord]
    let ttcMovingBarEffects: [SM64TTCMovingBarObjectEffectRecord]
    let ttcSpinnerEffects: [SM64TTCSpinnerObjectEffectRecord]
    let ttcTreadmillEffects: [SM64TTCTreadmillObjectEffectRecord]
    let ttcPendulumEffects: [SM64TTCPendulumObjectEffectRecord]
    let ttcElevatorEffects: [SM64TTCElevatorObjectEffectRecord]
    let ttcRotatingSolidEffects: [SM64TTCRotatingSolidObjectEffectRecord]
    let ttc2DRotatorEffects: [SM64TTC2DRotatorObjectEffectRecord]
    let ttcCogEffects: [SM64TTCCogObjectEffectRecord]
    let pyramidElevatorEffects: [SM64PyramidElevatorObjectEffectRecord]
    let pyramidMarkerEffects: [SM64PyramidMarkerObjectEffectRecord]
    let pyramidTopFragmentEffects: [SM64PyramidTopFragmentObjectEffectRecord]
    let pyramidPillarTouchDetectorEffects: [SM64PyramidPillarTouchDetectorObjectEffectRecord]
    let pyramidTopEffects: [SM64PyramidTopObjectEffectRecord]
    let ttcPitBlockEffects: [SM64TTCPitBlockObjectEffectRecord]
    let staticCheckeredPlatformEffects: [SM64StaticCheckeredPlatformObjectEffectRecord]
    let bbhTiltingTrapPlatformEffects: [SM64BBHTiltingTrapPlatformObjectEffectRecord]
    let lllSinkingPlatformEffects: [SM64LLLSinkingPlatformObjectEffectRecord]
    let wfRotatingWoodenPlatformEffects: [SM64WfRotatingWoodenPlatformObjectEffectRecord]
    let rotatingOctagonalPlatformEffects: [SM64RotatingOctagonalPlatformObjectEffectRecord]
    let wfSolidTowerPlatformEffects: [SM64WfSolidTowerPlatformObjectEffectRecord]
    let wfTowerPlatformEffects: [SM64WfTowerPlatformObjectEffectRecord]
    let trackBallEffects: [SM64TrackBallObjectEffectRecord]
    let wfSlidingPlatformEffects: [SM64WfSlidingPlatformObjectEffectRecord]
    let wdwExpressElevatorEffects: [SM64WdwExpressElevatorObjectEffectRecord]
    let lllSinkingRockBlockEffects: [SM64LllSinkingRockBlockObjectEffectRecord]
    let volcanoFallingTrapEffects: [SM64VolcanoFallingTrapObjectEffectRecord]
    let rollingLogEffects: [SM64RollingLogObjectEffectRecord]
    let lllMovingOctagonalMeshEffects: [SM64LllMovingOctagonalMeshObjectEffectRecord]
    let ferrisWheelEffects: [SM64FerrisWheelPlatformObjectEffectRecord]
    let checkerboardPlatformEffects: [SM64CheckerboardPlatformObjectEffectRecord]
    let wfTowerPlatformGroupEffects: [SM64WfTowerPlatformGroupObjectEffectRecord]
    let lllRotatingHexagonalPlatformEffects: [SM64LllRotatingHexagonalPlatformObjectEffectRecord]
    let lllRotatingHexFlameEffects: [SM64LllRotatingHexFlameObjectEffectRecord]
    let lllRotatingFireBarEffects: [SM64LllRotatingFireBarObjectEffectRecord]
    let activatedBackAndForthPlatformEffects: [SM64ActivatedBackAndForthPlatformObjectEffectRecord]
    let bitfsSinkingPlatformEffects: [SM64BitfsSinkingPlatformObjectEffectRecord]
    let dddMovingPoleEffects: [SM64DddMovingPoleObjectEffectRecord]
    let lllRotatingHexagonalRingEffects: [SM64LllRotatingHexagonalRingObjectEffectRecord]
    let lllWoodPieceEffects: [SM64LllWoodPieceObjectEffectRecord]
    let lllFloatingWoodBridgeEffects: [SM64LllFloatingWoodBridgeObjectEffectRecord]
    let squishablePlatformEffects: [SM64SquishablePlatformObjectEffectRecord]
    let lllDrawbridgeSpawnerEffects: [SM64LllDrawbridgeSpawnerObjectEffectRecord]
    let lllDrawbridgeEffects: [SM64LllDrawbridgeObjectEffectRecord]
    let idleWaterWaveEffects: [SM64IdleWaterWaveObjectEffectRecord]
    let waterfallSoundLoopEffects: [SM64WaterfallSoundLoopObjectEffectRecord]
    let volcanoSoundLoopEffects: [SM64VolcanoSoundLoopObjectEffectRecord]
    let tumblingBridgeParentEffects: [SM64TumblingBridgeParentEffectRecord]
    let tumblingBridgePlatformEffects: [SM64TumblingBridgePlatformEffectRecord]
    let floatingPlatformEffects: [SM64FloatingPlatformObjectEffectRecord]
    let jrbFloatingBoxEffects: [SM64JrbFloatingBoxObjectEffectRecord]
    let slidingPlatform2Effects: [SM64SlidingPlatform2ObjectEffectRecord]
    let smallWaterWaveEffects: [SM64SmallWaterWaveObjectEffectRecord]
    let ambientSoundLoopEffects: [SM64AmbientSoundLoopObjectEffectRecord]
    let rotatingExclamationMarkEffects: [SM64RotatingExclamationMarkObjectEffectRecord]
    let waterAirBubbleEffects: [SM64WaterAirBubbleObjectEffectRecord]
    let objectBubbleEffects: [SM64ObjectBubbleObjectEffectRecord]
    let waterDropletEffects: [SM64WaterDropletObjectEffectRecord]
    let waterMistEffects: [SM64WaterMistObjectEffectRecord]
    let waterMist2Effects: [SM64WaterMist2ObjectEffectRecord]
    let waterSplashEffects: [SM64WaterSplashObjectEffectRecord]
    let bubbleMaybeEffects: [SM64BubbleMaybeObjectEffectRecord]
    let windEffects: [SM64WindObjectEffectRecord]
    let jetStreamEffects: [SM64JetStreamObjectEffectRecord]
    let jetStreamWaterRingEffects: [SM64JetStreamWaterRingObjectEffectRecord]
    let jetStreamRingSpawnerEffects: [SM64JetStreamRingSpawnerObjectEffectRecord]
    let mantaRayWaterRingEffects: [SM64MantaRayWaterRingObjectEffectRecord]
    let whirlpoolEffects: [SM64WhirlpoolObjectEffectRecord]
    let mantaRayEffects: [SM64MantaRayObjectEffectRecord]
    let shallowWaterWaveEffects: [SM64ShallowWaterWaveObjectEffectRecord]
    let waterSplashSpawnerEffects: [SM64WaterSplashSpawnerObjectEffectRecord]
    let bubbleParticleSpawnerEffects: [SM64BubbleParticleSpawnerObjectEffectRecord]
    let piranhaPlantWakingBubbleEffects: [SM64PiranhaPlantWakingBubbleObjectEffectRecord]
    let piranhaPlantBubbleEffects: [SM64PiranhaPlantBubbleObjectEffectRecord]
    let waveTrailEffects: [SM64WaveTrailObjectEffectRecord]
    let sushiSharkEffects: [SM64SushiSharkObjectEffectRecord]
    let strongWindParticleEffects: [SM64StrongWindParticleObjectEffectRecord]
    let waterParticleEffects: [SM64WaterParticleObjectEffectRecord]
    let plungeBubbleEffects: [SM64PlungeBubbleObjectEffectRecord]
    let breathParticleSpawnerEffects: [SM64BreathParticleSpawnerObjectEffectRecord]
    let mistParticleEffects: [SM64MistParticleObjectEffectRecord]
    let mistParticleSpawnerEffects: [SM64MistParticleSpawnerObjectEffectRecord]
    let tweesterSandParticleEffects: [SM64TweesterSandParticleObjectEffectRecord]
    let blackSmokeMarioEffects: [SM64BlackSmokeMarioObjectEffectRecord]
    let flameMarioEffects: [SM64FlameMarioObjectEffectRecord]
    let blackSmokeBowserEffects: [SM64BlackSmokeBowserObjectEffectRecord]
    let blackSmokeUpwardEffects: [SM64BlackSmokeUpwardObjectEffectRecord]
    let whitePuffSmokeEffects: [SM64WhitePuffSmokeObjectEffectRecord]
    let whitePuffSmoke2Effects: [SM64WhitePuffSmoke2ObjectEffectRecord]
    let whitePuffExplosionEffects: [SM64WhitePuffExplosionObjectEffectRecord]
    let dustSmokeEffects: [SM64DustSmokeObjectEffectRecord]
    let starKeyPuffSpawnerEffects: [SM64StarKeyCollectionPuffSpawnerObjectEffectRecord]
    let staticFlameEffects: [SM64FlameObjectEffectRecord]
    let flamethrowerFlameEffects: [SM64FlamethrowerFlameObjectEffectRecord]
    let flameBouncingEffects: [SM64FlameBouncingObjectEffectRecord]
    let flameBowserEffects: [SM64BowserFlameObjectEffectRecord]
    let blueFlamesGroupEffects: [SM64BlueFlamesGroupObjectEffectRecord]
    let flameFloatingLandingEffects: [SM64FlameFloatingLandingObjectEffectRecord]
    let blueBowserFlameEffects: [SM64BlueBowserFlameObjectEffectRecord]
    let volcanoFlamesEffects: [SM64VolcanoFlamesObjectEffectRecord]
    let koopaShellFlameEffects: [SM64KoopaShellFlameObjectEffectRecord]
    let flameMovingForwardGrowingEffects: [SM64FlameMovingForwardGrowingObjectEffectRecord]
    let betaMovingFlamesEffects: [SM64BetaMovingFlamesObjectEffectRecord]
    let betaMovingFlamesSpawnEffects: [SM64BetaMovingFlamesSpawnObjectEffectRecord]
    let bowserFlameSpawnEffects: [SM64BowserFlameSpawnObjectEffectRecord]
    let smallPiranhaFlameEffects: [SM64SmallPiranhaFlameObjectEffectRecord]
    let fireSpitterEffects: [SM64FireSpitterObjectEffectRecord]
    let firePiranhaPlantEffects: [SM64FirePiranhaPlantObjectEffectRecord]
    let flamethrowerEffects: [SM64FlamethrowerObjectEffectRecord]
    let celebrationStarSparkleEffects: [SM64CelebrationStarSparkleObjectEffectRecord]
    let groundParticleSpawnerEffects: [SM64GroundParticleSpawnerObjectEffectRecord]
    let animatedTextureEffects: [SM64AnimatedTextureObjectEffectRecord]
    let sparkleEffects: [SM64SparkleObjectEffectRecord]
    let sparkleSpawnerEffects: [SM64SparkleSpawnerObjectEffectRecord]
    let ambientSoundsEffects: [SM64AmbientSoundsObjectEffectRecord]
    let coinSparklesEffects: [SM64CoinSparklesObjectEffectRecord]
    let goldenCoinSparklesEffects: [SM64GoldenCoinSparklesObjectEffectRecord]
    let purpleParticleEffects: [SM64PurpleParticleObjectEffectRecord]
    let tinyStarParticleEffects: [SM64TinyStarParticleObjectEffectRecord]
    let tinyStarParticleSpawnerEffects: [SM64TinyStarParticleSpawnerObjectEffectRecord]
    let triangleParticleEffects: [SM64TriangleParticleObjectEffectRecord]
    let triangleParticleSpawnerEffects: [SM64TriangleParticleSpawnerObjectEffectRecord]
    let treeLeafEffects: [SM64TreeLeafObjectEffectRecord]
    let treeParticleSpawnerEffects: [SM64TreeParticleSpawnerObjectEffectRecord]
    let mistCircParticleSpawnerEffects: [SM64MistCircParticleSpawnerObjectEffectRecord]
    let sparkleParticleSpawnerEffects: [SM64SparkleParticleSpawnerObjectEffectRecord]
    let simpleAnimationEffects: [SM64SimpleAnimationObjectEffectRecord]
    let unusedFakeStarEffects: [SM64UnusedFakeStarObjectEffectRecord]
    let cloudPartEffects: [SM64CloudPartObjectEffectRecord]
    let breakBoxTriangleEffects: [SM64BreakBoxTriangleObjectEffectRecord]
    let cannonBaseUnusedEffects: [SM64CannonBaseUnusedObjectEffectRecord]
    let noOpEffects: [SM64NoOpObjectEffectRecord]
    let cannonBarrelBubblesEffects: [SM64CannonBarrelBubblesObjectEffectRecord]
    let cloudEffects: [SM64CloudObjectEffectRecord]
    let celebrationStarEffects: [SM64CelebrationStarObjectEffectRecord]
    let warpEffects: [SM64WarpObjectEffectRecord]
    let dddWarpEffects: [SM64DddWarpObjectEffectRecord]
    let actSelectorEffects: [SM64ActSelectorObjectEffectRecord]
    let actSelectorStarTypeEffects: [SM64ActSelectorStarTypeObjectEffectRecord]
    let collectStarEffects: [SM64CollectStarObjectEffectRecord]
    let starSpawnCoordinatesEffects: [SM64StarSpawnCoordinatesObjectEffectRecord]
    let spawnedStarEffects: [SM64SpawnedStarObjectEffectRecord]
    let unlockDoorStarEffects: [SM64UnlockDoorStarObjectEffectRecord]
    let ccmTouchedStarSpawnEffects: [SM64CcmTouchedStarSpawnObjectEffectRecord]
    let hiddenStarEffects: [SM64HiddenStarObjectEffectRecord]
    let hiddenStarTriggerEffects: [SM64HiddenStarTriggerObjectEffectRecord]
    let castleCannonGrateEffects: [SM64CastleCannonGrateObjectEffectRecord]
    let blueCoinSwitchEffects: [SM64BlueCoinSwitchObjectEffectRecord]
    let hiddenBlueCoinEffects: [SM64HiddenBlueCoinObjectEffectRecord]
    let hiddenRedCoinStarEffects: [SM64HiddenRedCoinStarObjectEffectRecord]
    let redCoinStarMarkerEffects: [SM64RedCoinStarMarkerObjectEffectRecord]
    let redCoinEffects: [SM64RedCoinObjectEffectRecord]
    let starDoorEffects: [SM64StarDoorObjectEffectRecord]
    let capSwitchEffects: [SM64CapSwitchObjectEffectRecord]
    let metalCapEffects: [SM64MetalCapObjectEffectRecord]
    let vanishCapEffects: [SM64VanishCapObjectEffectRecord]
    let wingCapEffects: [SM64WingCapObjectEffectRecord]
    let normalCapEffects: [SM64NormalCapObjectEffectRecord]
    let capSwitchBaseEffects: [SM64CapSwitchBaseObjectEffectRecord]
    let towerDoorEffects: [SM64TowerDoorObjectEffectRecord]
    let openableGrillEffects: [SM64OpenableGrillObjectEffectRecord]
    let openableCageDoorEffects: [SM64OpenableCageDoorObjectEffectRecord]
    let doorEffects: [SM64DoorObjectEffectRecord]
    let hiddenObjectEffects: [SM64HiddenObjectEffectRecord]
    let recoveryHeartEffects: [SM64RecoveryHeartObjectEffectRecord]
    let coinEffects: [SM64CoinObjectEffectRecord]
    let coinSpawnerEffects: [SM64CoinSpawnerEffectRecord]
    let movingCoinEffects: [SM64MovingCoinObjectEffectRecord]
    let waterLevelDiamondEffects: [SM64WaterLevelDiamondObjectEffectRecord]
    let changingWaterLevelEffects: [SM64ChangingWaterLevelObjectEffectRecord]
    let waterPillarEffects: [SM64WaterPillarObjectEffectRecord]
    let floorSwitchEffects: [SM64FloorSwitchObjectEffectRecord]
    let animatedFloorSwitchEffects: [SM64AnimatedFloorSwitchObjectEffectRecord]
    let hiddenOneUpEffects: [SM64HiddenOneUpObjectEffectRecord]
    let breakableBoxEffects: [SM64BreakableBoxObjectEffectRecord]
    let jumpingBoxEffects: [SM64JumpingBoxObjectEffectRecord]
    let kickableBoardEffects: [SM64KickableBoardObjectEffectRecord]
    let exclamationBoxEffects: [SM64ExclamationBoxObjectEffectRecord]
    let orangeNumberEffects: [SM64OrangeNumberObjectEffectRecord]
    let soundSpawnerEffects: [SM64SoundSpawnerObjectEffectRecord]
    let rockSolidEffects: [SM64RockSolidObjectEffectRecord]
    let toxBoxEffects: [SM64ToxBoxObjectEffectRecord]
    let sslMovingPyramidWallEffects: [SM64SslMovingPyramidWallObjectEffectRecord]
    let thiIslandTopEffects: [SM64ThiIslandTopObjectEffectRecord]
    let environmentGateEffects: [SM64EnvironmentGateObjectEffectRecord]
    let clockArmEffects: [SM64ClockArmObjectEffectRecord]
    let castleFloorTrapEffects: [SM64CastleFloorTrapObjectEffectRecord]
    let castleFlagEffects: [SM64CastleFlagObjectEffectRecord]
    let booCageEffects: [SM64BooCageObjectEffectRecord]
    let booKeyEffects: [SM64BooKeyObjectEffectRecord]
    let booInCastleEffects: [SM64BooInCastleObjectEffectRecord]
    let merryGoRoundEffects: [SM64MerryGoRoundObjectEffectRecord]
    let musicTouchEffects: [SM64MusicTouchObjectEffectRecord]
    let textSurfaceEffects: [SM64TextSurfaceObjectEffectRecord]
    let grandStarEffects: [SM64GrandStarObjectEffectRecord]
    let betaBowserAnchorEffects: [SM64BetaBowserAnchorObjectEffectRecord]
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
    let bomp: SM64BompObjectBridge
    let thwomp: SM64ThwompObjectBridge
    let boulder: SM64BoulderObjectBridge
    let horizontalGrindel: SM64HorizontalGrindelObjectBridge
    let unusedParticleSpawn: SM64UnusedParticleSpawnObjectBridge
    let snowmanCheckpoint: SM64SnowmanCheckpointObjectBridge
    let bowserBodyAnchor: SM64BowserBodyAnchorObjectBridge
    let bowserTailAnchor: SM64BowserTailAnchorObjectBridge
    let snowmanHead: SM64SnowmanHeadObjectBridge
    let madPiano: SM64MadPianoObjectBridge
    let betaChest: SM64BetaChestObjectBridge
    let betaTrampoline: SM64BetaTrampolineObjectBridge
    let betaHoldable: SM64BetaHoldableObjectBridge
    let seaweed: SM64SeaweedObjectBridge
    let shipPart3: SM64ShipPart3ObjectBridge
    let sunkenShipPart: SM64SunkenShipPartObjectBridge
    let jrbSlidingBox: SM64JrbSlidingBoxObjectBridge
    let fallingPillar: SM64FallingPillarObjectBridge
    let coffin: SM64CoffinObjectBridge
    let blueFish: SM64BlueFishObjectBridge
    let clamShell: SM64ClamShellObjectBridge
    let bobombAnchorMario: SM64BobombAnchorMarioObjectBridge
    let bub: SM64BubObjectBridge
    let bubba: SM64BubbaObjectBridge
    let bowlingBall: SM64BowlingBallObjectBridge
    let dddPole: SM64DDDPoleObjectBridge
    let donutPlatform: SM64DonutPlatformObjectBridge
    let courtyardBooTriplet: SM64CourtyardBooTripletObjectBridge
    let fallingBowserPlatform: SM64FallingBowserPlatformObjectBridge
    let giantPole: SM64GiantPoleObjectBridge
    let koopaFlag: SM64KoopaFlagObjectBridge
    let koopaRaceEndpoint: SM64KoopaRaceEndpointObjectBridge
    let wfBreakableWall: SM64WfBreakableWallObjectBridge
    let unusedPoundablePlatform: SM64UnusedPoundablePlatformObjectBridge
    let yellowBackgroundMenu: SM64YellowBackgroundMenuObjectBridge
    let snowMound: SM64SnowMoundObjectBridge
    let rrCruiserWing: SM64RrCruiserWingObjectBridge
    let spindrift: SM64SpindriftObjectBridge
    let spindel: SM64SpindelObjectBridge
    let rrRotatingBridgePlatform: SM64RrRotatingBridgePlatformObjectBridge
    let snowmanWind: SM64SnowmanWindObjectBridge
    let mrBlizzardSnowball: SM64MrBlizzardSnowballObjectBridge
    let endCutsceneActor: SM64EndCutsceneActorObjectBridge
    let endBirds: SM64EndBirdsObjectBridge
    let beginningPeach: SM64BeginningPeachObjectBridge
    let butterfly: SM64ButterflyObjectBridge
    let tiltingPyramid: SM64TiltingPyramidObjectBridge
    let bookend: SM64BookendObjectBridge
    let bookSwitch: SM64BookSwitchObjectBridge
    let hauntedBookshelf: SM64HauntedBookshelfObjectBridge
    let hauntedBookshelfManager: SM64HauntedBookshelfManagerObjectBridge
    let hauntedChair: SM64HauntedChairObjectBridge
    let fish: SM64FishObjectBridge
    let cannonBarrel: SM64CannonBarrelObjectBridge
    let cannon: SM64CannonObjectBridge
    let merryGoRoundBooManager: SM64MerryGoRoundBooManagerObjectBridge
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
    let arrowLift: SM64ArrowLiftObjectBridge
    let elevator: SM64ElevatorObjectBridge
    let seesawPlatform: SM64SeesawPlatformObjectBridge
    let swingPlatform: SM64SwingPlatformObjectBridge
    let rotatingPlatform: SM64RotatingPlatformObjectBridge
    let ttcMovingBar: SM64TTCMovingBarObjectBridge
    let ttcSpinner: SM64TTCSpinnerObjectBridge
    let ttcTreadmill: SM64TTCTreadmillObjectBridge
    let ttcPendulum: SM64TTCPendulumObjectBridge
    let ttcElevator: SM64TTCElevatorObjectBridge
    let ttcRotatingSolid: SM64TTCRotatingSolidObjectBridge
    let ttc2DRotator: SM64TTC2DRotatorObjectBridge
    let ttcCog: SM64TTCCogObjectBridge
    let pyramidElevator: SM64PyramidElevatorObjectBridge
    let ttcPitBlock: SM64TTCPitBlockObjectBridge
    let staticCheckeredPlatform: SM64StaticCheckeredPlatformObjectBridge
    let bbhTiltingTrapPlatform: SM64BBHTiltingTrapPlatformObjectBridge
    let lllSinkingPlatform: SM64LLLSinkingPlatformObjectBridge
    let wfRotatingWoodenPlatform: SM64WfRotatingWoodenPlatformObjectBridge
    let rotatingOctagonalPlatform: SM64RotatingOctagonalPlatformObjectBridge
    let wfSolidTowerPlatform: SM64WfSolidTowerPlatformObjectBridge
    let wfTowerPlatform: SM64WfTowerPlatformObjectBridge
    let trackBall: SM64TrackBallObjectBridge
    let wfSlidingPlatform: SM64WfSlidingPlatformObjectBridge
    let wdwExpressElevator: SM64WdwExpressElevatorObjectBridge
    let lllSinkingRockBlock: SM64LllSinkingRockBlockObjectBridge
    let volcanoFallingTrap: SM64VolcanoFallingTrapObjectBridge
    let rollingLog: SM64RollingLogObjectBridge
    let lllMovingOctagonalMesh: SM64LllMovingOctagonalMeshObjectBridge
    let ferrisWheel: SM64FerrisWheelPlatformObjectBridge
    let checkerboardPlatform: SM64CheckerboardPlatformObjectBridge
    let wfTowerPlatformGroup: SM64WfTowerPlatformGroupObjectBridge
    let lllRotatingHexagonalPlatform: SM64LllRotatingHexagonalPlatformObjectBridge
    let lllRotatingHexFlame: SM64LllRotatingHexFlameObjectBridge
    let lllRotatingFireBar: SM64LllRotatingFireBarObjectBridge
    let activatedBackAndForthPlatform: SM64ActivatedBackAndForthPlatformObjectBridge
    let bitfsSinkingPlatform: SM64BitfsSinkingPlatformObjectBridge
    let dddMovingPole: SM64DddMovingPoleObjectBridge
    let lllRotatingHexagonalRing: SM64LllRotatingHexagonalRingObjectBridge
    let lllWoodPiece: SM64LllWoodPieceObjectBridge
    let lllFloatingWoodBridge: SM64LllFloatingWoodBridgeObjectBridge
    let squishablePlatform: SM64SquishablePlatformObjectBridge
    let lllDrawbridge: SM64LllDrawbridgeObjectBridge
    let idleWaterWave: SM64IdleWaterWaveObjectBridge
    let waterfallSoundLoop: SM64WaterfallSoundLoopObjectBridge
    let volcanoSoundLoop: SM64VolcanoSoundLoopObjectBridge
    let tumblingBridge: SM64TumblingBridgeObjectBridge
    let floatingPlatform: SM64FloatingPlatformObjectBridge
    let jrbFloatingBox: SM64JrbFloatingBoxObjectBridge
    let slidingPlatform2: SM64SlidingPlatform2ObjectBridge
    let smallWaterWave: SM64SmallWaterWaveObjectBridge
    let ambientSoundLoop: SM64AmbientSoundLoopObjectBridge
    let rotatingExclamationMark: SM64RotatingExclamationMarkObjectBridge
    let waterAirBubble: SM64WaterAirBubbleObjectBridge
    let objectBubble: SM64ObjectBubbleObjectBridge
    let waterDroplet: SM64WaterDropletObjectBridge
    let waterMist: SM64WaterMistObjectBridge
    let waterMist2: SM64WaterMist2ObjectBridge
    let waterSplash: SM64WaterSplashObjectBridge
    let bubbleMaybe: SM64BubbleMaybeObjectBridge
    let wind: SM64WindObjectBridge
    let jetStream: SM64JetStreamObjectBridge
    let jetStreamWaterRing: SM64JetStreamWaterRingObjectBridge
    let jetStreamRingSpawner: SM64JetStreamRingSpawnerObjectBridge
    let mantaRayWaterRing: SM64MantaRayWaterRingObjectBridge
    let whirlpool: SM64WhirlpoolObjectBridge
    let mantaRay: SM64MantaRayObjectBridge
    let shallowWaterWave: SM64ShallowWaterWaveObjectBridge
    let waterSplashSpawner: SM64WaterSplashSpawnerObjectBridge
    let bubbleParticleSpawner: SM64BubbleParticleSpawnerObjectBridge
    let piranhaPlantWakingBubble: SM64PiranhaPlantWakingBubbleObjectBridge
    let piranhaPlantBubble: SM64PiranhaPlantBubbleObjectBridge
    let waveTrail: SM64WaveTrailObjectBridge
    let sushiShark: SM64SushiSharkObjectBridge
    let ukiki: SM64UkikiObjectBridge
    let ukikiCage: SM64UkikiCageObjectBridge
    let mips: SM64MipsObjectBridge
    let toadMessage: SM64ToadMessageObjectBridge
    let menuButton: SM64MenuButtonObjectBridge
    let squarishPathMoving: SM64SquarishPathMovingObjectBridge
    let pushableMetalBox: SM64PushableMetalBoxObjectBridge
    let tiltingBowserLavaPlatform: SM64TiltingBowserLavaPlatformObjectBridge
    let lllBowserPuzzle: SM64LllBowserPuzzleObjectBridge
    let strongWindParticle: SM64StrongWindParticleObjectBridge
    let waterParticle: SM64WaterParticleObjectBridge
    let plungeBubble: SM64PlungeBubbleObjectBridge
    let breathParticleSpawner: SM64BreathParticleSpawnerObjectBridge
    let mistParticle: SM64MistParticleObjectBridge
    let mistParticleSpawner: SM64MistParticleSpawnerObjectBridge
    let tweesterSandParticle: SM64TweesterSandParticleObjectBridge
    let blackSmokeMario: SM64BlackSmokeMarioObjectBridge
    let flameMario: SM64FlameMarioObjectBridge
    let blackSmokeBowser: SM64BlackSmokeBowserObjectBridge
    let blackSmokeUpward: SM64BlackSmokeUpwardObjectBridge
    let whitePuffSmoke: SM64WhitePuffSmokeObjectBridge
    let whitePuffSmoke2: SM64WhitePuffSmoke2ObjectBridge
    let whitePuffExplosion: SM64WhitePuffExplosionObjectBridge
    let dustSmoke: SM64DustSmokeObjectBridge
    let starKeyPuffSpawner: SM64StarKeyCollectionPuffSpawnerObjectBridge
    let staticFlame: SM64FlameObjectBridge
    let flamethrowerFlame: SM64FlamethrowerFlameObjectBridge
    let flameBouncing: SM64FlameBouncingObjectBridge
    let bowserFlame: SM64BowserFlameObjectBridge
    let blueFlamesGroup: SM64BlueFlamesGroupObjectBridge
    let flameFloatingLanding: SM64FlameFloatingLandingObjectBridge
    let blueBowserFlame: SM64BlueBowserFlameObjectBridge
    let volcanoFlames: SM64VolcanoFlamesObjectBridge
    let koopaShellFlame: SM64KoopaShellFlameObjectBridge
    let flameMovingForwardGrowing: SM64FlameMovingForwardGrowingObjectBridge
    let betaMovingFlames: SM64BetaMovingFlamesObjectBridge
    let bowserFlameSpawn: SM64BowserFlameSpawnObjectBridge
    let smallPiranhaFlame: SM64SmallPiranhaFlameObjectBridge
    let fireSpitter: SM64FireSpitterObjectBridge
    let firePiranhaPlant: SM64FirePiranhaPlantObjectBridge
    let flamethrower: SM64FlamethrowerObjectBridge
    let celebrationStarSparkle: SM64CelebrationStarSparkleObjectBridge
    let groundParticleSpawner: SM64GroundParticleSpawnerObjectBridge
    let animatedTexture: SM64AnimatedTextureObjectBridge
    let sparkle: SM64SparkleObjectBridge
    let sparkleSpawner: SM64SparkleSpawnerObjectBridge
    let ambientSounds: SM64AmbientSoundsObjectBridge
    let coinSparkles: SM64CoinSparklesObjectBridge
    let goldenCoinSparkles: SM64GoldenCoinSparklesObjectBridge
    let purpleParticle: SM64PurpleParticleObjectBridge
    let tinyStarParticle: SM64TinyStarParticleObjectBridge
    let tinyStarParticleSpawner: SM64TinyStarParticleSpawnerObjectBridge
    let triangleParticle: SM64TriangleParticleObjectBridge
    let triangleParticleSpawner: SM64TriangleParticleSpawnerObjectBridge
    let treeLeaf: SM64TreeLeafObjectBridge
    let treeParticleSpawner: SM64TreeParticleSpawnerObjectBridge
    let mistCircParticleSpawner: SM64MistCircParticleSpawnerObjectBridge
    let sparkleParticleSpawner: SM64SparkleParticleSpawnerObjectBridge
    let simpleAnimation: SM64SimpleAnimationObjectBridge
    let unusedFakeStar: SM64UnusedFakeStarObjectBridge
    let cloudPart: SM64CloudPartObjectBridge
    let breakBoxTriangle: SM64BreakBoxTriangleObjectBridge
    let cannonBaseUnused: SM64CannonBaseUnusedObjectBridge
    let noOp: SM64NoOpObjectBridge
    let cannonBarrelBubbles: SM64CannonBarrelBubblesObjectBridge
    let cloud: SM64CloudObjectBridge
    let celebrationStar: SM64CelebrationStarObjectBridge
    let warp: SM64WarpObjectBridge
    let dddWarp: SM64DddWarpObjectBridge
    let actSelector: SM64ActSelectorObjectBridge
    let actSelectorStarType: SM64ActSelectorStarTypeObjectBridge
    let collectStar: SM64CollectStarObjectBridge
    let starSpawnCoordinates: SM64StarSpawnCoordinatesObjectBridge
    let spawnedStar: SM64SpawnedStarObjectBridge
    let unlockDoorStar: SM64UnlockDoorStarObjectBridge
    let ccmTouchedStarSpawn: SM64CcmTouchedStarSpawnObjectBridge
    let hiddenStar: SM64HiddenStarObjectBridge
    let castleCannonGrate: SM64CastleCannonGrateObjectBridge
    let blueCoin: SM64BlueCoinObjectBridge
    let redCoin: SM64RedCoinObjectBridge
    let starDoor: SM64StarDoorObjectBridge
    let capSwitch: SM64CapSwitchObjectBridge
    let metalCap: SM64MetalCapObjectBridge
    let vanishCap: SM64VanishCapObjectBridge
    let wingCap: SM64WingCapObjectBridge
    let normalCap: SM64NormalCapObjectBridge
    let towerDoor: SM64TowerDoorObjectBridge
    let openableGrill: SM64OpenableGrillObjectBridge
    let door: SM64DoorObjectBridge
    let hiddenObject: SM64HiddenObjectObjectBridge
    let recoveryHeart: SM64RecoveryHeartObjectBridge
    let coin: SM64CoinObjectBridge
    let movingCoin: SM64MovingCoinObjectBridge
    let waterLevel: SM64WaterLevelObjectBridge
    let waterPillar: SM64WaterPillarObjectBridge
    let floorSwitch: SM64FloorSwitchObjectBridge
    let animatedFloorSwitch: SM64AnimatedFloorSwitchObjectBridge
    let hiddenOneUp: SM64HiddenOneUpObjectBridge
    let breakableBox: SM64BreakableBoxObjectBridge
    let jumpingBox: SM64JumpingBoxObjectBridge
    let kickableBoard: SM64KickableBoardObjectBridge
    let exclamationBox: SM64ExclamationBoxObjectBridge
    let orangeNumber: SM64OrangeNumberObjectBridge
    let soundSpawner: SM64SoundSpawnerObjectBridge
    let rockSolid: SM64RockSolidObjectBridge
    let toxBox: SM64ToxBoxObjectBridge
    let sslMovingPyramidWall: SM64SslMovingPyramidWallObjectBridge
    let thiIslandTop: SM64ThiIslandTopObjectBridge
    let pyramidTopFragment: SM64PyramidTopFragmentObjectBridge
    let pyramidPillarTouchDetector: SM64PyramidPillarTouchDetectorObjectBridge
    let pyramidTop: SM64PyramidTopObjectBridge
    let environmentGate: SM64EnvironmentGateObjectBridge
    let clockArm: SM64ClockArmObjectBridge
    let castleFloorTrap: SM64CastleFloorTrapObjectBridge
    let castleFlag: SM64CastleFlagObjectBridge
    let booCage: SM64BooCageObjectBridge
    let booKey: SM64BooKeyObjectBridge
    let booInCastle: SM64BooInCastleObjectBridge
    let merryGoRound: SM64MerryGoRoundObjectBridge
    let musicTouch: SM64MusicTouchObjectBridge
    let textSurface: SM64TextSurfaceObjectBridge
    let grandStar: SM64GrandStarObjectBridge
    let betaBowserAnchor: SM64BetaBowserAnchorObjectBridge
    private var sushiWaterLevels: [SM64ObjectID: Float] = [:]
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
        self.bomp = SM64BompObjectBridge()
        self.thwomp = SM64ThwompObjectBridge()
        self.boulder = SM64BoulderObjectBridge()
        self.horizontalGrindel = SM64HorizontalGrindelObjectBridge()
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
        self.arrowLift = SM64ArrowLiftObjectBridge()
        self.elevator = SM64ElevatorObjectBridge()
        self.seesawPlatform = SM64SeesawPlatformObjectBridge()
        self.swingPlatform = SM64SwingPlatformObjectBridge()
        self.rotatingPlatform = SM64RotatingPlatformObjectBridge()
        self.ttcMovingBar = SM64TTCMovingBarObjectBridge()
        self.ttcSpinner = SM64TTCSpinnerObjectBridge()
        self.ttcTreadmill = SM64TTCTreadmillObjectBridge()
        self.ttcPendulum = SM64TTCPendulumObjectBridge()
        self.ttcElevator = SM64TTCElevatorObjectBridge()
        self.ttcRotatingSolid = SM64TTCRotatingSolidObjectBridge()
        self.ttc2DRotator = SM64TTC2DRotatorObjectBridge()
        self.ttcCog = SM64TTCCogObjectBridge()
        self.pyramidElevator = SM64PyramidElevatorObjectBridge()
        self.ttcPitBlock = SM64TTCPitBlockObjectBridge()
        self.staticCheckeredPlatform = SM64StaticCheckeredPlatformObjectBridge()
        self.bbhTiltingTrapPlatform = SM64BBHTiltingTrapPlatformObjectBridge()
        self.lllSinkingPlatform = SM64LLLSinkingPlatformObjectBridge()
        self.wfRotatingWoodenPlatform = SM64WfRotatingWoodenPlatformObjectBridge()
        self.rotatingOctagonalPlatform = SM64RotatingOctagonalPlatformObjectBridge()
        self.wfSolidTowerPlatform = SM64WfSolidTowerPlatformObjectBridge()
        self.wfTowerPlatform = SM64WfTowerPlatformObjectBridge()
        self.trackBall = SM64TrackBallObjectBridge()
        self.wfSlidingPlatform = SM64WfSlidingPlatformObjectBridge()
        self.wdwExpressElevator = SM64WdwExpressElevatorObjectBridge()
        self.lllSinkingRockBlock = SM64LllSinkingRockBlockObjectBridge()
        self.volcanoFallingTrap = SM64VolcanoFallingTrapObjectBridge()
        self.rollingLog = SM64RollingLogObjectBridge()
        self.lllMovingOctagonalMesh = SM64LllMovingOctagonalMeshObjectBridge()
        self.ferrisWheel = SM64FerrisWheelPlatformObjectBridge()
        self.checkerboardPlatform = SM64CheckerboardPlatformObjectBridge()
        self.wfTowerPlatformGroup = SM64WfTowerPlatformGroupObjectBridge(
            solidBridge: self.wfSolidTowerPlatform,
            towerBridge: self.wfTowerPlatform
        )
        self.lllRotatingHexagonalPlatform = SM64LllRotatingHexagonalPlatformObjectBridge()
        self.lllRotatingHexFlame = SM64LllRotatingHexFlameObjectBridge()
        self.lllRotatingFireBar = SM64LllRotatingFireBarObjectBridge(flameBridge: self.lllRotatingHexFlame)
        self.activatedBackAndForthPlatform = SM64ActivatedBackAndForthPlatformObjectBridge()
        self.dddMovingPole = SM64DddMovingPoleObjectBridge()
        self.bitfsSinkingPlatform = SM64BitfsSinkingPlatformObjectBridge(poleBridge: self.dddMovingPole)
        self.lllRotatingHexagonalRing = SM64LllRotatingHexagonalRingObjectBridge()
        self.lllWoodPiece = SM64LllWoodPieceObjectBridge()
        self.lllFloatingWoodBridge = SM64LllFloatingWoodBridgeObjectBridge(pieceBridge: self.lllWoodPiece)
        self.squishablePlatform = SM64SquishablePlatformObjectBridge()
        self.lllDrawbridge = SM64LllDrawbridgeObjectBridge()
        self.idleWaterWave = SM64IdleWaterWaveObjectBridge()
        self.waterfallSoundLoop = SM64WaterfallSoundLoopObjectBridge()
        self.volcanoSoundLoop = SM64VolcanoSoundLoopObjectBridge()
        self.tumblingBridge = SM64TumblingBridgeObjectBridge()
        self.floatingPlatform = SM64FloatingPlatformObjectBridge()
        self.jrbFloatingBox = SM64JrbFloatingBoxObjectBridge()
        self.slidingPlatform2 = SM64SlidingPlatform2ObjectBridge()
        self.waterSplash = SM64WaterSplashObjectBridge()
        self.smallWaterWave = SM64SmallWaterWaveObjectBridge(waterSplashBridge: self.waterSplash)
        self.bubbleParticleSpawner = SM64BubbleParticleSpawnerObjectBridge(smallWaterWaveBridge: self.smallWaterWave)
        self.piranhaPlantWakingBubble = SM64PiranhaPlantWakingBubbleObjectBridge()
        self.piranhaPlantBubble = SM64PiranhaPlantBubbleObjectBridge(wakingBubbleBridge: self.piranhaPlantWakingBubble)
        self.waveTrail = SM64WaveTrailObjectBridge()
        self.sushiShark = SM64SushiSharkObjectBridge()
        self.ukiki = SM64UkikiObjectBridge(scheduler: scheduler)
        self.ukikiCage = SM64UkikiCageObjectBridge(scheduler: scheduler)
        self.mips = SM64MipsObjectBridge(scheduler: scheduler)
        self.toadMessage = SM64ToadMessageObjectBridge(scheduler: scheduler)
        self.menuButton = SM64MenuButtonObjectBridge(scheduler: scheduler)
        self.squarishPathMoving = SM64SquarishPathMovingObjectBridge()
        self.pushableMetalBox = SM64PushableMetalBoxObjectBridge()
        self.tiltingBowserLavaPlatform = SM64TiltingBowserLavaPlatformObjectBridge()
        self.lllBowserPuzzle = SM64LllBowserPuzzleObjectBridge()
        self.strongWindParticle = SM64StrongWindParticleObjectBridge()
        self.waterParticle = SM64WaterParticleObjectBridge(waterSplashBridge: self.waterSplash)
        self.plungeBubble = SM64PlungeBubbleObjectBridge(waterParticleBridge: self.waterParticle)
        self.ambientSoundLoop = SM64AmbientSoundLoopObjectBridge()
        self.rotatingExclamationMark = SM64RotatingExclamationMarkObjectBridge()
        self.bubbleMaybe = SM64BubbleMaybeObjectBridge()
        self.waterAirBubble = SM64WaterAirBubbleObjectBridge(bubbleMaybeBridge: self.bubbleMaybe)
        self.objectBubble = SM64ObjectBubbleObjectBridge(waterSplashBridge: self.waterSplash)
        self.waterDroplet = SM64WaterDropletObjectBridge(waterSplashBridge: self.waterSplash)
        self.shallowWaterWave = SM64ShallowWaterWaveObjectBridge(dropletBridge: self.waterDroplet)
        self.waterSplashSpawner = SM64WaterSplashSpawnerObjectBridge(dropletBridge: self.waterDroplet)
        self.waterMist = SM64WaterMistObjectBridge()
        self.waterMist2 = SM64WaterMist2ObjectBridge()
        self.breathParticleSpawner = SM64BreathParticleSpawnerObjectBridge(waterMistBridge: self.waterMist)
        self.mistParticle = SM64MistParticleObjectBridge()
        self.mistParticleSpawner = SM64MistParticleSpawnerObjectBridge(puffBridge: self.mistParticle)
        self.tweesterSandParticle = SM64TweesterSandParticleObjectBridge()
        self.blackSmokeMario = SM64BlackSmokeMarioObjectBridge()
        self.flameMario = SM64FlameMarioObjectBridge(blackSmokeBridge: self.blackSmokeMario)
        self.blackSmokeBowser = SM64BlackSmokeBowserObjectBridge()
        self.blackSmokeUpward = SM64BlackSmokeUpwardObjectBridge(bowserSmokeBridge: self.blackSmokeBowser)
        self.whitePuffSmoke = SM64WhitePuffSmokeObjectBridge()
        self.whitePuffSmoke2 = SM64WhitePuffSmoke2ObjectBridge()
        self.whitePuffExplosion = SM64WhitePuffExplosionObjectBridge()
        self.dustSmoke = SM64DustSmokeObjectBridge()
        self.starKeyPuffSpawner = SM64StarKeyCollectionPuffSpawnerObjectBridge(puffBridge: self.whitePuffExplosion)
        self.staticFlame = SM64FlameObjectBridge()
        self.flamethrowerFlame = SM64FlamethrowerFlameObjectBridge()
        self.flameBouncing = SM64FlameBouncingObjectBridge()
        self.bowserFlame = SM64BowserFlameObjectBridge(smokeBridge: self.blackSmokeUpward)
        self.blueFlamesGroup = SM64BlueFlamesGroupObjectBridge(flameBridge: self.flameBouncing)
        self.flameFloatingLanding = SM64FlameFloatingLandingObjectBridge(bowserFlameBridge: self.bowserFlame, blueGroupBridge: self.blueFlamesGroup)
        self.blueBowserFlame = SM64BlueBowserFlameObjectBridge(floatingBridge: self.flameFloatingLanding)
        self.volcanoFlames = SM64VolcanoFlamesObjectBridge()
        self.koopaShellFlame = SM64KoopaShellFlameObjectBridge()
        self.flameMovingForwardGrowing = SM64FlameMovingForwardGrowingObjectBridge(bowserFlameBridge: self.bowserFlame)
        self.betaMovingFlames = SM64BetaMovingFlamesObjectBridge()
        self.bowserFlameSpawn = SM64BowserFlameSpawnObjectBridge(movingFlameBridge: self.flameMovingForwardGrowing)
        self.smallPiranhaFlame = SM64SmallPiranhaFlameObjectBridge(flyGuyBridge: self.flyGuy)
        self.fireSpitter = SM64FireSpitterObjectBridge(smallFlameBridge: self.smallPiranhaFlame)
        self.firePiranhaPlant = SM64FirePiranhaPlantObjectBridge(flameBridge: self.smallPiranhaFlame)
        self.flamethrower = SM64FlamethrowerObjectBridge(flameBridge: self.flamethrowerFlame)
        self.rrRotatingBridgePlatform = SM64RrRotatingBridgePlatformObjectBridge(flameBridge: self.flamethrower)
        self.snowmanWind = SM64SnowmanWindObjectBridge()
        self.mrBlizzardSnowball = SM64MrBlizzardSnowballObjectBridge()
        self.celebrationStarSparkle = SM64CelebrationStarSparkleObjectBridge()
        self.groundParticleSpawner = SM64GroundParticleSpawnerObjectBridge(puffBridge: self.whitePuffExplosion)
        self.animatedTexture = SM64AnimatedTextureObjectBridge()
        self.sparkle = SM64SparkleObjectBridge()
        self.sparkleSpawner = SM64SparkleSpawnerObjectBridge(sparkleBridge: self.sparkle)
        self.ambientSounds = SM64AmbientSoundsObjectBridge()
        self.coinSparkles = SM64CoinSparklesObjectBridge()
        self.goldenCoinSparkles = SM64GoldenCoinSparklesObjectBridge(coinSparklesBridge: self.coinSparkles)
        self.purpleParticle = SM64PurpleParticleObjectBridge()
        self.unusedParticleSpawn = SM64UnusedParticleSpawnObjectBridge(purpleParticleBridge: self.purpleParticle)
        self.snowmanCheckpoint = SM64SnowmanCheckpointObjectBridge()
        self.bowserBodyAnchor = SM64BowserBodyAnchorObjectBridge()
        self.bowserTailAnchor = SM64BowserTailAnchorObjectBridge()
        self.snowmanHead = SM64SnowmanHeadObjectBridge()
        self.madPiano = SM64MadPianoObjectBridge()
        self.betaChest = SM64BetaChestObjectBridge(waterAirBubbleBridge: self.waterAirBubble)
        self.betaTrampoline = SM64BetaTrampolineObjectBridge()
        self.betaHoldable = SM64BetaHoldableObjectBridge()
        self.seaweed = SM64SeaweedObjectBridge()
        self.shipPart3 = SM64ShipPart3ObjectBridge()
        self.sunkenShipPart = SM64SunkenShipPartObjectBridge()
        self.jrbSlidingBox = SM64JrbSlidingBoxObjectBridge()
        self.fallingPillar = SM64FallingPillarObjectBridge()
        self.coffin = SM64CoffinObjectBridge()
        self.blueFish = SM64BlueFishObjectBridge()
        self.clamShell = SM64ClamShellObjectBridge(bubbleBridge: self.bubbleMaybe)
        self.bobombAnchorMario = SM64BobombAnchorMarioObjectBridge()
        self.bub = SM64BubObjectBridge()
        self.bubba = SM64BubbaObjectBridge(waterSplashBridge: self.waterSplash)
        self.bowlingBall = SM64BowlingBallObjectBridge()
        self.dddPole = SM64DDDPoleObjectBridge()
        self.donutPlatform = SM64DonutPlatformObjectBridge()
        self.courtyardBooTriplet = SM64CourtyardBooTripletObjectBridge(booBridge: self.boo)
        self.fallingBowserPlatform = SM64FallingBowserPlatformObjectBridge()
        self.butterfly = SM64ButterflyObjectBridge()
        self.tiltingPyramid = SM64TiltingPyramidObjectBridge()
        self.bookend = SM64BookendObjectBridge()
        self.bookSwitch = SM64BookSwitchObjectBridge(bookendBridge: self.bookend)
        self.hauntedBookshelf = SM64HauntedBookshelfObjectBridge()
        self.hauntedBookshelfManager = SM64HauntedBookshelfManagerObjectBridge(bookSwitchBridge: self.bookSwitch, bookshelfBridge: self.hauntedBookshelf)
        self.hauntedChair = SM64HauntedChairObjectBridge()
        self.fish = SM64FishObjectBridge()
        self.cannonBarrel = SM64CannonBarrelObjectBridge()
        self.cannon = SM64CannonObjectBridge(barrelBridge: self.cannonBarrel)
        self.merryGoRoundBooManager = SM64MerryGoRoundBooManagerObjectBridge(booBridge: self.boo, bigBooBridge: self.bigBoo)
        self.tinyStarParticle = SM64TinyStarParticleObjectBridge()
        self.tinyStarParticleSpawner = SM64TinyStarParticleSpawnerObjectBridge(particleBridge: self.tinyStarParticle)
        self.triangleParticle = SM64TriangleParticleObjectBridge()
        self.triangleParticleSpawner = SM64TriangleParticleSpawnerObjectBridge(particleBridge: self.triangleParticle)
        self.treeLeaf = SM64TreeLeafObjectBridge()
        self.treeParticleSpawner = SM64TreeParticleSpawnerObjectBridge(treeBridge: self.treeLeaf)
        self.mistCircParticleSpawner = SM64MistCircParticleSpawnerObjectBridge(puffBridge: self.whitePuffExplosion)
        self.sparkleParticleSpawner = SM64SparkleParticleSpawnerObjectBridge()
        self.simpleAnimation = SM64SimpleAnimationObjectBridge()
        self.unusedFakeStar = SM64UnusedFakeStarObjectBridge()
        self.cloudPart = SM64CloudPartObjectBridge()
        self.breakBoxTriangle = SM64BreakBoxTriangleObjectBridge()
        self.cannonBaseUnused = SM64CannonBaseUnusedObjectBridge()
        self.noOp = SM64NoOpObjectBridge()
        self.giantPole = SM64GiantPoleObjectBridge(noOpBridge: self.noOp)
        self.koopaFlag = SM64KoopaFlagObjectBridge()
        self.koopaRaceEndpoint = SM64KoopaRaceEndpointObjectBridge(flagBridge: self.koopaFlag)
        self.wfBreakableWall = SM64WfBreakableWallObjectBridge()
        self.unusedPoundablePlatform = SM64UnusedPoundablePlatformObjectBridge()
        self.yellowBackgroundMenu = SM64YellowBackgroundMenuObjectBridge()
        self.snowMound = SM64SnowMoundObjectBridge()
        self.rrCruiserWing = SM64RrCruiserWingObjectBridge()
        self.spindrift = SM64SpindriftObjectBridge()
        self.spindel = SM64SpindelObjectBridge()
        self.endCutsceneActor = SM64EndCutsceneActorObjectBridge()
        self.endBirds = SM64EndBirdsObjectBridge()
        self.beginningPeach = SM64BeginningPeachObjectBridge()
        self.cannonBarrelBubbles = SM64CannonBarrelBubblesObjectBridge(waterBombBridge: self.waterBomb)
        self.cloud = SM64CloudObjectBridge(partBridge: self.cloudPart, windBridge: self.strongWindParticle)
        self.celebrationStar = SM64CelebrationStarObjectBridge(sparkleBridge: self.celebrationStarSparkle)
        self.warp = SM64WarpObjectBridge()
        self.dddWarp = SM64DddWarpObjectBridge()
        let sharedActSelectorStarType = SM64ActSelectorStarTypeObjectBridge()
        self.actSelectorStarType = sharedActSelectorStarType
        self.actSelector = SM64ActSelectorObjectBridge(
            scheduler: scheduler,
            starTypeBridge: sharedActSelectorStarType
        )
        self.collectStar = SM64CollectStarObjectBridge()
        self.starSpawnCoordinates = SM64StarSpawnCoordinatesObjectBridge(sparkleSpawnerBridge: self.sparkleSpawner)
        self.spawnedStar = SM64SpawnedStarObjectBridge(sparkleSpawnerBridge: self.sparkleSpawner)
        self.unlockDoorStar = SM64UnlockDoorStarObjectBridge()
        self.ccmTouchedStarSpawn = SM64CcmTouchedStarSpawnObjectBridge(starSpawnBridge: self.starSpawnCoordinates)
        self.hiddenStar = SM64HiddenStarObjectBridge(starSpawnBridge: self.starSpawnCoordinates)
        self.castleCannonGrate = SM64CastleCannonGrateObjectBridge()
        self.blueCoin = SM64BlueCoinObjectBridge(goldenCoinSparklesBridge: self.goldenCoinSparkles)
        self.redCoin = SM64RedCoinObjectBridge(
            starSpawnBridge: self.starSpawnCoordinates,
            collectStarBridge: self.collectStar,
            goldenCoinSparklesBridge: self.goldenCoinSparkles
        )
        self.starDoor = SM64StarDoorObjectBridge()
        self.capSwitch = SM64CapSwitchObjectBridge()
        self.metalCap = SM64MetalCapObjectBridge()
        self.vanishCap = SM64VanishCapObjectBridge()
        self.wingCap = SM64WingCapObjectBridge()
        self.normalCap = SM64NormalCapObjectBridge()
        self.towerDoor = SM64TowerDoorObjectBridge()
        self.openableGrill = SM64OpenableGrillObjectBridge()
        self.door = SM64DoorObjectBridge()
        self.hiddenObject = SM64HiddenObjectObjectBridge()
        self.recoveryHeart = SM64RecoveryHeartObjectBridge()
        self.coin = SM64CoinObjectBridge(goldenCoinSparklesBridge: self.goldenCoinSparkles)
        self.movingCoin = SM64MovingCoinObjectBridge(goldenCoinSparklesBridge: self.goldenCoinSparkles)
        self.waterLevel = SM64WaterLevelObjectBridge()
        self.waterPillar = SM64WaterPillarObjectBridge()
        self.floorSwitch = SM64FloorSwitchObjectBridge()
        self.animatedFloorSwitch = SM64AnimatedFloorSwitchObjectBridge()
        self.hiddenOneUp = SM64HiddenOneUpObjectBridge()
        self.breakableBox = SM64BreakableBoxObjectBridge()
        self.jumpingBox = SM64JumpingBoxObjectBridge()
        self.kickableBoard = SM64KickableBoardObjectBridge()
        self.exclamationBox = SM64ExclamationBoxObjectBridge(rotatingMarkBridge: self.rotatingExclamationMark)
        self.orangeNumber = SM64OrangeNumberObjectBridge(goldenCoinSparklesBridge: self.goldenCoinSparkles)
        self.soundSpawner = SM64SoundSpawnerObjectBridge()
        self.rockSolid = SM64RockSolidObjectBridge()
        self.toxBox = SM64ToxBoxObjectBridge()
        self.sslMovingPyramidWall = SM64SslMovingPyramidWallObjectBridge()
        self.thiIslandTop = SM64ThiIslandTopObjectBridge()
        self.pyramidTopFragment = SM64PyramidTopFragmentObjectBridge()
        self.pyramidPillarTouchDetector = SM64PyramidPillarTouchDetectorObjectBridge()
        self.pyramidTop = SM64PyramidTopObjectBridge()
        self.environmentGate = SM64EnvironmentGateObjectBridge()
        self.clockArm = SM64ClockArmObjectBridge()
        self.castleFloorTrap = SM64CastleFloorTrapObjectBridge()
        self.castleFlag = SM64CastleFlagObjectBridge()
        self.booCage = SM64BooCageObjectBridge()
        self.booKey = SM64BooKeyObjectBridge(goldenCoinSparklesBridge: self.goldenCoinSparkles)
        self.booInCastle = SM64BooInCastleObjectBridge()
        self.merryGoRound = SM64MerryGoRoundObjectBridge()
        self.musicTouch = SM64MusicTouchObjectBridge()
        self.textSurface = SM64TextSurfaceObjectBridge()
        self.grandStar = SM64GrandStarObjectBridge()
        self.betaBowserAnchor = SM64BetaBowserAnchorObjectBridge()
        self.wind = SM64WindObjectBridge()
        self.jetStream = SM64JetStreamObjectBridge()
        self.jetStreamWaterRing = SM64JetStreamWaterRingObjectBridge()
        self.jetStreamRingSpawner = SM64JetStreamRingSpawnerObjectBridge(ringBridge: self.jetStreamWaterRing)
        self.mantaRayWaterRing = SM64MantaRayWaterRingObjectBridge()
        self.whirlpool = SM64WhirlpoolObjectBridge()
        self.mantaRay = SM64MantaRayObjectBridge(ringBridge: self.mantaRayWaterRing)
    }

    static func route(for behaviorIdentity: UInt64) -> SM64BehaviorDispatchRoute {
        switch behaviorIdentity {
        case SM64DecorativePendulumObjectBridge.defaultBehaviorIdentity:
            return .decorativePendulum
        case SM64RespawnerObjectBridge.defaultBehaviorIdentity:
            return .respawner
        case SM64AmpObjectBridge.defaultBehaviorIdentity:
            return .amp
        case SM64BooObjectBridge.defaultBehaviorIdentity,
             SM64BooObjectBridge.ghostHuntBehaviorIdentity,
             SM64BooObjectBridge.merryGoRoundBehaviorIdentity,
             SM64BooObjectBridge.withCageBehaviorIdentity:
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
        case SM64BompObjectBridge.smallBehaviorIdentity,
             SM64BompObjectBridge.largeBehaviorIdentity:
            return .bomp
        case SM64SpindriftObjectBridge.defaultBehaviorIdentity:
            return .bomp
        case SM64MrBlizzardSnowballObjectBridge.defaultBehaviorIdentity:
            return .bomp
        case SM64ThwompObjectBridge.grindelBehaviorIdentity,
             SM64ThwompObjectBridge.thwomp2BehaviorIdentity,
             SM64ThwompObjectBridge.thwompBehaviorIdentity:
            return .thwomp
        case SM64BoulderObjectBridge.defaultBehaviorIdentity:
            return .boulder
        case SM64BoulderObjectBridge.generatorBehaviorIdentity:
            return .boulder
        case SM64HorizontalGrindelObjectBridge.defaultBehaviorIdentity:
            return .horizontalGrindel
        case SM64UnusedParticleSpawnObjectBridge.defaultBehaviorIdentity:
            return .unusedParticleSpawn
        case SM64SnowmanCheckpointObjectBridge.defaultBehaviorIdentity:
            return .snowmanCheckpoint
        case SM64BowserBodyAnchorObjectBridge.defaultBehaviorIdentity:
            return .bowserBodyAnchor
        case SM64BowserTailAnchorObjectBridge.defaultBehaviorIdentity:
            return .bowserTailAnchor
        case SM64SnowmanHeadObjectBridge.defaultBehaviorIdentity:
            return .snowmanHead
        case SM64MadPianoObjectBridge.defaultBehaviorIdentity:
            return .madPiano
        case SM64BetaChestObjectBridge.bottomBehaviorIdentity,
             SM64BetaChestObjectBridge.lidBehaviorIdentity:
            return .betaChest
        case SM64BetaTrampolineObjectBridge.topBehaviorIdentity,
             SM64BetaTrampolineObjectBridge.springBehaviorIdentity:
            return .betaTrampoline
        case SM64BetaHoldableObjectBridge.defaultBehaviorIdentity:
            return .betaHoldable
        case SM64SeaweedObjectBridge.seaweedBehaviorIdentity,
             SM64SeaweedObjectBridge.bundleBehaviorIdentity:
            return .seaweed
        case SM64ShipPart3ObjectBridge.decorativeBehaviorIdentity,
             SM64ShipPart3ObjectBridge.collisionBehaviorIdentity:
            return .shipPart3
        case SM64SunkenShipPartObjectBridge.defaultBehaviorIdentity:
            return .shipPart3
        case SM64JrbSlidingBoxObjectBridge.defaultBehaviorIdentity:
            return .shipPart3
        case SM64FallingPillarObjectBridge.pillarBehaviorIdentity,
             SM64FallingPillarObjectBridge.hitboxBehaviorIdentity:
            return .fallingPillar
        case SM64CoffinObjectBridge.spawnerBehaviorIdentity,
             SM64CoffinObjectBridge.coffinBehaviorIdentity:
            return .coffin
        case SM64BlueFishObjectBridge.defaultBehaviorIdentity:
            return .blueFish
        case SM64BlueFishObjectBridge.tankFishGroupBehaviorIdentity:
            return .blueFish
        case SM64ClamShellObjectBridge.defaultBehaviorIdentity:
            return .clamShell
        case SM64BobombAnchorMarioObjectBridge.defaultBehaviorIdentity:
            return .bobombAnchorMario
        case SM64BubObjectBridge.bubBehaviorIdentity,
             SM64BubObjectBridge.chirpChirpBehaviorIdentity,
             SM64BubObjectBridge.chirpChirpUnusedBehaviorIdentity:
            return .bub
        case SM64BubbaObjectBridge.defaultBehaviorIdentity:
            return .bubba
        case SM64BowlingBallObjectBridge.bowlingBallBehaviorIdentity,
             SM64BowlingBallObjectBridge.freeBowlingBallBehaviorIdentity,
             SM64BowlingBallObjectBridge.bobBowlingBallSpawnerBehaviorIdentity,
             SM64BowlingBallObjectBridge.ttmBowlingBallSpawnerBehaviorIdentity,
             SM64BowlingBallObjectBridge.thiBowlingBallSpawnerBehaviorIdentity,
             SM64BowlingBallObjectBridge.pitBowlingBallBehaviorIdentity:
            return .bowlingBall
        case SM64DDDPoleObjectBridge.defaultBehaviorIdentity:
            return .dddPole
        case SM64DonutPlatformObjectBridge.spawnerBehaviorIdentity,
             SM64DonutPlatformObjectBridge.platformBehaviorIdentity:
            return .donutPlatform
        case SM64CourtyardBooTripletObjectBridge.defaultBehaviorIdentity:
            return .courtyardBooTriplet
        case SM64FallingBowserPlatformObjectBridge.defaultBehaviorIdentity:
            return .fallingBowserPlatform
        case SM64GiantPoleObjectBridge.defaultBehaviorIdentity:
            return .giantPole
        case SM64KoopaFlagObjectBridge.defaultBehaviorIdentity,
             SM64KoopaFlagObjectBridge.poleGrabbingBehaviorIdentity,
             SM64KoopaFlagObjectBridge.treeBehaviorIdentity:
            return .giantPole
        case SM64KoopaRaceEndpointObjectBridge.defaultBehaviorIdentity:
            return .giantPole
        case SM64EndCutsceneActorObjectBridge.endPeachBehaviorIdentity,
             SM64EndCutsceneActorObjectBridge.endToadBehaviorIdentity,
             SM64EndBirdsObjectBridge.birds1BehaviorIdentity,
             SM64EndBirdsObjectBridge.birds2BehaviorIdentity,
             SM64BeginningPeachObjectBridge.defaultBehaviorIdentity:
            return .endCutsceneActor
        case SM64ButterflyObjectBridge.defaultBehaviorIdentity:
            return .butterfly
        case SM64TiltingPyramidObjectBridge.bitfsBehaviorIdentity,
             SM64TiltingPyramidObjectBridge.anotherBehaviorIdentity,
             SM64TiltingPyramidObjectBridge.lllBehaviorIdentity:
            return .tiltingPyramid
        case SM64BookendObjectBridge.spawnerBehaviorIdentity,
             SM64BookendObjectBridge.flyingBehaviorIdentity:
            return .bookend
        case SM64BookSwitchObjectBridge.defaultBehaviorIdentity:
            return .bookSwitch
        case SM64HauntedBookshelfObjectBridge.defaultBehaviorIdentity:
            return .bookSwitch
        case SM64HauntedBookshelfManagerObjectBridge.defaultBehaviorIdentity:
            return .bookSwitch
        case SM64HauntedChairObjectBridge.defaultBehaviorIdentity:
            return .bookSwitch
        case SM64FishObjectBridge.fishBehaviorIdentity,
             SM64FishObjectBridge.fishGroupBehaviorIdentity,
             SM64FishObjectBridge.fish2BehaviorIdentity,
             SM64FishObjectBridge.fish3BehaviorIdentity,
             SM64FishObjectBridge.largeFishGroupBehaviorIdentity:
            return .fish
        case SM64CannonBarrelObjectBridge.defaultBehaviorIdentity:
            return .cannonBarrel
        case SM64CannonObjectBridge.defaultBehaviorIdentity:
            return .cannon
        case SM64MerryGoRoundBooManagerObjectBridge.defaultBehaviorIdentity:
            return .merryGoRoundBooManager
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
             SM64BobombBuddyObjectBridge.opensCannonBehaviorIdentity,
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
        case SM64TuxiesMotherObjectBridge.defaultMotherBehaviorIdentity,
             SM64TuxiesMotherObjectBridge.unusedChildBehaviorIdentity,
             SM64TuxiesMotherObjectBridge.babyChildBehaviorIdentity:
            return .tuxiesMother
        case SM64ArrowLiftObjectBridge.defaultBehaviorIdentity:
            return .arrowLift
        case SM64ElevatorObjectBridge.rrBehaviorIdentity,
             SM64ElevatorObjectBridge.hmcBehaviorIdentity,
             SM64ElevatorObjectBridge.meshBehaviorIdentity,
             SM64ElevatorObjectBridge.anotherElevatorBehaviorIdentity:
            return .elevator
        case SM64SeesawPlatformObjectBridge.defaultBehaviorIdentity:
            return .seesawPlatform
        case SM64SwingPlatformObjectBridge.defaultBehaviorIdentity:
            return .swingPlatform
        case SM64RotatingPlatformObjectBridge.defaultBehaviorIdentity:
            return .rotatingPlatform
        case SM64TTCMovingBarObjectBridge.defaultBehaviorIdentity:
            return .ttcMovingBar
        case SM64TTCSpinnerObjectBridge.defaultBehaviorIdentity:
            return .ttcSpinner
        case SM64TTCTreadmillObjectBridge.defaultBehaviorIdentity:
            return .ttcTreadmill
        case SM64TTCPendulumObjectBridge.defaultBehaviorIdentity:
            return .ttcPendulum
        case SM64TTCElevatorObjectBridge.defaultBehaviorIdentity:
            return .ttcElevator
        case SM64TTCRotatingSolidObjectBridge.defaultBehaviorIdentity:
            return .ttcRotatingSolid
        case SM64TTC2DRotatorObjectBridge.defaultBehaviorIdentity:
            return .ttc2DRotator
        case SM64TTCCogObjectBridge.defaultBehaviorIdentity:
            return .ttcCog
        case SM64PyramidElevatorObjectBridge.elevatorBehaviorIdentity:
            return .pyramidElevator
        case SM64PyramidElevatorObjectBridge.markerBehaviorIdentity:
            return .pyramidMarker
        case SM64PyramidTopFragmentObjectBridge.defaultBehaviorIdentity:
            return .pyramidElevator
        case SM64PyramidPillarTouchDetectorObjectBridge.defaultBehaviorIdentity:
            return .pyramidElevator
        case SM64PyramidTopObjectBridge.defaultBehaviorIdentity:
            return .pyramidElevator
        case SM64TTCPitBlockObjectBridge.defaultBehaviorIdentity:
            return .ttcPitBlock
        case SM64StaticCheckeredPlatformObjectBridge.defaultBehaviorIdentity:
            return .staticCheckeredPlatform
        case SM64BBHTiltingTrapPlatformObjectBridge.defaultBehaviorIdentity:
            return .bbhTiltingTrapPlatform
        case SM64LLLSinkingPlatformObjectBridge.rectangularBehaviorIdentity,
             SM64LLLSinkingPlatformObjectBridge.squareBehaviorIdentity:
            return .lllSinkingPlatform
        case SM64WfRotatingWoodenPlatformObjectBridge.defaultBehaviorIdentity:
            return .wfRotatingWoodenPlatform
        case SM64RotatingOctagonalPlatformObjectBridge.defaultBehaviorIdentity:
            return .rotatingOctagonalPlatform
        case SM64WfSolidTowerPlatformObjectBridge.defaultBehaviorIdentity:
            return .wfSolidTowerPlatform
        case SM64WfTowerPlatformObjectBridge.elevatorBehaviorIdentity,
             SM64WfTowerPlatformObjectBridge.slidingBehaviorIdentity:
            return .wfTowerPlatform
        case SM64TrackBallObjectBridge.defaultBehaviorIdentity:
            return .wfTowerPlatform
        case SM64WfSlidingPlatformObjectBridge.defaultBehaviorIdentity:
            return .wfSlidingPlatform
        case SM64WdwExpressElevatorObjectBridge.elevatorBehaviorIdentity,
             SM64WdwExpressElevatorObjectBridge.staticPlatformBehaviorIdentity:
            return .wdwExpressElevator
        case SM64LllSinkingRockBlockObjectBridge.defaultBehaviorIdentity:
            return .lllSinkingRockBlock
        case SM64VolcanoFallingTrapObjectBridge.defaultBehaviorIdentity:
            return .lllSinkingRockBlock
        case SM64RollingLogObjectBridge.ttmBehaviorIdentity,
             SM64RollingLogObjectBridge.lllBehaviorIdentity:
            return .lllSinkingRockBlock
        case SM64LllMovingOctagonalMeshObjectBridge.defaultBehaviorIdentity:
            return .lllMovingOctagonalMesh
        case SM64FerrisWheelPlatformObjectBridge.axleBehaviorIdentity,
             SM64FerrisWheelPlatformObjectBridge.platformBehaviorIdentity:
            return .ferrisWheel
        case SM64CheckerboardPlatformObjectBridge.groupBehaviorIdentity,
             SM64CheckerboardPlatformObjectBridge.childBehaviorIdentity:
            return .checkerboardPlatform
        case SM64WfTowerPlatformGroupObjectBridge.defaultBehaviorIdentity:
            return .wfTowerPlatformGroup
        case SM64LllRotatingHexagonalPlatformObjectBridge.defaultBehaviorIdentity:
            return .lllRotatingHexagonalPlatform
        case SM64LllRotatingHexFlameObjectBridge.defaultBehaviorIdentity:
            return .lllRotatingHexFlame
        case SM64LllRotatingFireBarObjectBridge.defaultBehaviorIdentity:
            return .lllRotatingFireBar
        case SM64ActivatedBackAndForthPlatformObjectBridge.defaultBehaviorIdentity:
            return .activatedBackAndForthPlatform
        case SM64BitfsSinkingPlatformObjectBridge.platformBehaviorIdentity,
             SM64BitfsSinkingPlatformObjectBridge.cageBehaviorIdentity:
            return .bitfsSinkingPlatform
        case SM64DddMovingPoleObjectBridge.defaultBehaviorIdentity:
            return .dddMovingPole
        case SM64LllRotatingHexagonalRingObjectBridge.defaultBehaviorIdentity:
            return .lllRotatingHexagonalRing
        case SM64LllFloatingWoodBridgeObjectBridge.behaviorIdentity,
             SM64LllWoodPieceObjectBridge.behaviorIdentity:
            return .lllFloatingWoodBridge
        case SM64SquishablePlatformObjectBridge.defaultBehaviorIdentity:
            return .squishablePlatform
        case SM64LllDrawbridgeObjectBridge.spawnerBehaviorIdentity,
             SM64LllDrawbridgeObjectBridge.drawbridgeBehaviorIdentity:
            return .lllDrawbridge
        case SM64IdleWaterWaveObjectBridge.defaultBehaviorIdentity,
             SM64IdleWaterWaveObjectBridge.objectWaterWaveBehaviorIdentity:
            return .idleWaterWave
        case SM64WaterfallSoundLoopObjectBridge.defaultBehaviorIdentity:
            return .waterfallSoundLoop
        case SM64VolcanoSoundLoopObjectBridge.defaultBehaviorIdentity:
            return .volcanoSoundLoop
        case SM64TumblingBridgeObjectBridge.wfBehaviorIdentity,
             SM64TumblingBridgeObjectBridge.bbhBehaviorIdentity,
             SM64TumblingBridgeObjectBridge.lllBehaviorIdentity,
             SM64TumblingBridgeObjectBridge.platformBehaviorIdentity:
            return .tumblingBridge
        case SM64FloatingPlatformObjectBridge.wdwSquareBehaviorIdentity,
             SM64FloatingPlatformObjectBridge.wdwRectangularBehaviorIdentity,
             SM64FloatingPlatformObjectBridge.jrbBehaviorIdentity:
            return .floatingPlatform
        case SM64JrbFloatingBoxObjectBridge.defaultBehaviorIdentity:
            return .floatingPlatform
        case SM64SnowMoundObjectBridge.slidingBehaviorIdentity,
             SM64SnowMoundObjectBridge.spawnerBehaviorIdentity:
            return .floatingPlatform
        case SM64RrCruiserWingObjectBridge.defaultBehaviorIdentity:
            return .tumblingBridge
        case SM64SpindelObjectBridge.defaultBehaviorIdentity:
            return .tumblingBridge
        case SM64SlidingPlatform2ObjectBridge.defaultBehaviorIdentity:
            return .slidingPlatform2
        case SM64SmallWaterWaveObjectBridge.defaultBehaviorIdentity:
            return .smallWaterWave
        case SM64AmbientSoundLoopObjectBridge.birdsBehaviorIdentity,
             SM64AmbientSoundLoopObjectBridge.sandBehaviorIdentity:
            return .ambientSoundLoop
        case SM64RotatingExclamationMarkObjectBridge.defaultBehaviorIdentity:
            return .rotatingExclamationMark
        case SM64WaterAirBubbleObjectBridge.defaultBehaviorIdentity:
            return .waterAirBubble
        case SM64ObjectBubbleObjectBridge.defaultBehaviorIdentity:
            return .objectBubble
        case SM64WaterDropletObjectBridge.defaultBehaviorIdentity:
            return .waterDroplet
        case SM64WaterMistObjectBridge.defaultBehaviorIdentity:
            return .waterMist
        case SM64WaterMist2ObjectBridge.defaultBehaviorIdentity:
            return .waterMist2
        case SM64WaterSplashObjectBridge.bubbleBehaviorIdentity,
             SM64WaterSplashObjectBridge.waterDropletBehaviorIdentity,
             SM64WaterSplashObjectBridge.objectBehaviorIdentity:
            return .waterSplash
        case SM64BubbleMaybeObjectBridge.defaultBehaviorIdentity:
            return .bubbleMaybe
        case SM64WindObjectBridge.defaultBehaviorIdentity:
            return .wind
        case SM64SnowmanWindObjectBridge.defaultBehaviorIdentity:
            return .wind
        case SM64JetStreamObjectBridge.defaultBehaviorIdentity:
            return .wind
        case SM64JetStreamWaterRingObjectBridge.defaultBehaviorIdentity:
            return .wind
        case SM64JetStreamRingSpawnerObjectBridge.defaultBehaviorIdentity:
            return .wind
        case SM64MantaRayWaterRingObjectBridge.defaultBehaviorIdentity:
            return .wind
        case SM64WhirlpoolObjectBridge.defaultBehaviorIdentity:
            return .wind
        case SM64MantaRayObjectBridge.defaultBehaviorIdentity:
            return .wind
        case SM64ShallowWaterWaveObjectBridge.defaultBehaviorIdentity,
             SM64ShallowWaterWaveObjectBridge.splashBehaviorIdentity:
            return .shallowWaterWave
        case SM64WaterSplashSpawnerObjectBridge.defaultBehaviorIdentity:
            return .waterSplashSpawner
        case SM64BubbleParticleSpawnerObjectBridge.defaultBehaviorIdentity:
            return .bubbleParticleSpawner
        case SM64PiranhaPlantWakingBubbleObjectBridge.defaultBehaviorIdentity:
            return .piranhaPlantWakingBubble
        case SM64PiranhaPlantBubbleObjectBridge.defaultBehaviorIdentity:
            return .piranhaPlantBubble
        case SM64WaveTrailObjectBridge.marioBehaviorIdentity,
             SM64WaveTrailObjectBridge.objectBehaviorIdentity:
            return .waveTrail
        case SM64SushiSharkObjectBridge.sushiBehaviorIdentity,
             SM64SushiSharkObjectBridge.collisionChildBehaviorIdentity:
            return .sushiShark
        case SM64UkikiObjectBridge.ukikiBehaviorIdentity,
             SM64UkikiObjectBridge.macroUkikiBehaviorIdentity:
            return .ukiki
        case SM64UkikiCageObjectBridge.cageBehaviorIdentity,
             SM64UkikiCageObjectBridge.starBehaviorIdentity:
            return .ukikiCage
        case SM64MipsObjectBridge.defaultBehaviorIdentity:
            return .mips
        case SM64ToadMessageObjectBridge.defaultBehaviorIdentity:
            return .toadMessage
        case SM64MenuButtonObjectBridge.buttonBehaviorIdentity,
             SM64MenuButtonObjectBridge.managerBehaviorIdentity:
            return .menuButton
        case SM64SquarishPathMovingObjectBridge.defaultBehaviorIdentity:
            return .squarishPathMoving
        case SM64PushableMetalBoxObjectBridge.defaultBehaviorIdentity:
            return .pushableMetalBox
        case SM64TiltingBowserLavaPlatformObjectBridge.defaultBehaviorIdentity:
            return .tiltingBowserLavaPlatform
        case SM64LllBowserPuzzleObjectBridge.puzzleBehaviorIdentity,
             SM64LllBowserPuzzleObjectBridge.pieceBehaviorIdentity:
            return .lllBowserPuzzle
        case SM64StrongWindParticleObjectBridge.visibleBehaviorIdentity,
             SM64StrongWindParticleObjectBridge.tinyBehaviorIdentity:
            return .strongWindParticle
        case SM64WaterParticleObjectBridge.smallBehaviorIdentity,
             SM64WaterParticleObjectBridge.snowBehaviorIdentity,
             SM64WaterParticleObjectBridge.bubblesBehaviorIdentity:
            return .waterParticle
        case SM64PlungeBubbleObjectBridge.defaultBehaviorIdentity:
            return .plungeBubble
        case SM64BreathParticleSpawnerObjectBridge.defaultBehaviorIdentity:
            return .breathParticleSpawner
        case SM64MistParticleObjectBridge.puff1BehaviorIdentity,
             SM64MistParticleObjectBridge.puff2BehaviorIdentity:
            return .mistParticle
        case SM64MistParticleSpawnerObjectBridge.defaultBehaviorIdentity:
            return .mistParticleSpawner
        case SM64TweesterSandParticleObjectBridge.defaultBehaviorIdentity:
            return .tweesterSandParticle
        case SM64BlackSmokeMarioObjectBridge.defaultBehaviorIdentity:
            return .blackSmokeMario
        case SM64FlameMarioObjectBridge.defaultBehaviorIdentity:
            return .flameMario
        case SM64BlackSmokeBowserObjectBridge.defaultBehaviorIdentity:
            return .blackSmokeBowser
        case SM64BlackSmokeUpwardObjectBridge.defaultBehaviorIdentity:
            return .blackSmokeUpward
        case SM64WhitePuffSmokeObjectBridge.defaultBehaviorIdentity:
            return .whitePuffSmoke
        case SM64WhitePuffSmoke2ObjectBridge.defaultBehaviorIdentity:
            return .whitePuffSmoke2
        case SM64WhitePuffExplosionObjectBridge.defaultBehaviorIdentity:
            return .whitePuffExplosion
        case SM64DustSmokeObjectBridge.smokeBehaviorIdentity,
             SM64DustSmokeObjectBridge.bobombFuseBehaviorIdentity:
            return .dustSmoke
        case SM64StarKeyCollectionPuffSpawnerObjectBridge.defaultBehaviorIdentity:
            return .starKeyPuffSpawner
        case SM64FlameObjectBridge.defaultBehaviorIdentity:
            return .staticFlame
        case SM64FlamethrowerFlameObjectBridge.defaultBehaviorIdentity:
            return .flamethrowerFlame
        case SM64FlameBouncingObjectBridge.defaultBehaviorIdentity:
            return .flameBouncing
        case SM64BowserFlameObjectBridge.normalBehaviorIdentity:
            return .flameBowser
        case SM64BowserFlameObjectBridge.largeBurningOutBehaviorIdentity:
            return .flameLargeBurningOut
        case SM64BlueFlamesGroupObjectBridge.defaultBehaviorIdentity:
            return .blueFlamesGroup
        case SM64FlameFloatingLandingObjectBridge.defaultBehaviorIdentity:
            return .flameFloatingLanding
        case SM64BlueBowserFlameObjectBridge.defaultBehaviorIdentity:
            return .blueBowserFlame
        case SM64VolcanoFlamesObjectBridge.defaultBehaviorIdentity:
            return .volcanoFlames
        case SM64KoopaShellFlameObjectBridge.defaultBehaviorIdentity:
            return .koopaShellFlame
        case SM64FlameMovingForwardGrowingObjectBridge.defaultBehaviorIdentity:
            return .flameMovingForwardGrowing
        case SM64BetaMovingFlamesObjectBridge.spawnBehaviorIdentity:
            return .betaMovingFlamesSpawn
        case SM64BetaMovingFlamesObjectBridge.flameBehaviorIdentity:
            return .betaMovingFlames
        case SM64BowserFlameSpawnObjectBridge.defaultBehaviorIdentity:
            return .bowserFlameSpawn
        case SM64SmallPiranhaFlameObjectBridge.defaultBehaviorIdentity:
            return .smallPiranhaFlame
        case SM64FireSpitterObjectBridge.defaultBehaviorIdentity:
            return .fireSpitter
        case SM64FirePiranhaPlantObjectBridge.defaultBehaviorIdentity:
            return .firePiranhaPlant
        case SM64FlamethrowerObjectBridge.defaultBehaviorIdentity:
            return .flamethrower
        case SM64RrRotatingBridgePlatformObjectBridge.defaultBehaviorIdentity:
            return .flamethrower
        case SM64CelebrationStarSparkleObjectBridge.defaultBehaviorIdentity:
            return .celebrationStarSparkle
        case SM64CelebrationStarObjectBridge.defaultBehaviorIdentity:
            return .celebrationStar
        case SM64WarpObjectBridge.normalBehaviorIdentity,
             SM64WarpObjectBridge.fadingBehaviorIdentity,
             SM64WarpObjectBridge.pipeBehaviorIdentity,
             SM64WarpObjectBridge.exitPodiumBehaviorIdentity:
            return .warp
        case SM64DddWarpObjectBridge.defaultBehaviorIdentity:
            return .dddWarp
        case SM64ActSelectorStarTypeObjectBridge.defaultBehaviorIdentity:
            return .actSelectorStarType
        case SM64ActSelectorObjectBridge.defaultBehaviorIdentity:
            return .actSelector
        case SM64CollectStarObjectBridge.defaultBehaviorIdentity:
            return .collectStar
        case SM64StarSpawnCoordinatesObjectBridge.defaultBehaviorIdentity:
            return .starSpawnCoordinates
        case SM64SpawnedStarObjectBridge.defaultBehaviorIdentity:
            return .spawnedStar
        case SM64SpawnedStarObjectBridge.noLevelExitBehaviorIdentity:
            return .spawnedStarNoLevelExit
        case SM64UnlockDoorStarObjectBridge.defaultBehaviorIdentity:
            return .spawnedStar
        case SM64CcmTouchedStarSpawnObjectBridge.defaultBehaviorIdentity:
            return .ccmTouchedStarSpawn
        case SM64HiddenStarObjectBridge.hiddenStarBehaviorIdentity:
            return .hiddenStar
        case SM64HiddenStarObjectBridge.bowserCourseRedCoinStarBehaviorIdentity:
            return .hiddenStar
        case SM64HiddenStarObjectBridge.triggerBehaviorIdentity:
            return .hiddenStarTrigger
        case SM64CastleCannonGrateObjectBridge.defaultBehaviorIdentity:
            return .castleCannonGrate
        case SM64BlueCoinObjectBridge.blueCoinSwitchBehaviorIdentity:
            return .blueCoinSwitch
        case SM64BlueCoinObjectBridge.hiddenBlueCoinBehaviorIdentity:
            return .hiddenBlueCoin
        case SM64RedCoinObjectBridge.hiddenRedCoinStarBehaviorIdentity:
            return .hiddenRedCoinStar
        case SM64RedCoinObjectBridge.redCoinStarMarkerBehaviorIdentity:
            return .redCoinStarMarker
        case SM64RedCoinObjectBridge.redCoinBehaviorIdentity:
            return .redCoin
        case SM64StarDoorObjectBridge.defaultBehaviorIdentity:
            return .starDoor
        case SM64CapSwitchObjectBridge.capSwitchBehaviorIdentity:
            return .capSwitch
        case SM64CapSwitchObjectBridge.capSwitchBaseBehaviorIdentity:
            return .capSwitchBase
        case SM64MetalCapObjectBridge.defaultBehaviorIdentity:
            return .capSwitch
        case SM64VanishCapObjectBridge.defaultBehaviorIdentity:
            return .capSwitch
        case SM64WingCapObjectBridge.defaultBehaviorIdentity:
            return .capSwitch
        case SM64NormalCapObjectBridge.defaultBehaviorIdentity:
            return .capSwitch
        case SM64TowerDoorObjectBridge.defaultBehaviorIdentity:
            return .towerDoor
        case SM64OpenableGrillObjectBridge.grillBehaviorIdentity:
            return .openableGrill
        case SM64OpenableGrillObjectBridge.cageDoorBehaviorIdentity:
            return .openableCageDoor
        case SM64DoorObjectBridge.normalBehaviorIdentity, SM64DoorObjectBridge.warpBehaviorIdentity:
            return .door
        case SM64HiddenObjectObjectBridge.defaultBehaviorIdentity:
            return .hiddenObject
        case SM64RecoveryHeartObjectBridge.defaultBehaviorIdentity:
            return .recoveryHeart
        case SM64CoinObjectBridge.oneCoinBehaviorIdentity,
             SM64CoinObjectBridge.yellowCoinBehaviorIdentity,
             SM64CoinObjectBridge.temporaryYellowCoinBehaviorIdentity,
             SM64CoinObjectBridge.threeCoinsSpawnBehaviorIdentity,
             SM64CoinObjectBridge.tenCoinsSpawnBehaviorIdentity,
             SM64CoinObjectBridge.singleCoinGetsSpawnedBehaviorIdentity,
             SM64CoinObjectBridge.coinFormationBehaviorIdentity,
             SM64CoinObjectBridge.coinFormationSpawnBehaviorIdentity,
             SM64CoinObjectBridge.coinInsideBooBehaviorIdentity:
            return .coin
        case SM64MovingCoinObjectBridge.movingYellowCoinBehaviorIdentity,
             SM64MovingCoinObjectBridge.movingBlueCoinBehaviorIdentity,
             SM64MovingCoinObjectBridge.blueCoinSlidingBehaviorIdentity,
             SM64MovingCoinObjectBridge.blueCoinJumpingBehaviorIdentity:
            return .movingCoin
        case SM64WaterLevelObjectBridge.diamondBehaviorIdentity:
            return .waterLevelDiamond
        case SM64WaterLevelObjectBridge.initializerBehaviorIdentity:
            return .changingWaterLevel
        case SM64WaterPillarObjectBridge.defaultBehaviorIdentity:
            return .waterPillar
        case SM64FloorSwitchObjectBridge.hardcodedBehaviorIdentity,
             SM64FloorSwitchObjectBridge.grillsBehaviorIdentity,
             SM64FloorSwitchObjectBridge.animatesBehaviorIdentity,
             SM64FloorSwitchObjectBridge.hiddenObjectsBehaviorIdentity,
             SM64FloorSwitchObjectBridge.purpleSwitchHiddenBoxesBehaviorIdentity:
            return .floorSwitch
        case SM64AnimatedFloorSwitchObjectBridge.defaultBehaviorIdentity:
            return .animatedFloorSwitch
        case SM64HiddenOneUpObjectBridge.hiddenBehaviorIdentity,
             SM64HiddenOneUpObjectBridge.triggerBehaviorIdentity,
             SM64HiddenOneUpObjectBridge.hiddenInPoleBehaviorIdentity,
             SM64HiddenOneUpObjectBridge.poleTriggerBehaviorIdentity,
             SM64HiddenOneUpObjectBridge.poleSpawnerBehaviorIdentity,
             SM64HiddenOneUpObjectBridge.oneUpBehaviorIdentity,
             SM64HiddenOneUpObjectBridge.walkingBehaviorIdentity,
             SM64HiddenOneUpObjectBridge.runningAwayBehaviorIdentity,
             SM64HiddenOneUpObjectBridge.slidingBehaviorIdentity,
             SM64HiddenOneUpObjectBridge.jumpOnApproachBehaviorIdentity:
            return .hiddenOneUp
        case SM64BreakableBoxObjectBridge.largeBehaviorIdentity,
             SM64BreakableBoxObjectBridge.smallBehaviorIdentity:
            return .breakableBox
        case SM64JumpingBoxObjectBridge.defaultBehaviorIdentity:
            return .breakableBox
        case SM64KickableBoardObjectBridge.defaultBehaviorIdentity:
            return .breakableBox
        case SM64WfBreakableWallObjectBridge.leftBehaviorIdentity,
             SM64WfBreakableWallObjectBridge.rightBehaviorIdentity:
            return .breakableBox
        case SM64UnusedPoundablePlatformObjectBridge.defaultBehaviorIdentity:
            return .breakableBox
        case SM64YellowBackgroundMenuObjectBridge.defaultBehaviorIdentity:
            return .noOp
        case SM64JumpingBoxObjectBridge.defaultBehaviorIdentity:
            return .breakableBox
        case SM64ExclamationBoxObjectBridge.defaultBehaviorIdentity:
            return .exclamationBox
        case SM64OrangeNumberObjectBridge.defaultBehaviorIdentity:
            return .orangeNumber
        case SM64SoundSpawnerObjectBridge.defaultBehaviorIdentity:
            return .soundSpawner
        case SM64RockSolidObjectBridge.defaultBehaviorIdentity:
            return .rockSolid
        case SM64ToxBoxObjectBridge.defaultBehaviorIdentity:
            return .rockSolid
        case SM64SslMovingPyramidWallObjectBridge.defaultBehaviorIdentity:
            return .lllSinkingRockBlock
        case SM64ThiIslandTopObjectBridge.hugeBehaviorIdentity,
             SM64ThiIslandTopObjectBridge.tinyBehaviorIdentity:
            return .environmentGate
        case SM64EnvironmentGateObjectBridge.bowserSubDoorBehaviorIdentity,
             SM64EnvironmentGateObjectBridge.bowsersSubBehaviorIdentity,
             SM64EnvironmentGateObjectBridge.moatGrillsBehaviorIdentity,
             SM64EnvironmentGateObjectBridge.invisibleObjectsUnderBridgeBehaviorIdentity:
            return .environmentGate
        case SM64ClockArmObjectBridge.hourBehaviorIdentity,
             SM64ClockArmObjectBridge.minuteBehaviorIdentity:
            return .clockArm
        case SM64CastleFloorTrapObjectBridge.parentBehaviorIdentity,
             SM64CastleFloorTrapObjectBridge.childBehaviorIdentity:
            return .castleFloorTrap
        case SM64CastleFlagObjectBridge.defaultBehaviorIdentity:
            return .castleFlag
        case SM64BooCageObjectBridge.defaultBehaviorIdentity:
            return .booCage
        case SM64BooKeyObjectBridge.alphaBehaviorIdentity,
             SM64BooKeyObjectBridge.betaBehaviorIdentity:
            return .booKey
        case SM64BooInCastleObjectBridge.defaultBehaviorIdentity:
            return .booInCastle
        case SM64MerryGoRoundObjectBridge.defaultBehaviorIdentity:
            return .merryGoRound
        case SM64MusicTouchObjectBridge.defaultBehaviorIdentity:
            return .musicTouch
        case SM64TextSurfaceObjectBridge.messagePanelBehaviorIdentity,
             SM64TextSurfaceObjectBridge.signOnWallBehaviorIdentity:
            return .textSurface
        case SM64GrandStarObjectBridge.defaultBehaviorIdentity:
            return .grandStar
        case SM64BetaBowserAnchorObjectBridge.defaultBehaviorIdentity:
            return .betaBowserAnchor
        case SM64GroundParticleSpawnerObjectBridge.dirtBehaviorIdentity:
            return .dirtParticleSpawner
        case SM64GroundParticleSpawnerObjectBridge.snowBehaviorIdentity:
            return .snowParticleSpawner
        case SM64AnimatedTextureObjectBridge.defaultBehaviorIdentity:
            return .animatedTexture
        case SM64SparkleObjectBridge.defaultBehaviorIdentity:
            return .sparkle
        case SM64SparkleSpawnerObjectBridge.defaultBehaviorIdentity:
            return .sparkleSpawner
        case SM64AmbientSoundsObjectBridge.defaultBehaviorIdentity:
            return .ambientSounds
        case SM64CoinSparklesObjectBridge.defaultBehaviorIdentity:
            return .coinSparkles
        case SM64GoldenCoinSparklesObjectBridge.defaultBehaviorIdentity:
            return .goldenCoinSparkles
        case SM64PurpleParticleObjectBridge.defaultBehaviorIdentity:
            return .purpleParticle
        case SM64TinyStarParticleObjectBridge.wallBehaviorIdentity:
            return .wallTinyStarParticle
        case SM64TinyStarParticleObjectBridge.poundBehaviorIdentity:
            return .poundTinyStarParticle
        case SM64TinyStarParticleSpawnerObjectBridge.verticalBehaviorIdentity:
            return .vertStarParticleSpawner
        case SM64TinyStarParticleSpawnerObjectBridge.horizontalBehaviorIdentity:
            return .horStarParticleSpawner
        case SM64TriangleParticleObjectBridge.defaultBehaviorIdentity:
            return .triangleParticle
        case SM64TriangleParticleSpawnerObjectBridge.defaultBehaviorIdentity:
            return .triangleParticleSpawner
        case SM64TreeLeafObjectBridge.defaultBehaviorIdentity:
            return .treeLeaf
        case SM64TreeLeafObjectBridge.snowBehaviorIdentity:
            return .treeSnow
        case SM64TreeParticleSpawnerObjectBridge.defaultBehaviorIdentity:
            return .treeParticleSpawner
        case SM64MistCircParticleSpawnerObjectBridge.defaultBehaviorIdentity:
            return .mistCircParticleSpawner
        case SM64SparkleParticleSpawnerObjectBridge.defaultBehaviorIdentity:
            return .sparkleParticleSpawner
        case SM64SimpleAnimationObjectBridge.randomTextureBehaviorIdentity:
            return .randomAnimatedTexture
        case SM64SimpleAnimationObjectBridge.unusedSixFrameBehaviorIdentity:
            return .unusedSimpleAnimation
        case SM64UnusedFakeStarObjectBridge.defaultBehaviorIdentity:
            return .unusedFakeStar
        case SM64CloudPartObjectBridge.defaultBehaviorIdentity:
            return .cloudPart
        case SM64BreakBoxTriangleObjectBridge.defaultBehaviorIdentity:
            return .breakBoxTriangle
        case SM64CannonBaseUnusedObjectBridge.defaultBehaviorIdentity:
            return .cannonBaseUnused
        case SM64NoOpObjectBridge.unused05A8Identity,
             SM64NoOpObjectBridge.unused1820Identity,
             SM64NoOpObjectBridge.unused1F30Identity,
             SM64NoOpObjectBridge.unused2A10Identity,
             SM64NoOpObjectBridge.unused2A54Identity,
             SM64NoOpObjectBridge.instantActiveWarpIdentity,
             SM64NoOpObjectBridge.airborneWarpIdentity,
             SM64NoOpObjectBridge.hardAirKnockBackWarpIdentity,
             SM64NoOpObjectBridge.spinAirborneCircleWarpIdentity,
             SM64NoOpObjectBridge.deathWarpIdentity,
             SM64NoOpObjectBridge.spinAirborneWarpIdentity,
             SM64NoOpObjectBridge.flyingWarpIdentity,
             SM64NoOpObjectBridge.paintingStarCollectWarpIdentity,
             SM64NoOpObjectBridge.paintingDeathWarpIdentity,
             SM64NoOpObjectBridge.airborneDeathWarpIdentity,
             SM64NoOpObjectBridge.airborneStarCollectWarpIdentity,
             SM64NoOpObjectBridge.launchStarCollectWarpIdentity,
             SM64NoOpObjectBridge.launchDeathWarpIdentity,
             SM64NoOpObjectBridge.swimmingWarpIdentity,
             SM64NoOpObjectBridge.insideCannonIdentity,
             SM64NoOpObjectBridge.snowBallIdentity,
             SM64NoOpObjectBridge.cutOutObjectIdentity,
             SM64NoOpObjectBridge.rotatingCounterClockwiseIdentity,
             SM64NoOpObjectBridge.stubIdentity,
             SM64NoOpObjectBridge.stub1D0CIdentity,
             SM64NoOpObjectBridge.stub1D70Identity,
             SM64NoOpObjectBridge.unusedOneIdentity,
             SM64NoOpObjectBridge.staticObjectIdentity,
             SM64NoOpObjectBridge.yellowBallIdentity,
             SM64NoOpObjectBridge.carrySomething1Identity,
             SM64NoOpObjectBridge.carrySomething2Identity,
             SM64NoOpObjectBridge.carrySomething3Identity,
             SM64NoOpObjectBridge.carrySomething4Identity,
             SM64NoOpObjectBridge.carrySomething5Identity,
             SM64NoOpObjectBridge.carrySomething6Identity,
             SM64NoOpObjectBridge.iglooIdentity,
             SM64NoOpObjectBridge.bigSnowmanWholeIdentity,
             SM64NoOpObjectBridge.ukikiCageChildIdentity,
             SM64NoOpObjectBridge.sunkenShipPart2Identity,
             SM64NoOpObjectBridge.sunkenShipSetRotationIdentity,
             SM64NoOpObjectBridge.towerIdentity,
             SM64NoOpObjectBridge.bulletBillCannonIdentity,
             SM64NoOpObjectBridge.lllHexagonalMeshIdentity,
             SM64NoOpObjectBridge.hiddenStaircaseStepIdentity,
             SM64NoOpObjectBridge.pillarBaseIdentity,
             SM64NoOpObjectBridge.inSunkenShipIdentity,
             SM64NoOpObjectBridge.inSunkenShip2Identity,
             SM64NoOpObjectBridge.mantaRayRingManagerIdentity,
             SM64NoOpObjectBridge.betaFishSplashSpawnerIdentity:
            return .noOp
        case SM64CannonBarrelBubblesObjectBridge.defaultBehaviorIdentity:
            return .cannonBarrelBubbles
        case SM64CloudObjectBridge.defaultBehaviorIdentity:
            return .cloud
        default:
            return .unmigrated
        }
    }

    func reset() {
        eventLog.removeAll(keepingCapacity: true)
        sushiWaterLevels.removeAll(keepingCapacity: true)
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
        for id in bomp.registeredIDs { bomp.remove(id) }
        for id in thwomp.registeredIDs { thwomp.remove(id) }
        for id in boulder.registeredIDs { boulder.remove(id) }
        for id in horizontalGrindel.registeredIDs { horizontalGrindel.remove(id) }
        for id in unusedParticleSpawn.registeredIDs { unusedParticleSpawn.remove(id) }
        for id in snowmanCheckpoint.registeredIDs { snowmanCheckpoint.remove(id) }
    for id in bowserBodyAnchor.registeredIDs { bowserBodyAnchor.remove(id) }
    for id in bowserTailAnchor.registeredIDs { bowserTailAnchor.remove(id) }
    for id in snowmanHead.registeredIDs { snowmanHead.remove(id) }
    for id in madPiano.registeredIDs { madPiano.remove(id) }
        for id in betaChest.registeredIDs { betaChest.remove(id) }
        for id in betaTrampoline.registeredIDs { betaTrampoline.remove(id) }
        for id in betaHoldable.registeredIDs { betaHoldable.remove(id) }
        for id in seaweed.registeredIDs { seaweed.remove(id) }
        for id in shipPart3.registeredIDs { shipPart3.remove(id) }
        for id in sunkenShipPart.registeredIDs { sunkenShipPart.remove(id) }
        for id in jrbSlidingBox.registeredIDs { jrbSlidingBox.remove(id) }
        for id in fallingPillar.registeredIDs { fallingPillar.remove(id) }
        for id in coffin.registeredIDs { coffin.remove(id) }
        for id in blueFish.registeredIDs { blueFish.remove(id) }
        for id in clamShell.registeredIDs { clamShell.remove(id) }
        for id in bobombAnchorMario.registeredIDs { bobombAnchorMario.remove(id) }
        for id in bub.registeredIDs { bub.remove(id) }
        for id in bubba.registeredIDs { bubba.remove(id) }
        for id in bowlingBall.registeredIDs { bowlingBall.remove(id) }
        for id in dddPole.registeredIDs { dddPole.remove(id) }
        for id in donutPlatform.registeredIDs { donutPlatform.remove(id) }
        for id in courtyardBooTriplet.registeredIDs { courtyardBooTriplet.remove(id) }
        for id in fallingBowserPlatform.registeredIDs { fallingBowserPlatform.remove(id) }
        for id in giantPole.registeredIDs { giantPole.remove(id) }
        for id in endCutsceneActor.registeredIDs { endCutsceneActor.remove(id) }
        for id in endBirds.registeredIDs { endBirds.remove(id) }
        for id in beginningPeach.registeredIDs { beginningPeach.remove(id) }
        for id in butterfly.registeredIDs { butterfly.remove(id) }
        for id in tiltingPyramid.registeredIDs { tiltingPyramid.remove(id) }
        for id in bookend.registeredIDs { bookend.remove(id) }
        for id in bookSwitch.registeredIDs { bookSwitch.remove(id) }
        for id in hauntedBookshelf.registeredIDs { hauntedBookshelf.remove(id) }
        for id in hauntedBookshelfManager.registeredIDs { hauntedBookshelfManager.remove(id) }
        for id in hauntedChair.registeredIDs { hauntedChair.remove(id) }
        for id in fish.registeredIDs { fish.remove(id) }
        for id in cannonBarrel.registeredIDs { cannonBarrel.remove(id) }
        for id in cannon.registeredIDs { cannon.remove(id) }
        for id in merryGoRoundBooManager.registeredIDs { merryGoRoundBooManager.remove(id) }
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
        for id in arrowLift.registeredIDs { arrowLift.remove(id) }
        for id in elevator.registeredIDs { elevator.remove(id) }
        for id in seesawPlatform.registeredIDs { seesawPlatform.remove(id) }
        for id in swingPlatform.registeredIDs { swingPlatform.remove(id) }
        for id in rotatingPlatform.registeredIDs { rotatingPlatform.remove(id) }
        for id in ttcMovingBar.registeredIDs { ttcMovingBar.remove(id) }
        for id in ttcSpinner.registeredIDs { ttcSpinner.remove(id) }
        for id in ttcTreadmill.registeredIDs { ttcTreadmill.remove(id) }
        for id in ttcPendulum.registeredIDs { ttcPendulum.remove(id) }
        for id in ttcElevator.registeredIDs { ttcElevator.remove(id) }
        for id in ttcRotatingSolid.registeredIDs { ttcRotatingSolid.remove(id) }
        for id in ttc2DRotator.registeredIDs { ttc2DRotator.remove(id) }
        for id in ttcCog.registeredIDs { ttcCog.remove(id) }
        for id in pyramidElevator.registeredIDs { pyramidElevator.remove(id) }
        for id in pyramidTopFragment.registeredIDs { pyramidTopFragment.remove(id) }
        for id in pyramidPillarTouchDetector.registeredIDs { pyramidPillarTouchDetector.remove(id) }
        for id in pyramidTop.registeredIDs { pyramidTop.remove(id) }
        for id in ttcPitBlock.registeredIDs { ttcPitBlock.remove(id) }
        for id in staticCheckeredPlatform.registeredIDs { staticCheckeredPlatform.remove(id) }
        for id in bbhTiltingTrapPlatform.registeredIDs { bbhTiltingTrapPlatform.remove(id) }
        for id in lllSinkingPlatform.registeredIDs { lllSinkingPlatform.remove(id) }
        for id in wfRotatingWoodenPlatform.registeredIDs { wfRotatingWoodenPlatform.remove(id) }
        for id in rotatingOctagonalPlatform.registeredIDs { rotatingOctagonalPlatform.remove(id) }
        for id in wfSolidTowerPlatform.registeredIDs { wfSolidTowerPlatform.remove(id) }
        for id in wfTowerPlatform.registeredIDs { wfTowerPlatform.remove(id) }
        for id in trackBall.registeredIDs { trackBall.remove(id) }
        for id in wfSlidingPlatform.registeredIDs { wfSlidingPlatform.remove(id) }
        for id in wdwExpressElevator.registeredIDs { wdwExpressElevator.remove(id) }
        for id in lllSinkingRockBlock.registeredIDs { lllSinkingRockBlock.remove(id) }
        for id in volcanoFallingTrap.registeredIDs { volcanoFallingTrap.remove(id) }
        for id in rollingLog.registeredIDs { rollingLog.remove(id) }
        for id in lllMovingOctagonalMesh.registeredIDs { lllMovingOctagonalMesh.remove(id) }
        for id in ferrisWheel.registeredIDs { ferrisWheel.remove(id) }
        for id in checkerboardPlatform.registeredIDs { checkerboardPlatform.remove(id) }
        for id in wfTowerPlatformGroup.registeredIDs { wfTowerPlatformGroup.remove(id) }
        for id in lllRotatingHexagonalPlatform.registeredIDs { lllRotatingHexagonalPlatform.remove(id) }
        for id in lllRotatingHexFlame.registeredIDs { lllRotatingHexFlame.remove(id) }
        for id in lllRotatingFireBar.registeredIDs { lllRotatingFireBar.remove(id) }
        for id in activatedBackAndForthPlatform.registeredIDs { activatedBackAndForthPlatform.remove(id) }
        for id in bitfsSinkingPlatform.registeredIDs { bitfsSinkingPlatform.remove(id) }
        for id in dddMovingPole.registeredIDs { dddMovingPole.remove(id) }
        for id in lllRotatingHexagonalRing.registeredIDs { lllRotatingHexagonalRing.remove(id) }
        for id in lllWoodPiece.registeredIDs { lllWoodPiece.remove(id) }
        for id in lllFloatingWoodBridge.registeredIDs { lllFloatingWoodBridge.remove(id) }
        for id in squishablePlatform.registeredIDs { squishablePlatform.remove(id) }
        for id in lllDrawbridge.registeredIDs { lllDrawbridge.remove(id) }
        for id in idleWaterWave.registeredIDs { idleWaterWave.remove(id) }
        for id in waterfallSoundLoop.registeredIDs { waterfallSoundLoop.remove(id) }
        for id in volcanoSoundLoop.registeredIDs { volcanoSoundLoop.remove(id) }
        for id in tumblingBridge.registeredIDs { tumblingBridge.remove(id) }
        for id in floatingPlatform.registeredIDs { floatingPlatform.remove(id) }
        for id in jrbFloatingBox.registeredIDs { jrbFloatingBox.remove(id) }
        for id in slidingPlatform2.registeredIDs { slidingPlatform2.remove(id) }
        for id in smallWaterWave.registeredIDs { smallWaterWave.remove(id) }
        for id in ambientSoundLoop.registeredIDs { ambientSoundLoop.remove(id) }
        for id in rotatingExclamationMark.registeredIDs { rotatingExclamationMark.remove(id) }
        for id in waterAirBubble.registeredIDs { waterAirBubble.remove(id) }
        for id in objectBubble.registeredIDs { objectBubble.remove(id) }
        for id in waterDroplet.registeredIDs { waterDroplet.remove(id) }
        for id in waterMist.registeredIDs { waterMist.remove(id) }
        for id in waterMist2.registeredIDs { waterMist2.remove(id) }
        for id in waterSplash.registeredIDs { waterSplash.remove(id) }
        for id in bubbleMaybe.registeredIDs { bubbleMaybe.remove(id) }
        for id in wind.registeredIDs { wind.remove(id) }
        for id in jetStream.registeredIDs { jetStream.remove(id) }
        for id in jetStreamWaterRing.registeredIDs { jetStreamWaterRing.remove(id) }
        for id in jetStreamRingSpawner.registeredIDs { jetStreamRingSpawner.remove(id) }
        for id in mantaRayWaterRing.registeredIDs { mantaRayWaterRing.remove(id) }
        for id in whirlpool.registeredIDs { whirlpool.remove(id) }
        for id in mantaRay.registeredIDs { mantaRay.remove(id) }
        for id in shallowWaterWave.registeredIDs { shallowWaterWave.remove(id) }
        for id in waterSplashSpawner.registeredIDs { waterSplashSpawner.remove(id) }
        for id in bubbleParticleSpawner.registeredIDs { bubbleParticleSpawner.remove(id) }
        for id in piranhaPlantWakingBubble.registeredIDs { piranhaPlantWakingBubble.remove(id) }
        for id in piranhaPlantBubble.registeredIDs { piranhaPlantBubble.remove(id) }
        for id in waveTrail.registeredIDs { waveTrail.remove(id) }
        for id in sushiShark.registeredIDs { sushiShark.remove(id) }
        for id in ukiki.registeredIDs { ukiki.remove(id) }
        for id in ukikiCage.registeredIDs { ukikiCage.remove(id) }
        for id in mips.registeredIDs { mips.remove(id) }
        for id in toadMessage.registeredIDs { toadMessage.remove(id) }
        for id in menuButton.registeredIDs { menuButton.remove(id) }
        for id in squarishPathMoving.registeredIDs { squarishPathMoving.remove(id) }
        for id in pushableMetalBox.registeredIDs { pushableMetalBox.remove(id) }
        for id in tiltingBowserLavaPlatform.registeredIDs { tiltingBowserLavaPlatform.remove(id) }
        for id in lllBowserPuzzle.registeredIDs { lllBowserPuzzle.remove(id) }
        for id in strongWindParticle.registeredIDs { strongWindParticle.remove(id) }
        for id in waterParticle.registeredIDs { waterParticle.remove(id) }
        for id in plungeBubble.registeredIDs { plungeBubble.remove(id) }
        for id in breathParticleSpawner.registeredIDs { breathParticleSpawner.remove(id) }
        for id in mistParticle.registeredIDs { mistParticle.remove(id) }
        for id in mistParticleSpawner.registeredIDs { mistParticleSpawner.remove(id) }
        for id in tweesterSandParticle.registeredIDs { tweesterSandParticle.remove(id) }
        for id in blackSmokeMario.registeredIDs { blackSmokeMario.remove(id) }
        for id in flameMario.registeredIDs { flameMario.remove(id) }
        for id in blackSmokeBowser.registeredIDs { blackSmokeBowser.remove(id) }
        for id in blackSmokeUpward.registeredIDs { blackSmokeUpward.remove(id) }
        for id in whitePuffSmoke.registeredIDs { whitePuffSmoke.remove(id) }
        for id in whitePuffSmoke2.registeredIDs { whitePuffSmoke2.remove(id) }
        for id in whitePuffExplosion.registeredIDs { whitePuffExplosion.remove(id) }
        for id in dustSmoke.registeredIDs { dustSmoke.remove(id) }
        for id in starKeyPuffSpawner.registeredIDs { starKeyPuffSpawner.remove(id) }
        for id in staticFlame.registeredIDs { staticFlame.remove(id) }
        for id in flamethrowerFlame.registeredIDs { flamethrowerFlame.remove(id) }
        for id in flameBouncing.registeredIDs { flameBouncing.remove(id) }
        for id in bowserFlame.registeredIDs { bowserFlame.remove(id) }
        for id in blueFlamesGroup.registeredIDs { blueFlamesGroup.remove(id) }
        for id in flameFloatingLanding.registeredIDs { flameFloatingLanding.remove(id) }
        for id in blueBowserFlame.registeredIDs { blueBowserFlame.remove(id) }
        for id in volcanoFlames.registeredIDs { volcanoFlames.remove(id) }
        for id in koopaShellFlame.registeredIDs { koopaShellFlame.remove(id) }
        for id in flameMovingForwardGrowing.registeredIDs { flameMovingForwardGrowing.remove(id) }
        for id in betaMovingFlames.registeredIDs { betaMovingFlames.remove(id) }
        for id in bowserFlameSpawn.registeredIDs { bowserFlameSpawn.remove(id) }
        for id in smallPiranhaFlame.registeredIDs { smallPiranhaFlame.remove(id) }
        for id in fireSpitter.registeredIDs { fireSpitter.remove(id) }
        for id in firePiranhaPlant.registeredIDs { firePiranhaPlant.remove(id) }
        for id in flamethrower.registeredIDs { flamethrower.remove(id) }
        for id in celebrationStarSparkle.registeredIDs { celebrationStarSparkle.remove(id) }
        for id in celebrationStar.registeredIDs { celebrationStar.remove(id) }
        for id in warp.registeredIDs { warp.remove(id) }
        for id in dddWarp.registeredIDs { dddWarp.remove(id) }
        for id in actSelector.registeredIDs { actSelector.remove(id) }
        for id in actSelectorStarType.registeredIDs { actSelectorStarType.remove(id) }
        for id in collectStar.registeredIDs { collectStar.remove(id) }
        for id in starSpawnCoordinates.registeredIDs { starSpawnCoordinates.remove(id) }
        for id in spawnedStar.registeredIDs { spawnedStar.remove(id) }
        for id in unlockDoorStar.registeredIDs { unlockDoorStar.remove(id) }
        for id in ccmTouchedStarSpawn.registeredIDs { ccmTouchedStarSpawn.remove(id) }
        for id in hiddenStar.registeredIDs { hiddenStar.remove(id) }
        for id in castleCannonGrate.registeredIDs { castleCannonGrate.remove(id) }
        for id in blueCoin.registeredIDs { blueCoin.remove(id) }
        for id in redCoin.registeredIDs { redCoin.remove(id) }
        for id in starDoor.registeredIDs { starDoor.remove(id) }
        for id in capSwitch.registeredIDs { capSwitch.remove(id) }
        for id in metalCap.registeredIDs { metalCap.remove(id) }
        for id in vanishCap.registeredIDs { vanishCap.remove(id) }
        for id in wingCap.registeredIDs { wingCap.remove(id) }
        for id in normalCap.registeredIDs { normalCap.remove(id) }
        for id in towerDoor.registeredIDs { towerDoor.remove(id) }
        for id in openableGrill.registeredIDs { openableGrill.remove(id) }
        for id in door.registeredIDs { door.remove(id) }
        for id in hiddenObject.registeredIDs { hiddenObject.remove(id) }
        for id in recoveryHeart.registeredIDs { recoveryHeart.remove(id) }
        for id in coin.registeredIDs { coin.remove(id) }
        for id in movingCoin.registeredIDs { movingCoin.remove(id) }
        for id in waterLevel.registeredIDs { waterLevel.remove(id) }
        for id in waterPillar.registeredIDs { waterPillar.remove(id) }
        for id in floorSwitch.registeredIDs { floorSwitch.remove(id) }
        for id in animatedFloorSwitch.registeredIDs { animatedFloorSwitch.remove(id) }
        for id in hiddenOneUp.registeredIDs { hiddenOneUp.remove(id) }
        for id in breakableBox.registeredIDs { breakableBox.remove(id) }
        for id in jumpingBox.registeredIDs { jumpingBox.remove(id) }
        for id in kickableBoard.registeredIDs { kickableBoard.remove(id) }
        for id in koopaFlag.registeredIDs { koopaFlag.remove(id) }
        for id in koopaRaceEndpoint.registeredIDs { koopaRaceEndpoint.remove(id) }
        for id in wfBreakableWall.registeredIDs { wfBreakableWall.remove(id) }
        for id in unusedPoundablePlatform.registeredIDs { unusedPoundablePlatform.remove(id) }
        for id in yellowBackgroundMenu.registeredIDs { yellowBackgroundMenu.remove(id) }
        for id in snowMound.registeredIDs { snowMound.remove(id) }
        for id in rrCruiserWing.registeredIDs { rrCruiserWing.remove(id) }
        for id in spindrift.registeredIDs { spindrift.remove(id) }
        for id in spindel.registeredIDs { spindel.remove(id) }
        for id in rrRotatingBridgePlatform.registeredIDs { rrRotatingBridgePlatform.remove(id) }
        for id in snowmanWind.registeredIDs { snowmanWind.remove(id) }
        for id in mrBlizzardSnowball.registeredIDs { mrBlizzardSnowball.remove(id) }
        for id in exclamationBox.registeredIDs { exclamationBox.remove(id) }
        for id in orangeNumber.registeredIDs { orangeNumber.remove(id) }
        for id in soundSpawner.registeredIDs { soundSpawner.remove(id) }
        for id in rockSolid.registeredIDs { rockSolid.remove(id) }
        for id in toxBox.registeredIDs { toxBox.remove(id) }
        for id in sslMovingPyramidWall.registeredIDs { sslMovingPyramidWall.remove(id) }
        for id in thiIslandTop.registeredIDs { thiIslandTop.remove(id) }
        for id in environmentGate.registeredIDs { environmentGate.remove(id) }
        for id in clockArm.registeredIDs { clockArm.remove(id) }
        for id in castleFloorTrap.registeredIDs { castleFloorTrap.remove(id) }
        for id in castleFlag.registeredIDs { castleFlag.remove(id) }
        for id in booCage.registeredIDs { booCage.remove(id) }
        for id in booKey.registeredIDs { booKey.remove(id) }
        for id in booInCastle.registeredIDs { booInCastle.remove(id) }
        for id in merryGoRound.registeredIDs { merryGoRound.remove(id) }
        for id in musicTouch.registeredIDs { musicTouch.remove(id) }
        for id in textSurface.registeredIDs { textSurface.remove(id) }
        for id in grandStar.registeredIDs { grandStar.remove(id) }
        for id in betaBowserAnchor.registeredIDs { betaBowserAnchor.remove(id) }
        for id in groundParticleSpawner.registeredIDs { groundParticleSpawner.remove(id) }
        for id in animatedTexture.registeredIDs { animatedTexture.remove(id) }
        for id in sparkle.registeredIDs { sparkle.remove(id) }
        for id in sparkleSpawner.registeredIDs { sparkleSpawner.remove(id) }
        for id in ambientSounds.registeredIDs { ambientSounds.remove(id) }
        for id in coinSparkles.registeredIDs { coinSparkles.remove(id) }
        for id in goldenCoinSparkles.registeredIDs { goldenCoinSparkles.remove(id) }
        for id in purpleParticle.registeredIDs { purpleParticle.remove(id) }
        for id in tinyStarParticle.registeredIDs { tinyStarParticle.remove(id) }
        for id in tinyStarParticleSpawner.registeredIDs { tinyStarParticleSpawner.remove(id) }
        for id in triangleParticle.registeredIDs { triangleParticle.remove(id) }
        for id in triangleParticleSpawner.registeredIDs { triangleParticleSpawner.remove(id) }
        for id in treeLeaf.registeredIDs { treeLeaf.remove(id) }
        for id in treeParticleSpawner.registeredIDs { treeParticleSpawner.remove(id) }
        for id in mistCircParticleSpawner.registeredIDs { mistCircParticleSpawner.remove(id) }
        for id in sparkleParticleSpawner.registeredIDs { sparkleParticleSpawner.remove(id) }
        for id in simpleAnimation.registeredIDs { simpleAnimation.remove(id) }
        for id in unusedFakeStar.registeredIDs { unusedFakeStar.remove(id) }
        for id in cloudPart.registeredIDs { cloudPart.remove(id) }
        for id in breakBoxTriangle.registeredIDs { breakBoxTriangle.remove(id) }
        for id in cannonBaseUnused.registeredIDs { cannonBaseUnused.remove(id) }
        for id in noOp.registeredIDs { noOp.remove(id) }
        for id in cannonBarrelBubbles.registeredIDs { cannonBarrelBubbles.remove(id) }
        for id in cloud.registeredIDs { cloud.remove(id) }
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
        bomp.beginExternalTick()
        thwomp.beginExternalTick()
        boulder.beginExternalTick()
        horizontalGrindel.beginExternalTick()
        unusedParticleSpawn.beginExternalTick()
        snowmanCheckpoint.beginExternalTick()
        bowserBodyAnchor.beginExternalTick()
        bowserTailAnchor.beginExternalTick()
        snowmanHead.beginExternalTick()
        madPiano.beginExternalTick()
        betaChest.beginExternalTick()
        betaTrampoline.beginExternalTick()
        betaHoldable.beginExternalTick()
        seaweed.beginExternalTick()
        shipPart3.beginExternalTick()
        sunkenShipPart.beginExternalTick()
        jrbSlidingBox.beginExternalTick()
        fallingPillar.beginExternalTick()
        coffin.beginExternalTick()
        blueFish.beginExternalTick()
        clamShell.beginExternalTick()
        bobombAnchorMario.beginExternalTick()
        bub.beginExternalTick()
        bubba.beginExternalTick()
        bowlingBall.beginExternalTick()
        dddPole.beginExternalTick()
        donutPlatform.beginExternalTick()
        courtyardBooTriplet.beginExternalTick()
        fallingBowserPlatform.beginExternalTick()
        giantPole.beginExternalTick()
        koopaFlag.beginExternalTick()
        koopaRaceEndpoint.beginExternalTick()
        wfBreakableWall.beginExternalTick()
        unusedPoundablePlatform.beginExternalTick()
        yellowBackgroundMenu.beginExternalTick()
        snowMound.beginExternalTick()
        rrCruiserWing.beginExternalTick()
        spindrift.beginExternalTick()
        spindel.beginExternalTick()
        rrRotatingBridgePlatform.beginExternalTick()
        snowmanWind.beginExternalTick()
        mrBlizzardSnowball.beginExternalTick()
        endCutsceneActor.beginExternalTick()
        endBirds.beginExternalTick()
        beginningPeach.beginExternalTick()
        butterfly.beginExternalTick()
        tiltingPyramid.beginExternalTick()
        bookend.beginExternalTick()
        bookSwitch.beginExternalTick()
        hauntedBookshelf.beginExternalTick()
        hauntedBookshelfManager.beginExternalTick()
        hauntedChair.beginExternalTick()
        fish.beginExternalTick()
        cannonBarrel.beginExternalTick()
        cannon.beginExternalTick()
        merryGoRoundBooManager.beginExternalTick()
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
        arrowLift.beginExternalTick()
        elevator.beginExternalTick()
        seesawPlatform.beginExternalTick()
        swingPlatform.beginExternalTick()
        rotatingPlatform.beginExternalTick()
        ttcMovingBar.beginExternalTick()
        ttcSpinner.beginExternalTick()
        ttcTreadmill.beginExternalTick()
        ttcPendulum.beginExternalTick()
        ttcElevator.beginExternalTick()
        ttcRotatingSolid.beginExternalTick()
        ttc2DRotator.beginExternalTick()
        ttcCog.beginExternalTick()
        pyramidElevator.beginExternalTick()
        pyramidTopFragment.beginExternalTick()
        pyramidPillarTouchDetector.beginExternalTick()
        pyramidTop.beginExternalTick()
        ttcPitBlock.beginExternalTick()
        staticCheckeredPlatform.beginExternalTick()
        bbhTiltingTrapPlatform.beginExternalTick()
        lllSinkingPlatform.beginExternalTick()
        wfRotatingWoodenPlatform.beginExternalTick()
        rotatingOctagonalPlatform.beginExternalTick()
        wfSolidTowerPlatform.beginExternalTick()
        wfTowerPlatform.beginExternalTick()
        trackBall.beginExternalTick()
        wfSlidingPlatform.beginExternalTick()
        wdwExpressElevator.beginExternalTick()
        lllSinkingRockBlock.beginExternalTick()
        volcanoFallingTrap.beginExternalTick()
        rollingLog.beginExternalTick()
        lllMovingOctagonalMesh.beginExternalTick()
        ferrisWheel.beginExternalTick()
        checkerboardPlatform.beginExternalTick()
        wfTowerPlatformGroup.beginExternalTick()
        lllRotatingHexagonalPlatform.beginExternalTick()
        lllRotatingHexFlame.beginExternalTick()
        lllRotatingFireBar.beginExternalTick()
        activatedBackAndForthPlatform.beginExternalTick()
        bitfsSinkingPlatform.beginExternalTick()
        dddMovingPole.beginExternalTick()
        lllRotatingHexagonalRing.beginExternalTick()
        lllWoodPiece.beginExternalTick()
        lllFloatingWoodBridge.beginExternalTick()
        squishablePlatform.beginExternalTick()
        lllDrawbridge.beginExternalTick()
        idleWaterWave.beginExternalTick()
        waterfallSoundLoop.beginExternalTick()
        volcanoSoundLoop.beginExternalTick()
        tumblingBridge.beginExternalTick()
        floatingPlatform.beginExternalTick()
        jrbFloatingBox.beginExternalTick()
        slidingPlatform2.beginExternalTick()
        smallWaterWave.beginExternalTick()
        ambientSoundLoop.beginExternalTick()
        rotatingExclamationMark.beginExternalTick()
        waterAirBubble.beginExternalTick()
        objectBubble.beginExternalTick()
        waterDroplet.beginExternalTick()
        waterMist.beginExternalTick()
        waterMist2.beginExternalTick()
        waterSplash.beginExternalTick()
        bubbleMaybe.beginExternalTick()
        wind.beginExternalTick()
        jetStream.beginExternalTick()
        jetStreamWaterRing.beginExternalTick()
        jetStreamRingSpawner.beginExternalTick()
        mantaRayWaterRing.beginExternalTick()
        whirlpool.beginExternalTick()
        mantaRay.beginExternalTick()
        shallowWaterWave.beginExternalTick()
        waterSplashSpawner.beginExternalTick()
        bubbleParticleSpawner.beginExternalTick()
        piranhaPlantWakingBubble.beginExternalTick()
        piranhaPlantBubble.beginExternalTick()
        waveTrail.beginExternalTick()
        sushiShark.beginExternalTick()
        ukiki.beginExternalTick()
        ukikiCage.beginExternalTick()
        mips.beginExternalTick()
        toadMessage.beginExternalTick()
        menuButton.beginExternalTick()
        squarishPathMoving.beginExternalTick()
        pushableMetalBox.beginExternalTick()
        tiltingBowserLavaPlatform.beginExternalTick()
        lllBowserPuzzle.beginExternalTick()
        strongWindParticle.beginExternalTick()
        waterParticle.beginExternalTick()
        plungeBubble.beginExternalTick()
        breathParticleSpawner.beginExternalTick()
        mistParticle.beginExternalTick()
        mistParticleSpawner.beginExternalTick()
        tweesterSandParticle.beginExternalTick()
        blackSmokeMario.beginExternalTick()
        flameMario.beginExternalTick()
        blackSmokeBowser.beginExternalTick()
        blackSmokeUpward.beginExternalTick()
        whitePuffSmoke.beginExternalTick()
        whitePuffSmoke2.beginExternalTick()
        whitePuffExplosion.beginExternalTick()
        dustSmoke.beginExternalTick()
        starKeyPuffSpawner.beginExternalTick()
        staticFlame.beginExternalTick()
        flamethrowerFlame.beginExternalTick()
        flameBouncing.beginExternalTick()
        bowserFlame.beginExternalTick()
        blueFlamesGroup.beginExternalTick()
        flameFloatingLanding.beginExternalTick()
        blueBowserFlame.beginExternalTick()
        volcanoFlames.beginExternalTick()
        koopaShellFlame.beginExternalTick()
        flameMovingForwardGrowing.beginExternalTick()
        betaMovingFlames.beginExternalTick()
        bowserFlameSpawn.beginExternalTick()
        smallPiranhaFlame.beginExternalTick()
        fireSpitter.beginExternalTick()
        firePiranhaPlant.beginExternalTick()
        flamethrower.beginExternalTick()
        celebrationStarSparkle.beginExternalTick()
        celebrationStar.beginExternalTick()
        warp.beginExternalTick()
        dddWarp.beginExternalTick()
        groundParticleSpawner.beginExternalTick()
        actSelector.beginExternalTick()
        actSelectorStarType.beginExternalTick()
        collectStar.beginExternalTick()
        starSpawnCoordinates.beginExternalTick()
        spawnedStar.beginExternalTick()
        unlockDoorStar.beginExternalTick()
        ccmTouchedStarSpawn.beginExternalTick()
        hiddenStar.beginExternalTick()
        castleCannonGrate.beginExternalTick()
        blueCoin.beginExternalTick()
        redCoin.beginExternalTick()
        starDoor.beginExternalTick()
        capSwitch.beginExternalTick()
        metalCap.beginExternalTick()
        vanishCap.beginExternalTick()
        wingCap.beginExternalTick()
        normalCap.beginExternalTick()
        towerDoor.beginExternalTick()
        openableGrill.beginExternalTick()
        door.beginExternalTick()
        hiddenObject.beginExternalTick()
        recoveryHeart.beginExternalTick()
        coin.beginExternalTick()
        movingCoin.beginExternalTick()
        waterLevel.beginExternalTick()
        waterPillar.beginExternalTick()
        floorSwitch.beginExternalTick()
        animatedFloorSwitch.beginExternalTick()
        hiddenOneUp.beginExternalTick()
        breakableBox.beginExternalTick()
        jumpingBox.beginExternalTick()
        kickableBoard.beginExternalTick()
        exclamationBox.beginExternalTick()
        orangeNumber.beginExternalTick()
        soundSpawner.beginExternalTick()
        rockSolid.beginExternalTick()
        toxBox.beginExternalTick()
        sslMovingPyramidWall.beginExternalTick()
        thiIslandTop.beginExternalTick()
        environmentGate.beginExternalTick()
        clockArm.beginExternalTick()
        castleFloorTrap.beginExternalTick()
        castleFlag.beginExternalTick()
        booCage.beginExternalTick()
        booKey.beginExternalTick()
        booInCastle.beginExternalTick()
        merryGoRound.beginExternalTick()
        musicTouch.beginExternalTick()
        textSurface.beginExternalTick()
        grandStar.beginExternalTick()
        betaBowserAnchor.beginExternalTick()
        animatedTexture.beginExternalTick()
        sparkle.beginExternalTick()
        sparkleSpawner.beginExternalTick()
        ambientSounds.beginExternalTick()
        coinSparkles.beginExternalTick()
        goldenCoinSparkles.beginExternalTick()
        purpleParticle.beginExternalTick()
        tinyStarParticle.beginExternalTick()
        tinyStarParticleSpawner.beginExternalTick()
        triangleParticle.beginExternalTick()
        triangleParticleSpawner.beginExternalTick()
        treeLeaf.beginExternalTick()
        treeParticleSpawner.beginExternalTick()
        mistCircParticleSpawner.beginExternalTick()
        sparkleParticleSpawner.beginExternalTick()
        simpleAnimation.beginExternalTick()
        unusedFakeStar.beginExternalTick()
        cloudPart.beginExternalTick()
        breakBoxTriangle.beginExternalTick()
        cannonBaseUnused.beginExternalTick()
        noOp.beginExternalTick()
        cannonBarrelBubbles.beginExternalTick()
        cloud.beginExternalTick()
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
    func spawnArrowLift(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        faceYaw: Int16 = 0
    ) throws -> SM64ObjectID {
        try arrowLift.spawnArrowLift(
            in: engineState,
            position: position,
            faceYaw: faceYaw
        )
    }

    @discardableResult
    func spawnElevator(
        in engineState: SM64SwiftEngineState,
        behaviorIdentity: UInt64,
        positionY: Float = 0,
        bottomY: Float? = nil,
        topY: Float? = nil,
        midpointY: Float? = nil,
        faceYaw: Int16 = 0
    ) throws -> SM64ObjectID {
        try elevator.spawnElevator(
            in: engineState,
            behaviorIdentity: behaviorIdentity,
            positionY: positionY,
            bottomY: bottomY,
            topY: topY,
            midpointY: midpointY,
            faceYaw: faceYaw
        )
    }

    @discardableResult
    func spawnSeesawPlatform(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        faceYaw: Int16 = 0,
        behaviorByte: UInt8 = 0
    ) throws -> SM64ObjectID {
        try seesawPlatform.spawnSeesawPlatform(
            in: engineState,
            position: position,
            faceYaw: faceYaw,
            behaviorByte: behaviorByte
        )
    }

    @discardableResult
    func spawnSwingPlatform(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        faceRoll: Int32 = 0
    ) throws -> SM64ObjectID {
        try swingPlatform.spawnSwingPlatform(
            in: engineState,
            position: position,
            faceRoll: faceRoll
        )
    }

    @discardableResult
    func spawnRotatingPlatform(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        faceYaw: Int16 = 0,
        speedByte: Int8 = 0,
        action: Int32 = 0
    ) throws -> SM64ObjectID {
        try rotatingPlatform.spawnRotatingPlatform(
            in: engineState,
            position: position,
            faceYaw: faceYaw,
            speedByte: speedByte,
            action: action
        )
    }

    @discardableResult
    func spawnTTCMovingBar(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        faceYaw: Int16 = 0,
        speedSetting: Int32 = 0,
        behaviorByte: Int32 = 0
    ) throws -> SM64ObjectID {
        try ttcMovingBar.spawnMovingBar(
            in: engineState,
            position: position,
            faceYaw: faceYaw,
            speedSetting: speedSetting,
            behaviorByte: behaviorByte
        )
    }

    @discardableResult
    func spawnTTCSpinner(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        facePitch: Int16 = 0,
        speedSetting: Int32 = 0
    ) throws -> SM64ObjectID {
        try ttcSpinner.spawnSpinner(
            in: engineState,
            position: position,
            facePitch: facePitch,
            speedSetting: speedSetting
        )
    }

    @discardableResult
    func spawnTTCTreadmill(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        faceYaw: Int16 = 0,
        speedSetting: Int32 = 0,
        behaviorByte: UInt8 = 0
    ) throws -> SM64ObjectID {
        try ttcTreadmill.spawnTreadmill(
            in: engineState,
            position: position,
            faceYaw: faceYaw,
            speedSetting: speedSetting,
            behaviorByte: behaviorByte
        )
    }

    @discardableResult
    func spawnTTCPendulum(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        speedSetting: Int32 = 0
    ) throws -> SM64ObjectID {
        try ttcPendulum.spawnPendulum(
            in: engineState,
            position: position,
            speedSetting: speedSetting
        )
    }

    @discardableResult
    func spawnTTCElevator(
        in engineState: SM64SwiftEngineState,
        positionY: Float = 0,
        behaviorParameterHigh: UInt16 = 0,
        speedSetting: Int32 = 0,
        direction: Int32 = 1
    ) throws -> SM64ObjectID {
        try ttcElevator.spawnElevator(
            in: engineState,
            positionY: positionY,
            behaviorParameterHigh: behaviorParameterHigh,
            speedSetting: speedSetting,
            direction: direction
        )
    }

    @discardableResult
    func spawnTTCRotatingSolid(
        in engineState: SM64SwiftEngineState,
        positionY: Float = 0,
        behaviorByte: UInt8 = 0,
        speedSetting: Int32 = 0
    ) throws -> SM64ObjectID {
        try ttcRotatingSolid.spawnRotatingSolid(
            in: engineState,
            positionY: positionY,
            behaviorByte: behaviorByte,
            speedSetting: speedSetting
        )
    }

    @discardableResult
    func spawnTTC2DRotator(
        in engineState: SM64SwiftEngineState,
        faceYaw: Int16 = 0,
        behaviorByte: Int32 = 0,
        speedSetting: Int32 = 0
    ) throws -> SM64ObjectID {
        try ttc2DRotator.spawnRotator(
            in: engineState,
            faceYaw: faceYaw,
            behaviorByte: behaviorByte,
            speedSetting: speedSetting
        )
    }

    @discardableResult
    func spawnTTCCog(
        in engineState: SM64SwiftEngineState,
        faceYaw: Int16 = 0,
        behaviorByte: UInt8 = 0,
        speedSetting: Int32 = 0
    ) throws -> SM64ObjectID {
        try ttcCog.spawnCog(
            in: engineState,
            faceYaw: faceYaw,
            behaviorByte: behaviorByte,
            speedSetting: speedSetting
        )
    }

    @discardableResult
    func spawnPyramidElevator(
        in engineState: SM64SwiftEngineState,
        positionY: Float = 4600
    ) throws -> SM64ObjectID {
        try pyramidElevator.spawnElevator(in: engineState, positionY: positionY)
    }

    @discardableResult
    func spawnPyramidMarker(
        in engineState: SM64SwiftEngineState,
        parent: SM64ObjectID,
        positionY: Float
    ) throws -> SM64ObjectID {
        try pyramidElevator.spawnMarker(in: engineState, parent: parent, positionY: positionY)
    }

    @discardableResult
    func spawnPyramidTopFragment(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, scale: Float = 0.8) throws -> SM64ObjectID {
        try pyramidTopFragment.spawn(in: engineState, position: position, scale: scale)
    }

    @discardableResult
    func spawnPyramidPillarTouchDetector(in engineState: SM64SwiftEngineState, parent: SM64ObjectID, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try pyramidPillarTouchDetector.spawn(in: engineState, parent: parent, position: position)
    }

    @discardableResult
    func spawnPyramidTop(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try pyramidTop.spawn(in: engineState, position: position)
    }

    @discardableResult
    func spawnTTCPitBlock(
        in engineState: SM64SwiftEngineState,
        positionY: Float = 0,
        behaviorByte: UInt8 = 0,
        speedSetting: Int32 = 0,
        randomWaitTime: Int32 = 10
    ) throws -> SM64ObjectID {
        try ttcPitBlock.spawnPitBlock(
            in: engineState,
            positionY: positionY,
            behaviorByte: behaviorByte,
            speedSetting: speedSetting,
            randomWaitTime: randomWaitTime
        )
    }

    @discardableResult
    func spawnSquarishPathMoving(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        behaviorByte: Int32 = 0,
        model: UInt32 = SM64SquarishPathMovingObjectBridge.defaultModel
    ) throws -> SM64ObjectID {
        try squarishPathMoving.spawn(
            in: engineState,
            position: position,
            behaviorByte: behaviorByte,
            model: model
        )
    }

    @discardableResult
    func spawnPushableMetalBox(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        model: UInt32 = SM64PushableMetalBoxObjectBridge.defaultModel
    ) throws -> SM64ObjectID {
        try pushableMetalBox.spawn(
            in: engineState,
            position: position,
            model: model
        )
    }

    @discardableResult
    func spawnTiltingBowserLavaPlatform(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        faceAngles: SM64ObjectAngles = .zero,
        model: UInt32 = SM64TiltingBowserLavaPlatformObjectBridge.defaultModel
    ) throws -> SM64ObjectID {
        try tiltingBowserLavaPlatform.spawn(
            in: engineState,
            position: position,
            faceAngles: faceAngles,
            model: model
        )
    }

    @discardableResult
    func spawnLllBowserPuzzle(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        distanceToMario: Float = 19_000,
        model: UInt32 = SM64LllBowserPuzzleObjectBridge.defaultModel
    ) throws -> SM64ObjectID {
        try lllBowserPuzzle.spawnPuzzle(
            in: engineState,
            position: position,
            distanceToMario: distanceToMario,
            model: model
        )
    }

    @discardableResult
    func spawnLllBowserPuzzlePiece(
        in engineState: SM64SwiftEngineState,
        parent: SM64ObjectID,
        sourceIndex: Int,
        model: UInt32? = nil
    ) throws -> SM64ObjectID {
        try lllBowserPuzzle.spawnPiece(
            in: engineState,
            parent: parent,
            sourceIndex: sourceIndex,
            model: model
        )
    }

    @discardableResult
    func spawnStaticCheckeredPlatform(
        in engineState: SM64SwiftEngineState,
        mode: Int32 = 0,
        debugPitch: Int32 = 0,
        debugYaw: Int32 = 0,
        debugRoll: Int32 = 0,
        debugVelocityPitch: Int32 = 0,
        debugVelocityYaw: Int32 = 0,
        debugVelocityRoll: Int32 = 0
    ) throws -> SM64ObjectID {
        try staticCheckeredPlatform.spawnPlatform(
            in: engineState,
            mode: mode,
            debugPitch: debugPitch,
            debugYaw: debugYaw,
            debugRoll: debugRoll,
            debugVelocityPitch: debugVelocityPitch,
            debugVelocityYaw: debugVelocityYaw,
            debugVelocityRoll: debugVelocityRoll
        )
    }

    @discardableResult
    func spawnBBHTiltingTrapPlatform(
        in engineState: SM64SwiftEngineState,
        facePitch: Int32 = 0
    ) throws -> SM64ObjectID {
        try bbhTiltingTrapPlatform.spawnPlatform(in: engineState, facePitch: facePitch)
    }

    @discardableResult
    func spawnLLLSinkingPlatform(
        in engineState: SM64SwiftEngineState,
        rectangularMode: Bool = true,
        positionY: Float = 0
    ) throws -> SM64ObjectID {
        try lllSinkingPlatform.spawnPlatform(
            in: engineState,
            rectangularMode: rectangularMode,
            positionY: positionY
        )
    }

    @discardableResult
    func spawnWfRotatingWoodenPlatform(
        in engineState: SM64SwiftEngineState,
        faceYaw: Int32 = 0,
        action: Int32 = 0
    ) throws -> SM64ObjectID {
        try wfRotatingWoodenPlatform.spawnPlatform(
            in: engineState,
            faceYaw: faceYaw,
            action: action
        )
    }

    @discardableResult
    func spawnRotatingOctagonalPlatform(
        in engineState: SM64SwiftEngineState,
        faceYaw: Int32 = 0,
        collisionModelIndex: UInt8 = 0,
        speedIndex: UInt8 = 0
    ) throws -> SM64ObjectID {
        try rotatingOctagonalPlatform.spawnPlatform(
            in: engineState,
            faceYaw: faceYaw,
            collisionModelIndex: collisionModelIndex,
            speedIndex: speedIndex
        )
    }

    @discardableResult
    func spawnWfSolidTowerPlatform(
        in engineState: SM64SwiftEngineState,
        parent: SM64ObjectID,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try wfSolidTowerPlatform.spawnPlatform(
            in: engineState,
            parent: parent,
            position: position
        )
    }

    @discardableResult
    func spawnWfElevatorTowerPlatform(
        in engineState: SM64SwiftEngineState,
        parent: SM64ObjectID,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try wfTowerPlatform.spawnElevator(in: engineState, parent: parent, position: position)
    }

    @discardableResult
    func spawnWfSlidingTowerPlatform(
        in engineState: SM64SwiftEngineState,
        parent: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int16 = 0,
        distance: Int32 = 380,
        speed: Float = 3
    ) throws -> SM64ObjectID {
        try wfTowerPlatform.spawnSliding(
            in: engineState,
            parent: parent,
            position: position,
            moveYaw: moveYaw,
            distance: distance,
            speed: speed
        )
    }

    @discardableResult
    func spawnTrackBall(
        in engineState: SM64SwiftEngineState,
        parent: SM64ObjectID,
        behaviorByte: Int32,
        parentBaseBallIndex: Int32,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try trackBall.spawn(
            in: engineState,
            parent: parent,
            behaviorByte: behaviorByte,
            parentBaseBallIndex: parentBaseBallIndex,
            position: position
        )
    }

    @discardableResult
    func spawnWfSlidingPlatform(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        faceYaw: Int32 = 0,
        moveYaw: Int32 = 0,
        behaviorByte: UInt8 = 1,
        initialTimer: Int32 = 0
    ) throws -> SM64ObjectID {
        try wfSlidingPlatform.spawnPlatform(
            in: engineState,
            position: position,
            faceYaw: faceYaw,
            moveYaw: moveYaw,
            behaviorByte: behaviorByte,
            initialTimer: initialTimer
        )
    }

    @discardableResult
    func spawnWdwExpressElevator(
        in engineState: SM64SwiftEngineState,
        positionY: Float = 0,
        action: Int32 = 0
    ) throws -> SM64ObjectID {
        try wdwExpressElevator.spawnElevator(
            in: engineState,
            positionY: positionY,
            action: action
        )
    }

    @discardableResult
    func spawnWdwExpressElevatorPlatform(
        in engineState: SM64SwiftEngineState,
        positionY: Float = 0
    ) throws -> SM64ObjectID {
        try wdwExpressElevator.spawnStaticPlatform(in: engineState, positionY: positionY)
    }

    @discardableResult
    func spawnLllSinkingRockBlock(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try lllSinkingRockBlock.spawnBlock(in: engineState, position: position)
    }

    @discardableResult
    func spawnVolcanoFallingTrap(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try volcanoFallingTrap.spawn(in: engineState, position: position)
    }

    @discardableResult
    func spawnRollingLog(
        in engineState: SM64SwiftEngineState,
        variant: SM64RollingLogVariant,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try rollingLog.spawn(in: engineState, variant: variant, position: position)
    }

    @discardableResult
    func spawnLllMovingOctagonalMesh(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        mode: UInt8 = 0
    ) throws -> SM64ObjectID {
        try lllMovingOctagonalMesh.spawnPlatform(in: engineState, position: position, mode: mode)
    }

    @discardableResult
    func spawnFerrisWheel(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try ferrisWheel.spawnAxle(in: engineState, position: position)
    }

    @discardableResult
    func spawnCheckerboardGroup(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        variant: UInt8 = 0,
        waitTime: Int32 = 65
    ) throws -> SM64ObjectID {
        try checkerboardPlatform.spawnGroup(
            in: engineState,
            position: position,
            variant: variant,
            waitTime: waitTime
        )
    }

    @discardableResult
    func spawnWfTowerPlatformGroup(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try wfTowerPlatformGroup.spawnGroup(in: engineState, position: position)
    }

    @discardableResult
    func spawnLllRotatingHexagonalPlatform(
        in engineState: SM64SwiftEngineState,
        moveYaw: Int32 = 0
    ) throws -> SM64ObjectID {
        try lllRotatingHexagonalPlatform.spawnPlatform(in: engineState, moveYaw: moveYaw)
    }

    @discardableResult
    func spawnLllRotatingHexFlame(
        in engineState: SM64SwiftEngineState,
        parent: SM64ObjectID,
        leftOffset: Float = 0,
        forwardOffset: Float = 0
    ) throws -> SM64ObjectID {
        try lllRotatingHexFlame.spawnFlame(
            in: engineState,
            parent: parent,
            leftOffset: leftOffset,
            forwardOffset: forwardOffset
        )
    }

    @discardableResult
    func spawnLllRotatingFireBar(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        behaviorByte: UInt8 = 0
    ) throws -> SM64ObjectID {
        try lllRotatingFireBar.spawnFireBar(
            in: engineState,
            position: position,
            behaviorByte: behaviorByte
        )
    }

    @discardableResult
    func spawnActivatedBackAndForthPlatform(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        faceYaw: Int32 = 0,
        behaviorByte: UInt8 = 0
    ) throws -> SM64ObjectID {
        try activatedBackAndForthPlatform.spawnPlatform(
            in: engineState,
            position: position,
            faceYaw: faceYaw,
            behaviorByte: behaviorByte
        )
    }

    @discardableResult
    func spawnBitfsSinkingPlatform(
        in engineState: SM64SwiftEngineState,
        positionY: Float = 0
    ) throws -> SM64ObjectID {
        try bitfsSinkingPlatform.spawnPlatform(in: engineState, positionY: positionY)
    }

    @discardableResult
    func spawnBitfsSinkingCage(
        in engineState: SM64SwiftEngineState,
        positionY: Float = 0,
        cageParameter: UInt8 = 0
    ) throws -> SM64ObjectID {
        try bitfsSinkingPlatform.spawnCage(
            in: engineState,
            positionY: positionY,
            cageParameter: cageParameter
        )
    }

    @discardableResult
    func spawnLllRotatingHexagonalRing(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try lllRotatingHexagonalRing.spawnRing(in: engineState, position: position)
    }

    @discardableResult
    func spawnLllFloatingWoodBridge(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try lllFloatingWoodBridge.spawnBridge(in: engineState, position: position)
    }

    @discardableResult
    func spawnSquishablePlatform(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try squishablePlatform.spawnPlatform(in: engineState, position: position)
    }

    @discardableResult
    func spawnLllDrawbridgeSpawner(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0
    ) throws -> SM64ObjectID {
        try lllDrawbridge.spawnSpawner(in: engineState, position: position, moveYaw: moveYaw)
    }

    @discardableResult
    func spawnLllDrawbridge(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0,
        action: Int32 = 0,
        faceRoll: Int32 = 0
    ) throws -> SM64ObjectID {
        try lllDrawbridge.spawnDrawbridge(
            in: engineState,
            position: position,
            moveYaw: moveYaw,
            action: action,
            faceRoll: faceRoll
        )
    }

    @discardableResult
    func spawnIdleWaterWave(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        waterLevel: Float = 0
    ) throws -> SM64ObjectID {
        try idleWaterWave.spawnWave(in: engineState, position: position, waterLevel: waterLevel)
    }

    @discardableResult
    func spawnObjectWaterWave(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try idleWaterWave.spawnObjectWaterWave(in: engineState, position: position)
    }

    @discardableResult
    func spawnWaterfallSoundLoop(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try waterfallSoundLoop.spawnLoop(in: engineState, position: position)
    }

    @discardableResult
    func spawnVolcanoSoundLoop(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try volcanoSoundLoop.spawnLoop(in: engineState, position: position)
    }

    @discardableResult
    func spawnTumblingBridge(
        in engineState: SM64SwiftEngineState,
        variant: SM64TumblingBridgeVariant,
        position: SM64ObjectVector3 = .zero,
        distanceToMario: Float = 2000
    ) throws -> SM64ObjectID {
        try tumblingBridge.spawnBridge(
            in: engineState,
            variant: variant,
            position: position,
            distanceToMario: distanceToMario
        )
    }

    @discardableResult
    func spawnFloatingPlatform(
        in engineState: SM64SwiftEngineState,
        variant: SM64FloatingPlatformVariant,
        position: SM64ObjectVector3 = .zero,
        floorHeight: Float = 0,
        waterLevel: Float = 0,
        platformOffset: Float = 64
    ) throws -> SM64ObjectID {
        try floatingPlatform.spawnPlatform(
            in: engineState,
            variant: variant,
            position: position,
            floorHeight: floorHeight,
            waterLevel: waterLevel,
            platformOffset: platformOffset
        )
    }

    @discardableResult
    func spawnJrbFloatingBox(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try jrbFloatingBox.spawnBox(in: engineState, position: position)
    }

    @discardableResult
    func spawnJrbSlidingBox(in engineState: SM64SwiftEngineState, parent: SM64ObjectID, relativePosition: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try jrbSlidingBox.spawnBox(in: engineState, parent: parent, relativePosition: relativePosition)
    }

    @discardableResult
    func spawnSlidingPlatform2(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0,
        behaviorParams: UInt32 = 0
    ) throws -> SM64ObjectID {
        try slidingPlatform2.spawnPlatform(
            in: engineState,
            position: position,
            moveYaw: moveYaw,
            behaviorParams: behaviorParams
        )
    }

    @discardableResult
    func spawnSmallWaterWave(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        waterLevel: Float = 0
    ) throws -> SM64ObjectID {
        try smallWaterWave.spawnWave(in: engineState, position: position, waterLevel: waterLevel)
    }

    @discardableResult
    func spawnBirdsSoundLoop(
        in engineState: SM64SwiftEngineState,
        behaviorByte: UInt8 = 0,
        cameraBehindMario: Bool = false
    ) throws -> SM64ObjectID {
        try ambientSoundLoop.spawnBirds(
            in: engineState,
            behaviorByte: behaviorByte,
            cameraBehindMario: cameraBehindMario
        )
    }

    @discardableResult
    func spawnSandSoundLoop(
        in engineState: SM64SwiftEngineState,
        cameraBehindMario: Bool = false
    ) throws -> SM64ObjectID {
        try ambientSoundLoop.spawnSand(in: engineState, cameraBehindMario: cameraBehindMario)
    }

    @discardableResult
    func spawnRotatingExclamationMark(
        in engineState: SM64SwiftEngineState,
        parent: SM64ObjectID,
        moveYaw: Int32 = 0
    ) throws -> SM64ObjectID {
        try rotatingExclamationMark.spawnMark(in: engineState, parent: parent, moveYaw: moveYaw)
    }

    @discardableResult
    func spawnWaterAirBubble(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        waterLevel: Float = 100
    ) throws -> SM64ObjectID {
        try waterAirBubble.spawnBubble(in: engineState, position: position, waterLevel: waterLevel)
    }

    @discardableResult
    func spawnObjectBubble(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        waterLevel: Float = 100
    ) throws -> SM64ObjectID {
        try objectBubble.spawnBubble(in: engineState, position: position, waterLevel: waterLevel)
    }

    @discardableResult
    func spawnWaterDroplet(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        velocityY: Float = 20,
        waterLevel: Float = 100
    ) throws -> SM64ObjectID {
        try waterDroplet.spawnDroplet(
            in: engineState,
            position: position,
            velocityY: velocityY,
            waterLevel: waterLevel
        )
    }

    @discardableResult
    func spawnWaterMist(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0,
        randomOffsetX: Float = 0,
        randomOffsetZ: Float = 0
    ) throws -> SM64ObjectID {
        try waterMist.spawnMist(
            in: engineState,
            position: position,
            moveYaw: moveYaw,
            randomOffsetX: randomOffsetX,
            randomOffsetZ: randomOffsetZ
        )
    }

    @discardableResult
    func spawnWaterMist2(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        waterLevel: Float = 100
    ) throws -> SM64ObjectID {
        try waterMist2.spawnMist(in: engineState, position: position, waterLevel: waterLevel)
    }

    @discardableResult
    func spawnBubbleSplash(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        waterLevel: Float = 100
    ) throws -> SM64ObjectID {
        try waterSplash.spawnBubbleSplash(in: engineState, position: position, waterLevel: waterLevel)
    }

    @discardableResult
    func spawnWaterDropletSplash(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        randomScale: Float = 0
    ) throws -> SM64ObjectID {
        try waterSplash.spawnWaterDropletSplash(in: engineState, position: position, randomScale: randomScale)
    }

    @discardableResult
    func spawnBubbleMaybe(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        parent: SM64ObjectID? = nil,
        randomOffsetX: Float = 0,
        randomOffsetY: Float = 0,
        randomOffsetZ: Float = 0,
        randomStepX: Float = 0,
        randomStepY: Float = 0,
        randomStepZ: Float = 0,
        angleF4: Int32 = 0,
        angleF8: Int32 = 0,
        expansionRateX: Int32 = 0x800,
        expansionRateY: Int32 = 0x800
    ) throws -> SM64ObjectID {
        try bubbleMaybe.spawnBubble(
            in: engineState,
            position: position,
            parent: parent,
            randomOffsetX: randomOffsetX,
            randomOffsetY: randomOffsetY,
            randomOffsetZ: randomOffsetZ,
            randomStepX: randomStepX,
            randomStepY: randomStepY,
            randomStepZ: randomStepZ,
            angleF4: angleF4,
            angleF8: angleF8,
            expansionRateX: expansionRateX,
            expansionRateY: expansionRateY
        )
    }

    @discardableResult
    func spawnWind(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0,
        movePitch: Int32 = 0,
        initialRandomX: Float = 0,
        initialRandomY: Float = 0,
        initialRandomZ: Float = 0,
        initialYawJitter: Int32 = 0,
        initialForwardVelocity: Float = 50,
        initialVelocityY: Float = 50,
        initialRandomYaw: Int32 = 0,
        facePitchJitter: Float = 0,
        faceYawJitter: Float = 0
    ) throws -> SM64ObjectID {
        try wind.spawnWind(
            in: engineState,
            position: position,
            moveYaw: moveYaw,
            movePitch: movePitch,
            initialRandomX: initialRandomX,
            initialRandomY: initialRandomY,
            initialRandomZ: initialRandomZ,
            initialYawJitter: initialYawJitter,
            initialForwardVelocity: initialForwardVelocity,
            initialVelocityY: initialVelocityY,
            initialRandomYaw: initialRandomYaw,
            facePitchJitter: facePitchJitter,
            faceYawJitter: faceYawJitter
        )
    }

    @discardableResult
    func spawnJetStream(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, distanceToMario: Float = 10_000) throws -> SM64ObjectID {
        try jetStream.spawn(in: engineState, position: position, distanceToMario: distanceToMario)
    }

    @discardableResult
    func spawnJetStreamWaterRing(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try jetStreamWaterRing.spawnRing(in: engineState, position: position)
    }

    @discardableResult
    func spawnJetStreamRingSpawner(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try jetStreamRingSpawner.spawnSpawner(in: engineState, position: position)
    }

    @discardableResult
    func spawnMantaRayWaterRing(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try mantaRayWaterRing.spawnRing(in: engineState, position: position)
    }

    @discardableResult
    func spawnWhirlpool(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, distanceToMario: Float = 10_000, facePitch: Int32 = 0, faceRoll: Int32 = 0) throws -> SM64ObjectID {
        try whirlpool.spawn(in: engineState, position: position, distanceToMario: distanceToMario, facePitch: facePitch, faceRoll: faceRoll)
    }

    @discardableResult
    func spawnMantaRay(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try mantaRay.spawn(in: engineState, position: position)
    }

    @discardableResult
    func spawnShallowWaterWave(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        waterLevel: Float = 100,
        activeParticleFlags: UInt32 = SM64ShallowWaterWaveObjectBridge.particleFlag
    ) throws -> SM64ObjectID {
        try shallowWaterWave.spawnWave(
            in: engineState,
            position: position,
            waterLevel: waterLevel,
            activeParticleFlags: activeParticleFlags
        )
    }

    @discardableResult
    func spawnShallowWaterSplash(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        waterLevel: Float = 100,
        activeParticleFlags: UInt32 = SM64ShallowWaterWaveObjectBridge.splashParticleFlag
    ) throws -> SM64ObjectID {
        try shallowWaterWave.spawnSplash(
            in: engineState,
            position: position,
            waterLevel: waterLevel,
            activeParticleFlags: activeParticleFlags
        )
    }

    @discardableResult
    func spawnWaterSplashSpawner(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        waterLevel: Float = 100,
        activeParticleFlags: UInt32 = SM64WaterSplashSpawnerObjectBridge.particleFlag
    ) throws -> SM64ObjectID {
        try waterSplashSpawner.spawnSplash(
            in: engineState,
            position: position,
            waterLevel: waterLevel,
            activeParticleFlags: activeParticleFlags
        )
    }

    @discardableResult
    func spawnBubbleParticleSpawner(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        delay: Int32 = 2,
        waterLevel: Float = 100,
        activeParticleFlags: UInt32 = SM64BubbleParticleSpawnerObjectBridge.particleFlag
    ) throws -> SM64ObjectID {
        try bubbleParticleSpawner.spawnSpawner(
            in: engineState,
            position: position,
            delay: delay,
            waterLevel: waterLevel,
            activeParticleFlags: activeParticleFlags
        )
    }

    @discardableResult
    func spawnPiranhaPlantWakingBubble(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        initialMoveYaw: Int32 = 0,
        initialForwardVelocity: Float = 10,
        initialVelocityY: Float = 10,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        try piranhaPlantWakingBubble.spawnBubble(
            in: engineState,
            position: position,
            initialMoveYaw: initialMoveYaw,
            initialForwardVelocity: initialForwardVelocity,
            initialVelocityY: initialVelocityY,
            parent: parent
        )
    }

    @discardableResult
    func spawnPiranhaPlantBubble(
        in engineState: SM64SwiftEngineState,
        parent: SM64ObjectID,
        lastAnimationFrame: Int32 = 30
    ) throws -> SM64ObjectID {
        try piranhaPlantBubble.spawnBubble(
            in: engineState,
            parent: parent,
            lastAnimationFrame: lastAnimationFrame
        )
    }

    @discardableResult
    func spawnWaveTrail(
        in engineState: SM64SwiftEngineState,
        kind: SM64WaveTrailKind = .mario,
        position: SM64ObjectVector3 = .zero,
        waterLevel: Float = 100,
        globalFrame: UInt64 = 0,
        initialScale: Float = 1,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        try waveTrail.spawnTrail(
            in: engineState,
            kind: kind,
            position: position,
            waterLevel: waterLevel,
            globalFrame: globalFrame,
            initialScale: initialScale,
            parent: parent
        )
    }

    @discardableResult
    func spawnSushiShark(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        orbitAngle: Int32 = 0,
        waterLevel: Float = 0,
        marioY: Float = 10_000
    ) throws -> SM64ObjectID {
        let id = try sushiShark.spawnSushi(
            in: engineState,
            position: position,
            orbitAngle: orbitAngle,
            waterLevel: waterLevel,
            marioY: marioY
        )
        sushiWaterLevels[id] = waterLevel
        return id
    }

    @discardableResult
    func spawnStrongWindParticle(
        in engineState: SM64SwiftEngineState,
        kind: SM64StrongWindParticleKind = .visible,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0,
        movePitch: Int32 = 0,
        initialRandomX: Float = 0,
        initialRandomY: Float = 0,
        initialRandomZ: Float = 0,
        initialYawJitter: Int32 = 0,
        windSpread: UInt8 = 0,
        penguinCollisionPosition: SM64ObjectVector3? = nil,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        try strongWindParticle.spawnParticle(
            in: engineState,
            kind: kind,
            position: position,
            moveYaw: moveYaw,
            movePitch: movePitch,
            initialRandomX: initialRandomX,
            initialRandomY: initialRandomY,
            initialRandomZ: initialRandomZ,
            initialYawJitter: initialYawJitter,
            windSpread: windSpread,
            penguinCollisionPosition: penguinCollisionPosition,
            parent: parent
        )
    }

    @discardableResult
    func spawnWaterParticle(
        in engineState: SM64SwiftEngineState,
        kind: SM64WaterParticleKind = .small,
        position: SM64ObjectVector3 = .zero,
        initialOffset: SM64ObjectVector3 = .zero,
        angleX: Int32 = 0,
        angleZ: Int32 = 0,
        angleVelocityX: Int32 = 0x800,
        angleVelocityZ: Int32 = 0x800,
        waterLevel: Float = 100,
        randomStepX: Float = 0,
        randomStepZ: Float = 0,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        try waterParticle.spawnParticle(
            in: engineState,
            kind: kind,
            position: position,
            initialOffset: initialOffset,
            angleX: angleX,
            angleZ: angleZ,
            angleVelocityX: angleVelocityX,
            angleVelocityZ: angleVelocityZ,
            waterLevel: waterLevel,
            randomStepX: randomStepX,
            randomStepZ: randomStepZ,
            parent: parent
        )
    }

    @discardableResult
    func spawnPlungeBubble(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        activeParticleFlags: UInt32 = SM64PlungeBubbleObjectBridge.particleFlag
    ) throws -> SM64ObjectID {
        try plungeBubble.spawnPlunge(
            in: engineState,
            position: position,
            activeParticleFlags: activeParticleFlags
        )
    }

    @discardableResult
    func spawnBreathParticleSpawner(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        activeParticleFlags: UInt32 = SM64BreathParticleSpawnerObjectBridge.particleFlag
    ) throws -> SM64ObjectID {
        try breathParticleSpawner.spawnSpawner(
            in: engineState,
            position: position,
            activeParticleFlags: activeParticleFlags
        )
    }

    @discardableResult
    func spawnMistParticle(
        in engineState: SM64SwiftEngineState,
        kind: SM64MistParticleKind = .puff1,
        position: SM64ObjectVector3 = .zero,
        initialOffsetX: Float = 0,
        initialOffsetZ: Float = 0,
        moveYaw: Int32 = 0,
        forwardVelocity: Float = 0,
        velocityY: Float = 0,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        try mistParticle.spawn(in: engineState, kind: kind, position: position, initialOffsetX: initialOffsetX, initialOffsetZ: initialOffsetZ, moveYaw: moveYaw, forwardVelocity: forwardVelocity, velocityY: velocityY, parent: parent)
    }

    @discardableResult
    func spawnMistParticleSpawner(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        activeParticleFlags: UInt32 = SM64MistParticleSpawnerObjectBridge.particleFlag
    ) throws -> SM64ObjectID {
        try mistParticleSpawner.spawnSpawner(in: engineState, position: position, activeParticleFlags: activeParticleFlags)
    }

    @discardableResult
    func spawnTweesterSandParticle(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0,
        forwardVelocity: Float = 0,
        initialRandomX: Float = 0,
        initialRandomZ: Float = 0,
        initialFacePitch: Int32 = 0,
        initialFaceYaw: Int32 = 0,
        randomScale: Float = 0,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        try tweesterSandParticle.spawnParticle(in: engineState, position: position, moveYaw: moveYaw, forwardVelocity: forwardVelocity, initialRandomX: initialRandomX, initialRandomZ: initialRandomZ, initialFacePitch: initialFacePitch, initialFaceYaw: initialFaceYaw, randomScale: randomScale, parent: parent)
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
    func spawnFlameMario(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        activeParticleFlags: UInt32 = SM64FlameMarioObjectBridge.particleFlag,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        try flameMario.spawnFlame(in: engineState, position: position, activeParticleFlags: activeParticleFlags, parent: parent)
    }

    @discardableResult
    func spawnBlackSmokeMario(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        try blackSmokeMario.spawnSmoke(in: engineState, position: position, parent: parent)
    }

    @discardableResult
    func spawnBlackSmokeBowser(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        initialMoveYaw: Int32 = 0,
        initialForwardVelocity: Float = 1.25,
        initialVelocityY: Float = 8,
        angleVelocityYaw: Int32 = 0,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        try blackSmokeBowser.spawnSmoke(
            in: engineState,
            position: position,
            initialMoveYaw: initialMoveYaw,
            initialForwardVelocity: initialForwardVelocity,
            initialVelocityY: initialVelocityY,
            angleVelocityYaw: angleVelocityYaw,
            parent: parent
        )
    }

    @discardableResult
    func spawnBlackSmokeUpward(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        scale: Float = 1
    ) throws -> SM64ObjectID {
        try blackSmokeUpward.spawnUpward(in: engineState, position: position, scale: scale)
    }

    @discardableResult
    func spawnWhitePuffSmoke(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        initialScale: Float = 3
    ) throws -> SM64ObjectID {
        try whitePuffSmoke.spawnSmoke(in: engineState, position: position, initialScale: initialScale)
    }

    @discardableResult
    func spawnWhitePuffSmoke2(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0,
        forwardVelocity: Float = 0,
        velocityY: Float = 0,
        gravity: Float = 0,
        initialOffsetX: Float = 0,
        initialOffsetZ: Float = 0
    ) throws -> SM64ObjectID {
        try whitePuffSmoke2.spawnSmoke(
            in: engineState,
            position: position,
            moveYaw: moveYaw,
            forwardVelocity: forwardVelocity,
            velocityY: velocityY,
            gravity: gravity,
            initialOffsetX: initialOffsetX,
            initialOffsetZ: initialOffsetZ
        )
    }

    @discardableResult
    func spawnWhitePuffExplosion(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        velocity: SM64ObjectVector3 = .zero,
        gravity: Float = 0,
        dragStrength: Float = 0,
        initialScale: Float = 1,
        behaviorParam: Int32 = 2
    ) throws -> SM64ObjectID {
        try whitePuffExplosion.spawnExplosion(
            in: engineState,
            position: position,
            velocity: velocity,
            gravity: gravity,
            dragStrength: dragStrength,
            initialScale: initialScale,
            behaviorParam: behaviorParam
        )
    }

    @discardableResult
    func spawnDustSmoke(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        velocity: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0,
        forwardVelocity: Float = 0
    ) throws -> SM64ObjectID {
        try dustSmoke.spawnSmoke(
            in: engineState,
            position: position,
            velocity: velocity,
            moveYaw: moveYaw,
            forwardVelocity: forwardVelocity
        )
    }

    @discardableResult
    func spawnBobombFuseSmoke(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        velocity: SM64ObjectVector3 = .zero,
        initialOffset: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try dustSmoke.spawnBobombFuseSmoke(
            in: engineState,
            position: position,
            velocity: velocity,
            initialOffset: initialOffset
        )
    }

    @discardableResult
    func spawnStarKeyCollectionPuffSpawner(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        seeds: [SM64StarKeyPuffSeed] = SM64StarKeyCollectionPuffSpawnerObjectBridge.defaultSeeds
    ) throws -> SM64ObjectID {
        try starKeyPuffSpawner.spawnSpawner(in: engineState, position: position, seeds: seeds)
    }

    @discardableResult
    func spawnStaticFlame(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try staticFlame.spawnFlame(in: engineState, position: position)
    }

    @discardableResult
    func spawnFlamethrowerFlame(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0,
        forwardVelocity: Float = 20,
        velocityY: Float = 0,
        gravity: Float = 0,
        behaviorParam: Int32 = 2,
        parentLifetime: Int32 = 30,
        floorHeight: Float = 0,
        initialOffset: SM64ObjectVector3 = .zero,
        initialAnimationState: Int32 = 0
    ) throws -> SM64ObjectID {
        try flamethrowerFlame.spawnFlame(in: engineState, position: position, moveYaw: moveYaw, forwardVelocity: forwardVelocity, velocityY: velocityY, gravity: gravity, behaviorParam: behaviorParam, parentLifetime: parentLifetime, floorHeight: floorHeight, initialOffset: initialOffset, initialAnimationState: initialAnimationState)
    }

    @discardableResult
    func spawnFlameBouncing(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0,
        gravity: Float = -1,
        initialScale: Float = 1,
        distanceToBowser: Float = .greatestFiniteMagnitude,
        bowserExists: Bool = false,
        bowserHeldState: Int32 = 0,
        floorHazard: Bool = false
    ) throws -> SM64ObjectID {
        try flameBouncing.spawnFlame(in: engineState, position: position, moveYaw: moveYaw, gravity: gravity, initialScale: initialScale, distanceToBowser: distanceToBowser, bowserExists: bowserExists, bowserHeldState: bowserHeldState, floorHazard: floorHazard)
    }

    @discardableResult
    func spawnBowserFlame(
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
        try bowserFlame.spawnFlame(in: engineState, kind: kind, position: position, moveYaw: moveYaw, forwardVelocity: forwardVelocity, velocityY: velocityY, gravity: gravity, scaleFactor: scaleFactor, phase: phase, globalTimer: globalTimer, landingScale: landingScale)
    }

    @discardableResult
    func spawnBlueFlamesGroup(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, moveYaw: Int32 = 0, scale: Float = 5) throws -> SM64ObjectID {
        try blueFlamesGroup.spawnGroup(in: engineState, position: position, moveYaw: moveYaw, scale: scale)
    }

    @discardableResult
    func spawnFlameFloatingLanding(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, behaviorParam: Int32 = 0, scale: Float = 5) throws -> SM64ObjectID {
        try flameFloatingLanding.spawnFlame(in: engineState, position: position, behaviorParam: behaviorParam, scale: scale)
    }

    @discardableResult
    func spawnBlueBowserFlame(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, behaviorParam: Int32 = 0) throws -> SM64ObjectID {
        try blueBowserFlame.spawnFlame(in: engineState, position: position, behaviorParam: behaviorParam)
    }

    @discardableResult
    func spawnVolcanoFlames(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, moveYaw: Int32 = 0, forwardVelocity: Float = 0, velocityY: Float = 0, gravity: Float = -4) throws -> SM64ObjectID {
        try volcanoFlames.spawnFlame(in: engineState, position: position, moveYaw: moveYaw, forwardVelocity: forwardVelocity, velocityY: velocityY, gravity: gravity)
    }

    @discardableResult
    func spawnKoopaShellFlame(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, forwardVelocity: Float = 4, gravity: Float = -4, initialOffset: SM64ObjectVector3 = .zero, initialYaw: Int32 = 0, initialVelocityY: Float = 0, initialAnimationState: Int32 = 0) throws -> SM64ObjectID {
        try koopaShellFlame.spawnFlame(in: engineState, position: position, forwardVelocity: forwardVelocity, gravity: gravity, initialOffset: initialOffset, initialYaw: initialYaw, initialVelocityY: initialVelocityY, initialAnimationState: initialAnimationState)
    }

    @discardableResult
    func spawnFlameMovingForwardGrowing(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, moveYaw: Int32 = 0, movePitch: Int32 = 0, forwardVelocity: Float = 30, scaleFactor: Float = 3, initialOffset: SM64ObjectVector3 = .zero, floorHeight: Float = 0, initialAnimationState: Int32 = 0) throws -> SM64ObjectID {
        try flameMovingForwardGrowing.spawnFlame(in: engineState, position: position, moveYaw: moveYaw, movePitch: movePitch, forwardVelocity: forwardVelocity, scaleFactor: scaleFactor, initialOffset: initialOffset, floorHeight: floorHeight, initialAnimationState: initialAnimationState)
    }

    @discardableResult
    func spawnBetaMovingFlames(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, moveYaw: Int32 = 0) throws -> SM64ObjectID {
        try betaMovingFlames.spawnSpawner(in: engineState, position: position)
    }

    @discardableResult
    func spawnBowserFlameSpawn(in engineState: SM64SwiftEngineState, bowserObject: SM64ObjectID, animationEndFrame: Int32 = 100, sampleX: Float = 0, sampleY: Float = 0, sampleZ: Float = 0, samplePitch: Int32 = 0, sampleYaw: Int32 = 0) throws -> SM64ObjectID {
        try bowserFlameSpawn.spawnSpawner(in: engineState, bowserObject: bowserObject, animationEndFrame: animationEndFrame, sampleX: sampleX, sampleY: sampleY, sampleZ: sampleZ, samplePitch: samplePitch, sampleYaw: sampleYaw)
    }

    @discardableResult
    func spawnSmallPiranhaFlame(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, mode: SM64SmallPiranhaFlameMode = .ephemeral, moveYaw: Int32 = 0, movePitch: Int32 = 0, currentSpeed: Float = 0, targetSpeed: Float = 0, targetYaw: Int32 = 0, scale: Float = 1, randomScaleJitter: Float = 0, initialAnimationState: Int32 = 0, flyGuySpawnTimer: Int32 = 8) throws -> SM64ObjectID {
        try smallPiranhaFlame.spawnFlame(in: engineState, position: position, mode: mode, moveYaw: moveYaw, movePitch: movePitch, currentSpeed: currentSpeed, targetSpeed: targetSpeed, targetYaw: targetYaw, scale: scale, randomScaleJitter: randomScaleJitter, initialAnimationState: initialAnimationState, flyGuySpawnTimer: flyGuySpawnTimer)
    }

    @discardableResult
    func spawnFireSpitter(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, distanceToMario: Float = .greatestFiniteMagnitude, targetYaw: Int32 = 0, inWater: Bool = false) throws -> SM64ObjectID {
        try fireSpitter.spawnSpitter(in: engineState, position: position, distanceToMario: distanceToMario, targetYaw: targetYaw, inWater: inWater)
    }

    @discardableResult
    func spawnFirePiranhaPlant(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, behaviorVariant: Int32 = 0, distanceToMario: Float = .greatestFiniteMagnitude) throws -> SM64ObjectID {
        try firePiranhaPlant.spawnPlant(in: engineState, position: position, behaviorVariant: behaviorVariant, distanceToMario: distanceToMario)
    }

    @discardableResult
    func spawnFlamethrower(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, behaviorParam: Int32 = 0, distanceToMario: Float = .greatestFiniteMagnitude, activationAllowed: Bool = true) throws -> SM64ObjectID {
        try flamethrower.spawnFlamethrower(in: engineState, position: position, behaviorParam: behaviorParam, distanceToMario: distanceToMario, activationAllowed: activationAllowed)
    }

    @discardableResult
    func spawnCelebrationStarSparkle(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try celebrationStarSparkle.spawnSparkle(in: engineState, position: position)
    }

    @discardableResult
    func spawnCelebrationStar(in engineState: SM64SwiftEngineState, variant: SM64CelebrationStarVariant = .star, marioPosition: SM64ObjectVector3 = .zero, marioYaw: Int32 = 0) throws -> SM64ObjectID {
        try celebrationStar.spawnStar(in: engineState, variant: variant, marioPosition: marioPosition, marioYaw: marioYaw)
    }

    @discardableResult
    func spawnWarp(in engineState: SM64SwiftEngineState, variant: SM64WarpVariant = .normal, position: SM64ObjectVector3 = .zero, behaviorByte: UInt8 = 0) throws -> SM64ObjectID {
        try warp.spawnWarp(in: engineState, variant: variant, position: position, behaviorByte: behaviorByte)
    }

    @discardableResult
    func spawnDddWarp(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, paintingBeaten: Bool = false) throws -> SM64ObjectID {
        try dddWarp.spawnWarp(in: engineState, position: position, paintingBeaten: paintingBeaten)
    }

    @discardableResult
    func spawnActSelectorStarType(in engineState: SM64SwiftEngineState, type: SM64ActSelectorStarType = .notSelected, position: SM64ObjectVector3 = .zero, size: Float = 1) throws -> SM64ObjectID {
        try actSelectorStarType.spawnStar(in: engineState, type: type, position: position, size: size)
    }

    @discardableResult
    func spawnActSelector(
        in engineState: SM64SwiftEngineState,
        input: SM64ActSelectorInitializationInput,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try actSelector.spawnSelector(in: engineState, input: input, position: position)
    }

    @discardableResult
    func spawnCollectStar(in engineState: SM64SwiftEngineState, starCollected: Bool = false, behaviorByte: UInt8 = 0, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try collectStar.spawnStar(in: engineState, starCollected: starCollected, behaviorByte: behaviorByte, position: position)
    }

    @discardableResult
    func spawnStarSpawnCoordinates(in engineState: SM64SwiftEngineState, starCollected: Bool = false, position: SM64ObjectVector3 = .zero, homePosition: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try starSpawnCoordinates.spawnStar(in: engineState, starCollected: starCollected, position: position, homePosition: homePosition)
    }

    @discardableResult
    func spawnSpawnedStar(in engineState: SM64SwiftEngineState, noExit: Bool = false, starCollected: Bool = false, position: SM64ObjectVector3 = .zero, homePosition: SM64ObjectVector3 = .zero, marioPosition: SM64ObjectVector3 = .zero, moveToMario: Bool = false) throws -> SM64ObjectID {
        try spawnedStar.spawnStar(in: engineState, noExit: noExit, starCollected: starCollected, position: position, homePosition: homePosition, marioPosition: marioPosition, moveToMario: moveToMario)
    }

    @discardableResult
    func spawnUnlockDoorStar(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try unlockDoorStar.spawn(in: engineState, position: position)
    }

    @discardableResult
    func spawnCcmTouchedStarSpawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, enteredSlide: Bool = false) throws -> SM64ObjectID {
        try ccmTouchedStarSpawn.spawn(in: engineState, position: position, enteredSlide: enteredSlide)
    }

    @discardableResult
    func spawnHiddenStar(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, initialTriggerCounter: Int32 = 0) throws -> SM64ObjectID {
        try hiddenStar.spawnHiddenStar(in: engineState, position: position, initialTriggerCounter: initialTriggerCounter)
    }

    @discardableResult
    func spawnHiddenStarTrigger(in engineState: SM64SwiftEngineState, parent: SM64ObjectID? = nil, position: SM64ObjectVector3 = .zero, collidedWithMario: Bool = false) throws -> SM64ObjectID {
        try hiddenStar.spawnTrigger(in: engineState, parent: parent, position: position, collidedWithMario: collidedWithMario)
    }

    @discardableResult
    func spawnBowserCourseRedCoinStar(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, initialTriggerCounter: Int32 = 0) throws -> SM64ObjectID {
        try hiddenStar.spawnBowserCourseRedCoinStar(in: engineState, position: position, initialTriggerCounter: initialTriggerCounter)
    }

    @discardableResult
    func spawnCastleCannonGrate(in engineState: SM64SwiftEngineState, totalStarCount: Int32 = 0, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try castleCannonGrate.spawn(in: engineState, totalStarCount: totalStarCount, position: position)
    }

    @discardableResult
    func spawnBlueCoinSwitch(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, action: SM64BlueCoinSwitchAction = .idle) throws -> SM64ObjectID {
        try blueCoin.spawnSwitch(in: engineState, position: position, action: action)
    }

    @discardableResult
    func spawnHiddenBlueCoin(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, action: SM64HiddenBlueCoinAction = .inactive) throws -> SM64ObjectID {
        try blueCoin.spawnHiddenCoin(in: engineState, position: position, action: action)
    }

    @discardableResult
    func spawnHiddenRedCoinStar(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, redCoinCount: Int32 = 8, courseIsJrb: Bool = false) throws -> SM64ObjectID {
        try redCoin.spawnHiddenRedCoinStar(in: engineState, position: position, redCoinCount: redCoinCount, courseIsJrb: courseIsJrb)
    }

    @discardableResult
    func spawnRedCoinStarMarker(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try redCoin.spawnRedCoinStarMarker(in: engineState, position: position)
    }

    @discardableResult
    func spawnRedCoin(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, parent: SM64ObjectID? = nil) throws -> SM64ObjectID {
        try redCoin.spawnRedCoin(in: engineState, position: position, parent: parent)
    }

    @discardableResult
    func spawnStarDoor(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, moveYaw: Int32 = 0, roomVisible: Bool = true) throws -> SM64ObjectID {
        try starDoor.spawnDoor(in: engineState, position: position, moveYaw: moveYaw, roomVisible: roomVisible)
    }

    @discardableResult
    func spawnCapSwitch(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, variant: Int32 = 0, saveFlags: UInt32 = 0, levelIsUnknown32: Bool = false) throws -> SM64ObjectID {
        try capSwitch.spawnSwitch(in: engineState, position: position, variant: variant, saveFlags: saveFlags, levelIsUnknown32: levelIsUnknown32)
    }

    @discardableResult
    func spawnMetalCap(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, forwardVelocity: Float = 0) throws -> SM64ObjectID {
        try metalCap.spawn(in: engineState, position: position, forwardVelocity: forwardVelocity)
    }

    @discardableResult
    func spawnVanishCap(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, forwardVelocity: Float = 0) throws -> SM64ObjectID {
        try vanishCap.spawn(in: engineState, position: position, forwardVelocity: forwardVelocity)
    }

    @discardableResult
    func spawnWingCap(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, forwardVelocity: Float = 0) throws -> SM64ObjectID {
        try wingCap.spawn(in: engineState, position: position, forwardVelocity: forwardVelocity)
    }

    @discardableResult
    func spawnNormalCap(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, forwardVelocity: Float = 0, course: SM64NormalCapCourse = .other) throws -> SM64ObjectID {
        try normalCap.spawn(in: engineState, position: position, forwardVelocity: forwardVelocity, course: course)
    }

    @discardableResult
    func spawnCapSwitchBase(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, parent: SM64ObjectID? = nil) throws -> SM64ObjectID {
        try capSwitch.spawnBase(in: engineState, position: position, parent: parent)
    }

    @discardableResult
    func spawnTowerDoor(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, faceYaw: Int32 = 0) throws -> SM64ObjectID {
        try towerDoor.spawnDoor(in: engineState, position: position, faceYaw: faceYaw)
    }

    @discardableResult
    func spawnOpenableGrill(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, variant: Int32 = 0) throws -> SM64ObjectID {
        try openableGrill.spawnGrill(in: engineState, position: position, variant: variant)
    }

    @discardableResult
    func spawnDoor(in engineState: SM64SwiftEngineState, warp: Bool = false, metalDoor: Bool = false, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try door.spawnDoor(in: engineState, warp: warp, metalDoor: metalDoor, position: position)
    }

    @discardableResult
    func spawnHiddenObject(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, variant: Int32 = 0, switchAction: Int32? = nil) throws -> SM64ObjectID {
        try hiddenObject.spawnObject(in: engineState, position: position, variant: variant, switchAction: switchAction)
    }

    @discardableResult
    func spawnRecoveryHeart(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        recoveryHeart.spawnHeart(in: engineState, position: position)
    }

    @discardableResult
    func spawnCoin(in engineState: SM64SwiftEngineState, kind: SM64CoinKind = .yellow, position: SM64ObjectVector3 = .zero, floorDistance: Float = 0, oneCoin: Bool = false) throws -> SM64ObjectID {
        let identity = oneCoin ? SM64CoinObjectBridge.oneCoinBehaviorIdentity : nil
        return try coin.spawnCoin(in: engineState, kind: kind, position: position, floorDistance: floorDistance, identity: identity)
    }

    @discardableResult
    func spawnCoinFormation(in engineState: SM64SwiftEngineState, count: Int, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let identity = count == 10 ? SM64CoinObjectBridge.tenCoinsSpawnBehaviorIdentity : SM64CoinObjectBridge.threeCoinsSpawnBehaviorIdentity
        return try coin.spawnFormation(in: engineState, count: count, position: position, identity: identity)
    }

    @discardableResult
    func spawnCoinInsideBoo(
        in engineState: SM64SwiftEngineState,
        parent: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        levelIsBBH: Bool = false
    ) throws -> SM64ObjectID {
        try coin.spawnCoinInsideBoo(in: engineState, parent: parent, position: position, levelIsBBH: levelIsBBH)
    }

    @discardableResult
    func spawnMovingCoin(in engineState: SM64SwiftEngineState, kind: SM64MovingCoinKind = .yellow, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try movingCoin.spawnCoin(in: engineState, kind: kind, position: position)
    }

    @discardableResult
    func spawnWaterLevelDiamond(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, currentLevel: Int32 = 0) throws -> SM64ObjectID {
        try waterLevel.spawnDiamond(in: engineState, position: position, currentLevel: currentLevel)
    }

    @discardableResult
    func spawnChangingWaterLevel(in engineState: SM64SwiftEngineState, regionsAvailable: Bool = true, phase: Int32 = 0) throws -> SM64ObjectID {
        try waterLevel.spawnInitializer(in: engineState, regionsAvailable: regionsAvailable, phase: phase)
    }

    @discardableResult
    func spawnWaterPillar(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, drained: Bool = false, environmentLevel: Int32 = 0) throws -> SM64ObjectID {
        try waterPillar.spawnPillar(in: engineState, position: position, drained: drained, environmentLevel: environmentLevel)
    }

    @discardableResult
    func spawnFloorSwitch(in engineState: SM64SwiftEngineState, behaviorByte: Int32 = 0, position: SM64ObjectVector3 = .zero, variant: SM64FloorSwitchObjectBridge.Variant = .hardcoded) throws -> SM64ObjectID {
        try floorSwitch.spawnSwitch(in: engineState, behaviorByte: behaviorByte, position: position, identity: variant.identity)
    }

    @discardableResult
    func spawnAnimatedFloorSwitch(in engineState: SM64SwiftEngineState, behaviorByte: Int32 = 0, position: SM64ObjectVector3 = .zero, parent: SM64ObjectID? = nil) throws -> SM64ObjectID {
        try animatedFloorSwitch.spawn(in: engineState, behaviorByte: behaviorByte, position: position, parent: parent)
    }

    @discardableResult
    func spawnHiddenOneUp(
        in engineState: SM64SwiftEngineState,
        role: SM64HiddenOneUpRole = .hidden,
        behaviorByte: Int32 = 0,
        triggerCount: Int32 = 0,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try hiddenOneUp.spawn(
            in: engineState,
            role: role,
            behaviorByte: behaviorByte,
            triggerCount: triggerCount,
            position: position
        )
    }

    @discardableResult
    func spawnBreakableBox(
        in engineState: SM64SwiftEngineState,
        kind: SM64BreakableBoxKind = .small,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try breakableBox.spawn(in: engineState, kind: kind, position: position)
    }

    @discardableResult
    func spawnWfBreakableWall(in engineState: SM64SwiftEngineState, rightVariant: Bool = false, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try wfBreakableWall.spawn(in: engineState, rightVariant: rightVariant, position: position)
    }

    @discardableResult
    func spawnUnusedPoundablePlatform(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try unusedPoundablePlatform.spawn(in: engineState, position: position)
    }

    @discardableResult
    func spawnYellowBackgroundMenu(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try yellowBackgroundMenu.spawn(in: engineState, position: position)
    }

    @discardableResult
    func spawnSlidingSnowMound(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try snowMound.spawnSliding(in: engineState, position: position)
    }

    @discardableResult
    func spawnSnowMoundSpawner(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try snowMound.spawnSpawner(in: engineState, position: position)
    }

    @discardableResult
    func spawnRrCruiserWing(in engineState: SM64SwiftEngineState, baseYaw: Int32 = 0, basePitch: Int32 = 0, reverse: Bool = false, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try rrCruiserWing.spawn(in: engineState, baseYaw: baseYaw, basePitch: basePitch, reverse: reverse, position: position)
    }

    @discardableResult
    func spawnSpindrift(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try spindrift.spawn(in: engineState, position: position)
    }

    @discardableResult
    func spawnSpindel(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try spindel.spawn(in: engineState, position: position)
    }

    @discardableResult
    func spawnRrRotatingBridgePlatform(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, behaviorParam: Int32 = 0, distanceToMario: Float = .greatestFiniteMagnitude, activationAllowed: Bool = true) throws -> SM64ObjectID {
        try rrRotatingBridgePlatform.spawn(in: engineState, position: position, behaviorParam: behaviorParam, distanceToMario: distanceToMario, activationAllowed: activationAllowed)
    }

    @discardableResult
    func spawnSnowmanWind(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, originalYaw: Int32 = 0) throws -> SM64ObjectID {
        try snowmanWind.spawn(in: engineState, position: position, originalYaw: originalYaw)
    }

    @discardableResult
    func spawnMrBlizzardSnowball(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, moveYaw: Int32 = -0x5B58) throws -> SM64ObjectID {
        try mrBlizzardSnowball.spawn(in: engineState, position: position, moveYaw: moveYaw)
    }

    @discardableResult
    func spawnJumpingBox(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, threshold: Int32 = 60) throws -> SM64ObjectID {
        try jumpingBox.spawn(in: engineState, position: position, threshold: threshold)
    }

    @discardableResult
    func spawnKickableBoard(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try kickableBoard.spawn(in: engineState, position: position)
    }

    @discardableResult
    func spawnExclamationBox(
        in engineState: SM64SwiftEngineState,
        behaviorByte: Int32 = 0,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try exclamationBox.spawn(in: engineState, behaviorByte: behaviorByte, position: position)
    }

    @discardableResult
    func spawnOrangeNumber(
        in engineState: SM64SwiftEngineState,
        animationState: Int32 = 0,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try orangeNumber.spawn(in: engineState, animationState: animationState, position: position)
    }

    @discardableResult
    func spawnSoundSpawner(
        in engineState: SM64SwiftEngineState,
        soundID: Int32 = 0,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try soundSpawner.spawn(in: engineState, soundID: soundID, position: position)
    }

    @discardableResult
    func spawnRockSolid(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try rockSolid.spawn(in: engineState, position: position)
    }

    @discardableResult
    func spawnToxBox(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        initialDirectionAction: Int32 = 4,
        nextDirectionAction: Int32 = 4,
        behaviorVariant: Int32 = 0
    ) throws -> SM64ObjectID {
        try toxBox.spawn(in: engineState, position: position, initialDirectionAction: initialDirectionAction, nextDirectionAction: nextDirectionAction, behaviorVariant: behaviorVariant)
    }

    @discardableResult
    func spawnSslMovingPyramidWall(
        in engineState: SM64SwiftEngineState,
        positionY: Float = 0,
        start: SM64SslPyramidWallStart = .high
    ) throws -> SM64ObjectID {
        try sslMovingPyramidWall.spawn(in: engineState, positionY: positionY, start: start)
    }

    @discardableResult
    func spawnThiIslandTop(
        in engineState: SM64SwiftEngineState,
        role: SM64ThiIslandTopRole,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try thiIslandTop.spawn(in: engineState, role: role, position: position)
    }

    @discardableResult
    func spawnEnvironmentGate(in engineState: SM64SwiftEngineState, role: SM64EnvironmentGateRole, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try environmentGate.spawn(in: engineState, role: role, position: position)
    }

    @discardableResult
    func spawnClockArm(in engineState: SM64SwiftEngineState, kind: SM64ClockArmKind, position: SM64ObjectVector3 = .zero, surface: SM64ClockSurface = .default) throws -> SM64ObjectID {
        try clockArm.spawn(in: engineState, kind: kind, position: position, surface: surface)
    }

    @discardableResult
    func spawnCastleFloorTrap(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try castleFloorTrap.spawnParent(in: engineState, position: position)
    }

    @discardableResult
    func spawnCastleFlag(in engineState: SM64SwiftEngineState, randomFrame: Int32 = 0, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try castleFlag.spawn(in: engineState, randomFrame: randomFrame, position: position)
    }

    @discardableResult
    func spawnBooCage(in engineState: SM64SwiftEngineState, parent: SM64ObjectID? = nil, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try booCage.spawn(in: engineState, parent: parent, position: position)
    }

    @discardableResult
    func spawnBooKey(in engineState: SM64SwiftEngineState, kind: SM64BooKeyKind, parent: SM64ObjectID? = nil, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try booKey.spawn(in: engineState, kind: kind, parent: parent, position: position)
    }

    @discardableResult
    func spawnBooInCastle(in engineState: SM64SwiftEngineState, stars: Int32 = 12, room: Int32 = 0, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try booInCastle.spawn(in: engineState, stars: stars, room: room, position: position)
    }

    @discardableResult
    func spawnMerryGoRound(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try merryGoRound.spawn(in: engineState, position: position)
    }

    @discardableResult
    func spawnMusicTouch(in engineState: SM64SwiftEngineState, distanceToMario: Float = 10_000, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try musicTouch.spawn(in: engineState, distanceToMario: distanceToMario, position: position)
    }

    @discardableResult
    func spawnTextSurface(in engineState: SM64SwiftEngineState, kind: SM64TextSurfaceKind, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try textSurface.spawn(in: engineState, kind: kind, position: position)
    }

    @discardableResult
    func spawnGrandStar(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, homeY: Float = 0) throws -> SM64ObjectID {
        try grandStar.spawn(in: engineState, position: position, homeY: homeY)
    }

    @discardableResult
    func spawnBetaBowserAnchor(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try betaBowserAnchor.spawn(in: engineState, position: position)
    }

    @discardableResult
    func spawnGroundParticleSpawner(in engineState: SM64SwiftEngineState, kind: SM64GroundParticleKind, position: SM64ObjectVector3 = .zero, activeParticleFlags: UInt32 = 0) throws -> SM64ObjectID {
        try groundParticleSpawner.spawnSpawner(in: engineState, kind: kind, position: position, activeParticleFlags: activeParticleFlags)
    }

    @discardableResult
    func spawnAnimatedTexture(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        model: UInt32 = 0,
        animationState: Int32 = 0
    ) throws -> SM64ObjectID {
        try animatedTexture.spawnAnimatedTexture(
            in: engineState,
            position: position,
            model: model,
            animationState: animationState
        )
    }

    @discardableResult
    func spawnSparkle(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        try sparkle.spawnSparkle(in: engineState, position: position, parent: parent)
    }

    @discardableResult
    func spawnSparkleSpawner(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        randomOffset: SM64ObjectVector3 = .zero,
        randomScale: Float = 1
    ) throws -> SM64ObjectID {
        try sparkleSpawner.spawnSpawner(
            in: engineState,
            position: position,
            randomOffset: randomOffset,
            randomScale: randomScale
        )
    }

    @discardableResult
    func spawnAmbientSounds(
        in engineState: SM64SwiftEngineState,
        cameraBehindMario: Bool = false,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try ambientSounds.spawnAmbientSounds(
            in: engineState,
            cameraBehindMario: cameraBehindMario,
            position: position
        )
    }

    @discardableResult
    func spawnCoinSparkles(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        try coinSparkles.spawnSparkles(in: engineState, position: position, parent: parent)
    }

    @discardableResult
    func spawnGoldenCoinSparkles(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        randomOffsets: [SM64ObjectVector3] = Array(repeating: .zero, count: 3)
    ) throws -> SM64ObjectID {
        try goldenCoinSparkles.spawnSparkles(
            in: engineState,
            position: position,
            randomOffsets: randomOffsets
        )
    }

    @discardableResult
    func spawnPurpleParticle(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0,
        randomForwardUnit: Float = 0,
        randomVerticalUnit: Float = 0
    ) throws -> SM64ObjectID {
        try purpleParticle.spawnParticle(
            in: engineState,
            position: position,
            moveYaw: moveYaw,
            randomForwardUnit: randomForwardUnit,
            randomVerticalUnit: randomVerticalUnit
        )
    }

    @discardableResult
    func spawnTinyStarParticle(
        in engineState: SM64SwiftEngineState,
        kind: SM64TinyStarParticleKind,
        position: SM64ObjectVector3 = .zero,
        marioPosition: SM64ObjectVector3 = .zero,
        marioYaw: Int32 = 0,
        moveYaw: Int32 = 0,
        forwardVelocity: Float = 25,
        velocityY: Float = 10,
        gravity: Float = 0
    ) throws -> SM64ObjectID {
        try tinyStarParticle.spawnParticle(
            in: engineState,
            kind: kind,
            position: position,
            marioPosition: marioPosition,
            marioYaw: marioYaw,
            moveYaw: moveYaw,
            forwardVelocity: forwardVelocity,
            velocityY: velocityY,
            gravity: gravity
        )
    }

    @discardableResult
    func spawnTinyStarParticleSpawner(
        in engineState: SM64SwiftEngineState,
        kind: SM64TinyStarParticleSpawnerKind,
        position: SM64ObjectVector3 = .zero,
        activeParticleFlags: UInt32 = 0,
        particleFlag: UInt32 = 0x1,
        seeds: [SM64TinyStarParticleSeed] = [],
        marioPosition: SM64ObjectVector3 = .zero,
        marioYaw: Int32 = 0
    ) throws -> SM64ObjectID {
        try tinyStarParticleSpawner.spawnSpawner(
            in: engineState,
            kind: kind,
            position: position,
            activeParticleFlags: activeParticleFlags,
            particleFlag: particleFlag,
            seeds: seeds,
            marioPosition: marioPosition,
            marioYaw: marioYaw
        )
    }

    @discardableResult
    func spawnTriangleParticle(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, marioPosition: SM64ObjectVector3 = .zero, marioYaw: Int32 = 0, moveYaw: Int32 = 0, forwardVelocity: Float = 25, velocityY: Float = 14, gravity: Float = 0, lifetime: Int32 = 6) throws -> SM64ObjectID {
        try triangleParticle.spawnParticle(in: engineState, position: position, marioPosition: marioPosition, marioYaw: marioYaw, moveYaw: moveYaw, forwardVelocity: forwardVelocity, velocityY: velocityY, gravity: gravity, lifetime: lifetime)
    }

    @discardableResult
    func spawnTriangleParticleSpawner(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, activeParticleFlags: UInt32 = 0, particleFlag: UInt32 = 0x1, seeds: [SM64TinyStarParticleSeed] = [], marioPosition: SM64ObjectVector3 = .zero, marioYaw: Int32 = 0) throws -> SM64ObjectID {
        try triangleParticleSpawner.spawnSpawner(in: engineState, position: position, activeParticleFlags: activeParticleFlags, particleFlag: particleFlag, seeds: seeds, marioPosition: marioPosition, marioYaw: marioYaw)
    }

    @discardableResult
    func spawnTreeLeaf(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, floorHeight: Float = -10_000, moveYaw: Int32 = 0, phase: Int32 = 0, phaseRate: Int32 = 0x800, forwardVelocity: Float = 5, velocityY: Float = 15, scale: Float = 1, prevFrameObjectCount: Int32 = 0) throws -> SM64ObjectID {
        try treeLeaf.spawnLeaf(in: engineState, position: position, floorHeight: floorHeight, moveYaw: moveYaw, phase: phase, phaseRate: phaseRate, forwardVelocity: forwardVelocity, velocityY: velocityY, scale: scale, prevFrameObjectCount: prevFrameObjectCount)
    }

    @discardableResult
    func spawnTreeParticleSpawner(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, activeParticleFlags: UInt32 = 0, particleFlag: UInt32 = 0x2000, snowMode: Bool = false, spawnDecision: Float = 1, randomScale: Float = 1, randomYaw: Int32 = 0, randomForwardUnit: Float = 0, randomVerticalUnit: Float = 0, randomFacePitch: Int32 = 0, randomFaceRoll: Int32 = 0) throws -> SM64ObjectID {
        try treeParticleSpawner.spawnSpawner(in: engineState, position: position, activeParticleFlags: activeParticleFlags, particleFlag: particleFlag, snowMode: snowMode, spawnDecision: spawnDecision, randomScale: randomScale, randomYaw: randomYaw, randomForwardUnit: randomForwardUnit, randomVerticalUnit: randomVerticalUnit, randomFacePitch: randomFacePitch, randomFaceRoll: randomFaceRoll)
    }

    @discardableResult
    func spawnMistCircParticleSpawner(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, activeParticleFlags: UInt32 = 0, particleFlag: UInt32 = 0x8000, seeds: [SM64MistCircParticleSeed] = []) throws -> SM64ObjectID {
        try mistCircParticleSpawner.spawnSpawner(in: engineState, position: position, activeParticleFlags: activeParticleFlags, particleFlag: particleFlag, seeds: seeds)
    }

    @discardableResult
    func spawnSparkleParticleSpawner(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, activeParticleFlags: UInt32 = 0, particleFlag: UInt32 = 0x800, randomOffset: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try sparkleParticleSpawner.spawnSpawner(in: engineState, position: position, activeParticleFlags: activeParticleFlags, particleFlag: particleFlag, randomOffset: randomOffset)
    }

    @discardableResult
    func spawnSimpleAnimation(in engineState: SM64SwiftEngineState, kind: SM64SimpleAnimationKind, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try simpleAnimation.spawn(in: engineState, kind: kind, position: position)
    }

    @discardableResult
    func spawnUnusedFakeStar(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try unusedFakeStar.spawn(in: engineState, position: position)
    }

    @discardableResult
    func spawnCloudPart(in engineState: SM64SwiftEngineState, parentCenterX: Float = 0, parentCenterY: Float = 0, parentPositionZ: Float = 0, parentFaceYaw: Int32 = 0, parentScale: Float = 1, partIndex: Int32 = 0, parentUnloading: Bool = false) throws -> SM64ObjectID {
        try cloudPart.spawnPart(in: engineState, parentCenterX: parentCenterX, parentCenterY: parentCenterY, parentPositionZ: parentPositionZ, parentFaceYaw: parentFaceYaw, parentScale: parentScale, partIndex: partIndex, parentUnloading: parentUnloading)
    }

    @discardableResult
    func spawnBreakBoxTriangle(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, moveYaw: Int32 = 0, forwardVelocity: Float = 5, velocityY: Float = 15, gravity: Float = -1) throws -> SM64ObjectID {
        try breakBoxTriangle.spawn(in: engineState, position: position, moveYaw: moveYaw, forwardVelocity: forwardVelocity, velocityY: velocityY, gravity: gravity)
    }

    @discardableResult
    func spawnCannonBaseUnused(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, velocityY: Float = 0) throws -> SM64ObjectID {
        try cannonBaseUnused.spawn(in: engineState, position: position, velocityY: velocityY)
    }

    @discardableResult
    func spawnNoOp(in engineState: SM64SwiftEngineState, behaviorIdentity: UInt64, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try noOp.spawn(in: engineState, behaviorIdentity: behaviorIdentity, position: position)
    }

    @discardableResult
    func spawnCannonBarrelBubbles(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, parentPosition: SM64ObjectVector3 = .zero, relativePosition: SM64ObjectVector3 = .zero, parentFaceYaw: Int32 = 0, parentMovePitch: Int32 = 0, parentAction: Int32 = 0, accumulatedDistance: Float = 0, forwardVelocity: Float = 0, cannonActive: Bool = false) throws -> SM64ObjectID {
        try cannonBarrelBubbles.spawnBarrel(in: engineState, position: position, parentPosition: parentPosition, relativePosition: relativePosition, parentFaceYaw: parentFaceYaw, parentMovePitch: parentMovePitch, parentAction: parentAction, accumulatedDistance: accumulatedDistance, forwardVelocity: forwardVelocity, cannonActive: cannonActive)
    }

    @discardableResult
    func spawnCloud(in engineState: SM64SwiftEngineState, kind: SM64CloudKind = .fwoosh, position: SM64ObjectVector3 = .zero, parentPosition: SM64ObjectVector3 = .zero, parentActive: Bool = true, parentFaceYaw: Int32 = 0, distanceToMario: Float = 1_000, scale: Float = 3, action: SM64CloudAction = .spawnParts, timer: Int32 = 0, blowing: Bool = false, growSpeed: Float = 0) throws -> SM64ObjectID {
        try cloud.spawnCloud(in: engineState, kind: kind, position: position, parentPosition: parentPosition, parentActive: parentActive, parentFaceYaw: parentFaceYaw, distanceToMario: distanceToMario, scale: scale, action: action, timer: timer, blowing: blowing, growSpeed: growSpeed)
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
    func spawnBooWithCage(in engineState: SM64SwiftEngineState, homeX: Float = 0, homeY: Float = 0, homeZ: Float = 0, moveYaw: Int16 = 0, totalStars: Int32 = 12) throws -> SM64ObjectID {
        let id = try boo.spawnBooWithCage(in: engineState, homeX: homeX, homeY: homeY, homeZ: homeZ, moveYaw: moveYaw)
        if totalStars >= 12 { _ = try? booCage.spawn(in: engineState, parent: id, position: .init(x: homeX, y: homeY, z: homeZ)) }
        return id
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
    func spawnBomp(
        in engineState: SM64SwiftEngineState,
        variant: SM64BompVariant = .small,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0,
        randomTimer: Int32 = 0
    ) throws -> SM64ObjectID {
        try bomp.spawn(
            in: engineState,
            variant: variant,
            position: position,
            moveYaw: moveYaw,
            randomTimer: randomTimer
        )
    }

    @discardableResult
    func spawnThwomp(
        in engineState: SM64SwiftEngineState,
        variant: SM64ThwompVariant = .thwomp,
        position: SM64ObjectVector3 = .zero,
        behaviorByte: Int32 = 0,
        distanceToMario: Float = 10_000,
        randomWaitTimer: Float = 20,
        randomPauseTimer: Float = 20
    ) throws -> SM64ObjectID {
        try thwomp.spawn(
            in: engineState,
            variant: variant,
            position: position,
            behaviorByte: behaviorByte,
            distanceToMario: distanceToMario,
            randomWaitTimer: randomWaitTimer,
            randomPauseTimer: randomPauseTimer
        )
    }

    @discardableResult
    func spawnBoulder(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, moveYaw: Int32 = 0) throws -> SM64ObjectID {
        try boulder.spawn(in: engineState, position: position, moveYaw: moveYaw)
    }

    @discardableResult
    func spawnBoulderGenerator(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, timer: Int32 = 0, distanceToMario: Float = 10_000, currentRoomIsFour: Bool = true) throws -> SM64ObjectID {
        try boulder.spawnGenerator(in: engineState, position: position, timer: timer, distanceToMario: distanceToMario, currentRoomIsFour: currentRoomIsFour)
    }

    @discardableResult
    func spawnHorizontalGrindel(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, moveYaw: Int32 = 0, onGround: Bool = true, lateralDistanceHome: Float = 0) throws -> SM64ObjectID {
        try horizontalGrindel.spawn(in: engineState, position: position, moveYaw: moveYaw, onGround: onGround, lateralDistanceHome: lateralDistanceHome)
    }

    @discardableResult
    func spawnUnusedParticleSpawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try unusedParticleSpawn.spawn(in: engineState, position: position)
    }

    @discardableResult
    func spawnSnowmanCheckpoint(in engineState: SM64SwiftEngineState, parent: SM64ObjectID, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        guard let id = snowmanCheckpoint.spawn(in: engineState, parent: parent, position: position) else { throw SM64ObjectPoolError.invalidReference(parent) }
        return id
    }

    @discardableResult
    func spawnSnowmanHead(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try snowmanHead.spawn(in: engineState, position: position)
    }

    @discardableResult
    func spawnMadPiano(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        homePosition: SM64ObjectVector3? = nil
    ) throws -> SM64ObjectID {
        try madPiano.spawnPiano(in: engineState, position: position, homePosition: homePosition)
    }

    @discardableResult
    func spawnUkiki(
        in engineState: SM64SwiftEngineState,
        behaviorParam: Int32 = SM64UkikiBehavior.cageParam,
        position: SM64ObjectVector3 = .zero,
        behaviorIdentity: UInt64 = SM64UkikiObjectBridge.ukikiBehaviorIdentity
    ) throws -> SM64ObjectID {
        try ukiki.spawn(
            in: engineState,
            behaviorParam: behaviorParam,
            position: position,
            behaviorIdentity: behaviorIdentity
        )
    }

    @discardableResult
    func spawnMacroUkiki(
        in engineState: SM64SwiftEngineState,
        behaviorParam: Int32 = SM64UkikiBehavior.cageParam,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try spawnUkiki(
            in: engineState,
            behaviorParam: behaviorParam,
            position: position,
            behaviorIdentity: SM64UkikiObjectBridge.macroUkikiBehaviorIdentity
        )
    }

    @discardableResult
    func spawnUkikiCage(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try ukikiCage.spawnCage(in: engineState, position: position)
    }

    @discardableResult
    func spawnUkikiCageStar(
        in engineState: SM64SwiftEngineState,
        parent: SM64ObjectID,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try ukikiCage.spawnStar(in: engineState, parent: parent, position: position)
    }

    @discardableResult
    func spawnMips(
        in engineState: SM64SwiftEngineState,
        starCount: Int32 = 15,
        starFlags: UInt8 = 0,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try mips.spawn(in: engineState, starCount: starCount, starFlags: starFlags, position: position)
    }

    @discardableResult
    func spawnToadMessage(
        in engineState: SM64SwiftEngineState,
        dialogID: Int32,
        starCount: Int32 = 120,
        saveFlags: UInt32 = 0,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try toadMessage.spawn(
            in: engineState,
            dialogID: dialogID,
            starCount: starCount,
            saveFlags: saveFlags,
            position: position
        )
    }

    @discardableResult
    func spawnMenuButton(in engineState: SM64SwiftEngineState, relativePosition: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try menuButton.spawnButton(in: engineState, relativePosition: relativePosition)
    }

    @discardableResult
    func spawnMenuButtonManager(in engineState: SM64SwiftEngineState) throws -> SM64ObjectID {
        try menuButton.spawnManager(in: engineState)
    }

    @discardableResult
    func spawnBowserBodyAnchor(in engineState: SM64SwiftEngineState, parent: SM64ObjectID, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try bowserBodyAnchor.spawn(in: engineState, parent: parent, position: position)
    }

    @discardableResult
    func spawnBowserTailAnchor(in engineState: SM64SwiftEngineState, parent: SM64ObjectID, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try bowserTailAnchor.spawn(in: engineState, parent: parent, position: position)
    }

    @discardableResult
    func spawnBetaChest(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try betaChest.spawnBottom(in: engineState, position: position)
    }

    @discardableResult
    func spawnBetaTrampoline(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, marioOn: Bool = false) throws -> SM64ObjectID {
        try betaTrampoline.spawnTop(in: engineState, position: position, marioOn: marioOn)
    }

    @discardableResult
    func spawnBetaHoldable(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try betaHoldable.spawn(in: engineState, position: position)
    }

    @discardableResult
    func spawnSeaweedBundle(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try seaweed.spawnBundle(in: engineState, position: position)
    }

    @discardableResult
    func spawnShipPart3(
        in engineState: SM64SwiftEngineState,
        role: SM64ShipPart3Role = .decorative,
        position: SM64ObjectVector3 = .zero,
        yaw: Int32 = 0,
        rollPhase: Int32 = 0
    ) throws -> SM64ObjectID {
        try shipPart3.spawn(in: engineState, role: role, position: position, yaw: yaw, rollPhase: rollPhase)
    }

    @discardableResult
    func spawnSunkenShipPart(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, distanceToMario: Float = 19_000) throws -> SM64ObjectID {
        try sunkenShipPart.spawn(in: engineState, position: position, distanceToMario: distanceToMario)
    }

    @discardableResult
    func spawnFallingPillar(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        distanceToMario: Float = 10_000,
        angleToMario: Int32 = 0
    ) throws -> SM64ObjectID {
        try fallingPillar.spawnPillar(
            in: engineState,
            position: position,
            distanceToMario: distanceToMario,
            angleToMario: angleToMario
        )
    }

    @discardableResult
    func spawnCoffinSpawner(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        distanceToMario: Float = 10_000
    ) throws -> SM64ObjectID {
        try coffin.spawnSpawner(in: engineState, position: position, distanceToMario: distanceToMario)
    }

    @discardableResult
    func spawnBlueFish(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        randomAngle: Int32 = 0x800,
        randomVelocity: Float = 1,
        randomTime: Int32 = 20,
        angleVelocityPitch: Int32 = 0
    ) throws -> SM64ObjectID {
        try blueFish.spawnFish(
            in: engineState,
            position: position,
            randomAngle: randomAngle,
            randomVelocity: randomVelocity,
            randomTime: randomTime,
            angleVelocityPitch: angleVelocityPitch
        )
    }

    @discardableResult
    func spawnTankFishGroup(
        in engineState: SM64SwiftEngineState,
        room: Int32 = 15,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try blueFish.spawnTankFishGroup(in: engineState, room: room, position: position)
    }

    @discardableResult
    func spawnClamShell(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try clamShell.spawnClam(in: engineState, position: position)
    }

    @discardableResult
    func spawnBobombAnchorMario(in engineState: SM64SwiftEngineState, parent: SM64ObjectID) throws -> SM64ObjectID {
        try bobombAnchorMario.spawnAnchor(in: engineState, parent: parent)
    }

    @discardableResult
    func spawnBubSpawner(in engineState: SM64SwiftEngineState, childCount: Int = 1, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try bub.spawnSpawner(in: engineState, childCount: childCount, position: position)
    }

    @discardableResult
    func spawnBubba(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, waterLevel: Float = 100) throws -> SM64ObjectID {
        try bubba.spawnBubba(in: engineState, position: position, waterLevel: waterLevel)
    }

    @discardableResult
    func spawnBobBowlingBallSpawner(in engineState: SM64SwiftEngineState, behaviorParam: Int32 = 0, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try bowlingBall.spawnBobSpawner(in: engineState, behaviorParam: behaviorParam, position: position)
    }

    @discardableResult
    func spawnTtmBowlingBallSpawner(in engineState: SM64SwiftEngineState, behaviorParam: Int32 = 1, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try bowlingBall.spawnTtmSpawner(in: engineState, behaviorParam: behaviorParam, position: position)
    }

    @discardableResult
    func spawnThiBowlingBallSpawner(in engineState: SM64SwiftEngineState, behaviorParam: Int32 = 3, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try bowlingBall.spawnThiSpawner(in: engineState, behaviorParam: behaviorParam, position: position)
    }

    @discardableResult
    func spawnBowlingBall(in engineState: SM64SwiftEngineState, behaviorParam: Int32 = 0, position: SM64ObjectVector3 = .zero, parent: SM64ObjectID? = nil) throws -> SM64ObjectID {
        try bowlingBall.spawnBowlingBall(in: engineState, behaviorParam: behaviorParam, position: position, parent: parent)
    }

    @discardableResult
    func spawnFreeBowlingBall(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try bowlingBall.spawnFreeBowlingBall(in: engineState, position: position)
    }

    @discardableResult
    func spawnPitBowlingBall(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try bowlingBall.spawnPitBowlingBall(in: engineState, position: position)
    }

    @discardableResult
    func spawnDDDPole(in engineState: SM64SwiftEngineState, behaviorParam: Int32 = 1, saveUnlocked: Bool = true, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try dddPole.spawnPole(in: engineState, behaviorParam: behaviorParam, saveUnlocked: saveUnlocked, position: position)
    }

    @discardableResult
    func spawnDonutPlatformSpawner(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try donutPlatform.spawnSpawner(in: engineState, position: position)
    }

    @discardableResult
    func spawnCourtyardBooTriplet(in engineState: SM64SwiftEngineState, totalStars: Int32 = 12, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try courtyardBooTriplet.spawnTriplet(in: engineState, totalStars: totalStars, position: position)
    }

    @discardableResult
    func spawnFallingBowserPlatform(in engineState: SM64SwiftEngineState, variant: Int32 = 1, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try fallingBowserPlatform.spawnPlatform(in: engineState, variant: variant, position: position)
    }

    @discardableResult
    func spawnGiantPole(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, hitboxHeight: Float = 2_100) throws -> SM64ObjectID {
        try giantPole.spawnPole(in: engineState, position: position, hitboxHeight: hitboxHeight)
    }

    @discardableResult
    func spawnKoopaFlag(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, hitboxHeight: Float = 700) throws -> SM64ObjectID {
        try koopaFlag.spawn(in: engineState, position: position, hitboxHeight: hitboxHeight)
    }

    @discardableResult
    func spawnKoopaRaceEndpoint(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try koopaRaceEndpoint.spawn(in: engineState, position: position)
    }

    @discardableResult
    func spawnPoleGrabbing(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, hitboxHeight: Float = 1_500) throws -> SM64ObjectID {
        try koopaFlag.spawn(in: engineState, position: position, hitboxHeight: hitboxHeight, behaviorIdentity: SM64KoopaFlagObjectBridge.poleGrabbingBehaviorIdentity)
    }

    @discardableResult
    func spawnTree(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, hitboxHeight: Float = 500) throws -> SM64ObjectID {
        try koopaFlag.spawn(in: engineState, position: position, hitboxHeight: hitboxHeight, behaviorIdentity: SM64KoopaFlagObjectBridge.treeBehaviorIdentity)
    }

    @discardableResult
    func spawnEndPeach(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try endCutsceneActor.spawnPeach(in: engineState, position: position)
    }

    @discardableResult
    func spawnEndToad(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try endCutsceneActor.spawnToad(in: engineState, position: position)
    }

    @discardableResult
    func spawnEndBirds1(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try endBirds.spawnBirds1(in: engineState, position: position)
    }

    @discardableResult
    func spawnEndBirds2(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, targetPosition: SM64ObjectVector3 = .init(x: 0, y: 0, z: 14_000)) throws -> SM64ObjectID {
        try endBirds.spawnBirds2(in: engineState, position: position, targetPosition: targetPosition)
    }

    @discardableResult
    func spawnBeginningPeach(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, cameraTargetPosition: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try beginningPeach.spawnPeach(in: engineState, position: position, cameraTargetPosition: cameraTargetPosition)
    }

    @discardableResult
    func spawnBub(in engineState: SM64SwiftEngineState, parent: SM64ObjectID? = nil, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try bub.spawnBub(in: engineState, parent: parent, position: position)
    }

    @discardableResult
    func spawnButterfly(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try butterfly.spawnButterfly(in: engineState, position: position)
    }

    @discardableResult
    func spawnTiltingPyramid(in engineState: SM64SwiftEngineState, variant: SM64TiltingPyramidVariant = .bitfs, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try tiltingPyramid.spawn(in: engineState, variant: variant, position: position)
    }

    @discardableResult
    func spawnBookendSpawner(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try bookend.spawnSpawner(in: engineState, position: position)
    }

    @discardableResult
    func spawnBookSwitch(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, behaviorParam: Int32 = 0) throws -> SM64ObjectID {
        try bookSwitch.spawnSwitch(in: engineState, position: position, behaviorParam: behaviorParam)
    }

    @discardableResult
    func spawnHauntedBookshelf(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try hauntedBookshelf.spawnBookshelf(in: engineState, position: position)
    }

    @discardableResult
    func spawnHauntedBookshelfManager(in engineState: SM64SwiftEngineState, shelf: SM64ObjectID? = nil, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try hauntedBookshelfManager.spawnManager(in: engineState, shelf: shelf, position: position)
    }

    @discardableResult
    func spawnHauntedChair(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, hasPianoParent: Bool = false) throws -> SM64ObjectID {
        try hauntedChair.spawnChair(in: engineState, position: position, hasPianoParent: hasPianoParent)
    }

    @discardableResult
    func spawnFishGroup(in engineState: SM64SwiftEngineState, variant: SM64FishVariant = .blue20, position: SM64ObjectVector3 = .zero, distanceToMario: Float = 10_000) throws -> SM64ObjectID {
        try fish.spawnGroup(in: engineState, variant: variant, position: position, distanceToMario: distanceToMario)
    }

    @discardableResult
    func spawnCannonBarrel(in engineState: SM64SwiftEngineState, parent: SM64ObjectID, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try cannonBarrel.spawnBarrel(in: engineState, parent: parent, position: position)
    }

    @discardableResult
    func spawnCannon(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, behaviorByte: Int32 = 0) throws -> SM64ObjectID {
        try cannon.spawnCannon(in: engineState, position: position, behaviorByte: behaviorByte)
    }

    @discardableResult
    func spawnMerryGoRoundBooManager(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try merryGoRoundBooManager.spawnManager(in: engineState, position: position)
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
        bomp.beginExternalTick()
        thwomp.beginExternalTick()
        boulder.beginExternalTick()
        horizontalGrindel.beginExternalTick()
        unusedParticleSpawn.beginExternalTick()
        snowmanCheckpoint.beginExternalTick()
        bowserBodyAnchor.beginExternalTick()
        bowserTailAnchor.beginExternalTick()
        snowmanHead.beginExternalTick()
        betaChest.beginExternalTick()
        betaTrampoline.beginExternalTick()
        betaHoldable.beginExternalTick()
        seaweed.beginExternalTick()
        shipPart3.beginExternalTick()
        sunkenShipPart.beginExternalTick()
        jrbSlidingBox.beginExternalTick()
        fallingPillar.beginExternalTick()
        coffin.beginExternalTick()
        blueFish.beginExternalTick()
        clamShell.beginExternalTick()
        bobombAnchorMario.beginExternalTick()
        bub.beginExternalTick()
        bubba.beginExternalTick()
        bowlingBall.beginExternalTick()
        dddPole.beginExternalTick()
        donutPlatform.beginExternalTick()
        courtyardBooTriplet.beginExternalTick()
        fallingBowserPlatform.beginExternalTick()
        giantPole.beginExternalTick()
        koopaFlag.beginExternalTick()
        koopaRaceEndpoint.beginExternalTick()
        wfBreakableWall.beginExternalTick()
        unusedPoundablePlatform.beginExternalTick()
        yellowBackgroundMenu.beginExternalTick()
        snowMound.beginExternalTick()
        rrCruiserWing.beginExternalTick()
        spindrift.beginExternalTick()
        spindel.beginExternalTick()
        rrRotatingBridgePlatform.beginExternalTick()
        snowmanWind.beginExternalTick()
        mrBlizzardSnowball.beginExternalTick()
        endCutsceneActor.beginExternalTick()
        endBirds.beginExternalTick()
        beginningPeach.beginExternalTick()
        butterfly.beginExternalTick()
        tiltingPyramid.beginExternalTick()
        bookend.beginExternalTick()
        bookSwitch.beginExternalTick()
        hauntedBookshelf.beginExternalTick()
        hauntedBookshelfManager.beginExternalTick()
        hauntedChair.beginExternalTick()
        fish.beginExternalTick()
        cannonBarrel.beginExternalTick()
        cannon.beginExternalTick()
        merryGoRoundBooManager.beginExternalTick()
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
        arrowLift.beginExternalTick()
        seesawPlatform.beginExternalTick()
        swingPlatform.beginExternalTick()
        rotatingPlatform.beginExternalTick()
        ttcMovingBar.beginExternalTick()
        ttcSpinner.beginExternalTick()
        ttcTreadmill.beginExternalTick()
        ttcPendulum.beginExternalTick()
        ttcElevator.beginExternalTick()
        ttcRotatingSolid.beginExternalTick()
        ttc2DRotator.beginExternalTick()
        ttcCog.beginExternalTick()
        pyramidElevator.beginExternalTick()
        pyramidTopFragment.beginExternalTick()
        pyramidPillarTouchDetector.beginExternalTick()
        pyramidTop.beginExternalTick()
        ttcPitBlock.beginExternalTick()
        staticCheckeredPlatform.beginExternalTick()
        bbhTiltingTrapPlatform.beginExternalTick()
        lllSinkingPlatform.beginExternalTick()
        wfRotatingWoodenPlatform.beginExternalTick()
        rotatingOctagonalPlatform.beginExternalTick()
        wfSolidTowerPlatform.beginExternalTick()
        wfTowerPlatform.beginExternalTick()
        trackBall.beginExternalTick()
        wfSlidingPlatform.beginExternalTick()
        wdwExpressElevator.beginExternalTick()
        lllSinkingRockBlock.beginExternalTick()
        volcanoFallingTrap.beginExternalTick()
        lllMovingOctagonalMesh.beginExternalTick()
        ferrisWheel.beginExternalTick()
        checkerboardPlatform.beginExternalTick()
        wfTowerPlatformGroup.beginExternalTick()
        lllRotatingHexagonalPlatform.beginExternalTick()
        lllRotatingHexFlame.beginExternalTick()
        lllRotatingFireBar.beginExternalTick()
        activatedBackAndForthPlatform.beginExternalTick()
        bitfsSinkingPlatform.beginExternalTick()
        dddMovingPole.beginExternalTick()
        lllRotatingHexagonalRing.beginExternalTick()
        lllWoodPiece.beginExternalTick()
        lllFloatingWoodBridge.beginExternalTick()
        squishablePlatform.beginExternalTick()
        lllDrawbridge.beginExternalTick()
        idleWaterWave.beginExternalTick()
        waterfallSoundLoop.beginExternalTick()
        volcanoSoundLoop.beginExternalTick()
        tumblingBridge.beginExternalTick()
        floatingPlatform.beginExternalTick()
        jrbFloatingBox.beginExternalTick()
        slidingPlatform2.beginExternalTick()
        smallWaterWave.beginExternalTick()
        ambientSoundLoop.beginExternalTick()
        rotatingExclamationMark.beginExternalTick()
        waterAirBubble.beginExternalTick()
        objectBubble.beginExternalTick()
        waterDroplet.beginExternalTick()
        waterMist.beginExternalTick()
        waterMist2.beginExternalTick()
        waterSplash.beginExternalTick()
        bubbleMaybe.beginExternalTick()
        wind.beginExternalTick()
        jetStream.beginExternalTick()
        jetStreamWaterRing.beginExternalTick()
        jetStreamRingSpawner.beginExternalTick()
        mantaRayWaterRing.beginExternalTick()
        whirlpool.beginExternalTick()
        mantaRay.beginExternalTick()
        shallowWaterWave.beginExternalTick()
        waterSplashSpawner.beginExternalTick()
        bubbleParticleSpawner.beginExternalTick()
        piranhaPlantWakingBubble.beginExternalTick()
        piranhaPlantBubble.beginExternalTick()
        waveTrail.beginExternalTick()
        ukiki.beginExternalTick()
        ukikiCage.beginExternalTick()
        mips.beginExternalTick()
        toadMessage.beginExternalTick()
        menuButton.beginExternalTick()
        squarishPathMoving.beginExternalTick()
        pushableMetalBox.beginExternalTick()
        tiltingBowserLavaPlatform.beginExternalTick()
        lllBowserPuzzle.beginExternalTick()
        strongWindParticle.beginExternalTick()
        waterParticle.beginExternalTick()
        plungeBubble.beginExternalTick()
        breathParticleSpawner.beginExternalTick()
        mistParticle.beginExternalTick()
        mistParticleSpawner.beginExternalTick()
        tweesterSandParticle.beginExternalTick()
        blackSmokeMario.beginExternalTick()
        flameMario.beginExternalTick()
        blackSmokeBowser.beginExternalTick()
        blackSmokeUpward.beginExternalTick()
        whitePuffSmoke.beginExternalTick()
        whitePuffSmoke2.beginExternalTick()
        whitePuffExplosion.beginExternalTick()
        dustSmoke.beginExternalTick()
        starKeyPuffSpawner.beginExternalTick()
        staticFlame.beginExternalTick()
        flamethrowerFlame.beginExternalTick()
        flameBouncing.beginExternalTick()
        bowserFlame.beginExternalTick()
        blueFlamesGroup.beginExternalTick()
        flameFloatingLanding.beginExternalTick()
        blueBowserFlame.beginExternalTick()
        volcanoFlames.beginExternalTick()
        koopaShellFlame.beginExternalTick()
        flameMovingForwardGrowing.beginExternalTick()
        betaMovingFlames.beginExternalTick()
        bowserFlameSpawn.beginExternalTick()
        smallPiranhaFlame.beginExternalTick()
        fireSpitter.beginExternalTick()
        firePiranhaPlant.beginExternalTick()
        flamethrower.beginExternalTick()
        celebrationStarSparkle.beginExternalTick()
        celebrationStar.beginExternalTick()
        groundParticleSpawner.beginExternalTick()
        animatedTexture.beginExternalTick()
        sparkle.beginExternalTick()
        sparkleSpawner.beginExternalTick()
        ambientSounds.beginExternalTick()
        coinSparkles.beginExternalTick()
        goldenCoinSparkles.beginExternalTick()
        purpleParticle.beginExternalTick()
        tinyStarParticle.beginExternalTick()
        tinyStarParticleSpawner.beginExternalTick()
        triangleParticle.beginExternalTick()
        triangleParticleSpawner.beginExternalTick()
        treeLeaf.beginExternalTick()
        treeParticleSpawner.beginExternalTick()
        mistCircParticleSpawner.beginExternalTick()
        sparkleParticleSpawner.beginExternalTick()
        simpleAnimation.beginExternalTick()
        unusedFakeStar.beginExternalTick()
        cloudPart.beginExternalTick()
        breakBoxTriangle.beginExternalTick()
        cannonBaseUnused.beginExternalTick()
        noOp.beginExternalTick()
        cannonBarrelBubbles.beginExternalTick()
        cloud.beginExternalTick()
        warp.beginExternalTick()
        dddWarp.beginExternalTick()
        actSelector.beginExternalTick()
        actSelectorStarType.beginExternalTick()
        collectStar.beginExternalTick()
        starSpawnCoordinates.beginExternalTick()
        spawnedStar.beginExternalTick()
        unlockDoorStar.beginExternalTick()
        ccmTouchedStarSpawn.beginExternalTick()
        hiddenStar.beginExternalTick()
        castleCannonGrate.beginExternalTick()
        blueCoin.beginExternalTick()
        redCoin.beginExternalTick()
        starDoor.beginExternalTick()
        capSwitch.beginExternalTick()
        metalCap.beginExternalTick()
        vanishCap.beginExternalTick()
        wingCap.beginExternalTick()
        normalCap.beginExternalTick()
        towerDoor.beginExternalTick()
        openableGrill.beginExternalTick()
        door.beginExternalTick()
        hiddenObject.beginExternalTick()
        recoveryHeart.beginExternalTick()
        coin.beginExternalTick()
        movingCoin.beginExternalTick()
        waterLevel.beginExternalTick()
        waterPillar.beginExternalTick()
        floorSwitch.beginExternalTick()
        animatedFloorSwitch.beginExternalTick()
        hiddenOneUp.beginExternalTick()
        breakableBox.beginExternalTick()
        jumpingBox.beginExternalTick()
        kickableBoard.beginExternalTick()
        rollingLog.beginExternalTick()
        toxBox.beginExternalTick()
        sslMovingPyramidWall.beginExternalTick()
        thiIslandTop.beginExternalTick()
        elevator.beginExternalTick()

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
            case .bomp:
                if record.behaviorIdentity == SM64SpindriftObjectBridge.defaultBehaviorIdentity {
                    _ = self.spindrift.updateInline(id, state: engineState)
                } else if record.behaviorIdentity == SM64MrBlizzardSnowballObjectBridge.defaultBehaviorIdentity {
                    _ = self.mrBlizzardSnowball.updateInline(id, state: engineState)
                } else {
                    _ = self.bomp.updateInline(id, state: engineState)
                }
            case .thwomp:
                _ = self.thwomp.updateInline(id, state: engineState)
            case .boulder:
                _ = self.boulder.updateInline(id, state: engineState)
            case .horizontalGrindel:
                _ = self.horizontalGrindel.updateInline(id, state: engineState)
            case .unusedParticleSpawn:
                _ = self.unusedParticleSpawn.updateInline(id, state: engineState)
            case .snowmanCheckpoint:
                _ = self.snowmanCheckpoint.updateInline(id, state: engineState)
            case .snowmanHead:
                _ = self.snowmanHead.updateInline(id, state: engineState)
            case .madPiano:
                _ = self.madPiano.updateInline(id, state: engineState)
            case .bowserBodyAnchor:
                _ = self.bowserBodyAnchor.updateInline(id, state: engineState)
            case .bowserTailAnchor:
                _ = self.bowserTailAnchor.updateInline(id, state: engineState)
            case .betaChest:
                _ = self.betaChest.updateInline(id, state: engineState)
            case .betaTrampoline:
                _ = self.betaTrampoline.updateInline(id, state: engineState)
            case .betaHoldable:
                _ = self.betaHoldable.updateInline(id, state: engineState)
            case .seaweed:
                _ = self.seaweed.updateInline(id, state: engineState)
            case .shipPart3:
                if record.behaviorIdentity == SM64SunkenShipPartObjectBridge.defaultBehaviorIdentity {
                    _ = self.sunkenShipPart.updateInline(id, state: engineState)
                } else if record.behaviorIdentity == SM64JrbSlidingBoxObjectBridge.defaultBehaviorIdentity {
                    _ = self.jrbSlidingBox.updateInline(id, state: engineState)
                } else {
                    _ = self.shipPart3.updateInline(id, state: engineState)
                }
            case .fallingPillar:
                _ = self.fallingPillar.updateInline(id, state: engineState)
            case .coffin:
                _ = self.coffin.updateInline(id, state: engineState)
            case .blueFish:
                _ = self.blueFish.updateInline(id, state: engineState)
            case .clamShell:
                _ = self.clamShell.updateInline(id, state: engineState)
            case .bobombAnchorMario:
                _ = self.bobombAnchorMario.updateInline(id, state: engineState)
            case .bub:
                _ = self.bub.updateInline(id, state: engineState)
            case .bubba:
                _ = self.bubba.updateInline(id, state: engineState)
            case .bowlingBall:
                _ = self.bowlingBall.updateInline(id, state: engineState)
            case .dddPole:
                _ = self.dddPole.updateInline(id, state: engineState)
            case .donutPlatform:
                _ = self.donutPlatform.updateInline(id, state: engineState)
            case .courtyardBooTriplet:
                _ = self.courtyardBooTriplet.updateInline(id, state: engineState)
            case .fallingBowserPlatform:
                _ = self.fallingBowserPlatform.updateInline(id, state: engineState)
            case .giantPole:
                if record.behaviorIdentity == SM64KoopaRaceEndpointObjectBridge.defaultBehaviorIdentity {
                    _ = self.koopaRaceEndpoint.updateInline(id, state: engineState)
                } else if record.behaviorIdentity == SM64KoopaFlagObjectBridge.defaultBehaviorIdentity
                    || record.behaviorIdentity == SM64KoopaFlagObjectBridge.poleGrabbingBehaviorIdentity
                    || record.behaviorIdentity == SM64KoopaFlagObjectBridge.treeBehaviorIdentity {
                    _ = self.koopaFlag.updateInline(id, state: engineState)
                } else {
                    _ = self.giantPole.updateInline(id, state: engineState)
                }
            case .endCutsceneActor:
                if record.behaviorIdentity == SM64EndBirdsObjectBridge.birds1BehaviorIdentity || record.behaviorIdentity == SM64EndBirdsObjectBridge.birds2BehaviorIdentity {
                    _ = self.endBirds.updateInline(id, state: engineState)
                } else if record.behaviorIdentity == SM64BeginningPeachObjectBridge.defaultBehaviorIdentity {
                    _ = self.beginningPeach.updateInline(id, state: engineState)
                } else {
                    _ = self.endCutsceneActor.updateInline(id, state: engineState)
                }
            case .butterfly:
                _ = self.butterfly.updateInline(id, state: engineState)
            case .tiltingPyramid:
                _ = self.tiltingPyramid.updateInline(id, state: engineState)
            case .bookend:
                _ = self.bookend.updateInline(id, state: engineState)
            case .bookSwitch:
                if record.behaviorIdentity == SM64HauntedBookshelfObjectBridge.defaultBehaviorIdentity {
                    _ = self.hauntedBookshelf.updateInline(id, state: engineState)
                } else if record.behaviorIdentity == SM64HauntedBookshelfManagerObjectBridge.defaultBehaviorIdentity {
                    _ = self.hauntedBookshelfManager.updateInline(id, state: engineState)
                } else if record.behaviorIdentity == SM64HauntedChairObjectBridge.defaultBehaviorIdentity {
                    _ = self.hauntedChair.updateInline(id, state: engineState)
                } else {
                    _ = self.bookSwitch.updateInline(id, state: engineState)
                }
            case .fish:
                _ = self.fish.updateInline(id, state: engineState)
            case .cannonBarrel:
                _ = self.cannonBarrel.updateInline(id, state: engineState)
            case .cannon:
                _ = self.cannon.updateInline(id, state: engineState)
            case .merryGoRoundBooManager:
                _ = self.merryGoRoundBooManager.updateInline(id, state: engineState)
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
            case .arrowLift:
                _ = self.arrowLift.updateInline(id, pool: pool)
            case .elevator:
                _ = self.elevator.updateInline(id, state: engineState)
            case .seesawPlatform:
                _ = self.seesawPlatform.updateInline(id, state: engineState)
            case .swingPlatform:
                _ = self.swingPlatform.updateInline(id, state: engineState)
            case .rotatingPlatform:
                _ = self.rotatingPlatform.updateInline(id, state: engineState)
            case .ttcMovingBar:
                _ = self.ttcMovingBar.updateInline(id, state: engineState)
            case .ttcSpinner:
                _ = self.ttcSpinner.updateInline(id, state: engineState)
            case .ttcTreadmill:
                _ = self.ttcTreadmill.updateInline(id, state: engineState)
            case .ttcPendulum:
                _ = self.ttcPendulum.updateInline(id, state: engineState)
            case .ttcElevator:
                _ = self.ttcElevator.updateInline(id, state: engineState)
            case .ttcRotatingSolid:
                _ = self.ttcRotatingSolid.updateInline(id, state: engineState)
            case .ttc2DRotator:
                _ = self.ttc2DRotator.updateInline(id, state: engineState)
            case .ttcCog:
                _ = self.ttcCog.updateInline(id, state: engineState)
            case .pyramidElevator:
                if record.behaviorIdentity == SM64PyramidTopObjectBridge.defaultBehaviorIdentity {
                    _ = self.pyramidTop.updateInline(id, state: engineState)
                } else if record.behaviorIdentity == SM64PyramidPillarTouchDetectorObjectBridge.defaultBehaviorIdentity {
                    _ = self.pyramidPillarTouchDetector.updateInline(id, state: engineState)
                } else if record.behaviorIdentity == SM64PyramidTopFragmentObjectBridge.defaultBehaviorIdentity {
                    _ = self.pyramidTopFragment.updateInline(id, state: engineState)
                } else {
                    _ = self.pyramidElevator.updateElevator(id, state: engineState)
                }
            case .pyramidMarker:
                _ = self.pyramidElevator.updateMarker(id, state: engineState)
            case .ttcPitBlock:
                _ = self.ttcPitBlock.updateInline(id, state: engineState)
            case .squarishPathMoving:
                _ = self.squarishPathMoving.updateInline(id, state: engineState)
            case .pushableMetalBox:
                _ = self.pushableMetalBox.updateInline(id, state: engineState)
            case .tiltingBowserLavaPlatform:
                _ = self.tiltingBowserLavaPlatform.updateInline(id, state: engineState)
            case .lllBowserPuzzle:
                _ = self.lllBowserPuzzle.updateInline(id, state: engineState)
            case .staticCheckeredPlatform:
                _ = self.staticCheckeredPlatform.updateInline(id, state: engineState)
            case .bbhTiltingTrapPlatform:
                _ = self.bbhTiltingTrapPlatform.updateInline(id, state: engineState)
            case .lllSinkingPlatform:
                _ = self.lllSinkingPlatform.updateInline(id, state: engineState)
            case .wfRotatingWoodenPlatform:
                _ = self.wfRotatingWoodenPlatform.updateInline(id, state: engineState)
            case .rotatingOctagonalPlatform:
                _ = self.rotatingOctagonalPlatform.updateInline(id, state: engineState)
            case .wfSolidTowerPlatform:
                _ = self.wfSolidTowerPlatform.updateInline(id, state: engineState)
            case .wfTowerPlatform:
                if record.behaviorIdentity == SM64TrackBallObjectBridge.defaultBehaviorIdentity {
                    _ = self.trackBall.updateInline(id, state: engineState)
                } else {
                    _ = self.wfTowerPlatform.updateInline(id, state: engineState)
                }
            case .wfSlidingPlatform:
                _ = self.wfSlidingPlatform.updateInline(id, state: engineState)
            case .wdwExpressElevator:
                _ = self.wdwExpressElevator.updateInline(id, state: engineState)
            case .lllSinkingRockBlock:
                if record.behaviorIdentity == SM64VolcanoFallingTrapObjectBridge.defaultBehaviorIdentity {
                    _ = self.volcanoFallingTrap.updateInline(id, state: engineState)
                } else if record.behaviorIdentity == SM64RollingLogObjectBridge.ttmBehaviorIdentity
                    || record.behaviorIdentity == SM64RollingLogObjectBridge.lllBehaviorIdentity {
                    _ = self.rollingLog.updateInline(id, state: engineState)
                } else if record.behaviorIdentity == SM64SslMovingPyramidWallObjectBridge.defaultBehaviorIdentity {
                    _ = self.sslMovingPyramidWall.updateInline(id, state: engineState)
                } else {
                    _ = self.lllSinkingRockBlock.updateInline(id, state: engineState)
                }
            case .lllMovingOctagonalMesh:
                _ = self.lllMovingOctagonalMesh.updateInline(id, state: engineState)
            case .ferrisWheel:
                _ = self.ferrisWheel.updateInline(id, state: engineState)
            case .checkerboardPlatform:
                _ = self.checkerboardPlatform.updateInline(id, state: engineState)
            case .wfTowerPlatformGroup:
                _ = self.wfTowerPlatformGroup.updateInline(id, state: engineState)
            case .lllRotatingHexagonalPlatform:
                _ = self.lllRotatingHexagonalPlatform.updateInline(id, state: engineState)
            case .lllRotatingHexFlame:
                _ = self.lllRotatingHexFlame.updateInline(id, state: engineState)
            case .lllRotatingFireBar:
                _ = self.lllRotatingFireBar.updateInline(id, state: engineState)
            case .activatedBackAndForthPlatform:
                _ = self.activatedBackAndForthPlatform.updateInline(id, state: engineState)
            case .bitfsSinkingPlatform:
                _ = self.bitfsSinkingPlatform.updateInline(id, state: engineState)
            case .dddMovingPole:
                _ = self.dddMovingPole.updateInline(id, state: engineState)
            case .lllRotatingHexagonalRing:
                _ = self.lllRotatingHexagonalRing.updateInline(id, state: engineState)
            case .lllFloatingWoodBridge:
                _ = self.lllFloatingWoodBridge.updateInline(id, state: engineState)
                _ = self.lllWoodPiece.updateInline(id, state: engineState)
            case .squishablePlatform:
                _ = self.squishablePlatform.updateInline(id, state: engineState)
            case .lllDrawbridge:
                switch record.behaviorIdentity {
                case SM64LllDrawbridgeObjectBridge.spawnerBehaviorIdentity:
                    _ = self.lllDrawbridge.updateSpawnerInline(id, state: engineState)
                case SM64LllDrawbridgeObjectBridge.drawbridgeBehaviorIdentity:
                    _ = self.lllDrawbridge.updateInline(id, state: engineState)
                default:
                    break
                }
            case .idleWaterWave:
                _ = self.idleWaterWave.updateInline(id, state: engineState)
            case .waterfallSoundLoop:
                _ = self.waterfallSoundLoop.updateInline(id, state: engineState)
            case .volcanoSoundLoop:
                _ = self.volcanoSoundLoop.updateInline(id, state: engineState)
            case .tumblingBridge:
                if record.behaviorIdentity == SM64RrCruiserWingObjectBridge.defaultBehaviorIdentity {
                    _ = self.rrCruiserWing.updateInline(id, state: engineState)
                } else if record.behaviorIdentity == SM64SpindelObjectBridge.defaultBehaviorIdentity {
                    _ = self.spindel.updateInline(id, state: engineState)
                } else if record.behaviorIdentity == SM64TumblingBridgeObjectBridge.platformBehaviorIdentity {
                    _ = self.tumblingBridge.updatePlatformInline(id, state: engineState)
                } else {
                    _ = self.tumblingBridge.updateParentInline(id, state: engineState)
                }
            case .floatingPlatform:
                if record.behaviorIdentity == SM64JrbFloatingBoxObjectBridge.defaultBehaviorIdentity {
                    _ = self.jrbFloatingBox.updateInline(id, state: engineState)
                } else if record.behaviorIdentity == SM64SnowMoundObjectBridge.slidingBehaviorIdentity
                    || record.behaviorIdentity == SM64SnowMoundObjectBridge.spawnerBehaviorIdentity {
                    _ = self.snowMound.updateInline(id, state: engineState)
                } else {
                    _ = self.floatingPlatform.updateInline(id, state: engineState)
                }
            case .slidingPlatform2:
                _ = self.slidingPlatform2.updateInline(id, state: engineState)
            case .smallWaterWave:
                _ = self.smallWaterWave.updateInline(id, state: engineState)
            case .ambientSoundLoop:
                _ = self.ambientSoundLoop.updateInline(id, state: engineState)
            case .rotatingExclamationMark:
                _ = self.rotatingExclamationMark.updateInline(id, state: engineState)
            case .waterAirBubble:
                _ = self.waterAirBubble.updateInline(id, state: engineState)
            case .objectBubble:
                _ = self.objectBubble.updateInline(id, state: engineState)
            case .waterDroplet:
                _ = self.waterDroplet.updateInline(id, state: engineState)
            case .waterMist:
                _ = self.waterMist.updateInline(id, state: engineState)
            case .waterMist2:
                _ = self.waterMist2.updateInline(id, state: engineState)
            case .waterSplash:
                _ = self.waterSplash.updateInline(id, state: engineState)
            case .bubbleMaybe:
                _ = self.bubbleMaybe.updateInline(id, state: engineState)
            case .wind:
                if record.behaviorIdentity == SM64JetStreamObjectBridge.defaultBehaviorIdentity {
                    _ = self.jetStream.updateInline(id, state: engineState)
                } else if record.behaviorIdentity == SM64JetStreamWaterRingObjectBridge.defaultBehaviorIdentity {
                    _ = self.jetStreamWaterRing.updateInline(id, state: engineState)
                } else if record.behaviorIdentity == SM64JetStreamRingSpawnerObjectBridge.defaultBehaviorIdentity {
                    _ = self.jetStreamRingSpawner.updateInline(id, state: engineState)
                } else if record.behaviorIdentity == SM64MantaRayWaterRingObjectBridge.defaultBehaviorIdentity {
                    _ = self.mantaRayWaterRing.updateInline(id, state: engineState)
                } else if record.behaviorIdentity == SM64WhirlpoolObjectBridge.defaultBehaviorIdentity {
                    _ = self.whirlpool.updateInline(id, state: engineState)
                } else if record.behaviorIdentity == SM64MantaRayObjectBridge.defaultBehaviorIdentity {
                    _ = self.mantaRay.updateInline(id, state: engineState)
                } else if record.behaviorIdentity == SM64SnowmanWindObjectBridge.defaultBehaviorIdentity {
                    _ = self.snowmanWind.updateInline(id, state: engineState)
                } else {
                    _ = self.wind.updateInline(id, state: engineState)
                }
            case .shallowWaterWave:
                _ = self.shallowWaterWave.updateInline(id, state: engineState)
            case .waterSplashSpawner:
                _ = self.waterSplashSpawner.updateInline(id, state: engineState)
            case .bubbleParticleSpawner:
                _ = self.bubbleParticleSpawner.updateInline(id, state: engineState)
            case .piranhaPlantWakingBubble:
                _ = self.piranhaPlantWakingBubble.updateInline(id, state: engineState)
            case .piranhaPlantBubble:
                _ = self.piranhaPlantBubble.updateInline(id, state: engineState)
            case .waveTrail:
                _ = self.waveTrail.updateInline(id, state: engineState)
            case .sushiShark:
                if self.sushiShark.updateInline(id, state: engineState),
                   let effect = self.sushiShark.effectLog.last,
                   effect.objectID == id,
                   effect.output.spawnWaveTrail {
                    _ = try? self.waveTrail.spawnTrail(
                        in: engineState,
                        kind: .object,
                        position: effect.output.position,
                        waterLevel: self.sushiWaterLevels[id] ?? 100,
                        globalFrame: engineState.globals.frame,
                        initialScale: 4,
                        parent: id
                    )
                }
            case .ukiki:
                _ = self.ukiki.updateInline(id, state: engineState)
            case .ukikiCage:
                _ = self.ukikiCage.updateInline(id, state: engineState)
            case .mips:
                _ = self.mips.updateInline(id, state: engineState)
            case .toadMessage:
                _ = self.toadMessage.updateInline(id, state: engineState)
            case .menuButton:
                _ = self.menuButton.updateInline(id, state: engineState)
            case .strongWindParticle:
                _ = self.strongWindParticle.updateInline(id, state: engineState)
            case .waterParticle:
                _ = self.waterParticle.updateInline(id, state: engineState)
            case .plungeBubble:
                _ = self.plungeBubble.updateInline(id, state: engineState)
            case .breathParticleSpawner:
                _ = self.breathParticleSpawner.updateInline(id, state: engineState)
            case .mistParticle:
                _ = self.mistParticle.updateInline(id, state: engineState)
            case .mistParticleSpawner:
                _ = self.mistParticleSpawner.updateInline(id, state: engineState)
            case .tweesterSandParticle:
                _ = self.tweesterSandParticle.updateInline(id, state: engineState)
            case .blackSmokeMario:
                _ = self.blackSmokeMario.updateInline(id, state: engineState)
            case .flameMario:
                _ = self.flameMario.updateInline(id, state: engineState)
            case .blackSmokeBowser:
                _ = self.blackSmokeBowser.updateInline(id, state: engineState)
            case .blackSmokeUpward:
                _ = self.blackSmokeUpward.updateInline(id, state: engineState)
            case .whitePuffSmoke:
                _ = self.whitePuffSmoke.updateInline(id, state: engineState)
            case .whitePuffSmoke2:
                _ = self.whitePuffSmoke2.updateInline(id, state: engineState)
            case .whitePuffExplosion:
                _ = self.whitePuffExplosion.updateInline(id, state: engineState)
            case .dustSmoke:
                _ = self.dustSmoke.updateInline(id, state: engineState)
            case .starKeyPuffSpawner:
                _ = self.starKeyPuffSpawner.updateInline(id, state: engineState)
            case .staticFlame:
                _ = self.staticFlame.updateInline(id, state: engineState)
            case .flamethrowerFlame:
                _ = self.flamethrowerFlame.updateInline(id, state: engineState)
            case .flameBouncing:
                _ = self.flameBouncing.updateInline(id, state: engineState)
            case .flameBowser, .flameLargeBurningOut:
                _ = self.bowserFlame.updateInline(id, state: engineState)
            case .blueFlamesGroup:
                _ = self.blueFlamesGroup.updateInline(id, state: engineState)
            case .flameFloatingLanding:
                _ = self.flameFloatingLanding.updateInline(id, state: engineState)
            case .blueBowserFlame:
                _ = self.blueBowserFlame.updateInline(id, state: engineState)
            case .volcanoFlames:
                _ = self.volcanoFlames.updateInline(id, state: engineState)
            case .koopaShellFlame:
                _ = self.koopaShellFlame.updateInline(id, state: engineState)
            case .flameMovingForwardGrowing:
                _ = self.flameMovingForwardGrowing.updateInline(id, state: engineState)
            case .betaMovingFlamesSpawn, .betaMovingFlames:
                _ = self.betaMovingFlames.updateInline(id, state: engineState)
            case .bowserFlameSpawn:
                _ = self.bowserFlameSpawn.updateInline(id, state: engineState)
            case .smallPiranhaFlame:
                _ = self.smallPiranhaFlame.updateInline(id, state: engineState)
            case .fireSpitter:
                _ = self.fireSpitter.updateInline(id, state: engineState)
            case .firePiranhaPlant:
                _ = self.firePiranhaPlant.updateInline(id, state: engineState)
            case .flamethrower:
                if record.behaviorIdentity == SM64RrRotatingBridgePlatformObjectBridge.defaultBehaviorIdentity {
                    _ = self.rrRotatingBridgePlatform.updateInline(id, state: engineState)
                } else {
                    _ = self.flamethrower.updateInline(id, state: engineState)
                }
            case .celebrationStarSparkle:
                _ = self.celebrationStarSparkle.updateInline(id, state: engineState)
            case .celebrationStar:
                _ = self.celebrationStar.updateInline(id, state: engineState)
            case .warp:
                _ = self.warp.updateInline(id, state: engineState)
            case .dddWarp:
                _ = self.dddWarp.updateInline(id, state: engineState)
            case .actSelectorStarType:
                _ = self.actSelectorStarType.updateInline(id, state: engineState)
            case .actSelector:
                _ = self.actSelector.updateInline(id, state: engineState)
            case .collectStar:
                _ = self.collectStar.updateInline(id, state: engineState)
            case .starSpawnCoordinates:
                _ = self.starSpawnCoordinates.updateInline(id, state: engineState)
            case .spawnedStar, .spawnedStarNoLevelExit:
                if record.behaviorIdentity == SM64UnlockDoorStarObjectBridge.defaultBehaviorIdentity {
                    _ = self.unlockDoorStar.updateInline(id, state: engineState)
                } else {
                    _ = self.spawnedStar.updateInline(id, state: engineState)
                }
            case .ccmTouchedStarSpawn:
                _ = self.ccmTouchedStarSpawn.updateInline(id, state: engineState)
            case .hiddenStar, .hiddenStarTrigger:
                _ = self.hiddenStar.updateInline(id, state: engineState)
            case .castleCannonGrate:
                _ = self.castleCannonGrate.updateInline(id, state: engineState)
            case .blueCoinSwitch, .hiddenBlueCoin:
                _ = self.blueCoin.updateInline(id, state: engineState)
            case .hiddenRedCoinStar, .redCoinStarMarker, .redCoin:
                _ = self.redCoin.updateInline(id, state: engineState)
            case .starDoor:
                _ = self.starDoor.updateInline(id, state: engineState)
            case .capSwitch, .capSwitchBase:
                if record.behaviorIdentity == SM64MetalCapObjectBridge.defaultBehaviorIdentity {
                    _ = self.metalCap.updateInline(id, state: engineState)
                } else if record.behaviorIdentity == SM64VanishCapObjectBridge.defaultBehaviorIdentity {
                    _ = self.vanishCap.updateInline(id, state: engineState)
                } else if record.behaviorIdentity == SM64WingCapObjectBridge.defaultBehaviorIdentity {
                    _ = self.wingCap.updateInline(id, state: engineState)
                } else if record.behaviorIdentity == SM64NormalCapObjectBridge.defaultBehaviorIdentity {
                    _ = self.normalCap.updateInline(id, state: engineState)
                } else {
                    _ = self.capSwitch.updateInline(id, state: engineState)
                }
            case .towerDoor:
                _ = self.towerDoor.updateInline(id, state: engineState)
            case .openableGrill, .openableCageDoor:
                _ = self.openableGrill.updateInline(id, state: engineState)
            case .door:
                _ = self.door.updateInline(id, state: engineState)
            case .hiddenObject:
                _ = self.hiddenObject.updateInline(id, state: engineState)
            case .recoveryHeart:
                _ = self.recoveryHeart.updateInline(id, state: engineState)
            case .coin:
                _ = self.coin.updateInline(id, state: engineState)
            case .movingCoin:
                _ = self.movingCoin.updateInline(id, state: engineState)
            case .waterLevelDiamond, .changingWaterLevel:
                _ = self.waterLevel.updateInline(id, state: engineState)
            case .waterPillar:
                _ = self.waterPillar.updateInline(id, state: engineState)
            case .floorSwitch:
                _ = self.floorSwitch.updateInline(id, state: engineState)
            case .animatedFloorSwitch:
                _ = self.animatedFloorSwitch.updateInline(id, state: engineState)
            case .hiddenOneUp:
                _ = self.hiddenOneUp.updateInline(id, state: engineState)
            case .breakableBox:
                if record.behaviorIdentity == SM64JumpingBoxObjectBridge.defaultBehaviorIdentity {
                    _ = self.jumpingBox.updateInline(id, state: engineState)
                } else if record.behaviorIdentity == SM64KickableBoardObjectBridge.defaultBehaviorIdentity {
                    _ = self.kickableBoard.updateInline(id, state: engineState)
                } else if record.behaviorIdentity == SM64WfBreakableWallObjectBridge.leftBehaviorIdentity
                    || record.behaviorIdentity == SM64WfBreakableWallObjectBridge.rightBehaviorIdentity {
                    _ = self.wfBreakableWall.updateInline(id, state: engineState)
                } else if record.behaviorIdentity == SM64UnusedPoundablePlatformObjectBridge.defaultBehaviorIdentity {
                    _ = self.unusedPoundablePlatform.updateInline(id, state: engineState)
                } else {
                    _ = self.breakableBox.updateInline(id, state: engineState)
                }
            case .exclamationBox:
                _ = self.exclamationBox.updateInline(id, state: engineState)
            case .orangeNumber:
                _ = self.orangeNumber.updateInline(id, state: engineState)
            case .soundSpawner:
                _ = self.soundSpawner.updateInline(id, state: engineState)
            case .rockSolid:
                if record.behaviorIdentity == SM64ToxBoxObjectBridge.defaultBehaviorIdentity {
                    _ = self.toxBox.updateInline(id, state: engineState)
                } else {
                    _ = self.rockSolid.updateInline(id, state: engineState)
                }
            case .environmentGate:
                if record.behaviorIdentity == SM64ThiIslandTopObjectBridge.hugeBehaviorIdentity
                    || record.behaviorIdentity == SM64ThiIslandTopObjectBridge.tinyBehaviorIdentity {
                    _ = self.thiIslandTop.updateInline(id, state: engineState)
                } else {
                    _ = self.environmentGate.updateInline(id, state: engineState)
                }
            case .clockArm:
                _ = self.clockArm.updateInline(id, state: engineState)
            case .castleFloorTrap:
                _ = self.castleFloorTrap.updateInline(id, state: engineState)
            case .castleFlag:
                _ = self.castleFlag.updateInline(id, state: engineState)
            case .booCage:
                _ = self.booCage.updateInline(id, state: engineState)
            case .booKey:
                _ = self.booKey.updateInline(id, state: engineState)
            case .booInCastle:
                _ = self.booInCastle.updateInline(id, state: engineState)
            case .merryGoRound:
                _ = self.merryGoRound.updateInline(id, state: engineState)
            case .musicTouch:
                _ = self.musicTouch.updateInline(id, state: engineState)
            case .textSurface:
                _ = self.textSurface.updateInline(id, state: engineState)
            case .grandStar:
                _ = self.grandStar.updateInline(id, state: engineState)
            case .betaBowserAnchor:
                _ = self.betaBowserAnchor.updateInline(id, state: engineState)
            case .dirtParticleSpawner, .snowParticleSpawner:
                _ = self.groundParticleSpawner.updateInline(id, state: engineState)
            case .animatedTexture:
                _ = self.animatedTexture.updateInline(id, state: engineState)
            case .sparkle:
                _ = self.sparkle.updateInline(id, state: engineState)
            case .sparkleSpawner:
                _ = self.sparkleSpawner.updateInline(id, state: engineState)
            case .ambientSounds:
                _ = self.ambientSounds.updateInline(id, state: engineState)
            case .coinSparkles:
                _ = self.coinSparkles.updateInline(id, state: engineState)
            case .goldenCoinSparkles:
                _ = self.goldenCoinSparkles.updateInline(id, state: engineState)
            case .purpleParticle:
                _ = self.purpleParticle.updateInline(id, state: engineState)
            case .wallTinyStarParticle, .poundTinyStarParticle:
                _ = self.tinyStarParticle.updateInline(id, state: engineState)
            case .vertStarParticleSpawner, .horStarParticleSpawner:
                _ = self.tinyStarParticleSpawner.updateInline(id, state: engineState)
            case .triangleParticle:
                _ = self.triangleParticle.updateInline(id, state: engineState)
            case .triangleParticleSpawner:
                _ = self.triangleParticleSpawner.updateInline(id, state: engineState)
            case .treeLeaf, .treeSnow:
                _ = self.treeLeaf.updateInline(id, state: engineState)
            case .treeParticleSpawner:
                _ = self.treeParticleSpawner.updateInline(id, state: engineState)
            case .mistCircParticleSpawner:
                _ = self.mistCircParticleSpawner.updateInline(id, state: engineState)
            case .sparkleParticleSpawner:
                _ = self.sparkleParticleSpawner.updateInline(id, state: engineState)
            case .randomAnimatedTexture, .unusedSimpleAnimation:
                _ = self.simpleAnimation.updateInline(id, state: engineState)
            case .unusedFakeStar:
                _ = self.unusedFakeStar.updateInline(id, state: engineState)
            case .cloudPart:
                _ = self.cloudPart.updateInline(id, state: engineState)
            case .breakBoxTriangle:
                _ = self.breakBoxTriangle.updateInline(id, state: engineState)
            case .cannonBaseUnused:
                _ = self.cannonBaseUnused.updateInline(id, state: engineState)
            case .noOp:
                if record.behaviorIdentity == SM64YellowBackgroundMenuObjectBridge.defaultBehaviorIdentity {
                    _ = self.yellowBackgroundMenu.updateInline(id, state: engineState)
                } else {
                    _ = self.noOp.updateInline(id, state: engineState)
                }
            case .cannonBarrelBubbles:
                _ = self.cannonBarrelBubbles.updateInline(id, state: engineState)
            case .cloud:
                _ = self.cloud.updateInline(id, state: engineState)
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
            bomp.remove(id)
            thwomp.remove(id)
            boulder.remove(id)
            horizontalGrindel.remove(id)
            unusedParticleSpawn.remove(id)
            snowmanCheckpoint.remove(id)
            snowmanHead.remove(id)
            bowserBodyAnchor.remove(id)
            bowserTailAnchor.remove(id)
            betaChest.remove(id)
            betaTrampoline.remove(id)
            betaHoldable.remove(id)
            seaweed.remove(id)
            shipPart3.remove(id)
            jrbSlidingBox.remove(id)
            fallingPillar.remove(id)
            coffin.remove(id)
            blueFish.remove(id)
            clamShell.remove(id)
            bobombAnchorMario.remove(id)
            bub.remove(id)
            bubba.remove(id)
            bowlingBall.remove(id)
            dddPole.remove(id)
            donutPlatform.remove(id)
            courtyardBooTriplet.remove(id)
            fallingBowserPlatform.remove(id)
            giantPole.remove(id)
            koopaFlag.remove(id)
            koopaRaceEndpoint.remove(id)
            wfBreakableWall.remove(id)
            unusedPoundablePlatform.remove(id)
            yellowBackgroundMenu.remove(id)
            snowMound.remove(id)
            rrCruiserWing.remove(id)
            spindrift.remove(id)
            spindel.remove(id)
            rrRotatingBridgePlatform.remove(id)
            snowmanWind.remove(id)
            mrBlizzardSnowball.remove(id)
            endCutsceneActor.remove(id)
            endBirds.remove(id)
            beginningPeach.remove(id)
            butterfly.remove(id)
            tiltingPyramid.remove(id)
            bookend.remove(id)
            bookSwitch.remove(id)
            hauntedBookshelf.remove(id)
            hauntedBookshelfManager.remove(id)
            hauntedChair.remove(id)
            fish.remove(id)
            cannonBarrel.remove(id)
            cannon.remove(id)
            merryGoRoundBooManager.remove(id)
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
            arrowLift.remove(id)
            elevator.remove(id)
            seesawPlatform.remove(id)
            swingPlatform.remove(id)
            rotatingPlatform.remove(id)
            ttcMovingBar.remove(id)
            ttcSpinner.remove(id)
            ttcTreadmill.remove(id)
            ttcPendulum.remove(id)
            ttcElevator.remove(id)
            ttcRotatingSolid.remove(id)
            ttc2DRotator.remove(id)
            ttcCog.remove(id)
            pyramidElevator.remove(id)
            ttcPitBlock.remove(id)
            squarishPathMoving.remove(id)
            pushableMetalBox.remove(id)
            staticCheckeredPlatform.remove(id)
            bbhTiltingTrapPlatform.remove(id)
            lllSinkingPlatform.remove(id)
            wfRotatingWoodenPlatform.remove(id)
            rotatingOctagonalPlatform.remove(id)
            wfSolidTowerPlatform.remove(id)
            wfTowerPlatform.remove(id)
            wfSlidingPlatform.remove(id)
            wdwExpressElevator.remove(id)
            lllSinkingRockBlock.remove(id)
            lllMovingOctagonalMesh.remove(id)
            ferrisWheel.remove(id)
            checkerboardPlatform.remove(id)
            wfTowerPlatformGroup.remove(id)
            lllRotatingHexagonalPlatform.remove(id)
            lllRotatingHexFlame.remove(id)
            lllRotatingFireBar.remove(id)
            activatedBackAndForthPlatform.remove(id)
            bitfsSinkingPlatform.remove(id)
            dddMovingPole.remove(id)
            lllRotatingHexagonalRing.remove(id)
            lllWoodPiece.remove(id)
            lllFloatingWoodBridge.remove(id)
            squishablePlatform.remove(id)
            lllDrawbridge.remove(id)
            idleWaterWave.remove(id)
            waterfallSoundLoop.remove(id)
            volcanoSoundLoop.remove(id)
            tumblingBridge.remove(id)
            floatingPlatform.remove(id)
            jrbFloatingBox.remove(id)
            slidingPlatform2.remove(id)
            smallWaterWave.remove(id)
            ambientSoundLoop.remove(id)
            rotatingExclamationMark.remove(id)
            waterAirBubble.remove(id)
            objectBubble.remove(id)
            waterDroplet.remove(id)
            waterMist.remove(id)
            waterMist2.remove(id)
            waterSplash.remove(id)
            bubbleMaybe.remove(id)
            wind.remove(id)
            jetStream.remove(id)
            jetStreamWaterRing.remove(id)
            jetStreamRingSpawner.remove(id)
            mantaRayWaterRing.remove(id)
            whirlpool.remove(id)
            mantaRay.remove(id)
            shallowWaterWave.remove(id)
            waterSplashSpawner.remove(id)
            bubbleParticleSpawner.remove(id)
            piranhaPlantWakingBubble.remove(id)
            piranhaPlantBubble.remove(id)
            waveTrail.remove(id)
            sushiWaterLevels.removeValue(forKey: id)
            ukiki.remove(id)
            ukikiCage.remove(id)
            mips.remove(id)
            toadMessage.remove(id)
            menuButton.remove(id)
            tiltingBowserLavaPlatform.remove(id)
            lllBowserPuzzle.remove(id)
            strongWindParticle.remove(id)
            waterParticle.remove(id)
            plungeBubble.remove(id)
            breathParticleSpawner.remove(id)
            mistParticle.remove(id)
            mistParticleSpawner.remove(id)
            tweesterSandParticle.remove(id)
            blackSmokeMario.remove(id)
            flameMario.remove(id)
            blackSmokeBowser.remove(id)
            blackSmokeUpward.remove(id)
            whitePuffSmoke.remove(id)
            whitePuffSmoke2.remove(id)
            whitePuffExplosion.remove(id)
            dustSmoke.remove(id)
            starKeyPuffSpawner.remove(id)
            staticFlame.remove(id)
            flamethrowerFlame.remove(id)
            flameBouncing.remove(id)
            bowserFlame.remove(id)
            blueFlamesGroup.remove(id)
            flameFloatingLanding.remove(id)
            blueBowserFlame.remove(id)
            volcanoFlames.remove(id)
            koopaShellFlame.remove(id)
            flameMovingForwardGrowing.remove(id)
            betaMovingFlames.remove(id)
            bowserFlameSpawn.remove(id)
            smallPiranhaFlame.remove(id)
            fireSpitter.remove(id)
            firePiranhaPlant.remove(id)
            flamethrower.remove(id)
            celebrationStarSparkle.remove(id)
            groundParticleSpawner.remove(id)
            animatedTexture.remove(id)
            sparkle.remove(id)
            sparkleSpawner.remove(id)
            ambientSounds.remove(id)
            coinSparkles.remove(id)
            goldenCoinSparkles.remove(id)
            purpleParticle.remove(id)
            tinyStarParticle.remove(id)
            tinyStarParticleSpawner.remove(id)
            triangleParticle.remove(id)
            triangleParticleSpawner.remove(id)
            treeLeaf.remove(id)
            treeParticleSpawner.remove(id)
            mistCircParticleSpawner.remove(id)
            sparkleParticleSpawner.remove(id)
            simpleAnimation.remove(id)
            unusedFakeStar.remove(id)
            cloudPart.remove(id)
            breakBoxTriangle.remove(id)
            cannonBaseUnused.remove(id)
            noOp.remove(id)
            cannonBarrelBubbles.remove(id)
            cloud.remove(id)
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
        for id in bomp.registeredIDs where engineState.objects.record(for: id) == nil {
            bomp.remove(id)
        }
        for id in thwomp.registeredIDs where engineState.objects.record(for: id) == nil {
            thwomp.remove(id)
        }
        for id in boulder.registeredIDs where engineState.objects.record(for: id) == nil {
            boulder.remove(id)
        }
        for id in horizontalGrindel.registeredIDs where engineState.objects.record(for: id) == nil {
            horizontalGrindel.remove(id)
        }
        for id in unusedParticleSpawn.registeredIDs where engineState.objects.record(for: id) == nil {
            unusedParticleSpawn.remove(id)
        }
        for id in snowmanCheckpoint.registeredIDs where engineState.objects.record(for: id) == nil {
            snowmanCheckpoint.remove(id)
        }
        for id in snowmanHead.registeredIDs where engineState.objects.record(for: id) == nil {
            snowmanHead.remove(id)
        }
        for id in bowserBodyAnchor.registeredIDs where engineState.objects.record(for: id) == nil {
            bowserBodyAnchor.remove(id)
        }
        for id in bowserTailAnchor.registeredIDs where engineState.objects.record(for: id) == nil {
            bowserTailAnchor.remove(id)
        }
        for id in betaChest.registeredIDs where engineState.objects.record(for: id) == nil {
            betaChest.remove(id)
        }
        for id in betaTrampoline.registeredIDs where engineState.objects.record(for: id) == nil {
            betaTrampoline.remove(id)
        }
        for id in betaHoldable.registeredIDs where engineState.objects.record(for: id) == nil {
            betaHoldable.remove(id)
        }
        for id in seaweed.registeredIDs where engineState.objects.record(for: id) == nil {
            seaweed.remove(id)
        }
        for id in shipPart3.registeredIDs where engineState.objects.record(for: id) == nil {
            shipPart3.remove(id)
        }
        for id in sunkenShipPart.registeredIDs where engineState.objects.record(for: id) == nil {
            sunkenShipPart.remove(id)
        }
        for id in jrbSlidingBox.registeredIDs where engineState.objects.record(for: id) == nil {
            jrbSlidingBox.remove(id)
        }
        for id in fallingPillar.registeredIDs where engineState.objects.record(for: id) == nil {
            fallingPillar.remove(id)
        }
        for id in coffin.registeredIDs where engineState.objects.record(for: id) == nil {
            coffin.remove(id)
        }
        for id in blueFish.registeredIDs where engineState.objects.record(for: id) == nil {
            blueFish.remove(id)
        }
        for id in clamShell.registeredIDs where engineState.objects.record(for: id) == nil {
            clamShell.remove(id)
        }
        for id in bobombAnchorMario.registeredIDs where engineState.objects.record(for: id) == nil {
            bobombAnchorMario.remove(id)
        }
        for id in bub.registeredIDs where engineState.objects.record(for: id) == nil {
            bub.remove(id)
        }
        for id in bubba.registeredIDs where engineState.objects.record(for: id) == nil {
            bubba.remove(id)
        }
        for id in bowlingBall.registeredIDs where engineState.objects.record(for: id) == nil {
            bowlingBall.remove(id)
        }
        for id in dddPole.registeredIDs where engineState.objects.record(for: id) == nil {
            dddPole.remove(id)
        }
        for id in donutPlatform.registeredIDs where engineState.objects.record(for: id) == nil {
            donutPlatform.remove(id)
        }
        for id in courtyardBooTriplet.registeredIDs where engineState.objects.record(for: id) == nil {
            courtyardBooTriplet.remove(id)
        }
        for id in fallingBowserPlatform.registeredIDs where engineState.objects.record(for: id) == nil {
            fallingBowserPlatform.remove(id)
        }
        for id in giantPole.registeredIDs where engineState.objects.record(for: id) == nil {
            giantPole.remove(id)
        }
        for id in koopaFlag.registeredIDs where engineState.objects.record(for: id) == nil {
            koopaFlag.remove(id)
        }
        for id in koopaRaceEndpoint.registeredIDs where engineState.objects.record(for: id) == nil {
            koopaRaceEndpoint.remove(id)
        }
        for id in wfBreakableWall.registeredIDs where engineState.objects.record(for: id) == nil {
            wfBreakableWall.remove(id)
        }
        for id in unusedPoundablePlatform.registeredIDs where engineState.objects.record(for: id) == nil {
            unusedPoundablePlatform.remove(id)
        }
        for id in yellowBackgroundMenu.registeredIDs where engineState.objects.record(for: id) == nil {
            yellowBackgroundMenu.remove(id)
        }
        for id in snowMound.registeredIDs where engineState.objects.record(for: id) == nil {
            snowMound.remove(id)
        }
        for id in rrCruiserWing.registeredIDs where engineState.objects.record(for: id) == nil {
            rrCruiserWing.remove(id)
        }
        for id in spindrift.registeredIDs where engineState.objects.record(for: id) == nil {
            spindrift.remove(id)
        }
        for id in spindel.registeredIDs where engineState.objects.record(for: id) == nil {
            spindel.remove(id)
        }
        for id in rrRotatingBridgePlatform.registeredIDs where engineState.objects.record(for: id) == nil {
            rrRotatingBridgePlatform.remove(id)
        }
        for id in snowmanWind.registeredIDs where engineState.objects.record(for: id) == nil {
            snowmanWind.remove(id)
        }
        for id in mrBlizzardSnowball.registeredIDs where engineState.objects.record(for: id) == nil {
            mrBlizzardSnowball.remove(id)
        }
        for id in endCutsceneActor.registeredIDs where engineState.objects.record(for: id) == nil {
            endCutsceneActor.remove(id)
        }
        for id in endBirds.registeredIDs where engineState.objects.record(for: id) == nil {
            endBirds.remove(id)
        }
        for id in beginningPeach.registeredIDs where engineState.objects.record(for: id) == nil {
            beginningPeach.remove(id)
        }
        for id in butterfly.registeredIDs where engineState.objects.record(for: id) == nil {
            butterfly.remove(id)
        }
        for id in tiltingPyramid.registeredIDs where engineState.objects.record(for: id) == nil {
            tiltingPyramid.remove(id)
        }
        for id in bookend.registeredIDs where engineState.objects.record(for: id) == nil {
            bookend.remove(id)
        }
        for id in bookSwitch.registeredIDs where engineState.objects.record(for: id) == nil {
            bookSwitch.remove(id)
        }
        for id in hauntedBookshelf.registeredIDs where engineState.objects.record(for: id) == nil {
            hauntedBookshelf.remove(id)
        }
        for id in hauntedBookshelfManager.registeredIDs where engineState.objects.record(for: id) == nil {
            hauntedBookshelfManager.remove(id)
        }
        for id in hauntedChair.registeredIDs where engineState.objects.record(for: id) == nil {
            hauntedChair.remove(id)
        }
        for id in fish.registeredIDs where engineState.objects.record(for: id) == nil {
            fish.remove(id)
        }
        for id in cannonBarrel.registeredIDs where engineState.objects.record(for: id) == nil {
            cannonBarrel.remove(id)
        }
        for id in cannon.registeredIDs where engineState.objects.record(for: id) == nil {
            cannon.remove(id)
        }
        for id in merryGoRoundBooManager.registeredIDs where engineState.objects.record(for: id) == nil {
            merryGoRoundBooManager.remove(id)
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
        arrowLift.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        elevator.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        seesawPlatform.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        swingPlatform.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        rotatingPlatform.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        ttcMovingBar.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        ttcSpinner.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        ttcTreadmill.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        ttcPendulum.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        ttcElevator.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        ttcRotatingSolid.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        ttc2DRotator.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        ttcCog.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        pyramidElevator.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        pyramidTopFragment.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        pyramidPillarTouchDetector.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        pyramidTop.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        ttcPitBlock.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        squarishPathMoving.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        pushableMetalBox.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        staticCheckeredPlatform.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        bbhTiltingTrapPlatform.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        lllSinkingPlatform.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        wfRotatingWoodenPlatform.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        rotatingOctagonalPlatform.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        wfSolidTowerPlatform.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        wfTowerPlatform.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        trackBall.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        wfSlidingPlatform.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        wdwExpressElevator.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        lllSinkingRockBlock.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        volcanoFallingTrap.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        rollingLog.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        lllMovingOctagonalMesh.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        ferrisWheel.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        checkerboardPlatform.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        wfTowerPlatformGroup.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        lllRotatingHexagonalPlatform.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        lllRotatingHexFlame.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        lllRotatingFireBar.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        activatedBackAndForthPlatform.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        bitfsSinkingPlatform.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        dddMovingPole.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        lllRotatingHexagonalRing.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        lllWoodPiece.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        lllFloatingWoodBridge.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        squishablePlatform.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        lllDrawbridge.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        idleWaterWave.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        waterfallSoundLoop.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        volcanoSoundLoop.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        tumblingBridge.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        floatingPlatform.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        jrbFloatingBox.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        slidingPlatform2.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        smallWaterWave.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        ambientSoundLoop.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        rotatingExclamationMark.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        waterAirBubble.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        objectBubble.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        waterDroplet.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        waterMist.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        waterMist2.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        waterSplash.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        bubbleMaybe.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        wind.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        jetStream.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        jetStreamWaterRing.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        jetStreamRingSpawner.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        mantaRayWaterRing.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        whirlpool.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        mantaRay.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        shallowWaterWave.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        waterSplashSpawner.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        bubbleParticleSpawner.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        piranhaPlantWakingBubble.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        piranhaPlantBubble.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        waveTrail.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        sushiShark.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        ukiki.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        ukikiCage.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        mips.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        toadMessage.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        menuButton.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        tiltingBowserLavaPlatform.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        lllBowserPuzzle.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        for id in Array(sushiWaterLevels.keys) where engineState.objects.record(for: id) == nil {
            sushiWaterLevels.removeValue(forKey: id)
        }
        strongWindParticle.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        waterParticle.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        plungeBubble.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        breathParticleSpawner.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        mistParticle.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        mistParticleSpawner.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        tweesterSandParticle.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        blackSmokeMario.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        flameMario.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        blackSmokeBowser.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        blackSmokeUpward.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        whitePuffSmoke.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        whitePuffSmoke2.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        whitePuffExplosion.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        dustSmoke.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        starKeyPuffSpawner.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        staticFlame.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        flamethrowerFlame.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        flameBouncing.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        bowserFlame.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        blueFlamesGroup.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        flameFloatingLanding.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        blueBowserFlame.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        volcanoFlames.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        koopaShellFlame.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        flameMovingForwardGrowing.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        betaMovingFlames.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        bowserFlameSpawn.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        smallPiranhaFlame.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        fireSpitter.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        firePiranhaPlant.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        flamethrower.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        celebrationStarSparkle.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        celebrationStar.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        warp.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        dddWarp.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        actSelector.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        actSelectorStarType.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        collectStar.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        starSpawnCoordinates.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        spawnedStar.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        unlockDoorStar.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        ccmTouchedStarSpawn.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        hiddenStar.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        castleCannonGrate.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        blueCoin.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        redCoin.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        starDoor.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        capSwitch.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        metalCap.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        vanishCap.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        wingCap.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        normalCap.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        towerDoor.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        openableGrill.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        door.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        hiddenObject.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        recoveryHeart.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        coin.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        movingCoin.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        waterLevel.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        waterPillar.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        floorSwitch.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        animatedFloorSwitch.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        hiddenOneUp.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        breakableBox.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        jumpingBox.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        kickableBoard.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        wfBreakableWall.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        unusedPoundablePlatform.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        yellowBackgroundMenu.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        snowMound.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        rrCruiserWing.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        spindrift.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        spindel.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        rrRotatingBridgePlatform.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        snowmanWind.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        mrBlizzardSnowball.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        exclamationBox.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        orangeNumber.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        soundSpawner.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        rockSolid.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        toxBox.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        sslMovingPyramidWall.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        thiIslandTop.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        environmentGate.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        clockArm.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        castleFloorTrap.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        castleFlag.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        booCage.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        booKey.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        booInCastle.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        merryGoRound.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        musicTouch.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        textSurface.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        grandStar.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        betaBowserAnchor.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        groundParticleSpawner.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        animatedTexture.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        sparkle.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        sparkleSpawner.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        ambientSounds.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        coinSparkles.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        goldenCoinSparkles.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        purpleParticle.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        tinyStarParticle.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        tinyStarParticleSpawner.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        triangleParticle.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        triangleParticleSpawner.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        treeLeaf.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        treeParticleSpawner.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        mistCircParticleSpawner.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        sparkleParticleSpawner.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        simpleAnimation.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        unusedFakeStar.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        cloudPart.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        breakBoxTriangle.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        cannonBaseUnused.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        noOp.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        cannonBarrelBubbles.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        cloud.pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)

        return SM64BehaviorDispatchTickResult(
            scheduler: schedulerResult,
            events: eventLog,
            ukikiEffects: ukiki.effectLog,
            ukikiCageEffects: ukikiCage.effectLog,
            mipsEffects: mips.effectLog,
            toadMessageEffects: toadMessage.effectLog,
            menuButtonEffects: menuButton.buttonEffectLog,
            menuButtonManagerEffects: menuButton.managerEffectLog,
            squarishPathMovingEffects: squarishPathMoving.effectLog,
            pushableMetalBoxEffects: pushableMetalBox.effectLog,
            tiltingBowserLavaPlatformEffects: tiltingBowserLavaPlatform.effectLog,
            lllBowserPuzzleEffects: lllBowserPuzzle.effectLog,
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
            bompEffects: bomp.effectLog,
            thwompEffects: thwomp.effectLog,
            boulderEffects: boulder.effectLog,
            boulderGeneratorEffects: boulder.generatorEffectLog,
            horizontalGrindelEffects: horizontalGrindel.effectLog,
            unusedParticleSpawnEffects: unusedParticleSpawn.effectLog,
            snowmanCheckpointEffects: snowmanCheckpoint.effectLog,
            bowserBodyAnchorEffects: bowserBodyAnchor.effectLog,
            bowserTailAnchorEffects: bowserTailAnchor.effectLog,
            snowmanHeadEffects: snowmanHead.effectLog,
            betaChestEffects: betaChest.effectLog,
            betaTrampolineEffects: betaTrampoline.effectLog,
            betaHoldableEffects: betaHoldable.effectLog,
            seaweedEffects: seaweed.effectLog,
            shipPart3Effects: shipPart3.effectLog,
            sunkenShipPartEffects: sunkenShipPart.effectLog,
            jrbSlidingBoxEffects: jrbSlidingBox.effectLog,
            fallingPillarEffects: fallingPillar.effectLog,
            coffinEffects: coffin.effectLog,
            blueFishEffects: blueFish.effectLog,
            tankFishGroupEffects: blueFish.groupEffectLog,
            clamShellEffects: clamShell.effectLog,
            bobombAnchorMarioEffects: bobombAnchorMario.effectLog,
            bubEffects: bub.effectLog,
            bubbaEffects: bubba.effectLog,
            bowlingBallEffects: bowlingBall.effectLog,
            dddPoleEffects: dddPole.effectLog,
            donutPlatformEffects: donutPlatform.effectLog,
            courtyardBooTripletEffects: courtyardBooTriplet.effectLog,
            fallingBowserPlatformEffects: fallingBowserPlatform.effectLog,
            giantPoleEffects: giantPole.effectLog,
            koopaFlagEffects: koopaFlag.effectLog,
            koopaRaceEndpointEffects: koopaRaceEndpoint.effectLog,
            wfBreakableWallEffects: wfBreakableWall.effectLog,
            unusedPoundablePlatformEffects: unusedPoundablePlatform.effectLog,
            yellowBackgroundMenuEffects: yellowBackgroundMenu.effectLog,
            snowMoundSlidingEffects: snowMound.slidingEffectLog,
            snowMoundSpawnerEffects: snowMound.spawnerEffectLog,
            rrCruiserWingEffects: rrCruiserWing.effectLog,
            spindriftEffects: spindrift.effectLog,
            spindelEffects: spindel.effectLog,
            rrRotatingBridgePlatformEffects: rrRotatingBridgePlatform.effectLog,
            snowmanWindEffects: snowmanWind.effectLog,
            mrBlizzardSnowballEffects: mrBlizzardSnowball.effectLog,
            endCutsceneActorEffects: endCutsceneActor.effectLog,
            endBirdsEffects: endBirds.effectLog,
            beginningPeachEffects: beginningPeach.effectLog,
            butterflyEffects: butterfly.effectLog,
            tiltingPyramidEffects: tiltingPyramid.effectLog,
            bookendEffects: bookend.effectLog,
            bookSwitchEffects: bookSwitch.effectLog,
            hauntedBookshelfEffects: hauntedBookshelf.effectLog,
            hauntedBookshelfManagerEffects: hauntedBookshelfManager.effectLog,
            hauntedChairEffects: hauntedChair.effectLog,
            fishEffects: fish.effectLog,
            cannonBarrelEffects: cannonBarrel.effectLog,
            cannonEffects: cannon.effectLog,
            merryGoRoundBooManagerEffects: merryGoRoundBooManager.effectLog,
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
            tuxiesMotherDeliveries: tuxiesMother.deliveryLog,
            arrowLiftEffects: arrowLift.effectLog,
            elevatorEffects: elevator.effectLog,
            seesawPlatformEffects: seesawPlatform.effectLog,
            swingPlatformEffects: swingPlatform.effectLog,
            rotatingPlatformEffects: rotatingPlatform.effectLog,
            ttcMovingBarEffects: ttcMovingBar.effectLog,
            ttcSpinnerEffects: ttcSpinner.effectLog,
            ttcTreadmillEffects: ttcTreadmill.effectLog,
            ttcPendulumEffects: ttcPendulum.effectLog,
            ttcElevatorEffects: ttcElevator.effectLog,
            ttcRotatingSolidEffects: ttcRotatingSolid.effectLog,
            ttc2DRotatorEffects: ttc2DRotator.effectLog,
            ttcCogEffects: ttcCog.effectLog,
            pyramidElevatorEffects: pyramidElevator.elevatorEffectLog,
            pyramidMarkerEffects: pyramidElevator.markerEffectLog,
            pyramidTopFragmentEffects: pyramidTopFragment.effectLog,
            pyramidPillarTouchDetectorEffects: pyramidPillarTouchDetector.effectLog,
            pyramidTopEffects: pyramidTop.effectLog,
            ttcPitBlockEffects: ttcPitBlock.effectLog,
            staticCheckeredPlatformEffects: staticCheckeredPlatform.effectLog,
            bbhTiltingTrapPlatformEffects: bbhTiltingTrapPlatform.effectLog,
            lllSinkingPlatformEffects: lllSinkingPlatform.effectLog,
            wfRotatingWoodenPlatformEffects: wfRotatingWoodenPlatform.effectLog,
            rotatingOctagonalPlatformEffects: rotatingOctagonalPlatform.effectLog,
            wfSolidTowerPlatformEffects: wfSolidTowerPlatform.effectLog,
            wfTowerPlatformEffects: wfTowerPlatform.effectLog,
            trackBallEffects: trackBall.effectLog,
            wfSlidingPlatformEffects: wfSlidingPlatform.effectLog,
            wdwExpressElevatorEffects: wdwExpressElevator.effectLog,
            lllSinkingRockBlockEffects: lllSinkingRockBlock.effectLog,
            volcanoFallingTrapEffects: volcanoFallingTrap.effectLog,
            rollingLogEffects: rollingLog.effectLog,
            lllMovingOctagonalMeshEffects: lllMovingOctagonalMesh.effectLog,
            ferrisWheelEffects: ferrisWheel.effectLog,
            checkerboardPlatformEffects: checkerboardPlatform.effectLog,
            wfTowerPlatformGroupEffects: wfTowerPlatformGroup.effectLog,
            lllRotatingHexagonalPlatformEffects: lllRotatingHexagonalPlatform.effectLog,
            lllRotatingHexFlameEffects: lllRotatingHexFlame.effectLog,
            lllRotatingFireBarEffects: lllRotatingFireBar.effectLog,
            activatedBackAndForthPlatformEffects: activatedBackAndForthPlatform.effectLog,
            bitfsSinkingPlatformEffects: bitfsSinkingPlatform.effectLog,
            dddMovingPoleEffects: dddMovingPole.effectLog,
            lllRotatingHexagonalRingEffects: lllRotatingHexagonalRing.effectLog,
            lllWoodPieceEffects: lllWoodPiece.effectLog,
            lllFloatingWoodBridgeEffects: lllFloatingWoodBridge.effectLog,
            squishablePlatformEffects: squishablePlatform.effectLog,
            lllDrawbridgeSpawnerEffects: lllDrawbridge.spawnerEffectLog,
            lllDrawbridgeEffects: lllDrawbridge.effectLog,
            idleWaterWaveEffects: idleWaterWave.effectLog,
            waterfallSoundLoopEffects: waterfallSoundLoop.effectLog,
            volcanoSoundLoopEffects: volcanoSoundLoop.effectLog,
            tumblingBridgeParentEffects: tumblingBridge.parentEffectLog,
            tumblingBridgePlatformEffects: tumblingBridge.platformEffectLog,
            floatingPlatformEffects: floatingPlatform.effectLog,
            jrbFloatingBoxEffects: jrbFloatingBox.effectLog,
            slidingPlatform2Effects: slidingPlatform2.effectLog,
            smallWaterWaveEffects: smallWaterWave.effectLog,
            ambientSoundLoopEffects: ambientSoundLoop.effectLog,
            rotatingExclamationMarkEffects: rotatingExclamationMark.effectLog,
            waterAirBubbleEffects: waterAirBubble.effectLog,
            objectBubbleEffects: objectBubble.effectLog,
            waterDropletEffects: waterDroplet.effectLog,
            waterMistEffects: waterMist.effectLog,
            waterMist2Effects: waterMist2.effectLog,
            waterSplashEffects: waterSplash.effectLog,
            bubbleMaybeEffects: bubbleMaybe.effectLog,
            windEffects: wind.effectLog,
            jetStreamEffects: jetStream.effectLog,
            jetStreamWaterRingEffects: jetStreamWaterRing.effectLog,
            jetStreamRingSpawnerEffects: jetStreamRingSpawner.effectLog,
            mantaRayWaterRingEffects: mantaRayWaterRing.effectLog,
            whirlpoolEffects: whirlpool.effectLog,
            mantaRayEffects: mantaRay.effectLog,
            shallowWaterWaveEffects: shallowWaterWave.effectLog,
            waterSplashSpawnerEffects: waterSplashSpawner.effectLog,
            bubbleParticleSpawnerEffects: bubbleParticleSpawner.effectLog,
            piranhaPlantWakingBubbleEffects: piranhaPlantWakingBubble.effectLog,
            piranhaPlantBubbleEffects: piranhaPlantBubble.effectLog,
            waveTrailEffects: waveTrail.effectLog,
            sushiSharkEffects: sushiShark.effectLog,
            strongWindParticleEffects: strongWindParticle.effectLog,
            waterParticleEffects: waterParticle.effectLog,
            plungeBubbleEffects: plungeBubble.effectLog,
            breathParticleSpawnerEffects: breathParticleSpawner.effectLog,
            mistParticleEffects: mistParticle.effectLog,
            mistParticleSpawnerEffects: mistParticleSpawner.effectLog,
            tweesterSandParticleEffects: tweesterSandParticle.effectLog,
            blackSmokeMarioEffects: blackSmokeMario.effectLog,
            flameMarioEffects: flameMario.effectLog,
            blackSmokeBowserEffects: blackSmokeBowser.effectLog,
            blackSmokeUpwardEffects: blackSmokeUpward.effectLog,
            whitePuffSmokeEffects: whitePuffSmoke.effectLog,
            whitePuffSmoke2Effects: whitePuffSmoke2.effectLog,
            whitePuffExplosionEffects: whitePuffExplosion.effectLog,
            dustSmokeEffects: dustSmoke.effectLog,
            starKeyPuffSpawnerEffects: starKeyPuffSpawner.effectLog,
            staticFlameEffects: staticFlame.effectLog,
            flamethrowerFlameEffects: flamethrowerFlame.effectLog,
            flameBouncingEffects: flameBouncing.effectLog,
            flameBowserEffects: bowserFlame.effectLog,
            blueFlamesGroupEffects: blueFlamesGroup.effectLog,
            flameFloatingLandingEffects: flameFloatingLanding.effectLog,
            blueBowserFlameEffects: blueBowserFlame.effectLog,
            volcanoFlamesEffects: volcanoFlames.effectLog,
            koopaShellFlameEffects: koopaShellFlame.effectLog,
            flameMovingForwardGrowingEffects: flameMovingForwardGrowing.effectLog,
            betaMovingFlamesEffects: betaMovingFlames.effectLog,
            betaMovingFlamesSpawnEffects: betaMovingFlames.spawnEffectLog,
            bowserFlameSpawnEffects: bowserFlameSpawn.effectLog,
            smallPiranhaFlameEffects: smallPiranhaFlame.effectLog,
            fireSpitterEffects: fireSpitter.effectLog,
            firePiranhaPlantEffects: firePiranhaPlant.effectLog,
            flamethrowerEffects: flamethrower.effectLog,
            celebrationStarSparkleEffects: celebrationStarSparkle.effectLog,
            groundParticleSpawnerEffects: groundParticleSpawner.effectLog,
            animatedTextureEffects: animatedTexture.effectLog,
            sparkleEffects: sparkle.effectLog,
            sparkleSpawnerEffects: sparkleSpawner.effectLog,
            ambientSoundsEffects: ambientSounds.effectLog,
            coinSparklesEffects: coinSparkles.effectLog,
            goldenCoinSparklesEffects: goldenCoinSparkles.effectLog,
            purpleParticleEffects: purpleParticle.effectLog,
            tinyStarParticleEffects: tinyStarParticle.effectLog,
            tinyStarParticleSpawnerEffects: tinyStarParticleSpawner.effectLog,
            triangleParticleEffects: triangleParticle.effectLog,
            triangleParticleSpawnerEffects: triangleParticleSpawner.effectLog,
            treeLeafEffects: treeLeaf.effectLog,
            treeParticleSpawnerEffects: treeParticleSpawner.effectLog,
            mistCircParticleSpawnerEffects: mistCircParticleSpawner.effectLog,
            sparkleParticleSpawnerEffects: sparkleParticleSpawner.effectLog,
            simpleAnimationEffects: simpleAnimation.effectLog,
            unusedFakeStarEffects: unusedFakeStar.effectLog,
            cloudPartEffects: cloudPart.effectLog,
            breakBoxTriangleEffects: breakBoxTriangle.effectLog,
            cannonBaseUnusedEffects: cannonBaseUnused.effectLog,
            noOpEffects: noOp.effectLog,
            cannonBarrelBubblesEffects: cannonBarrelBubbles.effectLog,
            cloudEffects: cloud.effectLog,
            celebrationStarEffects: celebrationStar.effectLog,
            warpEffects: warp.effectLog,
            dddWarpEffects: dddWarp.effectLog,
            actSelectorEffects: actSelector.effectLog,
            actSelectorStarTypeEffects: actSelectorStarType.effectLog,
            collectStarEffects: collectStar.effectLog,
            starSpawnCoordinatesEffects: starSpawnCoordinates.effectLog,
            spawnedStarEffects: spawnedStar.effectLog,
            unlockDoorStarEffects: unlockDoorStar.effectLog,
            ccmTouchedStarSpawnEffects: ccmTouchedStarSpawn.effectLog,
            hiddenStarEffects: hiddenStar.parentEffectLog,
            hiddenStarTriggerEffects: hiddenStar.triggerEffectLog,
            castleCannonGrateEffects: castleCannonGrate.effectLog,
            blueCoinSwitchEffects: blueCoin.switchEffectLog,
            hiddenBlueCoinEffects: blueCoin.hiddenCoinEffectLog,
            hiddenRedCoinStarEffects: redCoin.hiddenStarEffectLog,
            redCoinStarMarkerEffects: redCoin.markerEffectLog,
            redCoinEffects: redCoin.coinEffectLog,
            starDoorEffects: starDoor.effectLog,
            capSwitchEffects: capSwitch.switchEffectLog,
            metalCapEffects: metalCap.effectLog,
            vanishCapEffects: vanishCap.effectLog,
            wingCapEffects: wingCap.effectLog,
            normalCapEffects: normalCap.effectLog,
            capSwitchBaseEffects: capSwitch.baseEffectLog,
            towerDoorEffects: towerDoor.effectLog,
            openableGrillEffects: openableGrill.grillEffectLog,
            openableCageDoorEffects: openableGrill.cageEffectLog,
            doorEffects: door.effectLog,
            hiddenObjectEffects: hiddenObject.effectLog,
            recoveryHeartEffects: recoveryHeart.effectLog,
            coinEffects: coin.effectLog,
            coinSpawnerEffects: coin.spawnerEffectLog,
            movingCoinEffects: movingCoin.effectLog,
            waterLevelDiamondEffects: waterLevel.diamondEffectLog,
            changingWaterLevelEffects: waterLevel.initializerEffectLog,
            waterPillarEffects: waterPillar.effectLog,
            floorSwitchEffects: floorSwitch.effectLog,
            animatedFloorSwitchEffects: animatedFloorSwitch.effectLog,
            hiddenOneUpEffects: hiddenOneUp.effectLog,
            breakableBoxEffects: breakableBox.effectLog,
            jumpingBoxEffects: jumpingBox.effectLog,
            kickableBoardEffects: kickableBoard.effectLog,
            exclamationBoxEffects: exclamationBox.effectLog,
            orangeNumberEffects: orangeNumber.effectLog,
            soundSpawnerEffects: soundSpawner.effectLog,
            rockSolidEffects: rockSolid.effectLog,
            toxBoxEffects: toxBox.effectLog,
            sslMovingPyramidWallEffects: sslMovingPyramidWall.effectLog,
            thiIslandTopEffects: thiIslandTop.effectLog,
            environmentGateEffects: environmentGate.effectLog,
            clockArmEffects: clockArm.effectLog,
            castleFloorTrapEffects: castleFloorTrap.effectLog,
            castleFlagEffects: castleFlag.effectLog,
            booCageEffects: booCage.effectLog,
            booKeyEffects: booKey.effectLog,
            booInCastleEffects: booInCastle.effectLog,
            merryGoRoundEffects: merryGoRound.effectLog,
            musicTouchEffects: musicTouch.effectLog,
            textSurfaceEffects: textSurface.effectLog,
            grandStarEffects: grandStar.effectLog,
            betaBowserAnchorEffects: betaBowserAnchor.effectLog
        )
    }
}
