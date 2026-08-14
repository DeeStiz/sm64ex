import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
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
    func append(_ bytes: [UInt8]) { data.append(contentsOf: bytes) }
    // SET_REG(7)
    append([0x13, 0x04, 0x07, 0x00, 0, 0, 0, 0])
    // AREA(2, target offset 0x40 / decimal 64)
    append([0x1f, 0x08, 0x02, 0x00, 0, 0, 0, 0, 0x40, 0, 0, 0, 0, 0, 0, 0])
    // WARP_NODE(0x0A, 5, 1, 2, 0x80)
    append([0x26, 0x08, 0x0a, 0x05, 0, 0, 0, 0, 0x01, 0x02, 0x80, 0, 0, 0, 0, 0])
    // TRANSITION(1, 10, 1, 2, 3)
    append([0x33, 0x08, 0x01, 0x0a, 0, 0, 0, 0, 0x01, 0x02, 0x03, 0, 0, 0, 0, 0])
    // END_AREA(), EXIT()
    append([0x20, 0x04, 0, 0, 0, 0, 0, 0])
    append([0x02, 0x04, 0, 0, 0, 0, 0, 0])
    return data
}

@main
enum SM64ModernLevelScriptSmoke {
    static func main() throws {
        let data = fixtureProgram()
        let program = try SM64LevelScriptProgram(data: data)
        require(program.commands.map(\.offset) == [0, 8, 24, 40, 56, 64], "command offsets")
        require(program.commands.map(\.byteLength) == [8, 16, 16, 16, 8, 8], "command lengths")
        require(program.commands.map(\.opcode) == [.setRegister, .beginArea, .createWarpNode, .setTransition, .endArea, .exit], "opcode decode")
        let setRegisterValue = try program.commands[0].readInt16(logicalOffset: 2)
        let areaTarget = try program.commands[1].readUInt64(logicalOffset: 4)
        let warpID = try program.commands[2].readUInt8(logicalOffset: 2)
        let warpLevel = try program.commands[2].readUInt8(logicalOffset: 3)
        let warpArea = try program.commands[2].readUInt8(logicalOffset: 4)
        let warpNode = try program.commands[2].readUInt8(logicalOffset: 5)
        let warpFlags = try program.commands[2].readUInt8(logicalOffset: 6)
        let transitionType = try program.commands[3].readUInt8(logicalOffset: 2)
        let transitionDuration = try program.commands[3].readUInt8(logicalOffset: 3)
        let targetOffset = try program.targetOffset(from: program.commands[1], logicalOffset: 4)
        require(setRegisterValue == 7, "header little-endian argument")
        require(areaTarget == 0x40, "C pointer logical offset")
        require(warpID == 0x0a, "warp id")
        require(warpLevel == 5, "warp destination level")
        require(warpArea == 1, "warp destination area")
        require(warpNode == 2, "warp destination node")
        require(warpFlags == 0x80, "warp flags")
        require(transitionType == 1, "transition type")
        require(transitionDuration == 10, "transition duration")
        require(targetOffset == 64, "target resolution")
        require(program.nextOffset(after: program.commands[4]) == 64, "next command")
        require(program.nextOffset(after: program.commands[5]) == nil, "program terminator")
        do {
            _ = try program.commands[0].readUInt64(logicalOffset: 4)
            preconditionFailure("wide logical read should fail at command boundary")
        } catch let error as SM64LevelScriptError {
            if case .outOfBounds = error {} else { preconditionFailure("wrong wide-read error") }
        }

        var hash = fnvOffset
        for command in program.commands {
            hash = hashU64(hash, UInt64(command.offset))
            hash = hashU64(hash, UInt64(command.opcode.rawValue))
            hash = hashU64(hash, UInt64(command.sizeUnits))
            hash = hashU64(hash, UInt64(command.byteLength))
        }
        hash = hashU64(hash, UInt64(try program.commands[0].readInt16(logicalOffset: 2)))
        hash = hashU64(hash, try program.commands[1].readUInt64(logicalOffset: 4))
        hash = hashU64(hash, UInt64(try program.commands[2].readUInt8(logicalOffset: 2)))
        hash = hashU64(hash, UInt64(try program.commands[2].readUInt8(logicalOffset: 3)))
        hash = hashU64(hash, UInt64(try program.commands[2].readUInt8(logicalOffset: 4)))
        hash = hashU64(hash, UInt64(try program.commands[2].readUInt8(logicalOffset: 5)))
        hash = hashU64(hash, UInt64(try program.commands[2].readUInt8(logicalOffset: 6)))
        hash = hashU64(hash, UInt64(try program.commands[3].readUInt8(logicalOffset: 2)))
        hash = hashU64(hash, UInt64(try program.commands[3].readUInt8(logicalOffset: 3)))
        hash = hashU64(hash, UInt64(try program.commands[3].readUInt8(logicalOffset: 4)))
        hash = hashU64(hash, UInt64(try program.commands[3].readUInt8(logicalOffset: 5)))
        hash = hashU64(hash, UInt64(try program.commands[3].readUInt8(logicalOffset: 6)))
        print(String(format: "levelScriptFingerprint=0x%016llx", hash))

        do {
            _ = try SM64LevelScriptProgram(data: Data([0x13, 0x04, 0x07]))
            preconditionFailure("truncated command should fail")
        } catch let error as SM64LevelScriptError {
            if case .truncatedCommand = error {} else { preconditionFailure("wrong truncation error") }
        }
        do {
            _ = try SM64LevelScriptProgram(data: Data([0x13, 0x03, 0, 0, 0, 0]))
            preconditionFailure("invalid size should fail")
        } catch let error as SM64LevelScriptError {
            if case .invalidCommandSize = error {} else { preconditionFailure("wrong size error") }
        }
        do {
            _ = try SM64LevelScriptProgram(data: Data([0xff, 0x04, 0, 0, 0, 0, 0, 0]))
            preconditionFailure("unknown opcode should fail")
        } catch let error as SM64LevelScriptError {
            if case .unknownOpcode = error {} else { preconditionFailure("wrong opcode error") }
        }
        print("SM64 Modern level-script decoder smoke passed")
    }
}
