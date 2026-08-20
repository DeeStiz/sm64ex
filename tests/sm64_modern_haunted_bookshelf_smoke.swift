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

private func row(_ output: SM64HauntedBookshelfOutput) -> [UInt64] {
    [UInt64(bitPattern: Int64(output.action)), UInt64(bitPattern: Int64(output.timer)), UInt64(output.position.x.bitPattern), output.playRecedeSound ? 1 : 0, output.shouldDelete ? 1 : 0]
}

@main
struct SM64HauntedBookshelfSmoke {
    static func main() {
        let idle = SM64HauntedBookshelfBehavior.update(.init(action: 0, timer: 0, position: .zero, shouldOpen: false))
        let open = SM64HauntedBookshelfBehavior.update(.init(action: 0, timer: 0, position: .zero, shouldOpen: true))
        let recede = SM64HauntedBookshelfBehavior.update(.init(action: 1, timer: 1, position: .zero, shouldOpen: false))
        let delete = SM64HauntedBookshelfBehavior.update(.init(action: 1, timer: 102, position: .zero, shouldOpen: false))
        precondition(idle.action == 0 && idle.timer == 1)
        precondition(open.action == 1 && open.timer == 0)
        precondition(recede.position.x == 5 && recede.playRecedeSound && !recede.shouldDelete)
        precondition(delete.shouldDelete)
        var fingerprint = offset
        for output in [idle, open, recede, delete] {
            for value in row(output) { fingerprint = hash(fingerprint, value) }
        }
        print(String(format: "hauntedBookshelfFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern haunted bookshelf smoke passed")
    }
}
