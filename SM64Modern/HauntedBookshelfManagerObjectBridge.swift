import Foundation

struct SM64HauntedBookshelfManagerObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64HauntedBookshelfManagerOutput
    let spawnedSwitches: [SM64ObjectID]
}

final class SM64HauntedBookshelfManagerObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_68626D
    private let bookSwitchBridge: SM64BookSwitchObjectBridge
    private let bookshelfBridge: SM64HauntedBookshelfObjectBridge
    private struct State { var sequence: Int32; var enabled: Bool; var nearAndFacingMario: Bool; var shelf: SM64ObjectID?; var inDifferentRoom: Bool }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64HauntedBookshelfManagerObjectEffectRecord] = []

    init(bookSwitchBridge: SM64BookSwitchObjectBridge, bookshelfBridge: SM64HauntedBookshelfObjectBridge) {
        self.bookSwitchBridge = bookSwitchBridge
        self.bookshelfBridge = bookshelfBridge
    }

    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnManager(in engineState: SM64SwiftEngineState, shelf: SM64ObjectID? = nil, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .generalActor, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, shelf: shelf, position: position, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned haunted bookshelf manager could not attach") }
        return id
    }

    @discardableResult
    private func attach(_ id: SM64ObjectID, shelf: SM64ObjectID?, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(sequence: 0, enabled: false, nearAndFacingMario: false, shelf: shelf, inDifferentRoom: false)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }

    @discardableResult
    func setInput(nearAndFacingMario: Bool? = nil, sequence: Int32? = nil, inDifferentRoom: Bool? = nil, for id: SM64ObjectID) -> Bool {
        guard var state = states[id] else { return false }
        if let nearAndFacingMario { state.nearAndFacingMario = nearAndFacingMario }
        if let sequence { state.sequence = sequence }
        if let inDifferentRoom { state.inDifferentRoom = inDifferentRoom }
        states[id] = state
        return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let shelfPositionX = state.shelf.flatMap { engineState.objects.record(for: $0)?.position.x } ?? record.position.x
        let output = SM64HauntedBookshelfManagerBehavior.update(.init(action: record.action, timer: record.timer, sequence: state.sequence, enabled: state.enabled, nearAndFacingMario: state.nearAndFacingMario, shelfPresent: state.shelf.flatMap { engineState.objects.record(for: $0) != nil } ?? false, shelfPositionX: shelfPositionX, positionX: record.position.x, inDifferentRoom: state.inDifferentRoom))
        var switches: [SM64ObjectID] = []
        if output.spawnSwitches {
            let offsets: [(Float, Float, Int32)] = [(52, 150, 0), (135, 3, 1), (-75, 78, 2)]
            for (x, z, parameter) in offsets {
                if let child = try? bookSwitchBridge.spawnSwitch(in: engineState, parent: id, position: .init(x: record.position.x + x, y: record.position.y, z: record.position.z + z), behaviorParam: parameter) { switches.append(child) }
            }
        }
        if output.openShelf, let shelf = state.shelf { _ = bookshelfBridge.setShouldOpen(true, for: shelf) }
        state.sequence = output.sequence; state.enabled = output.enabled; state.nearAndFacingMario = false; state.inDifferentRoom = false; states[id] = state
        _ = engineState.objects.mutate(id) { next in next.action = output.action; next.timer = output.timer; next.position.x = output.positionX; if output.shouldDelete { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        effectLog.append(.init(objectID: id, output: output, spawnedSwitches: switches))
        return true
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
