import Foundation

enum SM64PlatformCollisionRegistryError: Error, Equatable, Sendable {
    case duplicateSurface(UInt32)
}

/// Owner-thread value registry for dynamic platform collision. Entries retain
/// first-seen object order so replacement does not reorder collision surfaces
/// relative to the legacy object-list pass; an object generation remains part
/// of the key so a stale object cannot remove a recycled slot's collision.
struct SM64PlatformCollisionRegistry: Equatable, Sendable {
    private var ownerOrder: [SM64ObjectID] = []
    private var surfacesByOwner: [SM64ObjectID: [SM64Surface]] = [:]

    var owners: [SM64ObjectID] { ownerOrder }

    var dynamicSurfaces: [SM64Surface] {
        ownerOrder.flatMap { surfacesByOwner[$0] ?? [] }
    }

    mutating func replace(owner: SM64ObjectID, surfaces: [SM64Surface]) throws {
        var usedIDs = Set<UInt32>()
        for (existingOwner, existingSurfaces) in surfacesByOwner where existingOwner != owner {
            _ = existingOwner
            for surface in existingSurfaces {
                usedIDs.insert(surface.id)
            }
        }
        for surface in surfaces {
            guard usedIDs.insert(surface.id).inserted else {
                throw SM64PlatformCollisionRegistryError.duplicateSurface(surface.id)
            }
        }

        if surfacesByOwner[owner] == nil {
            ownerOrder.append(owner)
        }
        surfacesByOwner[owner] = surfaces
    }

    @discardableResult
    mutating func remove(owner: SM64ObjectID) -> Bool {
        guard surfacesByOwner.removeValue(forKey: owner) != nil else { return false }
        ownerOrder.removeAll { $0 == owner }
        return true
    }

    mutating func apply(to world: inout SM64SurfaceCollisionWorld) throws {
        try world.replaceDynamicSurfaces(dynamicSurfaces)
    }
}
