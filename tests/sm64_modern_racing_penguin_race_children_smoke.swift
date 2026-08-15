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

private func hashOutput(_ initial: UInt64, _ output: SM64RacingPenguinRaceChildOutput) -> UInt64 {
    let hash = hashU32(initial, output.marioWon ? 1 : 0)
    return hashU32(hash, output.marioCheated ? 1 : 0)
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernRacingPenguinRaceChildrenSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let finishCross = SM64RacingPenguinRaceChildren.update(
            SM64RacingPenguinRaceChildInput(
                kind: .finishLine,
                parentReachedBottom: false,
                distanceToMario: 999,
                marioDeltaZ: -0.5
            )
        )
        require(finishCross.marioWon, "finish line awards a non-bottom crossing")
        require(!finishCross.marioCheated, "finish line does not set shortcut cheat")
        fingerprint = hashOutput(fingerprint, finishCross)

        let bottom = SM64RacingPenguinRaceChildren.update(
            SM64RacingPenguinRaceChildInput(
                kind: .finishLine,
                parentReachedBottom: true,
                distanceToMario: 10,
                marioDeltaZ: -10
            )
        )
        require(!bottom.marioWon, "bottom arrival does not re-award finish line win")
        fingerprint = hashOutput(fingerprint, bottom)

        let outside = SM64RacingPenguinRaceChildren.update(
            SM64RacingPenguinRaceChildInput(
                kind: .finishLine,
                parentReachedBottom: false,
                distanceToMario: 1_000,
                marioDeltaZ: -1
            )
        )
        require(!outside.marioWon, "finish line uses strict distance boundary")
        fingerprint = hashOutput(fingerprint, outside)

        let shortcut = SM64RacingPenguinRaceChildren.update(
            SM64RacingPenguinRaceChildInput(
                kind: .shortcutCheck,
                parentReachedBottom: false,
                distanceToMario: 499.5,
                marioDeltaZ: 0
            )
        )
        require(shortcut.marioCheated, "shortcut child records cheat proximity")
        fingerprint = hashOutput(fingerprint, shortcut)

        let shortcutBoundary = SM64RacingPenguinRaceChildren.update(
            SM64RacingPenguinRaceChildInput(
                kind: .shortcutCheck,
                parentReachedBottom: false,
                distanceToMario: 500,
                marioDeltaZ: 0
            )
        )
        require(!shortcutBoundary.marioCheated, "shortcut uses strict distance boundary")
        fingerprint = hashOutput(fingerprint, shortcutBoundary)

        print(String(format: "racingPenguinRaceChildrenFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern racing penguin race-children smoke passed")
    }
}
