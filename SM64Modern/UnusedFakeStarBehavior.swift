import Foundation

struct SM64UnusedFakeStarInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let facePitch: Int32
    let faceYaw: Int32
}

struct SM64UnusedFakeStarOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let facePitch: Int32
    let faceYaw: Int32
}

/// Value counterpart of the unused fake-star behavior script.
enum SM64UnusedFakeStarBehavior {
    static func update(_ input: SM64UnusedFakeStarInput) -> SM64UnusedFakeStarOutput {
        SM64UnusedFakeStarOutput(
            position: input.position,
            facePitch: input.facePitch &+ 0x100,
            faceYaw: input.faceYaw &+ 0x100
        )
    }
}
