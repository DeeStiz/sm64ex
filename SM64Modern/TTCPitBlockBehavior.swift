import Foundation

struct SM64TTCPitBlockInitialization: Equatable, Sendable {
    let collisionModelIndex: UInt8
    let peakY: Float
    let initialPositionY: Float
}

struct SM64TTCPitBlockInput: Equatable, Sendable {
    let speedSetting: Int32
    let timer: Int32
    let direction: Int32
    let waitTime: Int32
    let velocityY: Float
    let positionY: Float
    let homeY: Float
    let peakY: Float
    let randomWaitTime: Int32
}

struct SM64TTCPitBlockOutput: Equatable, Sendable {
    let timer: Int32
    let direction: Int32
    let waitTime: Int32
    let velocityY: Float
    let positionY: Float
    let clampedAtEndpoint: Bool
}

/// Value counterpart of `bhv_ttc_pit_block_init/update`. The global TTC
/// setting and random delay are explicit inputs so replay never reads mutable
/// C globals or consumes a hidden random stream.
enum SM64TTCPitBlockBehavior {
    private static let speeds: [[Float]] = [
        [11, -9],
        [18, -11],
        [11, -9],
        [0, 0]
    ]
    private static let waits: [[Int32]] = [
        [20, 30],
        [15, 15],
        [20, -1],
        [0, 0]
    ]

    static func initialize(
        positionY: Float,
        behaviorByte: UInt8,
        speedSetting: Int32
    ) -> SM64TTCPitBlockInitialization {
        precondition((0...3).contains(speedSetting))
        let stopped = speedSetting == 3
        return SM64TTCPitBlockInitialization(
            collisionModelIndex: behaviorByte,
            peakY: positionY + 330,
            initialPositionY: stopped ? positionY + 330 : positionY
        )
    }

    static func update(_ input: SM64TTCPitBlockInput) -> SM64TTCPitBlockOutput {
        precondition((0...3).contains(input.speedSetting))
        var timer = input.timer
        var direction = input.direction
        var waitTime = input.waitTime
        var velocityY = input.velocityY
        var positionY = input.positionY
        var clampedAtEndpoint = false

        if input.timer > input.waitTime {
            positionY += velocityY
            if positionY <= input.homeY {
                positionY = input.homeY
                clampedAtEndpoint = true
            } else if positionY >= input.peakY {
                positionY = input.peakY
                clampedAtEndpoint = true
            }

            if clampedAtEndpoint {
                direction ^= 1
                waitTime = Self.waits[Int(input.speedSetting)][Int(direction & 1)]
                if waitTime < 0 { waitTime = input.randomWaitTime }
                velocityY = Self.speeds[Int(input.speedSetting)][Int(direction & 1)]
                timer = 0
            }
        }

        return SM64TTCPitBlockOutput(
            timer: timer,
            direction: direction,
            waitTime: waitTime,
            velocityY: velocityY,
            positionY: positionY,
            clampedAtEndpoint: clampedAtEndpoint
        )
    }
}
