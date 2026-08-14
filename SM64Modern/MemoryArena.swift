import Foundation

enum SM64MemoryArenaError: Error, Equatable, Sendable, CustomStringConvertible {
    case invalidSize(Int)
    case invalidAlignment(Int)
    case outOfMemory(requested: Int, available: Int)
    case invalidMark
    case invalidAllocation

    var description: String {
        switch self {
        case let .invalidSize(size):
            "invalid arena size \(size)"
        case let .invalidAlignment(alignment):
            "invalid arena alignment \(alignment)"
        case let .outOfMemory(requested, available):
            "arena out of memory (requested=\(requested), available=\(available))"
        case .invalidMark:
            "invalid arena mark"
        case .invalidAllocation:
            "invalid arena allocation"
        }
    }
}

struct SM64ArenaMark: Hashable, Sendable {
    fileprivate let generation: UInt32
    fileprivate let offset: Int
}

struct SM64ArenaAllocation: Hashable, Sendable {
    let generation: UInt32
    let offset: Int
    let byteCount: Int
    let reservedByteCount: Int
    fileprivate let token: UInt64
}

struct SM64ArenaSnapshot: Equatable, Sendable {
    let generation: UInt32
    let capacity: Int
    let usedBytes: Int

    var remainingBytes: Int {
        capacity - usedBytes
    }
}

private func sm64NextGeneration(_ generation: UInt32) -> UInt32 {
    generation == UInt32.max ? 1 : generation + 1
}

/// Model of the C `AllocOnlyPool`. C rounds every allocation to four bytes and
/// never frees individual allocations; the Swift owner-thread model also
/// supports marks so a level/script transaction can roll back before commit.
final class SM64LinearArena {
    private struct Range {
        let offset: Int
        let end: Int
    }

    let capacity: Int
    private(set) var usedBytes: Int = 0
    private var generation: UInt32 = 1
    private var nextToken: UInt64 = 1
    private var allocations: [UInt64: Range] = [:]

    init(capacity: Int) {
        precondition(capacity > 0)
        self.capacity = capacity
    }

    var remainingBytes: Int {
        capacity - usedBytes
    }

    func mark() -> SM64ArenaMark {
        SM64ArenaMark(generation: generation, offset: usedBytes)
    }

    func allocate(byteCount: Int, alignment: Int = 4) throws -> SM64ArenaAllocation {
        guard byteCount > 0 else { throw SM64MemoryArenaError.invalidSize(byteCount) }
        guard alignment > 0, alignment & (alignment - 1) == 0 else {
            throw SM64MemoryArenaError.invalidAlignment(alignment)
        }
        guard let reservedByteCount = sm64AlignUpChecked(byteCount, alignment: alignment) else {
            throw SM64MemoryArenaError.invalidSize(byteCount)
        }
        guard let offset = sm64AlignUpChecked(usedBytes, alignment: alignment) else {
            throw SM64MemoryArenaError.invalidAlignment(alignment)
        }
        guard offset <= capacity, reservedByteCount <= capacity - offset else {
            throw SM64MemoryArenaError.outOfMemory(
                requested: reservedByteCount,
                available: max(0, capacity - offset)
            )
        }

        let token = nextToken
        nextToken &+= 1
        let end = offset + reservedByteCount
        allocations[token] = Range(offset: offset, end: end)
        usedBytes = end
        return SM64ArenaAllocation(
            generation: generation,
            offset: offset,
            byteCount: byteCount,
            reservedByteCount: reservedByteCount,
            token: token
        )
    }

    func rewind(to mark: SM64ArenaMark) throws {
        guard mark.generation == generation, mark.offset >= 0, mark.offset <= usedBytes else {
            throw SM64MemoryArenaError.invalidMark
        }
        allocations = allocations.filter { $0.value.end <= mark.offset }
        usedBytes = mark.offset
    }

    func contains(_ allocation: SM64ArenaAllocation) -> Bool {
        guard allocation.generation == generation,
              let range = allocations[allocation.token] else { return false }
        return range.offset == allocation.offset
            && range.end == allocation.offset + allocation.reservedByteCount
    }

    func snapshot() -> SM64ArenaSnapshot {
        SM64ArenaSnapshot(generation: generation, capacity: capacity, usedBytes: usedBytes)
    }

    func reset() {
        generation = sm64NextGeneration(generation)
        usedBytes = 0
        nextToken = 1
        allocations.removeAll(keepingCapacity: true)
    }
}

/// Model of the C `MemoryPool` used for object-owned chain segments and
/// effects. The C implementation is a first-fit free list with a 16-byte
/// `MemoryBlock` header on the 64-bit macOS target, four-byte payload rounding,
/// arbitrary-order free, and adjacent-block coalescing.
final class SM64FreeListArena {
    static let cMemoryBlockHeaderBytes = 16

    private struct Block: Equatable {
        var offset: Int
        var byteCount: Int
    }

    private struct AllocationRecord {
        let block: Block
        let payloadOffset: Int
        let byteCount: Int
    }

