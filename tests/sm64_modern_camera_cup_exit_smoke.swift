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

private func hash(_ h: UInt64, _ v: SM64CameraCUpExitResult) -> UInt64 {
    var x = h8(h, v.state.active ? 1 : 0)
    x = h8(x, v.state.startedExiting ? 1 : 0)
    x = hi16(x, v.state.pitch); x = hi16(x, v.state.modeOffsetYaw)
    x = hi16(x, v.state.headPitch); x = hi16(x, v.state.headYaw)
    x = hash(x, v.state.storedPosition); x = hf(x, v.state.storedFocusOffsetY)
    x = h8(x, v.usedSearch ? 1 : 0); x = h8(x, v.foundOpening ? 1 : 0)
    x = hi16(x, v.selectedYaw); x = hi16(x, v.transitionFrames)
    return h8(x, v.soundRequested ? 1 : 0)
}

@main
enum SM64ModernCameraCUpExitSmoke {
    static func main() throws {
        let world = try SM64SurfaceCollisionWorld(checkingForCamera: true)
        let state = SM64CameraCUpState(
            active: true, startedExiting: false, pitch: 0x100,
            modeOffsetYaw: -0x200, headPitch: 0xC0, headYaw: -0x180,
            storedPosition: .init(x: 4, y: 5, z: 6), storedFocusOffsetY: 125
        )
        let search = SM64CameraCUpExit.update(.init(
            state: state, lastMode: SM64CameraMode.close.rawValue,
            marioPosition: .init(x: -100, y: 20, z: -200),
            cameraPosition: .init(x: -100, y: 145, z: -100),
            cameraFocus: .init(x: -100, y: 145, z: -200),
            zoomDistance: 100, world: world
        ))!
        precondition(search.usedSearch && search.foundOpening
            && search.transitionFrames == 15 && search.soundRequested)
        precondition(search.state.startedExiting
            && search.state.storedPosition == .init(x: 0, y: 125, z: 100)
            && search.state.storedFocusOffsetY == 125)

        let direct = SM64CameraCUpExit.update(.init(
            state: state, lastMode: SM64CameraMode.fixed.rawValue,
            marioPosition: .zero,
            cameraPosition: .init(x: 0, y: 0, z: 1),
            cameraFocus: .init(x: 0, y: 1, z: 0),
            zoomDistance: 100, world: world
        ))!
        precondition(!direct.state.active && !direct.state.startedExiting
            && !direct.usedSearch && direct.transitionFrames == 0)

        let repeated = SM64CameraCUpExit.update(.init(
            state: search.state, lastMode: SM64CameraMode.close.rawValue,
            marioPosition: .zero, cameraPosition: .zero, cameraFocus: .zero,
            zoomDistance: 100, world: world
        ))!
        precondition(repeated == .init(
            state: search.state, usedSearch: false, foundOpening: false,
            selectedYaw: 0, transitionFrames: 0, soundRequested: false
        ))

        var fingerprint = hash(fnvOffset, search)
        fingerprint = hash(fingerprint, direct)
        fingerprint = hash(fingerprint, repeated)
        print(String(format: "cameraCUpExitFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern camera C-up exit smoke passed")
    }
}
