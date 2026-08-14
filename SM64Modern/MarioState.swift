import Foundation

enum SM64MarioAction {
    static let idle: UInt32 = 0x0C400201
    static let waterIdle: UInt32 = 0x380022C0
}

/// Save flags consumed by `init_mario`. The cap-loss bits intentionally retain
/// their C save-file positions so this boundary can later consume the Swift
/// save codec without translating through a pointer-backed C state.
struct SM64MarioSaveFlags: OptionSet, Equatable, Sendable {
    let rawValue: UInt32

    static let capOnGround = Self(rawValue: 1 << 16)
    static let capOnKlepto = Self(rawValue: 1 << 17)
    static let capOnUkiki = Self(rawValue: 1 << 18)
    static let capOnMrBlizzard = Self(rawValue: 1 << 19)

    static let capLossMask: Self = [.capOnGround, .capOnKlepto, .capOnUkiki, .capOnMrBlizzard]
}

struct SM64MarioSaveState: Equatable, Sendable {
    var flags: SM64MarioSaveFlags = []
    var totalStars: Int16 = 0
}

struct SM64MarioSpawnInput: Equatable, Sendable {
    var position: SM64ObjectVector3
    var faceAngle: SM64ObjectAngles
    var waterLevel: Float
}

/// Swift-owned counterpart of the POD portion of `struct MarioState`. Object
/// and surface references are stable IDs, never raw pointers. The remaining
/// action/effect fields are deliberately explicit so later action slices can
/// be diffed without exposing the C object graph.
struct SM64MarioState: Equatable, Sendable {
    var unknown00: UInt16 = 0
    var input: SM64MarioInputFlags = []
    var flags: UInt32 = 0
    var particleFlags: UInt32 = 0
    var action: UInt32 = 0
    var previousAction: UInt32 = 0
    var terrainSoundAddend: UInt32 = 0
    var actionState: UInt16 = 0
    var actionTimer: UInt16 = 0
    var actionArgument: UInt32 = 0
    var intendedMagnitude: Float = 0
    var intendedYaw: Int16 = 0
    var invincibilityTimer: Int16 = 0
    var framesSinceA: UInt8 = 0
    var framesSinceB: UInt8 = 0
    var wallKickTimer: UInt8 = 0
    var doubleJumpTimer: UInt8 = 0
    var faceAngle: SM64ObjectAngles = .zero
    var angleVelocity: SM64ObjectAngles = .zero
    var slideYaw: Int16 = 0
    var twirlYaw: Int16 = 0
    var position: SM64ObjectVector3 = .zero
    var velocity: SM64ObjectVector3 = .zero
    var forwardVelocity: Float = 0
    var slideVelocityX: Float = 0
    var slideVelocityZ: Float = 0
    var wallSurfaceID: UInt32?
    var ceilingSurfaceID: UInt32?
    var floorSurfaceID: UInt32?
    var ceilingHeight: Float = SM64SurfaceCollisionWorld.missHeight
    var floorHeight: Float = SM64SurfaceCollisionWorld.missHeight
    var floorAngle: Int16 = 0
    var waterLevel: Float = SM64SurfaceCollisionWorld.missHeight
    var interactObjectID: SM64ObjectID?
    var heldObjectID: SM64ObjectID?
    var usedObjectID: SM64ObjectID?
    var riddenObjectID: SM64ObjectID?
    var marioObjectID: SM64ObjectID?
    var collidedObjectInteractionTypes: UInt32 = 0
    var coinCount: Int16 = 0
    var starCount: Int16 = 0
    var keyCount: Int8 = 0
    var lives: Int8 = 4
    var health: Int16 = 0x880
    var unknownB0: Int16 = 0x00BD
    var hurtCounter: UInt8 = 0
    var healCounter: UInt8 = 0
    var squishTimer: UInt8 = 0
    var fadeWarpOpacity: UInt8 = 0
    var capTimer: UInt16 = 0
    var previousStarsForDialog: Int16 = 0
    var peakHeight: Float = 0
    var quicksandDepth: Float = 0
    var unknownC4: Float = 0

