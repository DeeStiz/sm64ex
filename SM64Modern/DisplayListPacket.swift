import Foundation

// The legacy renderer owns the raw Gfx graph. Swift receives only copied
// 32-bit words and stable resource IDs; it never follows a C display-list
// pointer. This value boundary is deliberately independent of Metal object
// lifetimes so it can be compared with the C renderer oracle before encoding.

enum SM64DisplayListCommandKind: UInt8, CaseIterable, Sendable {
    case unknown = 0
    case noOp = 1
    case vertex = 2
    case modifyVertex = 3
    case cullDisplayList = 4
    case branchZ = 5
    case triangle1 = 6
    case triangle2 = 7
    case quad = 8
    case line3D = 9
    case special3 = 10
    case special2 = 11
    case special1 = 12
    case dmaIO = 13
    case texture = 14
    case popMatrix = 15
    case geometryMode = 16
    case matrix = 17
    case moveWord = 18
    case moveMemory = 19
    case displayList = 20
    case loadUCode = 21
    case spNoOp = 22
    case rdpHalf1 = 23
    case setOtherModeLow = 24
    case setOtherModeHigh = 25
    case endDisplayList = 26
    case rdpHalf2 = 27
    case setColorImage = 28
    case setDepthImage = 29
    case setTextureImage = 30
    case setCombine = 31
    case setEnvironmentColor = 32
    case setPrimitiveColor = 33
    case setBlendColor = 34
    case setFogColor = 35
    case setFillColor = 36
    case fillRectangle = 37
    case setTile = 38
    case loadTile = 39
    case loadBlock = 40
    case setTileSize = 41
    case loadTLUT = 42
    case rdpSetOtherMode = 43
    case setPrimitiveDepth = 44
    case setScissor = 45
    case setConvert = 46
    case setKeyR = 47
    case setKeyGB = 48
    case fullSync = 49
    case tileSync = 50
    case pipeSync = 51
    case loadSync = 52
    case textureRectangleFlip = 53
    case textureRectangle = 54
    case renderLayer = 55
}

struct SM64DisplayListWords: Equatable, Sendable {
    let word0: UInt32
    let word1: UInt32

    var opcode: UInt8 {
        UInt8(truncatingIfNeeded: word0 >> 24)
    }
}

struct SM64DisplayListState: Equatable, Sendable {
    let geometryMode: UInt32
    let textureScaleS: UInt32
    let textureScaleT: UInt32
    let textureTile: UInt32
    let textureLevel: UInt32
    let textureEnabled: UInt32
    let otherModeHigh: UInt32
    let otherModeLow: UInt32
    let combineHigh: UInt32
    let combineLow: UInt32
    let colorImageResourceID: UInt32
    let depthImageResourceID: UInt32
    let textureImageResourceID: UInt32
    let environmentColor: UInt32
    let primitiveColor: UInt32
    let blendColor: UInt32
    let fogColor: UInt32
    let fillColor: UInt32
    let scissorX: UInt32
    let scissorY: UInt32
    let scissorLrx: UInt32
    let scissorLry: UInt32
    let scissorMode: UInt32
    let scissorSet: UInt32
    let viewportResourceID: UInt32
    let viewportOffset: UInt32
    let lightCount: UInt32
    let fogMode: UInt32
    let renderLayer: UInt32
    let matrixDepth: UInt32
    let vertexResourceID: UInt32
    let tileWords0: [UInt32]
    let tileWords1: [UInt32]

