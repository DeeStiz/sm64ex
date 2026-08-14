import Foundation

enum SM64MarioWallAnimationID {
    static let pushing: UInt16 = 0x6C
    static let sidestepLeft: UInt16 = 0x7F
    static let sidestepRight: UInt16 = 0x80
}

enum SM64MarioWallSoundKind: UInt8, Equatable, Sendable {
    case none = 0
    case step = 1
    case movingTerrainSlide = 2
}

struct SM64MarioWallResponseProbe: Equatable, Sendable {
    let normalX: Float
    let normalZ: Float
}

struct SM64MarioWallResponseInput: Equatable, Sendable {
    let startPosition: SM64ObjectVector3
    let position: SM64ObjectVector3
    let velocity: SM64ObjectVector3
    let forwardVelocity: Float
    let faceYaw: Int32
    let animationFrame: Int16
    let animationPastFrame1: Bool
    let animationPastFrame2: Bool
    let terrainSoundAddend: UInt32
    let floorSlopePitch: Int16
    let wall: SM64MarioWallResponseProbe?
}

struct SM64MarioWallResponseResult: Equatable, Sendable {
    let velocity: SM64ObjectVector3
    let forwardVelocity: Float
    let flags: UInt32
    let animationID: UInt16
    let animationAcceleration: Int32
    let sound: SM64MarioWallSoundKind
    let particleDust: Bool
    let actionState: UInt16
    let actionArgument: UInt32
    let gfxAngle: SM64ObjectAngles
}

/// Value counterpart of `push_or_sidle_wall`. The floor-slope lookup and
/// object animation/audio delivery are supplied as scalar snapshots/effects;
/// no Mario or Surface pointer crosses this boundary.
enum SM64MarioWallResponse {
    static let unknown31: UInt32 = 0x80000000

    static func update(_ input: SM64MarioWallResponseInput) -> SM64MarioWallResponseResult? {
        guard input.startPosition.x.isFinite,
              input.startPosition.z.isFinite,
              input.position.x.isFinite,
              input.position.z.isFinite,
              input.velocity.x.isFinite,
              input.velocity.y.isFinite,
              input.velocity.z.isFinite,
              input.forwardVelocity.isFinite else {
            return nil
        }
        if let wall = input.wall,
           (!wall.normalX.isFinite || !wall.normalZ.isFinite) {
            return nil
        }

        var velocity = input.velocity
        var forwardVelocity = input.forwardVelocity
        if forwardVelocity > 6 {
            forwardVelocity = 6
            let yaw = Int16(truncatingIfNeeded: input.faceYaw)
            velocity.x = SM64CanonicalTrig.sins(yaw) * forwardVelocity
            velocity.z = SM64CanonicalTrig.coss(yaw) * forwardVelocity
        }

        guard let wall = input.wall else {
            return SM64MarioWallResponseResult(
                velocity: velocity,
                forwardVelocity: forwardVelocity,
                flags: unknown31,
                animationID: SM64MarioWallAnimationID.pushing,
                animationAcceleration: stepAcceleration(
                    start: input.startPosition,
                    position: input.position
                ),
                sound: stepSound(input),
                particleDust: false,
                actionState: 0,
                actionArgument: 0,
                gfxAngle: .zero
            )
        }

        let wallAngle = SM64CanonicalTrig.atan2s(y: wall.normalZ, x: wall.normalX)
        let faceYaw = Int16(truncatingIfNeeded: input.faceYaw)
        let wallDYaw = Int32(Int16(truncatingIfNeeded: Int32(wallAngle) - Int32(faceYaw)))
        let acceleration = stepAcceleration(start: input.startPosition, position: input.position)
        if wallDYaw <= -0x71C8 || wallDYaw >= 0x71C8 {
            return SM64MarioWallResponseResult(
                velocity: velocity,
                forwardVelocity: forwardVelocity,
                flags: unknown31,
                animationID: SM64MarioWallAnimationID.pushing,
                animationAcceleration: acceleration,
                sound: stepSound(input),
                particleDust: false,
                actionState: 0,
                actionArgument: 0,
                gfxAngle: .zero
            )
        }

        let facingWallYaw = Int16(truncatingIfNeeded: Int32(wallAngle) + 0x8000)
        let sound: SM64MarioWallSoundKind = input.animationFrame < 20
            ? .movingTerrainSlide
            : .none
        return SM64MarioWallResponseResult(
            velocity: velocity,
            forwardVelocity: forwardVelocity,
            flags: 0,
            animationID: wallDYaw < 0
                ? SM64MarioWallAnimationID.sidestepRight
                : SM64MarioWallAnimationID.sidestepLeft,
            animationAcceleration: acceleration,
            sound: sound,
            particleDust: input.animationFrame < 20,
            actionState: 1,
            actionArgument: UInt32(Int32(wallAngle) + 0x8000),
            gfxAngle: SM64ObjectAngles(pitch: 0, yaw: Int32(facingWallYaw), roll: Int32(input.floorSlopePitch))
        )
    }

    private static func stepAcceleration(
        start: SM64ObjectVector3,
        position: SM64ObjectVector3
    ) -> Int32 {
        let dx = position.x - start.x
        let dz = position.z - start.z
        let movedDistance = sqrt(dx * dx + dz * dz)
        let scaled = Double(movedDistance) * 2 * 65_536
        guard scaled.isFinite,
              scaled >= Double(Int32.min),
              scaled <= Double(Int32.max) else { return Int32.max }
        return Int32(scaled)
    }

    private static func stepSound(_ input: SM64MarioWallResponseInput) -> SM64MarioWallSoundKind {
        input.animationPastFrame1 || input.animationPastFrame2 ? .step : .none
    }
}
