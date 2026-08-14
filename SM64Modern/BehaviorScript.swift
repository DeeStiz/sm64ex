import Foundation

enum SM64BehaviorScriptError: Error, Equatable, Sendable, CustomStringConvertible {
    case emptyProgram
    case unalignedProgram
    case truncatedCommand(offset: Int)
    case unknownOpcode(offset: Int, opcode: UInt8)
    case invalidCommandLength(offset: Int, opcode: UInt8, length: Int)
    case invalidTarget(offset: Int, target: UInt32)

    var description: String {
        switch self {
        case .emptyProgram: "behavior script is empty"
        case .unalignedProgram: "behavior script byte count is not a multiple of four"
        case let .truncatedCommand(offset): "behavior command is truncated at word \(offset)"
        case let .unknownOpcode(offset, opcode): "unknown behavior opcode 0x\(String(format: "%02x", opcode)) at word \(offset)"
        case let .invalidCommandLength(offset, opcode, length): "invalid behavior opcode 0x\(String(format: "%02x", opcode)) length \(length) at word \(offset)"
        case let .invalidTarget(offset, target): "behavior target 0x\(String(format: "%08x", target)) is not a command at word \(offset)"
        }
    }
}

enum SM64BehaviorOpcode: UInt8, CaseIterable, Sendable {
    case begin = 0x00
    case delay = 0x01
    case call = 0x02
    case `return` = 0x03
    case goTo = 0x04
    case beginRepeat = 0x05
    case endRepeat = 0x06
    case endRepeatContinue = 0x07
    case beginLoop = 0x08
    case endLoop = 0x09
    case `break` = 0x0A
    case breakUnused = 0x0B
    case callNative = 0x0C
    case addFloat = 0x0D
    case setFloat = 0x0E
    case addInt = 0x0F
    case setInt = 0x10
    case orInt = 0x11
    case bitClear = 0x12
    case setIntRandomRightShift = 0x13
    case setRandomFloat = 0x14
    case setRandomInt = 0x15
    case addRandomFloat = 0x16
    case addIntRandomRightShift = 0x17
    case nop1 = 0x18
    case nop2 = 0x19
    case nop3 = 0x1A
    case setModel = 0x1B
    case spawnChild = 0x1C
    case deactivate = 0x1D
    case dropToFloor = 0x1E
    case sumFloat = 0x1F
    case sumInt = 0x20
    case billboard = 0x21
    case hide = 0x22
    case setHitbox = 0x23
    case nop4 = 0x24
    case delayVariable = 0x25
    case beginRepeatUnused = 0x26
    case loadAnimations = 0x27
    case animate = 0x28
    case spawnChildWithParam = 0x29
    case loadCollisionData = 0x2A
    case setHitboxWithOffset = 0x2B
    case spawnObject = 0x2C
    case setHome = 0x2D
    case setHurtbox = 0x2E
    case setInteractType = 0x2F
    case setObjectPhysics = 0x30
    case setInteractSubtype = 0x31
    case scale = 0x32
    case parentBitClear = 0x33
    case animateTexture = 0x34
    case disableRendering = 0x35
    case setIntUnused = 0x36
    case spawnWaterDroplet = 0x37
    case cylboard = 0x38
}

struct SM64BehaviorScriptCommand: Equatable, Sendable {
    let wordOffset: Int
    let opcode: SM64BehaviorOpcode
    let words: [UInt32]

    var wordLength: Int { words.count }

    var secondByte: UInt8 { UInt8(truncatingIfNeeded: words[0] >> 16) }
    var thirdByte: UInt8 { UInt8(truncatingIfNeeded: words[0] >> 8) }
    var fourthByte: UInt8 { UInt8(truncatingIfNeeded: words[0]) }
    var firstS16: Int16 { Int16(bitPattern: UInt16(truncatingIfNeeded: words[0])) }
    var secondS16: Int16 { Int16(bitPattern: UInt16(truncatingIfNeeded: words[0] >> 16)) }

    func word(_ index: Int) -> UInt32 { words[index] }
    func highS16(_ index: Int) -> Int16 { Int16(bitPattern: UInt16(truncatingIfNeeded: words[index] >> 16)) }
    func lowS16(_ index: Int) -> Int16 { Int16(bitPattern: UInt16(truncatingIfNeeded: words[index])) }
}