    static let empty = SM64DisplayListState(
        geometryMode: 0,
        textureScaleS: 0,
        textureScaleT: 0,
        textureTile: 0,
        textureLevel: 0,
        textureEnabled: 0,
        otherModeHigh: 0,
        otherModeLow: 0,
        combineHigh: 0,
        combineLow: 0,
        colorImageResourceID: 0,
        depthImageResourceID: 0,
        textureImageResourceID: 0,
        environmentColor: 0,
        primitiveColor: 0,
        blendColor: 0,
        fogColor: 0,
        fillColor: 0,
        scissorX: 0,
        scissorY: 0,
        scissorLrx: 0,
        scissorLry: 0,
        scissorMode: 0,
        scissorSet: 0,
        viewportResourceID: 0,
        viewportOffset: 0,
        lightCount: 0,
        fogMode: 0,
        renderLayer: 0,
        matrixDepth: 0,
        vertexResourceID: 0,
        tileWords0: Array(repeating: 0, count: 8),
        tileWords1: Array(repeating: 0, count: 8)
    )
}

struct SM64DisplayListCommand: Equatable, Sendable {
    let index: UInt32
    let opcode: UInt8
    let kind: SM64DisplayListCommandKind
    let word0: UInt32
    let word1: UInt32
    let argument0: UInt32
    let argument1: UInt32
    let argument2: UInt32
    let resourceID: UInt32
    let state: SM64DisplayListState
}

struct SM64DisplayListDraw: Equatable, Sendable {
    let commandIndex: UInt32
    let primitive: SM64DisplayListCommandKind
    let renderLayer: UInt32
    let vertexResourceID: UInt32
    let triangleCount: UInt32
    let state: SM64DisplayListState
}

struct SM64DisplayListPacket: Equatable, Sendable {
    let sequence: UInt64
    let commands: [SM64DisplayListCommand]
    let draws: [SM64DisplayListDraw]
    let finalState: SM64DisplayListState
    let isComplete: Bool
    let truncated: Bool
    let unsupportedCommandCount: UInt32
    let fingerprint: UInt64
}

struct SM64DisplayListPacketFingerprint {
    static let offset: UInt64 = 1_469_598_103_934_665_603
    static let prime: UInt64 = 1_099_511_628_211

    private static func hashU32(_ hash: UInt64, _ value: UInt32) -> UInt64 {
        var result = hash
        for shift in stride(from: 0, through: 24, by: 8) {
            result ^= UInt64((value >> UInt32(shift)) & 0xff)
            result &*= prime
        }
        return result
    }

    private static func hashU64(_ hash: UInt64, _ value: UInt64) -> UInt64 {
        var result = hash
        for shift in stride(from: 0, through: 56, by: 8) {
            result ^= (value >> UInt64(shift)) & 0xff
            result &*= prime
        }
        return result
    }

    static func state(_ state: SM64DisplayListState) -> UInt64 {
        var hash = offset
        let values: [UInt32] = [
            state.geometryMode,
            state.textureScaleS,
            state.textureScaleT,
            state.textureTile,
            state.textureLevel,
            state.textureEnabled,
            state.otherModeHigh,
            state.otherModeLow,
            state.combineHigh,
            state.combineLow,
            state.colorImageResourceID,
            state.depthImageResourceID,
            state.textureImageResourceID,
            state.environmentColor,
            state.primitiveColor,
            state.blendColor,
            state.fogColor,
            state.fillColor,
            state.scissorX,
            state.scissorY,
            state.scissorLrx,
            state.scissorLry,
            state.scissorMode,
            state.scissorSet,
            state.viewportResourceID,
            state.viewportOffset,
            state.lightCount,
            state.fogMode,
            state.renderLayer,
            state.matrixDepth,
            state.vertexResourceID,
        ]
        for value in values {
            hash = hashU32(hash, value)
        }
        for value in state.tileWords0 {
            hash = hashU32(hash, value)
        }
        for value in state.tileWords1 {
            hash = hashU32(hash, value)
        }
        return hash
    }

