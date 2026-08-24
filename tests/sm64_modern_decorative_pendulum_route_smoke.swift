import Foundation

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { preconditionFailure(message) }
}

private struct SourceVertex {
    let x: Int16
    let y: Int16
    let z: Int16
}

private struct SourceTriangle {
    let type: Int16
    let first: Int
    let second: Int
    let third: Int
}

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashBytes(_ bytes: some Sequence<UInt8>) -> UInt64 {
    bytes.reduce(fnvOffset) { partial, byte in
        (partial ^ UInt64(byte)) &* fnvPrime
    }
}

private func hashString(_ value: String) -> UInt64 {
    hashBytes(value.utf8)
}

private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var result = initial
    for byte in 0..<8 {
        result ^= (value >> UInt64(byte * 8)) & 0xff
        result &*= fnvPrime
    }
    return result
}

private func appendWord(_ word: UInt32, to data: inout Data) {
    data.append(UInt8(truncatingIfNeeded: word))
    data.append(UInt8(truncatingIfNeeded: word >> 8))
    data.append(UInt8(truncatingIfNeeded: word >> 16))
    data.append(UInt8(truncatingIfNeeded: word >> 24))
}

private func firstCapture(_ pattern: String, in text: String) -> String? {
    guard let expression = try? NSRegularExpression(pattern: pattern) else { return nil }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    guard let match = expression.firstMatch(in: text, range: range), match.numberOfRanges > 1,
          let capture = Range(match.range(at: 1), in: text) else { return nil }
    return String(text[capture])
}

private func sourceBehaviorProgram(_ text: String) throws -> (program: SM64BehaviorScriptProgram, callbacks: [String: UInt32]) {
    guard let start = text.range(of: "const BehaviorScript bhvDecorativePendulum[] = {") else {
        preconditionFailure("bhvDecorativePendulum declaration missing from content")
    }
    guard let end = text[start.upperBound...].range(of: "};") else {
        preconditionFailure("bhvDecorativePendulum declaration is unterminated")
    }
    let body = String(text[start.lowerBound..<end.upperBound])
    var data = Data()
    var callbacks: [String: UInt32] = [:]
    for rawLine in body.split(whereSeparator: \.isNewline) {
        let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        if line.contains("BEGIN(OBJ_LIST_DEFAULT)") {
            appendWord(0x0008_0000, to: &data)
        } else if line.contains("OR_INT(oFlags, OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE)") {
            appendWord(0x1100_0001, to: &data)
        } else if line.contains("BEGIN_LOOP()") {
            appendWord(0x0800_0000, to: &data)
        } else if line.contains("END_LOOP()") {
            appendWord(0x0900_0000, to: &data)
        } else if let callback = firstCapture(#"CALL_NATIVE\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*\)"#, in: line) {
            let identity = UInt32(truncatingIfNeeded: hashString(callback)) | 0x8000_0000
            callbacks[callback] = identity
            appendWord(0x0C00_0000, to: &data)
            appendWord(identity, to: &data)
        }
    }
    let program = try SM64BehaviorScriptProgram(data: data)
    require(program.commands.map(\.opcode) == [
        .begin, .orInt, .callNative, .beginLoop, .callNative, .endLoop,
    ], "decoded behavior command sequence")
    require(callbacks.keys.sorted() == ["bhv_decorative_pendulum_init", "bhv_decorative_pendulum_loop"], "decoded native callback source")
    return (program, callbacks)
}

