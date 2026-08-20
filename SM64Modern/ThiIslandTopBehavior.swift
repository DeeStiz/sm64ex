import Foundation

enum SM64ThiIslandTopRole: UInt8, Equatable, Sendable { case huge, tiny }

struct SM64ThiIslandTopInput: Equatable, Sendable {
    let role: SM64ThiIslandTopRole
    let action: Int32
    let timer: Int32
    let waterDrained: Bool
    let distanceToMario: Float
    let marioGroundPound: Bool
}

struct SM64ThiIslandTopOutput: Equatable, Sendable {
    let action: Int32
    let environmentDelta: Int32
    let environmentSet: Int32?
    let waterDrained: Bool
    let hidden: Bool
    let loadCollisionModel: Bool
    let spawnParticles: Bool
    let spawnTriangleParticles: Bool
    let playActivateSound: Bool
    let playDrainSound: Bool
    let playPuzzleJingle: Bool
}

enum SM64ThiIslandTopBehavior {
    static func update(_ input: SM64ThiIslandTopInput) -> SM64ThiIslandTopOutput {
        var action = input.action
        var environmentDelta: Int32 = 0
        var environmentSet: Int32?
        var waterDrained = input.waterDrained
        var hidden = false
        var loadCollision = false
        var particles = false
        var triangles = false
        var activate = false
        var drainSound = false
        var jingle = false
        switch input.role {
        case .huge:
            if waterDrained {
                if input.timer == 0 { environmentSet = 3_000 }
                hidden = true
            } else {
                loadCollision = true
            }
        case .tiny:
            if !waterDrained {
                if input.action == 0 {
                    if input.distanceToMario < 500 && input.marioGroundPound {
                        action = 1; particles = true; triangles = true; activate = true; hidden = true
                    }
                } else if input.timer < 50 {
                    environmentDelta = -1; drainSound = true
                } else {
                    waterDrained = true; jingle = true; action = 2
                }
            } else {
                if input.timer == 0 { environmentSet = 700 }
                hidden = true
            }
        }
        return .init(action: action, environmentDelta: environmentDelta, environmentSet: environmentSet, waterDrained: waterDrained, hidden: hidden, loadCollisionModel: loadCollision, spawnParticles: particles, spawnTriangleParticles: triangles, playActivateSound: activate, playDrainSound: drainSound, playPuzzleJingle: jingle)
    }
}
