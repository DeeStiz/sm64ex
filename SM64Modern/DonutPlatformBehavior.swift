import Foundation

enum SM64DonutPlatformRole: UInt8, Equatable, Sendable { case spawner = 0; case platform = 1 }

struct SM64DonutPlatformInput: Equatable, Sendable {
    let role: SM64DonutPlatformRole
    let timer: Int32
    let position: SM64ObjectVector3
    let homePosition: SM64ObjectVector3
    let gravity: Float
    let distanceToMario: Float
    let marioOnPlatform: Bool
    let onGround: Bool
    let spawnMask: UInt32
    let spawnedMask: UInt32
    let platformIndex: Int
}

struct SM64DonutPlatformOutput: Equatable, Sendable {
    let role: SM64DonutPlatformRole
    let timer: Int32
    let position: SM64ObjectVector3
    let gravity: Float
    let spawnedMask: UInt32
    let clearMask: UInt32
    let shouldDelete: Bool
    let exploded: Bool
    let collisionLoaded: Bool
}

/// Value counterpart of the 31-entry Donut Platform spawner and its
/// gravity/landing/destruction child behavior.
enum SM64DonutPlatformBehavior {
    static let relativePositions: [SM64ObjectVector3] = [
        .init(x: signed(0x0B4C), y: signed(0xF7D7), z: signed(0x19A4)),
        .init(x: signed(0xF794), y: signed(0x08A3), z: signed(0xFFA9)),
        .init(x: signed(0x069C), y: signed(0x09D8), z: signed(0xFFE0)),
        .init(x: signed(0x05CF), y: signed(0x09D8), z: signed(0xFFE0)),
        .init(x: signed(0x0502), y: signed(0x09D8), z: signed(0xFFE0)),
        .init(x: signed(0x054C), y: signed(0xF7D7), z: signed(0x19A4)),
        .init(x: signed(0x0A7F), y: signed(0xF7D7), z: signed(0x19A4)),
        .init(x: signed(0x09B2), y: signed(0xF7D7), z: signed(0x19A4)),
        .init(x: signed(0x06E6), y: signed(0xF7D7), z: signed(0x19A4)),
        .init(x: signed(0x0619), y: signed(0xF7D7), z: signed(0x19A4)),
        .init(x: signed(0xEFB5), y: signed(0xF7D7), z: signed(0x19A4)),
        .init(x: signed(0x00E6), y: signed(0xF7D7), z: signed(0x19A4)),
        .init(x: signed(0x0019), y: signed(0xF7D7), z: signed(0x19A4)),
        .init(x: signed(0xFF4D), y: signed(0xF7D7), z: signed(0x19A4)),
        .init(x: signed(0xF081), y: signed(0xF7D7), z: signed(0x19A4)),
        .init(x: signed(0xE34F), y: signed(0xF671), z: signed(0x197A)),
        .init(x: signed(0xEEE8), y: signed(0xF7D7), z: signed(0x19A4)),
        .init(x: signed(0xE74F), y: signed(0xF7D7), z: signed(0x197A)),
        .init(x: signed(0xE683), y: signed(0xF7D7), z: signed(0x197A)),
        .init(x: signed(0xE5B6), y: signed(0xF7D7), z: signed(0x197A)),
        .init(x: signed(0xEE83), y: signed(0xF4A4), z: signed(0x19A4)),
        .init(x: signed(0xE41C), y: signed(0xF671), z: signed(0x197A)),
        .init(x: signed(0xE4E9), y: signed(0xF671), z: signed(0x197A)),
        .init(x: signed(0xECE9), y: signed(0xF4A4), z: signed(0x19A4)),
        .init(x: signed(0xEDB6), y: signed(0xF4A4), z: signed(0x19A4)),
        .init(x: signed(0xFC3F), y: signed(0x0A66), z: signed(0xFF45)),
        .init(x: signed(0x00EF), y: signed(0x04CD), z: signed(0xFF53)),
        .init(x: signed(0x0022), y: signed(0x04CD), z: signed(0xFF53)),
        .init(x: signed(0xFF57), y: signed(0x04CD), z: signed(0xFF53)),
        .init(x: signed(0xFB73), y: signed(0x0A66), z: signed(0xFF45)),
        .init(x: signed(0xFD0C), y: signed(0x0A66), z: signed(0xFF45)),
    ]

    static func update(_ input: SM64DonutPlatformInput) -> SM64DonutPlatformOutput {
        if input.role == .spawner {
            let newMask = input.spawnMask & ~input.spawnedMask
            return .init(
                role: .spawner, timer: input.timer &+ 1, position: input.position,
                gravity: input.gravity, spawnedMask: input.spawnedMask | newMask,
                clearMask: 0, shouldDelete: false, exploded: false, collisionLoaded: false
            )
        }

        var timer = input.timer &+ 1
        var position = input.position
        var gravity = input.gravity
        var shouldDelete = false
        var exploded = false
        var clearMask: UInt32 = 0

        if input.timer != 0 && (input.onGround || input.distanceToMario > 2_500) {
            clearMask = UInt32(1) << UInt32(input.platformIndex)
            if input.distanceToMario > 2_500 {
                shouldDelete = true
            } else {
                exploded = true
            }
        } else if gravity == 0 {
            if input.marioOnPlatform {
                if input.timer > 15 { gravity = -0.1 }
            } else {
                position = input.homePosition
                timer = 0
            }
        } else {
            position.y += gravity
            gravity -= 0.4
        }

        return .init(
            role: .platform, timer: timer, position: position, gravity: gravity,
            spawnedMask: 0, clearMask: clearMask, shouldDelete: shouldDelete,
            exploded: exploded, collisionLoaded: !shouldDelete
        )
    }

    private static func signed(_ raw: UInt16) -> Float { Float(Int16(bitPattern: raw)) }
}
