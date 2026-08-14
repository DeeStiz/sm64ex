import Foundation

enum SM64LevelScriptError: Error, Equatable, Sendable, CustomStringConvertible {
    case emptyProgram
    case truncatedCommand(offset: Int)
    case invalidCommandSize(offset: Int, sizeUnits: UInt8)
    case unknownOpcode(offset: Int, opcode: UInt8)
    case outOfBounds(offset: Int, logicalOffset: Int, byteCount: Int)
    case invalidTarget(offset: Int, target: UInt64)

    var description: String {
        switch self {
        case .emptyProgram:
            "level script is empty"
        case let .truncatedCommand(offset):
            "level script command is truncated at byte \(offset)"
        case let .invalidCommandSize(offset, sizeUnits):
            "invalid level command size \(sizeUnits) at byte \(offset)"
        case let .unknownOpcode(offset, opcode):
            "unknown level command opcode 0x\(String(format: "%02x", opcode)) at byte \(offset)"
        case let .outOfBounds(offset, logicalOffset, byteCount):
            "level command logical offset \(logicalOffset) is out of bounds at byte \(offset) (\(byteCount) bytes)"
        case let .invalidTarget(offset, target):
            "level command target 0x\(String(format: "%llx", target)) is not a command at byte \(offset)"
        }
    }
}

enum SM64LevelScriptOpcode: UInt8, CaseIterable, Sendable {
    case execute = 0x00
    case exitAndExecute = 0x01
    case exit = 0x02
    case sleep = 0x03
    case sleep2 = 0x04
    case jump = 0x05
    case jumpAndLink = 0x06
    case `return` = 0x07
    case jumpAndLinkPushArg = 0x08
    case jumpRepeat = 0x09
    case loopBegin = 0x0A
    case loopUntil = 0x0B
    case jumpIf = 0x0C
    case jumpAndLinkIf = 0x0D
    case skipIf = 0x0E
    case skip = 0x0F
    case skippableNop = 0x10
    case call = 0x11
    case callLoop = 0x12
    case setRegister = 0x13
    case pushPool = 0x14
    case popPool = 0x15
    case fixedLoad = 0x16
    case loadRaw = 0x17
    case loadMio0 = 0x18
    case loadMarioHead = 0x19
    case loadMio0Texture = 0x1A
    case initLevel = 0x1B
    case clearLevel = 0x1C
    case allocLevelPool = 0x1D
    case freeLevelPool = 0x1E
    case beginArea = 0x1F
    case endArea = 0x20
    case loadModelFromDisplayList = 0x21
    case loadModelFromGeo = 0x22
    case scaleModel = 0x23
    case placeObject = 0x24
    case initMario = 0x25
    case createWarpNode = 0x26
    case createPaintingWarpNode = 0x27
    case createInstantWarp = 0x28
    case loadArea = 0x29
    case unloadArea = 0x2A
    case setMarioStartPosition = 0x2B
    case unloadMarioArea = 0x2C
    case updateObjects = 0x2D
    case setTerrainData = 0x2E
    case setRooms = 0x2F
    case showDialog = 0x30
    case setTerrainType = 0x31
    case nop = 0x32
    case setTransition = 0x33
    case setBlackout = 0x34
    case setGamma = 0x35
    case setMusic = 0x36
    case setMenuMusic = 0x37
    case fadeoutMusic = 0x38
    case setMacroObjects = 0x39
    case setAreaData = 0x3A
    case createWhirlpool = 0x3B
    case getOrSetVariable = 0x3C
    case advanceDemo = 0x3D
    case clearDemoPointer = 0x3E
}

struct SM64LevelScriptCommand: Equatable, Sendable {
    let offset: Int
    let opcode: SM64LevelScriptOpcode
    let sizeUnits: UInt8
    let bytes: Data

    var byteLength: Int {
        Int(sizeUnits) << 1
    }

    /// Logical command fields that contain a script/content target rather than
    /// an inline scalar. The offsets are the C `CMD_GET(void *, offset)`
    /// offsets; callers still decide whether a target is code, geometry, or
    /// another content resource.
    var pointerLogicalOffsets: [Int] {
        switch opcode {
        case .execute: return [4, 8, 12]
        case .exitAndExecute: return [4, 8, 12]
        case .jump, .jumpAndLink: return [4]
        case .jumpIf, .jumpAndLinkIf: return [8]
        case .beginArea: return [4]
        case .loadModelFromDisplayList, .loadModelFromGeo: return [4]
        case .scaleModel: return [4]
        case .placeObject: return [20]
        case .initMario: return [8]
        case .setTerrainData, .setRooms, .setMacroObjects: return [4]
        default: return []
        }
    }

    func readUInt8(logicalOffset: Int) throws -> UInt8 {
        let index = try physicalIndex(logicalOffset, width: 1)
        return bytes[index]
    }

    func readInt8(logicalOffset: Int) throws -> Int8 {
        Int8(bitPattern: try readUInt8(logicalOffset: logicalOffset))
    }

    func readUInt16(logicalOffset: Int) throws -> UInt16 {
        let index = try physicalIndex(logicalOffset, width: 2)
        return UInt16(bytes[index]) | UInt16(bytes[index + 1]) << 8
    }

