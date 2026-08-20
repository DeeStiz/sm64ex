import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 {
        hash ^= (value >> UInt64(byte * 8)) & 0xff
        hash &*= fnvPrime
    }
    return hash
}

private func hashOutput(_ initial: UInt64, _ output: SM64LllDrawbridgeOutput) -> UInt64 {
    var hash = hashU64(initial, UInt64(bitPattern: Int64(output.action)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.faceRoll)))
    hash = hashU64(hash, output.playLowerSound ? 1 : 0)
    return hashU64(hash, output.playRaiseSound ? 1 : 0)
}

@main
struct SM64LllDrawbridgeSmoke {
    static func main() {
        let cases = [
            SM64LllDrawbridgeInput(action: 0, timer: 0, globalTimer: 1, faceRoll: 0),
            SM64LllDrawbridgeInput(action: 0, timer: 51, globalTimer: 8, faceRoll: 0),
            SM64LllDrawbridgeInput(action: 1, timer: 51, globalTimer: 8, faceRoll: -0x1F00),
            SM64LllDrawbridgeInput(action: 1, timer: 1, globalTimer: 2, faceRoll: 0),
        ]
        var fingerprint = fnvOffset
        let outputs = cases.map(SM64LllDrawbridgeBehavior.update)
        for output in outputs { fingerprint = hashOutput(fingerprint, output) }

        precondition(outputs[0].faceRoll == 0 && !outputs[0].playRaiseSound)
        precondition(outputs[1].action == 1 && outputs[1].faceRoll == 0 && outputs[1].playRaiseSound)
        precondition(outputs[2].action == 0 && outputs[2].faceRoll == -0x2001 && outputs[2].playLowerSound)
        precondition(outputs[3].action == 1 && outputs[3].faceRoll == -0x100)

        print(String(format: "lllDrawbridgeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern LLL drawbridge smoke passed")
    }
}
