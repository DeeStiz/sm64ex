import Foundation

enum SM64MarioFaceEyeState: UInt32, Sendable {
    case blink = 0
    case open = 1
    case halfClosed = 2
    case closed = 3
    case lookLeft = 4
    case lookRight = 5
    case lookUp = 6
    case lookDown = 7
    case dead = 8
}

enum SM64MarioFaceHandState: UInt32, Sendable {
    case fists = 0
    case open = 1
    case peaceSign = 2
    case holdingCap = 3
    case holdingWingCap = 4
    case rightOpen = 5
}

enum SM64MarioFaceCapState: UInt32, Sendable {
    case defaultOn = 0
    case defaultOff = 1
    case wingOn = 2
    case wingOff = 3
}

struct SM64MarioFaceInput: Equatable, Sendable {
    let bodyIndex: UInt32
    let areaUpdateCounter: UInt32
    let eyeState: UInt32
    let action: UInt32
    let handState: UInt32
    let handSwitchCaseCount: UInt32
    let capState: UInt32
    let modelState: UInt32
}

struct SM64MarioFaceRenderPacket: Equatable, Sendable {
    let blinkFrame: UInt32
    let eyeCase: UInt32
    let handCase: UInt32
    let standRunCase: UInt32
    let capEffectCase: UInt32
    let capOnOffCase: UInt32
    let wingActive: UInt32
    let alpha: UInt32
    let materialMode: UInt32
}

struct SM64MarioFaceGeometryDescriptor: Equatable, Sendable {
    let masterGroupID: UInt32
    let faceShapeID: UInt32
    let vertexGroupID: UInt32
    let faceGroupID: UInt32
    let materialGroupID: UInt32
    let vertexCount: UInt32
    let faceCount: UInt32
    let materialCount: UInt32
    let componentIDs: [UInt32]
    let primaryAnimationFrames: UInt32
    let secondaryAnimationFrames: UInt32
}

/// Swift value boundary for the product-reachable Mario face switches and the
/// Goddard face asset inventory. It mirrors the source geo callbacks without
/// importing graph-node pointers or mutating a render tree.
enum SM64MarioFace {
    static let stationaryActionMask: UInt32 = 1 << 9
    static let swimmingOrFlyingActionMask: UInt32 = 1 << 28
    static let blinkAnimation: [UInt32] = [1, 2, 1, 0, 1, 2, 1]

    static let geometry = SM64MarioFaceGeometryDescriptor(
        masterGroupID: 0x3E8,
        faceShapeID: 0xE1,
        vertexGroupID: 0xDE,
        faceGroupID: 0xDF,
        materialGroupID: 0xE0,
        vertexCount: 440,
        faceCount: 877,
        materialCount: 8,
        componentIDs: [
            0x07, 0x10, 0x20, 0x29, 0x32, 0x3F, 0x42, 0x48, 0x4B, 0x54,
            0x6B, 0x7B, 0x84, 0x96, 0x9F, 0xA8, 0xB1, 0xBA, 0xC3, 0xC6,
            0xCF, 0xD8,
        ],
        primaryAnimationFrames: 820,
        secondaryAnimationFrames: 166
    )

    static func resolve(_ input: SM64MarioFaceInput) -> SM64MarioFaceRenderPacket {
        let blinkFrame: UInt32
        let eyeCase: UInt32
        if input.eyeState == SM64MarioFaceEyeState.blink.rawValue {
            blinkFrame = ((input.bodyIndex &* 32 &+ input.areaUpdateCounter) >> 1) & 0x1F
            eyeCase = blinkFrame < UInt32(blinkAnimation.count)
                ? blinkAnimation[Int(blinkFrame)]
                : 0
        } else {
            blinkFrame = 0
            eyeCase = input.eyeState &- 1
        }

        let handCase: UInt32
        if input.handState == SM64MarioFaceHandState.fists.rawValue {
            handCase = (input.action & swimmingOrFlyingActionMask) != 0 ? 1 : 0
        } else if input.handSwitchCaseCount == 0 {
            handCase = input.handState < 5 ? input.handState : SM64MarioFaceHandState.open.rawValue
        } else {
            handCase = input.handState < 2 ? input.handState : SM64MarioFaceHandState.fists.rawValue
        }

        return SM64MarioFaceRenderPacket(
            blinkFrame: blinkFrame,
            eyeCase: eyeCase,
            handCase: handCase,
            standRunCase: (input.action & stationaryActionMask) == 0 ? 1 : 0,
            capEffectCase: input.modelState >> 8,
            capOnOffCase: input.capState & 1,
            wingActive: (input.capState & 2) != 0 ? 1 : 0,
            alpha: (input.modelState & 0x100) != 0 ? input.modelState & 0xFF : 255,
            materialMode: input.modelState & 0x300
        )
    }
}

enum SM64MarioFaceFingerprint {
    static let offset: UInt64 = 1_469_598_103_934_665_603
    static let prime: UInt64 = 1_099_511_628_211

    private static func hash(_ initial: UInt64, _ value: UInt64) -> UInt64 {
        var result = initial
        for byte in 0..<8 {
            result ^= (value >> UInt64(byte * 8)) & 0xFF
            result &*= prime
        }
        return result
    }

    static func geometry(_ descriptor: SM64MarioFaceGeometryDescriptor) -> UInt64 {
        var result = offset
        for value in [
            descriptor.masterGroupID, descriptor.faceShapeID, descriptor.vertexGroupID,
            descriptor.faceGroupID, descriptor.materialGroupID, descriptor.vertexCount,
            descriptor.faceCount, descriptor.materialCount,
        ] {
            result = hash(result, UInt64(value))
        }
        result = hash(result, UInt64(descriptor.componentIDs.count))
        for componentID in descriptor.componentIDs {
            result = hash(result, UInt64(componentID))
        }
        result = hash(result, UInt64(descriptor.primaryAnimationFrames))
        return hash(result, UInt64(descriptor.secondaryAnimationFrames))
    }

    static func packet(_ initial: UInt64, _ packet: SM64MarioFaceRenderPacket) -> UInt64 {
        var result = initial
        for value in [
            packet.blinkFrame, packet.eyeCase, packet.handCase, packet.standRunCase,
            packet.capEffectCase, packet.capOnOffCase, packet.wingActive, packet.alpha,
            packet.materialMode,
        ] {
            result = hash(result, UInt64(value))
        }
        return result
    }
}
