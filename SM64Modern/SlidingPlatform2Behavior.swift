import Foundation

struct SM64SlidingPlatform2Initialization: Equatable, Sendable {
    let distance: Float
    let speed: Float
    let moveYaw: Int32
    let verticalSign: Float
}

struct SM64SlidingPlatform2Input: Equatable, Sendable {
    let timer: Int32
    let homePosition: SM64ObjectVector3
    let moveYaw: Int32
    let offset: Float
    let speed: Float
    let distance: Float
    let verticalSign: Float
}

struct SM64SlidingPlatform2Output: Equatable, Sendable {
    let position: SM64ObjectVector3
    let offset: Float
    let speed: Float
    let timer: Int32
}

enum SM64SlidingPlatform2Behavior {
    static func initialize(
        behaviorParams: UInt32,
        moveYaw: Int32
    ) -> SM64SlidingPlatform2Initialization {
        let packed = UInt16(truncatingIfNeeded: behaviorParams >> 16)
        let variant = Int((packed & 0x0380) >> 7)
        let distance = Float(packed & 0x003F) * 50
        if variant < 5 || variant > 6 {
            let yaw = packed & 0x0040 != 0 ? moveYaw &+ 0x8000 : moveYaw
            return SM64SlidingPlatform2Initialization(
                distance: distance,
                speed: 15,
                moveYaw: yaw,
                verticalSign: 0
            )
        }
        return SM64SlidingPlatform2Initialization(
            distance: distance,
            speed: 10,
            moveYaw: moveYaw,
            verticalSign: packed & 0x0040 != 0 ? -1 : 1
        )
    }

    static func update(_ input: SM64SlidingPlatform2Input) -> SM64SlidingPlatform2Output {
        var timer = input.timer
        var offset = input.offset
        var speed = input.speed
        if timer > 10 {
            offset += speed
            if offset < -input.distance {
                offset = -input.distance
                speed = -speed
                timer = 0
            } else if offset > 0 {
                offset = 0
                speed = -speed
                timer = 0
            }
        }
        let yaw = Int16(truncatingIfNeeded: input.moveYaw)
        let position: SM64ObjectVector3
        if input.verticalSign != 0 {
            position = SM64ObjectVector3(
                x: input.homePosition.x,
                y: input.homePosition.y + offset * input.verticalSign,
                z: input.homePosition.z
            )
        } else {
            position = SM64ObjectVector3(
                x: input.homePosition.x + offset * SM64CanonicalTrig.coss(yaw),
                y: input.homePosition.y,
                z: input.homePosition.z + offset * SM64CanonicalTrig.sins(yaw)
            )
        }
        return SM64SlidingPlatform2Output(
            position: position,
            offset: offset,
            speed: speed,
            timer: timer &+ 1
        )
    }
}
