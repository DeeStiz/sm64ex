import Foundation

private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for byte in 0..<8 { result ^= (value >> UInt64(byte * 8)) & 0xff; result &*= prime }; return result }
private func hash(_ seed: UInt64, _ value: Int32) -> UInt64 { hash(seed, UInt64(bitPattern: Int64(value))) }
private func hash(_ seed: UInt64, _ value: Float) -> UInt64 { hash(seed, UInt64(value.bitPattern)) }
private func hash(_ seed: UInt64, _ output: SM64BoulderOutput) -> UInt64 { var result=hash(seed,UInt64(output.action.rawValue));result=hash(result,output.position.y);result=hash(result,output.velocityY);result=hash(result,output.forwardVelocity);result=hash(result,output.facePitch);result=hash(result,output.scale);result=hash(result,output.graphYOffset);result=hash(result,output.hitboxRadius);result=hash(result,output.hitboxHeight);result=hash(result,UInt64(output.soundRoll ? 1:0));result=hash(result,UInt64(output.soundImpact ? 1:0));result=hash(result,UInt64(output.spawnMist ? 1:0));return hash(result,UInt64(output.shouldDelete ? 1:0)) }
@main struct SM64BoulderSmoke {
    static func main() {
        let rows=[SM64BoulderBehavior.update(.init(action:.initialize,position:.zero,velocityY:0,forwardVelocity:0,moveYaw:0,facePitch:0,stepFlags:0)),SM64BoulderBehavior.update(.init(action:.rolling,position:.zero,velocityY:20,forwardVelocity:80,moveYaw:0,facePitch:0,stepFlags:1)),SM64BoulderBehavior.update(.init(action:.rolling,position:.init(x:0,y:-1001,z:0),velocityY:0,forwardVelocity:20,moveYaw:0,facePitch:0,stepFlags:0))]
        precondition(rows[0].action == .rolling && rows[0].forwardVelocity == 40 && rows[0].scale == 1.5)
        precondition(rows[1].forwardVelocity == 70 && rows[1].soundRoll && rows[1].spawnMist && rows[1].soundImpact && rows[1].facePitch == 4666)
        precondition(rows[2].shouldDelete)
        var fingerprint=offset;for row in rows{fingerprint=hash(fingerprint,row)};print(String(format:"boulderFingerprint=0x%016llx",fingerprint));print("SM64 Modern boulder smoke passed")
    }
}
