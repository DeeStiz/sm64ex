import Foundation

enum SM64BreakableBoxKind: UInt8, Equatable, Sendable {
    case large = 0
    case small = 1
}

struct SM64BreakableBoxInput: Equatable, Sendable {
    let kind: SM64BreakableBoxKind
    let heldState: Int32
    let action: Int32
    let timer: Int32
    let attacked: Bool
    let moveFlags: UInt32
    let lavaDeath: Bool
    let released: Bool
    let framesSinceReleased: Int32
    let forwardVelocity: Float
}

struct SM64BreakableBoxOutput: Equatable, Sendable {
    let kind: SM64BreakableBoxKind
    let action: Int32
    let timer: Int32
    let visible: Bool
    let tangible: Bool
    let shouldDelete: Bool
    let shouldRespawn: Bool
    let model: UInt32
    let scale: Float
    let hitboxRadius: Float
    let hitboxHeight: Float
    let forwardVelocity: Float
    let velocityY: Float
    let spawnCoins: Int32
    let spawnDust: Bool
    let spawnMist: Bool
    let spawnTriangles: Bool
    let playLandingSound: Bool
    let playBreakSound: Bool
    let loadCollisionModel: Bool
}

/// Fixed-width counterpart of the large and holdable small breakable-box
/// reducers. Pointer-backed respawn and particle/audio delivery stays in the
/// owner bridge; branch decisions and timers are value-only.
enum SM64BreakableBoxBehavior {
    static func update(_ input: SM64BreakableBoxInput) -> SM64BreakableBoxOutput {
        if input.kind == .large {
            let broken = input.attacked
            return .init(
                kind: .large, action: input.action, timer: input.timer &+ 1,
                visible: !broken, tangible: !broken, shouldDelete: broken,
                shouldRespawn: false, model: 0x82, scale: 1,
                hitboxRadius: 150, hitboxHeight: 200,
                forwardVelocity: input.forwardVelocity, velocityY: 0,
                spawnCoins: broken ? 1 : 0, spawnDust: false,
                spawnMist: broken, spawnTriangles: broken,
                playLandingSound: false, playBreakSound: broken,
                loadCollisionModel: true
            )
        }

        let action = input.action
        var timer = input.timer &+ 1
        var visible = true
        var tangible = true
        var shouldDelete = false
        var shouldRespawn = false
        var forwardVelocity = input.forwardVelocity
        var velocityY: Float = 0
        var spawnDust = false
        var spawnMist = false
        var spawnTriangles = false
        var playLandingSound = false
        var playBreakSound = false

        switch input.heldState {
        case 1:
            visible = false; tangible = false
        case 2:
            forwardVelocity = 40; velocityY = 20; tangible = true
        case 3:
            tangible = true
        default:
            break
        }

        if input.heldState == 0 {
            if input.moveFlags & 2 != 0 || input.attacked {
                shouldDelete = true; visible = false; tangible = false
                spawnMist = true; spawnTriangles = true; playBreakSound = true
            }
            if input.moveFlags & 1 != 0 {
                playLandingSound = true
                if forwardVelocity > 20 { spawnDust = true }
            }
            if input.lavaDeath { shouldDelete = true; shouldRespawn = true; visible = false; tangible = false }
        }
        if input.released { tangible = true; visible = true; timer = 0 }
        if input.framesSinceReleased > 810 { visible = input.framesSinceReleased % 2 == 0 }
        if input.framesSinceReleased > 900 { shouldDelete = true; shouldRespawn = true; visible = false; tangible = false }

        return .init(
            kind: .small, action: action, timer: timer, visible: visible,
            tangible: tangible, shouldDelete: shouldDelete,
            shouldRespawn: shouldRespawn, model: 0x82, scale: 0.4,
            hitboxRadius: 150, hitboxHeight: 250,
            forwardVelocity: forwardVelocity, velocityY: velocityY,
            spawnCoins: shouldDelete && !shouldRespawn ? 3 : 0,
            spawnDust: spawnDust, spawnMist: spawnMist,
            spawnTriangles: spawnTriangles, playLandingSound: playLandingSound,
            playBreakSound: playBreakSound, loadCollisionModel: false
        )
    }
}
