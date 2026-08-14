import Foundation

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func contractLine() -> String {
    let updateOrder = SM64ObjectList.updateOrder.map(\.rawValue).map(String.init).joined(separator: ",")
    let active = String(format: "0x%04x", SM64ObjectPool.activeFlagActive | SM64ObjectPool.activeFlagUnknown8)
    let unimportant = String(
        format: "0x%04x",
        SM64ObjectPool.activeFlagActive | SM64ObjectPool.activeFlagUnknown8
            | SM64ObjectPool.activeFlagUnimportant
    )
    let floatBits: (Float) -> String = { String(format: "0x%08x", $0.bitPattern) }
    return "contract=capacity:\(SM64ObjectPool.defaultCapacity);numLists:\(SM64ObjectList.allCases.count);updateOrder:\(updateOrder);active:\(active);unimportant:\(unimportant);hitboxRadius:\(floatBits(50));hitboxHeight:\(floatBits(100));collisionDistance:\(floatBits(1000));drawingDistance:\(floatBits(4000));distanceToMario:\(floatBits(19_000));gfxOrigin:\(floatBits(-10_000))"
}

@main
enum SM64ModernObjectPoolSmoke {
    static func main() throws {
        print(contractLine())
        require(SM64ObjectList.updateOrder.map(\.rawValue) == [11, 9, 10, 0, 5, 4, 2, 6, 8, 12], "C update order drift")

        let pool = SM64ObjectPool(capacity: 3)
        let player = try pool.spawn(in: .player, model: 1, behaviorIdentity: 0x20)
        let actor = try pool.spawn(in: .generalActor, model: 2, behaviorIdentity: 0x40, parent: player)
        let unimportant = try pool.spawn(in: .unimportant, model: 3, behaviorIdentity: 0x60, parent: player)

        require(player.slot == 0 && player.generation == 1 && player.traceSubject == 1, "first C slot identity")
        require(actor.slot == 1 && actor.generation == 1 && actor.traceSubject == 2, "second C slot identity")
        require(unimportant.slot == 2 && unimportant.generation == 1, "third C slot identity")
        require(pool.ids(in: .player) == [player], "player list insertion")
        require(pool.ids(in: .generalActor) == [actor], "actor list insertion")
        require(pool.ids(in: .unimportant) == [unimportant], "unimportant list insertion")
        require(pool.updateIDs() == [player, actor, unimportant], "C update flattening")

        guard let initial = pool.record(for: player) else { preconditionFailure("missing initialized object") }
        require(initial.activeFlags == 0x0101, "active flag initialization")
        require(initial.parent == player, "self parent initialization")
        require(initial.position == .zero, "logical position initialization")
        require(initial.gfxPosition == .hiddenGfxOrigin, "hidden gfx position initialization")
        require(initial.hitboxRadius == 50 && initial.hitboxHeight == 100, "hitbox initialization")
        require(initial.intangibleTimer == -1 && initial.health == 2048, "interaction initialization")
        require(initial.collisionDistance == 1000 && initial.drawingDistance == 4000, "distance initialization")
        require(initial.distanceToMario == 19_000 && initial.room == -1, "room/distance initialization")
        require(initial.transform == [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1], "identity transform")
        require(pool.record(for: unimportant)?.activeFlags == 0x0111, "unimportant flag initialization")

        require(pool.markForDeletion(unimportant), "mark deletion")
        require(pool.contains(unimportant), "deactivated node remains linked until unload")
        require(pool.updateIDs() == [player, actor, unimportant], "deactivated node remains ordered")

        // With no free slots, C evicts the first unimportant node and allocates
        // its slot. Generation 2 rejects the old pointer-like reference.
        let replacement = try pool.spawn(in: .level, model: 4, behaviorIdentity: 0x80, parent: player)
        require(pool.lastEvictedID == unimportant, "unimportant eviction")
        require(replacement.slot == unimportant.slot && replacement.generation == 2, "head-prepend slot reuse")
        require(!pool.contains(unimportant) && pool.contains(replacement), "stale generation rejection")
        require(!pool.mutate(unimportant) { _ in }, "stale mutation rejection")
        require(pool.ids(in: .level) == [replacement], "replacement list insertion")

        require(pool.despawn(actor), "explicit unload")
        require(!pool.contains(actor), "unloaded object absent")
        let reused = try pool.spawn(in: .surface, parent: player)
        require(reused.slot == actor.slot && reused.generation == 2, "free-list head reuse")
        require(pool.ids(in: .surface) == [reused], "reused list insertion")

        require(pool.markForDeletion(reused), "second mark deletion")
        require(pool.unloadDeactivated() == [reused], "ordered deactivated unload")
        require(!pool.contains(reused), "deactivated object unloaded")

        do {
            _ = try pool.spawn(in: .default, parent: unimportant)
            preconditionFailure("stale parent should fail closed")
        } catch let error as SM64ObjectPoolError {
            require(error == .invalidReference(unimportant), "stale parent error")
        }

        pool.reset()
        require(pool.allRecords().isEmpty, "reset clears records")
        require(!pool.contains(player), "reset invalidates old generation")
        let afterReset = try pool.spawn(in: .player)
        require(afterReset.slot == 0 && afterReset.generation == 2, "reset generation fence")

        let exhausted = SM64ObjectPool(capacity: 1)
        _ = try exhausted.spawn(in: .player)
        do {
            _ = try exhausted.spawn(in: .level)
            preconditionFailure("exhaustion should fail closed")
        } catch let error as SM64ObjectPoolError {
            require(error == .poolExhausted(capacity: 1), "exhaustion error")
        }

        print("SM64 Modern object pool smoke passed")
    }
}
