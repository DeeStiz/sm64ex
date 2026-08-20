import Foundation
private let off:UInt64=1_469_598_103_934_665_603
private let prime:UInt64=1_099_511_628_211
private func hash(_ s:UInt64,_ v:UInt64)->UInt64{var r=s;for i in 0..<8{r^=(v>>UInt64(i*8))&255;r&*=prime};return r}
private func hash(_ s:UInt64,_ v:Int32)->UInt64{hash(s,UInt64(bitPattern:Int64(v)))}
private func hash(_ s:UInt64,_ v:Float)->UInt64{hash(s,UInt64(v.bitPattern))}
@main struct SM64HiddenObjectSmoke{static func main(){
 let hidden=SM64HiddenObjectBehavior.update(.init(action:.hidden,timer:0,variant:0,switchAction:nil,attackedOrGroundPounded:false))
 let show=SM64HiddenObjectBehavior.update(.init(action:.hidden,timer:4,variant:1,switchAction:2,attackedOrGroundPounded:false))
 let blink=SM64HiddenObjectBehavior.update(.init(action:.visible,timer:360,variant:1,switchAction:2,attackedOrGroundPounded:false))
 let broken=SM64HiddenObjectBehavior.update(.init(action:.visible,timer:12,variant:0,switchAction:2,attackedOrGroundPounded:true))
 let reset=SM64HiddenObjectBehavior.update(.init(action:.broken,timer:2,variant:0,switchAction:0,attackedOrGroundPounded:false))
 precondition(!hidden.visible && !hidden.tangible && hidden.timer == 1,"hidden object hidden route")
 precondition(show.action == .visible && show.visible && show.tangible && show.timer == 0 && show.numLootCoins == 3,"hidden object reveal route")
 precondition(blink.visible && blink.loadCollisionModel,"hidden object blink route")
 precondition(broken.action == .broken && broken.spawnMist && broken.spawnTriangleBreak && broken.playBreakSound && !broken.loadCollisionModel,"hidden object break route")
 precondition(reset.action == .hidden && reset.timer == 0,"hidden object reset route")
 var f=off;for o in [hidden,show,blink,broken,reset]{f=hash(f,o.action.rawValue);f=hash(f,o.timer);f=hash(f,UInt64(o.visible ? 1:0));f=hash(f,UInt64(o.tangible ? 1:0));f=hash(f,o.scale);f=hash(f,o.numLootCoins);f=hash(f,UInt64(o.spawnMist ? 1:0));f=hash(f,UInt64(o.spawnTriangleBreak ? 1:0));f=hash(f,UInt64(o.playBreakSound ? 1:0));f=hash(f,UInt64(o.loadCollisionModel ? 1:0))};print(String(format:"hiddenObjectFingerprint=0x%016llx",f));print("SM64 Modern hidden-object smoke passed")
}}