    static func initialized(
        save: SM64MarioSaveState,
        spawn: SM64MarioSpawnInput,
        floor: SM64SurfaceQueryResult,
        marioObjectID: SM64ObjectID? = nil
    ) -> Self {
        var state = Self()
        state.framesSinceA = .max
        state.framesSinceB = .max
        state.faceAngle = spawn.faceAngle
        state.waterLevel = spawn.waterLevel
        state.floorSurfaceID = floor.surfaceID
        state.floorHeight = floor.height
        state.marioObjectID = marioObjectID
        state.starCount = save.totalStars
        state.previousStarsForDialog = save.totalStars

        // `init_mario` keeps Mario's cap on his head only when none of the
        // four portable cap-loss locations has claimed it.
        if save.flags.intersection(.capLossMask).isEmpty {
            state.flags = SM64MarioCapFlags.normal.rawValue | SM64MarioCapFlags.onHead.rawValue
        }

        state.position = SM64ObjectVector3(
            x: spawn.position.x,
            y: max(spawn.position.y, floor.height),
            z: spawn.position.z
        )
        state.floorHeight = floor.height
        state.action = state.position.y <= spawn.waterLevel - 100
            ? SM64MarioAction.waterIdle
            : SM64MarioAction.idle
        return state
    }
}

struct SM64MarioCapFlags: OptionSet, Equatable, Sendable {
    let rawValue: UInt32

    static let normal = Self(rawValue: 0x00000001)
    static let vanish = Self(rawValue: 0x00000002)
    static let metal = Self(rawValue: 0x00000004)
    static let wing = Self(rawValue: 0x00000008)
    static let onHead = Self(rawValue: 0x00000010)
    static let inHand = Self(rawValue: 0x00000020)
}

enum SM64MarioCapPowerup: Equatable, Sendable {
    case vanish
    case metal
    case wing

    var capFlag: SM64MarioCapFlags {
        switch self {
        case .vanish: return .vanish
        case .metal: return .metal
        case .wing: return .wing
        }
    }

    /// Timers used by `set_mario_initial_cap_powerup` in the three cap
    /// courses. Pickups use a separate timer because the C interaction path
    /// gives the wing cap 1800 frames instead of the initial 1200.
    var initialTimer: UInt16 {
        switch self {
        case .vanish, .metal: return 600
        case .wing: return 1200
        }
    }

    var pickupTimer: UInt16 {
        switch self {
        case .vanish, .metal: return 600
        case .wing: return 1800
        }
    }
}

struct SM64MarioCapMutation: Equatable, Sendable {
    let capTimer: UInt16
    let flags: UInt32
    let renderFlags: UInt32
    let didExpire: Bool
    let shouldFadeOutMusic: Bool
    let didFlicker: Bool
}

struct SM64MarioTerrainMutation: Equatable, Sendable {
    let position: SM64ObjectVector3
    let floorSurfaceID: UInt32?
    let ceilingSurfaceID: UInt32?
    let wallSurfaceID: UInt32?
    let floorHeight: Float
    let ceilingHeight: Float
    let floorAngle: Int16
    let waterLevel: Float
    let terrainSoundAddend: UInt32
    let input: SM64MarioInputFlags
    let floorChanged: Bool
    let ceilingChanged: Bool
    let waterLevelChanged: Bool
}

enum SM64MarioActionBits {
    static let groupMask: UInt32 = 0x000001C0
    static let movingGroup: UInt32 = 0x00000040
    static let airborneGroup: UInt32 = 0x00000080
    static let submergedGroup: UInt32 = 0x000000C0
    static let cutsceneGroup: UInt32 = 0x00000100
    static let air: UInt32 = 0x00000800
    static let intangible: UInt32 = 0x00001000
    static let swimming: UInt32 = 0x00002000
    static let actionSoundPlayed: UInt32 = 0x00010000
    static let marioSoundPlayed: UInt32 = 0x00020000
    static let unknown18: UInt32 = 0x00040000
    static let unknown08: UInt32 = 0x00000100
}

