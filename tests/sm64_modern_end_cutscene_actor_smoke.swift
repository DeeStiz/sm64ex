import Foundation

private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211

private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 {
    var result = seed
    for index in 0..<8 {
        result ^= (value >> UInt64(index * 8)) & 255
        result &*= prime
    }
    return result
}

private func row(_ output: SM64EndCutsceneActorOutput) -> [UInt64] {
    [UInt64(output.role.rawValue), UInt64(bitPattern: Int64(output.animationIndex)), output.advanced ? 1 : 0]
}

@main
struct SM64EndCutsceneActorSmoke {
    static func main() {
        let peach = SM64EndCutsceneActorBehavior.update(.init(role: .peach, animationIndex: 2, positionX: 0, nearAnimationEnd: true))
        let peachHold = SM64EndCutsceneActorBehavior.update(.init(role: .peach, animationIndex: 3, positionX: 0, nearAnimationEnd: true))
        let peachWave = SM64EndCutsceneActorBehavior.update(.init(role: .peach, animationIndex: 6, positionX: 0, nearAnimationEnd: true))
        let toadRight = SM64EndCutsceneActorBehavior.update(.init(role: .toad, animationIndex: 0, positionX: 10, nearAnimationEnd: true))
        let toadLeft = SM64EndCutsceneActorBehavior.update(.init(role: .toad, animationIndex: 2, positionX: -10, nearAnimationEnd: true))
        precondition(peach.animationIndex == 3 && peach.advanced)
        precondition(peachHold.animationIndex == 3 && !peachHold.advanced)
        precondition(peachWave.animationIndex == 7 && peachWave.advanced)
        precondition(toadRight.animationIndex == 1 && toadRight.advanced)
        precondition(toadLeft.animationIndex == 3 && toadLeft.advanced)
        var fingerprint = offset
        for output in [peach, peachHold, peachWave, toadRight, toadLeft] {
            for value in row(output) { fingerprint = hash(fingerprint, value) }
        }
        print(String(format: "endCutsceneActorFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern end cutscene actor smoke passed")
    }
}
