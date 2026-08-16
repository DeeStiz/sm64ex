import Foundation

struct SM64ExplosionBubbleSpawnInput: Equatable, Sendable {
    let positionOffset: SM64ObjectVector3
    let microOffset: SM64ObjectVector3
    let expansionRateX: Int32
    let expansionRateY: Int32
    let initialTimer: UInt32
    let velocityY: Float

    init(
        positionOffset: SM64ObjectVector3 = .zero,
        microOffset: SM64ObjectVector3 = .zero,
        expansionRateX: Int32 = 0x800,
        expansionRateY: Int32 = 0x800,
        initialTimer: UInt32 = 0,
        velocityY: Float = 4
    ) {
        self.positionOffset = positionOffset
        self.microOffset = microOffset
        self.expansionRateX = expansionRateX
        self.expansionRateY = expansionRateY
        self.initialTimer = initialTimer
        self.velocityY = velocityY
    }
}

struct SM64ExplosionBubbleState: Equatable, Sendable {
    var position: SM64ObjectVector3
    var scale: SM64ObjectVector3 = SM64ObjectVector3(x: 2, y: 2, z: 1)
    var scaleFactorX: Int32 = 0
    var scaleFactorY: Int32 = 0
    var expansionRateX: Int32
    var expansionRateY: Int32
    var velocityY: Float
    var timer: UInt32
    var animationState: Int32 = 0
    var delayed = true
    var markedForDeletion = false
    var spawnedSplash = false

    init(position: SM64ObjectVector3, input: SM64ExplosionBubbleSpawnInput) {
        self.position = position
        self.expansionRateX = input.expansionRateX
        self.expansionRateY = input.expansionRateY
        self.velocityY = input.velocityY
        self.timer = input.initialTimer
    }
}

struct SM64ExplosionBubbleTickInput: Equatable, Sendable {
    let waterLevel: Float

    init(waterLevel: Float = -.greatestFiniteMagnitude) {
        self.waterLevel = waterLevel
    }
}

struct SM64ExplosionBubbleEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt16

    init(rawValue: UInt16) { self.rawValue = rawValue }

    static let delay = Self(rawValue: 1 << 0)
    static let animate = Self(rawValue: 1 << 1)
    static let spawnSplash = Self(rawValue: 1 << 2)
    static let markForDeletion = Self(rawValue: 1 << 3)
}

struct SM64ExplosionBubbleTickResult: Equatable, Sendable {
    let state: SM64ExplosionBubbleState
    let effects: SM64ExplosionBubbleEffect
    let spawnedSplash: Bool
}

struct SM64ExplosionGroundSmokeState: Equatable, Sendable {
    var position: SM64ObjectVector3
    var velocity: SM64ObjectVector3 = .zero
    var scale: Float = 10
    var smokeTimer: UInt32 = 0
    var timer: UInt32 = 0
    var animationState: Int32 = -1
    var delayed = true
    var markedForDeletion = false

    init(position: SM64ObjectVector3) {
        self.position = position
        self.position.y -= 300
    }
}

struct SM64ExplosionGroundSmokeEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt16

    init(rawValue: UInt16) { self.rawValue = rawValue }

    static let delay = Self(rawValue: 1 << 0)
    static let animate = Self(rawValue: 1 << 1)
    static let markForDeletion = Self(rawValue: 1 << 2)
}

struct SM64ExplosionGroundSmokeTickResult: Equatable, Sendable {
    let state: SM64ExplosionGroundSmokeState
    let effects: SM64ExplosionGroundSmokeEffect
}

/// Value translations for `corkbox.inc.c` and `bhv_dust_smoke_loop`. Random
/// placement/rates/timers are inputs; this kernel never reaches a global RNG.
enum SM64ExplosionChildrenKernel {
    static func makeGroundSmoke(
        parentPosition: SM64ObjectVector3
    ) -> SM64ExplosionGroundSmokeState {
        SM64ExplosionGroundSmokeState(position: parentPosition)
    }

    static func makeBubble(
        parentPosition: SM64ObjectVector3,
        input: SM64ExplosionBubbleSpawnInput
    ) -> SM64ExplosionBubbleState {
        SM64ExplosionBubbleState(
            position: SM64ObjectVector3(
                x: parentPosition.x + input.positionOffset.x + input.microOffset.x,
                y: parentPosition.y + input.positionOffset.y + input.microOffset.y,
                z: parentPosition.z + input.positionOffset.z + input.microOffset.z
            ),
            input: input
        )
    }

    static func tickBubble(
        _ input: SM64ExplosionBubbleTickInput,
        state: inout SM64ExplosionBubbleState
    ) -> SM64ExplosionBubbleTickResult {
        if state.delayed {
            state.delayed = false
            return SM64ExplosionBubbleTickResult(
                state: state,
                effects: [.delay],
                spawnedSplash: false
            )
        }

        var effects: SM64ExplosionBubbleEffect = [.animate]
        state.scale = SM64ObjectVector3(
            x: SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: state.scaleFactorX)) * 0.5 + 2,
            y: SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: state.scaleFactorY)) * 0.5 + 2,
            z: 1
        )
        state.scaleFactorX &+= state.expansionRateX
        state.scaleFactorY &+= state.expansionRateY

        var spawnedSplash = false
        if state.position.y > input.waterLevel {
            state.markedForDeletion = true
            state.position.y += 5
            state.spawnedSplash = true
            spawnedSplash = true
            effects.insert(.spawnSplash)
        }
        if state.timer >= 61 {
            state.markedForDeletion = true
        }
        if state.markedForDeletion {
            effects.insert(.markForDeletion)
        }
        state.position.y += state.velocityY
        state.timer = state.timer == UInt32.max ? 0 : state.timer + 1
        state.animationState &+= 1
        return SM64ExplosionBubbleTickResult(
            state: state,
            effects: effects,
            spawnedSplash: spawnedSplash
        )
    }

    static func tickGroundSmoke(
        state: inout SM64ExplosionGroundSmokeState
    ) -> SM64ExplosionGroundSmokeTickResult {
        if state.delayed {
            state.delayed = false
            return SM64ExplosionGroundSmokeTickResult(state: state, effects: [.delay])
        }

        var effects: SM64ExplosionGroundSmokeEffect = [.animate]
        state.position.x += state.velocity.x
        state.position.y += state.velocity.y
        state.position.z += state.velocity.z
        if state.smokeTimer == 10 {
            state.markedForDeletion = true
            effects.insert(.markForDeletion)
        }
        state.smokeTimer = state.smokeTimer == UInt32.max ? 0 : state.smokeTimer + 1
        state.timer = state.timer == UInt32.max ? 0 : state.timer + 1
        state.animationState &+= 1
        return SM64ExplosionGroundSmokeTickResult(state: state, effects: effects)
    }
}
