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
