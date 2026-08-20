import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 {
    var result = seed
    for index in 0..<8 {
        result ^= (value >> UInt64(index * 8)) & 0xff
        result &*= fnvPrime
    }
    return result
}

@main
struct SM64ActSelectorStarTypeSmoke {
    static func main() {
        let notSelected = SM64ActSelectorStarTypeBehavior.update(.init(type: .notSelected, size: 1.05, faceYaw: 0x4000, timer: 4))
        let selected = SM64ActSelectorStarTypeBehavior.update(.init(type: .selected, size: 1.25, faceYaw: 0x4000, timer: 7))
        let selectedCap = SM64ActSelectorStarTypeBehavior.update(.init(type: .selected, size: 1.3, faceYaw: 0, timer: 8))
        let coins = SM64ActSelectorStarTypeBehavior.update(.init(type: .oneHundredCoins, size: 0.8, faceYaw: 0x4000, timer: 10))
        precondition(notSelected.size == 1 && notSelected.faceYaw == 0 && notSelected.timer == 5)
        precondition(selected.size == 1.3 && selected.faceYaw == 0x4800 && selected.timer == 8)
        precondition(selectedCap.size == 1.3 && selectedCap.faceYaw == 0x800 && selectedCap.timer == 9)
        precondition(coins.size == 0.8 && coins.faceYaw == 0x4800 && coins.timer == 11)

        var fingerprint = fnvOffset
        for output in [notSelected, selected, selectedCap, coins] {
            fingerprint = hash(fingerprint, UInt64(output.type.rawValue))
            fingerprint = hash(fingerprint, UInt64(output.size.bitPattern))
            fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.faceYaw)))
            fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.timer)))
            fingerprint = hash(fingerprint, UInt64(output.scale.bitPattern))
        }
        print(String(format: "actSelectorStarTypeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern act-selector star type smoke passed")
    }
}