    func readInt16(logicalOffset: Int) throws -> Int16 {
        Int16(bitPattern: try readUInt16(logicalOffset: logicalOffset))
    }

    func readUInt32(logicalOffset: Int) throws -> UInt32 {
        let index = try physicalIndex(logicalOffset, width: 4)
        return UInt32(bytes[index])
            | UInt32(bytes[index + 1]) << 8
            | UInt32(bytes[index + 2]) << 16
            | UInt32(bytes[index + 3]) << 24
    }

    func readInt32(logicalOffset: Int) throws -> Int32 {
        Int32(bitPattern: try readUInt32(logicalOffset: logicalOffset))
    }

    func readUInt64(logicalOffset: Int) throws -> UInt64 {
        let index = try physicalIndex(logicalOffset, width: 8)
        var value: UInt64 = 0
        for byte in 0..<8 {
            value |= UInt64(bytes[index + byte]) << UInt64(byte * 8)
        }
        return value
    }

    /// C's `CMD_PROCESS_OFFSET` for the 64-bit macOS build. Logical offsets
    /// 0...3 live in the header word; every later four-byte word is an eight
    /// byte host word because pointers are 64-bit.
    func physicalIndex(_ logicalOffset: Int, width: Int = 1) throws -> Int {
        guard logicalOffset >= 0 else {
            throw SM64LevelScriptError.outOfBounds(
                offset: offset,
                logicalOffset: logicalOffset,
                byteCount: bytes.count
            )
        }
        guard width > 0 else {
            throw SM64LevelScriptError.outOfBounds(
                offset: offset,
                logicalOffset: logicalOffset,
                byteCount: bytes.count
            )
        }
        let physical = (logicalOffset & 3) | ((logicalOffset & ~3) << 1)
        guard physical <= bytes.count - width else {
            throw SM64LevelScriptError.outOfBounds(
                offset: offset,
                logicalOffset: logicalOffset,
                byteCount: bytes.count
            )
        }
        return physical
    }
}

/// Resolves the retained 64-bit command-word value to a validated command
/// offset. The default mode accepts the synthetic offset representation used
/// by source-only fixtures; production content supplies explicit segmented
/// mappings from `SM64ContentPackRuntime`.
struct SM64LevelScriptTargetResolver: Sendable {
    let mappedTargets: [UInt64: Int]

    init(mappedTargets: [UInt64: Int] = [:]) {
        self.mappedTargets = mappedTargets
    }

    func targetOffset(
        from command: SM64LevelScriptCommand,
        logicalOffset: Int,
        in program: SM64LevelScriptProgram
    ) throws -> Int {
        let rawTarget = try command.readUInt64(logicalOffset: logicalOffset)
        if let mapped = mappedTargets[rawTarget] {
            return mapped
        }
        return try program.targetOffset(from: command, logicalOffset: logicalOffset)
    }
}

struct SM64LevelScriptProgram: Sendable {
    let data: Data
    let commands: [SM64LevelScriptCommand]
    private let offsets: Set<Int>

    init(data: Data) throws {
        guard !data.isEmpty else { throw SM64LevelScriptError.emptyProgram }
        var cursor = 0
        var decoded: [SM64LevelScriptCommand] = []
        while cursor < data.count {
            guard data.count - cursor >= 2 else {
                throw SM64LevelScriptError.truncatedCommand(offset: cursor)
            }
            let opcodeValue = data[cursor]
            let sizeUnits = data[cursor + 1]
            guard let opcode = SM64LevelScriptOpcode(rawValue: opcodeValue) else {
                throw SM64LevelScriptError.unknownOpcode(offset: cursor, opcode: opcodeValue)
            }
            let byteLength = Int(sizeUnits) << 1
            guard byteLength >= 8, byteLength % 8 == 0 else {
                throw SM64LevelScriptError.invalidCommandSize(offset: cursor, sizeUnits: sizeUnits)
            }
            guard byteLength <= data.count - cursor else {
                throw SM64LevelScriptError.truncatedCommand(offset: cursor)
            }
            let commandData = data.subdata(in: cursor..<(cursor + byteLength))
            decoded.append(SM64LevelScriptCommand(
                offset: cursor,
                opcode: opcode,
                sizeUnits: sizeUnits,
                bytes: commandData
            ))
            cursor += byteLength
        }
        self.data = data
        self.commands = decoded
        self.offsets = Set(decoded.map(\.offset))
    }

    func command(at offset: Int) throws -> SM64LevelScriptCommand {
        guard let command = commands.first(where: { $0.offset == offset }) else {
            throw SM64LevelScriptError.invalidTarget(offset: offset, target: UInt64(max(0, offset)))
        }
        return command
    }

    func nextOffset(after command: SM64LevelScriptCommand) -> Int? {
        let next = command.offset + command.byteLength
        return offsets.contains(next) ? next : nil
    }

    func targetOffset(from command: SM64LevelScriptCommand, logicalOffset: Int) throws -> Int {
        let target = try command.readUInt64(logicalOffset: logicalOffset)
        guard target <= UInt64(Int.max), offsets.contains(Int(target)) else {
            throw SM64LevelScriptError.invalidTarget(offset: command.offset, target: target)
        }
        return Int(target)
    }
}
