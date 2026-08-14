import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func appendWord(_ bytes: [UInt8], to data: inout Data) {
    precondition(bytes.count == 8)
    data.append(contentsOf: bytes)
}

private func word(_ a: UInt8, _ b: UInt8, _ c: UInt8 = 0, _ d: UInt8 = 0) -> [UInt8] {
    [a, b, c, d, 0, 0, 0, 0]
}

private func pointer(_ value: Int) -> [UInt8] {
    var bytes = Array(repeating: UInt8(0), count: 8)
    var raw = UInt64(value)
    for index in 0..<8 {
        bytes[index] = UInt8(truncatingIfNeeded: raw)
        raw >>= 8
    }
    return bytes
}

private func pair(_ first: Int16, _ second: Int16) -> [UInt8] {
    var bytes = Array(repeating: UInt8(0), count: 8)
    let a = UInt16(bitPattern: first)
    let b = UInt16(bitPattern: second)
    bytes[0] = UInt8(truncatingIfNeeded: a)
    bytes[1] = UInt8(truncatingIfNeeded: a >> 8)
    bytes[2] = UInt8(truncatingIfNeeded: b)
    bytes[3] = UInt8(truncatingIfNeeded: b >> 8)
    return bytes
}

private func fixtureProgram() -> Data {
    var data = Data()
    // 000: SET_REG(7)
    appendWord(word(0x13, 0x04, 0x07), to: &data)
    // 008: JUMP_IF(EQ, 7, 40), with the NOP at 32 on the untaken path.
    appendWord(word(0x0c, 0x0c, 0x02), to: &data)
    appendWord(word(0x07, 0), to: &data)
    appendWord(pointer(40), to: &data)
    // 032: NOP()
    appendWord(word(0x32, 0x04), to: &data)
    // 040: AREA(2, nil)
    appendWord(word(0x1f, 0x08, 0x02), to: &data)
    appendWord(pointer(0), to: &data)
    // 056: WARP_NODE(10, 5, 1, 2, 0x80)
    appendWord(word(0x26, 0x08, 0x0a, 0x05), to: &data)
    appendWord(word(0x01, 0x02, 0x80), to: &data)
    // 072: PAINTING_WARP_NODE(3, 7, 2, 9, 1)
    appendWord(word(0x27, 0x08, 0x03, 0x07), to: &data)
    appendWord(word(0x02, 0x09, 0x01), to: &data)
    // 088: INSTANT_WARP(1, 4, -100, 200, -300)
    appendWord(word(0x28, 0x0c, 0x01, 0x04), to: &data)
    appendWord(pair(-100, 200), to: &data)
    appendWord(pair(-300, 0), to: &data)
    // 112: MARIO_POS(2, 900, 10, 20, -30)
    appendWord(word(0x2b, 0x0c, 0x02), to: &data)
    appendWord(pair(900, 10), to: &data)
    appendWord(pair(20, -30), to: &data)
    // 136: TERRAIN_TYPE(4), 144: SHOW_DIALOG(0, 42), 152: SET_MUSIC(0x1234, 0x56)
    appendWord(word(0x31, 0x04, 0x04), to: &data)
    appendWord(word(0x30, 0x04, 0x00, 0x2a), to: &data)
    appendWord(word(0x36, 0x08, 0x34, 0x12), to: &data)
    appendWord(pair(0x0056, 0), to: &data)
    // 168: TRANSITION(2, 15, 10, 20, 30)
    appendWord(word(0x33, 0x08, 0x02, 0x0f), to: &data)
    appendWord(word(10, 20, 30), to: &data)
    // 184: BLACKOUT(1), 192: GAMMA(1), 200: END_AREA()
    appendWord(word(0x34, 0x04, 1), to: &data)
    appendWord(word(0x35, 0x04, 1), to: &data)
    appendWord(word(0x20, 0x04), to: &data)
    // 208: JUMP_LINK(248), 224: SET_REG(9), 232: EXIT()
    appendWord(word(0x06, 0x08), to: &data)
    appendWord(pointer(248), to: &data)
    appendWord(word(0x13, 0x04, 0x09), to: &data)
    appendWord(word(0x02, 0x04), to: &data)
    // 240: unreachable NOP; 248: SET_REG(42); 256: RETURN().
    appendWord(word(0x32, 0x04), to: &data)
    appendWord(word(0x13, 0x04, 0x2a), to: &data)
    appendWord(word(0x07, 0x04), to: &data)
    return data
}

