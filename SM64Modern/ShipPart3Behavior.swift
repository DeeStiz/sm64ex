import Foundation

enum SM64ShipPart3Role: UInt8, Equatable, Sendable {
    case decorative = 0
    case collision = 1
}

struct SM64ShipPart3Output: Equatable, Sendable {
    let role: SM64ShipPart3Role
    let position: SM64ObjectVector3
    let faceAngles: SM64ObjectAngles
    let angleVelocity: SM64ObjectAngles
    let collisionLoaded: Bool
}

enum SM64ShipPart3Behavior {
    static func update(
        role: SM64ShipPart3Role,
        homePosition: SM64ObjectVector3,
        phase: Int32,
        rollPhase: Int32,
        previousAngles: SM64ObjectAngles
    ) -> SM64ShipPart3Output {
        let nextPhase = phase &+ 0x100
        let nextAngles = SM64ObjectAngles(
            pitch: Int32(SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: nextPhase)) * 1024),
            yaw: previousAngles.yaw,
            roll: Int32(SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: rollPhase)) * 1024)
        )
        return .init(
            role: role,
            position: homePosition,
            faceAngles: nextAngles,
            angleVelocity: .init(
                pitch: nextAngles.pitch &- previousAngles.pitch,
                yaw: 0,
                roll: nextAngles.roll &- previousAngles.roll
            ),
            collisionLoaded: role == .collision
        )
    }
}
