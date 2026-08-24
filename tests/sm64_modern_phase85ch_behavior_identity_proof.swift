import Foundation

private enum ProofError: Error, CustomStringConvertible {
    case invalid(String)

    var description: String {
        switch self {
        case .invalid(let message): return message
        }
    }
}

private func u32(_ data: Data, _ offset: Int) -> UInt32 {
    var value: UInt32 = 0
    for index in 0..<4 {
        value |= UInt32(data[offset + index]) << UInt32(index * 8)
    }
    return value
}

private func u64(_ data: Data, _ offset: Int) -> UInt64 {
    var value: UInt64 = 0
    for index in 0..<8 {
        value |= UInt64(data[offset + index]) << UInt64(index * 8)
    }
    return value
}

private func source(_ path: String) throws -> String {
    try String(contentsOfFile: path, encoding: .utf8)
}

private func fnv(_ value: String) -> UInt64 {
    var hash: UInt64 = 1_469_598_103_934_665_603
    for byte in value.utf8 {
        hash ^= UInt64(byte)
        hash &*= 1_099_511_628_211
    }
    return hash
}

private struct SpawnRecord {
    let path: String
    let subject: UInt64
    let model: UInt64
    let identity: UInt64
    let parent: UInt64
    let tick: UInt64
}

private let headerSize = 72
private let recordSize = 128
private let targetRecord = 355
private let targetOffset = headerSize + targetRecord * recordSize

private func parse(_ path: String) throws -> SpawnRecord {
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    guard data.count >= targetOffset + recordSize,
          u32(data, 0) == 1,
          u32(data, 4) == UInt32(headerSize),
          u32(data, 8) == 4 else {
        throw ProofError.invalid("schema-4 header mismatch: \(path)")
    }

    let record = SpawnRecord(
        path: path,
        subject: u64(data, targetOffset + 24),
        model: u64(data, targetOffset + 56),
        identity: u64(data, targetOffset + 64),
        parent: u64(data, targetOffset + 72),
        tick: u64(data, targetOffset + 8))

    guard record.subject == 11,
          record.model == 0,
          record.parent == 0,
          record.tick == 1,
          u32(data, targetOffset + 16) == 12,
          u32(data, targetOffset + 20) == 4,
          u64(data, targetOffset + 32) == 4,
          u32(data, targetOffset + 40) == 10,
          u32(data, targetOffset + 44) == 3 else {
        throw ProofError.invalid("subject-11 object-spawn metadata mismatch: \(path)")
    }

    print(
        "phase85ch_trace path=\(path) record=\(targetRecord) tick=\(record.tick) "
            + "subject=\(record.subject) model=0x\(String(record.model, radix: 16)) "
            + "behavior_identity=0x\(String(record.identity, radix: 16)) parent=\(record.parent)"
    )
    return record
}

do {
    let arguments = Array(CommandLine.arguments.dropFirst())
    guard arguments.count == 3 else {
        throw ProofError.invalid("usage: phase85ch-behavior-identity-proof DEBUG ASAN RELEASE")
    }

    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let area1Macro = try source(root.appendingPathComponent("levels/castle_inside/areas/1/macro.inc.c").path)
    let area1Collision = try source(root.appendingPathComponent("levels/castle_inside/areas/1/collision.inc.c").path)
    let macroPresets = try source(root.appendingPathComponent("include/macro_presets.h").path)
    let surfaceLoad = try source(root.appendingPathComponent("src/engine/surface_load.c").path)
    let macroSpawn = try source(root.appendingPathComponent("src/game/macro_special_objects.c").path)

    let macroLines = area1Macro
        .split(separator: "\n")
        .map(String.init)
        .filter { $0.contains("MACRO_OBJECT") && !$0.contains("MACRO_OBJECT_END") }
    guard macroLines.count >= 6,
          macroLines.prefix(6).allSatisfy({ $0.contains("macro_sign_on_wall") }),
          area1Collision.contains("COL_SPECIAL_INIT(11)"),
          area1Collision.components(separatedBy: "SPECIAL_OBJECT").count - 1 == 11,
          area1Collision.contains("special_null_start"),
          macroPresets.contains("{bhvSignOnWall, MODEL_NONE, 0}"),
          surfaceLoad.range(of: "spawn_special_objects(index, &data)")
              .map({ surfaceLoad.distance(from: surfaceLoad.startIndex, to: $0.lowerBound) })
              ?? Int.max
              < (surfaceLoad.range(of: "spawn_macro_objects(index, macroObjects)")
                  .map({ surfaceLoad.distance(from: surfaceLoad.startIndex, to: $0.lowerBound) }) ?? Int.min),
          macroSpawn.contains("spawn_object_abs_with_rot"),
          macroSpawn.contains("preset.behavior") else {
        throw ProofError.invalid("source order or authored behavior mapping missing")
    }

    let records = try arguments.map(parse)
    let identities = Set(records.map(\.identity))
    guard identities.count > 1 else {
        throw ProofError.invalid("pointer-derived identity unexpectedly stable across variants")
    }

    let expectedIdentity = fnv("bhvSignOnWall")
    print("phase85ch_source_behavior=bhvSignOnWall")
    print("phase85ch_source_routes=castle_inside_area1_specials_then_macro_signs")
    print("phase85ch_subject11_mapping=first_macro_sign_after_10_nonnull_special_spawns")
    print("phase85ch_expected_semantic_identity=0x\(String(expectedIdentity, radix: 16))")
    print("phase85ch_pointer_identity_variants=\(identities.count)")
    print("phase85ch_source_bound_identity_emitted=0")
    print("phase85ch_full_trace_c_swift_asan_release_pair=deferred")
    print("phase85ch_canonical_promotion=0")
} catch {
    FileHandle.standardError.write(Data("phase85ch_behavior_identity_proof_failed=\(error)\n".utf8))
    exit(1)
}
