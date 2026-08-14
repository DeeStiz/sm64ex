import Foundation

enum SM64BehaviorVMStatus: Int8, Equatable, Sendable {
    case running = 1
    case `break` = 0
    case deactivated = -1
}

enum SM64BehaviorVMError: Error, Equatable, Sendable, CustomStringConvertible {
    case invalidStart(Int)
    case stackOverflow
    case stackUnderflow
    case stepLimitExceeded(Int)
    case missingNativeCallback(UInt64)
    case invalidDelay(Int32)

    var description: String {
        switch self {
        case let .invalidStart(offset): "behavior VM start offset " + String(offset) + " is invalid"
        case .stackOverflow: "behavior VM stack overflow"
        case .stackUnderflow: "behavior VM stack underflow"
        case let .stepLimitExceeded(limit): "behavior VM exceeded the per-tick command limit " + String(limit)
        case let .missingNativeCallback(pointer): "behavior VM has no native callback for 0x" + String(pointer, radix: 16)
        case let .invalidDelay(value): "behavior VM delay value " + String(value) + " is invalid"
        }
    }
}

enum SM64BehaviorProcResult: Int8, Equatable, Sendable {
    case `continue` = 1
    case `break` = 0
}

struct SM64BehaviorVec3f: Equatable, Sendable {
    var x: Float
    var y: Float
    var z: Float

    init(_ x: Float = 0, _ y: Float = 0, _ z: Float = 0) {
        self.x = x
        self.y = y
        self.z = z
    }
}

/// The deterministic subset of an engine Object that behavior bytecode can
/// mutate.  Object-field dictionaries preserve the original field-number ABI
/// while the named values make fixtures and later native actor ports readable.
struct SM64BehaviorObjectState: Equatable, Sendable {
    var intFields: [UInt8: Int32] = [:]
    var floatFields: [UInt8: Float] = [:]
    var pointerFields: [UInt8: UInt64] = [:]
    var parentIntFields: [UInt8: Int32] = [:]

    var activeFlags: UInt32 = 1
    var gfxFlags: UInt32 = 1
    var modelID: Int32 = 0
    var collisionData: UInt64 = 0
    var animationIndex: UInt8 = 0
    var animationPointer: UInt64 = 0

    var hitboxRadius: Int16 = 0
    var hitboxHeight: Int16 = 0
    var hitboxDownOffset: Int16 = 0
    var hurtboxRadius: Int16 = 0
    var hurtboxHeight: Int16 = 0
    var interactType: UInt32 = 0
    var interactSubtype: UInt32 = 0
    var scale: Float = 1

    var position = SM64BehaviorVec3f()
    var home = SM64BehaviorVec3f()
    var wallHitboxRadius: Float = 0
    var gravity: Float = 0
    var bounciness: Float = 0
    var dragStrength: Float = 0
    var friction: Float = 0
    var buoyancy: Float = 0

    var action: Int32 = 0
    var previousAction: Int32 = 0
    var subAction: Int32 = 0
    var timer: UInt32 = 0
    var behaviorDelayTimer: Int32 = 0
    var behaviorParameter: Int16 = 0
    var spawnCount: UInt32 = 0
    var waterDropletCount: UInt32 = 0
    var lastSpawnedModel: UInt32 = 0
    var lastSpawnedBehavior: UInt64 = 0
    var lastSpawnedParameter: Int16 = 0

    func getInt(_ field: UInt8) -> Int32 { intFields[field] ?? 0 }
    mutating func setInt(_ field: UInt8, _ value: Int32) { intFields[field] = value }
    mutating func addInt(_ field: UInt8, _ value: Int32) { intFields[field, default: 0] &+= value }
    func getFloat(_ field: UInt8) -> Float { floatFields[field] ?? 0 }
    mutating func setFloat(_ field: UInt8, _ value: Float) { floatFields[field] = value }
    mutating func addFloat(_ field: UInt8, _ value: Float) { floatFields[field, default: 0] += value }
}

struct SM64BehaviorCommandTrace: Equatable, Sendable {
    let tick: UInt32
    let executedOffset: Int
    let executedOpcode: UInt8
    let procResult: SM64BehaviorProcResult
    let action: Int32
    let timer: UInt32
    let nextOffset: Int?
}

