import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ value: UInt8) -> UInt64 { var x = h; x ^= UInt64(value); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ value: UInt16) -> UInt64 {
    var x = h; for index in 0..<2 { x = h8(x, UInt8(truncatingIfNeeded: value >> UInt16(index * 8))) }; return x
}
private func h32(_ h: UInt64, _ value: UInt32) -> UInt64 {
    var x = h; for index in 0..<4 { x = h8(x, UInt8(truncatingIfNeeded: value >> UInt32(index * 8))) }; return x
}
private func hi16(_ h: UInt64, _ value: Int16) -> UInt64 { h16(h, UInt16(bitPattern: value)) }

private func hash(
    _ h: UInt64,
    _ actor: SM64ProgressionActorState,
    _ progression: SM64ProgressionState,
    _ effects: SM64ProgressionActorEffect,
    _ progressionEffects: SM64ProgressionEffect,
    _ accepted: Bool
) -> UInt64 {
    var x = h8(h, actor.redCoinsCollected)
    x = h8(x, actor.redCoinStarSpawned ? 1 : 0)
    x = h8(x, actor.capSwitchesPressed)
    x = h8(x, actor.levelCompleted ? 1 : 0)
    x = h32(x, progression.flags)
    for value in progression.courseStars { x = h8(x, value) }
    for value in progression.courseCoinScores { x = h8(x, value) }
    x = hi16(x, progression.coins)
    x = h8(x, progression.saveModified ? 1 : 0)
    x = h16(x, effects.rawValue)
    x = h16(x, progressionEffects.rawValue)
    return h8(x, accepted ? 1 : 0)
}

@main
enum SM64ModernProgressionActorsSmoke {
    static func main() {
        var actor = SM64ProgressionActorState()
        var progression = SM64ProgressionState(
            flags: SM64ProgressionReducer.fileExists,
            coins: 10,
            courseNumber: 3
        )
        var fingerprint = fnvOffset

        for _ in 0..<8 {
            let result = SM64ProgressionActorReducer.reduce(
                .collectRedCoin, actor: actor, progression: progression
            )!
            actor = result.actor; progression = result.progression
            fingerprint = hash(
                fingerprint, actor, progression, result.effects,
                result.progressionEffects, result.accepted
            )
        }
        precondition(actor.redCoinsCollected == 8 && actor.redCoinStarSpawned)
        precondition(progression.coins == 26)

        let duplicate = SM64ProgressionActorReducer.reduce(
            .collectRedCoin, actor: actor, progression: progression
        )!
        precondition(!duplicate.accepted && duplicate.actor == actor)
        fingerprint = hash(
            fingerprint, duplicate.actor, duplicate.progression,
            duplicate.effects, duplicate.progressionEffects, duplicate.accepted
        )

        let wing = SM64ProgressionActorReducer.reduce(
            .pressCapSwitch(index: 0), actor: actor, progression: progression
        )!
        actor = wing.actor; progression = wing.progression
        fingerprint = hash(
            fingerprint, actor, progression, wing.effects,
            wing.progressionEffects, wing.accepted
        )
        precondition(progression.flags & SM64ProgressionReducer.haveWingCap != 0)

        let duplicateWing = SM64ProgressionActorReducer.reduce(
            .pressCapSwitch(index: 0), actor: actor, progression: progression
        )!
        precondition(!duplicateWing.accepted)
        fingerprint = hash(
            fingerprint, duplicateWing.actor, duplicateWing.progression,
            duplicateWing.effects, duplicateWing.progressionEffects,
            duplicateWing.accepted
        )

        let reward = SM64ProgressionActorReducer.reduce(
            .completeLevel(
                kind: .courseStar, starIndex: 2, coinScore: 100,
                globalMaxCoinScore: 95
            ), actor: actor, progression: progression
        )!
        actor = reward.actor; progression = reward.progression
        fingerprint = hash(
            fingerprint, actor, progression, reward.effects,
            reward.progressionEffects, reward.accepted
        )
        precondition(actor.levelCompleted && progression.courseStars[2] == 0x04)
        precondition(progression.courseCoinScores[2] == 100)

        let duplicateReward = SM64ProgressionActorReducer.reduce(
            .completeLevel(
                kind: .courseStar, starIndex: 2, coinScore: 100,
                globalMaxCoinScore: 95
            ), actor: actor, progression: progression
        )!
        precondition(!duplicateReward.accepted)
        fingerprint = hash(
            fingerprint, duplicateReward.actor, duplicateReward.progression,
            duplicateReward.effects, duplicateReward.progressionEffects,
            duplicateReward.accepted
        )

        let invalidSwitch = SM64ProgressionActorReducer.reduce(
            .pressCapSwitch(index: 3), actor: actor, progression: progression
        )
        precondition(invalidSwitch == nil)

        print(String(format: "progressionActorsFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern progression-actors smoke passed")
    }
}
