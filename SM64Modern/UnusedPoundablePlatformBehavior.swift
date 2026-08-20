import Foundation

struct SM64UnusedPoundablePlatformInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let marioGroundPounded: Bool
}

struct SM64UnusedPoundablePlatformOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let scale: Float
    let spawnMistParticles: Bool
    let spawnTriangleParticles: Bool
    let loadCollisionModel: Bool
    let shouldDelete: Bool
}

/// Value counterpart of `bhv_unused_poundable_platform`.
enum SM64UnusedPoundablePlatformBehavior {
    static func update(_ input: SM64UnusedPoundablePlatformInput) -> SM64UnusedPoundablePlatformOutput {
        var action = input.action
        var mist = false
        var triangles = false
        var shouldDelete = false
        if input.action == 0 {
            if input.marioGroundPounded {
                action = 1
                mist = true
                triangles = true
            }
        } else if input.timer > 7 {
            shouldDelete = true
        }
        return .init(action: action, timer: input.timer &+ 1, scale: 1.02, spawnMistParticles: mist, spawnTriangleParticles: triangles, loadCollisionModel: true, shouldDelete: shouldDelete)
    }
}