    static func packet(
        sequence: UInt64,
        commands: [SM64DisplayListCommand],
        draws: [SM64DisplayListDraw],
        finalState: SM64DisplayListState,
        isComplete: Bool,
        truncated: Bool,
        unsupportedCommandCount: UInt32
    ) -> UInt64 {
        var hash = hashU64(offset, sequence)
        hash = hashU32(hash, UInt32(commands.count))
        for command in commands {
            hash = hashU32(hash, command.index)
            hash = hashU32(hash, UInt32(command.opcode))
            hash = hashU32(hash, UInt32(command.kind.rawValue))
            hash = hashU32(hash, command.word0)
            hash = hashU32(hash, command.word1)
            hash = hashU32(hash, command.argument0)
            hash = hashU32(hash, command.argument1)
            hash = hashU32(hash, command.argument2)
            hash = hashU32(hash, command.resourceID)
            hash = hashU64(hash, state(command.state))
        }
        hash = hashU32(hash, UInt32(draws.count))
        for draw in draws {
            hash = hashU32(hash, draw.commandIndex)
            hash = hashU32(hash, UInt32(draw.primitive.rawValue))
            hash = hashU32(hash, draw.renderLayer)
            hash = hashU32(hash, draw.vertexResourceID)
            hash = hashU32(hash, draw.triangleCount)
            hash = hashU64(hash, state(draw.state))
        }
        hash = hashU64(hash, state(finalState))
        hash = hashU32(hash, isComplete ? 1 : 0)
        hash = hashU32(hash, truncated ? 1 : 0)
        return hashU32(hash, unsupportedCommandCount)
    }
}

struct SM64DisplayListPacketBuilder: Sendable {
    private(set) var commands: [SM64DisplayListCommand] = []
    private(set) var draws: [SM64DisplayListDraw] = []
    private(set) var state = SM64DisplayListState.empty
    private(set) var sawEnd = false
    private(set) var truncated = false
    private(set) var unsupportedCommandCount: UInt32 = 0

    private let sequence: UInt64
    private let maxCommands: UInt32

    init(sequence: UInt64 = 1, maxCommands: UInt32 = 4096) {
        self.sequence = sequence
        self.maxCommands = max(1, maxCommands)
        commands.reserveCapacity(min(Int(self.maxCommands), 512))
        draws.reserveCapacity(min(Int(self.maxCommands), 512))
    }

    mutating func append(_ words: SM64DisplayListWords) -> Bool {
        append(
            opcode: words.opcode,
            kind: Self.kind(for: words.opcode),
            word0: words.word0,
            word1: words.word1
        )
    }

    mutating func appendRenderLayer(_ layer: UInt32) -> Bool {
        append(opcode: 0, kind: .renderLayer, word0: layer, word1: 0)
    }

    mutating func finish() -> SM64DisplayListPacket {
        let complete = sawEnd && !truncated
        let fingerprint = SM64DisplayListPacketFingerprint.packet(
            sequence: sequence,
            commands: commands,
            draws: draws,
            finalState: state,
            isComplete: complete,
            truncated: truncated,
            unsupportedCommandCount: unsupportedCommandCount
        )
        return SM64DisplayListPacket(
            sequence: sequence,
            commands: commands,
            draws: draws,
            finalState: state,
            isComplete: complete,
            truncated: truncated,
            unsupportedCommandCount: unsupportedCommandCount,
            fingerprint: fingerprint
        )
    }

