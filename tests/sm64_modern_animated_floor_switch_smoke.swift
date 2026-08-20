import Foundation
private let off:UInt64=1_469_598_103_934_665_603
private let prime:UInt64=1_099_511_628_211
private func hash(_ s:UInt64,_ v:UInt64)->UInt64{var r=s;for i in 0..<8{r^=(v>>UInt64(i*8))&255;r&*=prime};return r}
private func hash(_ s:UInt64,_ v:Int32)->UInt64{hash(s,UInt64(bitPattern:Int64(v)))}
@main struct SM64AnimatedFloorSwitchSmoke{
 static func main(){
  let start=SM64AnimatedFloorSwitchBehavior.update(.init(parentAction:2,behaviorByte:0,animationActive:false,toggle:0,remaining:0,frame:0))
  let fast=SM64AnimatedFloorSwitchBehavior.update(.init(parentAction:2,behaviorByte:0,animationActive:true,toggle:1,remaining:250,frame:4))
  let slow=SM64AnimatedFloorSwitchBehavior.update(.init(parentAction:0,behaviorByte:0,animationActive:false,toggle:1,remaining:59,frame:9))
  let reset=SM64AnimatedFloorSwitchBehavior.update(.init(parentAction:0,behaviorByte:0,animationActive:true,toggle:1,remaining:50,frame:8))
  precondition(start.animationActive && start.toggle == 1 && start.remaining == 249 && start.frame == 1,"animated floor-switch activation")
  precondition(fast.remaining == 249 && fast.frame == 5 && fast.sound == .fast,"animated floor-switch fast tick")
  precondition(slow.remaining == 58 && slow.sound == .slow,"animated floor-switch slow tick")
  precondition(!reset.animationActive && reset.remaining == 249 && reset.frame == 9,"animated floor-switch parent reset")
  var f=off
  for o in [start,fast,slow,reset]{f=hash(f,UInt64(o.animationActive ? 1:0));f=hash(f,o.toggle);f=hash(f,o.remaining);f=hash(f,o.frame);f=hash(f,o.modelFrame);f=hash(f,UInt64(o.sound.rawValue));f=hash(f,UInt64(o.loadCollisionModel ? 1:0))}
  print(String(format:"animatedFloorSwitchFingerprint=0x%016llx",f));print("SM64 Modern animated-floor-switch smoke passed")
 }
}
