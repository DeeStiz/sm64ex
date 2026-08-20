import Foundation

struct SM64CloudPartInput: Equatable, Sendable {
    let parentCenterX: Float
    let parentCenterY: Float
    let parentPositionZ: Float
    let parentFaceYaw: Int32
    let parentScale: Float
    let partIndex: Int32
    let globalFrame: UInt64
    let parentUnloading: Bool
}

struct SM64CloudPartOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let faceYaw: Int32
    let scaleX: Float
    let scaleY: Float
    let scaleZ: Float
    let shouldDeactivate: Bool
}

enum SM64CloudPartBehavior {
    private static let heights: [Float] = [11, 8, 12, 8, 9, 9]

    static func update(_ input: SM64CloudPartInput) -> SM64CloudPartOutput {
        let index = max(0, min(Int(input.partIndex), heights.count - 1))
        let size = (2.0 / 3.0) * input.parentScale
        let angle = input.parentFaceYaw &+ Int32((0x10000 / 5) * index)
        let phase = Int32(truncatingIfNeeded: input.globalFrame &* 0x800)
            &+ Int32(0x4000 * index)
        let localOffset = 2 * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: phase)) * size
        let radius = 25 * size
        let position = SM64ObjectVector3(
            x: input.parentCenterX + radius * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: angle)) + localOffset,
            y: input.parentCenterY + localOffset + size * heights[index],
            z: input.parentPositionZ + radius * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: angle)) + localOffset
        )
        let capFace = index == 5 && size > 2
        return SM64CloudPartOutput(
            position: position,
            faceYaw: input.parentFaceYaw,
            scaleX: size,
            scaleY: capFace ? 2 : size,
            scaleZ: size,
            shouldDeactivate: input.parentUnloading
        )
    }
}
