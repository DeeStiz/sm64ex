import Foundation
private let off:UInt64=1_469_598_103_934_665_603
private let prime:UInt64=1_099_511_628_211
private func hash(_ s:UInt64,_ v:UInt64)->UInt64{var r=s;for i in 0..<8{r^=(v>>UInt64(i*8))&255;r&*=prime};return r}
private func hash(_ s:UInt64,_ v:Int32)->UInt64{hash(s,UInt64(bitPattern:Int64(v)))}
private func hash(_ s:UInt64,_ v:Float)->UInt64{hash(s,UInt64(v.bitPattern))}
@main struct SM64RecoveryHeartSmoke{static func main(){
 let idle=SM64RecoveryHeartBehavior.update(.init(collidedWithMario:false,marioForwardVelocity:0,soundPlayed:false,yawVelocity:450,totalSpin:100,faceYaw:0))
 let hit=SM64RecoveryHeartBehavior.update(.init(collidedWithMario:true,marioForwardVelocity:10,soundPlayed:false,yawVelocity:400,totalSpin:0xFF00,faceYaw:0))
 let hitSilent=SM64RecoveryHeartBehavior.update(.init(collidedWithMario:true,marioForwardVelocity:10,soundPlayed:true,yawVelocity:3000,totalSpin:0,faceYaw:0))
 precondition(idle.yawVelocity == 400 && idle.totalSpin == 500 && idle.faceYaw == 400 && !idle.soundSpin,"recovery heart decay")
 precondition(hit.yawVelocity == 3000 && hit.soundSpin && hit.healCounterDelta == 4 && hit.totalSpin == 0x0AB8,"recovery heart hit/heal")
 precondition(!hitSilent.soundSpin && hitSilent.soundPlayed && hitSilent.faceYaw == 3000,"recovery heart sound gate")
 var f=off;for o in [idle,hit,hitSilent]{f=hash(f,UInt64(o.soundSpin ? 1:0));f=hash(f,UInt64(o.soundPlayed ? 1:0));f=hash(f,o.yawVelocity);f=hash(f,o.totalSpin);f=hash(f,o.faceYaw);f=hash(f,o.healCounterDelta);f=hash(f,o.hitboxRadius);f=hash(f,o.hitboxHeight);f=hash(f,o.hurtboxRadius);f=hash(f,o.hurtboxHeight)};print(String(format:"recoveryHeartFingerprint=0x%016llx",f));print("SM64 Modern recovery-heart smoke passed")
}}
