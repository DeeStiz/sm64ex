import Foundation

enum SM64WaterLevelDiamondAction: Int32, Equatable, Sendable { case initialize = 0; case idle = 1; case changing = 2; case idleSpinning = 3 }
enum SM64WaterLevelSound: UInt8, Equatable, Sendable { case none = 0; case trigger = 1; case drain = 2 }
struct SM64WaterLevelDiamondInput: Equatable, Sendable {
    let action: SM64WaterLevelDiamondAction; let timer: Int32; let targetLevel: Int32; let currentLevel: Int32; let faceYaw: Int32; let angleVelocityYaw: Int32; let collidedWithMario: Bool; let globalChanging: Bool
}
struct SM64WaterLevelDiamondOutput: Equatable, Sendable {
    let action: SM64WaterLevelDiamondAction; let timer: Int32; let targetLevel: Int32; let currentLevel: Int32; let faceYaw: Int32; let angleVelocityYaw: Int32; let globalChanging: Bool; let sound: SM64WaterLevelSound; let rumble: Bool; let hitboxRadius: Float; let hitboxHeight: Float; let collisionDistance: Float
}
enum SM64WaterLevelDiamondBehavior {
    static func update(_ input: SM64WaterLevelDiamondInput) -> SM64WaterLevelDiamondOutput {
        var action=input.action; var timer=input.timer &+ 1; var target=input.targetLevel; var current=input.currentLevel; var yaw=input.faceYaw; var velocity=input.angleVelocityYaw; var changing=input.globalChanging; var sound:SM64WaterLevelSound = .none; var rumble=false
        if input.action == .initialize {
            yaw=0; target=input.targetLevel
            if input.timer > 10 { action = .idle; timer=0 }
        } else if input.action == .idle {
            if input.collidedWithMario && !input.globalChanging { action = .changing; timer=0; changing=true }
        } else if input.action == .changing {
            velocity=0
            if current < target { current=min(current+10,target) } else if current > target { current=max(current-10,target) }
            if current == target {
                if yaw == 0 { action = .idleSpinning; timer=0 }
                else { velocity=0x800 }
            } else {
                if input.timer == 0 { sound = .trigger } else { sound = .drain }
                velocity=0x800; rumble=true
            }
        } else if input.action == .idleSpinning && !input.collidedWithMario {
            changing = false; action = .idle; timer = 0; velocity = 0
        }
        yaw &+= velocity
        return .init(action:action,timer:timer,targetLevel:target,currentLevel:current,faceYaw:yaw,angleVelocityYaw:velocity,globalChanging:changing,sound:sound,rumble:rumble,hitboxRadius:70,hitboxHeight:30,collisionDistance:200)
    }
}

struct SM64ChangingWaterLevelInput: Equatable, Sendable { let action: Int32; let timer: Int32; let phase: Int32; let globalLevel: Int32; let regionsAvailable: Bool }
struct SM64ChangingWaterLevelOutput: Equatable, Sendable { let action: Int32; let timer: Int32; let phase: Int32; let globalLevel: Int32; let regionLevel: Int32 }
enum SM64ChangingWaterLevelBehavior {
    static func update(_ input: SM64ChangingWaterLevelInput) -> SM64ChangingWaterLevelOutput {
        var action=input.action; var timer=input.timer &+ 1; var phase=input.phase; var region=input.globalLevel
        if input.action == 0 {
            if input.regionsAvailable { action=1; timer=0 }
        } else if input.timer < 10 {
            region=input.globalLevel
        } else {
            let sine=Int32(SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: phase)))
            region=input.globalLevel + Int32((Int64(sine)*20)/32767)
            phase &+= 0x200
        }
        return .init(action:action,timer:timer,phase:phase,globalLevel:input.globalLevel,regionLevel:region)
    }
}
