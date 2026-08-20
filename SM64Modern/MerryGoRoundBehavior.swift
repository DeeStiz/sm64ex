import Foundation

struct SM64MerryGoRoundInput: Equatable, Sendable { let timer: Int32; let yaw: Int32; let stopped: Bool; let marioOutsideLatched: Bool; let marioRoom: Int32 }
struct SM64MerryGoRoundOutput: Equatable, Sendable { let timer: Int32; let yaw: Int32; let angleVelocity: Int32; let marioOutsideLatched: Bool; let playHowlingWind: Bool; let playMusic: Bool; let stopMusic: Bool; let loadCollisionModel: Bool }
enum SM64MerryGoRoundBehavior {
    static func update(_ input: SM64MerryGoRoundInput) -> SM64MerryGoRoundOutput {
        var latched = input.marioOutsideLatched; var howling = false
        if !latched { if input.marioRoom == 1 { latched = true } }
        else { howling = true; if input.marioRoom != 1 && input.marioRoom != 2 { latched = false } }
        let rotating = !input.stopped
        return .init(timer: input.timer &+ 1, yaw: rotating ? input.yaw &+ 0x80 : input.yaw, angleVelocity: rotating ? 0x80 : 0, marioOutsideLatched: latched, playHowlingWind: howling, playMusic: rotating, stopMusic: input.stopped, loadCollisionModel: true)
    }
}
