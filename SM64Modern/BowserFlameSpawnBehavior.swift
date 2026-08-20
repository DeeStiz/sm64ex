import Foundation

struct SM64BowserFlameSpawnInput: Equatable, Sendable {
    let objectPosition: SM64ObjectVector3
    let bowserPosition: SM64ObjectVector3
    let bowserYaw: Int32
    let bowserSoundState: Int32
    let animationFrame: Int32
    let animationEndFrame: Int32
    let sampleX: Float
    let sampleY: Float
    let sampleZ: Float
    let samplePitch: Int32
    let sampleYaw: Int32
}

struct SM64BowserFlameSpawnOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let movePitch: Int32
    let shouldSpawnFlame: Bool
}

enum SM64BowserFlameSpawnBehavior {
    static func update(_ input: SM64BowserFlameSpawnInput) -> SM64BowserFlameSpawnOutput {
        var frame = input.animationFrame + 1
        if frame == input.animationEndFrame { frame = 0 }
        let active = input.bowserSoundState == 6 && frame > 45 && frame < 85
        let yaw = Int16(truncatingIfNeeded: input.bowserYaw)
        let sinYaw = SM64CanonicalTrig.sins(yaw)
        let cosYaw = SM64CanonicalTrig.coss(yaw)
        let position = SM64ObjectVector3(
            x: input.bowserPosition.x + input.sampleZ * sinYaw + input.sampleX * cosYaw,
            y: input.bowserPosition.y + input.sampleY,
            z: input.bowserPosition.z + input.sampleZ * cosYaw - input.sampleX * sinYaw
        )
        return SM64BowserFlameSpawnOutput(
            position: active ? position : input.objectPosition,
            moveYaw: active ? input.sampleYaw &+ input.bowserYaw : input.bowserYaw,
            movePitch: active ? input.samplePitch &+ 0xC00 : 0,
            shouldSpawnFlame: active && frame % 2 == 0
        )
    }
}
