import Foundation

enum SM64GeoLayoutError: Error, Equatable, Sendable, CustomStringConvertible {
    case emptyProgram
    case truncatedCommand(offset: Int)
    case unknownOpcode(offset: Int, opcode: UInt8)
    case invalidCommandLength(offset: Int, opcode: UInt8, length: Int)
    case outOfBounds(offset: Int, logicalOffset: Int, byteCount: Int)
    case invalidTarget(offset: Int, target: UInt64)
    case branchStackUnderflow
    case nodeStackUnderflow
    case invalidViewIndex(Int)
    case sceneRootAlreadyExists
    case stepLimitExceeded(Int)

    var description: String {
        switch self {
        case .emptyProgram: "geo layout is empty"
        case let .truncatedCommand(offset): "geo layout command is truncated at byte \(offset)"
        case let .unknownOpcode(offset, opcode):
            "unknown geo layout opcode 0x\(String(format: "%02x", opcode)) at byte \(offset)"
        case let .invalidCommandLength(offset, opcode, length):
            "invalid geo layout command 0x\(String(format: "%02x", opcode)) length \(length) at byte \(offset)"
        case let .outOfBounds(offset, logicalOffset, byteCount):
            "geo layout logical offset \(logicalOffset) is out of bounds at byte \(offset) (\(byteCount) bytes)"
        case let .invalidTarget(offset, target):
            "geo layout target 0x\(String(format: "%llx", target)) is not a command at byte \(offset)"
        case .branchStackUnderflow: "geo layout branch stack underflow"
        case .nodeStackUnderflow: "geo layout node stack underflow"
        case let .invalidViewIndex(index): "geo layout view index \(index) is invalid"
        case .sceneRootAlreadyExists: "geo layout has more than one scene root"
        case let .stepLimitExceeded(limit): "geo layout exceeded step limit \(limit)"
        }
    }
}

enum SM64GeoLayoutOpcode: UInt8, CaseIterable, Sendable {
    case branchAndLink = 0x00
    case end = 0x01
    case branch = 0x02
    case `return` = 0x03
    case openNode = 0x04
    case closeNode = 0x05
    case assignAsView = 0x06
    case updateNodeFlags = 0x07
    case nodeRoot = 0x08
    case nodeOrthoProjection = 0x09
    case nodePerspective = 0x0A
    case nodeStart = 0x0B
    case nodeMasterList = 0x0C
    case nodeLevelOfDetail = 0x0D
    case nodeSwitchCase = 0x0E
    case nodeCamera = 0x0F
    case nodeTranslationRotation = 0x10
    case nodeTranslation = 0x11
    case nodeRotation = 0x12
    case nodeAnimatedPart = 0x13
    case nodeBillboard = 0x14
    case nodeDisplayList = 0x15
    case nodeShadow = 0x16
    case nodeObjectParent = 0x17
    case nodeGenerated = 0x18
    case nodeBackground = 0x19
    case nop = 0x1A
    case copyView = 0x1B
    case nodeHeldObject = 0x1C
    case nodeScale = 0x1D
    case nop2 = 0x1E
    case nop3 = 0x1F
    case nodeCullingRadius = 0x20
}

struct SM64GeoLayoutCommand: Equatable, Sendable {
    let offset: Int
    let opcode: SM64GeoLayoutOpcode
    let parameter: UInt8
    let bytes: Data

    var byteLength: Int { bytes.count }

