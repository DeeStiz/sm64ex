import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64,_ v: UInt8)->UInt64{var x=h;x ^= UInt64(v);x &*= fnvPrime;return x}
private func h16(_ h: UInt64,_ v: UInt16)->UInt64{var x=h;for i in 0..<2{x ^= UInt64((v >> UInt16(i*8))&0xff);x &*= fnvPrime};return x}
private func h32(_ h: UInt64,_ v: UInt32)->UInt64{var x=h;for i in 0..<4{x ^= UInt64((v >> UInt32(i*8))&0xff);x &*= fnvPrime};return x}
private func hf(_ h: UInt64,_ v: Float)->UInt64{h32(h,v.bitPattern)}
private func hash(_ h: UInt64,_ r: SM64MarioLedgeCannonActionResult)->UInt64{
 var x=h8(h,r.variant.rawValue);x=h8(x,r.intent.rawValue);x=h32(x,r.action ?? UInt32.max);x=h32(x,r.actionArgument)
 x=h8(x,r.actionState);x=h16(x,r.actionTimer);x=h16(x,r.animationID);x=h16(x,UInt16(bitPattern:r.faceYaw));x=h16(x,UInt16(bitPattern:r.facePitch));x=h16(x,UInt16(bitPattern:r.cannonInputYaw))
 x=hf(x,r.position.x);x=hf(x,r.position.y);x=hf(x,r.position.z);x=hf(x,r.velocity.x);x=hf(x,r.velocity.y);x=hf(x,r.velocity.z);x=hf(x,r.forwardVelocity)
 x=h8(x,r.shouldHideMario ? 1:0);x=h8(x,r.shouldShowMario ? 1:0);x=h8(x,r.shouldMarkCannonInteracted ? 1:0);x=h8(x,r.shouldPlayWhoa ? 1:0);x=h8(x,r.shouldPlayClimbSound ? 1:0);x=h8(x,r.shouldPlayLandingSound ? 1:0);x=h8(x,r.shouldPlayCannonAimSound ? 1:0);x=h8(x,r.shouldQueueRumble ? 1:0);x=h8(x,r.shouldResetRumble ? 1:0);return h8(x,r.shouldReleaseLedge ? 1:0)
}
private func input(_ variant: SM64MarioLedgeCannonVariant,flags:SM64MarioInputFlags=[],state:UInt8=0,arg:UInt32=0,timer:UInt16=0,end:Bool=false,frame:Int16=0,normal:Float=1,floor:Float=0,ceil:Float=300,y:Float=100,height:Float=120,intended:Int16=0,face:Int16=0,hurt:Bool=false,sound:Bool=false,space:Bool=true,cannonActive:Bool=false,cannonPos:SM64ObjectVector3 = .init(x:10,y:20,z:30),cannonPitch:Int16=0x2000,cannonYaw:Int16=0x1000,cannonInputYaw:Int16=0,stickX:Float=0,stickY:Float=0,startPitch:Int16=0x2000,startYaw:Int16=0x1000)->SM64MarioLedgeCannonActionInput{
 SM64MarioLedgeCannonActionInput(variant:variant,input:flags,actionState:state,actionArgument:arg,actionTimer:timer,animationAtEnd:end,animationFrame:frame,floorNormalY:normal,floorHeight:floor,ceilingHeight:ceil,positionY:y,heightAboveFloor:height,intendedYaw:intended,faceYaw:face,interactionHurts:hurt,soundPlayed:sound,hasSpaceForMario:space,cannonActive:cannonActive,cannonPosition:cannonPos,cannonObjectPitch:cannonPitch,cannonObjectYaw:cannonYaw,cannonInputYaw:cannonInputYaw,stickX:stickX,stickY:stickY,startFacePitch:startPitch,startFaceYaw:startYaw)
}

@main
enum SM64ModernMarioLedgeCannonSmoke {
 static func main(){
  var fingerprint=fnvOffset
  let grab=SM64MarioLedgeCannonAction.update(input(.ledgeGrab,flags:[.nonzeroAnalog],timer:9,intended:0,face:0))!;precondition(grab.intent == .ledgeClimbSlow1);fingerprint=hash(fingerprint,grab)
  let fast=SM64MarioLedgeCannonAction.update(input(.ledgeGrab,flags:[.aPressed],space:true))!;precondition(fast.action == SM64MarioActionID.ledgeClimbFast);fingerprint=hash(fingerprint,fast)
  let down=SM64MarioLedgeCannonAction.update(input(.ledgeClimbDown,end:true,sound:true))!;precondition(down.action == SM64MarioActionID.ledgeGrab && down.actionArgument == 1);fingerprint=hash(fingerprint,down)
  let climb=SM64MarioLedgeCannonAction.update(input(.ledgeClimbFast,frame:8,sound:true))!;precondition(climb.shouldPlayLandingSound);fingerprint=hash(fingerprint,climb)
  let cannon0=SM64MarioLedgeCannonAction.update(input(.inCannon,state:0,cannonPos:.init(x:1,y:2,z:3)))!;precondition(cannon0.actionState == 1 && cannon0.shouldHideMario);fingerprint=hash(fingerprint,cannon0)
  let cannon1=SM64MarioLedgeCannonAction.update(input(.inCannon,state:1,cannonActive:true,cannonPitch:0x3000,cannonYaw:0x2000,startPitch:0x3000,startYaw:0x2000))!;precondition(cannon1.actionState == 2);fingerprint=hash(fingerprint,cannon1)
  let shot=SM64MarioLedgeCannonAction.update(input(.inCannon,flags:[.aPressed],state:2,cannonActive:true,cannonPitch:0x3000,cannonYaw:0x2000,startPitch:0x3000,startYaw:0x2000))!;precondition(shot.action == SM64MarioActionID.shotFromCannon && shot.shouldShowMario);fingerprint=hash(fingerprint,shot)
  precondition(SM64MarioLedgeCannonAction.update(input(.inCannon,stickX:.infinity)) == nil)
  print(String(format:"marioLedgeCannonFingerprint=0x%016llx",fingerprint));print("SM64 Modern Mario ledge/cannon smoke passed")
 }
}
