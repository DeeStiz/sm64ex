import Foundation

enum SM64LevelScriptVMStatus: Int8, Equatable, Sendable {
    case paused2 = -1
    case paused = 0
    case running = 1
    case halted = 2
}

enum SM64LevelScriptVMError: Error, Equatable, Sendable, CustomStringConvertible {
    case halted
    case invalidStart(Int)
    case stackOverflow
    case stackUnderflow
    case loopStackUnderflow
    case stepLimitExceeded(Int)
    case missingCallHandler(Int16)
    case unsupportedCommand(SM64LevelScriptOpcode)

    var description: String {
        switch self {
        case .halted:
            "level-script VM is halted"
        case let .invalidStart(offset):
            "level-script VM start offset \(offset) is invalid"
        case .stackOverflow:
            "level-script VM stack overflow"
        case .stackUnderflow:
            "level-script VM stack underflow"
        case .loopStackUnderflow:
            "level-script VM loop stack underflow"
        case let .stepLimitExceeded(limit):
            "level-script VM exceeded the per-tick command limit \(limit)"
        case let .missingCallHandler(argument):
            "level-script CALL has no deterministic handler for argument \(argument)"
        case let .unsupportedCommand(opcode):
            "level-script command \(opcode) is not supported by this VM mode"
        }
    }
}

struct SM64LevelScriptWarpRecord: Equatable, Sendable {
    let id: UInt8
    let destinationLevel: UInt16
    let destinationArea: UInt8
    let destinationNode: UInt8
    let flags: UInt8
    let painting: Bool
}

struct SM64LevelScriptInstantWarpRecord: Equatable, Sendable {
    let id: UInt8
    let destinationArea: UInt8
    let displacement: (Int16, Int16, Int16)

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
            && lhs.destinationArea == rhs.destinationArea
            && lhs.displacement.0 == rhs.displacement.0
            && lhs.displacement.1 == rhs.displacement.1
            && lhs.displacement.2 == rhs.displacement.2
    }
}

struct SM64LevelScriptTransitionRecord: Equatable, Sendable {
    let type: UInt8
    let duration: UInt8
    let red: UInt8
    let green: UInt8
    let blue: UInt8
}

struct SM64LevelScriptMarioStart: Equatable, Sendable {
    var area: UInt8
    var yaw: Int16
    var position: (Int16, Int16, Int16)

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.area == rhs.area
            && lhs.yaw == rhs.yaw
            && lhs.position.0 == rhs.position.0
            && lhs.position.1 == rhs.position.1
            && lhs.position.2 == rhs.position.2
    }
}

struct SM64LevelScriptCommandTrace: Equatable, Sendable {
    let tick: UInt32
    let executedOffset: Int
    let executedOpcode: UInt8
    let executedSizeUnits: UInt8
    let register: Int32
    let level: Int16
    let globalArea: Int16
    let status: SM64LevelScriptVMStatus
    let nextOffset: Int?
}

struct SM64LevelScriptVMSnapshot: Equatable, Sendable {
    let status: SM64LevelScriptVMStatus
    let currentOffset: Int?
    let register: Int32
    let level: Int16
    let course: Int16
    let act: Int16
    let saveFile: Int16
    let globalArea: Int16
    let activeArea: Int16
    let delayFrames: UInt16
    let delayFrames2: UInt16
    let stackDepth: Int
    let loopDepth: Int
    let commandCount: UInt64
    let transitions: [SM64LevelScriptTransitionRecord]
    let warps: [SM64LevelScriptWarpRecord]
    let paintingWarps: [SM64LevelScriptWarpRecord]
    let instantWarps: [SM64LevelScriptInstantWarpRecord]
    let marioStart: SM64LevelScriptMarioStart?
    let terrainType: Int16
    let dialog: (UInt8, UInt8)
    let music: (Int16, Int16)
    let blackout: UInt8
    let gamma: UInt8

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.status == rhs.status
            && lhs.currentOffset == rhs.currentOffset
            && lhs.register == rhs.register
            && lhs.level == rhs.level
            && lhs.course == rhs.course
            && lhs.act == rhs.act
            && lhs.saveFile == rhs.saveFile
            && lhs.globalArea == rhs.globalArea
            && lhs.activeArea == rhs.activeArea
            && lhs.delayFrames == rhs.delayFrames
            && lhs.delayFrames2 == rhs.delayFrames2
            && lhs.stackDepth == rhs.stackDepth
            && lhs.loopDepth == rhs.loopDepth
            && lhs.commandCount == rhs.commandCount
            && lhs.transitions == rhs.transitions
            && lhs.warps == rhs.warps
            && lhs.paintingWarps == rhs.paintingWarps
            && lhs.instantWarps == rhs.instantWarps
            && lhs.marioStart == rhs.marioStart
            && lhs.terrainType == rhs.terrainType
            && lhs.dialog.0 == rhs.dialog.0
            && lhs.dialog.1 == rhs.dialog.1
            && lhs.music.0 == rhs.music.0
            && lhs.music.1 == rhs.music.1
            && lhs.blackout == rhs.blackout
            && lhs.gamma == rhs.gamma
    }
}