    private mutating func append(opcode: UInt8, kind: SM64DisplayListCommandKind, word0: UInt32, word1: UInt32) -> Bool {
        guard UInt32(commands.count) < maxCommands else {
            truncated = true
            return false
        }

        var argument0: UInt32 = 0
        var argument1: UInt32 = 0
        var argument2: UInt32 = 0
        var resourceID: UInt32 = 0
        let index = UInt32(commands.count)

        switch kind {
        case .geometryMode:
            state = state.with(
                geometryMode: (state.geometryMode & (word0 & 0x00ff_ffff)) | word1
            )
            argument0 = word0 & 0x00ff_ffff
            argument1 = word1
        case .texture:
            state = state.with(
                textureScaleS: word1 >> 16,
                textureScaleT: word1 & 0xffff,
                textureTile: (word0 >> 8) & 0x7,
                textureLevel: (word0 >> 11) & 0x7,
                textureEnabled: (word0 >> 1) & 0x7f
            )
            argument0 = state.textureTile
            argument1 = state.textureLevel
            argument2 = state.textureEnabled
        case .matrix:
            resourceID = word1
            argument0 = (word0 >> 19) & 0x1f
            if (word0 & 0xff) & 0x1 != 0 {
                state = state.with(matrixDepth: state.matrixDepth &+ 1)
            }
        case .popMatrix:
            argument0 = max(1, (word0 >> 19) & 0x1f)
            state = state.with(matrixDepth: state.matrixDepth >= argument0 ? state.matrixDepth - argument0 : 0)
        case .moveMemory:
            let index = word0 & 0xff
            let offset = (word0 >> 8) & 0xff
            argument0 = index
            argument1 = offset
            resourceID = word1
            if index == 8 {
                state = state.with(viewportResourceID: word1, viewportOffset: offset)
            } else if index == 10 {
                state = state.with(lightCount: max(state.lightCount, offset / 24))
            }
        case .moveWord:
            let index = (word0 >> 16) & 0xff
            let offset = word0 & 0xffff
            argument0 = index
            argument1 = offset
            argument2 = word1
            if index == 2 {
                state = state.with(lightCount: word1)
            } else if index == 8 {
                state = state.with(fogMode: word1)
            }
        case .vertex:
            resourceID = word1
            argument0 = (word0 >> 12) & 0xff
            argument1 = (word0 >> 1) & 0x7f
            state = state.with(vertexResourceID: word1)
        case .displayList:
            resourceID = word1
            argument0 = word0 & 0xff
        case .branchZ:
            resourceID = word1
            argument0 = (word0 >> 12) & 0xfff
            argument1 = word0 & 0xfff
            argument2 = word1
        case .triangle1:
            argument0 = (word1 >> 16) & 0xff
            argument1 = (word1 >> 8) & 0xff
            argument2 = word1 & 0xff
        case .triangle2:
            argument0 = (word0 >> 16) & 0xff
            argument1 = (word0 >> 8) & 0xff
            argument2 = word1
        case .setOtherModeHigh:
            state = state.with(otherModeHigh: word1)
            argument0 = (word0 >> 8) & 0xff
            argument1 = word1
        case .setOtherModeLow, .rdpSetOtherMode:
            state = state.with(otherModeLow: word1, renderLayer: (word1 >> 16) & 0xff)
            argument0 = (word0 >> 8) & 0xff
            argument1 = word1
        case .setColorImage:
            state = state.with(colorImageResourceID: word1)
            resourceID = word1
        case .setDepthImage:
            state = state.with(depthImageResourceID: word1)
            resourceID = word1
        case .setTextureImage:
            state = state.with(textureImageResourceID: word1)
            resourceID = word1
        case .setCombine:
            state = state.with(combineHigh: word0 & 0x00ff_ffff, combineLow: word1)
            argument0 = word0 & 0x00ff_ffff
            argument1 = word1
        case .setEnvironmentColor:
            state = state.with(environmentColor: word1)
        case .setPrimitiveColor:
            state = state.with(primitiveColor: word1)
        case .setBlendColor:
            state = state.with(blendColor: word1)
        case .setFogColor:
            state = state.with(fogColor: word1)
        case .setFillColor:
            state = state.with(fillColor: word1)
        case .setScissor:
            state = state.with(
                scissorX: (word0 >> 12) & 0xfff,
                scissorY: word0 & 0xfff,
                scissorLrx: (word1 >> 12) & 0xfff,
                scissorLry: word1 & 0xfff,
                scissorMode: (word1 >> 24) & 0x3,
                scissorSet: 1
            )
        case .setTile, .loadTile, .loadBlock, .setTileSize:
            let tile = Int((word1 >> 24) & 0x7)
            argument0 = UInt32(tile)
            if tile < state.tileWords0.count {
                var words0 = state.tileWords0
                var words1 = state.tileWords1
                words0[tile] = word0
                words1[tile] = word1
                state = state.with(tileWords0: words0, tileWords1: words1)
            }
        case .renderLayer:
            state = state.with(renderLayer: word0)
            argument0 = word0
        case .endDisplayList:
            sawEnd = true
        case .fillRectangle, .textureRectangle, .textureRectangleFlip:
            argument0 = word0 & 0x00ff_ffff
            argument1 = word1
        case .unknown:
            unsupportedCommandCount &+= 1
        default:
            break
        }

        let command = SM64DisplayListCommand(
            index: index,
            opcode: opcode,
            kind: kind,
            word0: word0,
            word1: word1,
            argument0: argument0,
            argument1: argument1,
            argument2: argument2,
            resourceID: resourceID,
            state: state
        )
        commands.append(command)

        let triangleCount: UInt32?
        switch kind {
        case .triangle1, .line3D, .textureRectangle, .textureRectangleFlip, .fillRectangle:
            triangleCount = 1
        case .triangle2, .quad:
            triangleCount = 2
        default:
            triangleCount = nil
        }
        if let triangleCount {
            draws.append(SM64DisplayListDraw(
                commandIndex: index,
                primitive: kind,
                renderLayer: state.renderLayer,
                vertexResourceID: state.vertexResourceID,
                triangleCount: triangleCount,
                state: state
            ))
        }
        return true
    }