struct SM64MarioHealthContext: Equatable, Sendable {
    var terrainType: UInt16
    var debugLevelSelect: Bool
}

struct SM64MarioHealthMutation: Equatable, Sendable {
    let health: Int16
    let healCounter: UInt8
    let hurtCounter: UInt8
    let nearDrowningRumble: Bool
}

extension SM64MarioState {
    private static let temporaryCapMask =
        SM64MarioCapFlags.vanish.rawValue
        | SM64MarioCapFlags.metal.rawValue
        | SM64MarioCapFlags.wing.rawValue
    private static let persistentCapMask =
        SM64MarioCapFlags.normal.rawValue
        | SM64MarioCapFlags.vanish.rawValue
        | SM64MarioCapFlags.metal.rawValue
        | SM64MarioCapFlags.wing.rawValue
    private static let capFlickerFrames: UInt64 = 0x4444_4492_4925_5555

    /// Applies the cap course powerup selected by `gCurrCourseNum` in
    /// `set_mario_initial_cap_powerup`. Course numbers 20, 21, and 22 are
    /// `COURSE_COTMC`, `COURSE_TOTWC`, and `COURSE_VCUTM` in the US table.
    @discardableResult
    mutating func applyInitialCapPowerup(courseIndex: Int) -> SM64MarioCapMutation? {
        let powerup: SM64MarioCapPowerup?
        switch courseIndex {
        case 20: powerup = .metal
        case 21: powerup = .wing
        case 22: powerup = .vanish
        default: powerup = nil
        }
        guard let powerup else { return nil }
        flags |= powerup.capFlag.rawValue | SM64MarioCapFlags.onHead.rawValue
        capTimer = powerup.initialTimer
        return SM64MarioCapMutation(
            capTimer: capTimer,
            flags: flags,
            renderFlags: flags,
            didExpire: false,
            shouldFadeOutMusic: false,
            didFlicker: false
        )
    }

    /// Applies the value portion of `interact_cap`. Action selection,
    /// sequence playback, and object ownership remain owner-thread effects;
    /// this method only performs the C-compatible flag and timer mutation.
    @discardableResult
    mutating func applyCapPowerup(_ powerup: SM64MarioCapPowerup) -> SM64MarioCapMutation {
        flags &= ~(SM64MarioCapFlags.onHead.rawValue | SM64MarioCapFlags.inHand.rawValue)
        flags |= powerup.capFlag.rawValue
        capTimer = max(capTimer, powerup.pickupTimer)
        return SM64MarioCapMutation(
            capTimer: capTimer,
            flags: flags,
            renderFlags: flags,
            didExpire: false,
            shouldFadeOutMusic: false,
            didFlicker: false
        )
    }

    /// Mirrors `update_and_return_cap_flags`. The returned render flags may
    /// flicker while the state flags remain stable; expiration mutates the
    /// state and reports the music transition as an intent.
    @discardableResult
    mutating func tickCapTimer() -> SM64MarioCapMutation {
        var renderFlags = flags
        var didExpire = false
        var shouldFadeOutMusic = false
        var didFlicker = false

        if capTimer > 0 {
            let pausesWhileReading = action == 0x20001305 // ACT_READING_AUTOMATIC_DIALOG
                || action == 0x20001306 // ACT_READING_NPC_DIALOG
                || action == 0x00001308 // ACT_READING_SIGN
                || action == 0x00001371 // ACT_IN_CANNON
            if capTimer <= 60 || !pausesWhileReading {
                capTimer &-= 1
            }

            if capTimer == 0 {
                didExpire = true
                flags &= ~Self.temporaryCapMask
                if flags & Self.persistentCapMask == 0 {
                    flags &= ~SM64MarioCapFlags.onHead.rawValue
                }
            }

            shouldFadeOutMusic = capTimer == 0x3C
            if capTimer < 0x40
                && ((Self.capFlickerFrames & (UInt64(1) << UInt64(capTimer))) != 0) {
                renderFlags &= ~Self.temporaryCapMask
                if renderFlags & Self.persistentCapMask == 0 {
                    renderFlags &= ~SM64MarioCapFlags.onHead.rawValue
                }
                didFlicker = true
            }
        }

        return SM64MarioCapMutation(
            capTimer: capTimer,
            flags: flags,
            renderFlags: renderFlags,
            didExpire: didExpire,
            shouldFadeOutMusic: shouldFadeOutMusic,
            didFlicker: didFlicker
        )
    }

