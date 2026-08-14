import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hashU16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x=h; for i in 0..<2{x ^= UInt64((v >> UInt16(i*8)) & 0xff); x &*= fnvPrime}; return x }
private func hashU32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x=h; for i in 0..<4{x ^= UInt64((v >> UInt32(i*8)) & 0xff); x &*= fnvPrime}; return x }
private func hashFloat(_ h: UInt64, _ v: Float) -> UInt64 { hashU32(h, v.bitPattern) }

@main
enum SM64ModernMarioWalkingSlopeSmoke {
    static func main() {
        let floor = SM64MarioGroundFloorProbe(surfaceID: 1, height: 0, normalY: 1)
        let probes = Array(repeating: SM64MarioGroundQuarterProbe(
            floor: floor, ceilingHeight: 1000, waterLevel: 0, upperWall: nil
        ), count: 4)
        let slopeInput = SM64MarioSlopeInput(
            floorClass: .defaultClass,
            terrainIsSlide: false,
            floorNormalX: 0.6,
            floorNormalY: 0.8,
            floorNormalZ: 0,
            floorAngle: 0,
            faceYaw: 0,
            forwardVelocity: 12,
            action: SM64MarioActionID.idle
        )
        let input = SM64MarioWalkingActionInput(
            input: [], terrainIsSlide: false, facingDownhill: false,
            actionState: 0, actionArgument: 0, faceYaw: 0,
            intendedMagnitude: 20, intendedYaw: 0, forwardVelocity: 12,
            stickMagnitude: 0, floorNormalY: 0.8, quicksandDepth: 0,
            floorIsSlow: false, responsiveCheat: false, cheatsEnabled: false,
            groundStep: SM64MarioGroundStepInput(
                position: .zero, velocity: SM64ObjectVector3(x: 0, y: 0, z: 6),
                floor: floor, faceYaw: 0, nativeStepScale: 1,
                ridingShell: false, terrainSoundAddend: 0, quarterProbes: probes
            ),
            walkAnimation: SM64MarioWalkAnimationInput(
                intendedMagnitude: 20, forwardVelocity: 12, quicksandDepth: 0,
                actionTimer: 0, animationPastFrame23: false,
                animationPastFrame1: false, animationPastFrame2: false,
                metalCap: false, walkingPitch: 0, runningPitch: 0
            ),
            wallResponse: SM64MarioWallResponseInput(
                startPosition: .zero, position: .zero,
                velocity: SM64ObjectVector3(x: 0, y: 0, z: 6),
                forwardVelocity: 12, faceYaw: 0, animationFrame: 30,
                animationPastFrame1: false, animationPastFrame2: false,
                terrainSoundAddend: 0, floorSlopePitch: 0, wall: nil
            ),
            slope: slopeInput
        )
        let result = SM64MarioWalkingAction.update(input)!
        let speed = SM64MarioGroundSpeed.update(SM64MarioGroundSpeedInput(
            intendedMagnitude: 20, forwardVelocity: 12, quicksandDepth: 0,
            floorNormalY: 0.8, intendedYaw: 0, faceYaw: 0,
            floorIsSlow: false, responsiveCheat: false, cheatsEnabled: false
        ))!
        let expectedSlope = SM64MarioSlope.update(SM64MarioSlopeInput(
            floorClass: .defaultClass, terrainIsSlide: false,
            floorNormalX: 0.6, floorNormalY: 0.8, floorNormalZ: 0,
            floorAngle: 0, faceYaw: speed.faceYaw,
            forwardVelocity: speed.forwardVelocity, action: SM64MarioActionID.idle
        ))!
        precondition(result.intent == .continueGround)
        precondition(result.forwardVelocity == expectedSlope.forwardVelocity)
        precondition(result.velocity.z == expectedSlope.velocity.z)
        precondition(result.groundStep?.result == SM64MarioGroundStepOutcome.none)

        var hash = hashFloat(fnvOffset, result.forwardVelocity)
        hash = hashFloat(hash, result.velocity.z)
        hash = hashU16(hash, UInt16(bitPattern: result.faceYaw))
        hash = hashU16(hash, result.animationID ?? UInt16.max)
        hash = hashU32(hash, UInt32(bitPattern: result.animationAcceleration))
        hash = hashU16(hash, result.actionTimer)
        print(String(format: "marioWalkingSlopeFingerprint=0x%016llx", hash))
        print("SM64 Modern Mario walking-slope integration smoke passed")
    }
}
