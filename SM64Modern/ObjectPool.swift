import Foundation

/// The object-list values are part of the retained C ABI's deterministic
/// ordering contract. Keep the raw values aligned with `enum ObjectList` in
/// `src/game/object_list_processor.h`.
enum SM64ObjectList: Int, CaseIterable, Sendable {
    case player = 0
    case unused1 = 1
    case destructive = 2
    case unused3 = 3
    case generalActor = 4
    case pushable = 5
    case level = 6
    case unused7 = 7
    case `default` = 8
    case surface = 9
    case polelike = 10
    case spawner = 11
    case unimportant = 12

    /// C's `sObjectListUpdateOrder`, including its deliberate omission of the
    /// unused list values.
    static let updateOrder: [SM64ObjectList] = [
        .spawner,
        .surface,
        .polelike,
        .player,
        .pushable,
        .generalActor,
        .destructive,
        .level,
        .default,
        .unimportant,
    ]
}

struct SM64ObjectID: Hashable, Sendable, CustomStringConvertible {
    let slot: UInt16
    let generation: UInt32

    init(slot: Int, generation: UInt32) {
        precondition(slot >= 0 && slot <= Int(UInt16.max))
        precondition(generation != 0)
        self.slot = UInt16(slot)
        self.generation = generation
    }

    /// Schema-4 uses C's slot identity, which is one-based and intentionally
    /// ignores the Swift generation used to reject stale references.
    var traceSubject: UInt32 {
        UInt32(slot) + 1
    }

    var description: String {
        "slot=\(slot),generation=\(generation)"
    }
}

struct SM64ObjectVector3: Equatable, Sendable {
    var x: Float
    var y: Float
    var z: Float

    static let zero = SM64ObjectVector3(x: 0, y: 0, z: 0)
    static let hiddenGfxOrigin = SM64ObjectVector3(x: -10_000, y: -10_000, z: -10_000)
}

struct SM64ObjectAngles: Equatable, Sendable {
    var pitch: Int32
    var yaw: Int32
    var roll: Int32

    static let zero = SM64ObjectAngles(pitch: 0, yaw: 0, roll: 0)
}

struct SM64ObjectRecord: Equatable, Sendable {
    let id: SM64ObjectID
    var objectList: SM64ObjectList
    var activeFlags: UInt16
    var parent: SM64ObjectID
    var previousObject: SM64ObjectID?
    var collidedObjects: [SM64ObjectID?]
    var platform: SM64ObjectID?
    var model: UInt32
    var behaviorIdentity: UInt64
    var currentBehaviorCommandIdentity: UInt64
    var behaviorStack: [UInt64]
    var objectFlags: UInt32
    var dialogResponse: Int16
    var dialogState: Int16
    var intangibleTimer: Int32
    var position: SM64ObjectVector3
    var velocity: SM64ObjectVector3
    var forwardVelocity: Float
    var moveAngles: SM64ObjectAngles
    var faceAngles: SM64ObjectAngles
    var angleVelocity: SM64ObjectAngles
    var gfxPosition: SM64ObjectVector3
    var graphFlags: UInt16
    var graphYOffset: Float
    var activeParticleFlags: UInt32
    var gravity: Float
    var floorHeight: Float
    var moveFlags: UInt32
    var animationState: Int32
    var heldState: UInt32
    var hitboxRadius: Float
    var hitboxHeight: Float
    var hurtboxRadius: Float
    var hurtboxHeight: Float
    var hitboxDownOffset: Float
    var wallHitboxRadius: Float
    var dragStrength: Float
    var interactionType: UInt32
    var interactionStatus: Int32
    var interactionSubtype: UInt32
    var parentRelativePosition: SM64ObjectVector3
    var behaviorParams: Int32
    var behaviorParams2ndByte: Int32
    var action: Int32
    var subAction: Int32
    var timer: Int32
    var previousAction: Int32
    var collisionDistance: Float
    var angleToMario: Int32
    var drawingDistance: Float
    var distanceToMario: Float
    var homePosition: SM64ObjectVector3
    var friction: Float
    var buoyancy: Float
    var soundStateID: Int32
    var opacity: Int32
    var damageOrCoinValue: Int32
    var health: Int32
    var numLootCoins: Int32
    var room: Int32
    var floorType: Int16
    var floorRoom: Int16
    var angleToHome: Int32
    var collisionDataIdentity: UInt64
    var respawnInfoType: UInt8
    var respawnInfoIdentity: UInt64
    var transform: [Float]
    var behaviorStackIndex: UInt32
    var behaviorDelayTimer: Int16

