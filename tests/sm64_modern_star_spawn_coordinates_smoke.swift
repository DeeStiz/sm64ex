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
struct SM64StarSpawnCoordinatesSmoke {
    static func main() {
        let initial = SM64StarSpawnCoordinatesBehavior.initialState(
            starCollected: false,
            position: .zero,
            homePosition: .init(x: 0, y: 30, z: 30)
        )
        precondition(initial.moveYaw == 0 && initial.forwardVelocity == 1 && initial.velocityY == 1 && initial.model == .star)

        let intro = SM64StarSpawnCoordinatesBehavior.update(.init(
            starCollected: false,
            action: .intro,
            timer: 0,
            position: .zero,
            homePosition: .init(x: 0, y: 30, z: 30),
            moveYaw: 0x4000,
            faceYaw: 0,
            forwardVelocity: 1,
            velocityY: 1,
            starSpawnBaseY: 0,
            interactionStatus: 0
        ))
        let rise = SM64StarSpawnCoordinatesBehavior.update(.init(
            starCollected: false,
            action: .rise,
            timer: 0,
            position: .zero,
            homePosition: .init(x: 0, y: 30, z: 30),
            moveYaw: 0,
            faceYaw: 0,
            forwardVelocity: 2,
            velocityY: 1,
            starSpawnBaseY: 0,
            interactionStatus: 0
        ))
        let riseEnd = SM64StarSpawnCoordinatesBehavior.update(.init(
            starCollected: true,
            action: .rise,
            timer: 30,
            position: .init(x: 0, y: 0, z: 0),
            homePosition: .init(x: 0, y: 30, z: 30),
            moveYaw: 0,
            faceYaw: 0,
            forwardVelocity: 2,
            velocityY: 1,
            starSpawnBaseY: 0,
            interactionStatus: 0
        ))
        let landed = SM64StarSpawnCoordinatesBehavior.update(.init(
            starCollected: false,
            action: .fall,
            timer: 20,
            position: .init(x: 0, y: 5, z: 0),
            homePosition: .init(x: 0, y: 0, z: 0),
            moveYaw: 0,
            faceYaw: 0x1000,
            forwardVelocity: 0,
            velocityY: 0,
            starSpawnBaseY: 0,
            interactionStatus: 0
        ))
        let clear = SM64StarSpawnCoordinatesBehavior.update(.init(
            starCollected: false,
            action: .landed,
            timer: 20,
            position: .zero,
            homePosition: .zero,
            moveYaw: 0,
            faceYaw: 0,
            forwardVelocity: 0,
            velocityY: 0,
            starSpawnBaseY: 0,
            interactionStatus: 0
        ))
        let delete = SM64StarSpawnCoordinatesBehavior.update(.init(
            starCollected: false,
            action: .landed,
            timer: 21,
            position: .zero,
            homePosition: .zero,
            moveYaw: 0,
            faceYaw: 0,
            forwardVelocity: 0,
            velocityY: 0,
            starSpawnBaseY: 0,
            interactionStatus: 1
        ))

        precondition(intro.faceYaw == 0x1000 && intro.action == .intro)
        precondition(rise.position == .init(x: 0, y: 1, z: 2) && rise.spawnSparkle && rise.soundIntent == .environmentStar)
        precondition(riseEnd.action == .fall && riseEnd.forwardVelocity == 0 && riseEnd.model == .transparentStar)
        precondition(landed.action == .landed && landed.position.y == 0 && landed.becomeTangible && landed.soundIntent == .starAppears)
        precondition(clear.clearTimeStop && clear.faceYaw == 0x800)
        precondition(delete.shouldDelete && delete.clearInteraction)

        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(initial.moveYaw)))
        fingerprint = hash(fingerprint, UInt64(initial.forwardVelocity.bitPattern))
        fingerprint = hash(fingerprint, UInt64(initial.velocityY.bitPattern))
        fingerprint = hash(fingerprint, UInt64(intro.faceYaw))
        fingerprint = hash(fingerprint, UInt64(rise.position.y.bitPattern))
        fingerprint = hash(fingerprint, UInt64(rise.position.z.bitPattern))
        fingerprint = hash(fingerprint, UInt64(rise.spawnSparkle ? 1 : 0))
        fingerprint = hash(fingerprint, UInt64(riseEnd.action.rawValue))
        fingerprint = hash(fingerprint, UInt64(riseEnd.model.rawValue))
        fingerprint = hash(fingerprint, UInt64(landed.position.y.bitPattern))
        fingerprint = hash(fingerprint, UInt64(landed.becomeTangible ? 1 : 0))
        fingerprint = hash(fingerprint, UInt64(landed.soundIntent.rawValue))
        fingerprint = hash(fingerprint, UInt64(clear.clearTimeStop ? 1 : 0))
        fingerprint = hash(fingerprint, UInt64(delete.shouldDelete ? 1 : 0))
        print(String(format: "starSpawnCoordinatesFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern star-spawn coordinates smoke passed")
    }
}
