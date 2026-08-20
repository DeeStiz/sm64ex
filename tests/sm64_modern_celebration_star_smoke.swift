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

private let home = SM64ObjectVector3(x: 10, y: 130, z: -4)

@main
struct SM64CelebrationStarSmoke {
    static func main() {
        let initial = SM64CelebrationStarBehavior.initialState(
            variant: .star,
            marioPosition: .init(x: 10, y: 100, z: -4),
            marioYaw: 0
        )
        precondition(initial.position == home && initial.moveYaw == 0x8000 && initial.scale == 0.4 && initial.faceRoll == 0 && initial.diameter == 100)

        let spin = SM64CelebrationStarBehavior.update(.init(
            variant: .star,
            action: .spinAroundMario,
            timer: 0,
            position: home,
            homePosition: home,
            moveYaw: 0,
            faceYaw: 0,
            facePitch: 0,
            faceRoll: 0,
            diameter: 100,
            scale: 0.4,
            marioYaw: 0
        ))
        precondition(spin.position == .init(x: 10, y: 135, z: 46) && spin.moveYaw == 0x2000 && spin.faceYaw == 0x1000 && spin.diameter == 101 && spin.spawnSparkle)

        let transition = SM64CelebrationStarBehavior.update(.init(
            variant: .star,
            action: .spinAroundMario,
            timer: 40,
            position: home,
            homePosition: home,
            moveYaw: 0,
            faceYaw: 0,
            facePitch: 0,
            faceRoll: 0,
            diameter: 135,
            scale: 0.4,
            marioYaw: 0
        ))
        precondition(transition.action == .faceCamera && transition.diameter == 115 && !transition.spawnSparkle)

        let face = SM64CelebrationStarBehavior.update(.init(
            variant: .star,
            action: .faceCamera,
            timer: 10,
            position: home,
            homePosition: home,
            moveYaw: 0,
            faceYaw: 0x1000,
            facePitch: 0,
            faceRoll: 0,
            diameter: 100,
            scale: 0.4,
            marioYaw: 0x1234
        ))
        precondition(face.faceYaw == 0x1234 && face.scale == 0.4 && !face.shouldDeactivate)

        let keyInitial = SM64CelebrationStarBehavior.initialState(
            variant: .bowserKey,
            marioPosition: .init(x: 10, y: 100, z: -4),
            marioYaw: 0
        )
        precondition(keyInitial.scale == 0.1 && keyInitial.faceRoll == 49_152)

        let keyFace = SM64CelebrationStarBehavior.update(.init(
            variant: .bowserKey,
            action: .faceCamera,
            timer: 0,
            position: home,
            homePosition: home,
            moveYaw: 0,
            faceYaw: 0,
            facePitch: 0,
            faceRoll: 49_152,
            diameter: 100,
            scale: 0.1,
            marioYaw: 0
        ))
        precondition(keyFace.scale == 0 && keyFace.faceYaw == 0x1000 && keyFace.faceRoll == 49_152)

        let end = SM64CelebrationStarBehavior.update(.init(
            variant: .star,
            action: .faceCamera,
            timer: 59,
            position: home,
            homePosition: home,
            moveYaw: 0,
            faceYaw: 0,
            facePitch: 0,
            faceRoll: 0,
            diameter: 100,
            scale: 0.4,
            marioYaw: 0
        ))
        precondition(end.shouldDeactivate)

        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, UInt64(initial.position.y.bitPattern))
        fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(initial.moveYaw)))
        fingerprint = hash(fingerprint, UInt64(initial.scale.bitPattern))
        fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(initial.faceRoll)))
        fingerprint = hash(fingerprint, UInt64(spin.position.y.bitPattern))
        fingerprint = hash(fingerprint, UInt64(spin.position.z.bitPattern))
        fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(spin.moveYaw)))
        fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(spin.faceYaw)))
        fingerprint = hash(fingerprint, UInt64(spin.diameter.bitPattern))
        fingerprint = hash(fingerprint, UInt64(spin.spawnSparkle ? 1 : 0))
        fingerprint = hash(fingerprint, UInt64(transition.action.rawValue))
        fingerprint = hash(fingerprint, UInt64(transition.diameter.bitPattern))
        fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(face.faceYaw)))
        fingerprint = hash(fingerprint, UInt64(keyInitial.scale.bitPattern))
        fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(keyInitial.faceRoll)))
        fingerprint = hash(fingerprint, UInt64(keyFace.scale.bitPattern))
        fingerprint = hash(fingerprint, UInt64(end.shouldDeactivate ? 1 : 0))
        print(String(format: "celebrationStarFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern celebration star smoke passed")
    }
}