    fileprivate init(
        id: SM64ObjectID,
        objectList: SM64ObjectList,
        model: UInt32,
        behaviorIdentity: UInt64,
        parent: SM64ObjectID,
        drawingDistance: Float
    ) {
        self.id = id
        self.objectList = objectList
        self.activeFlags = SM64ObjectPool.activeFlagActive | SM64ObjectPool.activeFlagUnknown8
            | (objectList == .unimportant ? SM64ObjectPool.activeFlagUnimportant : 0)
        self.parent = parent
        self.previousObject = nil
        self.collidedObjects = Array(repeating: nil, count: 4)
        self.platform = nil
        self.model = model
        self.behaviorIdentity = behaviorIdentity
        self.currentBehaviorCommandIdentity = behaviorIdentity
        self.behaviorStack = Array(repeating: 0, count: 8)
        self.objectFlags = 0
        self.dialogResponse = 0
        self.dialogState = 0
        self.intangibleTimer = -1
        self.position = .zero
        self.velocity = .zero
        self.forwardVelocity = 0
        self.moveAngles = .zero
        self.faceAngles = .zero
        self.angleVelocity = .zero
        self.gfxPosition = .hiddenGfxOrigin
        self.graphFlags = 0
        self.graphYOffset = 0
        self.activeParticleFlags = 0
        self.gravity = 0
        self.floorHeight = 0
        self.moveFlags = 0
        self.animationState = 0
        self.heldState = 0
        self.hitboxRadius = 50
        self.hitboxHeight = 100
        self.hurtboxRadius = 0
        self.hurtboxHeight = 0
        self.hitboxDownOffset = 0
        self.wallHitboxRadius = 0
        self.dragStrength = 0
        self.interactionType = 0
        self.interactionStatus = 0
        self.interactionSubtype = 0
        self.parentRelativePosition = .zero
        self.behaviorParams = 0
        self.behaviorParams2ndByte = 0
        self.action = 0
        self.subAction = 0
        self.timer = 0
        self.previousAction = 0
        self.angleToMario = 0
        self.damageOrCoinValue = 0
        self.health = 2048
        self.collisionDistance = 1000
        self.drawingDistance = drawingDistance
        self.distanceToMario = 19_000
        self.homePosition = .zero
        self.friction = 0
        self.buoyancy = 0
        self.soundStateID = 0
        self.opacity = 0
        self.numLootCoins = 0
        self.room = -1
        self.floorType = 0
        self.floorRoom = 0
        self.angleToHome = 0
        self.collisionDataIdentity = 0
        self.respawnInfoType = 0
        self.respawnInfoIdentity = 0
        self.transform = [
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1,
        ]
        self.behaviorStackIndex = 0
        self.behaviorDelayTimer = 0
    }
}

enum SM64ObjectPoolError: Error, Equatable, Sendable, CustomStringConvertible {
    case invalidReference(SM64ObjectID)
    case poolExhausted(capacity: Int)

    var description: String {
        switch self {
        case let .invalidReference(id):
            "invalid object reference (\(id))"
        case let .poolExhausted(capacity):
            "object pool exhausted (capacity=\(capacity))"
        }
    }
}

/// Swift-owned, owner-thread-only object storage. It intentionally does not
/// conform to `Sendable`: the eventual behavior VM will mutate these records
/// only on the dedicated engine thread, while render/audio snapshots remain
/// value types. The retained C object graph is never exposed here.
final class SM64ObjectPool {
    static let defaultCapacity = 240

    // C object_constants.h values kept as UInt16 so traces cannot acquire a
    // platform-dependent signed representation.
    static let activeFlagActive: UInt16 = 1 << 0
    static let activeFlagUnimportant: UInt16 = 1 << 4
    static let activeFlagInitiatedTimeStop: UInt16 = 1 << 5
    static let activeFlagUnknown8: UInt16 = 1 << 8

    private struct Slot {
        var generation: UInt32
        var record: SM64ObjectRecord?
        var nextFree: Int?
    }

    let capacity: Int
    private var slots: [Slot]
    private var freeHead: Int?
    private var listMembers: [[SM64ObjectID]]
    private(set) var lastEvictedID: SM64ObjectID?

    init(capacity: Int = SM64ObjectPool.defaultCapacity) {
        precondition(capacity > 0 && capacity <= Int(UInt16.max) + 1)
        self.capacity = capacity
        self.slots = (0..<capacity).map { index in
            Slot(
                generation: 1,
                record: nil,
                nextFree: index + 1 < capacity ? index + 1 : nil
            )
        }
        self.freeHead = 0
        self.listMembers = Array(repeating: [], count: SM64ObjectList.allCases.count)
        self.lastEvictedID = nil
    }

    /// Mirrors `clear_objects`: all object lists are empty and the free list
    /// is rebuilt in ascending pool-slot order. Generations advance so a
    /// reference retained across an area reset cannot alias a new object.
    func reset() {
        for index in slots.indices {
            slots[index].generation = nextGeneration(slots[index].generation)
            slots[index].record = nil
            slots[index].nextFree = index + 1 < capacity ? index + 1 : nil
        }
        freeHead = 0
        listMembers = Array(repeating: [], count: SM64ObjectList.allCases.count)
        lastEvictedID = nil
    }

