import Foundation
private let offset:UInt64=1_469_598_103_934_665_603
private let prime:UInt64=1_099_511_628_211
private func hash(_ seed:UInt64,_ value:UInt64)->UInt64{var r=seed;for i in 0..<8{r^=(value>>UInt64(i*8))&255;r&*=prime};return r}
@main struct SM64BubSmoke{static func main(){
 let sp=SM64BubBehavior.updateSpawner(action:0,timer:0,distanceToMario:100,marioY:0,positionY:0,childCount:2)
 let initBub=SM64BubBehavior.updateBub(action:0,timer:0,position:.zero,moveYaw:0,forwardVelocity:0,waterLevel:100,targetY:100,angleToMario:0,angleToHome:0,distanceToMario:1000,lateralDistanceHome:0,randomFleeTrigger:false,interacted:false,parentDuplicate:false)
 let patrol=SM64BubBehavior.updateBub(action:1,timer:0,position:.zero,moveYaw:0,forwardVelocity:0,waterLevel:100,targetY:100,angleToMario:0,angleToHome:0,distanceToMario:1000,lateralDistanceHome:0,randomFleeTrigger:false,interacted:false,parentDuplicate:false)
 let flee=SM64BubBehavior.updateBub(action:2,timer:201,position:.zero,moveYaw:0,forwardVelocity:0,waterLevel:100,targetY:100,angleToMario:0,angleToHome:0,distanceToMario:700,lateralDistanceHome:0,randomFleeTrigger:false,interacted:false,parentDuplicate:false)
 precondition(sp.spawnedChildren==2&&sp.action==1);precondition(initBub.action==1);precondition(patrol.forwardVelocity==3&&patrol.position.z==3);precondition(flee.action==1&&flee.forwardVelocity==6)
 var f=offset;for o in [sp,initBub,patrol,flee]{f=hash(f,UInt64(bitPattern:Int64(o.action)));f=hash(f,UInt64(bitPattern:Int64(o.timer)));f=hash(f,UInt64(o.spawnedChildren));f=hash(f,UInt64(o.spawnParticle ? 1:0));f=hash(f,UInt64(o.shouldDelete ? 1:0))};print(String(format:"bubFingerprint=0x%016llx",f));print("SM64 Modern Bub smoke passed")
}}