private func surfaceType(_ token: String) -> Int16? {
    let values: [String: Int16] = [
        "SURFACE_DEFAULT": 0x0000,
        "SURFACE_VERY_SLIPPERY": 0x0013,
        "SURFACE_INSTANT_WARP_1B": 0x001B,
        "SURFACE_WALL_MISC": 0x0028,
        "SURFACE_NO_CAM_COLLISION": 0x0076,
        "SURFACE_PAINTING_WOBBLE_BE": 0x00BE,
        "SURFACE_PAINTING_WOBBLE_BF": 0x00BF,
        "SURFACE_PAINTING_WOBBLE_C0": 0x00C0,
        "SURFACE_PAINTING_WOBBLE_C1": 0x00C1,
        "SURFACE_PAINTING_WOBBLE_C2": 0x00C2,
        "SURFACE_PAINTING_WOBBLE_C3": 0x00C3,
        "SURFACE_PAINTING_WOBBLE_C4": 0x00C4,
        "SURFACE_PAINTING_WOBBLE_C5": 0x00C5,
        "SURFACE_PAINTING_WOBBLE_C6": 0x00C6,
        "SURFACE_PAINTING_WOBBLE_CD": 0x00CD,
        "SURFACE_PAINTING_WOBBLE_CE": 0x00CE,
        "SURFACE_PAINTING_WOBBLE_CF": 0x00CF,
        "SURFACE_PAINTING_WARP_EB": 0x00EB,
        "SURFACE_PAINTING_WARP_EC": 0x00EC,
        "SURFACE_PAINTING_WARP_ED": 0x00ED,
        "SURFACE_PAINTING_WARP_EE": 0x00EE,
        "SURFACE_PAINTING_WARP_EF": 0x00EF,
        "SURFACE_PAINTING_WARP_F0": 0x00F0,
        "SURFACE_PAINTING_WARP_F1": 0x00F1,
        "SURFACE_PAINTING_WARP_F2": 0x00F2,
        "SURFACE_PAINTING_WARP_F3": 0x00F3,
        "SURFACE_PAINTING_WARP_F7": 0x00F7,
        "SURFACE_PAINTING_WARP_F8": 0x00F8,
        "SURFACE_PAINTING_WARP_F9": 0x00F9,
        "SURFACE_PAINTING_WARP_FA": 0x00FA,
        "SURFACE_PAINTING_WARP_FB": 0x00FB,
        "SURFACE_PAINTING_WARP_FC": 0x00FC,
        "SURFACE_TTC_PAINTING_1": 0x00F4,
        "SURFACE_TTC_PAINTING_2": 0x00F5,
        "SURFACE_TTC_PAINTING_3": 0x00F6,
        "SURFACE_WOBBLING_WARP": 0x00FD,
    ]
    return values[token]
}

private func integers(in text: String) -> [Int] {
    guard let expression = try? NSRegularExpression(pattern: #"(?<![A-Za-z_])-?[0-9]+"#) else { return [] }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    return expression.matches(in: text, range: range).compactMap { match in
        guard let capture = Range(match.range, in: text) else { return nil }
        return Int(text[capture])
    }
}