    func spawn(
        in objectList: SM64ObjectList,
        model: UInt32 = 0,
        behaviorIdentity: UInt64 = 0,
        parent: SM64ObjectID? = nil,
        drawingDistance: Float = 4_000
    ) throws -> SM64ObjectID {
        lastEvictedID = nil

        if let parent, record(for: parent) == nil {
            throw SM64ObjectPoolError.invalidReference(parent)
        }

        if freeHead == nil {
            guard let unimportant = listMembers[SM64ObjectList.unimportant.rawValue].first else {
                throw SM64ObjectPoolError.poolExhausted(capacity: capacity)
            }
            lastEvictedID = unimportant
            _ = despawn(unimportant)
        }

        guard let slotIndex = freeHead else {
            throw SM64ObjectPoolError.poolExhausted(capacity: capacity)
        }
        freeHead = slots[slotIndex].nextFree
        slots[slotIndex].nextFree = nil

        let id = SM64ObjectID(slot: slotIndex, generation: slots[slotIndex].generation)
        let record = SM64ObjectRecord(
            id: id,
            objectList: objectList,
            model: model,
            behaviorIdentity: behaviorIdentity,
            parent: parent ?? id,
            drawingDistance: drawingDistance
        )
        slots[slotIndex].record = record
        listMembers[objectList.rawValue].append(id)
        return id
    }

    func record(for id: SM64ObjectID) -> SM64ObjectRecord? {
        guard isValid(id), let record = slots[Int(id.slot)].record else { return nil }
        return record
    }

    @discardableResult
    func mutate(_ id: SM64ObjectID, _ mutation: (inout SM64ObjectRecord) -> Void) -> Bool {
        guard isValid(id), var record = slots[Int(id.slot)].record else { return false }
        mutation(&record)
        slots[Int(id.slot)].record = record
        return true
    }

    @discardableResult
    func setParent(_ child: SM64ObjectID, parent: SM64ObjectID) -> Bool {
        guard isValid(parent) else { return false }
        return mutate(child) { $0.parent = parent }
    }

    @discardableResult
    func setPreviousObject(_ object: SM64ObjectID, previous: SM64ObjectID?) -> Bool {
        if let previous, !isValid(previous) { return false }
        return mutate(object) { $0.previousObject = previous }
    }

    @discardableResult
    func setPlatform(_ object: SM64ObjectID, platform: SM64ObjectID?) -> Bool {
        if let platform, !isValid(platform) { return false }
        return mutate(object) { $0.platform = platform }
    }

    @discardableResult
    func setCollidedObject(
        _ object: SM64ObjectID,
        slot: Int,
        collidedObject: SM64ObjectID?
    ) -> Bool {
        guard (0..<4).contains(slot) else { return false }
        if let collidedObject, !isValid(collidedObject) { return false }
        return mutate(object) { $0.collidedObjects[slot] = collidedObject }
    }

    /// Matches `mark_obj_for_deletion`: the node stays in its list until the
    /// end-of-frame unload pass.
    @discardableResult
    func markForDeletion(_ id: SM64ObjectID) -> Bool {
        mutate(id) { $0.activeFlags = 0 }
    }

    /// Matches the C end-of-frame unload pass. Returns the IDs removed in the
    /// exact list order used by `sObjectListUpdateOrder`.
    @discardableResult
    func unloadDeactivated() -> [SM64ObjectID] {
        var removed: [SM64ObjectID] = []
        for objectList in SM64ObjectList.updateOrder {
            let ids = listMembers[objectList.rawValue]
            for id in ids {
                guard let record = record(for: id),
                      record.activeFlags & Self.activeFlagActive == 0 else { continue }
                if despawn(id) {
                    removed.append(id)
                }
            }
        }
        return removed
    }

    /// Immediate equivalent of `unload_object`, used for unimportant-object
    /// eviction and area teardown.
    @discardableResult
    func despawn(_ id: SM64ObjectID) -> Bool {
        guard isValid(id), let record = slots[Int(id.slot)].record else { return false }
        let listIndex = record.objectList.rawValue
        listMembers[listIndex].removeAll { $0 == id }
        slots[Int(id.slot)].record = nil
        slots[Int(id.slot)].generation = nextGeneration(slots[Int(id.slot)].generation)
        slots[Int(id.slot)].nextFree = freeHead
        freeHead = Int(id.slot)
        return true
    }

    func contains(_ id: SM64ObjectID) -> Bool {
        isValid(id)
    }

    func ids(in objectList: SM64ObjectList) -> [SM64ObjectID] {
        listMembers[objectList.rawValue]
    }

    /// Flatten active and deactivated nodes in the same order C updates them;
    /// behavior code decides whether a deactivated node is skipped.
    func updateIDs() -> [SM64ObjectID] {
        SM64ObjectList.updateOrder.flatMap { ids(in: $0) }
    }

    func allRecords() -> [SM64ObjectRecord] {
        SM64ObjectList.allCases.flatMap { ids(in: $0).compactMap(record(for:)) }
    }

    private func isValid(_ id: SM64ObjectID) -> Bool {
        let index = Int(id.slot)
        guard index < slots.count else { return false }
        guard slots[index].generation == id.generation else { return false }
        return slots[index].record?.id == id
    }

    private func nextGeneration(_ generation: UInt32) -> UInt32 {
        generation == UInt32.max ? 1 : generation + 1
    }
}
