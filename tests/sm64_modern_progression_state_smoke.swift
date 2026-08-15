import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func hf(_ h: UInt64, _ v: Float) -> UInt64 { h32(h, v.bitPattern) }
private func hi16(_ h: UInt64, _ v: Int16) -> UInt64 { h16(h, UInt16(bitPattern: v)) }

private func hash(
    _ h: UInt64,
    _ state: SM64ProgressionState
) -> UInt64 {
    var x = h32(h, state.flags)
    for value in state.courseStars { x = h8(x, value) }
    for value in state.courseCoinScores { x = h8(x, value) }
    x = h8(x, state.secretStars)
    x = h32(x, state.switchFlags)
    x = hi16(x, state.coins); x = hi16(x, state.lives)
    x = hi16(x, state.courseNumber); x = hi16(x, state.lastCompletedCourse)
    x = hi16(x, state.lastCompletedStar)
    x = h8(x, state.capLocation.rawValue); x = h8(x, state.capLevel); x = h8(x, state.capArea)
    x = hf(x, state.capPosition.x); x = hf(x, state.capPosition.y); x = hf(x, state.capPosition.z)
    if let checkpoint = state.checkpoint {
        x = h8(x, 1); x = h8(x, checkpoint.act); x = h8(x, checkpoint.course)
        x = h8(x, checkpoint.level); x = h8(x, checkpoint.area); x = h8(x, checkpoint.node)
    } else {
        x = h8(x, 0)
    }
    return h8(x, state.saveModified ? 1 : 0)
}

private func hash(
    _ h: UInt64,
    _ result: SM64ProgressionReduceResult
) -> UInt64 {
    var x = hash(h, result.state)
    x = h16(x, result.effects.rawValue)
    x = h8(x, result.accepted ? 1 : 0)
    if let warp = result.warp {
        x = h8(x, 1); x = hi16(x, warp.level); x = hi16(x, warp.area)
        x = hi16(x, warp.node); x = h32(x, UInt32(bitPattern: warp.argument))
    } else {
        x = h8(x, 0)
    }
    return x
}

@main
enum SM64ModernProgressionStateSmoke {
    static func main() {
        var state = SM64ProgressionState(
            flags: SM64ProgressionReducer.fileExists,
            coins: 95, lives: 4, courseNumber: 3
        )
        var fingerprint = fnvOffset

        let events: [SM64ProgressionEvent] = [
            .collectCoin(value: 5),
            .collectStarOrKey(kind: .courseStar, starIndex: 2,
                              coinScore: 100, globalMaxCoinScore: 95),
            .unlockCannon,
            .pressSwitch(index: 4),
            .openDoor(requiredStars: 1, flag: SM64ProgressionReducer.unlockedBasementDoor),
            .setCapOnGround(level: 7, area: 2,
                            position: .init(x: -10, y: 20, z: 30)),
            .setCheckpoint(.init(act: 2, course: 3, level: 7, area: 2, node: 4)),
            .requestWarp(
                destination: .init(level: 10, area: 2, node: 3, argument: -7),
                checkpoint: nil
            ),
            .addLife(value: 2),
            .setCapLocation(.ukiki),
            .collectStarOrKey(kind: .secretStar, starIndex: 1,
                              coinScore: 0, globalMaxCoinScore: 0)
        ]

        for event in events {
            let result = SM64ProgressionReducer.reduce(event, state: state)!
            state = result.state
            fingerprint = hash(fingerprint, result)
        }

        precondition(state.coins == 100 && state.lives == 6
            && state.totalStars == 2)
        precondition(state.courseStars[2] == 0x04 && state.courseStars[3] == 0x80)
        precondition(state.courseCoinScores[2] == 100)
        precondition(state.flags & SM64ProgressionReducer.unlockedBasementDoor != 0)
        precondition(state.flags & SM64ProgressionReducer.capOnUkiki != 0
            && state.flags & SM64ProgressionReducer.capOnGround == 0)
        precondition(state.switchFlags == 0x10)
        precondition(state.checkpoint == .init(act: 2, course: 3, level: 7, area: 2, node: 4))
        precondition(SM64ProgressionReducer.reduce(.addLife(value: 0), state: state) == nil)
        precondition(SM64ProgressionReducer.reduce(
            .openDoor(requiredStars: 99, flag: 1 << 20), state: state
        )!.accepted == false)

        print(String(format: "progressionStateFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern progression-state smoke passed")
    }
}
