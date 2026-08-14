import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU8(_ initial: UInt64, _ value: UInt8) -> UInt64 {
    var hash = initial
    hash ^= UInt64(value)
    hash &*= fnvPrime
    return hash
}

private func hashU16(_ initial: UInt64, _ value: UInt16) -> UInt64 {
    var hash = initial
    for byte in 0..<2 { hash ^= UInt64((value >> UInt16(byte * 8)) & 0xff); hash &*= fnvPrime }
    return hash
}

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for byte in 0..<4 { hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff); hash &*= fnvPrime }
    return hash
}

private func hashFrame(_ initial: UInt64, _ frame: SM64MarioInputFrame) -> UInt64 {
    var hash = hashU8(initial, frame.focused ? 1 : 0)
    hash = hashU8(hash, frame.demoEnded ? 1 : 0)
    hash = hashU8(hash, frame.demoTimer ?? 0xff)
    hash = hashU16(hash, frame.controller.buttonDown)
    hash = hashU16(hash, frame.controller.buttonPressed)
    hash = hashU16(hash, UInt16(bitPattern: frame.controller.rawStickX))
    hash = hashU16(hash, UInt16(bitPattern: frame.controller.rawStickY))
    hash = hashU16(hash, frame.mario.input.rawValue)
    hash = hashU32(hash, frame.mario.intendedMagnitude.bitPattern)
    hash = hashU16(hash, UInt16(bitPattern: frame.mario.intendedYaw))
    hash = hashU16(hash, frame.geometry.flags.rawValue)
    hash = hashU32(hash, frame.rumbleRequest == nil ? 0 : 1)
    return hash
}

private func floor() -> SM64Surface {
    SM64Surface(
        id: 1,
        vertex1: SM64SurfaceVec3s(x: -100, y: 0, z: -100),
        vertex2: SM64SurfaceVec3s(x: -100, y: 0, z: 100),
        vertex3: SM64SurfaceVec3s(x: 100, y: 0, z: -100),
        normal: SM64SurfaceVec3f(x: 0, y: 1, z: 0),
        originOffset: -0
    )
}

@main
enum SM64ModernMarioInputFrameSmoke {
    static func main() throws {
        let world = try SM64SurfaceCollisionWorld(staticSurfaces: [floor()])
        var normalizer = SM64ControllerInputNormalizer()
        let first = SM64MarioInputFrameComposer.update(
            normalizer: &normalizer,
            simulationTick: 11,
            sample: SM64ControllerRawSample(buttons: 0x8000, rawStickX: 38),
            focused: true,
            advanceLegacyDomain: true,
            rumbleRequest: SM64RumbleRequest(strength: 0.5, duration: 0.25),
            position: SM64ObjectVector3(x: 0, y: 0, z: 0),
            graphicsPosition: .hiddenGfxOrigin,
            world: world,
            squishTimer: 0,
            previousFramesSinceA: 7,
            previousFramesSinceB: 9,
            faceYaw: 0x1111,
            cameraYaw: 0x0200
        )
        precondition(first.frame.focused && !first.frame.demoEnded, "focused frame")
        precondition(first.frame.mario.input.contains(.aPressed), "A edge composed")
        precondition(first.frame.rumbleRequest != nil, "logical rumble admission")

        let second = SM64MarioInputFrameComposer.update(
            normalizer: &normalizer,
            simulationTick: 12,
            sample: SM64ControllerRawSample(buttons: 0x8000, rawStickX: 38),
            focused: false,
            advanceLegacyDomain: false,
            rumbleRequest: SM64RumbleRequest(strength: 1, duration: 1),
            position: SM64ObjectVector3(x: 0, y: 0, z: 0),
            graphicsPosition: .hiddenGfxOrigin,
            world: world,
            squishTimer: 0,
            previousFramesSinceA: first.frame.mario.framesSinceA,
            previousFramesSinceB: first.frame.mario.framesSinceB,
            faceYaw: 0x1111,
            cameraYaw: 0x0200
        )
        precondition(second.frame.controller.buttonDown == 0 && second.frame.controller.buttonPressed == 0, "focus clears input")
        precondition(second.frame.rumbleRequest == nil, "focus blocks rumble")

        let demo = SM64DemoInputState(timer: 2, buttonMask: 0x90, rawStickX: 24, rawStickY: -12)
        let third = SM64MarioInputFrameComposer.update(
            normalizer: &normalizer,
            simulationTick: 13,
            sample: SM64ControllerRawSample(buttons: 0x1000),
            focused: true,
            advanceLegacyDomain: false,
            demoState: demo,
            position: SM64ObjectVector3(x: 0, y: 0, z: 0),
            graphicsPosition: .hiddenGfxOrigin,
            world: world,
            squishTimer: 0,
            previousFramesSinceA: second.frame.mario.framesSinceA,
            previousFramesSinceB: second.frame.mario.framesSinceB,
            faceYaw: 0x1111,
            cameraYaw: 0x0200
        )
        precondition(third.frame.controller.buttonDown == 0x9000, "demo button mapping")
        precondition(third.frame.controller.rawStickX == 24 && third.frame.controller.rawStickY == -12, "demo stick mapping")
        precondition(third.nextDemoState?.timer == 2, "held demo timer")

        let fourth = SM64MarioInputFrameComposer.update(
            normalizer: &normalizer,
            simulationTick: 14,
            sample: SM64ControllerRawSample(buttons: 0x1000),
            focused: true,
            advanceLegacyDomain: true,
            demoState: third.nextDemoState,
            position: SM64ObjectVector3(x: 0, y: 0, z: 0),
            graphicsPosition: .hiddenGfxOrigin,
            world: world,
            squishTimer: 0,
            previousFramesSinceA: third.frame.mario.framesSinceA,
            previousFramesSinceB: third.frame.mario.framesSinceB,
            faceYaw: 0x1111,
            cameraYaw: 0x0200
        )
        precondition(fourth.nextDemoState?.timer == 1, "logical demo timer")

        let end = SM64MarioInputFrameComposer.update(
            normalizer: &normalizer,
            simulationTick: 15,
            sample: SM64ControllerRawSample(buttons: 0x1000),
            focused: true,
            advanceLegacyDomain: true,
            demoState: SM64DemoInputState(timer: 0, buttonMask: 0, rawStickX: 0, rawStickY: 0),
            position: SM64ObjectVector3(x: 0, y: 0, z: 0),
            graphicsPosition: .hiddenGfxOrigin,
            world: world,
            squishTimer: 0,
            previousFramesSinceA: fourth.frame.mario.framesSinceA,
            previousFramesSinceB: fourth.frame.mario.framesSinceB,
            faceYaw: 0x1111,
            cameraYaw: 0x0200
        )
        precondition(
            end.frame.demoEnded && end.frame.controller.buttonDown == 0x1080,
            "demo end sentinel demo=\(end.frame.demoEnded) buttons=0x\(String(end.frame.controller.buttonDown, radix: 16)) pressed=0x\(String(end.frame.controller.buttonPressed, radix: 16)) timer=\(String(describing: end.frame.demoTimer)) input=0x\(String(end.frame.mario.input.rawValue, radix: 16))"
        )
        var fingerprint = fnvOffset
        fingerprint = hashFrame(fingerprint, first.frame)
        fingerprint = hashFrame(fingerprint, second.frame)
        fingerprint = hashFrame(fingerprint, third.frame)
        fingerprint = hashFrame(fingerprint, fourth.frame)
        fingerprint = hashFrame(fingerprint, end.frame)
        print(String(format: "marioInputFrameFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario input frame smoke passed")
    }
}