struct SM64BehaviorScriptProgram: Sendable {
    let words: [UInt32]
    let commands: [SM64BehaviorScriptCommand]
    private let offsets: Set<Int>

    init(data: Data) throws {
        guard !data.isEmpty else { throw SM64BehaviorScriptError.emptyProgram }
        guard data.count % 4 == 0 else { throw SM64BehaviorScriptError.unalignedProgram }
        var rawWords: [UInt32] = []
        rawWords.reserveCapacity(data.count / 4)
        for offset in stride(from: 0, to: data.count, by: 4) {
            rawWords.append(
                UInt32(data[offset])
                    | UInt32(data[offset + 1]) << 8
                    | UInt32(data[offset + 2]) << 16
                    | UInt32(data[offset + 3]) << 24
            )
        }
        var cursor = 0
        var decoded: [SM64BehaviorScriptCommand] = []
        while cursor < rawWords.count {
            let opcodeValue = UInt8(truncatingIfNeeded: rawWords[cursor] >> 24)
            guard let opcode = SM64BehaviorOpcode(rawValue: opcodeValue) else {
                throw SM64BehaviorScriptError.unknownOpcode(offset: cursor, opcode: opcodeValue)
            }
            let length = Self.wordLength(opcode: opcode)
            guard length > 0 else { throw SM64BehaviorScriptError.invalidCommandLength(offset: cursor, opcode: opcodeValue, length: length) }
            guard cursor + length <= rawWords.count else { throw SM64BehaviorScriptError.truncatedCommand(offset: cursor) }
            decoded.append(SM64BehaviorScriptCommand(
                wordOffset: cursor,
                opcode: opcode,
                words: Array(rawWords[cursor..<(cursor + length)])
            ))
            cursor += length
        }
        self.words = rawWords
        self.commands = decoded
        self.offsets = Set(decoded.map(\.wordOffset))
    }

    static func wordLength(opcode: SM64BehaviorOpcode) -> Int {
        switch opcode {
        case .call, .goTo, .callNative, .spawnChild, .loadAnimations, .loadCollisionData,
             .spawnObject, .setInteractType, .setInteractSubtype, .parentBitClear,
             .spawnWaterDroplet: return opcode == .spawnChild || opcode == .spawnObject ? 3 : 2
        case .setIntRandomRightShift, .setRandomFloat, .setRandomInt, .addRandomFloat,
             .addIntRandomRightShift, .setHitbox, .setHurtbox,
             .setHitboxWithOffset, .setObjectPhysics, .setIntUnused: break
        default: break
        }
        switch opcode {
        case .setIntRandomRightShift, .setRandomFloat, .setRandomInt, .addRandomFloat,
             .addIntRandomRightShift, .setHitbox, .setHurtbox,
             .setHitboxWithOffset, .setObjectPhysics, .setIntUnused: return opcode == .setObjectPhysics ? 5 : (opcode == .setHitboxWithOffset ? 3 : 2)
        case .spawnChildWithParam: return 3
        default: return 1
        }
    }

    func command(at wordOffset: Int) throws -> SM64BehaviorScriptCommand {
        guard let command = commands.first(where: { $0.wordOffset == wordOffset }) else {
            throw SM64BehaviorScriptError.invalidTarget(offset: wordOffset, target: UInt32(max(0, wordOffset)))
        }
        return command
    }

    func nextOffset(after command: SM64BehaviorScriptCommand) -> Int? {
        let next = command.wordOffset + command.wordLength
        return offsets.contains(next) ? next : nil
    }

    func targetOffset(from command: SM64BehaviorScriptCommand, wordIndex: Int = 1) throws -> Int {
        let target = command.word(wordIndex)
        guard target <= UInt32(Int.max), offsets.contains(Int(target)) else {
            throw SM64BehaviorScriptError.invalidTarget(offset: command.wordOffset, target: target)
        }
        return Int(target)
    }
}

struct SM64BehaviorTargetResolver: Sendable {
    let mappedTargets: [UInt32: Int]

    init(mappedTargets: [UInt32: Int] = [:]) { self.mappedTargets = mappedTargets }

    func targetOffset(from command: SM64BehaviorScriptCommand, in program: SM64BehaviorScriptProgram) throws -> Int {
        let raw = command.word(1)
        if let mapped = mappedTargets[raw] { return mapped }
        return try program.targetOffset(from: command)
    }
}
