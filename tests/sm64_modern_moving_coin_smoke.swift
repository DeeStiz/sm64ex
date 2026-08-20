import Foundation
private let off:UInt64=1_469_598_103_934_665_603
private let prime:UInt64=1_099_511_628_211
private func hash(_ s:UInt64,_ v:UInt64)->UInt64{var r=s;for i in 0..<8{r^=(v>>UInt64(i*8))&255;r&*=prime};return r}
private func hash(_ s:UInt64,_ v:Int32)->UInt64{hash(s,UInt64(bitPattern:Int64(v)))}
private func hash(_ s:UInt64,_ v:Float)->UInt64{hash(s,UInt64(v.bitPattern))}
@main struct SM64MovingCoinSmoke{static func main(){
 let y=SM64MovingCoinBehavior.update(.init(kind:.yellow,action:0,timer:10,forwardVelocity:0,velocityY:0,collisionGrounded:true,collisionNoYVelocity:false,floorDeath:false,withinMarioRadius:false,interacted:false))
 let yExpire=SM64MovingCoinBehavior.update(.init(kind:.yellow,action:0,timer:301,forwardVelocity:0,velocityY:0,collisionGrounded:false,collisionNoYVelocity:false,floorDeath:false,withinMarioRadius:false,interacted:false))
 let bStill=SM64MovingCoinBehavior.update(.init(kind:.blue,action:0,timer:3,forwardVelocity:20,velocityY:0,collisionGrounded:false,collisionNoYVelocity:false,floorDeath:false,withinMarioRadius:true,interacted:false))
 let bMove=SM64MovingCoinBehavior.update(.init(kind:.blue,action:1,timer:10,forwardVelocity:60,velocityY:0,collisionGrounded:true,collisionNoYVelocity:false,floorDeath:false,withinMarioRadius:false,interacted:false))
 let collect=SM64MovingCoinBehavior.update(.init(kind:.blue,action:1,timer:10,forwardVelocity:60,velocityY:0,collisionGrounded:false,collisionNoYVelocity:false,floorDeath:false,withinMarioRadius:false,interacted:true))
 let sliding=SM64MovingCoinBehavior.update(.init(kind:.blueSliding,action:0,timer:0,forwardVelocity:0,velocityY:0,collisionGrounded:false,collisionNoYVelocity:false,floorDeath:false,withinMarioRadius:false,interacted:false,withinMario500:true,withinMario1000:true))
 let jumping=SM64MovingCoinBehavior.update(.init(kind:.blueJumping,action:0,timer:0,forwardVelocity:0,velocityY:0,collisionGrounded:false,collisionNoYVelocity:false,floorDeath:false,withinMarioRadius:false,interacted:false))
 let slidingAway=SM64MovingCoinBehavior.update(.init(kind:.blueSliding,action:1,timer:0,forwardVelocity:0,velocityY:0,collisionGrounded:true,collisionNoYVelocity:false,floorDeath:false,withinMarioRadius:false,interacted:false,angleToMario:0x1000,withinMario1000:true))
 precondition(y.tangible&&y.soundCoinDrop&&y.timer==11,"moving yellow coin idle")
 precondition(yExpire.action==1&&yExpire.timer==0,"moving yellow coin action timeout")
 precondition(bStill.action==1&&bStill.timer==0,"moving blue coin radius admission")
 precondition(bMove.forwardVelocity==75&&bMove.soundCoinDrop,"moving blue coin ground acceleration")
 precondition(collect.spawnGoldenSparkles&&collect.shouldDelete,"moving coin collection")
 precondition(sliding.action==1&&sliding.tangible,"moving blue sliding admission")
 precondition(jumping.velocityY==50 && !jumping.tangible,"moving blue jumping launch")
 precondition(slidingAway.velocityY==18&&slidingAway.soundCoinDrop,"moving blue sliding bounce")
 var f=off;for o in [y,yExpire,bStill,bMove,collect,sliding,jumping,slidingAway]{f=hash(f,UInt64(o.kind.rawValue));f=hash(f,o.action);f=hash(f,o.timer);f=hash(f,o.forwardVelocity);f=hash(f,o.velocityY);f=hash(f,UInt64(o.tangible ? 1:0));f=hash(f,UInt64(o.soundCoinDrop ? 1:0));f=hash(f,UInt64(o.spawnGoldenSparkles ? 1:0));f=hash(f,UInt64(o.shouldDelete ? 1:0));f=hash(f,o.damageOrCoinValue)};print(String(format:"movingCoinFingerprint=0x%016llx",f));print("SM64 Modern moving-coin smoke passed")
}}