private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 {
        hash ^= (value >> UInt64(byte * 8)) & 0xff
        hash &*= fnvPrime
    }
    return hash
}

private func traceFingerprint(_ traces: [SM64LevelScriptCommandTrace]) -> UInt64 {
    traces.reduce(fnvOffset) { hash, trace in
        var result = hash
        result = hashU64(result, UInt64(trace.tick))
        result = hashU64(result, UInt64(trace.executedOffset))
        result = hashU64(result, UInt64(trace.executedOpcode))
        result = hashU64(result, UInt64(trace.executedSizeUnits))
        result = hashU64(result, UInt64(bitPattern: Int64(trace.register)))
        result = hashU64(result, UInt64(bitPattern: Int64(trace.level)))
        result = hashU64(result, UInt64(bitPattern: Int64(trace.globalArea)))
        result = hashU64(result, UInt64(bitPattern: Int64(trace.status.rawValue)))
        result = hashU64(result, trace.nextOffset.map(UInt64.init) ?? UInt64.max)
        return result
    }
}

private func stateFingerprint(_ vm: SM64LevelScriptVM) -> UInt64 {
    let state = vm.snapshot
    var hash = fnvOffset
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.status.rawValue)))
    hash = hashU64(hash, state.currentOffset.map(UInt64.init) ?? UInt64.max)
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.register)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.level)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.course)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.act)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.saveFile)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.globalArea)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.activeArea)))
    hash = hashU64(hash, UInt64(state.commandCount))
    for warp in state.warps + state.paintingWarps {
        hash = hashU64(hash, UInt64(warp.id))
        hash = hashU64(hash, UInt64(warp.destinationLevel))
        hash = hashU64(hash, UInt64(warp.destinationArea))
        hash = hashU64(hash, UInt64(warp.destinationNode))
        hash = hashU64(hash, UInt64(warp.flags))
        hash = hashU64(hash, warp.painting ? 1 : 0)
    }
    for warp in state.instantWarps {
        hash = hashU64(hash, UInt64(warp.id))
        hash = hashU64(hash, UInt64(warp.destinationArea))
        hash = hashU64(hash, UInt64(bitPattern: Int64(warp.displacement.0)))
        hash = hashU64(hash, UInt64(bitPattern: Int64(warp.displacement.1)))
        hash = hashU64(hash, UInt64(bitPattern: Int64(warp.displacement.2)))
    }
    if let mario = state.marioStart {
        hash = hashU64(hash, 1)
        hash = hashU64(hash, UInt64(mario.area))
        hash = hashU64(hash, UInt64(bitPattern: Int64(mario.yaw)))
        hash = hashU64(hash, UInt64(bitPattern: Int64(mario.position.0)))
        hash = hashU64(hash, UInt64(bitPattern: Int64(mario.position.1)))
        hash = hashU64(hash, UInt64(bitPattern: Int64(mario.position.2)))
    } else {
        hash = hashU64(hash, 0)
    }
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.terrainType)))
    hash = hashU64(hash, UInt64(state.dialog.0))
    hash = hashU64(hash, UInt64(state.dialog.1))
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.music.0)))
    hash = hashU64(hash, UInt64(bitPattern: Int64(state.music.1)))
    hash = hashU64(hash, UInt64(state.blackout))
    hash = hashU64(hash, UInt64(state.gamma))
    for transition in state.transitions {
        hash = hashU64(hash, UInt64(transition.type))
        hash = hashU64(hash, UInt64(transition.duration))
        hash = hashU64(hash, UInt64(transition.red))
        hash = hashU64(hash, UInt64(transition.green))
        hash = hashU64(hash, UInt64(transition.blue))
    }
    return hash
}

private func sleepProgram() -> Data {
    Data([0x13, 0x04, 1, 0, 0, 0, 0, 0, 0x03, 0x04, 2, 0, 0, 0, 0, 0, 0x02, 0x04, 0, 0, 0, 0, 0, 0])
}

private func loopProgram() -> Data {
    var data = Data()
    appendWord(word(0x13, 0x04, 1), to: &data)
    appendWord(word(0x0a, 0x04), to: &data)
    appendWord(word(0x0b, 0x08, 2), to: &data)
    appendWord(word(1, 0), to: &data)
    appendWord(word(0x02, 0x04), to: &data)
    return data
}