    private static func kind(for opcode: UInt8) -> SM64DisplayListCommandKind {
        switch opcode {
        case 0x00: return .noOp
        case 0x01: return .vertex
        case 0x02: return .modifyVertex
        case 0x03: return .cullDisplayList
        case 0x04: return .branchZ
        case 0x05: return .triangle1
        case 0x06: return .triangle2
        case 0x07: return .quad
        case 0x08: return .line3D
        case 0xd3: return .special3
        case 0xd4: return .special2
        case 0xd5: return .special1
        case 0xd6: return .dmaIO
        case 0xd7: return .texture
        case 0xd8: return .popMatrix
        case 0xd9: return .geometryMode
        case 0xda: return .matrix
        case 0xdb: return .moveWord
        case 0xdc: return .moveMemory
        case 0xdd: return .loadUCode
        case 0xde: return .displayList
        case 0xdf: return .endDisplayList
        case 0xe0: return .spNoOp
        case 0xe1: return .rdpHalf1
        case 0xe2: return .setOtherModeLow
        case 0xe3: return .setOtherModeHigh
        case 0xe4: return .textureRectangle
        case 0xe5: return .textureRectangleFlip
        case 0xe6: return .loadSync
        case 0xe7: return .pipeSync
        case 0xe8: return .tileSync
        case 0xe9: return .fullSync
        case 0xea: return .setKeyGB
        case 0xeb: return .setKeyR
        case 0xec: return .setConvert
        case 0xed: return .setScissor
        case 0xee: return .setPrimitiveDepth
        case 0xef: return .rdpSetOtherMode
        case 0xf0: return .loadTLUT
        case 0xf1: return .rdpHalf2
        case 0xf2: return .setTileSize
        case 0xf3: return .loadBlock
        case 0xf4: return .loadTile
        case 0xf5: return .setTile
        case 0xf6: return .fillRectangle
        case 0xf7: return .setFillColor
        case 0xf8: return .setFogColor
        case 0xf9: return .setBlendColor
        case 0xfa: return .setPrimitiveColor
        case 0xfb: return .setEnvironmentColor
        case 0xfc: return .setCombine
        case 0xfd: return .setTextureImage
        case 0xfe: return .setDepthImage
        case 0xff: return .setColorImage
        default: return .unknown
        }
    }
}