struct SM64BehaviorVMSnapshot: Equatable, Sendable {
    let status: SM64BehaviorVMStatus
    let currentOffset: Int?
    let stackDepth: Int
    let timer: UInt32
    let behaviorDelayTimer: Int32
    let commandCount: UInt64
    let tickCount: UInt32
    let randomSeed: UInt16
    let object: SM64BehaviorObjectState
}

struct SM64BehaviorVM: Sendable {
    private static let stackCapacity = 32
    private static let activeFlag = UInt32(1 << 0)
    private static let renderActiveFlag = UInt32(1 << 0)
    private static let renderBillboardFlag = UInt32(1 << 2)
    private static let renderInvisibleFlag = UInt32(1 << 4)
    private static let renderCylboardFlag = UInt32(1 << 6)

    let program: SM64BehaviorScriptProgram
    let targetResolver: SM64BehaviorTargetResolver
    let strictNativeCallbacks: Bool
    let nativeHandler: (@Sendable (UInt64, inout SM64BehaviorObjectState) -> Void)?
    let floorHeight: Float?

    private(set) var status: SM64BehaviorVMStatus = .running
    private(set) var currentOffset: Int?
    private(set) var object: SM64BehaviorObjectState
    private(set) var commandCount: UInt64 = 0
    private(set) var tickCount: UInt32 = 0
    private(set) var random: SM64Random16
    private(set) var traces: [SM64BehaviorCommandTrace] = []
    private var stack: [Int64] = []

    init(
        program: SM64BehaviorScriptProgram,
        startOffset: Int = 0,
        targetResolver: SM64BehaviorTargetResolver = SM64BehaviorTargetResolver(),
        strictNativeCallbacks: Bool = false,
        nativeHandler: (@Sendable (UInt64, inout SM64BehaviorObjectState) -> Void)? = nil,
        floorHeight: Float? = nil,
        object: SM64BehaviorObjectState = SM64BehaviorObjectState(),
        randomSeed: UInt16 = 0
    ) throws {
        guard program.commands.contains(where: { $0.wordOffset == startOffset }) else {
            throw SM64BehaviorVMError.invalidStart(startOffset)
        }
        self.program = program
        self.targetResolver = targetResolver
        self.strictNativeCallbacks = strictNativeCallbacks
        self.nativeHandler = nativeHandler
        self.floorHeight = floorHeight
        self.currentOffset = startOffset
        self.object = object
        self.random = SM64Random16(seed: randomSeed)
    }

    var snapshot: SM64BehaviorVMSnapshot {
        SM64BehaviorVMSnapshot(
            status: status,
            currentOffset: currentOffset,
            stackDepth: stack.count,
            timer: object.timer,
            behaviorDelayTimer: object.behaviorDelayTimer,
            commandCount: commandCount,
            tickCount: tickCount,
            randomSeed: random.seed,
            object: object
        )
    }

    mutating func executeTick(commandLimit: Int = 10_000) throws {
        guard status != .deactivated, currentOffset != nil else { return }
        guard commandLimit > 0 else { throw SM64BehaviorVMError.stepLimitExceeded(commandLimit) }
        tickCount &+= 1
        status = .running
        var executed = 0
        while status == .running, let offset = currentOffset {
            guard executed < commandLimit else {
                throw SM64BehaviorVMError.stepLimitExceeded(commandLimit)
            }
            executed += 1
            let command = try program.command(at: offset)
            let result = try execute(command)
            commandCount &+= 1
            traces.append(SM64BehaviorCommandTrace(
                tick: tickCount,
                executedOffset: command.wordOffset,
                executedOpcode: command.opcode.rawValue,
                procResult: result,
                action: object.action,
                timer: object.timer,
                nextOffset: currentOffset
            ))
            if result == .break { status = .break }
        }
        if object.timer < 0x3FFF_FFFF { object.timer &+= 1 }
    }

    mutating func run(tickLimit: Int = 100_000, commandLimitPerTick: Int = 10_000) throws {
        guard tickLimit > 0 else { throw SM64BehaviorVMError.stepLimitExceeded(tickLimit) }
        var ticks = 0
        while status != .deactivated && currentOffset != nil && ticks < tickLimit {
            try executeTick(commandLimit: commandLimitPerTick)
            ticks += 1
        }
        if currentOffset != nil && status != .deactivated {
            throw SM64BehaviorVMError.stepLimitExceeded(tickLimit)
        }
    }