private func variableProgram() -> Data {
    var data = Data()
    appendWord(word(0x13, 0x04, 7), to: &data)
    appendWord(word(0x3c, 0x04, 0, 3), to: &data)
    appendWord(word(0x13, 0x04), to: &data)
    appendWord(word(0x3c, 0x04, 1, 3), to: &data)
    appendWord(word(0x02, 0x04), to: &data)
    return data
}

private func callProgram() -> Data {
    var data = Data()
    appendWord(word(0x11, 0x08, 5), to: &data)
    appendWord(pointer(0), to: &data)
    appendWord(word(0x02, 0x04), to: &data)
    return data
}

private func skipProgram() -> Data {
    var data = Data()
    appendWord(word(0x13, 0x04, 1), to: &data)
    appendWord(word(0x0e, 0x08, 2), to: &data)
    appendWord(word(0, 0), to: &data)
    appendWord(word(0x10, 0x04), to: &data)
    appendWord(word(0x10, 0x04), to: &data)
    appendWord(word(0x13, 0x04, 9), to: &data)
    appendWord(word(0x02, 0x04), to: &data)
    return data
}

@main
enum SM64ModernLevelScriptVMSmoke {
    static func main() throws {
        let program = try SM64LevelScriptProgram(data: fixtureProgram())
        var vm = try SM64LevelScriptVM(program: program)
        try vm.runToHalt()
        require(vm.snapshot.status == .halted, "main VM halted")
        require(vm.snapshot.register == 9, "subroutine returned to caller")
        require(vm.snapshot.activeArea == -1, "area teardown")
        require(vm.snapshot.warps == [SM64LevelScriptWarpRecord(id: 10, destinationLevel: 133, destinationArea: 1, destinationNode: 2, flags: 0x80, painting: false)], "warp state")
        require(vm.snapshot.paintingWarps.count == 1, "painting warp state")
        require(vm.snapshot.instantWarps.count == 1, "instant warp state")
        require(vm.snapshot.marioStart?.position.2 == -30, "Mario start state")
        require(vm.snapshot.transitions == [SM64LevelScriptTransitionRecord(type: 2, duration: 15, red: 10, green: 20, blue: 30)], "transition state")
        require(vm.traces.map(\.executedOffset) == [0, 8, 40, 56, 72, 88, 112, 136, 144, 152, 168, 184, 192, 200, 208, 248, 256, 224, 232], "control-flow trace")
        let trace = traceFingerprint(vm.traces)
        let state = stateFingerprint(vm)
        print(String(format: "levelScriptVMTraceFingerprint=0x%016llx", trace))
        print(String(format: "levelScriptVMStateFingerprint=0x%016llx", state))

        var sleep = try SM64LevelScriptVM(program: SM64LevelScriptProgram(data: sleepProgram()))
        try sleep.executeTick()
        require(sleep.snapshot.status == .paused && sleep.snapshot.delayFrames == 2 && sleep.snapshot.currentOffset == 8, "sleep initial pause")
        try sleep.executeTick()
        require(sleep.snapshot.status == .paused && sleep.snapshot.delayFrames == 1, "sleep countdown")
        try sleep.executeTick()
        require(sleep.snapshot.status == .halted && sleep.snapshot.currentOffset == nil, "sleep completion")

        var loop = try SM64LevelScriptVM(program: SM64LevelScriptProgram(data: loopProgram()))
        try loop.runToHalt()
        require(loop.snapshot.loopDepth == 0 && loop.snapshot.register == 1, "loop completion")

        var variables = try SM64LevelScriptVM(program: SM64LevelScriptProgram(data: variableProgram()))
        try variables.runToHalt()
        require(variables.snapshot.level == 7 && variables.snapshot.register == 7, "get/set variable semantics")

        var call = try SM64LevelScriptVM(
            program: SM64LevelScriptProgram(data: callProgram()),
            callHandler: { argument, value in value + Int32(argument) }
        )
        try call.runToHalt()
        require(call.snapshot.register == 5, "deterministic CALL handler")

        var skip = try SM64LevelScriptVM(program: SM64LevelScriptProgram(data: skipProgram()))
        try skip.runToHalt()
        require(skip.snapshot.register == 1, "SKIP_IF skips skippable commands and one following command")
        print("SM64 Modern level-script VM smoke passed")
    }
}
