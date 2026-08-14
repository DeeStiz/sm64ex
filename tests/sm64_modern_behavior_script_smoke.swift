import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func appendWord(_ word: UInt32, to data: inout Data) {
    data.append(UInt8(truncatingIfNeeded: word))
    data.append(UInt8(truncatingIfNeeded: word >> 8))
    data.append(UInt8(truncatingIfNeeded: word >> 16))
    data.append(UInt8(truncatingIfNeeded: word >> 24))
}

private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 {
        hash ^= (value >> UInt64(byte * 8)) & 0xff
        hash &*= fnvPrime
    }
    return hash
}

private func fixtureProgram() -> Data {
    var data = Data()
    appendWord(0x0001_0000, to: &data) // BEGIN(1)
    appendWord(0x1002_0007, to: &data) // SET_INT(field 2, 7)
    appendWord(0x0f02_0003, to: &data) // ADD_INT(field 2, 3)
    appendWord(0x0500_0002, to: &data) // BEGIN_REPEAT(2)
    appendWord(0x1002_0009, to: &data) // SET_INT(field 2, 9)
    appendWord(0x0700_0000, to: &data) // END_REPEAT_CONTINUE()
    appendWord(0x0100_0002, to: &data) // DELAY(2)
    appendWord(0x0d03_0004, to: &data) // ADD_FLOAT(field 3, 4)
    appendWord(0x0c00_0000, to: &data) // CALL_NATIVE(0)
    appendWord(0, to: &data)
    appendWord(0x0a00_0000, to: &data) // BREAK()
    return data
}

private func traceFingerprint(_ traces: [SM64BehaviorCommandTrace]) -> UInt64 {
    traces.reduce(fnvOffset) { hash, trace in
        var result = hash
        result = hashU64(result, UInt64(trace.tick))
        result = hashU64(result, UInt64(trace.executedOffset))
        result = hashU64(result, UInt64(trace.executedOpcode))
        result = hashU64(result, UInt64(bitPattern: Int64(trace.procResult.rawValue)))
        result = hashU64(result, UInt64(bitPattern: Int64(trace.action)))
        result = hashU64(result, UInt64(trace.timer))
        result = hashU64(result, trace.nextOffset.map(UInt64.init) ?? UInt64.max)
        return result
    }
}

private func stateFingerprint(_ vm: SM64BehaviorVM) -> UInt64 {
    let snapshot = vm.snapshot
    var hash = fnvOffset
    hash = hashU64(hash, UInt64(bitPattern: Int64(snapshot.status.rawValue)))
    hash = hashU64(hash, snapshot.currentOffset.map(UInt64.init) ?? UInt64.max)
    hash = hashU64(hash, UInt64(snapshot.stackDepth))
    hash = hashU64(hash, UInt64(snapshot.timer))
    hash = hashU64(hash, UInt64(bitPattern: Int64(snapshot.behaviorDelayTimer)))
    hash = hashU64(hash, snapshot.commandCount)
    hash = hashU64(hash, UInt64(snapshot.tickCount))
    hash = hashU64(hash, UInt64(snapshot.randomSeed))
    let object = snapshot.object
    hash = hashU64(hash, UInt64(object.activeFlags))
    hash = hashU64(hash, UInt64(object.gfxFlags))
    hash = hashU64(hash, UInt64(bitPattern: Int64(object.modelID)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(object.hitboxRadius)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(object.hitboxHeight)))
    hash = hashU64(hash, UInt64(object.spawnCount))
    hash = hashU64(hash, UInt64(object.waterDropletCount))
    hash = hashU64(hash, UInt64(object.lastSpawnedModel))
    hash = hashU64(hash, object.lastSpawnedBehavior)
    hash = hashU64(hash, UInt64(bitPattern: Int64(object.lastSpawnedParameter)))
    for field in [UInt8(2), 3, 4] {
        hash = hashU64(hash, UInt64(field))
        hash = hashU64(hash, UInt64(bitPattern: Int64(object.getInt(field))))
        hash = hashU64(hash, UInt64(object.getFloat(field).bitPattern))
    }
    return hash
}

@main
enum SM64ModernBehaviorScriptSmoke {
    static func main() throws {
        let program = try SM64BehaviorScriptProgram(data: fixtureProgram())
        require(program.commands.map(\.wordLength) == [1, 1, 1, 1, 1, 1, 1, 1, 2, 1], "behavior command lengths")
        var vm = try SM64BehaviorVM(
            program: program,
            nativeHandler: { pointer, object in
                require(pointer == 0, "fixture native pointer")
                object.addInt(4, 1)
            }
        )
        try vm.executeTick()
        require(vm.snapshot.status == .break && vm.snapshot.currentOffset == 6, "first delay boundary")
        require(vm.snapshot.object.getInt(2) == 9, "repeat writes final integer")
        try vm.executeTick()
        require(vm.snapshot.status == .break && vm.snapshot.currentOffset == 7, "delay completion boundary")
        try vm.executeTick()
        require(vm.snapshot.status == .break && vm.snapshot.currentOffset == 10, "native and break boundary")
        require(vm.snapshot.object.getFloat(3) == 4, "float field")
        require(vm.snapshot.object.getInt(4) == 1, "native callback")
        require(vm.traces.map(\.executedOffset) == [0, 1, 2, 3, 4, 5, 4, 5, 6, 6, 7, 8, 10], "behavior control-flow trace")
        let trace = traceFingerprint(vm.traces)
        let state = stateFingerprint(vm)
        print(String(format: "behaviorTraceFingerprint=0x%016llx", trace))
        print(String(format: "behaviorStateFingerprint=0x%016llx", state))
    }
}
