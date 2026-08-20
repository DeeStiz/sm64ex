import Foundation
private let offset:UInt64=1_469_598_103_934_665_603
private let prime:UInt64=1_099_511_628_211
private func hash(_ seed:UInt64,_ value:UInt64)->UInt64{var r=seed;for i in 0..<8{r^=(value>>UInt64(i*8))&255;r&*=prime};return r}
@main struct SM64ButterflySmoke{static func main(){
 let rest=SM64ButterflyBehavior.update(.init(action:.resting,position:.zero,homePosition:.zero,moveYaw:0,movePitch:0,yPhase:0,distanceToMario:500,homeDistance:0,angleToMario:0,angleToHome:0,pitchToHome:0))
 let follow=SM64ButterflyBehavior.update(.init(action:.followMario,position:.zero,homePosition:.zero,moveYaw:0,movePitch:0,yPhase:0,distanceToMario:500,homeDistance:0,angleToMario:0,angleToHome:0,pitchToHome:0))
 let back=SM64ButterflyBehavior.update(.init(action:.returnHome,position:.zero,homePosition:.init(x:5,y:6,z:7),moveYaw:0,movePitch:0,yPhase:0,distanceToMario:1000,homeDistance:0,angleToMario:0,angleToHome:0,pitchToHome:0))
 precondition(rest.action == .followMario&&rest.animationState==0);precondition(follow.position.z==7);precondition(back.action == .resting&&back.animationState==1)
 var f=offset;for o in [rest,follow,back]{f=hash(f,UInt64(o.action.rawValue));f=hash(f,UInt64(bitPattern:Int64(o.moveYaw)));f=hash(f,UInt64(bitPattern:Int64(o.movePitch)));f=hash(f,UInt64(bitPattern:Int64(o.animationState)))};print(String(format:"butterflyFingerprint=0x%016llx",f));print("SM64 Modern butterfly smoke passed")
}}
