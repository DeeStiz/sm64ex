import Foundation

struct SM64TimeStopFlags: OptionSet, Equatable, Sendable {
    let rawValue: UInt32

    static let unknown0 = SM64TimeStopFlags(rawValue: 1 << 0)
    static let enabled = SM64TimeStopFlags(rawValue: 1 << 1)
    static let dialog = SM64TimeStopFlags(rawValue: 1 << 2)
    static let marioAndDoors = SM64TimeStopFlags(rawValue: 1 << 3)
    static let allObjects = SM64TimeStopFlags(rawValue: 1 << 4)
    static let marioOpenedDoor = SM64TimeStopFlags(rawValue: 1 << 5)
    static let active = SM64TimeStopFlags(rawValue: 1 << 6)
}

struct SM64EngineGlobals: Equatable, Sendable {
    var levelNumber: Int16 = 1
    var areaIndex: Int16 = 0
    var courseNumber: Int16 = 0
    var actNumber: Int16 = 0
    var timeStopState: SM64TimeStopFlags = []
    var objectCounter: UInt32 = 0
    var previousFrameObjectCount: Int16 = 0
    var marioObject: SM64ObjectID?
    var currentObject: SM64ObjectID?
    var frame: UInt64 = 0
    var resetEpoch: UInt64 = 1
}

struct SM64EngineStateSnapshot: Equatable, Sendable {
    let globals: SM64EngineGlobals
    let objects: [SM64ObjectRecord]
    let platformCollisionOwners: [SM64ObjectID]
    let platformCollisionSurfaceIDs: [SM64ObjectID: [UInt32]]
    let levelArena: SM64ArenaSnapshot
    let objectArena: SM64ArenaSnapshot
    let effectsArena: SM64ArenaSnapshot
}

/// Owner-thread state boundary for the Swift engine. This is intentionally a
/// reference type containing non-Sendable pools; only the immutable snapshot
/// crosses into renderer/audio or differential-trace consumers.
final class SM64SwiftEngineState {
    let objects: SM64ObjectPool
    let arenas: SM64EngineArenas
    private(set) var platformCollisionOwners: [SM64ObjectID] = []
    private(set) var platformCollisionSurfaceIDs: [SM64ObjectID: [UInt32]] = [:]
    private(set) var globals: SM64EngineGlobals

    init(
        objectCapacity: Int = SM64ObjectPool.defaultCapacity,
        arenaCapacities: SM64EngineArenaCapacities = .cDefaults
    ) {
        self.objects = SM64ObjectPool(capacity: objectCapacity)
        self.arenas = SM64EngineArenas(capacities: arenaCapacities)
        self.globals = SM64EngineGlobals()
    }

    func reset() {
        objects.reset()
        arenas.resetAll()
        platformCollisionOwners.removeAll(keepingCapacity: true)
        platformCollisionSurfaceIDs.removeAll(keepingCapacity: true)
        let nextEpoch = globals.resetEpoch == UInt64.max ? 1 : globals.resetEpoch + 1
        var resetGlobals = SM64EngineGlobals()
        resetGlobals.resetEpoch = nextEpoch
        globals = resetGlobals
    }

    func beginLevel(levelNumber: Int16, areaIndex: Int16 = 0) {
        reset()
        globals.levelNumber = levelNumber
        globals.areaIndex = areaIndex
    }

    func beginArea(_ areaIndex: Int16) {
        globals.areaIndex = areaIndex
        globals.timeStopState = []
        globals.currentObject = nil
    }

    @discardableResult
    func bindPlatformCollisionOwner(
        _ owner: SM64ObjectID,
        surfaceIDs: [UInt32] = []
    ) -> Bool {
        guard !platformCollisionOwners.contains(owner) else { return false }
        platformCollisionOwners.append(owner)
        platformCollisionSurfaceIDs[owner] = surfaceIDs
        return true
    }

    @discardableResult
    func updatePlatformCollisionOwner(
        _ owner: SM64ObjectID,
        surfaceIDs: [UInt32]
    ) -> Bool {
        guard platformCollisionOwners.contains(owner) else { return false }
        platformCollisionSurfaceIDs[owner] = surfaceIDs
        return true
    }

    @discardableResult
    func removePlatformCollisionOwner(_ owner: SM64ObjectID) -> Bool {
        guard let index = platformCollisionOwners.firstIndex(of: owner) else { return false }
        platformCollisionOwners.remove(at: index)
        platformCollisionSurfaceIDs.removeValue(forKey: owner)
        return true
    }

    func spawnObject(
        in objectList: SM64ObjectList,
        model: UInt32 = 0,
        behaviorIdentity: UInt64 = 0,
        parent: SM64ObjectID? = nil,
        isMario: Bool = false,
        drawingDistance: Float = 4_000
    ) throws -> SM64ObjectID {
        let id = try objects.spawn(
            in: objectList,
            model: model,
            behaviorIdentity: behaviorIdentity,
            parent: parent,
            drawingDistance: drawingDistance
        )
        if isMario {
            globals.marioObject = id
        }
        return id
    }

    @discardableResult
    func setCurrentObject(_ id: SM64ObjectID?) -> Bool {
        if let id, !objects.contains(id) { return false }
        globals.currentObject = id
        return true
    }

    @discardableResult
    func setMarioObject(_ id: SM64ObjectID?) -> Bool {
        if let id, !objects.contains(id) { return false }
        globals.marioObject = id
        return true
    }

    func addTimeStop(_ flags: SM64TimeStopFlags) {
        globals.timeStopState.formUnion(flags)
    }

    func removeTimeStop(_ flags: SM64TimeStopFlags) {
        globals.timeStopState.subtract(flags)
    }

    /// Applies the C boundary latch after a logical frame. Native 60 Hz
    /// simulation steps may be held between these logical updates, so the
    /// scheduler calls this only when the legacy domain is allowed to advance.
    func latchTimeStopAtLogicalBoundary() {
        if globals.timeStopState.contains(.enabled) {
            globals.timeStopState.insert(.active)
        } else {
            globals.timeStopState.remove(.active)
        }
    }

    func beginFrame() {
        globals.frame &+= 1
        globals.objectCounter = 0
    }

    func finishFrame(objectCount: UInt32) {
        globals.objectCounter = objectCount
        globals.previousFrameObjectCount = Int16(clamping: Int(objectCount))
    }

    func snapshot() -> SM64EngineStateSnapshot {
        SM64EngineStateSnapshot(
            globals: globals,
            objects: objects.allRecords(),
            platformCollisionOwners: platformCollisionOwners,
            platformCollisionSurfaceIDs: platformCollisionSurfaceIDs,
            levelArena: arenas.level.snapshot(),
            objectArena: arenas.object.snapshot(),
            effectsArena: arenas.effects.snapshot()
        )
    }
}
