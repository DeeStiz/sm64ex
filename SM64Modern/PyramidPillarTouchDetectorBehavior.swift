import Foundation

struct SM64PyramidPillarTouchDetectorInput: Equatable, Sendable {
    let parentTouchedCount: Int32
    let collidedWithMario: Bool
}

struct SM64PyramidPillarTouchDetectorOutput: Equatable, Sendable {
    let parentTouchedCount: Int32
    let tangible: Bool
    let deactivated: Bool
}

enum SM64PyramidPillarTouchDetectorBehavior {
    static func update(_ input: SM64PyramidPillarTouchDetectorInput) -> SM64PyramidPillarTouchDetectorOutput {
        guard input.collidedWithMario else { return .init(parentTouchedCount: input.parentTouchedCount, tangible: true, deactivated: false) }
        return .init(parentTouchedCount: input.parentTouchedCount &+ 1, tangible: true, deactivated: true)
    }
}
