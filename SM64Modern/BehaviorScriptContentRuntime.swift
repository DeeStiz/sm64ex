import Foundation

enum SM64BehaviorScriptContentError: Error, Equatable, Sendable, CustomStringConvertible {
    case invalidTargetResource(UInt32)
    case unalignedTarget(UInt32, UInt64)
    case targetOutsideProgram(UInt32, Int)

    var description: String {
        switch self {
        case let .invalidTargetResource(raw):
            "behavior target 0x\(String(format: "%08x", raw)) does not resolve to the requested resource"
        case let .unalignedTarget(raw, offset):
            "behavior target 0x\(String(format: "%08x", raw)) has unaligned resource offset \(offset)"
        case let .targetOutsideProgram(raw, offset):
            "behavior target 0x\(String(format: "%08x", raw)) resolves outside the program at \(offset)"
        }
    }
}

extension SM64ContentPackRuntime {
    func behaviorScript(resource: SM64ContentResourceKey) throws -> SM64BehaviorScriptProgram {
        try SM64BehaviorScriptProgram(data: index.bytes(
            kind: resource.kind,
            relativePath: resource.relativePath
        ))
    }

    /// Resolves only command operands that are behavior pointers. Numeric
    /// object fields and model IDs are intentionally not treated as pointers.
    func behaviorScriptTargetResolver(
        program: SM64BehaviorScriptProgram,
        resource: SM64ContentResourceKey,
        resourceBaseOffset: UInt64 = 0
    ) throws -> SM64BehaviorTargetResolver {
        var mapped: [UInt32: Int] = [:]
        for command in program.commands {
            let pointerWordIndices: [Int]
            switch command.opcode {
            case .call, .goTo, .callNative, .loadAnimations, .loadCollisionData, .spawnWaterDroplet:
                pointerWordIndices = [1]
            case .spawnChild, .spawnObject, .spawnChildWithParam:
                pointerWordIndices = [2]
            default:
                pointerWordIndices = []
            }
            for wordIndex in pointerWordIndices where wordIndex < command.words.count {
                let raw = command.word(wordIndex)
                guard raw != 0 else { continue }
                let resolved: SM64ResolvedSegmentAddress
                do {
                    resolved = try resolve(rawAddress: raw)
                } catch SM64ContentPackError.unknownSegment {
                    continue
                }
                guard resolved.resource == resource else {
                    throw SM64BehaviorScriptContentError.invalidTargetResource(raw)
                }
                guard resolved.resourceOffset >= resourceBaseOffset else {
                    throw SM64BehaviorScriptContentError.targetOutsideProgram(raw, Int(resolved.resourceOffset))
                }
                let byteOffset = resolved.resourceOffset - resourceBaseOffset
                guard byteOffset % 4 == 0 else {
                    throw SM64BehaviorScriptContentError.unalignedTarget(raw, resolved.resourceOffset)
                }
                let target = byteOffset / 4
                guard target <= UInt64(Int.max), program.commands.contains(where: { $0.wordOffset == Int(target) }) else {
                    throw SM64BehaviorScriptContentError.targetOutsideProgram(raw, Int(min(byteOffset, UInt64(Int.max))))
                }
                mapped[raw] = Int(target)
            }
        }
        return SM64BehaviorTargetResolver(mappedTargets: mapped)
    }
}
