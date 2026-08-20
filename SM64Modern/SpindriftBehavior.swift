import Foundation

struct SM64SpindriftInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let homePosition: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let lateralDistanceToHome: Float
    let distanceToMario: Float
    let angleToMario: Int32
    let angleToHome: Int32
    let attacked: Bool
}

struct SM64SpindriftOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let interactable: Bool
    let playDyingSound: Bool
    let resetInteraction: Bool
    let hitboxRadius: Float
    let hitboxHeight: Float
    let damageOrCoinValue: Int32
    let health: Int32
    let lootCoins: Int32
}

/// Value counterpart of `bhv_spindrift_loop`.
enum SM64SpindriftBehavior {
    static func update(_ input: SM64SpindriftInput) -> SM64SpindriftOutput {
        var action = input.action
        let timer = input.timer &+ 1
        var position = input.position
        var moveYaw = input.moveYaw
        var forwardVelocity = input.forwardVelocity
        var interactable = true
        var resetInteraction = false
        let dying = input.attacked
        if dying { action = 1 }
        if action == 0 {
            forwardVelocity = min(forwardVelocity + 1, 4)
            let target: Int32
            if input.lateralDistanceToHome > 1_000 { target = input.angleToHome }
            else if input.distanceToMario > 300 { target = input.angleToMario }
            else { target = moveYaw }
            moveYaw = approachAngle(current: moveYaw, target: target, increment: 0x400)
        } else if action == 1 {
            interactable = false
            forwardVelocity = -10
            if input.timer > 20 { action = 0; resetInteraction = true; interactable = true }
        }
        let yaw = Int16(truncatingIfNeeded: moveYaw)
        position.x += SM64CanonicalTrig.sins(yaw) * forwardVelocity
        position.z += SM64CanonicalTrig.coss(yaw) * forwardVelocity
        return .init(action: action, timer: timer, position: position, moveYaw: moveYaw, forwardVelocity: forwardVelocity, interactable: interactable, playDyingSound: dying, resetInteraction: resetInteraction, hitboxRadius: 90, hitboxHeight: 80, damageOrCoinValue: 2, health: 1, lootCoins: 3)
    }

    private static func approachAngle(current: Int32, target: Int32, increment: Int32) -> Int32 {
        let delta = Int16(truncatingIfNeeded: target &- current)
        if delta > Int16(increment) { return current &+ increment }
        if delta < -Int16(increment) { return current &- increment }
        return target
    }
}
