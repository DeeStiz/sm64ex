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

private func surface(id: UInt32) -> SM64Surface {
    SM64Surface(
        id: id,
        vertex1: .init(x: 0, y: 0, z: 0),
        vertex2: .init(x: 100, y: 0, z: 0),
        vertex3: .init(x: 0, y: 0, z: 100),
        normal: .init(x: 0, y: 1, z: 0),
        originOffset: 0
    )
}

@main
enum SM64ModernPlatformCollisionRegistrySmoke {
    static func main() throws {
        let ownerA = SM64ObjectID(slot: 2, generation: 1)
        let ownerB = SM64ObjectID(slot: 7, generation: 1)
        let recycledA = SM64ObjectID(slot: 2, generation: 2)
        var registry = SM64PlatformCollisionRegistry()
        try registry.replace(owner: ownerA, surfaces: [surface(id: 10), surface(id: 11)])
        try registry.replace(owner: ownerB, surfaces: [surface(id: 20)])
        precondition(registry.owners == [ownerA, ownerB])
        precondition(registry.dynamicSurfaces.map(\.id) == [10, 11, 20])

        try registry.replace(owner: ownerA, surfaces: [surface(id: 12)])
        precondition(registry.owners == [ownerA, ownerB])
        precondition(registry.dynamicSurfaces.map(\.id) == [12, 20])
        precondition(!registry.remove(owner: recycledA))
        precondition(registry.remove(owner: ownerB))
        precondition(registry.dynamicSurfaces.map(\.id) == [12])

        do {
            try registry.replace(owner: ownerA, surfaces: [surface(id: 12), surface(id: 12)])
            preconditionFailure("duplicate dynamic surface must reject")
        } catch SM64PlatformCollisionRegistryError.duplicateSurface(12) {
            // Expected.
        }

        var world = try SM64SurfaceCollisionWorld(staticSurfaces: [surface(id: 99)])
        try registry.apply(to: &world)
        precondition(world.dynamicSurfaces.map(\.id) == [12])

        var fingerprint = fnvOffset
        for owner in registry.owners {
            fingerprint = hashU32(fingerprint, UInt32(owner.slot))
            fingerprint = hashU32(fingerprint, owner.generation)
        }
        for current in world.dynamicSurfaces {
            fingerprint = hashU32(fingerprint, current.id)
        }
        print(String(format: "platformCollisionRegistryFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern platform collision registry smoke passed")
    }
}