private func sourceCollisionWorld(
    collisionText: String,
    roomText: String
) throws -> (world: SM64SurfaceCollisionWorld, surfaceCount: Int, floor: SM64SurfaceQueryResult) {
    let vertexExpression = try NSRegularExpression(
        pattern: #"COL_VERTEX\(\s*(-?[0-9]+)\s*,\s*(-?[0-9]+)\s*,\s*(-?[0-9]+)\s*\)"#
    )
    let sourceRange = NSRange(collisionText.startIndex..<collisionText.endIndex, in: collisionText)
    let vertices = vertexExpression.matches(in: collisionText, range: sourceRange).compactMap { match -> SourceVertex? in
        guard match.numberOfRanges == 4,
              let xRange = Range(match.range(at: 1), in: collisionText),
              let yRange = Range(match.range(at: 2), in: collisionText),
              let zRange = Range(match.range(at: 3), in: collisionText),
              let x = Int16(String(collisionText[xRange])),
              let y = Int16(String(collisionText[yRange])),
              let z = Int16(String(collisionText[zRange])) else { return nil }
        return SourceVertex(x: x, y: y, z: z)
    }
    require(vertices.count > 1_600, "decoded Castle Inside area-2 vertices")

    let roomBody = roomText.components(separatedBy: .newlines)
        .map { $0.components(separatedBy: "//").first ?? $0 }
        .joined(separator: "\n")
    let rooms = integers(in: roomBody)
    var triangles: [SourceTriangle] = []
    var currentType: Int16?
    for rawLine in collisionText.components(separatedBy: .newlines) {
        let line = rawLine.components(separatedBy: "//").first ?? rawLine
        if let typeToken = firstCapture(#"COL_TRI_INIT\(\s*([A-Za-z0-9_]+)\s*,"#, in: line) {
            currentType = surfaceType(typeToken)
            continue
        }
        guard let type = currentType else { continue }
        if line.contains("COL_TRI_SPECIAL(") {
            let values = integers(in: line)
            guard values.count >= 4 else { continue }
            triangles.append(SourceTriangle(type: type, first: values[0], second: values[1], third: values[2]))
        } else if line.contains("COL_TRI(") {
            let values = integers(in: line)
            guard values.count >= 3 else { continue }
            triangles.append(SourceTriangle(type: type, first: values[0], second: values[1], third: values[2]))
        }
    }
    require(triangles.count == 2_019, "decoded Castle Inside area-2 triangle stream")
    require(rooms.count >= triangles.count, "decoded Castle Inside area-2 room stream")

    var surfaces: [SM64Surface] = []
    surfaces.reserveCapacity(triangles.count)
    for (index, triangle) in triangles.enumerated() {
        guard vertices.indices.contains(triangle.first), vertices.indices.contains(triangle.second), vertices.indices.contains(triangle.third) else {
            preconditionFailure("collision triangle references an invalid source vertex")
        }
        let v1 = vertices[triangle.first]
        let v2 = vertices[triangle.second]
        let v3 = vertices[triangle.third]
        let nxInteger = (Int(v2.y) - Int(v1.y)) * (Int(v3.z) - Int(v2.z))
            - (Int(v2.z) - Int(v1.z)) * (Int(v3.y) - Int(v2.y))
        let nyInteger = (Int(v2.z) - Int(v1.z)) * (Int(v3.x) - Int(v2.x))
            - (Int(v2.x) - Int(v1.x)) * (Int(v3.z) - Int(v2.z))
        let nzInteger = (Int(v2.x) - Int(v1.x)) * (Int(v3.y) - Int(v2.y))
            - (Int(v2.y) - Int(v1.y)) * (Int(v3.x) - Int(v2.x))
        let nx = Float(nxInteger)
        let ny = Float(nyInteger)
        let nz = Float(nzInteger)
        let magnitude = sqrt(nx * nx + ny * ny + nz * nz)
        guard magnitude >= 0.0001 else { continue }
        let normal = SM64SurfaceVec3f(x: nx / magnitude, y: ny / magnitude, z: nz / magnitude)
        var flags: Int8 = 0
        if (0x76...0x7A).contains(triangle.type) { flags |= SM64SurfaceCollisionWorld.noCameraCollisionFlag }
        if normal.y <= 0.01 && normal.y >= -0.01 && (normal.x < -0.707 || normal.x > 0.707) {
            flags |= SM64SurfaceCollisionWorld.xProjectionFlag
        }
        let minY = min(Int(v1.y), Int(v2.y), Int(v3.y))
        let maxY = max(Int(v1.y), Int(v2.y), Int(v3.y))
        surfaces.append(SM64Surface(
            id: UInt32(index + 1),
            type: triangle.type,
            force: 0,
            flags: flags,
            room: Int8(truncatingIfNeeded: rooms[index]),
            lowerY: Int16(truncatingIfNeeded: minY - 5),
            upperY: Int16(truncatingIfNeeded: maxY + 5),
            vertex1: SM64SurfaceVec3s(x: v1.x, y: v1.y, z: v1.z),
            vertex2: SM64SurfaceVec3s(x: v2.x, y: v2.y, z: v2.z),
            vertex3: SM64SurfaceVec3s(x: v3.x, y: v3.y, z: v3.z),
            normal: normal,
            originOffset: -(normal.x * Float(v1.x) + normal.y * Float(v1.y) + normal.z * Float(v1.z))
        ))
    }
    let world = try SM64SurfaceCollisionWorld(staticSurfaces: surfaces)
    let floor = world.findFloor(x: -205, y: 2611, z: 7140)
    require(floor.surfaceID != nil && floor.height > 2_000, "source level floor at pendulum position")
    return (world, surfaces.count, floor)
}

