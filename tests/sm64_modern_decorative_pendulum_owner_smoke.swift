import Foundation

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func appendWord(_ word: UInt32, to data: inout Data) {
    data.append(UInt8(truncatingIfNeeded: word))
    data.append(UInt8(truncatingIfNeeded: word >> 8))
    data.append(UInt8(truncatingIfNeeded: word >> 16))
    data.append(UInt8(truncatingIfNeeded: word >> 24))
}

/// This is the decoded shape of data/behavior_data.c's
/// bhvDecorativePendulum. Native pointers are source operands; the bridge
/// only records them through the VM and does not infer behavior from the
/// object identity.
private func decorativeProgram() throws -> SM64BehaviorScriptProgram {
    var data = Data()
    appendWord(0x0008_0000, to: &data) // BEGIN(OBJ_LIST_DEFAULT)
    appendWord(0x1100_0001, to: &data) // OR_INT(oFlags, update-gfx)
    appendWord(0x0C00_0000, to: &data) // CALL_NATIVE(init)
    appendWord(0x0000_0001, to: &data)
    appendWord(0x0800_0000, to: &data) // BEGIN_LOOP()
    appendWord(0x0C00_0000, to: &data) // CALL_NATIVE(loop)
    appendWord(0x0000_0002, to: &data)
    appendWord(0x0900_0000, to: &data) // END_LOOP()
    return try SM64BehaviorScriptProgram(data: data)
}

private func floorWorld() throws -> SM64SurfaceCollisionWorld {
    try SM64SurfaceCollisionWorld(staticSurfaces: [
        SM64Surface(
            id: 0x44,
            room: 7,
            vertex1: SM64SurfaceVec3s(x: -100, y: 0, z: -100),
            vertex2: SM64SurfaceVec3s(x: -100, y: 0, z: 100),
            vertex3: SM64SurfaceVec3s(x: 100, y: 0, z: -100),
            normal: SM64SurfaceVec3f(x: 0, y: 1, z: 0),
            originOffset: 0
        )
    ])
}

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hash(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var result = initial
    for byte in 0..<8 {
        result ^= (value >> UInt64(byte * 8)) & 0xff
        result &*= fnvPrime
    }
    return result
}

private func traceFingerprint(_ records: [SM64OracleTraceRecord]) -> UInt64 {
    records.reduce(fnvOffset) { partial, record in
        var result = hash(partial, record.simulationTick)
        result = hash(result, UInt64(record.domain))
        result = hash(result, UInt64(record.recordKind))
        result = hash(result, record.subjectID)
        result = hash(result, record.recordID)
        result = hash(result, UInt64(record.sequence))
        result = hash(result, UInt64(record.values.count))
        for value in record.values {
            result = hash(result, value)
        }
        return result
    }
}

@main
enum SM64ModernDecorativePendulumOwnerSmoke {
    static func main() throws {
        let program = try decorativeProgram()
        let source = SM64DecorativePendulumBehaviorSource(program: program)
        let engine = SM64SwiftEngineState(objectCapacity: 8)
        let captured = SM64DecorativePendulumObjectBridge()
        captured.bindCollisionWorld(try floorWorld())
        captured.bindSchema4TraceSink { _ in }
        let pendulum = try captured.spawnPendulum(
            in: engine,
            position: SM64ObjectVector3(x: 0, y: 200, z: 0),
            faceRoll: 100,
            behaviorSource: source
        )
        _ = engine.objects.mutate(pendulum) { record in
            record.angleVelocity.roll = 0x18
        }

        let tick = captured.tick(state: engine)
        let records = captured.schema4TraceRecords
        require(tick.effects.first?.output.angleVelocityRoll == 0x10, "source owner swing")
        require(tick.effects.first?.presentedEffects.count == 1, "source owner sound")
        require(records.count == 23, "fixed source trace count")
        require(records.map(\.sequence) == Array(0..<UInt32(records.count)), "fixed sequence")

        let lifecycle = records[0]
        require(lifecycle.domain == 6 && lifecycle.recordKind == 3, "lifecycle domain")
        require(lifecycle.recordID == 5 && lifecycle.subjectID == UInt64(pendulum.traceSubject), "lifecycle identity")
        require(lifecycle.values == [0, 0, 0x101], "lifecycle values")

        let collision = records[1]
        require(collision.domain == 7 && collision.recordKind == 3, "floor domain")
        require(collision.recordID == 1 && collision.subjectID == 0, "floor identity")
        require(collision.values == [
            UInt64(Float(0).bitPattern),
            UInt64(Float(200).bitPattern),
            UInt64(Float(0).bitPattern),
            UInt64(0x8000_0000),
            0,
            0,
            UInt64(Float(1).bitPattern),
        ], "floor query values")
        require(engine.objects.record(for: pendulum)?.room == 7, "floor query owns room")

        require(records[6].domain == 12 && records[6].recordKind == 4, "effect order")
        require(records[6].recordID == 1 && records[6].subjectID == UInt64(pendulum.traceSubject), "effect identity")
        require(records[7].domain == 6 && records[7].recordID == 2, "behavior follows effect")

        let objectTail = Array(records.suffix(14))
        require(objectTail.map(\.recordID) == Array(400...413).map(UInt64.init), "object schema order")
        require(objectTail.allSatisfy { $0.domain == 3 && $0.recordKind == 1 }, "object schema domain")
        require(objectTail.first?.subjectID == UInt64(pendulum.traceSubject), "generation-safe subject")
        require(objectTail[4].values == [1], "object timer after owner tick")

        // Without an attached decoded program, identity alone does not emit
        // lifecycle/script/collision records.
        let identityOnly = SM64DecorativePendulumObjectBridge()
        identityOnly.bindCollisionWorld(try floorWorld())
        identityOnly.bindSchema4TraceSink { _ in }
        let plainEngine = SM64SwiftEngineState(objectCapacity: 2)
        _ = try identityOnly.spawnPendulum(in: plainEngine, position: .zero)
        _ = identityOnly.tick(state: plainEngine)
        require(
            identityOnly.schema4TraceRecords.allSatisfy { $0.domain == 3 },
            "identity does not fake source records"
        )

        print(String(format: "decorativePendulumOwnerFingerprint=0x%016llx", traceFingerprint(records)))
        print("SM64 Modern decorative pendulum owner smoke passed")
    }
}
