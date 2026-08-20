import Foundation

enum SM64WaterSplashKind: UInt8, Equatable, Sendable {
    case bubble = 0
    case waterDroplet = 1
    case object = 2
}

struct SM64WaterSplashInput: Equatable, Sendable {
    let kind: SM64WaterSplashKind
    let position: SM64ObjectVector3
    let waterLevel: Float
    let randomScale: Float
    let timer: Int32
    let animationState: Int32
}

struct SM64WaterSplashOutput: Equatable, Sendable {
    let kind: SM64WaterSplashKind
    let position: SM64ObjectVector3
    let scale: SM64ObjectVector3
    let animationState: Int32
    let shouldDelete: Bool
}

/// Value counterparts of `bhv_bubble_splash_init` and
/// `bhv_water_droplet_splash_init`.
enum SM64WaterSplashBehavior {
    static func update(_ input: SM64WaterSplashInput) -> SM64WaterSplashOutput {
        switch input.kind {
        case .bubble:
            return SM64WaterSplashOutput(
                kind: .bubble,
                position: SM64ObjectVector3(
                    x: input.position.x,
                    y: input.waterLevel + 5,
                    z: input.position.z
                ),
                scale: SM64ObjectVector3(x: 0.5, y: 1, z: 0.5),
                animationState: input.animationState &+ 1,
                shouldDelete: input.timer >= 6
            )
        case .waterDroplet:
            return SM64WaterSplashOutput(
                kind: .waterDroplet,
                position: SM64ObjectVector3(
                    x: input.position.x,
                    y: input.timer == 0 ? input.position.y + 5 : input.position.y,
                    z: input.position.z
                ),
                scale: SM64ObjectVector3(
                    x: input.randomScale + 1.5,
                    y: input.randomScale + 1.5,
                    z: input.randomScale + 1.5
                ),
                animationState: input.animationState &+ 1,
                shouldDelete: input.timer >= 6
            )
        case .object:
            return SM64WaterSplashOutput(
                kind: .object,
                position: input.position,
                scale: .one,
                animationState: input.animationState &+ 1,
                shouldDelete: input.timer >= 6
            )
        }
    }
}
