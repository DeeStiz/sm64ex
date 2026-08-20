import Foundation

enum SM64AnimatedFloorSwitchSound: UInt8, Equatable, Sendable { case none = 0; case slow = 1; case fast = 2 }
struct SM64AnimatedFloorSwitchInput: Equatable, Sendable { let parentAction:Int32;let behaviorByte:Int32;let animationActive:Bool;let toggle:Int32;let remaining:Int32;let frame:Int32 }
struct SM64AnimatedFloorSwitchOutput: Equatable, Sendable { let animationActive:Bool;let toggle:Int32;let remaining:Int32;let frame:Int32;let modelFrame:Int32;let sound:SM64AnimatedFloorSwitchSound;let loadCollisionModel:Bool }
enum SM64AnimatedFloorSwitchBehavior {
 static let durations:[Int32]=[250,200,200]
 static func update(_ i:SM64AnimatedFloorSwitchInput)->SM64AnimatedFloorSwitchOutput{var active=i.animationActive;var toggle=i.toggle;var remaining=i.remaining;var frame=i.frame;var sound:SM64AnimatedFloorSwitchSound = .none;if active{if i.parentAction != 2{active=false};remaining=toggle != 0 ? (i.behaviorByte >= 0 && i.behaviorByte < 3 ? durations[Int(i.behaviorByte)] : 200):0}else if i.parentAction == 2{toggle ^= 1;active=true;remaining=toggle != 0 ? (i.behaviorByte >= 0 && i.behaviorByte < 3 ? durations[Int(i.behaviorByte)] : 200):0};if remaining != 0{sound=remaining < 60 ? .slow:.fast;remaining -= 1;if remaining == 0{toggle=0};if frame < 9{frame += 1}}else{frame -= 2;if frame < 0{frame=0;toggle=1}};return .init(animationActive:active,toggle:toggle,remaining:remaining,frame:frame,modelFrame:frame/2,sound:sound,loadCollisionModel:true)}
}
