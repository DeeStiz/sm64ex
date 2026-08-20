import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for index in 0..<8 { result ^= (value >> UInt64(index * 8)) & 0xff; result &*= fnvPrime }; return result }

@main
struct SM64SpawnedStarSmoke {
    static func main() {
        let initial = SM64SpawnedStarBehavior.initialState(starCollected: true, noExit: false, position: .zero, homePosition: .zero, marioPosition: .init(x: 0, y: 100, z: 0), moveToMario: true)
        precondition(initial.position.y == 350 && initial.model == .transparentStar && initial.velocityY == 50 && initial.angleVelocityYaw == 0x800)
        let launch = SM64SpawnedStarBehavior.update(.init(starCollected: false, noExit: false, action: .launch, timer: 0, position: .init(x: 0, y: 10, z: 0), homePosition: .init(x: 0, y: 0, z: 0), moveYaw: 0, faceYaw: 0, angleVelocityYaw: 0x800, forwardVelocity: 0, velocityY: 50, gravity: -4, interactionStatus: 0, cameraClear: false))
        let wait = SM64SpawnedStarBehavior.update(.init(starCollected: false, noExit: false, action: .waitForCutscene, timer: 0, position: .zero, homePosition: .zero, moveYaw: 0, faceYaw: 0, angleVelocityYaw: 0x800, forwardVelocity: 0, velocityY: 0, gravity: 0, interactionStatus: 0, cameraClear: true))
        let idleDelete = SM64SpawnedStarBehavior.update(.init(starCollected: false, noExit: true, action: .idle, timer: 0, position: .zero, homePosition: .zero, moveYaw: 0, faceYaw: 0, angleVelocityYaw: 0x400, forwardVelocity: 0, velocityY: 0, gravity: 0, interactionStatus: 1, cameraClear: true))
        precondition(launch.position.y == 56 && launch.faceYaw == 0x800 && launch.spawnSparkle && launch.soundIntent == .environmentStar)
        precondition(wait.action == .idle && wait.clearTimeStop)
        precondition(idleDelete.noExit && idleDelete.shouldDelete && idleDelete.clearInteraction && idleDelete.becomeTangible)
        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, UInt64(initial.position.y.bitPattern)); fingerprint = hash(fingerprint, UInt64(initial.model.rawValue)); fingerprint = hash(fingerprint, UInt64(initial.velocityY.bitPattern)); fingerprint = hash(fingerprint, UInt64(initial.angleVelocityYaw))
        fingerprint = hash(fingerprint, UInt64(launch.position.y.bitPattern)); fingerprint = hash(fingerprint, UInt64(launch.faceYaw)); fingerprint = hash(fingerprint, UInt64(launch.spawnSparkle ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(launch.soundIntent.rawValue))
        fingerprint = hash(fingerprint, UInt64(wait.action.rawValue)); fingerprint = hash(fingerprint, UInt64(wait.clearTimeStop ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(idleDelete.noExit ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(idleDelete.shouldDelete ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(idleDelete.clearInteraction ? 1 : 0))
        print(String(format: "spawnedStarFingerprint=0x%016llx", fingerprint)); print("SM64 Modern spawned-star smoke passed")
    }
}
