import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 {
    var x = h
    x ^= UInt64(v)
    x &*= fnvPrime
    return x
}

private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 {
    var x = h
    for index in 0..<2 {
        x ^= UInt64((v >> UInt16(index * 8)) & 0xff)
        x &*= fnvPrime
    }
    return x
}

private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 {
    var x = h
    for index in 0..<4 {
        x ^= UInt64((v >> UInt32(index * 8)) & 0xff)
        x &*= fnvPrime
    }
    return x
}

private func hf(_ h: UInt64, _ v: Float) -> UInt64 { h32(h, v.bitPattern) }
private func hi16(_ h: UInt64, _ v: Int16) -> UInt64 { h16(h, UInt16(bitPattern: v)) }

private func hash(
    _ h: UInt64,
    _ descriptor: SM64CameraModeCallbackDescriptor
) -> UInt64 {
    var x = hi16(h, descriptor.rawMode)
    x = h8(x, descriptor.callback.rawValue)
    x = h8(x, descriptor.pureGeometryImplemented ? 1 : 0)
    x = h8(x, descriptor.ownerThreadRequired ? 1 : 0)
    x = h8(x, descriptor.outputsSwapped ? 1 : 0)
    x = hf(x, descriptor.baseDistance)
    x = hf(x, descriptor.positionYOffset)
    x = hf(x, descriptor.focusYOffset)
    x = hi16(x, descriptor.basePitch)
    x = h8(x, descriptor.returnsMarioYaw ? 1 : 0)
    return h8(x, descriptor.pansAhead ? 1 : 0)
}

private func hash(
    _ h: UInt64,
    _ result: SM64CameraCallbackResult
) -> UInt64 {
    var x = hi16(h, result.cameraYaw)
    x = hi16(x, result.returnedYaw)
    x = hi16(x, result.areaYaw)
    x = hi16(x, result.pitch)
    x = hf(x, result.distance)
    x = h8(x, result.outputsSwapped ? 1 : 0)
    return h8(x, result.panAhead ? 1 : 0)
}

@main
enum SM64ModernCameraModeCallbacksSmoke {
    static func main() {
        precondition(SM64CameraModeCallbacks.descriptors.count == 19)
        precondition(SM64CameraModeCallbacks.descriptor(for: 1)?.callback == .radial)
        precondition(SM64CameraModeCallbacks.descriptor(for: 6)?.pureGeometryImplemented == true)
        precondition(SM64CameraModeCallbacks.descriptor(for: 10)?.outputsSwapped == true)
        precondition(SM64CameraModeCallbacks.descriptor(for: 12)?.pureGeometryImplemented == false)

        var fingerprint = fnvOffset
        for descriptor in SM64CameraModeCallbacks.descriptors {
            fingerprint = hash(fingerprint, descriptor)
        }

        let radial = SM64CameraModeCallbacks.evaluate(.init(
            mode: 1,
            marioPosition: .init(x: 100, y: 0, z: 0),
            areaCenter: .init(x: 0, y: 0, z: 0),
            modeOffsetYaw: 0x0100,
            lakituDistance: 25
        ))!
        precondition(radial.cameraYaw == 0x4100 && radial.areaYaw == 0x4000
            && radial.returnedYaw == 0x4100 && radial.pitch == 0x05B0
            && radial.distance == 1025 && !radial.outputsSwapped
            && radial.panAhead && radial.focus.y == 125)
        fingerprint = hash(fingerprint, radial)

        let outward = SM64CameraModeCallbacks.evaluate(.init(
            mode: 2,
            marioPosition: .init(x: 100, y: 0, z: 0),
            modeOffsetYaw: 0x0100,
            lakituDistance: 25
        ))!
        precondition(outward.cameraYaw == Int16(bitPattern: 0xC100)
            && outward.areaYaw == 0x4000 && outward.returnedYaw == Int16(bitPattern: 0xC100)
            && outward.distance == 1025 && outward.panAhead)
        fingerprint = hash(fingerprint, outward)

        let eight = SM64CameraModeCallbacks.evaluate(.init(
            mode: 14,
            marioPosition: .init(x: 100, y: 0, z: 0),
            lakituDistance: 5,
            eightDirectionBaseYaw: 0x2000,
            eightDirectionYawOffset: 0x1000
        ))!
        precondition(eight.cameraYaw == 0x3000 && eight.areaYaw == 0x3000
            && eight.distance == 1005 && eight.panAhead)
        fingerprint = hash(fingerprint, eight)

        let mario = SM64CameraModeCallbacks.evaluate(.init(
            mode: 4,
            marioPosition: .init(x: 100, y: 0, z: 0),
            faceYaw: 0x6000,
            zoomDistance: 700
        ))!
        precondition(mario.cameraYaw == Int16(bitPattern: 0xE000)
            && mario.returnedYaw == 0x6000 && mario.distance == 700
            && mario.pitch == 0x05B0)
        fingerprint = hash(fingerprint, mario)

        let cUp = SM64CameraModeCallbacks.evaluate(.init(
            mode: 6,
            marioPosition: .init(x: 100, y: 0, z: 0),
            faceYaw: 0x6000,
            facePitch: 0x1000,
            modeOffsetYaw: 0x0100,
            lakituPitch: 0x0200
        ))!
        precondition(cUp.cameraYaw == Int16(bitPattern: 0xE100)
            && cUp.returnedYaw == 0x6000 && cUp.pitch == 0x1000
            && cUp.distance == 250 && !cUp.outputsSwapped
            && !cUp.panAhead)
        fingerprint = hash(fingerprint, cUp)

        let slide = SM64CameraModeCallbacks.evaluate(.init(
            mode: 9,
            marioPosition: .init(x: 100, y: 0, z: 0),
            faceYaw: 0x5000,
            modeOffsetYaw: 0x0100
        ))!
        precondition(slide.cameraYaw == Int16(bitPattern: 0xD100)
            && slide.returnedYaw == 0x5000 && slide.pitch == 0x1555
            && slide.distance == 800)
        fingerprint = hash(fingerprint, slide)

        let cannon = SM64CameraModeCallbacks.evaluate(.init(
            mode: 10,
            marioPosition: .init(x: 100, y: 0, z: 0),
            faceYaw: 0x6000,
            facePitch: -0x1000,
            cannonYOffset: 25
        ))!
        precondition(cannon.cameraYaw == 0x6000 && cannon.returnedYaw == 0x6000
            && cannon.pitch == -0x1000 && cannon.distance == 800
            && cannon.outputsSwapped && cannon.focus.y == 125
            && cannon.position.y.isFinite && cannon.position.y < 150)
        fingerprint = hash(fingerprint, cannon)

        precondition(SM64CameraModeCallbacks.evaluate(.init(
            mode: 12, marioPosition: .init(x: 0, y: 0, z: 0)
        )) == nil)
        precondition(SM64CameraModeCallbacks.evaluate(.init(
            mode: 1, marioPosition: .init(x: .nan, y: 0, z: 0)
        )) == nil)

        print(String(format: "cameraModeCallbacksFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern camera mode callback smoke passed")
    }
}
