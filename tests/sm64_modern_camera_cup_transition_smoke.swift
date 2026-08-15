import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func hf(_ h: UInt64, _ v: Float) -> UInt64 { h32(h, v.bitPattern) }
private func hi16(_ h: UInt64, _ v: Int16) -> UInt64 { h16(h, UInt16(bitPattern: v)) }
private func hash(_ h: UInt64, _ v: SM64ObjectVector3) -> UInt64 {
    var x = hf(h, v.x); x = hf(x, v.y); return hf(x, v.z)
}
private func hash(_ h: UInt64, _ v: SM64CameraCUpTransitionResult) -> UInt64 {
    var x = hash(h, v.focus); x = hash(x, v.position); x = hf(x, v.distance)
    x = hi16(x, v.pitch); x = hi16(x, v.yaw); x = hi16(x, v.nextFrame)
    x = h8(x, v.finished ? 1 : 0); x = hi16(x, v.headPitch)
    return hi16(x, v.headYaw)
}

@main
enum SM64ModernCameraCUpTransitionSmoke {
    static func main() {
        let start = SM64CameraTransitionPoint(
            focus: .zero, position: .init(x: 0, y: 0, z: 100),
            distance: 100, pitch: 0, yaw: 0
        )
        let end = SM64CameraTransitionPoint(
            focus: .init(x: 4, y: 8, z: 12),
            position: .init(x: 0, y: 0, z: 200),
            distance: 200, pitch: 0, yaw: 0
        )
        let input = SM64CameraCUpTransitionInput(
            start: start, end: end, frame: 2, max: 4,
            marioPosition: .init(x: 10, y: 20, z: 30)
        )
        let middle = SM64CameraCUpTransition.update(input)!
        precondition(middle.focus == .init(x: 12, y: 24, z: 36)
            && middle.position == .init(x: 12, y: 24, z: 186)
            && middle.distance == 150 && middle.pitch == 0
            && middle.yaw == 0 && middle.nextFrame == 3
            && !middle.finished && middle.headPitch == 0 && middle.headYaw == 0)

        let final = SM64CameraCUpTransition.update(.init(
            start: start, end: end, frame: 3, max: 4,
            marioPosition: .init(x: 10, y: 20, z: 30)
        ))!
        precondition(final.nextFrame == 4 && final.finished
            && final.focus == .init(x: 13, y: 26, z: 39)
            && final.position == .init(x: 13, y: 26, z: 214))
        precondition(SM64CameraCUpTransition.update(.init(
            start: start, end: end, frame: 0, max: 0,
            marioPosition: .zero
        )) == nil)

        var fingerprint = hash(fnvOffset, middle)
        fingerprint = hash(fingerprint, final)
        print(String(format: "cameraCUpTransitionFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern camera C-up transition smoke passed")
    }
}