    private mutating func execute(_ command: SM64BehaviorScriptCommand) throws -> SM64BehaviorProcResult {
        switch command.opcode {
        case .begin:
            advance(command)
        case .delay:
            let frames = Int32(command.firstS16)
            try delay(frames, command: command)
            return .break
        case .call:
            try push(Int64(command.wordOffset + command.wordLength))
            currentOffset = try targetResolver.targetOffset(from: command, in: program)
        case .return:
            currentOffset = try popOffset()
        case .goTo:
            currentOffset = try targetResolver.targetOffset(from: command, in: program)
        case .beginRepeat, .beginRepeatUnused:
            let count = command.opcode == .beginRepeat ? Int64(command.firstS16) : Int64(command.secondByte)
            try push(Int64(command.wordOffset + command.wordLength))
            try push(count)
            advance(command)
        case .endRepeat, .endRepeatContinue:
            let count = try pop()
            let target = try popOffset()
            let nextCount = count &- 1
            if nextCount != 0 {
                currentOffset = target
                try push(Int64(target))
                try push(nextCount)
            } else {
                advance(command)
            }
            return command.opcode == .endRepeat ? .break : .continue
        case .beginLoop:
            try push(Int64(command.wordOffset + command.wordLength))
            advance(command)
        case .endLoop:
            let target = try popOffset()
            currentOffset = target
            try push(Int64(target))
            return .break
        case .break, .breakUnused:
            return .break
        case .callNative:
            let pointer = UInt64(command.word(1))
            if let nativeHandler {
                nativeHandler(pointer, &object)
            } else if strictNativeCallbacks && pointer != 0 {
                throw SM64BehaviorVMError.missingNativeCallback(pointer)
            }
            currentOffset = program.nextOffset(after: command)
        case .addFloat:
            object.addFloat(command.secondByte, Float(command.firstS16)); advance(command)
        case .setFloat:
            object.setFloat(command.secondByte, Float(command.firstS16)); advance(command)
        case .addInt:
            object.addInt(command.secondByte, Int32(command.firstS16)); advance(command)
        case .setInt:
            object.setInt(command.secondByte, Int32(command.firstS16)); advance(command)
        case .orInt:
            object.setInt(command.secondByte, object.getInt(command.secondByte) | Int32(UInt16(bitPattern: command.firstS16))); advance(command)
        case .bitClear:
            let mask = Int32(UInt16(bitPattern: command.firstS16) ^ 0xffff)
            object.setInt(command.secondByte, object.getInt(command.secondByte) & mask); advance(command)
        case .setIntRandomRightShift:
            let shift = max(0, min(31, Int(command.highS16(1))))
            object.setInt(command.secondByte, Int32(random.next() >> UInt16(shift)) &+ Int32(command.firstS16)); advance(command, words: 2)
        case .setRandomFloat:
            let value = Float(command.firstS16) + Float(command.highS16(1)) * nextRandomFloat()
            object.setFloat(command.secondByte, value); advance(command, words: 2)
        case .setRandomInt:
            let value = Int32(Float(command.highS16(1)) * nextRandomFloat()) &+ Int32(command.firstS16)
            object.setInt(command.secondByte, value); advance(command, words: 2)
        case .addRandomFloat:
            let value = Float(command.firstS16) + Float(command.highS16(1)) * nextRandomFloat()
            object.addFloat(command.secondByte, value); advance(command, words: 2)
        case .addIntRandomRightShift:
            let shift = max(0, min(31, Int(command.highS16(1))))
            let value = Int32(command.firstS16) &+ Int32(random.next() >> UInt16(shift))
            object.addInt(command.secondByte, value); advance(command, words: 2)
        case .nop1, .nop2, .nop3, .nop4:
            advance(command)
        case .setModel:
            object.modelID = Int32(command.firstS16); advance(command)
        case .spawnChild, .spawnObject:
            recordSpawn(command, parameter: 0); advance(command, words: 3)
        case .deactivate:
            object.activeFlags = 0
            status = .deactivated
            return .break
        case .dropToFloor:
            if let floorHeight { object.position.y = floorHeight }
            advance(command)
        case .sumFloat:
            object.setFloat(command.secondByte, object.getFloat(command.thirdByte) + object.getFloat(command.fourthByte)); advance(command)
        case .sumInt:
            object.setInt(command.secondByte, object.getInt(command.thirdByte) &+ object.getInt(command.fourthByte)); advance(command)
        case .billboard:
            object.gfxFlags |= Self.renderBillboardFlag; advance(command)
        case .hide:
            object.gfxFlags |= Self.renderInvisibleFlag; advance(command)
        case .setHitbox:
            object.hitboxRadius = command.highS16(1); object.hitboxHeight = command.lowS16(1); advance(command, words: 2)
        case .delayVariable:
            try delay(object.getInt(command.secondByte), command: command)
            return .break
        case .loadAnimations:
            object.animationPointer = UInt64(command.word(1)); object.pointerFields[command.secondByte] = UInt64(command.word(1)); advance(command, words: 2)
        case .animate:
            object.animationIndex = command.secondByte; advance(command)
        case .spawnChildWithParam:
            recordSpawn(command, parameter: command.firstS16); advance(command, words: 3)
        case .loadCollisionData:
            object.collisionData = UInt64(command.word(1)); advance(command, words: 2)
        case .setHitboxWithOffset:
            object.hitboxRadius = command.highS16(1); object.hitboxHeight = command.lowS16(1); object.hitboxDownOffset = command.highS16(2); advance(command, words: 3)
        case .setHome:
            object.home = object.position; advance(command)
        case .setHurtbox:
            object.hurtboxRadius = command.highS16(1); object.hurtboxHeight = command.lowS16(1); advance(command, words: 2)
        case .setInteractType:
            object.interactType = command.word(1); advance(command, words: 2)
        case .setObjectPhysics:
            object.wallHitboxRadius = Float(command.highS16(1))
            object.gravity = Float(command.lowS16(1)) / 100
            object.bounciness = Float(command.highS16(2)) / 100
            object.dragStrength = Float(command.lowS16(2)) / 100
            object.friction = Float(command.highS16(3)) / 100
            object.buoyancy = Float(command.lowS16(3)) / 100
            advance(command, words: 5)
        case .setInteractSubtype:
            object.interactSubtype = command.word(1); advance(command, words: 2)
        case .scale:
            object.scale = Float(command.firstS16) / 100; advance(command)
        case .parentBitClear:
            let mask = command.word(1)
            object.parentIntFields[command.secondByte, default: 0] &= Int32(truncatingIfNeeded: ~mask)
            advance(command, words: 2)
        case .animateTexture:
            let rate = Int(command.firstS16)
            if rate != 0 && Int(tickCount) % abs(rate) == 0 { object.addInt(command.secondByte, 1) }
            advance(command)
        case .disableRendering:
            object.gfxFlags &= ~Self.renderActiveFlag; advance(command)
        case .setIntUnused:
            object.setInt(command.secondByte, Int32(command.lowS16(1))); advance(command, words: 2)
        case .spawnWaterDroplet:
            object.waterDropletCount &+= 1; advance(command, words: 2)
        case .cylboard:
            object.gfxFlags |= Self.renderCylboardFlag; advance(command)
        }
        return .continue
    }

