import Foundation
private let off:UInt64=1_469_598_103_934_665_603
private let prime:UInt64=1_099_511_628_211
private func hash(_ s:UInt64,_ v:UInt64)->UInt64{var r=s;for i in 0..<8{r^=(v>>UInt64(i*8))&255;r&*=prime};return r}
private func hash(_ s:UInt64,_ v:Int32)->UInt64{hash(s,UInt64(bitPattern:Int64(v)))}
private func hash(_ s:UInt64,_ v:Float)->UInt64{hash(s,UInt64(v.bitPattern))}
@main struct SM64FloorSwitchSmoke{
 static func main(){
  let idle=SM64FloorSwitchBehavior.update(.init(action:.idle,timer:0,behaviorByte:1,platformOn:true,lateralDistance:100,marioUnknown13:false))
  let pressed=SM64FloorSwitchBehavior.update(.init(action:.pressed,timer:3,behaviorByte:1,platformOn:true,lateralDistance:0,marioUnknown13:false))
  let fast=SM64FloorSwitchBehavior.update(.init(action:.ticking,timer:10,behaviorByte:1,platformOn:true,lateralDistance:0,marioUnknown13:false))
  let release=SM64FloorSwitchBehavior.update(.init(action:.ticking,timer:10,behaviorByte:1,platformOn:false,lateralDistance:0,marioUnknown13:false))
  let unpress=SM64FloorSwitchBehavior.update(.init(action:.unpressed,timer:3,behaviorByte:1,platformOn:false,lateralDistance:0,marioUnknown13:false))
  precondition(idle.action == .pressed && idle.timer == 0,"floor switch activation")
  precondition(pressed.action == .ticking && pressed.timer == 0 && pressed.scale == 0.2 && pressed.sound == .activate && pressed.rumble,"floor switch press")
  precondition(fast.sound == .tickFast && fast.scale == 0.2,"floor switch fast tick")
  precondition(release.action == .unpressed && release.timer == 0,"floor switch release")
  precondition(unpress.action == .idle && unpress.timer == 0 && unpress.scale == 1.5,"floor switch unpress")
  var f=off
  for o in [idle,pressed,fast,release,unpress]{f=hash(f,o.action.rawValue);f=hash(f,o.timer);f=hash(f,o.scale);f=hash(f,UInt64(o.sound.rawValue));f=hash(f,UInt64(o.rumble ? 1:0));f=hash(f,UInt64(o.loadCollisionModel ? 1:0))}
  print(String(format:"floorSwitchFingerprint=0x%016llx",f));print("SM64 Modern floor-switch smoke passed")
 }
}
