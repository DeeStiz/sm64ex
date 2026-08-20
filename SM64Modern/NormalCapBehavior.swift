import Foundation

enum SM64NormalCapCourse: Int32, Equatable, Sendable { case other = 0; case ssl = 1; case sl = 2; case ttm = 3 }
struct SM64NormalCapInput: Equatable, Sendable { let action: Int32; let timer: Int32; let faceYaw: Int32; let facePitch: Int32; let forwardVelocity: Float; let verticalVelocity: Float; let capPhase: Int32; let floorLanded: Bool; let interacted: Bool; let deactivated: Bool; let course: SM64NormalCapCourse }
struct SM64NormalCapOutput: Equatable, Sendable { let action: Int32; let timer: Int32; let faceYaw: Int32; let facePitch: Int32; let verticalVelocity: Float; let capPhase: Int32; let gravity: Float; let friction: Float; let buoyancy: Float; let opacity: Int32; let tangible: Bool; let deactivated: Bool; let savePosition: Bool; let saveFlag: Int32; let clearGroundFlag: Bool }
enum SM64NormalCapBehavior {
    static func update(_ input: SM64NormalCapInput) -> SM64NormalCapOutput {
        var pitch = input.facePitch
        var verticalVelocity = input.verticalVelocity
        var phase = input.capPhase
        if input.action == 0 { pitch &+= Int32(input.forwardVelocity * 80) }
        if input.floorLanded, verticalVelocity != 0 { phase = 1; verticalVelocity = 0; pitch = 0 }
        if phase == 1 { phase = input.timer >= 8 ? 2 : phase }
        let saveFlag: Int32 = input.deactivated ? (input.course == .ssl ? 1 : input.course == .sl ? 2 : input.course == .ttm ? 3 : 1) : 0
        return .init(action: input.action, timer: input.timer &+ 1, faceYaw: input.action == 0 ? input.faceYaw &+ Int32(input.forwardVelocity * 128) : input.faceYaw, facePitch: pitch, verticalVelocity: verticalVelocity, capPhase: phase, gravity: 0.7, friction: 0.89, buoyancy: 0.9, opacity: 255, tangible: input.timer > 20, deactivated: input.deactivated || input.interacted, savePosition: input.forwardVelocity != 0, saveFlag: saveFlag, clearGroundFlag: input.interacted)
    }
}
