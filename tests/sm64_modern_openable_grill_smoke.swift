import Foundation
private let off: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var r=seed; for i in 0..<8 { r ^= (value >> UInt64(i*8)) & 255; r &*= prime }; return r }
private func hash(_ seed: UInt64, _ value: Int32) -> UInt64 { hash(seed, UInt64(bitPattern: Int64(value))) }
@main struct SM64OpenableGrillSmoke {
 static func main() {
  let spawn = SM64OpenableGrillBehavior.update(.init(action:.spawnChildren,timer:0,variant:0,floorSwitchFound:false,floorSwitchAction:nil))
  let wait = SM64OpenableGrillBehavior.update(.init(action:.waitForSwitch,timer:0,variant:1,floorSwitchFound:true,floorSwitchAction:nil))
  let open = SM64OpenableGrillBehavior.update(.init(action:.open,timer:4,variant:1,floorSwitchFound:true,floorSwitchAction:2))
  let done = SM64OpenableGrillBehavior.update(.init(action:.done,timer:2,variant:1,floorSwitchFound:false,floorSwitchAction:nil))
  precondition(spawn.action == .waitForSwitch && spawn.timer == 0 && spawn.spawnChildren, "openable grill child spawn")
  precondition(wait.action == .open && wait.timer == 0 && !wait.playCageOpenSound, "openable grill floor-switch admission")
  precondition(open.action == .done && open.timer == 0 && open.signalChildren && open.playCageOpenSound && open.playPuzzleJingle, "openable grill open signal")
  precondition(done.action == .done && done.timer == 3, "openable grill done route")
  let child0 = SM64OpenableCageDoorBehavior.update(.init(action:0,timer:0,faceYaw:0,yawDirection:-1,parentOpenSignal:0))
  let child1 = SM64OpenableCageDoorBehavior.update(.init(action:1,timer:0,faceYaw:0,yawDirection:-1,parentOpenSignal:2))
  let childEnd = SM64OpenableCageDoorBehavior.update(.init(action:1,timer:64,faceYaw:-0x4000,yawDirection:-1,parentOpenSignal:2))
  precondition(child0.action == 0 && child0.timer == 1 && child1.action == 1 && child1.faceYaw == 0x100 && childEnd.action == 2 && childEnd.timer == 0, "openable cage child motion")
  var f=off
  for o in [spawn,wait,open,done] { f=hash(f,o.action.rawValue); f=hash(f,o.timer); f=hash(f,UInt64(o.spawnChildren ? 1:0)); f=hash(f,UInt64(o.signalChildren ? 1:0)); f=hash(f,UInt64(o.playCageOpenSound ? 1:0)); f=hash(f,UInt64(o.playPuzzleJingle ? 1:0)) }
  for o in [child0,child1,childEnd] { f=hash(f,o.action); f=hash(f,o.timer); f=hash(f,o.faceYaw); f=hash(f,UInt64(o.loadCollisionModel ? 1:0)) }
  print(String(format:"openableGrillFingerprint=0x%016llx",f)); print("SM64 Modern openable-grill smoke passed")
 }
}
