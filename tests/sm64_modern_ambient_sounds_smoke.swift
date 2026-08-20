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
struct SM64AmbientSoundsSmoke {
    static func main() {
        let output = SM64AmbientSoundsBehavior.update(.init(cameraBehindMario: false))
        precondition(output.playCastleOutdoorsAmbient)
        let suppressed = SM64AmbientSoundsBehavior.update(.init(cameraBehindMario: true))
        precondition(!suppressed.playCastleOutdoorsAmbient)

        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, output.playCastleOutdoorsAmbient ? 1 : 0)
        fingerprint = hash(fingerprint, suppressed.playCastleOutdoorsAmbient ? 1 : 0)
        print(String(format: "ambientSoundsFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern ambient sounds smoke passed")
    }
}