struct SM64DisplayListDecoder: Sendable {
    static func decode(
        _ words: [SM64DisplayListWords],
        sequence: UInt64 = 1,
        maxCommands: UInt32 = 4096
    ) -> SM64DisplayListPacket {
        var builder = SM64DisplayListPacketBuilder(sequence: sequence, maxCommands: maxCommands)
        for word in words {
            guard builder.append(word) else { break }
        }
        return builder.finish()
    }
}

private extension SM64DisplayListState {
    func with(
        geometryMode: UInt32? = nil,
        textureScaleS: UInt32? = nil,
        textureScaleT: UInt32? = nil,
        textureTile: UInt32? = nil,
        textureLevel: UInt32? = nil,
        textureEnabled: UInt32? = nil,
        otherModeHigh: UInt32? = nil,
        otherModeLow: UInt32? = nil,
        combineHigh: UInt32? = nil,
        combineLow: UInt32? = nil,
        colorImageResourceID: UInt32? = nil,
        depthImageResourceID: UInt32? = nil,
        textureImageResourceID: UInt32? = nil,
        environmentColor: UInt32? = nil,
        primitiveColor: UInt32? = nil,
        blendColor: UInt32? = nil,
        fogColor: UInt32? = nil,
        fillColor: UInt32? = nil,
        scissorX: UInt32? = nil,
        scissorY: UInt32? = nil,
        scissorLrx: UInt32? = nil,
        scissorLry: UInt32? = nil,
        scissorMode: UInt32? = nil,
        scissorSet: UInt32? = nil,
        viewportResourceID: UInt32? = nil,
        viewportOffset: UInt32? = nil,
        lightCount: UInt32? = nil,
        fogMode: UInt32? = nil,
        renderLayer: UInt32? = nil,
        matrixDepth: UInt32? = nil,
        vertexResourceID: UInt32? = nil,
        tileWords0: [UInt32]? = nil,
        tileWords1: [UInt32]? = nil
    ) -> SM64DisplayListState {
        SM64DisplayListState(
            geometryMode: geometryMode ?? self.geometryMode,
            textureScaleS: textureScaleS ?? self.textureScaleS,
            textureScaleT: textureScaleT ?? self.textureScaleT,
            textureTile: textureTile ?? self.textureTile,
            textureLevel: textureLevel ?? self.textureLevel,
            textureEnabled: textureEnabled ?? self.textureEnabled,
            otherModeHigh: otherModeHigh ?? self.otherModeHigh,
            otherModeLow: otherModeLow ?? self.otherModeLow,
            combineHigh: combineHigh ?? self.combineHigh,
            combineLow: combineLow ?? self.combineLow,
            colorImageResourceID: colorImageResourceID ?? self.colorImageResourceID,
            depthImageResourceID: depthImageResourceID ?? self.depthImageResourceID,
            textureImageResourceID: textureImageResourceID ?? self.textureImageResourceID,
            environmentColor: environmentColor ?? self.environmentColor,
            primitiveColor: primitiveColor ?? self.primitiveColor,
            blendColor: blendColor ?? self.blendColor,
            fogColor: fogColor ?? self.fogColor,
            fillColor: fillColor ?? self.fillColor,
            scissorX: scissorX ?? self.scissorX,
            scissorY: scissorY ?? self.scissorY,
            scissorLrx: scissorLrx ?? self.scissorLrx,
            scissorLry: scissorLry ?? self.scissorLry,
            scissorMode: scissorMode ?? self.scissorMode,
            scissorSet: scissorSet ?? self.scissorSet,
            viewportResourceID: viewportResourceID ?? self.viewportResourceID,
            viewportOffset: viewportOffset ?? self.viewportOffset,
            lightCount: lightCount ?? self.lightCount,
            fogMode: fogMode ?? self.fogMode,
            renderLayer: renderLayer ?? self.renderLayer,
            matrixDepth: matrixDepth ?? self.matrixDepth,
            vertexResourceID: vertexResourceID ?? self.vertexResourceID,
            tileWords0: tileWords0 ?? self.tileWords0,
            tileWords1: tileWords1 ?? self.tileWords1
        )
    }
}
