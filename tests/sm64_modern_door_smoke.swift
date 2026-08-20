import Foundation
private let off:UInt64=1_469_598_103_934_665_603
private let prime:UInt64=1_099_511_628_211
private func hash(_ s:UInt64,_ v:UInt64)->UInt64{var r=s;for i in 0..<8{r^=(v>>UInt64(i*8))&255;r&*=prime};return r}
private func hash(_ s:UInt64,_ v:Int32)->UInt64{hash(s,UInt64(bitPattern:Int64(v)))}
@main struct SM64DoorSmoke{static func main(){
 let closed=SM64DoorBehavior.update(.init(action:.closed,timer:0,interactionStatus:0,animationNearEnd:false,metalDoor:false,warpDoor:false,roomVisible:true))
 let wood=SM64DoorBehavior.update(.init(action:.closed,timer:4,interactionStatus:0x10000,animationNearEnd:false,metalDoor:false,warpDoor:false,roomVisible:true))
 let iron70=SM64DoorBehavior.update(.init(action:.openingIron,timer:70,interactionStatus:0,animationNearEnd:false,metalDoor:true,warpDoor:false,roomVisible:true))
 let warp30=SM64DoorBehavior.update(.init(action:.warpOpening,timer:30,interactionStatus:0,animationNearEnd:false,metalDoor:false,warpDoor:true,roomVisible:true))
 let end=SM64DoorBehavior.update(.init(action:.openingWood,timer:12,interactionStatus:0,animationNearEnd:true,metalDoor:false,warpDoor:false,roomVisible:false))
 precondition(closed.action == .closed && closed.timer == 1 && closed.loadCollisionModel,"door closed route")
 precondition(wood.action == .openingWood && wood.timer == 1 && wood.sound == .openWood && wood.cameraEvent == .door && wood.setMarioOpenedDoorTimeStop,"door wood opening route")
 precondition(iron70.sound == .closeIron && iron70.timer == 71,"door iron close sound timing")
 precondition(warp30.sound == .warpClose && warp30.cameraEvent == SM64DoorCameraEvent.none,"warp door close timing")
 precondition(end.action == .closed && end.timer == 0 && !end.visible && end.animationState == 0,"door animation reset/visibility")
 var f=off
 for o in [closed,wood,iron70,warp30,end]{f=hash(f,o.action.rawValue);f=hash(f,o.timer);f=hash(f,o.animationState);f=hash(f,UInt64(o.visible ? 1:0));f=hash(f,UInt64(o.loadCollisionModel ? 1:0));f=hash(f,UInt64(o.sound.rawValue));f=hash(f,UInt64(o.cameraEvent.rawValue));f=hash(f,UInt64(o.setMarioOpenedDoorTimeStop ? 1:0));f=hash(f,UInt64(o.clearInteractionStatus ? 1:0))}
 print(String(format:"doorFingerprint=0x%016llx",f));print("SM64 Modern door smoke passed")
}}
