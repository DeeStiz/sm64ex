import Foundation

enum SM64ButterflyAction: Int32, Equatable, Sendable { case resting = 0; case followMario = 1; case returnHome = 2 }

struct SM64ButterflyInput: Equatable, Sendable {
    let action: SM64ButterflyAction
    let position: SM64ObjectVector3
    let homePosition: SM64ObjectVector3
    let moveYaw: Int32
    let movePitch: Int32
    let yPhase: Int32
    let distanceToMario: Float
    let homeDistance: Float
    let angleToMario: Int32
    let angleToHome: Int32
    let pitchToHome: Int32
}

struct SM64ButterflyOutput: Equatable, Sendable {
    let action: SM64ButterflyAction
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let movePitch: Int32
    let yPhase: Int32
    let animationState: Int32
}

enum SM64ButterflyBehavior {
    static func update(_ input: SM64ButterflyInput) -> SM64ButterflyOutput {
        var action = input.action
        var position = input.position
        var yaw = input.moveYaw
        var pitch = input.movePitch
        var animation = 1
        var nextPhase = input.yPhase &+ 1

        switch input.action {
        case .resting:
            if input.distanceToMario < 1_000 {
                action = .followMario
                yaw = input.angleToMario
                animation = 0
            }
        case .followMario:
            yaw = approachAngle(current: yaw, target: input.angleToMario, increment: 0x300)
            pitch = approachAngle(current: pitch, target: input.pitchToHome, increment: 0x500)
            position = step(position: position, yaw: yaw, pitch: pitch, speed: 7, phase: nextPhase, follow: true)
            animation = 0
            if input.homeDistance > 1_200 { action = .returnHome }
        case .returnHome:
            yaw = approachAngle(current: yaw, target: input.angleToHome, increment: 0x800)
            pitch = approachAngle(current: pitch, target: input.pitchToHome, increment: 0x50)
            position = step(position: position, yaw: yaw, pitch: pitch, speed: 7, phase: nextPhase, follow: false)
            if input.homeDistance * input.homeDistance < 144 {
                action = .resting
                position = input.homePosition
                animation = 1
            }
        }
        if nextPhase >= 101 { nextPhase = 0 }
        return .init(action: action, position: position, moveYaw: yaw, movePitch: pitch, yPhase: nextPhase, animationState: Int32(animation))
    }

    private static func step(position: SM64ObjectVector3, yaw: Int32, pitch: Int32, speed: Float, phase: Int32, follow: Bool) -> SM64ObjectVector3 {
        let yaw16 = Int16(truncatingIfNeeded: yaw)
        let pitch16 = Int16(truncatingIfNeeded: pitch)
        var result = position
        result.x += SM64CanonicalTrig.sins(yaw16) * speed
        result.z += SM64CanonicalTrig.coss(yaw16) * speed
        result.y -= SM64CanonicalTrig.sins(pitch16) * speed
        if follow {
            result.y -= SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: Int32(Float(phase) * 655.36))) * 5
        }
        return result
    }

    private static func approachAngle(current: Int32, target: Int32, increment: Int32) -> Int32 {
        let delta = Int16(truncatingIfNeeded: target &- current)
        if delta > Int16(increment) { return current &+ increment }
        if delta < -Int16(increment) { return current &- increment }
        return target
    }
}
