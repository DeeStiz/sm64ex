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
    for byte in 0..<2 {
        hash ^= UInt64((value >> UInt16(byte * 8)) & 0xff)
        hash &*= fnvPrime
    }
    return hash
}

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for byte in 0..<4 {
        hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff)
        hash &*= fnvPrime
    }
    return hash
}

private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 {
        hash ^= (value >> UInt64(byte * 8)) & 0xff
        hash &*= fnvPrime
    }
    return hash
}

private func hashTick(_ initial: UInt64, _ result: SM64SwiftGameplayTickResult) -> UInt64 {
    var hash = hashU64(initial, result.frame.simulationTick)
    hash = hashU8(hash, result.frame.focused ? 1 : 0)
    hash = hashU8(hash, result.frame.demoEnded ? 1 : 0)
    hash = hashU8(hash, result.frame.demoTimer ?? 0xff)
    hash = hashU16(hash, result.frame.controller.buttonDown)
    hash = hashU16(hash, result.frame.controller.buttonPressed)
    hash = hashU16(hash, UInt16(bitPattern: result.frame.controller.rawStickX))
    hash = hashU16(hash, UInt16(bitPattern: result.frame.controller.rawStickY))
    hash = hashU16(hash, result.frame.camera.buttonDown)
    hash = hashU16(hash, result.frame.camera.buttonPressed)
    hash = hashU16(hash, result.frame.mario.input.rawValue)
    hash = hashU32(hash, result.frame.mario.intendedMagnitude.bitPattern)
    hash = hashU16(hash, UInt16(bitPattern: result.frame.mario.intendedYaw))
    hash = hashU16(hash, result.frame.geometry.flags.rawValue)
    hash = hashU8(hash, result.frame.rumbleRequest == nil ? 0 : 1)
    hash = hashU64(hash, result.state.simulationTick)
    hash = hashU64(hash, result.state.globalTimer)
    hash = hashU8(hash, result.state.demoState?.timer ?? 0xff)
    hash = hashU8(hash, result.state.framesSinceA)
    hash = hashU8(hash, result.state.framesSinceB)
    hash = hashU8(hash, result.rumble.command.rawValue)
    hash = hashU8(hash, result.rumble.advanced ? 1 : 0)
    hash = hashU16(hash, UInt16(bitPattern: result.rumble.current.duration))
    hash = hashU16(hash, UInt16(bitPattern: result.rumble.current.warmup))
    return hash
}

private func floor() -> SM64Surface {
    SM64Surface(
        id: 1,
        vertex1: SM64SurfaceVec3s(x: -100, y: 0, z: -100),
        vertex2: SM64SurfaceVec3s(x: -100, y: 0, z: 100),
        vertex3: SM64SurfaceVec3s(x: 100, y: 0, z: -100),
        normal: SM64SurfaceVec3f(x: 0, y: 1, z: 0),
        originOffset: 0
    )
}

