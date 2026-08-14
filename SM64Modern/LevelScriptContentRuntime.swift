import Foundation

enum SM64LevelScriptContentError: Error, Equatable, Sendable, CustomStringConvertible {
    case invalidTargetResource(UInt64)
    case targetOutsideProgram(UInt64, Int)

    var description: String {
        switch self {
        case let .invalidTargetResource(raw):
            "level-script target 0x\(String(format: "%llx", raw)) does not resolve to the requested resource"
        case let .targetOutsideProgram(raw, offset):
            "level-script target 0x\(String(format: "%llx", raw)) resolves outside the program at \(offset)"
        }
    }
}

extension SM64ContentPackRuntime {
    /// Builds a target map for a script whose command-word pointers contain
    /// N64-style segmented addresses. Only targets that resolve into the
    /// supplied script resource are accepted; zero/null pointers are ignored.
    func levelScriptTargetResolver(
        program: SM64LevelScriptProgram,
        resource: SM64ContentResourceKey,
        resourceBaseOffset: UInt64 = 0
    ) throws -> SM64LevelScriptTargetResolver {
        var mapped: [UInt64: Int] = [:]
        for command in program.commands {
            for logicalOffset in command.pointerLogicalOffsets {
                let raw = try command.readUInt64(logicalOffset: logicalOffset)
                guard raw != 0 else { continue }
                guard raw <= UInt64(UInt32.max) else { continue }
                let resolved: SM64ResolvedSegmentAddress
                do {
                    resolved = try resolve(rawAddress: UInt32(raw))
                } catch SM64ContentPackError.unknownSegment {
                    continue
                }
                guard resolved.resource == resource else {
                    throw SM64LevelScriptContentError.invalidTargetResource(raw)
                }
                guard resolved.resourceOffset >= resourceBaseOffset else {
                    throw SM64LevelScriptContentError.targetOutsideProgram(
                        raw,
                        Int(resolved.resourceOffset)
                    )
                }
                let targetOffset = resolved.resourceOffset - resourceBaseOffset
                guard targetOffset <= UInt64(Int.max) else {
                    throw SM64LevelScriptContentError.targetOutsideProgram(raw, Int.max)
                }
                let target = Int(targetOffset)
                guard program.commands.contains(where: { $0.offset == target }) else {
                    throw SM64LevelScriptContentError.targetOutsideProgram(raw, target)
                }
                mapped[raw] = target
            }
        }
        return SM64LevelScriptTargetResolver(mappedTargets: mapped)
    }

    func levelScript(
        resource: SM64ContentResourceKey
    ) throws -> SM64LevelScriptProgram {
        try SM64LevelScriptProgram(data: index.bytes(
            kind: resource.kind,
            relativePath: resource.relativePath
        ))
    }
}
