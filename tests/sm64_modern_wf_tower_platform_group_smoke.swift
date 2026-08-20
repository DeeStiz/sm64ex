import Foundation
private let fnvOffset:UInt64=1_469_598_103_934_665_603,fnvPrime:UInt64=1_099_511_628_211
private func hu(_ h:UInt64,_ v:UInt32)->UInt64{var x=h;for b in 0..<4{x^=UInt64((v>>UInt32(b*8))&0xff);x&*=fnvPrime};return x}
private func ap(_ o:SM64WfTowerPlatformGroupOutput,_ h:inout UInt64){h=hu(h,UInt32(bitPattern:o.action));h=hu(h,o.spawnChildren ? 1:0)}
@main enum SM64ModernWfTowerPlatformGroupSmoke{static func main(){
 let idle=SM64WfTowerPlatformGroupBehavior.update(SM64WfTowerPlatformGroupInput(action:0,marioY:0,homeY:2000))
 let approach=SM64WfTowerPlatformGroupBehavior.update(SM64WfTowerPlatformGroupInput(action:0,marioY:1100,homeY:2000))
 let spawn=SM64WfTowerPlatformGroupBehavior.update(SM64WfTowerPlatformGroupInput(action:1,marioY:1100,homeY:2000))
 let leave=SM64WfTowerPlatformGroupBehavior.update(SM64WfTowerPlatformGroupInput(action:2,marioY:900,homeY:2000))
 let reset=SM64WfTowerPlatformGroupBehavior.update(SM64WfTowerPlatformGroupInput(action:3,marioY:900,homeY:2000))
 precondition(idle.action == 0 && !idle.spawnChildren && approach.action == 1 && spawn.action == 2 && spawn.spawnChildren && leave.action == 3 && reset.action == 0)
 var h=fnvOffset;ap(idle,&h);ap(approach,&h);ap(spawn,&h);ap(leave,&h);ap(reset,&h);print(String(format:"wfTowerPlatformGroupFingerprint=0x%016llx",h));print("SM64 Modern WF tower platform group smoke passed")
}}
