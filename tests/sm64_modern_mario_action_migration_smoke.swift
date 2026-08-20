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

private func hashFloat(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU32(initial, value.bitPattern)
}

private func hashMutation(_ initial: UInt64, _ requested: UInt32,
                          _ mutation: SM64MarioActionMutation) -> UInt64 {
    var hash = hashU32(initial, requested)
    hash = hashU32(hash, mutation.action)
    hash = hashU32(hash, mutation.previousAction)
    hash = hashU32(hash, mutation.actionArgument)
    hash = hashU32(hash, UInt32(mutation.actionState))
    hash = hashU32(hash, UInt32(mutation.actionTimer))
    hash = hashU32(hash, mutation.flags)
    hash = hashFloat(hash, mutation.velocity.x)
    hash = hashFloat(hash, mutation.velocity.y)
    hash = hashFloat(hash, mutation.velocity.z)
    hash = hashFloat(hash, mutation.forwardVelocity)
    hash = hashU32(hash, UInt32(bitPattern: mutation.faceAngle.pitch))
    hash = hashU32(hash, UInt32(bitPattern: mutation.faceAngle.yaw))
    hash = hashU32(hash, UInt32(bitPattern: mutation.faceAngle.roll))
    hash = hashU32(hash, UInt32(mutation.wallKickTimer))
    hash = hashFloat(hash, mutation.peakHeight)
    hash = hashU32(hash, mutation.droppedHeldObject ? 1 : 0)
    hash = hashU32(hash, mutation.droppedRiddenObject ? 1 : 0)
    return hashU32(hash, UInt32(mutation.hurtCounter))
}

private func seededState() -> SM64MarioState {
    var state = SM64MarioState()
    state.action = SM64MarioActionID.idle
    state.flags = SM64MarioActionBits.actionSoundPlayed
        | SM64MarioActionBits.marioSoundPlayed
        | SM64MarioActionBits.unknown18
    state.intendedMagnitude = 6
    state.intendedYaw = 0x3000
    state.faceAngle = SM64ObjectAngles(pitch: 0x111, yaw: 0x2000, roll: -0x222)
    state.position = SM64ObjectVector3(x: 1, y: 37, z: -4)
    state.forwardVelocity = 2
    state.velocity = SM64ObjectVector3(x: 3, y: 4, z: 5)
    state.peakHeight = 11
    return state
}

@main
enum SM64ModernMarioActionMigrationSmoke {
    static func main() {
        var fingerprint = fnvOffset
        let actions: [UInt32] = [
            SM64MarioActionID.walking,
            SM64MarioActionID.beginSliding,
            SM64MarioActionID.doubleJump,
            SM64MarioActionID.backflip,
            SM64MarioActionID.longJump,
            SM64MarioActionID.sideFlip,
            SM64MarioActionID.metalWaterJump,
            SM64MarioActionID.jumpKick
        ]
        for action in actions {
            var state = seededState()
            if action == SM64MarioActionID.doubleJump { state.forwardVelocity = 20 }
            let mutation = state.setAction(action, floorClass: 0, facingDownhill: false)
            fingerprint = hashMutation(
                fingerprint,
                action,
                mutation
            )
        }
        print(String(format: "marioActionMigrationFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario action migration Swift smoke passed")
    }
}
