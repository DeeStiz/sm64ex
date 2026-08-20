import Foundation

enum SM64CoffinRole: UInt8, Equatable, Sendable { case spawner = 0; case coffin = 1 }
enum SM64CoffinAction: UInt8, Equatable, Sendable { case idle = 0; case standUp = 1 }

struct SM64CoffinOutput: Equatable, Sendable {
    let role: SM64CoffinRole
    let action: SM64CoffinAction
    let faceAngles: SM64ObjectAngles
    let scale: SM64ObjectVector3
    let spawnCoffins: Bool
    let collisionLoaded: Bool
}

enum SM64CoffinBehavior {
    static let relativePositions: [SM64ObjectVector3] = [
        .init(x: 412, y: 0, z: -150), .init(x: 762, y: 0, z: -150), .init(x: 1112, y: 0, z: -150),
        .init(x: 412, y: 0, z: 150), .init(x: 762, y: 0, z: 150), .init(x: 1112, y: 0, z: 150),
    ]

    static func updateSpawner(timer: Int32, inDifferentRoom: Bool) -> SM64CoffinOutput {
        .init(role: .spawner, action: inDifferentRoom ? .idle : .standUp, faceAngles: .zero, scale: .one, spawnCoffins: timer == 0 && !inDifferentRoom, collisionLoaded: false)
    }

    static func updateCoffin(
        action: SM64CoffinAction,
        timer: Int32,
        staticCoffin: Bool,
        distanceToMario: Float,
        faceAngles: SM64ObjectAngles
    ) -> SM64CoffinOutput {
        var nextAction = action
        var nextFace = faceAngles
        if !staticCoffin {
            switch action {
            case .idle where timer > 60 && distanceToMario < 150:
                nextAction = .standUp
            case .standUp:
                nextFace.pitch = min(nextFace.pitch &+ 1_000, 0x4000)
                if nextFace.pitch == 0x4000 && timer > 60 { nextAction = .idle; nextFace.roll = 0 }
            default:
                break
            }
        }
        return .init(role: .coffin, action: nextAction, faceAngles: nextFace, scale: .init(x: 1, y: 1.1, z: 1), spawnCoffins: false, collisionLoaded: true)
    }
}
