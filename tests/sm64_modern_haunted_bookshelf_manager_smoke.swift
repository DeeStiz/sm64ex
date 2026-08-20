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

private func row(_ output: SM64HauntedBookshelfManagerOutput) -> [UInt64] {
    [UInt64(bitPattern: Int64(output.action)), UInt64(bitPattern: Int64(output.timer)), UInt64(bitPattern: Int64(output.sequence)), output.enabled ? 1 : 0, output.spawnSwitches ? 1 : 0, output.openShelf ? 1 : 0, output.shouldDelete ? 1 : 0]
}

@main
struct SM64HauntedBookshelfManagerSmoke {
    static func main() {
        let spawn = SM64HauntedBookshelfManagerBehavior.update(.init(action: 0, timer: 0, sequence: 0, enabled: false, nearAndFacingMario: false, shelfPresent: false, shelfPositionX: 0, positionX: 0, inDifferentRoom: false))
        let enable = SM64HauntedBookshelfManagerBehavior.update(.init(action: 1, timer: 0, sequence: 0, enabled: false, nearAndFacingMario: true, shelfPresent: false, shelfPositionX: 0, positionX: 0, inDifferentRoom: false))
        let solve = SM64HauntedBookshelfManagerBehavior.update(.init(action: 2, timer: 101, sequence: 3, enabled: false, nearAndFacingMario: false, shelfPresent: true, shelfPositionX: 42, positionX: 0, inDifferentRoom: false))
        let retire = SM64HauntedBookshelfManagerBehavior.update(.init(action: 4, timer: 0, sequence: 3, enabled: false, nearAndFacingMario: false, shelfPresent: true, shelfPositionX: 42, positionX: 0, inDifferentRoom: false))
        precondition(spawn.action == 1 && spawn.timer == 0 && spawn.spawnSwitches)
        precondition(enable.enabled && enable.action == 1)
        precondition(solve.action == 3 && solve.openShelf && solve.positionX == 42)
        precondition(retire.shouldDelete)
        var fingerprint = offset
        for output in [spawn, enable, solve, retire] {
            for value in row(output) { fingerprint = hash(fingerprint, value) }
        }
        print(String(format: "hauntedBookshelfManagerFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern haunted bookshelf manager smoke passed")
    }
}
