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

private func hashOutput(_ initial: UInt64, _ output: SM64IdleWaterWaveOutput) -> UInt64 {
    var hash = hashU64(initial, UInt64(bitPattern: Int64(output.animationState)))
    hash = hashU64(hash, UInt64(output.position.x.bitPattern))
    hash = hashU64(hash, UInt64(output.position.y.bitPattern))
    hash = hashU64(hash, UInt64(output.position.z.bitPattern))
    hash = hashU64(hash, output.deactivate ? 1 : 0)
    return hashU64(hash, output.clearMarioFlag ? 1 : 0)
}

@main
struct SM64IdleWaterWaveSmoke {
    static func main() {
        let cases = [
            SM64IdleWaterWaveInput(animationState: 0, globalTimer: 1),
            SM64IdleWaterWaveInput(animationState: 15, globalTimer: 16),
            SM64IdleWaterWaveInput(animationState: 31, globalTimer: 32),
            SM64IdleWaterWaveInput(animationState: -1, globalTimer: 7),
        ]
        var fingerprint = fnvOffset
        let outputs = cases.map(SM64IdleWaterWaveBehavior.update)
        let idleCases = [
            SM64IdleWaterWaveInput(
                animationState: 0, globalTimer: 1,
                marioPosition: .init(x: 10, y: 20, z: 30),
                marioWaterLevel: 100, marioParticleFlags: 0x80
            ),
            SM64IdleWaterWaveInput(
                animationState: 1, globalTimer: 2,
                marioPosition: .init(x: -5, y: 0, z: 7),
                marioWaterLevel: -10, marioParticleFlags: 0
            ),
        ]
        let idleOutputs = idleCases.map(SM64IdleWaterWaveBehavior.updateIdle)
        for output in outputs + idleOutputs { fingerprint = hashOutput(fingerprint, output) }
        precondition(outputs.map(\.animationState) == [1, 16, 32, 0])
        precondition(outputs.map(\.deactivate) == [false, true, true, false])
        precondition(idleOutputs[0].position == .init(x: 10, y: 105, z: 30)
            && !idleOutputs[0].deactivate && !idleOutputs[0].clearMarioFlag)
        precondition(idleOutputs[1].position == .init(x: -5, y: -5, z: 7)
            && idleOutputs[1].deactivate && idleOutputs[1].clearMarioFlag)
        print(String(format: "idleWaterWaveFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern idle water wave smoke passed")
    }
}