private func sourceLevelPosition(_ text: String) -> SM64ObjectVector3 {
    let pattern = #"MODEL_CASTLE_CLOCK_PENDULUM,\s*/\*pos\*/\s*(-?[0-9]+),\s*(-?[0-9]+),\s*(-?[0-9]+).*bhvDecorativePendulum"#
    guard let capture = firstCapture(pattern, in: text), let x = Float(capture) else {
        preconditionFailure("Castle Inside area-2 pendulum object is missing")
    }
    let expression = try! NSRegularExpression(pattern: pattern)
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    guard let match = expression.firstMatch(in: text, range: range), match.numberOfRanges == 4 else {
        preconditionFailure("Castle Inside pendulum coordinates are missing")
    }
    let values = (1..<4).compactMap { index -> Float? in
        guard let captureRange = Range(match.range(at: index), in: text) else { return nil }
        return Float(text[captureRange])
    }
    require(values.count == 3 && x == values[0], "source object coordinate decode")
    return SM64ObjectVector3(x: values[0], y: values[1], z: values[2])
}

private struct CoverageKey: Hashable {
    let domain: UInt32
    let recordID: UInt64
}

private func coverageFingerprint(_ records: [SM64OracleTraceRecord]) -> UInt64 {
    var result = fnvOffset
    let keys = Set(records.compactMap { record -> CoverageKey? in
        guard record.domain == 3 || record.domain == 6 || record.domain == 7
                || record.domain == 12 else { return nil }
        guard record.domain != 12 || record.recordID == 1 else { return nil }
        return CoverageKey(domain: record.domain, recordID: record.recordID)
    }).sorted { lhs, rhs in
        lhs.domain == rhs.domain ? lhs.recordID < rhs.recordID : lhs.domain < rhs.domain
    }
    for key in keys {
        result = hashU64(result, UInt64(key.domain))
        result = hashU64(result, 0)
        result = hashU64(result, key.recordID)
    }
    result = hashU64(result, UInt64(keys.count))
    return result
}

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var result = initial
    for byte in 0..<4 {
        result ^= (UInt64(value) >> UInt64(byte * 8)) & 0xff
        result &*= fnvPrime
    }
    return result
}

private func nativeTimebaseFingerprint() -> UInt64 {
    var result = fnvOffset
    // TIMEBASE_CADENCE_POLICY_VERSION=3, 60 Hz simulation, 30 Hz legacy,
    // two simulation steps per legacy tick, and max catch-up of two.
    for value: UInt32 in [3, 60, 1, 30, 1, 2, 2] {
        result = hashU32(result, value)
    }
    return result
}

