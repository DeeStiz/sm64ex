import Foundation
struct SM64LllFloatingWoodBridgeInput: Equatable, Sendable { let action: Int32; let distanceToMario: Float }
struct SM64LllFloatingWoodBridgeOutput: Equatable, Sendable { let action: Int32; let spawnChildren: Bool }
enum SM64LllFloatingWoodBridgeBehavior {
    static func update(_ input: SM64LllFloatingWoodBridgeInput) -> SM64LllFloatingWoodBridgeOutput {
        var action = input.action; var spawn = false
        switch input.action { case 0: if input.distanceToMario < 2500 { action=1; spawn=true }; case 1: if input.distanceToMario > 2600 { action=2 }; case 2: action=0; default: action=0 }
        return SM64LllFloatingWoodBridgeOutput(action: action, spawnChildren: spawn)
    }
}
