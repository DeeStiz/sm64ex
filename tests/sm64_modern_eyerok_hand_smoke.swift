import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for byte in 0..<4 {
        hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff)
        hash &*= fnvPrime
    }
    return hash
}

private func hashI32(_ initial: UInt64, _ value: Int32) -> UInt64 {
    hashU32(initial, UInt32(bitPattern: value))
}

private func hashFloat(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU32(initial, value.bitPattern)
}

private func hashResult(_ initial: UInt64, _ result: SM64EyerokHandTickResult) -> UInt64 {
    let state = result.state
    var hash = hashI32(initial, Int32(state.side))
    hash = hashU32(hash, UInt32(state.action.rawValue))
    hash = hashFloat(hash, state.positionX)
    hash = hashFloat(hash, state.positionY)
    hash = hashFloat(hash, state.positionZ)
    hash = hashI32(hash, Int32(state.faceYaw))
    hash = hashI32(hash, Int32(state.moveYaw))
    hash = hashFloat(hash, state.forwardVelocity)
    hash = hashFloat(hash, state.velocityY)
    hash = hashFloat(hash, state.gravity)
    hash = hashI32(hash, Int32(state.health))
    hash = hashI32(hash, state.wakeUpTimer)
    hash = hashI32(hash, state.handTimer)
    hash = hashI32(hash, state.eyeTimer)
    hash = hashI32(hash, Int32(state.animState))
    hash = hashU32(hash, state.moveFlags)
    hash = hashI32(hash, state.collisionMode)
    hash = hashFloat(hash, state.renderScale)
    hash = hashI32(hash, Int32(bitPattern: state.timer))
    hash = hashU32(hash, result.effects.rawValue)
    hash = hashI32(hash, result.parentNumHands)
    hash = hashI32(hash, result.parentActiveHand)
    return hashI32(hash, result.parentBusyHand)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernEyerokHandSmoke {
    static func main() {
        var fingerprint = fnvOffset

        var sleeping = SM64EyerokHandState(side: -1, homeX: 100, homeY: 50, homeZ: 200)
        let sleep = SM64EyerokHandKernel.tick(.init(), state: &sleeping)
        require(sleep.state.positionX == -624 && sleep.state.collisionMode == 1,
                "Eyerok sleeping hand source offset")
        fingerprint = hashResult(fingerprint, sleep)

        sleeping.wakeUpTimer = 3
        sleeping.action = .sleep
        let wake = SM64EyerokHandKernel.tick(
            .init(parentAction: .fight, animationNearEnd: true),
            state: &sleeping
        )
        require(wake.state.action == .idle && wake.parentNumHands == 3,
                "Eyerok hand wake transition")
        fingerprint = hashResult(fingerprint, wake)

        var target = SM64EyerokHandState(side: -1, homeX: 0, homeY: 0, homeZ: 0)
        target.action = .idle
        let targetResult = SM64EyerokHandKernel.tick(
            .init(parentAction: .fight, parentActiveHand: -1, marioRelativeZ: 100, angleToMario: 0x200),
            state: &target
        )
        require(targetResult.state.action == .targetMario && targetResult.state.gravity == 0,
                "Eyerok target-Mario route")
        fingerprint = hashResult(fingerprint, targetResult)

        var open = SM64EyerokHandState(side: 1, homeX: 0, homeY: 0, homeZ: 0)
        open.action = .idle
        let openResult = SM64EyerokHandKernel.tick(
            .init(parentAction: .fight, parentActiveHand: -1),
            state: &open
        )
        require(openResult.state.action == .open && openResult.effects == .idleAnimation,
                "Eyerok non-active hand opens")
        let eye = SM64EyerokHandKernel.tick(
            .init(parentAction: .fight, parentNumHands: 1, parentBusyHand: 1,
                 angleToMario: 0x4000, animationEnded: true),
            state: &open
        )
        require(eye.state.action == .showEye && eye.state.collisionMode == 3,
                "Eyerok open-to-eye route")
        require(eye.state.moveYaw == 0x3000 && eye.state.forwardVelocity == 50,
                "Eyerok eye single-hand clamp")
        fingerprint = hashResult(fingerprint, openResult)
        fingerprint = hashResult(fingerprint, eye)

        let attacked = SM64EyerokHandKernel.tick(
            .init(parentAction: .fight, parentNumHands: 1, parentBusyHand: 1,
                 angleToMario: 0, receivedAttack: true),
            state: &open
        )
        require(attacked.state.action == .attacked && attacked.state.health == 3,
                "Eyerok nonlethal eye attack")
        require(attacked.effects.contains(.shortSound), "Eyerok attack sound")
        fingerprint = hashResult(fingerprint, attacked)

        let recover = SM64EyerokHandKernel.tick(
            .init(parentAction: .fight, animationEnded: true, onGround: true),
            state: &open
        )
        require(recover.state.action == .recover && recover.state.forwardVelocity == 0,
                "Eyerok attacked recovery")
        fingerprint = hashResult(fingerprint, recover)

        let becomeActive = SM64EyerokHandKernel.tick(
            .init(parentAction: .fight, parentNumHands: 1, animationEnded: true),
            state: &open
        )
        require(becomeActive.state.action == .becomeActive, "Eyerok recover transition")
        fingerprint = hashResult(fingerprint, becomeActive)

        let retreat = SM64EyerokHandKernel.tick(
            .init(parentAction: .fight, parentNumHands: 1, parentActiveHand: 0),
            state: &open
        )
        require(retreat.state.action == .retreat && retreat.parentActiveHand == 1,
                "Eyerok become-active retreat")
        open.positionX = open.homeX
        open.positionY = open.homeY
        open.positionZ = open.homeZ
        open.faceYaw = 0
        let idle = SM64EyerokHandKernel.tick(
            .init(parentAction: .fight, parentNumHands: 1, parentActiveHand: 1),
            state: &open
        )
        require(idle.state.action == .idle && idle.parentActiveHand == 0,
                "Eyerok retreat idle")
        fingerprint = hashResult(fingerprint, retreat)
        fingerprint = hashResult(fingerprint, idle)

        var double = SM64EyerokHandState(side: -1, homeX: 0, homeY: 0, homeZ: 0, faceYaw: 0x100)
        double.action = .idle
        let beginDouble = SM64EyerokHandKernel.tick(
            .init(parentAction: .fight, parentHandSelectionPhase: 8),
            state: &double
        )
        require(beginDouble.state.action == .beginDoublePound, "Eyerok begin double pound")
        let doublePound = SM64EyerokHandKernel.tick(
            .init(parentAction: .fight, parentActiveHand: -1,
                 parentHandSelectionPhase: 8, parentHandSelectionDirection: -1),
            state: &double
        )
        require(doublePound.state.action == .doublePound && doublePound.state.moveYaw == 0x4100,
                "Eyerok double pound setup")
        fingerprint = hashResult(fingerprint, beginDouble)
        fingerprint = hashResult(fingerprint, doublePound)

        let launch = SM64EyerokHandKernel.tick(
            .init(parentAction: .fight, parentActiveHand: -1,
                 parentHandSelectionDirection: -1, onGround: true),
            state: &double
        )
        require(launch.state.forwardVelocity == 30 && launch.state.velocityY == 100,
                "Eyerok double pound launch")
        fingerprint = hashResult(fingerprint, launch)

        var smash = SM64EyerokHandState(side: 1, homeY: 10, homeZ: 0)
        smash.action = .targetMario
        smash.positionY = 290
        let smashResult = SM64EyerokHandKernel.tick(
            .init(parentAction: .fight, marioRelativeZ: 100),
            state: &smash
        )
        require(smashResult.state.action == .smash && smashResult.state.positionY == 310,
                "Eyerok target smash transition")
        fingerprint = hashResult(fingerprint, smashResult)

        smash.timer = 21
        smash.gravity = -20
        let pound = SM64EyerokHandKernel.tick(
            .init(parentAction: .fight, onGround: true),
            state: &smash
        )
        require(pound.state.gravity == -4 && pound.effects.contains(.poundSound),
                "Eyerok smash pound")
        fingerprint = hashResult(fingerprint, pound)

        var dying = SM64EyerokHandState(side: 1)
        dying.action = .showEye
        dying.health = 1
        let death = SM64EyerokHandKernel.tick(
            .init(parentAction: .fight, parentNumHands: 2, angleToMario: 0,
                 receivedAttack: true),
            state: &dying
        )
        require(death.state.action == .die && death.parentNumHands == 1,
                "Eyerok lethal eye attack")
        let deathEffects = SM64EyerokHandKernel.tick(
            .init(parentAction: .fight, animationEnded: true, onGround: true),
            state: &dying
        )
        require(deathEffects.effects.contains([.explodeCoins, .soundSpawner, .deathPound]),
                "Eyerok hand death effects")
        fingerprint = hashResult(fingerprint, death)
        fingerprint = hashResult(fingerprint, deathEffects)

        print(String(format: "eyerokHandFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Eyerok hand smoke passed")
    }
}