struct SM64LevelScriptVM: Sendable {
    private struct LoopFrame: Sendable {
        let targetOffset: Int
    }

    private static let defaultDemoLevels: [Int32] = [22, 9, 13, 8, 7, 6, 23]
    private static let stackCapacity = 32

    let program: SM64LevelScriptProgram
    let strictUnsupportedCommands: Bool
    let callHandler: (@Sendable (Int16, Int32) -> Int32)?

    private(set) var status: SM64LevelScriptVMStatus = .running
    private(set) var currentOffset: Int?
    private(set) var register: Int32 = 0
    private(set) var level: Int16 = 0
    private(set) var course: Int16 = 0
    private(set) var act: Int16 = 1
    private(set) var saveFile: Int16 = 0
    private(set) var globalArea: Int16 = 0
    private(set) var activeArea: Int16 = -1
    private(set) var delayFrames: UInt16 = 0
    private(set) var delayFrames2: UInt16 = 0
    private(set) var commandCount: UInt64 = 0
    private(set) var tickCount: UInt32 = 0
    private(set) var traces: [SM64LevelScriptCommandTrace] = []
    private(set) var transitions: [SM64LevelScriptTransitionRecord] = []
    private(set) var warps: [SM64LevelScriptWarpRecord] = []
    private(set) var paintingWarps: [SM64LevelScriptWarpRecord] = []
    private(set) var instantWarps: [SM64LevelScriptInstantWarpRecord] = []
    private(set) var marioStart: SM64LevelScriptMarioStart?
    private(set) var terrainType: Int16 = 0
    private(set) var dialog: (UInt8, UInt8) = (0, 0)
    private(set) var music: (Int16, Int16) = (0, 0)
    private(set) var blackout: UInt8 = 0
    private(set) var gamma: UInt8 = 0
    private(set) var pressedStart: Int32 = 0
    private var stack: [Int64] = []
    private var loopStack: [LoopFrame] = []
    private var demoLevelIndex: Int = 0
    private var demoLevels: [Int32]

    init(
        program: SM64LevelScriptProgram,
        startOffset: Int = 0,
        strictUnsupportedCommands: Bool = false,
        callHandler: (@Sendable (Int16, Int32) -> Int32)? = nil,
        demoLevels: [Int32] = SM64LevelScriptVM.defaultDemoLevels
    ) throws {
        guard program.commands.contains(where: { $0.offset == startOffset }) else {
            throw SM64LevelScriptVMError.invalidStart(startOffset)
        }
        self.program = program
        self.currentOffset = startOffset
        self.strictUnsupportedCommands = strictUnsupportedCommands
        self.callHandler = callHandler
        self.demoLevels = demoLevels.isEmpty ? SM64LevelScriptVM.defaultDemoLevels : demoLevels
    }

    var snapshot: SM64LevelScriptVMSnapshot {
        SM64LevelScriptVMSnapshot(
            status: status,
            currentOffset: currentOffset,
            register: register,
            level: level,
            course: course,
            act: act,
            saveFile: saveFile,
            globalArea: globalArea,
            activeArea: activeArea,
            delayFrames: delayFrames,
            delayFrames2: delayFrames2,
            stackDepth: stack.count,
            loopDepth: loopStack.count,
            commandCount: commandCount,
            transitions: transitions,
            warps: warps,
            paintingWarps: paintingWarps,
            instantWarps: instantWarps,
            marioStart: marioStart,
            terrainType: terrainType,
            dialog: dialog,
            music: music,
            blackout: blackout,
            gamma: gamma
        )
    }

    mutating func setInitialGlobals(
        level: Int16,
        course: Int16,
        act: Int16,
        saveFile: Int16,
        globalArea: Int16,
        pressedStart: Int32 = 0
    ) {
        self.level = level
        self.course = course
        self.act = act
        self.saveFile = saveFile
        self.globalArea = globalArea
        self.pressedStart = pressedStart
    }

