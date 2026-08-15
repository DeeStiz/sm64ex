import Foundation

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func contractLine() -> String {
    let timeStopMask = SM64TimeStopFlags.unknown0
        .union(.enabled)
        .union(.dialog)
        .union(.marioAndDoors)
        .union(.allObjects)
        .union(.marioOpenedDoor)
        .union(.active)
    return "contract=levelMin:\(SM64EngineGlobals().levelNumber);objectArena:\(0x800);effectsArena:\(0x4000);timeStopMask:\(String(format: "0x%02x", timeStopMask.rawValue));initialArea:\(SM64EngineGlobals().areaIndex);initialTimeStop:\(SM64EngineGlobals().timeStopState.rawValue);initialObjectCounter:\(SM64EngineGlobals().objectCounter)"
}

@main
enum SM64ModernEngineStateSmoke {
    static func main() throws {
        print(contractLine())

        let linear = SM64LinearArena(capacity: 32)
        let first = try linear.allocate(byteCount: 1)
        require(first.offset == 0 && first.byteCount == 1 && first.reservedByteCount == 4, "C ALIGN4 first allocation")
        let second = try linear.allocate(byteCount: 3)
        require(second.offset == 4 && second.reservedByteCount == 4, "C ALIGN4 second allocation")
        let mark = linear.mark()
        let third = try linear.allocate(byteCount: 5)
        require(third.offset == 8 && third.reservedByteCount == 8, "C ALIGN4 third allocation")
        require(linear.usedBytes == 16 && linear.contains(first) && linear.contains(third), "linear arena usage")
        try linear.rewind(to: mark)
        require(linear.usedBytes == 8 && linear.contains(first) && !linear.contains(third), "linear rewind")
        do {
            _ = try linear.allocate(byteCount: 25)
            preconditionFailure("linear overflow should fail closed")
        } catch let error as SM64MemoryArenaError {
            require(error == .outOfMemory(requested: 28, available: 24), "linear overflow error")
        }
        linear.reset()
        require(!linear.contains(first) && linear.usedBytes == 0, "linear generation reset")

        let freeList = SM64FreeListArena(capacity: 64)
        let blockA = try freeList.allocate(byteCount: 1)
        require(blockA.offset == 16 && blockA.reservedByteCount == 20, "C memory header/payload alignment")
        let blockB = try freeList.allocate(byteCount: 17)
        require(blockB.offset == 36 && blockB.reservedByteCount == 44, "C small remainder consumption")
        require(freeList.remainingBytes == 0, "free-list full usage")
        require(freeList.free(blockA), "arbitrary-order free")
        require(!freeList.contains(blockA), "freed allocation invalid")
        let blockC = try freeList.allocate(byteCount: 1)
        require(blockC.offset == 16 && blockC != blockA, "first-fit reuse with generation token")
        require(freeList.free(blockB) && freeList.free(blockC), "free/coalesce")
        require(freeList.remainingBytes == 64, "coalesced full arena")
        freeList.reset()
        require(!freeList.contains(blockB), "free-list generation reset")

        let state = SM64SwiftEngineState(
            objectCapacity: 4,
            arenaCapacities: SM64EngineArenaCapacities(level: 128, object: 64, effects: 64)
        )
        require(state.globals == SM64EngineGlobals(), "C global initialization")
        let mario = try state.spawnObject(in: .player, behaviorIdentity: 0x20, isMario: true)
        let actor = try state.spawnObject(in: .generalActor, behaviorIdentity: 0x40, parent: mario)
        require(state.globals.marioObject == mario, "Mario global identity")
        require(state.setCurrentObject(actor) && state.globals.currentObject == actor, "current object identity")
        require(state.bindPlatformCollisionOwner(actor), "owner collision lease")
        require(state.platformCollisionOwners == [actor], "owner collision order")
        require(!state.bindPlatformCollisionOwner(actor), "duplicate owner collision lease")
        require(state.removePlatformCollisionOwner(actor), "owner collision removal")
        require(state.platformCollisionOwners.isEmpty, "collision lease removed")
        state.addTimeStop([.enabled, .marioAndDoors])
        require(state.globals.timeStopState == [.enabled, .marioAndDoors], "time-stop flags")
        state.beginFrame()
        state.finishFrame(objectCount: 2)
        let snapshot = state.snapshot()
        require(snapshot.globals.frame == 1 && snapshot.globals.objectCounter == 2, "frame snapshot")
        require(snapshot.objects.map(\.id) == [mario, actor], "object snapshot ordering")

        let oldEpoch = state.globals.resetEpoch
        state.beginLevel(levelNumber: 7, areaIndex: 2)
        require(state.globals.levelNumber == 7 && state.globals.areaIndex == 2, "level transition")
        require(state.globals.resetEpoch == oldEpoch + 1, "state reset epoch")
        require(!state.objects.contains(mario) && state.snapshot().objects.isEmpty, "level reset object teardown")
        require(state.arenas.level.usedBytes == 0 && state.arenas.object.usedBytes == 0, "level reset arenas")

        print("SM64 Modern engine state smoke passed")
    }
}
