import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result=seed; for index in 0..<8 { result ^= (value >> UInt64(index*8)) & 0xff; result &*= fnvPrime }; return result }
@main struct SM64GroundParticleSpawnerSmoke { static func main() { let seeds=Array(repeating:SM64StarKeyPuffSeed(velocity:.init(x:0,y:20,z:1),scale:0.5),count:4); let output=SM64GroundParticleSpawnerBehavior.update(.init(kind:.dirt,position:.init(x:10,y:20,z:-4),timer:0,activeParticleFlags:0x4000,particleFlag:0x4000,seeds:seeds)); precondition(output.seeds.count==4 && output.clearParticleFlag && !output.shouldDeactivate); var f=fnvOffset; f=hash(f,UInt64(output.seeds.count)); f=hash(f,output.clearParticleFlag ? 1:0); f=hash(f,output.shouldDeactivate ? 1:0); print(String(format:"groundParticleSpawnerFingerprint=0x%016llx",f)); print("SM64 Modern ground particle spawner smoke passed") } }
