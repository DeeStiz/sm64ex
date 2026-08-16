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

private func hashState(_ initial: UInt64, _ state: SM64BobombBuddyState) -> UInt64 {
    var hash = hashU64(initial, UInt64(bitPattern: Int64(state.action)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.role)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.cannonStatus)))
    hash = hashU64(hash, state.hasTalked ? 1 : 0)
    hash = hashU64(hash, UInt64(UInt16(bitPattern: state.moveYaw)))
    return hashU64(hash, UInt64(state.blinkTimer))
}

private func hashOutput(_ initial: UInt64, _ output: SM64BobombBuddyOutput) -> UInt64 {
    var hash = hashState(initial, output.state)
    hash = hashU64(hash, output.playWalkingSound ? 1 : 0)
    hash = hashU64(hash, output.playReadSignSound ? 1 : 0)
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.dialogID)))
    hash = hashU64(hash, output.dialogRequested ? 1 : 0)
    hash = hashU64(hash, UInt64(bitPattern: Int64(output.cameraRequest)))
    hash = hashU64(hash, output.activeTimeStop ? 1 : 0)
    hash = hashU64(hash, output.clearTimeStop ? 1 : 0)
    hash = hashU64(hash, output.clearInteraction ? 1 : 0)
    return hashU64(hash, UInt64(output.visibilityDistance.bitPattern))
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernBobombBuddySmoke {
    static func main() {
        var state = SM64BobombBuddyState()
        var fingerprint = fnvOffset

        var output = SM64BobombBuddyBehavior.update(
            SM64BobombBuddyInput(
                animationFrame: 5,
                distanceToMario: 500,
                angleToMario: 0x2000,
                interacted: true,
                randomBlinkTimer: 11
            ),
            state: state
        )
        require(output.state.action == SM64BobombBuddyBehavior.turnToTalkAction, "interaction enters turn action")
        require(output.state.moveYaw == 0x140, "idle yaw approaches Mario")
        require(output.playWalkingSound && output.playReadSignSound, "turn transition sounds")
        fingerprint = hashOutput(fingerprint, output)
        state = output.state

        output = SM64BobombBuddyBehavior.update(
            SM64BobombBuddyInput(animationFrame: 16, angleToMario: 0x2000, randomBlinkTimer: 12),
            state: state
        )
        require(output.state.action == SM64BobombBuddyBehavior.turnToTalkAction, "turn remains until target")
        fingerprint = hashOutput(fingerprint, output)
        state = output.state

        output = SM64BobombBuddyBehavior.update(
            SM64BobombBuddyInput(angleToMario: 0x2000, randomBlinkTimer: 13),
            state: state
        )
        require(output.state.action == SM64BobombBuddyBehavior.talkAction, "turn reaches talk")
        fingerprint = hashOutput(fingerprint, output)
        state = output.state

        state.role = SM64BobombBuddyBehavior.adviceRole
        output = SM64BobombBuddyBehavior.update(
            SM64BobombBuddyInput(
                dialogOpenResult: 2,
                adviceDialogResult: 1,
                adviceDialogID: 77,
                randomBlinkTimer: 14
            ),
            state: state
        )
        require(output.dialogID == 77 && output.dialogRequested, "advice dialog request")
        require(output.state.hasTalked && output.state.action == SM64BobombBuddyBehavior.idleAction, "advice completion")
        require(output.clearTimeStop && output.clearInteraction, "advice cleanup")
        fingerprint = hashOutput(fingerprint, output)

        state = SM64BobombBuddyState(action: SM64BobombBuddyBehavior.talkAction, role: SM64BobombBuddyBehavior.cannonRole)
        output = SM64BobombBuddyBehavior.update(
            SM64BobombBuddyInput(dialogOpenResult: 2, cannonFirstDialogResult: 1, nearestCannonExists: true),
            state: state
        )
        require(output.dialogID == SM64BobombBuddyBehavior.bobombDialogID, "cannon first dialog")
        require(output.state.cannonStatus == SM64BobombBuddyBehavior.cannonOpening, "cannon opens")
        fingerprint = hashOutput(fingerprint, output)
        state = output.state

        output = SM64BobombBuddyBehavior.update(
            SM64BobombBuddyInput(dialogOpenResult: 2, cannonCutsceneResult: -1),
            state: state
        )
        require(output.cameraRequest == SM64BobombBuddyBehavior.cannonPrepareCameraRequest, "cannon prepare camera")
        require(output.state.cannonStatus == SM64BobombBuddyBehavior.cannonOpened, "cannon opened")
        fingerprint = hashOutput(fingerprint, output)
        state = output.state

        output = SM64BobombBuddyBehavior.update(
            SM64BobombBuddyInput(dialogOpenResult: 2, cannonSecondDialogResult: 1),
            state: state
        )
        require(output.dialogID == SM64BobombBuddyBehavior.bobombReadyDialogID, "cannon ready dialog")
        require(output.state.cannonStatus == SM64BobombBuddyBehavior.cannonStopTalking, "cannon stop phase")
        fingerprint = hashOutput(fingerprint, output)
        state = output.state

        output = SM64BobombBuddyBehavior.update(
            SM64BobombBuddyInput(dialogOpenResult: 2),
            state: state
        )
        require(output.state.action == SM64BobombBuddyBehavior.idleAction && output.state.hasTalked, "cannon completion")
        require(output.clearTimeStop && output.clearInteraction, "cannon cleanup")
        fingerprint = hashOutput(fingerprint, output)

        print(String(format: "bobombBuddyFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Bob-omb Buddy smoke passed")
    }
}