    mutating func executeTick(commandLimit: Int = 10_000) throws {
        guard status != .halted, currentOffset != nil else { return }
        guard commandLimit > 0 else { throw SM64LevelScriptVMError.stepLimitExceeded(commandLimit) }
        tickCount &+= 1
        status = .running
        var executed = 0
        while status == .running, let offset = currentOffset {
            guard executed < commandLimit else {
                throw SM64LevelScriptVMError.stepLimitExceeded(commandLimit)
            }
            executed += 1
            let command = try program.command(at: offset)
            try execute(command)
            commandCount &+= 1
            let nextOpcode = currentOffset.flatMap { try? program.command(at: $0).opcode.rawValue }
            traces.append(SM64LevelScriptCommandTrace(
                tick: tickCount,
                executedOffset: command.offset,
                executedOpcode: command.opcode.rawValue,
                executedSizeUnits: command.sizeUnits,
                register: register,
                level: level,
                globalArea: globalArea,
                status: status,
                nextOffset: currentOffset
            ))
            _ = nextOpcode
        }
    }

    mutating func runToHalt(commandLimitPerTick: Int = 10_000, tickLimit: Int = 100_000) throws {
        guard tickLimit > 0 else { throw SM64LevelScriptVMError.stepLimitExceeded(tickLimit) }
        var ticks = 0
        while status != .halted && ticks < tickLimit {
            try executeTick(commandLimit: commandLimitPerTick)
            ticks += 1
        }
        if status != .halted {
            throw SM64LevelScriptVMError.stepLimitExceeded(tickLimit)
        }
    }

