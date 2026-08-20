import Foundation
private let off:UInt64=1_469_598_103_934_665_603
private let prime:UInt64=1_099_511_628_211
private func hash(_ s:UInt64,_ v:UInt64)->UInt64{var r=s;for i in 0..<8{r^=(v>>UInt64(i*8))&255;r&*=prime};return r}
private func hash(_ s:UInt64,_ v:Int32)->UInt64{hash(s,UInt64(bitPattern:Int64(v)))}
private func hash(_ s:UInt64,_ v:Float)->UInt64{hash(s,UInt64(v.bitPattern))}
@main struct SM64CoinSmoke{static func main(){
 let yellow=SM64CoinBehavior.update(.init(kind:.yellow,timer:0,animationState:-1,interacted:false,floorDistance:600))
 let temp=SM64CoinBehavior.update(.init(kind:.temporary,timer:200,animationState:4,interacted:false,floorDistance:0))
 let expired=SM64CoinBehavior.update(.init(kind:.temporary,timer:243,animationState:8,interacted:false,floorDistance:0))
 let collected=SM64CoinBehavior.update(.init(kind:.yellow,timer:3,animationState:2,interacted:true,floorDistance:0))
 precondition(yellow.timer==1&&yellow.animationState==0&&yellow.modelNoShadow&&yellow.damageOrCoinValue==1,"yellow coin route")
 precondition(temp.visible && temp.timer == 201 && !temp.shouldDelete,"temporary coin blink start")
 precondition(!expired.visible&&expired.shouldDelete,"temporary coin expiry")
 precondition(collected.spawnGoldenSparkles&&collected.shouldDelete,"coin interaction retirement")
 var f=off;for o in [yellow,temp,expired,collected]{f=hash(f,UInt64(o.kind.rawValue));f=hash(f,o.timer);f=hash(f,o.animationState);f=hash(f,UInt64(o.visible ? 1:0));f=hash(f,UInt64(o.modelNoShadow ? 1:0));f=hash(f,UInt64(o.spawnGoldenSparkles ? 1:0));f=hash(f,UInt64(o.shouldDelete ? 1:0));f=hash(f,o.hitboxRadius);f=hash(f,o.hitboxHeight);f=hash(f,o.damageOrCoinValue)};print(String(format:"coinFingerprint=0x%016llx",f));print("SM64 Modern coin smoke passed")
}}
