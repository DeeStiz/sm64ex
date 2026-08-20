import Foundation
private let fnvOffset: UInt64=1_469_598_103_934_665_603, fnvPrime: UInt64=1_099_511_628_211
private func hu(_ h:UInt64,_ v:UInt32)->UInt64{var x=h;for b in 0..<4{x ^= UInt64((v>>UInt32(b*8))&0xff);x &*= fnvPrime};return x}
private func hf(_ h:UInt64,_ v:Float)->UInt64{hu(h,v.bitPattern)}
private func ap(_ o:SM64CheckerboardPlatformOutput,_ h:inout UInt64){h=hu(h,UInt32(bitPattern:o.action));h=hu(h,UInt32(bitPattern:o.timer));h=hf(h,o.positionX);h=hf(h,o.positionY);h=hf(h,o.positionZ);h=hu(h,UInt32(bitPattern:o.movePitch));h=hu(h,UInt32(bitPattern:o.facePitch));h=hu(h,UInt32(bitPattern:o.angleVelocityPitch));h=hf(h,o.forwardVelocity);h=hf(h,o.velocityY);h=hu(h,o.shouldDelete ? 1:0)}
@main enum SM64ModernCheckerboardPlatformSmoke{static func main(){
 let first=SM64CheckerboardPlatformBehavior.update(SM64CheckerboardPlatformInput(kind:.child,action:0,timer:0,waitTime:65,childParameter:0,speed:7,positionX:0,positionY:100,positionZ:0,moveYaw:0,movePitch:0,facePitch:0,angleVelocityPitch:0,forwardVelocity:0,velocityY:0))
 let second=SM64CheckerboardPlatformBehavior.update(SM64CheckerboardPlatformInput(kind:.child,action:0,timer:0,waitTime:65,childParameter:1,speed:7,positionX:0,positionY:100,positionZ:0,moveYaw:0,movePitch:0,facePitch:0,angleVelocityPitch:0,forwardVelocity:0,velocityY:0))
 let move=SM64CheckerboardPlatformBehavior.update(SM64CheckerboardPlatformInput(kind:.child,action:1,timer:0,waitTime:65,childParameter:0,speed:7,positionX:0,positionY:100,positionZ:0,moveYaw:0,movePitch:0,facePitch:0,angleVelocityPitch:0,forwardVelocity:0,velocityY:0))
 let rotate=SM64CheckerboardPlatformBehavior.update(SM64CheckerboardPlatformInput(kind:.child,action:2,timer:0,waitTime:65,childParameter:0,speed:0,positionX:0,positionY:100,positionZ:0,moveYaw:0,movePitch:0,facePitch:0,angleVelocityPitch:0,forwardVelocity:0,velocityY:0))
 let descend=SM64CheckerboardPlatformBehavior.update(SM64CheckerboardPlatformInput(kind:.child,action:3,timer:66,waitTime:65,childParameter:0,speed:7,positionX:0,positionY:100,positionZ:0,moveYaw:0,movePitch:0,facePitch:0,angleVelocityPitch:0,forwardVelocity:0,velocityY:0))
 precondition(first.action==1 && second.action==3 && move.action==1 && move.positionY==110 && move.velocityY==10 && rotate.movePitch==512 && descend.action==4 && descend.positionY==90)
 var h=fnvOffset;ap(first,&h);ap(second,&h);ap(move,&h);ap(rotate,&h);ap(descend,&h);print(String(format:"checkerboardPlatformFingerprint=0x%016llx",h));print("SM64 Modern checkerboard platform smoke passed")
}}
