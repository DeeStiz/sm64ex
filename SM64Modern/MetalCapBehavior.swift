import Foundation

struct SM64MetalCapInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let faceYaw: Int32
    let forwardVelocity: Float
    let interacted: Bool
}

struct SM64MetalCapOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let faceYaw: Int32
    let gravity: Float
    let friction: Float
    let buoyancy: Float
    let opacity: Int32
    let tangible: Bool
    let deactivated: Bool
    let hitboxRadius: Float
    let hitboxHeight: Float
}

enum SM64MetalCapBehavior {
    static func update(_ input: SM64MetalCapInput) -> SM64MetalCapOutput {
        let yaw = input.action == 0 ? input.faceYaw &+ Int32(input.forwardVelocity * 128) : input.faceYaw
        let tangible = input.timer > 20
        return .init(action: input.action, timer: input.timer &+ 1, faceYaw: yaw, gravity: 2.4, friction: 0.999, buoyancy: 1.5, opacity: 255, tangible: tangible, deactivated: input.timer > 300 || input.interacted, hitboxRadius: 80, hitboxHeight: 80)
    }
}
