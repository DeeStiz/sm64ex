import Foundation

private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 {
    var result = seed
    for byte in 0..<8 {
        result ^= (value >> UInt64(byte * 8)) & 0xff
        result &*= prime
    }
    return result
}
private func hash(_ seed: UInt64, _ value: Float) -> UInt64 { hash(seed, UInt64(value.bitPattern)) }

@main
struct SM64SushiSharkSmoke {
    static func main() {
        let first = SM64SushiSharkBehavior.update(.init(
            timer: 0,
            homePosition: .init(x: 10, y: 20, z: 30),
            orbitAngle: 0,
            waterLevel: 100,
            marioY: 100
        ))
        let next = SM64SushiSharkBehavior.update(.init(
            timer: 1,
            homePosition: .init(x: 10, y: 20, z: 30),
            orbitAngle: first.orbitAngle,
            waterLevel: 100,
            marioY: 100
        ))
        let outOfWater = SM64SushiSharkBehavior.update(.init(
            timer: 16,
            homePosition: .init(x: 10, y: -400, z: 30),
            orbitAngle: 0,
            waterLevel: 100,
            marioY: -500
        ))
        precondition(first.position == .init(x: 10, y: 120, z: 1730))
        precondition(first.moveYaw == 0x4000 && first.orbitAngle == 0x80)
        precondition(first.spawnWaveTrail && first.playWaterSound && first.clearInteractionStatus)
        precondition(next.orbitAngle == 0x100 && next.spawnWaveTrail && !next.playWaterSound)
        precondition(!outOfWater.spawnWaveTrail && outOfWater.playWaterSound)

        let engine = SM64SwiftEngineState(objectCapacity: 8)
        let bridge = SM64SushiSharkObjectBridge()
        let sharkID = try! bridge.spawnSushi(
            in: engine,
            position: .init(x: 10, y: 20, z: 30),
            orbitAngle: 0,
            waterLevel: 100,
            marioY: 100
        )
        let childID = bridge.registeredIDs.first { $0 != sharkID }
        precondition(childID != nil)
        let sharkRecord = engine.objects.record(for: sharkID)
        precondition(sharkRecord?.model == SM64SushiSharkObjectBridge.sushiModel)
        precondition(sharkRecord?.hitboxRadius == 100 && sharkRecord?.hitboxHeight == 50)
        precondition(sharkRecord?.hitboxDownOffset == 50 && sharkRecord?.intangibleTimer == 0)
        precondition(sharkRecord?.interactionType == SM64SushiSharkObjectBridge.damageInteractionType)
        precondition(childID.flatMap { engine.objects.record(for: $0)?.parent } == sharkID)
        precondition(childID.flatMap { engine.objects.record(for: $0).map { $0.graphFlags & 0x10 } } == 0x10)
        precondition(bridge.updateInline(sharkID, state: engine))
        precondition(bridge.effectLog.last?.output.position == first.position)
        precondition(childID.flatMap { engine.objects.record(for: $0)?.position } == first.position)

        var fingerprint = offset
        for output in [first, next, outOfWater] {
            fingerprint = hash(fingerprint, output.position.x)
            fingerprint = hash(fingerprint, output.position.y)
            fingerprint = hash(fingerprint, output.position.z)
            fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.moveYaw)))
            fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.orbitAngle)))
            fingerprint = hash(fingerprint, UInt64(output.spawnWaveTrail ? 1 : 0))
            fingerprint = hash(fingerprint, UInt64(output.playWaterSound ? 1 : 0))
            fingerprint = hash(fingerprint, UInt64(output.clearInteractionStatus ? 1 : 0))
        }
        print(String(format: "sushiSharkFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Sushi shark smoke passed")
    }
}
