import Foundation

private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211

private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 255; result &*= prime }; return result }
private func row(_ output: SM64KoopaRaceEndpointOutput) -> [UInt64] {
    [output.raceEnded ? 1 : 0, UInt64(bitPattern: Int64(output.raceStatus)), output.playFanfare ? 1 : 0, output.stopTimer ? 1 : 0]
}

@main
struct SM64KoopaRaceEndpointSmoke {
    static func main() {
        let idle = SM64KoopaRaceEndpointBehavior.update(.init(raceBegun: false, raceEnded: false, koopaFinished: false, distanceToMario: 100, marioShotFromCannon: false, raceStatus: 0))
        let win = SM64KoopaRaceEndpointBehavior.update(.init(raceBegun: true, raceEnded: false, koopaFinished: false, distanceToMario: 300, marioShotFromCannon: false, raceStatus: 0))
        let cannon = SM64KoopaRaceEndpointBehavior.update(.init(raceBegun: true, raceEnded: false, koopaFinished: true, distanceToMario: 3_000, marioShotFromCannon: true, raceStatus: 0))
        precondition(!idle.raceEnded && !idle.stopTimer)
        precondition(win.raceEnded && win.raceStatus == 1 && win.playFanfare && win.stopTimer)
        precondition(cannon.raceEnded && cannon.raceStatus == 0 && !cannon.playFanfare && cannon.stopTimer)
        var fingerprint = offset
        for output in [idle, win, cannon] { for value in row(output) { fingerprint = hash(fingerprint, value) } }
        print(String(format: "koopaRaceEndpointFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Koopa race endpoint smoke passed")
    }
}
