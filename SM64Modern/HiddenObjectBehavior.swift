import Foundation

enum SM64HiddenObjectAction: Int32, Equatable, Sendable { case hidden = 0; case visible = 1; case broken = 2 }
struct SM64HiddenObjectInput: Equatable, Sendable {
    let action: SM64HiddenObjectAction
    let timer: Int32
    let variant: Int32
    let switchAction: Int32?
    let attackedOrGroundPounded: Bool
}
struct SM64HiddenObjectOutput: Equatable, Sendable {
    let action: SM64HiddenObjectAction
    let timer: Int32
    let visible: Bool
    let tangible: Bool
    let scale: Float
    let numLootCoins: Int32
    let spawnMist: Bool
    let spawnTriangleBreak: Bool
    let playBreakSound: Bool
    let loadCollisionModel: Bool
}
enum SM64HiddenObjectBehavior {
    static func update(_ input: SM64HiddenObjectInput) -> SM64HiddenObjectOutput {
        let breakable = input.variant == 0
        var action = input.action
        var timer = input.timer &+ 1
        var visible = false
        var tangible = false
        let scale: Float = input.variant == 3 ? 1.5 : 1
        var spawnMist = false
        var spawnTriangleBreak = false
        var playBreakSound = false
        var loadCollision = false
        switch input.action {
        case .hidden:
            if input.switchAction == 2 { action = .visible; timer = 0; visible = true; tangible = true }
        case .visible:
            visible = true; tangible = true; loadCollision = true
            if input.timer >= 360 {
                let blinking = input.timer - 360
                visible = blinking % 2 == 0
                if blinking / 2 > 20 { action = .hidden; timer = 0; visible = false; tangible = false }
            }
            if breakable && input.attackedOrGroundPounded {
                action = .broken; timer = 0; visible = false; tangible = false; loadCollision = false
                spawnMist = true; spawnTriangleBreak = true; playBreakSound = true
            }
        case .broken:
            if input.switchAction == 0 { action = .hidden; timer = 0 }
        }
        return .init(action: action, timer: timer, visible: visible, tangible: tangible, scale: scale, numLootCoins: input.variant == 1 ? 3 : (input.variant == 2 ? 5 : 0), spawnMist: spawnMist, spawnTriangleBreak: spawnTriangleBreak, playBreakSound: playBreakSound, loadCollisionModel: loadCollision)
    }
}
