import Foundation
enum SM64BetaChestRole: UInt8, Equatable, Sendable { case bottom = 0; case lid = 1 }
enum SM64BetaChestAction: UInt8, Equatable, Sendable { case closed = 0; case opening = 1; case open = 2 }
struct SM64BetaChestOutput: Equatable, Sendable { let action: SM64BetaChestAction; let timer: Int32; let facePitch: Int32; let spawnBubble: Bool; let playSound: Bool }
enum SM64BetaChestBehavior { static func update(action:SM64BetaChestAction,timer:Int32,distanceToMario:Float,facePitch:Int32)->SM64BetaChestOutput{var a=action;var t=timer;var pitch=facePitch;var bubble=false;var sound=false;if action == .closed && distanceToMario < 300{a = .opening;t=0}else if action == .opening{if timer == 0{bubble=true;sound=true};pitch &-= 0x400;if pitch < -0x4000{a = .open}};if a == action{t &+= 1}else{t=0};return .init(action:a,timer:t,facePitch:pitch,spawnBubble:bubble,playSound:sound)} }
