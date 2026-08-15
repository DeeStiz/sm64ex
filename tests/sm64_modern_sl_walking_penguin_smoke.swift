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

@main
enum SM64ModernSLWalkingPenguinSmoke {
    static func main() {
        var action = SM64SLWalkingPenguinBehavior.movingForwards
        var step = 0
        var stepTimer = 0
        var position = SM64ObjectVector3(x: 600, y: 12, z: -40)
        var moveYaw: Int16 = 0x2000
        var fingerprint = fnvOffset

        for timer in 0..<65 {
            let output = SM64SLWalkingPenguinBehavior.update(
                .init(
                    action: action,
                    timer: Int32(timer),
                    currentStep: Int32(step),
                    currentStepTimer: Int32(stepTimer),
                    position: position,
                    moveYaw: moveYaw
                )
            )
            action = output.action
            step = Int(output.currentStep)
            stepTimer = Int(output.currentStepTimer)
            position = output.nextPosition
            moveYaw = output.moveYaw
            fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.action))
            fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.currentStep))
            fingerprint = hashU32(fingerprint, UInt32(bitPattern: output.currentStepTimer))
            fingerprint = hashU32(fingerprint, output.forwardVelocity.bitPattern)
            fingerprint = hashU32(fingerprint, UInt32(UInt16(bitPattern: output.angleVelocityYaw)))
            fingerprint = hashU32(fingerprint, UInt32(UInt16(bitPattern: output.moveYaw)))
            fingerprint = hashU32(fingerprint, output.nextPosition.x.bitPattern)
            fingerprint = hashU32(fingerprint, output.nextPosition.z.bitPattern)
        }

        let turn = SM64SLWalkingPenguinBehavior.update(
            .init(
                action: SM64SLWalkingPenguinBehavior.turningBack,
                timer: 31,
                currentStep: 0,
                currentStepTimer: 0,
                position: position,
                moveYaw: moveYaw
            )
        )
        precondition(turn.completedTurn && turn.action == SM64SLWalkingPenguinBehavior.returning)
        precondition(turn.angleVelocityYaw == 0x400)
        precondition(turn.forwardVelocity == 0)
        print(String(format: "slWalkingPenguinFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern SL walking penguin smoke passed")
    }
}