    var pointerLogicalOffsets: [Int] {
        switch opcode {
        case .branchAndLink, .branch: return [4]
        case .nodePerspective: return parameter == 0 ? [] : [8]
        case .nodeSwitchCase: return [4]
        case .nodeCamera: return [16]
        case .nodeTranslationRotation:
            guard parameter & 0x80 != 0 else { return [] }
            let layout = (parameter & 0x70) >> 4
            return [layout == 0 ? 16 : (layout == 3 ? 4 : 8)]
        case .nodeTranslation, .nodeRotation, .nodeBillboard:
            return parameter & 0x80 == 0 ? [] : [8]
        case .nodeAnimatedPart: return [8]
        case .nodeDisplayList: return [4]
        case .nodeGenerated, .nodeBackground: return [4]
        case .nodeHeldObject: return [8]
        case .nodeScale: return parameter & 0x80 == 0 ? [] : [8]
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

    func readUInt64(logicalOffset: Int) throws -> UInt64 {
        let index = try physicalIndex(logicalOffset, width: 8)
        var value: UInt64 = 0
        for byte in 0..<8 { value |= UInt64(bytes[index + byte]) << UInt64(byte * 8) }
        return value
    }

    private func physicalIndex(_ logicalOffset: Int, width: Int) throws -> Int {
        guard logicalOffset >= 0, width > 0 else {
            throw SM64GeoLayoutError.outOfBounds(offset: offset, logicalOffset: logicalOffset, byteCount: bytes.count)
        }
        let physical = (logicalOffset & 3) | ((logicalOffset & ~3) << 1)
        guard physical <= bytes.count - width else {
            throw SM64GeoLayoutError.outOfBounds(offset: offset, logicalOffset: logicalOffset, byteCount: bytes.count)
        }
        return physical
    }
}

struct SM64GeoLayoutProgram: Sendable {
    let data: Data
    let commands: [SM64GeoLayoutCommand]
    private let offsets: Set<Int>

    init(data: Data) throws {
        guard !data.isEmpty else { throw SM64GeoLayoutError.emptyProgram }
        var cursor = 0
        var decoded: [SM64GeoLayoutCommand] = []
        while cursor < data.count {
            guard data.count - cursor >= 2 else { throw SM64GeoLayoutError.truncatedCommand(offset: cursor) }
            let opcodeValue = data[cursor]
            let parameter = data[cursor + 1]
            guard let opcode = SM64GeoLayoutOpcode(rawValue: opcodeValue) else {
                throw SM64GeoLayoutError.unknownOpcode(offset: cursor, opcode: opcodeValue)
            }
            let length = Self.byteLength(opcode: opcode, parameter: parameter)
            guard length >= 8, length % 8 == 0 else {
                throw SM64GeoLayoutError.invalidCommandLength(offset: cursor, opcode: opcodeValue, length: length)
            }
            guard length <= data.count - cursor else { throw SM64GeoLayoutError.truncatedCommand(offset: cursor) }
            decoded.append(SM64GeoLayoutCommand(
                offset: cursor,
                opcode: opcode,
                parameter: parameter,
                bytes: data.subdata(in: cursor..<(cursor + length))
            ))
            cursor += length
        }
        self.data = data
        self.commands = decoded
        self.offsets = Set(decoded.map(\.offset))
    }

    static func byteLength(opcode: SM64GeoLayoutOpcode, parameter: UInt8) -> Int {
        switch opcode {
        case .branchAndLink, .branch: return 16
        case .end, .return, .openNode, .closeNode, .assignAsView, .updateNodeFlags,
             .nodeOrthoProjection, .nodeStart, .nodeMasterList, .copyView,
             .nodeObjectParent, .nodeCullingRadius: return 8
        case .nodeRoot: return 24
        case .nodePerspective: return parameter == 0 ? 16 : 24
        case .nodeLevelOfDetail, .nodeSwitchCase, .nodeTranslation, .nodeRotation,
             .nodeBillboard, .nodeScale, .nop2: return (opcode == .nodeScale && parameter & 0x80 != 0)
                || ((opcode == .nodeTranslation || opcode == .nodeRotation || opcode == .nodeBillboard) && parameter & 0x80 != 0)
                ? 24 : 16
        case .nodeCamera: return 40
        case .nodeTranslationRotation:
            let layout = (parameter & 0x70) >> 4
            let base = [32, 16, 16, 8][Int(min(layout, 3))]
            return base + (parameter & 0x80 != 0 ? 8 : 0)
        case .nodeAnimatedPart, .nodeHeldObject: return 24
        case .nodeDisplayList, .nodeShadow, .nodeGenerated, .nodeBackground: return 16
        case .nop, .nop3: return opcode == .nop3 ? 32 : 16
        }
    }

    func command(at offset: Int) throws -> SM64GeoLayoutCommand {
        guard let command = commands.first(where: { $0.offset == offset }) else {
            throw SM64GeoLayoutError.invalidTarget(offset: offset, target: UInt64(max(0, offset)))
        }
        return command
    }

    func nextOffset(after command: SM64GeoLayoutCommand) -> Int? {
        let next = command.offset + command.byteLength
        return offsets.contains(next) ? next : nil
    }

    func targetOffset(from command: SM64GeoLayoutCommand, logicalOffset: Int) throws -> Int {
        let target = try command.readUInt64(logicalOffset: logicalOffset)
        guard target <= UInt64(Int.max), offsets.contains(Int(target)) else {
            throw SM64GeoLayoutError.invalidTarget(offset: command.offset, target: target)
        }
        return Int(target)
    }
}

struct SM64GeoLayoutTargetResolver: Sendable {
    let mappedTargets: [UInt64: Int]

    init(mappedTargets: [UInt64: Int] = [:]) { self.mappedTargets = mappedTargets }

    func targetOffset(
        from command: SM64GeoLayoutCommand,
        logicalOffset: Int,
        in program: SM64GeoLayoutProgram
    ) throws -> Int {
        let raw = try command.readUInt64(logicalOffset: logicalOffset)
        if let mapped = mappedTargets[raw] { return mapped }
        return try program.targetOffset(from: command, logicalOffset: logicalOffset)
    }
}

struct SM64GeoVec3s: Equatable, Sendable {
    let x: Int16
    let y: Int16
    let z: Int16
}

enum SM64GeoNodeKind: UInt16, Equatable, Sendable {
    case root = 0x001
    case orthoProjection = 0x002
    case perspective = 0x003
    case masterList = 0x004
    case start = 0x00A
    case levelOfDetail = 0x00B
    case switchCase = 0x00C
    case camera = 0x014
    case translationRotation = 0x015
    case translation = 0x016
    case rotation = 0x017
    case object = 0x018
    case animatedPart = 0x019
    case billboard = 0x01A
    case displayList = 0x01B
    case scale = 0x01C
    case shadow = 0x028
    case objectParent = 0x029
    case generated = 0x02A
    case background = 0x02C
    case heldObject = 0x02E
    case cullingRadius = 0x02F
}

enum SM64GeoNodePayload: Equatable, Sendable {
    case none
    case root(numEntries: Int16, x: Int16, y: Int16, width: Int16, height: Int16)
    case ortho(scalePercent: Int16)
    case perspective(fov: Int16, near: Int16, far: Int16, function: UInt64?)
    case masterList(zBuffer: UInt8)
    case levelOfDetail(minDistance: Int16, maxDistance: Int16)
    case switchCase(count: Int16, selectedCase: Int16, function: UInt64)
    case camera(type: Int16, position: SM64GeoVec3s, focus: SM64GeoVec3s, function: UInt64)
    case transform(layer: UInt8, translation: SM64GeoVec3s, rotation: SM64GeoVec3s, displayList: UInt64?)
    case translation(layer: UInt8, translation: SM64GeoVec3s, displayList: UInt64?)
    case rotation(layer: UInt8, rotation: SM64GeoVec3s, displayList: UInt64?)
    case animatedPart(layer: UInt8, translation: SM64GeoVec3s, displayList: UInt64)
    case billboard(layer: UInt8, translation: SM64GeoVec3s, displayList: UInt64?)
    case displayList(layer: UInt8, address: UInt64)
    case shadow(type: UInt8, solidity: UInt8, scale: Int16)
    case generated(parameter: Int16, function: UInt64)
    case background(background: Int16, function: UInt64)
    case heldObject(parameter: UInt8, offset: SM64GeoVec3s, function: UInt64)
    case scale(layer: UInt8, fixedScale: UInt32, displayList: UInt64?)
    case cullingRadius(Int16)
    case raw(values: [Int16], pointers: [UInt64])
}

struct SM64GeoLayoutSceneNode: Equatable, Sendable {
    let id: Int
    let kind: SM64GeoNodeKind
    let parent: Int?
    var children: [Int]
    var flags: Int16
    let payload: SM64GeoNodePayload
}

struct SM64GeoLayoutTrace: Equatable, Sendable {
    let offset: Int
    let opcode: UInt8
    let parameter: UInt8
    let currentNode: Int?
    let nodeDepth: Int
}

struct SM64GeoLayoutScene: Equatable, Sendable {
    let root: Int?
    let nodes: [SM64GeoLayoutSceneNode]
    let views: [Int: Int]
    let traces: [SM64GeoLayoutTrace]
}

struct SM64GeoLayoutBuilder: Sendable {
    let program: SM64GeoLayoutProgram
    let targetResolver: SM64GeoLayoutTargetResolver

    private var currentOffset: Int?
    private var branchStack: [Int] = []
    private var nodeDepth: Int = 0
    private var nodeAtDepth: [Int] = []
    private var currentNode: Int?
    private var rootNode: Int?
    private var nodes: [SM64GeoLayoutSceneNode] = []
    private var views: [Int: Int] = [:]
    private var traces: [SM64GeoLayoutTrace] = []

    init(program: SM64GeoLayoutProgram, targetResolver: SM64GeoLayoutTargetResolver = SM64GeoLayoutTargetResolver()) {
        self.program = program
        self.targetResolver = targetResolver
        self.currentOffset = program.commands.first?.offset
    }

    mutating func build(stepLimit: Int = 100_000) throws -> SM64GeoLayoutScene {
        guard stepLimit > 0 else { throw SM64GeoLayoutError.stepLimitExceeded(stepLimit) }
        var steps = 0
        while let offset = currentOffset {
            guard steps < stepLimit else { throw SM64GeoLayoutError.stepLimitExceeded(stepLimit) }
            steps += 1
            let command = try program.command(at: offset)
            traces.append(SM64GeoLayoutTrace(
                offset: offset,
                opcode: command.opcode.rawValue,
                parameter: command.parameter,
                currentNode: currentNode,
                nodeDepth: nodeDepth
            ))
            try execute(command)
        }
        return SM64GeoLayoutScene(root: rootNode, nodes: nodes, views: views, traces: traces)
    }

    private mutating func execute(_ command: SM64GeoLayoutCommand) throws {
        switch command.opcode {
        case .branchAndLink:
            try branchStackPush(program.nextOffset(after: command))
            try jump(command, logicalOffset: 4)
        case .end:
            if let target = branchStack.popLast() { currentOffset = target } else { currentOffset = nil }
        case .branch:
            if command.parameter == 1 { try branchStackPush(program.nextOffset(after: command)) }
            try jump(command, logicalOffset: 4)
        case .return:
            guard let target = branchStack.popLast() else { throw SM64GeoLayoutError.branchStackUnderflow }
            currentOffset = target
        case .openNode:
            guard let currentNode else { throw SM64GeoLayoutError.nodeStackUnderflow }
            nodeDepth += 1
            if nodeAtDepth.count > nodeDepth {
                nodeAtDepth[nodeDepth] = currentNode
            } else {
                nodeAtDepth.append(currentNode)
            }
            currentOffset = program.nextOffset(after: command)
        case .closeNode:
            guard nodeDepth > 0, nodeAtDepth.count > nodeDepth else { throw SM64GeoLayoutError.nodeStackUnderflow }
            nodeDepth -= 1
            currentNode = nodeAtDepth[nodeDepth]
            currentOffset = program.nextOffset(after: command)
        case .assignAsView:
            let index = Int(try command.readInt16(logicalOffset: 2))
            guard index >= 0 else { throw SM64GeoLayoutError.invalidViewIndex(index) }
            if let currentNode { views[index] = currentNode }
            currentOffset = program.nextOffset(after: command)
        case .updateNodeFlags:
            if let currentNode {
                let operation = try command.readUInt8(logicalOffset: 1)
                let bits = try command.readInt16(logicalOffset: 2)
                switch operation {
                case 0: nodes[currentNode].flags = bits
                case 1: nodes[currentNode].flags |= bits
                case 2: nodes[currentNode].flags &= ~bits
                default: break
                }
            }
            currentOffset = program.nextOffset(after: command)
        case .nodeRoot:
            let payload = SM64GeoNodePayload.root(
                numEntries: try command.readInt16(logicalOffset: 2),
                x: try command.readInt16(logicalOffset: 4),
                y: try command.readInt16(logicalOffset: 6),
                width: try command.readInt16(logicalOffset: 8),
                height: try command.readInt16(logicalOffset: 10)
            )
            try registerNode(kind: .root, payload: payload)
            currentOffset = program.nextOffset(after: command)
        case .nodeOrthoProjection:
            try registerNode(kind: .orthoProjection, payload: .ortho(scalePercent: try command.readInt16(logicalOffset: 2)))
            currentOffset = program.nextOffset(after: command)
        case .nodePerspective:
            let function = command.parameter == 0 ? nil : try command.readUInt64(logicalOffset: 8)
            try registerNode(kind: .perspective, payload: .perspective(
                fov: try command.readInt16(logicalOffset: 2),
                near: try command.readInt16(logicalOffset: 4),
                far: try command.readInt16(logicalOffset: 6),
                function: function
            ))
            currentOffset = program.nextOffset(after: command)
        case .nodeStart:
            try registerNode(kind: .start, payload: .none)
            currentOffset = program.nextOffset(after: command)
        case .nodeMasterList:
            try registerNode(kind: .masterList, payload: .masterList(zBuffer: try command.readUInt8(logicalOffset: 1)))
            currentOffset = program.nextOffset(after: command)
        case .nodeLevelOfDetail:
            try registerNode(kind: .levelOfDetail, payload: .levelOfDetail(
                minDistance: try command.readInt16(logicalOffset: 4),
                maxDistance: try command.readInt16(logicalOffset: 6)
            ))
            currentOffset = program.nextOffset(after: command)
        case .nodeSwitchCase:
            try registerNode(kind: .switchCase, payload: .switchCase(
                count: try command.readInt16(logicalOffset: 2),
                selectedCase: 0,
                function: try command.readUInt64(logicalOffset: 4)
            ))
            currentOffset = program.nextOffset(after: command)
        case .nodeCamera:
            try registerNode(kind: .camera, payload: .camera(
                type: try command.readInt16(logicalOffset: 2),
                position: try vec3(command, at: 4),
                focus: try vec3(command, at: 10),
                function: try command.readUInt64(logicalOffset: 16)
            ))
            currentOffset = program.nextOffset(after: command)
        case .nodeTranslationRotation:
            let layout = (command.parameter & 0x70) >> 4
            let translation: SM64GeoVec3s
            let rotation: SM64GeoVec3s
            switch layout {
            case 0:
                translation = try vec3(command, at: 4)
                rotation = try vec3(command, at: 10)
            case 1:
                translation = try vec3(command, at: 2)
                rotation = SM64GeoVec3s(x: 0, y: 0, z: 0)
            case 2:
                translation = SM64GeoVec3s(x: 0, y: 0, z: 0)
                rotation = try vec3(command, at: 2)
            default:
                translation = SM64GeoVec3s(x: 0, y: 0, z: 0)
                let degrees = Int32(try command.readInt16(logicalOffset: 2))
                rotation = SM64GeoVec3s(x: 0, y: Int16(truncatingIfNeeded: degrees * 0x8000 / 180), z: 0)
            }
            let displayList = command.parameter & 0x80 == 0 ? nil : try command.readUInt64(logicalOffset: layout == 0 ? 16 : (layout == 3 ? 4 : 8))
            try registerNode(kind: .translationRotation, payload: .transform(
                layer: command.parameter & 0x0f,
                translation: translation,
                rotation: rotation,
                displayList: displayList
            ))
            currentOffset = program.nextOffset(after: command)
        case .nodeTranslation:
            try registerNode(kind: .translation, payload: .translation(
                layer: command.parameter & 0x0f,
                translation: try vec3(command, at: 2),
                displayList: command.parameter & 0x80 == 0 ? nil : try command.readUInt64(logicalOffset: 8)
            ))
            currentOffset = program.nextOffset(after: command)
        case .nodeRotation:
            try registerNode(kind: .rotation, payload: .rotation(
                layer: command.parameter & 0x0f,
                rotation: try vec3(command, at: 2),
                displayList: command.parameter & 0x80 == 0 ? nil : try command.readUInt64(logicalOffset: 8)
            ))
            currentOffset = program.nextOffset(after: command)
        case .nodeAnimatedPart:
            try registerNode(kind: .animatedPart, payload: .animatedPart(
                layer: command.parameter,
                translation: try vec3(command, at: 2),
                displayList: try command.readUInt64(logicalOffset: 8)
            ))
            currentOffset = program.nextOffset(after: command)
        case .nodeBillboard:
            try registerNode(kind: .billboard, payload: .billboard(
                layer: command.parameter & 0x0f,
                translation: try vec3(command, at: 2),
                displayList: command.parameter & 0x80 == 0 ? nil : try command.readUInt64(logicalOffset: 8)
            ))
            currentOffset = program.nextOffset(after: command)
        case .nodeDisplayList:
            try registerNode(kind: .displayList, payload: .displayList(
                layer: command.parameter,
                address: try command.readUInt64(logicalOffset: 4)
            ))
            currentOffset = program.nextOffset(after: command)
        case .nodeShadow:
            try registerNode(kind: .shadow, payload: .shadow(
                type: UInt8(truncatingIfNeeded: try command.readInt16(logicalOffset: 2)),
                solidity: UInt8(truncatingIfNeeded: try command.readInt16(logicalOffset: 4)),
                scale: try command.readInt16(logicalOffset: 6)
            ))
            currentOffset = program.nextOffset(after: command)
        case .nodeObjectParent:
            try registerNode(kind: .objectParent, payload: .none)
            currentOffset = program.nextOffset(after: command)
        case .nodeGenerated:
            try registerNode(kind: .generated, payload: .generated(
                parameter: try command.readInt16(logicalOffset: 2),
                function: try command.readUInt64(logicalOffset: 4)
            ))
            currentOffset = program.nextOffset(after: command)
        case .nodeBackground:
            try registerNode(kind: .background, payload: .background(
                background: try command.readInt16(logicalOffset: 2),
                function: try command.readUInt64(logicalOffset: 4)
            ))
            currentOffset = program.nextOffset(after: command)
        case .nop, .nop2, .nop3:
            currentOffset = program.nextOffset(after: command)
        case .copyView:
            try registerNode(kind: .objectParent, payload: .raw(values: [try command.readInt16(logicalOffset: 2)], pointers: []))
            currentOffset = program.nextOffset(after: command)
        case .nodeHeldObject:
            try registerNode(kind: .heldObject, payload: .heldObject(
                parameter: command.parameter,
                offset: try vec3(command, at: 2),
                function: try command.readUInt64(logicalOffset: 8)
            ))
            currentOffset = program.nextOffset(after: command)
        case .nodeScale:
            try registerNode(kind: .scale, payload: .scale(
                layer: command.parameter & 0x0f,
                fixedScale: try command.readUInt32(logicalOffset: 4),
                displayList: command.parameter & 0x80 == 0 ? nil : try command.readUInt64(logicalOffset: 8)
            ))
            currentOffset = program.nextOffset(after: command)
        case .nodeCullingRadius:
            try registerNode(kind: .cullingRadius, payload: .cullingRadius(try command.readInt16(logicalOffset: 2)))
            currentOffset = program.nextOffset(after: command)
        }
    }

    private mutating func registerNode(kind: SM64GeoNodeKind, payload: SM64GeoNodePayload) throws {
        let id = nodes.count
        let parent = nodeDepth == 0 ? nil : nodeAtDepth[nodeDepth - 1]
        if nodeDepth == 0 {
            guard rootNode == nil else { throw SM64GeoLayoutError.sceneRootAlreadyExists }
            rootNode = id
        }
        nodes.append(SM64GeoLayoutSceneNode(id: id, kind: kind, parent: parent, children: [], flags: 0, payload: payload))
        if let parent { nodes[parent].children.append(id) }
        if nodeAtDepth.count > nodeDepth {
            nodeAtDepth[nodeDepth] = id
        } else {
            nodeAtDepth.append(id)
        }
        currentNode = id
    }

    private mutating func branchStackPush(_ target: Int?) throws {
        guard let target else { throw SM64GeoLayoutError.invalidTarget(offset: currentOffset ?? 0, target: 0) }
        branchStack.append(target)
    }

    private mutating func jump(_ command: SM64GeoLayoutCommand, logicalOffset: Int) throws {
        currentOffset = try targetResolver.targetOffset(from: command, logicalOffset: logicalOffset, in: program)
    }

    private func vec3(_ command: SM64GeoLayoutCommand, at logicalOffset: Int) throws -> SM64GeoVec3s {
        SM64GeoVec3s(
            x: try command.readInt16(logicalOffset: logicalOffset),
            y: try command.readInt16(logicalOffset: logicalOffset + 2),
            z: try command.readInt16(logicalOffset: logicalOffset + 4)
        )
    }
}