@main
enum SM64ModernGameplayTickSmoke {
    static func main() throws {
        let world = try SM64SurfaceCollisionWorld(staticSurfaces: [floor()])
        var tick = SM64SwiftGameplayTick(initialFramesSinceA: 7, initialFramesSinceB: 9)
        tick.enqueueRumble(strength: 5, duration: 80)
        let common = SM64SwiftGameplayTickInput(
            sample: SM64ControllerRawSample(buttons: 0x8000, rawStickX: 38, extStickX: 20_000, extStickY: -20_000),
            focused: true,
            advanceLegacyDomain: false,
            rumbleRequest: SM64RumbleRequest(strength: 0.5, duration: 0.25),
            position: .zero,
            graphicsPosition: .hiddenGfxOrigin,
            world: world,
            faceYaw: 0x1111,
            cameraYaw: 0x0200
        )
        let first = tick.step(common)
        precondition(first.frame.simulationTick == 0 && first.state.simulationTick == 1, "first tick counter")
        precondition(first.state.globalTimer == 0 && !first.rumble.advanced, "held native step")
        precondition(first.frame.mario.input.contains(.aDown), "A held")

        let second = tick.step(SM64SwiftGameplayTickInput(
            sample: common.sample,
            focused: true,
            advanceLegacyDomain: true,
            rumbleRequest: common.rumbleRequest,
            position: common.position,
            graphicsPosition: common.graphicsPosition,
            world: world,
            faceYaw: common.faceYaw,
            cameraYaw: common.cameraYaw
        ))
        precondition(second.frame.simulationTick == 1 && second.state.globalTimer == 1, "logical counter")
        precondition(second.frame.controller.buttonPressed == 0x8000, "buffered A edge")
        precondition(second.rumble.command == .stop && second.rumble.advanced, "rumble queue shift")

        let third = tick.step(SM64SwiftGameplayTickInput(
            sample: SM64ControllerRawSample(),
            focused: true,
            advanceLegacyDomain: false,
            position: .zero,
            graphicsPosition: .hiddenGfxOrigin,
            world: world,
            faceYaw: common.faceYaw,
            cameraYaw: common.cameraYaw
        ))
        precondition(third.state.globalTimer == 1 && !third.rumble.advanced, "held step preserves legacy state")

        let fourth = tick.step(SM64SwiftGameplayTickInput(
            sample: SM64ControllerRawSample(),
            focused: true,
            advanceLegacyDomain: true,
            position: .zero,
            graphicsPosition: .hiddenGfxOrigin,
            world: world,
            faceYaw: common.faceYaw,
            cameraYaw: common.cameraYaw
        ))
        precondition(
            fourth.state.globalTimer == 2 && fourth.rumble.command == .stop,
            "rumble queue promotion timer=\(fourth.state.globalTimer) command=\(fourth.rumble.command.rawValue) duration=\(fourth.rumble.current.duration) warmup=\(fourth.rumble.current.warmup)"
        )

        tick.setDemoState(SM64DemoInputState(timer: 1, buttonMask: 0x90, rawStickX: 24, rawStickY: -12))
        let fifth = tick.step(SM64SwiftGameplayTickInput(
            sample: SM64ControllerRawSample(buttons: 0x1000),
            focused: true,
            advanceLegacyDomain: true,
            position: .zero,
            graphicsPosition: .hiddenGfxOrigin,
            world: world,
            faceYaw: common.faceYaw,
            cameraYaw: common.cameraYaw
        ))
        precondition(!fifth.frame.demoEnded && fifth.state.demoState?.timer == 0, "demo countdown")
        precondition(fifth.frame.controller.buttonDown == 0x9000, "demo overlay")
        precondition(fifth.rumble.command == .start && fifth.rumble.current.warmup == 3, "rumble warmup")

        let sixth = tick.step(SM64SwiftGameplayTickInput(
            sample: SM64ControllerRawSample(buttons: 0x1000),
            focused: true,
            advanceLegacyDomain: true,
            position: .zero,
            graphicsPosition: .hiddenGfxOrigin,
            world: world,
            faceYaw: common.faceYaw,
            cameraYaw: common.cameraYaw
        ))
        precondition(sixth.frame.demoEnded && sixth.frame.controller.buttonDown == 0x1080, "demo end sentinel")
        precondition(sixth.state.simulationTick == 6 && sixth.state.globalTimer == 4, "final tick state")

        var fingerprint = fnvOffset
        fingerprint = hashTick(fingerprint, first)
        fingerprint = hashTick(fingerprint, second)
        fingerprint = hashTick(fingerprint, third)
        fingerprint = hashTick(fingerprint, fourth)
        fingerprint = hashTick(fingerprint, fifth)
        fingerprint = hashTick(fingerprint, sixth)
        print(String(format: "gameplayTickFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern gameplay tick smoke passed")
    }
}
