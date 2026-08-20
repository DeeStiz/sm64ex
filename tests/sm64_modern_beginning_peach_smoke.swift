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

private func row(_ output: SM64BeginningPeachOutput) -> [UInt64] {
    [UInt64(bitPattern: Int64(output.action)), UInt64(bitPattern: Int64(output.timer)), UInt64(bitPattern: Int64(output.opacity)), UInt64(bitPattern: Int64(output.animationFrame)), output.shouldDelete ? 1 : 0]
}

@main
struct SM64BeginningPeachSmoke {
    static func main() {
        let initState = SM64BeginningPeachBehavior.update(.init(action: 0, timer: 0, opacity: 0, position: .zero, cameraTargetPosition: .init(x: 1, y: 2, z: 3), dialogID: -1))
        let vanish = SM64BeginningPeachBehavior.update(.init(action: 1, timer: 21, opacity: 255, position: .zero, cameraTargetPosition: .init(x: 1, y: 2, z: 3), dialogID: -1))
        let appear = SM64BeginningPeachBehavior.update(.init(action: 2, timer: 0, opacity: 0, position: .zero, cameraTargetPosition: .init(x: 1, y: 2, z: 3), dialogID: -1))
        let next = SM64BeginningPeachBehavior.update(.init(action: 2, timer: 101, opacity: 255, position: .zero, cameraTargetPosition: .init(x: 1, y: 2, z: 3), dialogID: -1))
        let delete = SM64BeginningPeachBehavior.update(.init(action: 3, timer: 61, opacity: 8, position: .zero, cameraTargetPosition: .init(x: 1, y: 2, z: 3), dialogID: -1))
        precondition(initState.action == 1 && initState.timer == 0 && initState.opacity == 255)
        precondition(vanish.action == 2 && vanish.opacity == 0 && vanish.position == .init(x: 1, y: 2, z: 3))
        precondition(appear.opacity == 3)
        precondition(next.action == 3 && next.timer == 0)
        precondition(delete.shouldDelete)
        var fingerprint = offset
        for output in [initState, vanish, appear, next, delete] {
            for value in row(output) { fingerprint = hash(fingerprint, value) }
        }
        print(String(format: "beginningPeachFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Beginning Peach smoke passed")
    }
}
