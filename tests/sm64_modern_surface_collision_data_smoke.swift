import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func append(_ value: Int16, to data: inout Data) {
    let raw = UInt16(bitPattern: value)
    data.append(UInt8(truncatingIfNeeded: raw))
    data.append(UInt8(truncatingIfNeeded: raw >> 8))
}

private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 {
        hash ^= (value >> UInt64(byte * 8)) & 0xff
        hash &*= fnvPrime
    }
    return hash
}

private func fixture() -> Data {
    var data = Data()
    append(0x40, to: &data)
    append(3, to: &data)
    append(-100, to: &data); append(0, to: &data); append(-100, to: &data)
    append(-100, to: &data); append(0, to: &data); append(100, to: &data)
    append(100, to: &data); append(0, to: &data); append(-100, to: &data)
    append(0, to: &data); append(1, to: &data)
    append(0, to: &data); append(1, to: &data); append(2, to: &data)
    append(0x44, to: &data); append(1, to: &data)
    append(0, to: &data); append(-50, to: &data); append(-50, to: &data)
    append(50, to: &data); append(50, to: &data); append(80, to: &data)
    append(0x42, to: &data)
    return data
}

@main
enum SM64ModernSurfaceCollisionDataSmoke {
    static func main() throws {
        let decoded = try SM64SurfaceCollisionDecoder().decode(data: fixture())
        require(decoded.surfaces.count == 1, "decoded triangle")
        require(decoded.surfaces[0].id == 0 && decoded.surfaces[0].normal.y == 1, "derived surface normal")
        require(decoded.surfaces[0].lowerY == -5 && decoded.surfaces[0].upperY == 5, "derived bounds")
        require(decoded.waterRegions == [SM64WaterRegion(value: 0, lowX: -50, lowZ: -50, highX: 50, highZ: 50, level: 80)], "decoded water region")
        let world = try SM64SurfaceCollisionWorld(staticSurfaces: decoded.surfaces, waterRegions: decoded.waterRegions)
        require(world.findFloor(x: 0, y: 100, z: 0).surfaceID == 0, "decoded surface query")
        require(world.findWaterLevel(x: 0, z: 0) == 80, "decoded environment query")

        var fingerprint = fnvOffset
        let surface = decoded.surfaces[0]
        fingerprint = hashU64(fingerprint, UInt64(surface.id))
        fingerprint = hashU64(fingerprint, UInt64(bitPattern: Int64(surface.type)))
        fingerprint = hashU64(fingerprint, UInt64(surface.flags))
        fingerprint = hashU64(fingerprint, UInt64(bitPattern: Int64(surface.lowerY)))
        fingerprint = hashU64(fingerprint, UInt64(bitPattern: Int64(surface.upperY)))
        fingerprint = hashU64(fingerprint, UInt64(surface.normal.x.bitPattern))
        fingerprint = hashU64(fingerprint, UInt64(surface.normal.y.bitPattern))
        fingerprint = hashU64(fingerprint, UInt64(surface.normal.z.bitPattern))
        fingerprint = hashU64(fingerprint, UInt64(surface.originOffset.bitPattern))
        for region in decoded.waterRegions {
            fingerprint = hashU64(fingerprint, UInt64(bitPattern: Int64(region.value)))
            fingerprint = hashU64(fingerprint, UInt64(region.level.bitPattern))
        }
        print(String(format: "surfaceCollisionDataFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern surface collision data smoke passed")
    }
}
