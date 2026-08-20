import Foundation

private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211

private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 {
    var result = seed
    for index in 0..<8 {
        result ^= (value >> UInt64(index * 8)) & 255
        result &*= prime
    }
    return result
}

private func row(_ output: SM64JrbSlidingBoxOutput) -> [UInt64] {
    [UInt64(output.position.x.bitPattern), UInt64(output.position.y.bitPattern), UInt64(output.position.z.bitPattern), UInt64(bitPattern: Int64(output.phase)), output.tangible ? 1 : 0]
}

@main
struct SM64JrbSlidingBoxSmoke {
    static func main() {
        let rest = SM64JrbSlidingBoxBehavior.update(.init(parentPosition: .init(x: 10, y: 20, z: 30), parentAngles: .zero, relativePosition: .init(x: 1, y: 2, z: 3), phase: 0, y: 0))
        let slide = SM64JrbSlidingBoxBehavior.update(.init(parentPosition: .init(x: 10, y: 20, z: 30), parentAngles: .zero, relativePosition: .init(x: 1, y: 2, z: 3), phase: 0x4000, y: 0))
        precondition(rest.position == .init(x: 11, y: 22, z: 33) && rest.phase == 0x100)
        precondition(slide.position.z == 53 && slide.playSlideSound)
        var fingerprint = offset
        for output in [rest, slide] {
            for value in row(output) { fingerprint = hash(fingerprint, value) }
        }
        print(String(format: "jrbSlidingBoxFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern JRB sliding box smoke passed")
    }
}
