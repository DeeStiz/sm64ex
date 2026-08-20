import Foundation

struct SM64VanishCapInput: Equatable, Sendable { let action: Int32; let timer: Int32; let faceYaw: Int32; let forwardVelocity: Float; let interacted: Bool }
struct SM64VanishCapOutput: Equatable, Sendable { let action: Int32; let timer: Int32; let faceYaw: Int32; let gravity: Float; let friction: Float; let buoyancy: Float; let opacity: Int32; let tangible: Bool; let deactivated: Bool; let hitboxRadius: Float; let hitboxHeight: Float }
enum SM64VanishCapBehavior {
    static func update(_ input: SM64VanishCapInput) -> SM64VanishCapOutput {
        let yaw = input.action == 0 ? input.faceYaw &+ Int32(input.forwardVelocity * 128) : input.faceYaw
        return .init(action: input.action, timer: input.timer &+ 1, faceYaw: yaw, gravity: 1.2, friction: 0.999, buoyancy: 0.9, opacity: 150, tangible: input.timer > 20, deactivated: input.timer > 300 || input.interacted, hitboxRadius: 80, hitboxHeight: 80)
    }
}
