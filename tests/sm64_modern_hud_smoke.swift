private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU32(_ hash: UInt64, _ value: UInt32) -> UInt64 {
    var result = hash
    for shift in stride(from: 0, through: 24, by: 8) {
        result ^= UInt64((value >> UInt32(shift)) & 0xFF)
        result &*= fnvPrime
    }
    return result
}

private func hashBool(_ hash: UInt64, _ value: Bool) -> UInt64 {
    hashU32(hash, value ? 1 : 0)
}

private func record(_ hash: UInt64, _ projection: SM64HUDProjection) -> UInt64 {
    var result = hash
    result = hashU32(result, UInt32(projection.flags.rawValue))
    result = hashBool(result, projection.configHUD)
    result = hashU32(result, UInt32(bitPattern: Int32(projection.lives)))
    result = hashU32(result, UInt32(bitPattern: Int32(projection.coins)))
    result = hashU32(result, UInt32(bitPattern: Int32(projection.stars)))
    result = hashU32(result, UInt32(bitPattern: Int32(projection.keys)))
    for value in [
        projection.showLives, projection.showCoins, projection.showStars,
        projection.showKeys, projection.showCameraAndPower,
        projection.showTimer, projection.showStarMultiplier,
        projection.powerMeter.render
    ] {
        result = hashBool(result, value)
    }
    result = hashU32(result, UInt32(projection.timer.minutes))
    result = hashU32(result, UInt32(projection.timer.seconds))
    result = hashU32(result, UInt32(projection.timer.fractionalSeconds))
    result = hashU32(result, UInt32(projection.powerMeter.animation.rawValue))
    result = hashU32(result, UInt32(bitPattern: Int32(projection.powerMeter.y)))
    result = hashU32(result, projection.powerMeter.visibleTimer)
    return result
}

@main
enum SM64ModernHUDSmoke {
    static func main() {
        var power = SM64PowerMeterState()
        var fingerprint = fnvOffset

        let full = SM64HUDProjection.project(
            SM64HUDInput(
                flags: [.lives, .coinCount, .starCount, .cameraAndPower, .keys, .timer],
                lives: 4, coins: 23, stars: 99, keys: 1, timer: 1_857
            ), powerMeter: &power
        )
        precondition(full.showLives && full.showCoins && full.showStars)
        precondition(full.showKeys && full.showCameraAndPower && full.showTimer)
        precondition(full.showStarMultiplier)
        precondition(full.timer.minutes == 1 && full.timer.seconds == 1)
        precondition(full.timer.fractionalSeconds == 9)
        fingerprint = record(fingerprint, full)

        let flashing = SM64HUDProjection.project(
            SM64HUDInput(
                flags: [.starCount], lives: 4, coins: 23, stars: 100, keys: 1,
                timer: 1_857, hudFlash: true, globalTimer: 8
            ), powerMeter: &power
        )
        precondition(!flashing.showStars && !flashing.showStarMultiplier)
        fingerprint = record(fingerprint, flashing)

        let damaged = SM64HUDProjection.project(
            SM64HUDInput(
                flags: [.cameraAndPower], lives: 4, coins: 23, stars: 99,
                keys: 1, timer: 1_857, healthWedges: 6
            ), powerMeter: &power
        )
        precondition(damaged.powerMeter.animation == .emphasized)
        precondition(damaged.powerMeter.render)
        fingerprint = record(fingerprint, damaged)

        for _ in 0..<45 {
            _ = SM64HUDProjection.project(
                SM64HUDInput(
                    flags: [.cameraAndPower], lives: 4, coins: 23, stars: 99,
                    keys: 1, timer: 1_857, healthWedges: 6
                ),
                powerMeter: &power
            )
        }
        let deEmphasized = SM64HUDProjection.project(
            SM64HUDInput(
                flags: [.cameraAndPower], lives: 4, coins: 23, stars: 99,
                keys: 1, timer: 1_857, healthWedges: 6
            ),
            powerMeter: &power
        )
        precondition(deEmphasized.powerMeter.animation == .deemphasizing)
        fingerprint = record(fingerprint, deEmphasized)

        let frozen = SM64HUDProjection.project(
            SM64HUDInput(
                flags: [.cameraAndPower], lives: 4, coins: 23, stars: 99,
                keys: 1, timer: 1_857, healthWedges: 6,
                advanceLegacyDomain: false
            ),
            powerMeter: &power
        )
        precondition(frozen.powerMeter.y == deEmphasized.powerMeter.y)
        print("hudFingerprint=0x\(String(fingerprint, radix: 16))")
        print("SM64 Modern HUD smoke passed")
    }
}