@main
enum SM64ModernDecorativePendulumRouteSmoke {
    static func main() throws {
        guard CommandLine.arguments.count == 8 else {
            preconditionFailure("usage: route-smoke PACK BEHAVIOR_SOURCE COLLISION_SOURCE ROOM_SOURCE LEVEL_SOURCE OUTPUT TICKS")
        }
        let packURL = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
        let behaviorURL = URL(fileURLWithPath: CommandLine.arguments[2]).standardizedFileURL
        let collisionURL = URL(fileURLWithPath: CommandLine.arguments[3]).standardizedFileURL
        let roomURL = URL(fileURLWithPath: CommandLine.arguments[4]).standardizedFileURL
        let levelURL = URL(fileURLWithPath: CommandLine.arguments[5]).standardizedFileURL
        let outputURL = URL(fileURLWithPath: CommandLine.arguments[6]).standardizedFileURL
        let tickCount = Int(CommandLine.arguments[7]) ?? 0
        require(tickCount >= 2 && tickCount <= 120, "bounded multi-tick capture")

        let pack = try SM64ContentPack.load(from: packURL)
        let index = try SM64ContentPackIndex(pack: pack)
        let behaviorKey = SM64ContentResourceKey(kind: .behaviorBytecode, relativePath: "data/behavior_data.c")
        let collisionKey = SM64ContentResourceKey(kind: .geometry, relativePath: "levels/castle_inside/areas/2/collision.inc.c")
        let packedBehavior = try index.bytes(kind: behaviorKey.kind, relativePath: behaviorKey.relativePath)
        let packedCollision = try index.bytes(kind: collisionKey.kind, relativePath: collisionKey.relativePath)
        let behaviorData = try Data(contentsOf: behaviorURL, options: [.mappedIfSafe])
        let collisionData = try Data(contentsOf: collisionURL, options: [.mappedIfSafe])
        require(packedBehavior == behaviorData, "behavior source pack bytes")
        require(packedCollision == collisionData, "collision source pack bytes")
        let behaviorText = String(decoding: packedBehavior, as: UTF8.self)
        let collisionText = String(decoding: collisionData, as: UTF8.self)
        let roomText = try String(contentsOf: roomURL, encoding: .utf8)
        let levelText = try String(contentsOf: levelURL, encoding: .utf8)
        let decoded = try sourceBehaviorProgram(behaviorText)
        let collision = try sourceCollisionWorld(collisionText: collisionText, roomText: roomText)
        let position = sourceLevelPosition(levelText)
        require(position == SM64ObjectVector3(x: -205, y: 2611, z: 7140), "canonical source object position")

        var captured: [SM64OracleTraceRecord] = []
        let bridge = SM64DecorativePendulumObjectBridge()
        bridge.bindCollisionWorld(collision.world)
        bridge.bindSchema4TraceSink { record in captured.append(record) }
        let engine = SM64SwiftEngineState(objectCapacity: 8)
        engine.beginLevel(levelNumber: 6, areaIndex: 2)
        let source = SM64DecorativePendulumBehaviorSource(
            program: decoded.program,
            targetResolver: SM64BehaviorTargetResolver()
        )
        _ = try bridge.spawnPendulum(in: engine, position: position, behaviorSource: source)
        // The native owner runs continuous pendulum dynamics on every 60 Hz
        // step while the decoded behavior program advances on every other
        // (30 Hz) legacy boundary. Keep the two domains explicit in the
        // source-backed Swift capture.
        // The authored area-2 route reaches its transition after the final
        // three source ticks: the native object remains observable, but the
        // behavior VM no longer emits script records. The last two redraws
        // also clear the graph animation bit while preserving render
        // ownership, matching the native transition boundary.
        let sourceBehaviorTicks = max(0, tickCount - 3)
        let animatedTicks = max(0, tickCount - 2)
        for index in 0..<tickCount {
            // The first admitted native step closes the legacy interval;
            // the following redraw holds the VM cursor while still running
            // the source native body. This is the C timebase's 60/30 phase.
            _ = bridge.tick(
                state: engine,
                advanceLegacyDomain: index < sourceBehaviorTicks && index.isMultiple(of: 2),
                advanceNativeDomain: index < sourceBehaviorTicks,
                keepGraphAnimation: index < animatedTicks
            )
        }

        let domains = Set(captured.map(\.domain))
        require(captured.count > 0, "source-backed Swift records")
        require(Set([3, 6, 7, 12]).isSubset(of: domains), "complete decorative route domains")
        require(Set(captured.map(\.simulationTick)).count >= 2, "multi-tick Swift window")
        require(captured.map(\.sequence) == Array(0..<UInt32(captured.count)), "canonical Swift sequence")
        require(collision.floor.surfaceID != nil, "source floor query was not a miss")

        let contentFingerprint = hashString("behavior_data.c;castle_inside/areas/2;castle_inside/script.c")
        let configuration = SM64OracleTraceConfiguration(
            regionCode: 0x5553,
            mode: .record,
            buildFingerprint: hashString("sm64-modern-native-castle-area2-pendulum;source-backed"),
            contentFingerprint: contentFingerprint,
            timebaseFingerprint: nativeTimebaseFingerprint(),
            configurationFingerprint: hashString("region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;castle=area2"),
            initialSaveFingerprint: hashString("sm64-modern-native-castle-area2-initial-save"),
            coverageFingerprint: coverageFingerprint(captured)
        )
        try SM64OracleTraceFile.write(configuration: configuration, records: captured, to: outputURL)
        print(
            "decorativePendulumRouteSwiftCapture output=\(outputURL.path) records=\(captured.count) "
                + "ticks=\(Set(captured.map(\.simulationTick)).count) domains=\(domains.sorted().map(String.init).joined(separator: ",")) "
                + "source_program_commands=\(decoded.program.commands.count) collision_surfaces=\(collision.surfaceCount) "
                + "floor_height=\(collision.floor.height) floor_room=\(collision.floor.surfaceID.flatMap(collision.world.surface(withID:)).map { $0.room } ?? 0)"
        )
    }
}
