import Foundation
private let off:UInt64=1_469_598_103_934_665_603
private let prime:UInt64=1_099_511_628_211
private func hash(_ s:UInt64,_ v:UInt64)->UInt64{var r=s;for i in 0..<8{r^=(v>>UInt64(i*8))&255;r&*=prime};return r}
private func hash(_ s:UInt64,_ v:Int32)->UInt64{hash(s,UInt64(bitPattern:Int64(v)))}
@main struct SM64WaterLevelSmoke{static func main(){
 let init0=SM64WaterLevelDiamondBehavior.update(.init(action:.initialize,timer:0,targetLevel:100,currentLevel:0,faceYaw:123,angleVelocityYaw:0,collidedWithMario:false,globalChanging:false))
 let init11=SM64WaterLevelDiamondBehavior.update(.init(action:.initialize,timer:11,targetLevel:100,currentLevel:0,faceYaw:123,angleVelocityYaw:0,collidedWithMario:false,globalChanging:false))
 let activate=SM64WaterLevelDiamondBehavior.update(.init(action:.idle,timer:4,targetLevel:100,currentLevel:0,faceYaw:0,angleVelocityYaw:0,collidedWithMario:true,globalChanging:false))
 let change=SM64WaterLevelDiamondBehavior.update(.init(action:.changing,timer:0,targetLevel:100,currentLevel:0,faceYaw:0,angleVelocityYaw:0,collidedWithMario:true,globalChanging:true))
 let complete=SM64WaterLevelDiamondBehavior.update(.init(action:.changing,timer:2,targetLevel:100,currentLevel:100,faceYaw:0,angleVelocityYaw:0x800,collidedWithMario:true,globalChanging:true))
 let released=SM64WaterLevelDiamondBehavior.update(.init(action:.idleSpinning,timer:3,targetLevel:100,currentLevel:100,faceYaw:0x1000,angleVelocityYaw:0x800,collidedWithMario:false,globalChanging:true))
 precondition(init0.faceYaw == 0 && init0.timer == 1 && init0.action == .initialize,"water diamond init")
 precondition(init11.action == .idle && init11.timer == 0,"water diamond init transition")
 precondition(activate.action == .changing && activate.timer == 0 && activate.globalChanging,"water diamond activation")
 precondition(change.currentLevel == 10 && change.sound == .trigger && change.angleVelocityYaw == 0x800 && change.rumble,"water diamond change step")
 precondition(complete.action == .idleSpinning && complete.timer == 0 && complete.currentLevel == 100,"water diamond complete")
 precondition(released.action == .idle && released.timer == 0 && !released.globalChanging,"water diamond release")
 let start=SM64ChangingWaterLevelBehavior.update(.init(action:0,timer:0,phase:0,globalLevel:100,regionsAvailable:true));let copy=SM64ChangingWaterLevelBehavior.update(.init(action:1,timer:5,phase:0,globalLevel:120,regionsAvailable:true));let wave=SM64ChangingWaterLevelBehavior.update(.init(action:1,timer:10,phase:0,globalLevel:100,regionsAvailable:true));precondition(start.action == 1 && start.timer == 0 && copy.regionLevel == 120 && wave.regionLevel == 100,"changing water initializer")
 var f=off;for o in [init0,init11,activate,change,complete,released]{f=hash(f,o.action.rawValue);f=hash(f,o.timer);f=hash(f,o.targetLevel);f=hash(f,o.currentLevel);f=hash(f,o.faceYaw);f=hash(f,o.angleVelocityYaw);f=hash(f,UInt64(o.globalChanging ? 1:0));f=hash(f,UInt64(o.sound.rawValue));f=hash(f,UInt64(o.rumble ? 1:0))};for o in [start,copy,wave]{f=hash(f,o.action);f=hash(f,o.timer);f=hash(f,o.phase);f=hash(f,o.globalLevel);f=hash(f,o.regionLevel)};print(String(format:"waterLevelFingerprint=0x%016llx",f));print("SM64 Modern water-level smoke passed")
}}
