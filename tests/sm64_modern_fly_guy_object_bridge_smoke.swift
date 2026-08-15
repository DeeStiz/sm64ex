import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 {
        hash ^= (value >> UInt64(byte * 8)) & 0xff
        hash &*= fnvPrime
    }
    return hash
}

private func hashState(_ initial: UInt64, _ result: SM64FlyGuyTickResult) -> UInt64 {
    let s = result.state
    let values: [UInt64] = [
        UInt64(result.effects.rawValue), UInt64(s.action.rawValue),
        UInt64(s.homeX.bitPattern), UInt64(s.homeY.bitPattern), UInt64(s.homeZ.bitPattern),
        UInt64(s.positionX.bitPattern), UInt64(s.positionY.bitPattern), UInt64(s.positionZ.bitPattern),
        UInt64(UInt16(bitPattern: s.moveYaw)), UInt64(UInt16(bitPattern: s.faceYaw)),
        UInt64(UInt16(bitPattern: s.facePitch)), UInt64(UInt16(bitPattern: s.faceRoll)),
        UInt64(s.forwardVelocity.bitPattern), UInt64(s.velocityY.bitPattern),
        UInt64(s.scale.bitPattern), UInt64(s.scaleVelocity.bitPattern),
        UInt64(UInt16(bitPattern: s.lungeTargetPitch)), UInt64(s.lungeYDeceleration.bitPattern),
        UInt64(UInt16(bitPattern: s.targetRoll)), UInt64(s.idleTimer), UInt64(s.oscillationTimer),
        s.tangible ? 1 : 0, s.markedForDeletion ? 1 : 0, UInt64(s.timer)
    ]
    return values.reduce(initial, hashU64)
}

private func hashFlame(_ initial: UInt64, _ result: SM64FlyGuyFlameTickResult) -> UInt64 {
    let s = result.state
    let values: [UInt64] = [
        UInt64(result.effects.rawValue), UInt64(s.positionX.bitPattern),
        UInt64(s.positionY.bitPattern), UInt64(s.positionZ.bitPattern),
        UInt64(s.scale.bitPattern), UInt64(UInt16(bitPattern: s.moveYaw)),
        UInt64(s.timer), s.markedForDeletion ? 1 : 0
    ]
    return values.reduce(initial, hashU64)
}

private func hashEffect(_ initial: UInt64, _ effect: SM64FlyGuyObjectEffectRecord) -> UInt64 {
    let values: [UInt64] = [
        UInt64(effect.objectID.traceSubject), UInt64(effect.kind.rawValue),
        UInt64(effect.effects.rawValue), UInt64(effect.action?.rawValue ?? 255),
        UInt64(effect.spawnedChildren.count)
    ] + effect.spawnedChildren.map { UInt64($0.traceSubject) } + [effect.markedForDeletion ? 1 : 0]
    return values.reduce(initial, hashU64)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernFlyGuyObjectBridgeSmoke {
    static func main() throws {
        var fingerprint = fnvOffset

        var idle = SM64FlyGuyState(homeX: 10, homeY: 500, homeZ: 30)
        idle.scale = 1.5
        idle.idleTimer = 3
        let approach = SM64FlyGuyKernel.tick(
            SM64FlyGuyTickInput(distanceToMario: 1_000, angleToMario: 0), state: &idle
        )
        require(approach.state.action == .approachMario, "Fly Guy approach")
        fingerprint = hashState(fingerprint, approach)

        var lunge = SM64FlyGuyState(homeX: 0, homeY: 500, homeZ: 0)
        lunge.action = .approachMario
        lunge.scale = 1.5
        let lungeResult = SM64FlyGuyKernel.tick(
            SM64FlyGuyTickInput(distanceToMario: 300, angleToMario: 0, marioY: 0), state: &lunge
        )
        require(lungeResult.state.action == .lunge && lungeResult.effects.contains(.lunge),
                "Fly Guy lunge")
        fingerprint = hashState(fingerprint, lungeResult)

        var shooter = SM64FlyGuyState(homeX: 0, homeY: 500, homeZ: 0)
        shooter.action = .approachMario
        shooter.scale = 1.5
        let shoot = SM64FlyGuyKernel.tick(
            SM64FlyGuyTickInput(
                distanceToMario: 300,
                angleToMario: 0,
                marioY: 0,
                behaviorShootsFire: true,
                randomValue: 1
            ),
            state: &shooter
        )
        require(shoot.state.action == .shootFire, "Fly Guy shoot admission")
        fingerprint = hashState(fingerprint, shoot)

        shooter.scale = 1.2
        shooter.scaleVelocity = -0.01
        let spit = SM64FlyGuyKernel.tick(
            SM64FlyGuyTickInput(angleToMario: 0, behaviorShootsFire: true), state: &shooter
        )
        require(spit.effects.contains(.spitFire), "Fly Guy spit fire")
        fingerprint = hashState(fingerprint, spit)

        var flame = SM64FlyGuyFlameState()
        let flameTick = SM64FlyGuyKernel.tickFlame(parent: shooter, state: &flame)
        require(flameTick.state.positionY == shooter.positionY + 38 && flameTick.state.scale == 1.9,
                "Fly Guy flame child")
        fingerprint = hashFlame(fingerprint, flameTick)

        let wall = SM64FlyGuyKernel.tick(
            SM64FlyGuyTickInput(moveFlags: SM64FlyGuyKernel.hitWallFlag), state: &shooter
        )
        require(wall.effects.contains(.wallReflect), "Fly Guy wall reflection")
        fingerprint = hashState(fingerprint, wall)

        let engineState = SM64SwiftEngineState(objectCapacity: 128)
        let bridge = SM64FlyGuyObjectBridge()
        let flyID = try bridge.spawnFlyGuy(in: engineState, homeX: 5, homeY: 500, homeZ: 15)
        require(flyID.traceSubject == 1, "stable Fly Guy slot")
        var parentFire: SM64FlyGuyObjectEffectRecord?
        var flameEffect: SM64FlyGuyObjectEffectRecord?
        for _ in 0..<120 where flameEffect == nil {
            let tick = bridge.tick(
                state: engineState,
                inputs: [flyID: SM64FlyGuyTickInput(
                    distanceToMario: 300,
                    angleToMario: 0,
                    marioY: -500,
                    behaviorShootsFire: true,
                    randomValue: 1
                )]
            )
            if let effect = tick.effects.first(where: {
                $0.objectID == flyID && $0.effects.contains(.spitFire)
            }) {
                parentFire = effect
                if let child = effect.spawnedChildren.first {
                    flameEffect = tick.effects.first(where: { $0.objectID == child })
                }
            }
        }
        guard let parentFire, let flameEffect else { preconditionFailure("Fly Guy bridge flame missing") }
        fingerprint = hashEffect(fingerprint, parentFire)
        fingerprint = hashEffect(fingerprint, flameEffect)

        print(String(format: "flyGuyObjectBridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Fly Guy object bridge smoke passed")
    }
}
