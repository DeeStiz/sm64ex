import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for byte in 0..<4 {
        hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff)
        hash &*= fnvPrime
    }
    return hash
}

private func hashF32(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU32(initial, value.bitPattern)
}

private func append(_ output: SM64TTCTreadmillOutput, to fingerprint: inout UInt64) {
    fingerprint = hashF32(fingerprint, output.speed)
    fingerprint = hashF32(fingerprint, output.targetSpeed)
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.timeUntilSwitch))
    fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.timer))
    fingerprint = hashF32(fingerprint, output.forwardVelocity)
    fingerprint = hashU32(fingerprint, output.becameMaster ? 1 : 0)
    fingerprint = hashU32(fingerprint, output.playsElevatorSound ? 1 : 0)
}

@main
enum SM64ModernTTCTreadmillSmoke {
    static func main() {
        let small = SM64TTCTreadmillBehavior.initialize(behaviorByte: 0, speedSetting: 0)
        let large = SM64TTCTreadmillBehavior.initialize(behaviorByte: 3, speedSetting: 1)
        let stopped = SM64TTCTreadmillBehavior.initialize(behaviorByte: 1, speedSetting: 3)
        precondition(small.collisionModelIndex == 0 && small.initialSurfaceSpeed == 50)
        precondition(large.collisionModelIndex == 1 && large.initialSurfaceSpeed == 100)
        precondition(stopped.initialSurfaceSpeed == 0)

        let nonMaster = SM64TTCTreadmillBehavior.update(
            SM64TTCTreadmillInput(speedSetting: 0, timer: 10, timeUntilSwitch: 0,
                                  speed: 50, targetSpeed: 0, isMaster: false,
                                  noMasterExists: false, randomTimeUntilSwitch: 20,
                                  randomDirection: -1)
        )
        let randomPause = SM64TTCTreadmillBehavior.update(
            SM64TTCTreadmillInput(speedSetting: 2, timer: 5, timeUntilSwitch: 10,
                                  speed: 0, targetSpeed: 50, isMaster: true,
                                  noMasterExists: false, randomTimeUntilSwitch: 20,
                                  randomDirection: -1)
        )
        let randomApproach = SM64TTCTreadmillBehavior.update(
            SM64TTCTreadmillInput(speedSetting: 2, timer: 6, timeUntilSwitch: 10,
                                  speed: 0, targetSpeed: 50, isMaster: true,
                                  noMasterExists: false, randomTimeUntilSwitch: 20,
                                  randomDirection: -1)
        )
        let randomSwitch = SM64TTCTreadmillBehavior.update(
            SM64TTCTreadmillInput(speedSetting: 2, timer: 11, timeUntilSwitch: 10,
                                  speed: 8, targetSpeed: 50, isMaster: true,
                                  noMasterExists: false, randomTimeUntilSwitch: 20,
                                  randomDirection: -1)
        )
        let elected = SM64TTCTreadmillBehavior.update(
            SM64TTCTreadmillInput(speedSetting: 0, timer: 0, timeUntilSwitch: 0,
                                  speed: 50, targetSpeed: 0, isMaster: false,
                                  noMasterExists: true, randomTimeUntilSwitch: 20,
                                  randomDirection: 1)
        )

        precondition(nonMaster.speed == 50 && nonMaster.forwardVelocity == 4.2
                     && !nonMaster.playsElevatorSound)
        precondition(randomPause.speed == 0 && randomPause.forwardVelocity == 0
                     && randomPause.playsElevatorSound)
        precondition(randomApproach.speed == 10 && randomApproach.forwardVelocity == 0.84)
        precondition(randomSwitch.speed == 0 && randomSwitch.targetSpeed == -50
                     && randomSwitch.timeUntilSwitch == 20 && randomSwitch.timer == 0)
        precondition(elected.becameMaster && elected.playsElevatorSound)

        var fingerprint = fnvOffset
        append(nonMaster, to: &fingerprint)
        append(randomPause, to: &fingerprint)
        append(randomApproach, to: &fingerprint)
        append(randomSwitch, to: &fingerprint)
        append(elected, to: &fingerprint)
        print(String(format: "ttcTreadmillFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern TTC treadmill smoke passed")
    }
}
