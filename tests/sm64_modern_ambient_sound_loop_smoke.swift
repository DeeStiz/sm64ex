import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 { hash ^= (value >> UInt64(byte * 8)) & 0xff; hash &*= fnvPrime }
    return hash
}

@main
struct SM64AmbientSoundLoopSmoke {
    static func main() {
        let inputs = [
            SM64AmbientSoundLoopInput(kind: .birds, behaviorByte: 0, cameraBehindMario: false),
            SM64AmbientSoundLoopInput(kind: .birds, behaviorByte: 2, cameraBehindMario: false),
            SM64AmbientSoundLoopInput(kind: .birds, behaviorByte: 3, cameraBehindMario: false),
            SM64AmbientSoundLoopInput(kind: .birds, behaviorByte: 0, cameraBehindMario: true),
            SM64AmbientSoundLoopInput(kind: .sand, behaviorByte: 0, cameraBehindMario: false),
            SM64AmbientSoundLoopInput(kind: .sand, behaviorByte: 0, cameraBehindMario: true),
        ]
        let outputs = inputs.map(SM64AmbientSoundLoopBehavior.update)
        precondition(outputs.map(\.soundIntent) == [0, 2, -1, -1, 3, -1])
        precondition(outputs.map(\.playSound) == [true, true, false, false, true, false])
        var fingerprint = fnvOffset
        for output in outputs {
            fingerprint = hashU64(fingerprint, UInt64(bitPattern: Int64(output.soundIntent)))
            fingerprint = hashU64(fingerprint, output.playSound ? 1 : 0)
        }
        print(String(format: "ambientSoundLoopFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern ambient sound loop smoke passed")
    }
}
