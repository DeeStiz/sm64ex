import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for byte in 0..<4 {
        hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff)
        hash &*= fnvPrime
    }
    return hash
}

private func hashSurface(_ initial: UInt64, _ surface: SM64Surface) -> UInt64 {
    var hash = initial
    hash = hashU32(hash, surface.id)
    hash = hashU32(hash, UInt32(UInt16(bitPattern: surface.type)))
    hash = hashU32(hash, UInt32(UInt16(bitPattern: surface.force)))
    hash = hashU32(hash, UInt32(UInt8(bitPattern: surface.flags)))
    hash = hashU32(hash, UInt32(UInt8(bitPattern: surface.room)))
    hash = hashU32(hash, UInt32(UInt16(bitPattern: surface.lowerY)))
    hash = hashU32(hash, UInt32(UInt16(bitPattern: surface.upperY)))
    for vertex in [surface.vertex1, surface.vertex2, surface.vertex3] {
        hash = hashU32(hash, UInt32(UInt16(bitPattern: vertex.x)))
        hash = hashU32(hash, UInt32(UInt16(bitPattern: vertex.y)))
        hash = hashU32(hash, UInt32(UInt16(bitPattern: vertex.z)))
    }
    hash = hashU32(hash, surface.normal.x.bitPattern)
    hash = hashU32(hash, surface.normal.y.bitPattern)
    hash = hashU32(hash, surface.normal.z.bitPattern)
    hash = hashU32(hash, surface.originOffset.bitPattern)
    return hash
}

private let collisionWords: [Int16] = [
    0x0040, 4,
    0, 0, 0,
    100, 0, 0,
    0, 0, 100,
    0, 100, 0,
    0x0000, 1, 0, 2, 1,
    0x002C, 1, 0, 2, 3, 7,
    0x0041, 0x0042,
]

@main
enum SM64ModernCollisionMeshSmoke {
    static func main() throws {
        let state = SM64SwiftEngineState(objectCapacity: 4)
        let owner = try state.spawnObject(in: .surface, behaviorIdentity: 0x19)
        _ = state.objects.mutate(owner) {
            $0.position = SM64ObjectVector3(x: 10, y: 20, z: 30)
            $0.scale = SM64ObjectVector3(x: 2, y: 1, z: 1)
            $0.objectFlags = SM64ObjectScheduler.objectFlagBuildTransform
        }
        let object = state.objects.record(for: owner)!
        let runtime = try SM64PlatformCollisionRuntime()
        let surfaces = try runtime.bind(
            owner: owner,
            object: object,
            collisionWords: collisionWords,
            surfaceIDBase: 0x100,
            state: state
        )
        precondition(surfaces.count == 2)
        precondition(surfaces.map(\.id) == [0x100, 0x101])
        precondition(surfaces[0].vertex1 == .init(x: 10, y: 20, z: 30))
        precondition(surfaces[0].vertex2 == .init(x: 10, y: 20, z: 130))
        precondition(surfaces[0].vertex3 == .init(x: 210, y: 20, z: 30))
        guard abs(surfaces[0].normal.y - 1) < 0.0001 && surfaces[0].force == 0 else {
            fatalError("surface0 normal=\(surfaces[0].normal) force=\(surfaces[0].force)")
        }
        precondition(surfaces[1].force == 7)
        precondition(surfaces.allSatisfy { $0.flags & SM64CollisionMeshDecoder.dynamicFlag != 0 })
        precondition(runtime.world.dynamicSurfaces == surfaces)
        precondition(state.platformCollisionSurfaceIDs[owner] == [0x100, 0x101])
        precondition(runtime.world.findFloor(x: 50, y: 100, z: 50).surfaceID == 0x100)

        do {
            _ = try runtime.bind(
                owner: owner,
                object: object,
                collisionWords: Array(collisionWords.dropLast(2)),
                surfaceIDBase: 0x200,
                state: state
            )
            preconditionFailure("truncated collision data must fail")
        } catch SM64PlatformCollisionRouteError.collision(.noTerminator) {
            // Expected; the old binding must remain live.
        }
        precondition(runtime.world.dynamicSurfaces == surfaces)
        precondition(state.platformCollisionSurfaceIDs[owner] == [0x100, 0x101])
        let removed = try runtime.remove(owner: owner, state: state)
        precondition(removed)
        precondition(runtime.world.dynamicSurfaces.isEmpty)
        precondition(state.platformCollisionOwners.isEmpty)

        var fingerprint = fnvOffset
        for surface in surfaces { fingerprint = hashSurface(fingerprint, surface) }
        print(String(format: "collisionMeshFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern collision mesh smoke passed")
    }
}