    private mutating func execute(_ command: SM64LevelScriptCommand) throws {
        switch command.opcode {
        case .execute:
            try push(Int64(command.offset + command.byteLength))
            try jump(to: command, logicalOffset: 12)
        case .exitAndExecute:
            stack.removeAll(keepingCapacity: true)
            try jump(to: command, logicalOffset: 12)
        case .exit:
            if let target = stack.popLast() {
                currentOffset = Int(target)
            } else {
                currentOffset = nil
                status = .halted
            }
        case .sleep:
            status = .paused
            if delayFrames == 0 {
                delayFrames = try command.readUInt16(logicalOffset: 2)
            } else if delayFrames &- 1 == 0 {
                delayFrames = 0
                currentOffset = nextOffset(after: command)
                status = .running
            } else {
                delayFrames &-= 1
            }
        case .sleep2:
            status = .paused2
            if delayFrames2 == 0 {
                delayFrames2 = try command.readUInt16(logicalOffset: 2)
            } else if delayFrames2 &- 1 == 0 {
                delayFrames2 = 0
                currentOffset = nextOffset(after: command)
                status = .running
            } else {
                delayFrames2 &-= 1
            }
        case .jump:
            try jump(to: command, logicalOffset: 4)
        case .jumpAndLink:
            try push(Int64(command.offset + command.byteLength))
            try jump(to: command, logicalOffset: 4)
        case .return:
            guard let target = stack.popLast() else { throw SM64LevelScriptVMError.stackUnderflow }
            currentOffset = Int(target)
        case .jumpAndLinkPushArg:
            try push(Int64(command.offset + command.byteLength))
            try push(Int64(try command.readInt16(logicalOffset: 2)))
            currentOffset = nextOffset(after: command)
        case .jumpRepeat:
            guard stack.count >= 2 else { throw SM64LevelScriptVMError.stackUnderflow }
            let countIndex = stack.count - 1
            let target = Int(stack[stack.count - 2])
            let value = stack[countIndex]
            if value == 0 {
                currentOffset = target
            } else if value - 1 != 0 {
                stack[countIndex] = value - 1
                currentOffset = target
            } else {
                stack.removeLast(2)
                currentOffset = nextOffset(after: command)
            }
        case .loopBegin:
            guard loopStack.count < Self.stackCapacity else { throw SM64LevelScriptVMError.stackOverflow }
            loopStack.append(LoopFrame(targetOffset: command.offset + command.byteLength))
            currentOffset = nextOffset(after: command)
        case .loopUntil:
            guard let frame = loopStack.last else { throw SM64LevelScriptVMError.loopStackUnderflow }
            if evaluate(op: try command.readUInt8(logicalOffset: 2), argument: try command.readInt32(logicalOffset: 4)) {
                loopStack.removeLast()
                currentOffset = nextOffset(after: command)
            } else {
                currentOffset = frame.targetOffset
            }
        case .jumpIf:
            if evaluate(op: try command.readUInt8(logicalOffset: 2), argument: try command.readInt32(logicalOffset: 4)) {
                try jump(to: command, logicalOffset: 8)
            } else {
                currentOffset = nextOffset(after: command)
            }
        case .jumpAndLinkIf:
            if evaluate(op: try command.readUInt8(logicalOffset: 2), argument: try command.readInt32(logicalOffset: 4)) {
                try push(Int64(command.offset + command.byteLength))
                try jump(to: command, logicalOffset: 8)
            } else {
                currentOffset = nextOffset(after: command)
            }
        case .skipIf:
            if !evaluate(op: try command.readUInt8(logicalOffset: 2), argument: try command.readInt32(logicalOffset: 4)) {
                var cursor = nextOffset(after: command)
                while let next = cursor {
                    let nextCommand = try program.command(at: next)
                    cursor = nextCommand.opcode == .skip || nextCommand.opcode == .skippableNop
                        ? nextOffset(after: nextCommand)
                        : next
                    if nextCommand.opcode != .skip && nextCommand.opcode != .skippableNop { break }
                }
                currentOffset = cursor.flatMap { try? program.command(at: $0).offset }
            }
            if let offset = currentOffset {
                currentOffset = nextOffset(after: try program.command(at: offset))
            }
        case .skip:
            var cursor = nextOffset(after: command)
            while let next = cursor, try program.command(at: next).opcode == .skippableNop {
                cursor = nextOffset(after: try program.command(at: next))
            }
            currentOffset = cursor.flatMap { try? nextOffset(after: program.command(at: $0)) } ?? nil
        case .skippableNop:
            currentOffset = nextOffset(after: command)
        case .call:
            guard let callHandler else { throw SM64LevelScriptVMError.missingCallHandler(try command.readInt16(logicalOffset: 2)) }
            register = callHandler(try command.readInt16(logicalOffset: 2), register)
            currentOffset = nextOffset(after: command)
        case .callLoop:
            guard let callHandler else { throw SM64LevelScriptVMError.missingCallHandler(try command.readInt16(logicalOffset: 2)) }
            register = callHandler(try command.readInt16(logicalOffset: 2), register)
            if register == 0 {
                status = .paused
            } else {
                currentOffset = nextOffset(after: command)
            }
        case .setRegister:
            register = Int32(try command.readInt16(logicalOffset: 2))
            currentOffset = nextOffset(after: command)
        case .pushPool, .popPool, .fixedLoad, .loadRaw, .loadMio0, .loadMarioHead,
             .loadMio0Texture, .initLevel, .clearLevel, .allocLevelPool, .freeLevelPool,
             .loadModelFromDisplayList, .loadModelFromGeo, .scaleModel, .placeObject,
             .initMario, .loadArea, .unloadArea, .unloadMarioArea, .updateObjects,
             .setTerrainData, .setRooms, .setMacroObjects, .setAreaData, .createWhirlpool:
            if strictUnsupportedCommands { throw SM64LevelScriptVMError.unsupportedCommand(command.opcode) }
            currentOffset = nextOffset(after: command)
        case .beginArea:
            activeArea = Int16(try command.readUInt8(logicalOffset: 2))
            currentOffset = nextOffset(after: command)
        case .endArea:
            activeArea = -1
            currentOffset = nextOffset(after: command)
        case .createWarpNode:
            if activeArea >= 0 {
                let flags = try command.readUInt8(logicalOffset: 6)
                warps.append(SM64LevelScriptWarpRecord(
                    id: try command.readUInt8(logicalOffset: 2),
                    destinationLevel: UInt16(try command.readUInt8(logicalOffset: 3)) + UInt16(flags),
                    destinationArea: try command.readUInt8(logicalOffset: 4),
                    destinationNode: try command.readUInt8(logicalOffset: 5),
                    flags: flags,
                    painting: false
                ))
            }
            currentOffset = nextOffset(after: command)
        case .createPaintingWarpNode:
            if activeArea >= 0 {
                let flags = try command.readUInt8(logicalOffset: 6)
                paintingWarps.append(SM64LevelScriptWarpRecord(
                    id: try command.readUInt8(logicalOffset: 2),
                    destinationLevel: UInt16(try command.readUInt8(logicalOffset: 3)) + UInt16(flags),
                    destinationArea: try command.readUInt8(logicalOffset: 4),
                    destinationNode: try command.readUInt8(logicalOffset: 5),
                    flags: flags,
                    painting: true
                ))
            }
            currentOffset = nextOffset(after: command)
        case .createInstantWarp:
            if activeArea >= 0 {
                instantWarps.append(SM64LevelScriptInstantWarpRecord(
                    id: try command.readUInt8(logicalOffset: 2),
                    destinationArea: try command.readUInt8(logicalOffset: 3),
                    displacement: (
                        try command.readInt16(logicalOffset: 4),
                        try command.readInt16(logicalOffset: 6),
                        try command.readInt16(logicalOffset: 8)
                    )
                ))
            }
            currentOffset = nextOffset(after: command)
        case .setMarioStartPosition:
            marioStart = SM64LevelScriptMarioStart(
                area: try command.readUInt8(logicalOffset: 2),
                yaw: try command.readInt16(logicalOffset: 4),
                position: (
                    try command.readInt16(logicalOffset: 6),
                    try command.readInt16(logicalOffset: 8),
                    try command.readInt16(logicalOffset: 10)
                )
            )
            currentOffset = nextOffset(after: command)
        case .setTerrainType:
            if activeArea >= 0 { terrainType |= try command.readInt16(logicalOffset: 2) }
            currentOffset = nextOffset(after: command)
        case .showDialog:
            let index = try command.readUInt8(logicalOffset: 2)
            if index < 2 {
                if index == 0 { dialog.0 = try command.readUInt8(logicalOffset: 3) }
                else { dialog.1 = try command.readUInt8(logicalOffset: 3) }
            }
            currentOffset = nextOffset(after: command)
        case .setTransition:
            transitions.append(SM64LevelScriptTransitionRecord(
                type: try command.readUInt8(logicalOffset: 2),
                duration: try command.readUInt8(logicalOffset: 3),
                red: try command.readUInt8(logicalOffset: 4),
                green: try command.readUInt8(logicalOffset: 5),
                blue: try command.readUInt8(logicalOffset: 6)
            ))
            currentOffset = nextOffset(after: command)
        case .setBlackout:
            blackout = try command.readUInt8(logicalOffset: 2)
            currentOffset = nextOffset(after: command)
        case .setGamma:
            gamma = try command.readUInt8(logicalOffset: 2)
            currentOffset = nextOffset(after: command)
        case .setMusic:
            music = (try command.readInt16(logicalOffset: 2), try command.readInt16(logicalOffset: 4))
            currentOffset = nextOffset(after: command)
        case .setMenuMusic, .fadeoutMusic, .nop:
            currentOffset = nextOffset(after: command)
        case .getOrSetVariable:
            let operation = try command.readUInt8(logicalOffset: 2)
            let variable = try command.readUInt8(logicalOffset: 3)
            if operation == 0 {
                switch variable {
                case 0: saveFile = Int16(truncatingIfNeeded: register)
                case 1: course = Int16(truncatingIfNeeded: register)
                case 2: act = Int16(truncatingIfNeeded: register)
                case 3: level = Int16(truncatingIfNeeded: register)
                case 4: globalArea = Int16(truncatingIfNeeded: register)
                case 5: pressedStart = register
                default: break
                }
            } else {
                switch variable {
                case 0: register = Int32(saveFile)
                case 1: register = Int32(course)
                case 2: register = Int32(act)
                case 3: register = Int32(level)
                case 4: register = Int32(globalArea)
                case 5: register = pressedStart
                default: break
                }
            }
            currentOffset = nextOffset(after: command)
        case .advanceDemo:
            register = demoLevels[demoLevelIndex]
            demoLevelIndex = (demoLevelIndex + 1) % demoLevels.count
            currentOffset = nextOffset(after: command)
        case .clearDemoPointer:
            currentOffset = nextOffset(after: command)
        }
    }

    private func nextOffset(after command: SM64LevelScriptCommand) -> Int? {
        program.nextOffset(after: command)
    }

    private mutating func jump(to command: SM64LevelScriptCommand, logicalOffset: Int) throws {
        currentOffset = try program.targetOffset(from: command, logicalOffset: logicalOffset)
    }

    private mutating func push(_ value: Int64) throws {
        guard stack.count < Self.stackCapacity else { throw SM64LevelScriptVMError.stackOverflow }
        stack.append(value)
    }

    private func evaluate(op: UInt8, argument: Int32) -> Bool {
        switch op {
        case 0: return register & argument != 0
        case 1: return register & argument == 0
        case 2: return register == argument
        case 3: return register != argument
        case 4: return register < argument
        case 5: return register <= argument
        case 6: return register > argument
        case 7: return register >= argument
        default: return false
        }
    }
}
