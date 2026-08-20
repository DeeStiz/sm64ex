import Foundation

enum SM64EnvironmentGateRole: UInt8, Equatable, Sendable {
    case bowserSubDoor = 0
    case bowsersSub = 1
    case moatGrills = 2
    case invisibleObjectsUnderBridge = 3
}

struct SM64EnvironmentGateInput: Equatable, Sendable {
    let role: SM64EnvironmentGateRole
    let timer: Int32
    let submarineUnlocked: Bool
    let moatDrained: Bool
}

struct SM64EnvironmentGateOutput: Equatable, Sendable {
    let role: SM64EnvironmentGateRole
    let timer: Int32
    let shouldDelete: Bool
    let loadCollisionModel: Bool
    let modelNone: Bool
    let environmentLevel6: Int32?
    let environmentLevel12: Int32?
}

enum SM64EnvironmentGateBehavior {
    static func update(_ input: SM64EnvironmentGateInput) -> SM64EnvironmentGateOutput {
        switch input.role {
        case .bowserSubDoor, .bowsersSub:
            return .init(role: input.role, timer: input.timer &+ 1,
                         shouldDelete: input.submarineUnlocked,
                         loadCollisionModel: !input.submarineUnlocked,
                         modelNone: false, environmentLevel6: nil, environmentLevel12: nil)
        case .moatGrills:
            return .init(role: input.role, timer: input.timer &+ 1,
                         shouldDelete: false, loadCollisionModel: !input.moatDrained,
                         modelNone: input.moatDrained, environmentLevel6: nil, environmentLevel12: nil)
        case .invisibleObjectsUnderBridge:
            let drained = input.moatDrained
            return .init(role: input.role, timer: input.timer &+ 1,
                         shouldDelete: true, loadCollisionModel: false,
                         modelNone: false,
                         environmentLevel6: drained ? -800 : nil,
                         environmentLevel12: drained ? -800 : nil)
        }
    }
}