    let capacity: Int
    private(set) var usedBytes: Int = 0
    private var generation: UInt32 = 1
    private var nextToken: UInt64 = 1
    private var freeBlocks: [Block]
    private var allocations: [UInt64: AllocationRecord] = [:]

    init(capacity: Int) {
        precondition(capacity > SM64FreeListArena.cMemoryBlockHeaderBytes)
        self.capacity = capacity
        self.freeBlocks = [Block(offset: 0, byteCount: capacity)]
    }

    var remainingBytes: Int {
        capacity - usedBytes
    }

    func allocate(byteCount: Int) throws -> SM64ArenaAllocation {
        guard byteCount > 0 else { throw SM64MemoryArenaError.invalidSize(byteCount) }
        guard let alignedPayload = sm64AlignUpChecked(byteCount, alignment: 4) else {
            throw SM64MemoryArenaError.invalidSize(byteCount)
        }
        let required = SM64FreeListArena.cMemoryBlockHeaderBytes + alignedPayload

        guard let blockIndex = freeBlocks.firstIndex(where: { $0.byteCount >= required }) else {
            throw SM64MemoryArenaError.outOfMemory(requested: required, available: largestFreeBlock)
        }

        let block = freeBlocks[blockIndex]
        let remainder = block.byteCount - required
        let consumed = remainder <= SM64FreeListArena.cMemoryBlockHeaderBytes
            ? block.byteCount : required
        if consumed == block.byteCount {
            freeBlocks.remove(at: blockIndex)
        } else {
            freeBlocks[blockIndex] = Block(
                offset: block.offset + consumed,
                byteCount: block.byteCount - consumed
            )
        }

        let token = nextToken
        nextToken &+= 1
        let allocationBlock = Block(offset: block.offset, byteCount: consumed)
        let payloadOffset = block.offset + SM64FreeListArena.cMemoryBlockHeaderBytes
        allocations[token] = AllocationRecord(
            block: allocationBlock,
            payloadOffset: payloadOffset,
            byteCount: byteCount
        )
        usedBytes += consumed
        return SM64ArenaAllocation(
            generation: generation,
            offset: payloadOffset,
            byteCount: byteCount,
            reservedByteCount: consumed,
            token: token
        )
    }

    @discardableResult
    func free(_ allocation: SM64ArenaAllocation) -> Bool {
        guard allocation.generation == generation,
              let record = allocations.removeValue(forKey: allocation.token),
              record.payloadOffset == allocation.offset else { return false }
        usedBytes -= record.block.byteCount
        insertAndCoalesce(record.block)
        return true
    }

    func contains(_ allocation: SM64ArenaAllocation) -> Bool {
        guard allocation.generation == generation,
              let record = allocations[allocation.token] else { return false }
        return record.payloadOffset == allocation.offset
    }

    func snapshot() -> SM64ArenaSnapshot {
        SM64ArenaSnapshot(generation: generation, capacity: capacity, usedBytes: usedBytes)
    }

    func reset() {
        generation = sm64NextGeneration(generation)
        usedBytes = 0
        nextToken = 1
        allocations.removeAll(keepingCapacity: true)
        freeBlocks = [Block(offset: 0, byteCount: capacity)]
    }

    private var largestFreeBlock: Int {
        freeBlocks.map(\.byteCount).max() ?? 0
    }

    private func insertAndCoalesce(_ block: Block) {
        freeBlocks.append(block)
        freeBlocks.sort { $0.offset < $1.offset }
        var coalesced: [Block] = []
        for candidate in freeBlocks {
            guard let last = coalesced.last else {
                coalesced.append(candidate)
                continue
            }
            if last.offset + last.byteCount == candidate.offset {
                coalesced[coalesced.count - 1] = Block(
                    offset: last.offset,
                    byteCount: last.byteCount + candidate.byteCount
                )
            } else {
                coalesced.append(candidate)
            }
        }
        freeBlocks = coalesced
    }
}

private func sm64AlignUpChecked(_ value: Int, alignment: Int) -> Int? {
    guard value >= 0, alignment > 0 else { return nil }
    let remainder = value % alignment
    let padding = remainder == 0 ? 0 : alignment - remainder
    return value <= Int.max - padding ? value + padding : nil
}

struct SM64EngineArenaCapacities: Sendable {
    var level: Int
    var object: Int
    var effects: Int

    static let cDefaults = SM64EngineArenaCapacities(
        level: 1 << 20,
        object: 0x800,
        effects: 0x4000
    )
}

final class SM64EngineArenas {
    let level: SM64LinearArena
    let object: SM64FreeListArena
    let effects: SM64FreeListArena

    init(capacities: SM64EngineArenaCapacities = .cDefaults) {
        self.level = SM64LinearArena(capacity: capacities.level)
        self.object = SM64FreeListArena(capacity: capacities.object)
        self.effects = SM64FreeListArena(capacity: capacities.effects)
    }

    func resetAll() {
        level.reset()
        object.reset()
        effects.reset()
    }
}
