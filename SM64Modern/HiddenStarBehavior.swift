import Foundation

enum SM64HiddenStarAction: Int32, Equatable, Sendable {
    case waiting = 0
    case reveal = 1
}

struct SM64HiddenStarParentInput: Equatable, Sendable {
    let action: SM64HiddenStarAction
    let timer: Int32
    let triggerCounter: Int32
    let requiredCounter: Int32

    init(action: SM64HiddenStarAction, timer: Int32, triggerCounter: Int32, requiredCounter: Int32 = 5) {
        self.action = action; self.timer = timer; self.triggerCounter = triggerCounter; self.requiredCounter = requiredCounter
    }
}

struct SM64HiddenStarParentOutput: Equatable, Sendable {
    let action: SM64HiddenStarAction
    let triggerCounter: Int32
    let spawnStar: Bool
    let spawnMist: Bool
    let shouldDelete: Bool
}

struct SM64HiddenStarTriggerInput: Equatable, Sendable {
    let triggerCounter: Int32
    let collidedWithMario: Bool
    let requiredCounter: Int32

    init(triggerCounter: Int32, collidedWithMario: Bool, requiredCounter: Int32 = 5) {
        self.triggerCounter = triggerCounter; self.collidedWithMario = collidedWithMario; self.requiredCounter = requiredCounter
    }
}

struct SM64HiddenStarTriggerOutput: Equatable, Sendable {
    let triggerCounter: Int32
    let spawnNumber: Int32?
    let playSound: Bool
    let shouldDelete: Bool
}

enum SM64HiddenStarBehavior {
    static func updateParent(_ input: SM64HiddenStarParentInput) -> SM64HiddenStarParentOutput {
        var action = input.action
        var spawnStar = false
        var spawnMist = false
        var shouldDelete = false
        switch input.action {
        case .waiting:
            if input.triggerCounter == input.requiredCounter { action = .reveal }
        case .reveal:
            if input.timer > 2 {
                spawnStar = true
                spawnMist = true
                shouldDelete = true
            }
        }
        return .init(action: action, triggerCounter: input.triggerCounter, spawnStar: spawnStar, spawnMist: spawnMist, shouldDelete: shouldDelete)
    }

    static func updateTrigger(_ input: SM64HiddenStarTriggerInput) -> SM64HiddenStarTriggerOutput {
        guard input.collidedWithMario else {
            return .init(triggerCounter: input.triggerCounter, spawnNumber: nil, playSound: false, shouldDelete: false)
        }
        let counter = input.triggerCounter &+ 1
        return .init(triggerCounter: counter, spawnNumber: counter == input.requiredCounter ? nil : counter, playSound: true, shouldDelete: true)
    }
}
