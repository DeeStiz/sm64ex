import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU8(_ initial: UInt64, _ value: UInt8) -> UInt64 {
    var hash = initial; hash ^= UInt64(value); hash &*= fnvPrime; return hash
}

private func hashU16(_ initial: UInt64, _ value: UInt16) -> UInt64 {
    var hash = initial
    for byte in 0..<2 { hash ^= UInt64((value >> UInt16(byte * 8)) & 0xff); hash &*= fnvPrime }
    return hash
}

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for byte in 0..<4 { hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff); hash &*= fnvPrime }
    return hash
}

private func hashFloat(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU32(initial, value.bitPattern)
}

private func hashResult(_ initial: UInt64, _ result: SM64MarioSlopeResult) -> UInt64 {
    var hash = hashU8(initial, result.facingDownhill ? 1 : 0)
    hash = hashU8(hash, result.floorIsSlope ? 1 : 0)
    hash = hashU8(hash, result.floorIsSteep ? 1 : 0)
    hash = hashFloat(hash, result.forwardVelocity)
    hash = hashU16(hash, UInt16(bitPattern: result.slideYaw))
    hash = hashFloat(hash, result.slideVelocityX)
    hash = hashFloat(hash, result.slideVelocityZ)
    hash = hashFloat(hash, result.velocity.y)
    hash = hashU8(hash, result.shouldUpdateMovingSand ? 1 : 0)
    return hashU8(hash, result.shouldUpdateWindyGround ? 1 : 0)
}

private func input(
    floorClass: SM64MarioFloorClass = .defaultClass,
    terrainSlide: Bool = false,
    normalX: Float = 0,
    normalY: Float = 1,
    normalZ: Float = 0,
    floorAngle: Int16 = 0,
    faceYaw: Int16 = 0,
    forward: Float = 10,
    action: UInt32 = SM64MarioActionID.idle
) -> SM64MarioSlopeInput {
    SM64MarioSlopeInput(
        floorClass: floorClass,
        terrainIsSlide: terrainSlide,
        floorNormalX: normalX,
        floorNormalY: normalY,
        floorNormalZ: normalZ,
        floorAngle: floorAngle,
        faceYaw: faceYaw,
        forwardVelocity: forward,
        action: action
    )
}

@main
enum SM64ModernMarioSlopeSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let flat = SM64MarioSlope.update(input())!
        precondition(flat.facingDownhill && !flat.floorIsSlope && !flat.floorIsSteep
            && flat.forwardVelocity == 10 && flat.velocity.z == 10)
        fingerprint = hashResult(fingerprint, flat)

        let slide = SM64MarioSlope.update(input(
            terrainSlide: true, normalY: 0.99
        ))!
        precondition(slide.floorIsSlope && slide.facingDownhill)
        fingerprint = hashResult(fingerprint, slide)

        let verySlippery = SM64MarioSlope.update(input(
            floorClass: .verySlippery, normalX: 0.3122499, normalY: 0.95
        ))!
        precondition(verySlippery.floorIsSlope && verySlippery.forwardVelocity > 10)
        fingerprint = hashResult(fingerprint, verySlippery)

        let uphill = SM64MarioSlope.update(input(
            normalX: 0.6, normalY: 0.8, floorAngle: Int16(bitPattern: 0x8000)
        ))!
        precondition(uphill.floorIsSlope && !uphill.facingDownhill && uphill.forwardVelocity < 10)
        fingerprint = hashResult(fingerprint, uphill)

        let softKnockback = SM64MarioSlope.update(input(
            floorClass: .verySlippery, normalX: 0.3122499, normalY: 0.95,
            action: SM64MarioActionID.softForwardGroundKnockback
        ))!
        precondition(softKnockback.forwardVelocity < verySlippery.forwardVelocity)
        fingerprint = hashResult(fingerprint, softKnockback)

        let steep = SM64MarioSlope.update(input(
            normalX: 0.6, normalY: 0.8, floorAngle: 0x4000
        ))!
        precondition(!steep.facingDownhill && steep.floorIsSteep)
        fingerprint = hashResult(fingerprint, steep)

        let notSteepDownhill = SM64MarioSlope.update(input(
            normalX: 0.6, normalY: 0.8, floorAngle: 0
        ))!
        precondition(notSteepDownhill.facingDownhill && !notSteepDownhill.floorIsSteep)
        fingerprint = hashResult(fingerprint, notSteepDownhill)

        let boundary = SM64MarioSlope.update(input(floorAngle: 0x4000))!
        precondition(!boundary.facingDownhill)
        fingerprint = hashResult(fingerprint, boundary)

        precondition(SM64MarioSlope.update(input(normalY: .infinity)) == nil)
        print(String(format: "marioSlopeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario slope smoke passed")
    }
}
