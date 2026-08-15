import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func hf(_ h: UInt64, _ v: Float) -> UInt64 { h32(h, v.bitPattern) }
private func hi16(_ h: UInt64, _ v: Int16) -> UInt64 { h16(h, UInt16(bitPattern: v)) }
private func hi32(_ h: UInt64, _ v: Int32) -> UInt64 { h32(h, UInt32(bitPattern: v)) }

private func hash(_ h: UInt64, _ state: SM64CameraModeState) -> UInt64 {
    var x = h16(h, state.selectionFlags)
    x = h16(x, state.movementFlags); x = h16(x, state.soundFlags); x = h16(x, state.statusFlags)
    x = hi16(x, state.mode); x = hi16(x, state.defaultMode); x = hi16(x, state.lastMode); x = hi16(x, state.newMode)
    x = hi32(x, state.transitionFramesLeft); x = hi16(x, state.transitionMax); x = hi16(x, state.transitionFrame)
    x = hi16(x, state.cUpCameraPitch); x = hi16(x, state.modeOffsetYaw); x = hi16(x, state.lakituDistance)
    x = hi16(x, state.lakituPitch); x = hi16(x, state.areaYawChange); x = hf(x, state.panDistance)
    return hf(x, state.cannonYOffset)
}

private func hash(_ h: UInt64, _ result: SM64CameraSelectionResult) -> UInt64 {
    let x = hash(h, result.state)
    return hi16(x, result.selection.rawValue)
}

private func hash(_ h: UInt64, _ result: SM64CameraAngleResult) -> UInt64 {
    let x = hash(h, result.state)
    return hi16(x, result.angle.rawValue)
}

private func hash(_ h: UInt64, _ result: SM64CameraModeResult) -> UInt64 {
    let x = hash(h, result.state)
    return h8(x, result.changed ? 1 : 0)
}

