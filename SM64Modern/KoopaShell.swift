import Foundation

enum SM64KoopaShellKind: UInt8, Equatable, Sendable {
    case shell = 0
    case underwater = 1
}

enum SM64KoopaShellAction: UInt8, Equatable, Sendable {
    case free = 0
    case ridden = 1
}

enum SM64KoopaShellHeldState: UInt8, Equatable, Sendable {
    case free = 0
    case held = 1
    case thrown = 2
    case dropped = 3
}

struct SM64KoopaShellHitbox: Equatable, Sendable {
    let interactType: UInt32
    let downOffset: Float
    let damageOrCoinValue: Int16
    let health: Int16
    let numLootCoins: UInt8
    let radius: Float
    let height: Float
    let hurtboxRadius: Float
    let hurtboxHeight: Float

    static let shell = Self(
        interactType: 1 << 19,
        downOffset: 0,
        damageOrCoinValue: 4,
        health: 1,
        numLootCoins: 1,
        radius: 50,
        height: 50,
        hurtboxRadius: 50,
        hurtboxHeight: 50
    )

    static let underwater = Self(
        interactType: 1 << 1,
        downOffset: 0,
        damageOrCoinValue: 0,
        health: 1,
        numLootCoins: 0,
        radius: 80,
        height: 50,
        hurtboxRadius: 0,
        hurtboxHeight: 0
    )
}

struct SM64KoopaShellState: Equatable, Sendable {
    let kind: SM64KoopaShellKind
    let hitbox: SM64KoopaShellHitbox

    var action: SM64KoopaShellAction = .free
    var heldState: SM64KoopaShellHeldState = .free
    var positionX: Float = 0
    var positionY: Float = 0
    var positionZ: Float = 0
    var floorHeight: Float = 0
    var moveYaw: Int16 = 0
    var faceYaw: Int16 = 0
    var forwardVelocity: Float = 0
    var velocityY: Float = 0
    var moveFlags: UInt32 = 0
    var floorType: Int16 = 0
    var hidden = false
    var markedForDeletion = false
    var timer: UInt32 = 0

    init(
        kind: SM64KoopaShellKind = .shell,
        action: SM64KoopaShellAction = .free,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        floorHeight: Float = 0,
        moveYaw: Int16 = 0,
        forwardVelocity: Float = 0
    ) {
        self.kind = kind
        self.hitbox = kind == .shell ? .shell : .underwater
        self.action = action
        self.positionX = positionX
        self.positionY = positionY
        self.positionZ = positionZ
        self.floorHeight = floorHeight
        self.moveYaw = moveYaw
        self.faceYaw = moveYaw
        self.forwardVelocity = forwardVelocity
    }
}

struct SM64KoopaShellTickInput: Equatable, Sendable {
    var heldState: SM64KoopaShellHeldState
    var moveFlags: UInt32
    var wallYaw: Int16
    var floorHeight: Float
    var floorType: Int16
    var interacted: Bool
    var stopRiding: Bool
    var nearWater: Bool
    var marioForwardVelocity: Float
    var marioX: Float
    var marioY: Float
    var marioZ: Float
    var marioMoveYaw: Int16

    init(
        heldState: SM64KoopaShellHeldState = .free,
        moveFlags: UInt32 = 0,
        wallYaw: Int16 = 0,
        floorHeight: Float = 0,
        floorType: Int16 = 0,
        interacted: Bool = false,
        stopRiding: Bool = false,
        nearWater: Bool = false,
        marioForwardVelocity: Float = 0,
        marioX: Float = 0,
        marioY: Float = 0,
        marioZ: Float = 0,
        marioMoveYaw: Int16 = 0
    ) {
        self.heldState = heldState
        self.moveFlags = moveFlags
        self.wallYaw = wallYaw
        self.floorHeight = floorHeight
        self.floorType = floorType
        self.interacted = interacted
        self.stopRiding = stopRiding
        self.nearWater = nearWater
        self.marioForwardVelocity = marioForwardVelocity
        self.marioX = marioX
        self.marioY = marioY
        self.marioZ = marioZ
        self.marioMoveYaw = marioMoveYaw
    }
}

