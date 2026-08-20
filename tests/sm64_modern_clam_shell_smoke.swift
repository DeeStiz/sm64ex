import Foundation
private let offset:UInt64=1_469_598_103_934_665_603
private let prime:UInt64=1_099_511_628_211
private func hash(_ seed:UInt64,_ value:UInt64)->UInt64{var r=seed;for i in 0..<8{r^=(value>>UInt64(i*8))&255;r&*=prime};return r}
@main struct SM64ClamShellSmoke{static func main(){
 let opening=SM64ClamShellBehavior.update(.init(action:.closed,timer:151,shakeTimer:0,distanceToMario:400,animationFrame25:false,animationFrame8:false,animationFrame30:false,renderingEnabled:true))
 let tangible=SM64ClamShellBehavior.update(.init(action:.closed,timer:0,shakeTimer:0,distanceToMario:1000,animationFrame25:true,animationFrame8:false,animationFrame30:false,renderingEnabled:true))
 let bubbles=SM64ClamShellBehavior.update(.init(action:.opening,timer:0,shakeTimer:0,distanceToMario:1000,animationFrame25:false,animationFrame8:true,animationFrame30:false,renderingEnabled:true))
 precondition(opening.action == .opening && opening.timer == 0)
 precondition(tangible.tangible && tangible.shakeTimer == 10)
 precondition(bubbles.spawnBubbleCount == 12)
 var f=offset;for o in [opening,tangible,bubbles]{f=hash(f,UInt64(o.action.rawValue));f=hash(f,UInt64(bitPattern:Int64(o.timer)));f=hash(f,UInt64(bitPattern:Int64(o.shakeTimer)));f=hash(f,UInt64(o.tangible ? 1:0));f=hash(f,UInt64(o.spawnBubbleCount))};print(String(format:"clamShellFingerprint=0x%016llx",f));print("SM64 Modern clam-shell smoke passed")
}}
