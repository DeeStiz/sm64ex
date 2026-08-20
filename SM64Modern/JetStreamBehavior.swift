import Foundation

struct SM64JetStreamInput: Equatable, Sendable {
    let distanceToMario: Float
    let position: SM64ObjectVector3
    let timer: Int32
}

struct SM64JetStreamOutput: Equatable, Sendable {
    let particleCount: Int32
    let visible: Bool
    let playWaterSound: Bool
    let position: SM64ObjectVector3
    let timer: Int32
}

/// Value counterpart of `bhv_jet_stream_loop`.
enum SM64JetStreamBehavior {
    static func update(_ input: SM64JetStreamInput) -> SM64JetStreamOutput {
        let visible = input.distanceToMario < 5_000
        return .init(particleCount: visible ? 60 : 0, visible: visible, playWaterSound: true, position: input.position, timer: input.timer &+ 1)
    }
}