struct SM64KoopaShellEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt16

    init(rawValue: UInt16) { self.rawValue = rawValue }

    static let animate = Self(rawValue: 1 << 0)
    static let setHitbox = Self(rawValue: 1 << 1)
    static let wallBounce = Self(rawValue: 1 << 2)
    static let riding = Self(rawValue: 1 << 3)
    static let spin = Self(rawValue: 1 << 4)
    static let spawnSparkle = Self(rawValue: 1 << 5)
    static let spawnWaveTrail = Self(rawValue: 1 << 6)
    static let spawnWaterDrop = Self(rawValue: 1 << 7)
    static let spawnFlames = Self(rawValue: 1 << 8)
    static let spawnMist = Self(rawValue: 1 << 9)
    static let markForDeletion = Self(rawValue: 1 << 10)
    static let hide = Self(rawValue: 1 << 11)
    static let tangible = Self(rawValue: 1 << 12)
}

struct SM64KoopaShellTickResult: Equatable, Sendable {
    let state: SM64KoopaShellState
    let effects: SM64KoopaShellEffect
}

enum SM64KoopaShellKernel {
    static let hitWallFlag: UInt32 = 1 << 9
    static let onGroundMask: UInt32 = (1 << 0) | (1 << 1)

    static func tick(
        _ input: SM64KoopaShellTickInput,
        state: inout SM64KoopaShellState
    ) -> SM64KoopaShellTickResult {
        guard state.kind == .shell else {
            return tickUnderwater(input, state: &state)
        }

        var effects: SM64KoopaShellEffect = [.animate, .setHitbox]
        state.moveFlags = input.moveFlags
        state.floorHeight = input.floorHeight
        state.floorType = input.floorType

        switch state.action {
        case .free:
            if input.moveFlags & Self.hitWallFlag != 0 {
                state.moveYaw = input.wallYaw
                effects.insert(.wallBounce)
            }
            if input.interacted {
                state.action = .ridden
                effects.insert(.riding)
            }
            state.faceYaw &+= 0x1000
            state.forwardVelocity = max(state.forwardVelocity, 0)
            moveStandard(state: &state)
            effects.insert([.spin, .spawnSparkle])

        case .ridden:
            state.positionX = input.marioX
            state.positionY = input.marioY
            state.positionZ = input.marioZ
            state.faceYaw = input.marioMoveYaw
            if input.nearWater {
                effects.insert(.spawnWaveTrail)
                if input.marioForwardVelocity > 10 {
                    effects.insert(.spawnWaterDrop)
                }
            } else if abs(state.positionY - state.floorHeight) < 5,
                      state.floorType == 1 {
                effects.insert(.spawnFlames)
            } else {
                effects.insert(.spawnSparkle)
            }

            if input.stopRiding {
                state.markedForDeletion = true
                state.action = .free
                effects.insert([.spawnMist, .markForDeletion])
            }
        }

        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64KoopaShellTickResult(state: state, effects: effects)
    }

    private static func tickUnderwater(
        _ input: SM64KoopaShellTickInput,
        state: inout SM64KoopaShellState
    ) -> SM64KoopaShellTickResult {
        var effects: SM64KoopaShellEffect = [.animate]
        state.heldState = input.stopRiding ? .dropped : input.heldState
        switch state.heldState {
        case .free:
            state.hidden = false
            effects.insert(.tangible)
        case .held:
            state.hidden = true
            effects.insert(.hide)
        case .thrown, .dropped:
            state.markedForDeletion = true
            effects.insert([.spawnMist, .markForDeletion])
        }
        if input.stopRiding {
            state.markedForDeletion = true
            effects.insert([.spawnMist, .markForDeletion])
        }
        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64KoopaShellTickResult(state: state, effects: effects)
    }

    private static func moveStandard(state: inout SM64KoopaShellState) {
        state.positionX += SM64CanonicalTrig.sins(state.moveYaw) * state.forwardVelocity
        state.positionZ += SM64CanonicalTrig.coss(state.moveYaw) * state.forwardVelocity
        state.velocityY = max(state.velocityY - 4, -78)
        state.positionY += state.velocityY
        if state.moveFlags & Self.onGroundMask != 0,
           state.positionY < state.floorHeight {
            state.positionY = state.floorHeight
            if state.velocityY < 0 { state.velocityY *= -0.5 }
        }
    }
}
