import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func hf(_ h: UInt64, _ v: Float) -> UInt64 { h32(h, v.bitPattern) }
private func hi16(_ h: UInt64, _ v: Int16) -> UInt64 { h16(h, UInt16(bitPattern: v)) }

private func hash(_ h: UInt64, _ vector: SM64ObjectVector3) -> UInt64 {
    var x = hf(h, vector.x); x = hf(x, vector.y); return hf(x, vector.z)
}

private func hash(_ h: UInt64, _ offsets: SM64CameraHeightOffsets) -> UInt64 {
    let x = hf(h, offsets.position); return hf(x, offsets.focus)
}

private func hash(_ h: UInt64, _ placement: SM64CameraFocusPlacement) -> UInt64 {
    let x = hash(h, placement.focus); return hash(x, placement.position)
}

private func hash(_ h: UInt64, _ placement: SM64CameraRadialPlacement) -> UInt64 {
    var x = hash(h, placement.focus); x = hash(x, placement.position)
    x = hi16(x, placement.cameraYaw); x = hi16(x, placement.areaYaw); x = hi16(x, placement.pitch)
    return hash(x, placement.offsets)
}

@main
enum SM64ModernCameraGeometrySmoke {
    static func main() {
        var fingerprint = fnvOffset
        let standard = SM64CameraGeometry.calculateHeightOffsets(
            SM64CameraHeightInput(
                marioY: 50, floorHeight: 100, waterHeight: 250,
                isMetalWater: false, isOnPole: false,
                poleObjectY: nil, poleObjectHitboxHeight: nil
            )
        )!
        precondition(standard.position == 200 && standard.focus == 180)
        fingerprint = hash(fingerprint, standard)

        let metal = SM64CameraGeometry.calculateHeightOffsets(
            SM64CameraHeightInput(
                marioY: 50, floorHeight: 100, waterHeight: 250,
                isMetalWater: true, isOnPole: false,
                poleObjectY: nil, poleObjectHitboxHeight: nil
            )
        )!
        precondition(metal.position == 50 && metal.focus == 45)
        fingerprint = hash(fingerprint, metal)

        let pole = SM64CameraGeometry.calculateHeightOffsets(
            SM64CameraHeightInput(
                marioY: -100, floorHeight: 2000, waterHeight: nil,
                isMetalWater: false, isOnPole: true,
                poleObjectY: 0, poleObjectHitboxHeight: 100
            )
        )!
        precondition(pole.position == 1200 && pole.focus == 200)
        fingerprint = hash(fingerprint, pole)

        let direct = SM64CameraGeometry.focusOnMario(
            marioPosition: .init(x: -100, y: 20, z: -200),
            positionYOffset: 5, focusYOffset: 2, distance: 100,
            pitch: 0, yaw: 0
        )!
        precondition(direct.focus == .init(x: -100, y: 22, z: -200))
        precondition(direct.position == .init(x: -100, y: 25, z: -100))
        fingerprint = hash(fingerprint, direct)

        precondition(SM64CameraGeometry.lookDownSlopes(
            .init(marioY: 20, floorHeight: nil, floorType: 0, floorNormalZ: 0)
        ) == 0x05B0)
        precondition(SM64CameraGeometry.lookDownSlopes(
            .init(marioY: 20, floorHeight: 100, floorType: SM64CameraGeometry.wallMiscSurfaceType, floorNormalZ: 1)
        ) == 0x05B0)
        fingerprint = hi16(fingerprint, 0x05B0)
        fingerprint = hi16(fingerprint, 0x05B0)

        let radial = SM64CameraGeometry.updateRadial(
            .init(
                marioPosition: .init(x: -100, y: 50, z: -200),
                areaCenter: .init(x: -300, y: 0, z: -200),
                modeOffsetYaw: 0, lakituPitch: 0, lakituDistance: 0,
                height: .init(
                    marioY: 50, floorHeight: 50, waterHeight: nil,
                    isMetalWater: false, isOnPole: false,
                    poleObjectY: nil, poleObjectHitboxHeight: nil
                ),
                slope: .init(marioY: 50, floorHeight: nil, floorType: 0, floorNormalZ: 0)
            )
        )!
        precondition(radial.cameraYaw == 0x4000 && radial.areaYaw == 0x4000
            && radial.pitch == 0x05B0)
        fingerprint = hash(fingerprint, radial)

        precondition(SM64CameraGeometry.calculateHeightOffsets(
            .init(marioY: .nan, floorHeight: 0, waterHeight: nil,
                  isMetalWater: false, isOnPole: false,
                  poleObjectY: nil, poleObjectHitboxHeight: nil)
        ) == nil)
        print(String(format: "cameraGeometryFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern camera geometry smoke passed")
    }
}