    /// Applies the collision-derived portion of `update_mario_geometry_inputs`
    /// after wall resolution and the graphics-position fallback have already
    /// been performed by `SM64MarioGeometryInput.update`.
    @discardableResult
    mutating func applyTerrainSnapshot(
        _ geometry: SM64MarioGeometryInputResult
    ) -> SM64MarioTerrainMutation {
        let oldFloor = floorSurfaceID
        let oldCeiling = ceilingSurfaceID
        let oldWaterLevel = waterLevel

        position = geometry.position
        input.formUnion(geometry.flags)
        floorSurfaceID = geometry.floor.surfaceID
        ceilingSurfaceID = geometry.ceiling.surfaceID
        // C stores only the resolved wall pointer outside the collision
        // routine. The lower probe is the last C wall pass, so its newest
        // surface is the stable ID used by the Swift state boundary.
        wallSurfaceID = geometry.lowerWall.surfaceIDs.last
            ?? geometry.upperWall.surfaceIDs.last
        floorHeight = geometry.floor.height
        ceilingHeight = geometry.ceiling.height
        floorAngle = geometry.floorAngle
        waterLevel = geometry.waterLevel
        terrainSoundAddend = geometry.terrainSoundAddend

        return SM64MarioTerrainMutation(
            position: position,
            floorSurfaceID: floorSurfaceID,
            ceilingSurfaceID: ceilingSurfaceID,
            wallSurfaceID: wallSurfaceID,
            floorHeight: floorHeight,
            ceilingHeight: ceilingHeight,
            floorAngle: floorAngle,
            waterLevel: waterLevel,
            terrainSoundAddend: terrainSoundAddend,
            input: input,
            floorChanged: oldFloor != floorSurfaceID,
            ceilingChanged: oldCeiling != ceilingSurfaceID,
            waterLevelChanged: oldWaterLevel != waterLevel
        )
    }

    /// Value counterpart of `update_mario_health`. It returns the observable
    /// rumble intent instead of calling a platform API; the owner-thread tick
    /// can enqueue it after the state transition is accepted.
    mutating func updateHealth(context: SM64MarioHealthContext) -> SM64MarioHealthMutation {
        var didRunHealthDomain = false
        if health >= 0x100 {
            didRunHealthDomain = true
            if healCounter == 0 && hurtCounter == 0 {
                let isIntangible = action & SM64MarioActionBits.intangible != 0
                let isSwimming = action & SM64MarioActionBits.swimming != 0
                if input.contains(.inPoisonGas) && !isIntangible
                    && flags & SM64MarioCapFlags.metal.rawValue == 0
                    && !context.debugLevelSelect {
                    health -= 4
                } else if isSwimming && !isIntangible {
                    let terrainIsSnow = context.terrainType & 0x0007 == 0x0002
                    if position.y >= waterLevel - 140 && !terrainIsSnow {
                        health += 0x1A
                    } else if !context.debugLevelSelect {
                        health -= terrainIsSnow ? 3 : 1
                    }
                }
            }

            if healCounter > 0 {
                health += 0x40
                healCounter -= 1
            }
            if hurtCounter > 0 {
                health -= 0x40
                hurtCounter -= 1
            }

            if health >= 0x881 { health = 0x880 }
            if health < 0x100 { health = 0xFF }
        }

        let nearDrowning = didRunHealthDomain
            && action & SM64MarioActionBits.groupMask == SM64MarioActionBits.submergedGroup
            && health < 0x300
        return SM64MarioHealthMutation(
            health: health,
            healCounter: healCounter,
            hurtCounter: hurtCounter,
            nearDrowningRumble: nearDrowning
        )
    }
}
