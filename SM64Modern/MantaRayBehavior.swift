import Foundation

struct SM64MantaRayInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let movePitch: Int32
    let faceRoll: Int32
    let trajectoryIndex: Int
    let ringsCollected: Int32
}

struct SM64MantaRayOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let movePitch: Int32
    let faceRoll: Int32
    let trajectoryIndex: Int
    let spawnRing: Bool
    let ringPosition: SM64ObjectVector3
    let ringYaw: Int32
    let ringPitch: Int32
    let spawnStar: Bool
}

/// Value counterpart of the Manta Ray trajectory/ring loop.
enum SM64MantaRayBehavior {
    static let trajectory: [SM64ObjectVector3] = [
        .init(x: -4500, y: -1380, z: -40), .init(x: -4120, y: -2240, z: 740),
        .init(x: -3280, y: -3080, z: 1040), .init(x: -2240, y: -3320, z: 720),
        .init(x: -1840, y: -3140, z: -280), .init(x: -2320, y: -2480, z: -1100),
        .init(x: -3220, y: -1600, z: -1360), .init(x: -4180, y: -1020, z: -1040)
    ]

    static func update(_ input: SM64MantaRayInput) -> SM64MantaRayOutput {
        let index = min(max(input.trajectoryIndex, 0), trajectory.count - 1)
        let target = trajectory[index]
        let nextIndex = index == trajectory.count - 1 ? 0 : index + 1
        let spawn = input.action == 0 && (input.timer == 0 || input.timer == 50 || input.timer == 150 || input.timer == 200 || input.timer == 250)
        let star = input.action == 0 && input.ringsCollected == 5
        let yaw = input.moveYaw &+ 0x80
        let pitch = input.movePitch &+ 0x80
        let ringYaw = yaw
        let ringPitch = pitch &+ 0x4000
        let ringPosition = SM64ObjectVector3(
            x: input.position.x + SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: yaw &+ 0x8000)) * 200,
            y: input.position.y + 10 + SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: pitch)) * 200,
            z: input.position.z + SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: yaw &+ 0x8000)) * 200
        )
        return .init(action: star ? 1 : input.action, timer: input.timer == 300 ? 1 : input.timer &+ 1, position: target, moveYaw: yaw, movePitch: pitch, faceRoll: input.faceRoll, trajectoryIndex: nextIndex, spawnRing: spawn, ringPosition: ringPosition, ringYaw: ringYaw, ringPitch: ringPitch, spawnStar: star)
    }
}
