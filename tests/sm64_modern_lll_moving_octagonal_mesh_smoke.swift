import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 { var h=initial; for b in 0..<4 { h ^= UInt64((value >> UInt32(b*8)) & 0xff); h &*= fnvPrime }; return h }
private func hashF32(_ initial: UInt64, _ value: Float) -> UInt64 { hashU32(initial, value.bitPattern) }
private func append(_ o: SM64LllMovingOctagonalMeshOutput, to h: inout UInt64) {
    h=hashU32(h,UInt32(bitPattern:o.action)); h=hashU32(h,UInt32(bitPattern:o.timer)); h=hashU32(h,UInt32(bitPattern:o.sequenceIndex))
    h=hashF32(h,o.positionX); h=hashF32(h,o.positionY); h=hashF32(h,o.positionZ); h=hashF32(h,o.forwardVelocity)
    h=hashU32(h,UInt32(bitPattern:o.moveYaw)); h=hashF32(h,o.velocityX); h=hashF32(h,o.velocityZ)
    h=hashU32(h,UInt32(bitPattern:o.verticalAngle)); h=hashU32(h,UInt32(bitPattern:o.rotationAngle)); h=hashF32(h,o.baseOffset); h=hashU32(h,o.reachedVerticalEndpoint ? 1:0)
}

@main
enum SM64ModernLllMovingOctagonalMeshSmoke {
    static func main() {
        let first = SM64LllMovingOctagonalMeshBehavior.update(SM64LllMovingOctagonalMeshInput(
            mode: 0, action: 0, timer: 0, sequenceIndex: 0, positionX: 0, positionY: 50,
            positionZ: 0, homeY: 100, forwardVelocity: 0, moveYaw: 0x4000,
            verticalAngle: 0, rotationAngle: -0x800, baseOffset: 0, marioOnPlatform: false
        ))
        let waitEnd = SM64LllMovingOctagonalMeshBehavior.update(SM64LllMovingOctagonalMeshInput(
            mode: 0, action: 1, timer: 31, sequenceIndex: 0, positionX: 0, positionY: 100,
            positionZ: 0, homeY: 100, forwardVelocity: 0, moveYaw: 0,
            verticalAngle: 0, rotationAngle: -0x800, baseOffset: 0, marioOnPlatform: false
        ))
        let accelerate = SM64LllMovingOctagonalMeshBehavior.update(SM64LllMovingOctagonalMeshInput(
            mode: 0, action: 1, timer: 0, sequenceIndex: 4, positionX: 0, positionY: 100,
            positionZ: 0, homeY: 100, forwardVelocity: 0, moveYaw: 0x4000,
            verticalAngle: 0, rotationAngle: -0x800, baseOffset: 0, marioOnPlatform: false
        ))
        let waitForMario = SM64LllMovingOctagonalMeshBehavior.update(SM64LllMovingOctagonalMeshInput(
            mode: 1, action: 1, timer: 0, sequenceIndex: 0, positionX: 0, positionY: 100,
            positionZ: 0, homeY: 100, forwardVelocity: 0, moveYaw: 0,
            verticalAngle: 0, rotationAngle: -0x800, baseOffset: 0, marioOnPlatform: false
        ))
        let marioStart = SM64LllMovingOctagonalMeshBehavior.update(SM64LllMovingOctagonalMeshInput(
            mode: 1, action: 1, timer: 0, sequenceIndex: 0, positionX: 0, positionY: 100,
            positionZ: 0, homeY: 100, forwardVelocity: 0, moveYaw: 0,
            verticalAngle: 0, rotationAngle: -0x800, baseOffset: 0, marioOnPlatform: true
        ))
        let top = SM64LllMovingOctagonalMeshBehavior.update(SM64LllMovingOctagonalMeshInput(
            mode: 1, action: 1, timer: 0, sequenceIndex: 4, positionX: 0, positionY: 100,
            positionZ: 0, homeY: 100, forwardVelocity: 0, moveYaw: 0,
            verticalAngle: 0x4000, rotationAngle: -0x800, baseOffset: 0, marioOnPlatform: true
        ))
        precondition(first.action == 1 && first.sequenceIndex == 0 && first.positionY == 100)
        precondition(waitEnd.sequenceIndex == 4 && waitEnd.timer == 0 && waitEnd.moveYaw == 0x4000)
        precondition(accelerate.forwardVelocity == 0.3 && accelerate.positionX == 0.3 && accelerate.moveYaw == 0x4000)
        precondition(waitForMario.sequenceIndex == 0 && marioStart.sequenceIndex == 4)
        precondition(top.positionY == 20 && top.verticalAngle == 0x4000 && top.forwardVelocity == 0.3)
        var h=fnvOffset; append(first,to:&h); append(waitEnd,to:&h); append(accelerate,to:&h); append(waitForMario,to:&h); append(marioStart,to:&h); append(top,to:&h)
        print(String(format:"lllMovingOctagonalMeshFingerprint=0x%016llx",h)); print("SM64 Modern LLL moving octagonal mesh smoke passed")
    }
}
