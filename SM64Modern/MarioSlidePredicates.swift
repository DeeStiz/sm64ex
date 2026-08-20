import Foundation

struct SM64MarioSlidePredicatesInput: Equatable, Sendable {
    let input: SM64MarioInputFlags
    let terrainIsSlide: Bool
    let forwardVelocity: Float
    let facingDownhill: Bool
    let intendedYaw: Int16
    let faceYaw: Int16
}

struct SM64MarioSlidePredicatesResult: Equatable, Sendable {
    let shouldBeginSliding: Bool
    let analogStickHeldBack: Bool
}

/// Value counterpart of `should_begin_sliding` and
/// `analog_stick_held_back`.
enum SM64MarioSlidePredicates {
    static func update(
        _ input: SM64MarioSlidePredicatesInput
    ) -> SM64MarioSlidePredicatesResult? {
        guard input.forwardVelocity.isFinite else { return nil }
        let shouldBeginSliding = input.input.contains(.aboveSlide)
            && (input.terrainIsSlide || input.forwardVelocity <= -1 || input.facingDownhill)
        let intendedDelta = Int16(
            truncatingIfNeeded: Int32(input.intendedYaw) - Int32(input.faceYaw)
        )
        return SM64MarioSlidePredicatesResult(
            shouldBeginSliding: shouldBeginSliding,
            analogStickHeldBack: intendedDelta < -0x471C || intendedDelta > 0x471C
        )
    }
}