@main
enum SM64ModernCameraModeStateSmoke {
    static func main() {
        let seeded = SM64CameraModeState(
            selectionFlags: 0,
            movementFlags: SM64CameraModeStateMachine.moveZoomedOut
                | SM64CameraModeStateMachine.moveRotateRight
                | SM64CameraModeStateMachine.moveEnteredRotateSurface,
            soundFlags: 0,
            statusFlags: 0,
            mode: SM64CameraMode.radial.rawValue,
            defaultMode: SM64CameraMode.close.rawValue,
            lastMode: SM64CameraMode.freeRoam.rawValue,
            newMode: SM64CameraMode.none.rawValue,
            transitionFramesLeft: 7,
            transitionMax: 8,
            transitionFrame: 3,
            cUpCameraPitch: 0x1234,
            modeOffsetYaw: -0x2345,
            lakituDistance: -300,
            lakituPitch: 0x123,
            areaYawChange: -0x456,
            panDistance: 12.5,
            cannonYOffset: -3.25
        )

        var fingerprint = fnvOffset
        let marioSelection = SM64CameraModeStateMachine.selectAlternateMode(
            SM64CameraSelection.mario.rawValue, state: seeded
        )
        precondition(marioSelection.selection == .mario)
        precondition(marioSelection.state.selectionFlags
            & SM64CameraModeStateMachine.modeMarioSelected != 0)
        fingerprint = hash(fingerprint, marioSelection)

        let marioAngle = SM64CameraModeStateMachine.setCameraAngle(
            SM64CameraAngle.mario.rawValue, state: marioSelection.state
        )
        precondition(marioAngle.angle == .mario)
        precondition(marioAngle.state.selectionFlags
            & SM64CameraModeStateMachine.modeLakituWasZoomedOut != 0)
        precondition(marioAngle.state.movementFlags
            & SM64CameraModeStateMachine.moveZoomedOut == 0)
        fingerprint = hash(fingerprint, marioAngle)

        let fixedSelection = SM64CameraModeStateMachine.selectAlternateMode(
            SM64CameraSelection.fixed.rawValue, state: marioAngle.state
        )
        precondition(fixedSelection.selection == .fixed)
        precondition(fixedSelection.state.selectionFlags
            & SM64CameraModeStateMachine.modeMarioSelected == 0)
        precondition(fixedSelection.state.selectionFlags
            & SM64CameraModeStateMachine.modeMarioActive == 0)
        precondition(fixedSelection.state.movementFlags
            & SM64CameraModeStateMachine.moveZoomedOut != 0)
        fingerprint = hash(fingerprint, fixedSelection)

        let transition = SM64CameraModeStateMachine.transitionToCameraMode(
            SM64CameraMode.freeRoam.rawValue, frames: 12,
            state: seeded
        )
        precondition(transition.changed)
        precondition(transition.state.mode == SM64CameraMode.freeRoam.rawValue)
        precondition(transition.state.lastMode == SM64CameraMode.radial.rawValue)
        precondition(transition.state.transitionFramesLeft == 12)
        precondition(transition.state.statusFlags
            & SM64CameraModeStateMachine.flagStartTransition != 0)
        precondition(transition.state.cUpCameraPitch == 0
            && transition.state.modeOffsetYaw == 0
            && transition.state.panDistance == 0)
        precondition(transition.state.movementFlags
            & (SM64CameraModeStateMachine.moveRestrict
                | SM64CameraModeStateMachine.moveRotate) == 0)
        fingerprint = hash(fingerprint, transition)

        let unchanged = SM64CameraModeStateMachine.transitionToCameraMode(
            seeded.mode, frames: 99, state: seeded
        )
        precondition(!unchanged.changed && unchanged.state == seeded)
        fingerprint = hash(fingerprint, unchanged)

        let postInit = SM64CameraModeState(
            selectionFlags: 0,
            movementFlags: SM64CameraModeStateMachine.moveRotateLeft
                | SM64CameraModeStateMachine.moveFixInPlace,
            statusFlags: SM64CameraModeStateMachine.flagFrameAfterCameraInit,
            mode: SM64CameraMode.cUp.rawValue,
            lastMode: SM64CameraMode.behindMario.rawValue,
            newMode: SM64CameraMode.cUp.rawValue,
            transitionFramesLeft: 4,
            cUpCameraPitch: 100,
            modeOffsetYaw: -200,
            lakituDistance: 300,
            lakituPitch: 20,
            areaYawChange: 4,
            panDistance: 8,
            cannonYOffset: 9
        )
        let previous = SM64CameraModeStateMachine.transitionToCameraMode(
            -1, frames: 20, state: postInit
        )
        precondition(previous.changed && previous.state.mode == SM64CameraMode.behindMario.rawValue)
        precondition(previous.state.cUpCameraPitch == 100 && previous.state.panDistance == 8)
        precondition(previous.state.transitionFramesLeft == 4)
        precondition(previous.state.movementFlags
            & (SM64CameraModeStateMachine.moveRestrict
                | SM64CameraModeStateMachine.moveRotate) == 0)
        fingerprint = hash(fingerprint, previous)

        let blockedTransition = SM64CameraModeStateMachine.transitionNextState(
            frames: 20, state: postInit
        )
        precondition(!blockedTransition.changed && blockedTransition.state == postInit)
        fingerprint = hash(fingerprint, blockedTransition)

        let marioHUD = SM64CameraModeStateMachine.hudStatus(
            cutsceneActive: false, rightTriggerDown: false, state: marioAngle.state
        )
        precondition(marioHUD == .mario)
        fingerprint = h16(fingerprint, marioHUD.rawValue)
        let fixedHUD = SM64CameraModeStateMachine.hudStatus(
            cutsceneActive: true, rightTriggerDown: false, state: seeded
        )
        precondition(fixedHUD == [.fixed, .cDown])
        fingerprint = h16(fingerprint, fixedHUD.rawValue)
        let zoomHUD = SM64CameraModeStateMachine.hudStatus(
            cutsceneActive: false, rightTriggerDown: false,
            state: seeded.with(movementFlags: seeded.movementFlags | 0x2000)
        )
        precondition(zoomHUD == [.lakitu, .cDown, .cUp])
        fingerprint = h16(fingerprint, zoomHUD.rawValue)

        print(String(format: "cameraModeStateFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern camera mode state smoke passed")
    }
}

private extension SM64CameraModeState {
    func with(movementFlags: UInt16) -> SM64CameraModeState {
        var copy = self
        copy.movementFlags = movementFlags
        return copy
    }
}