    private mutating func delay(_ frames: Int32, command: SM64BehaviorScriptCommand) throws {
        guard frames >= 0 else { throw SM64BehaviorVMError.invalidDelay(frames) }
        if object.behaviorDelayTimer < frames - 1 {
            object.behaviorDelayTimer &+= 1
        } else {
            object.behaviorDelayTimer = 0
            advance(command)
        }
    }

    private mutating func recordSpawn(_ command: SM64BehaviorScriptCommand, parameter: Int16) {
        object.spawnCount &+= 1
        object.lastSpawnedModel = command.word(1)
        object.lastSpawnedBehavior = UInt64(command.word(2))
        object.lastSpawnedParameter = parameter
    }

    private mutating func push(_ value: Int64) throws {
        guard stack.count < Self.stackCapacity else { throw SM64BehaviorVMError.stackOverflow }
        stack.append(value)
    }

    private mutating func pop() throws -> Int64 {
        guard let value = stack.popLast() else { throw SM64BehaviorVMError.stackUnderflow }
        return value
    }

    private mutating func popOffset() throws -> Int {
        let value = try pop()
        guard value >= 0, value <= Int64(Int.max) else { throw SM64BehaviorVMError.stackUnderflow }
        return Int(value)
    }

    private mutating func advance(_ command: SM64BehaviorScriptCommand, words: Int? = nil) {
        let next = command.wordOffset + (words ?? command.wordLength)
        currentOffset = program.commands.contains(where: { $0.wordOffset == next }) ? next : nil
    }

    private mutating func nextRandomFloat() -> Float {
        Float(bitPattern: random.nextFloatBits())
    }
}
