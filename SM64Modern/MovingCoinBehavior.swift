import Foundation

enum SM64MovingCoinKind: UInt8, Equatable, Sendable {
    case yellow = 0
    case blue = 1
    case blueSliding = 2
    case blueJumping = 3

    var isBlue: Bool { self != .yellow }
    var isSlidingOrJumping: Bool { self == .blueSliding || self == .blueJumping }
}
struct SM64MovingCoinInput: Equatable, Sendable {
    let kind: SM64MovingCoinKind
    let action: Int32
    let timer: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let collisionGrounded: Bool
    let collisionNoYVelocity: Bool
    let floorDeath: Bool
    let withinMarioRadius: Bool
    let interacted: Bool
    let angleToMario: Int32
    let collisionWall: Bool
    let withinMario500: Bool
    let withinMario1000: Bool

    init(
        kind: SM64MovingCoinKind,
        action: Int32,
        timer: Int32,
        forwardVelocity: Float,
        velocityY: Float,
        collisionGrounded: Bool,
        collisionNoYVelocity: Bool,
        floorDeath: Bool,
        withinMarioRadius: Bool,
        interacted: Bool,
        angleToMario: Int32 = 0,
        collisionWall: Bool = false,
        withinMario500: Bool = false,
        withinMario1000: Bool = false
    ) {
        self.kind = kind
        self.action = action
        self.timer = timer
        self.forwardVelocity = forwardVelocity
        self.velocityY = velocityY
        self.collisionGrounded = collisionGrounded
        self.collisionNoYVelocity = collisionNoYVelocity
        self.floorDeath = floorDeath
        self.withinMarioRadius = withinMarioRadius
        self.interacted = interacted
        self.angleToMario = angleToMario
        self.collisionWall = collisionWall
        self.withinMario500 = withinMario500
        self.withinMario1000 = withinMario1000
    }
}
struct SM64MovingCoinOutput: Equatable, Sendable {
    let kind: SM64MovingCoinKind
    let action: Int32
    let timer: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let tangible: Bool
    let soundCoinDrop: Bool
    let spawnGoldenSparkles: Bool
    let shouldDelete: Bool
    let damageOrCoinValue: Int32
    let moveYaw: Int32
    let visible: Bool
}
enum SM64MovingCoinBehavior {
    static func update(_ input: SM64MovingCoinInput) -> SM64MovingCoinOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var speed = input.forwardVelocity
        var velocityY = input.velocityY
        var moveYaw = input.angleToMario
        var tangible = false
        var visible = true
        var sound = false
        var deleteObject = input.floorDeath
        var sparkles = false
        if input.kind == .yellow {
            switch input.action {
            case 0:
                if input.collisionGrounded && !input.collisionNoYVelocity { sound = true }
                tangible = input.timer >= 10
                if input.timer >= 301 { action = 1; timer = 0 }
            case 1:
                break
            case 100, 101:
                deleteObject = true
            default:
                break
            }
        } else if input.kind == .blue {
            switch input.action {
            case 0:
                if input.withinMarioRadius { action = 1; timer = 0 }
            case 1:
                if input.collisionGrounded {
                    speed = min(speed + 25, 75)
                    if !input.collisionNoYVelocity { sound = true }
                } else {
                    speed *= 0.98
                }
                deleteObject = input.timer >= 600
            default:
                break
            }
        } else {
            // `bhvBlueCoinSliding` and `bhvBlueCoinJumping` share the C
            // away/slow/fade tail; only their initial action differs.
            if input.kind == .blueJumping && input.action == 0 {
                if input.timer == 0 {
                    velocityY = 50
                    tangible = false
                }
                if input.timer >= 15 {
                    action = 1
                    timer = 0
                    tangible = true
                }
            } else {
                tangible = input.action != 4
                switch input.action {
                case 0:
                    if input.withinMario500 { action = 1; timer = 0 }
                case 1:
                    speed = 15
                    moveYaw = input.angleToMario &+ 0x8000
                    if input.collisionGrounded {
                        if !input.collisionNoYVelocity {
                            velocityY += 18
                            sound = true
                        }
                    }
                    if input.collisionWall || !input.withinMario1000 {
                        action = input.collisionWall ? 3 : 2
                        timer = 0
                    }
                case 2:
                    if input.withinMario500 {
                        action = 1
                        timer = 0
                    } else if input.timer >= 151 {
                        action = 3
                        timer = 0
                    }
                case 3:
                    if input.timer >= 61 {
                        action = 4
                        timer = 0
                    }
                case 4:
                    visible = input.timer.isMultiple(of: 2)
                case 100, 101:
                    deleteObject = true
                default:
                    break
                }
            }
        }
        if input.interacted {
            sparkles = true
            deleteObject = true
        }
        return .init(
            kind: input.kind,
            action: action,
            timer: timer,
            forwardVelocity: speed,
            velocityY: velocityY,
            tangible: tangible,
            soundCoinDrop: sound,
            spawnGoldenSparkles: sparkles,
            shouldDelete: deleteObject,
            damageOrCoinValue: input.kind.isBlue ? 5 : 1,
            moveYaw: moveYaw,
            visible: visible
        )
    }
}
