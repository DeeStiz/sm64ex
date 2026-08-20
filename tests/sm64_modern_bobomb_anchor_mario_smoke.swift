import Foundation
private let offset:UInt64=1_469_598_103_934_665_603
private let prime:UInt64=1_099_511_628_211
private func hash(_ seed:UInt64,_ value:UInt64)->UInt64{var r=seed;for i in 0..<8{r^=(value>>UInt64(i*8))&255;r&*=prime};return r}
@main struct SM64BobombAnchorSmoke{static func main(){
 let thr=SM64BobombAnchorMarioBehavior.update(.init(parentMoveYaw:0x2000,parentThrowState:2,parentActive:true))
 let toss=SM64BobombAnchorMarioBehavior.update(.init(parentMoveYaw:0x1000,parentThrowState:3,parentActive:true))
 let dead=SM64BobombAnchorMarioBehavior.update(.init(parentMoveYaw:0,parentThrowState:0,parentActive:false))
 precondition(thr.parentRelativePosition == .init(x:100,y:0,z:150)&&thr.throwForwardVelocity==50&&thr.throwMario)
 precondition(toss.throwForwardVelocity==10&&toss.tossMario)
 precondition(dead.shouldDelete)
 var f=offset;for o in [thr,toss,dead]{f=hash(f,UInt64(bitPattern:Int64(o.moveYaw)));f=hash(f,UInt64(o.throwMario ? 1:0));f=hash(f,UInt64(o.tossMario ? 1:0));f=hash(f,UInt64(o.shouldDelete ? 1:0))};print(String(format:"bobombAnchorFingerprint=0x%016llx",f));print("SM64 Modern Bob-omb anchor smoke passed")
}}
