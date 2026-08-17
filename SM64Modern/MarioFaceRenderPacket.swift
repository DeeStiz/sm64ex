import Foundation

enum SM64MarioFaceRenderMaterialPolicy: UInt32, Sendable {
    /// Keep the source face-local material assignment in its material group;
    /// this packet does not guess a texture or a replacement material.
    case sourceMaterialGroup = 0
}

enum SM64MarioFaceRenderLODPolicy: UInt32, Sendable {
    /// Use the source mesh at its authored vertex/face counts. No distance LOD
    /// is claimed until a later route/resource pass supplies camera evidence.
    case sourceFullResolution = 0
}

struct SM64MarioFaceRenderMeshRecord: Equatable, Sendable {
    let meshID: UInt32
    let shapeID: UInt32
    let vertexGroupID: UInt32
    let planeGroupID: UInt32
    let materialGroupID: UInt32
    let vertexCount: UInt32
    let faceCount: UInt32
    let materialCount: UInt32
    let materialPolicy: SM64MarioFaceRenderMaterialPolicy
    let lodPolicy: SM64MarioFaceRenderLODPolicy
    let materialIDs: [UInt32]
}

struct SM64MarioFaceRenderAnimationAttachment: Equatable, Sendable {
    let componentID: UInt32
    let animatorID: UInt32
    let parentGroupID: UInt32
    let dataGroupID: UInt32
    let nodeGroupID: UInt32
    let linkedObjectID: UInt32
    let available: Bool
    let transformType: UInt32
    let currentSourceFrame: UInt32
    let nextSourceFrame: UInt32
    let fractionQ16: UInt32
    let values: [Float]
}

struct SM64MarioFaceRenderFramePacket: Equatable, Sendable {
    let catalogFingerprint: UInt64
    let masterGroupID: UInt32
    let animationParentGroupID: UInt32
    let animationBank: UInt32
    let animationFrameQ16: UInt32
    let face: SM64MarioFaceRenderPacket
    let eyeOverrideState: UInt32
    let eyeOverrideSource: UInt32
    let channelMask: UInt64
    let residentChannelCount: UInt32
    let unavailableChannelCount: UInt32
    let meshes: [SM64MarioFaceRenderMeshRecord]
    let lights: [SM64MarioFaceLightingResource]
    let animations: [SM64MarioFaceRenderAnimationAttachment]
}

/// Joins M30j values to M30k resource IDs without touching a graph node,
/// texture, camera, Metal encoder, or reusable renderer storage. This is the
/// final value packet before a route-specific C render-oracle comparison.
enum SM64MarioFaceRenderPacketBuilder {
    static func make(
        input: SM64MarioFaceExpressionInput,
        bundle: SM64MarioFacePayloadBundle
    ) -> SM64MarioFaceRenderFramePacket {
        let composition = SM64MarioFaceExpressionComposition.compose(input: input, bundle: bundle)
        let meshes = SM64MarioFaceResourceCatalog.meshes.map { mesh in
            SM64MarioFaceRenderMeshRecord(
                meshID: mesh.meshID,
                shapeID: mesh.shapeID,
                vertexGroupID: mesh.vertexGroupID,
                planeGroupID: mesh.planeGroupID,
                materialGroupID: mesh.materialGroupID,
                vertexCount: mesh.vertexCount,
                faceCount: mesh.faceCount,
                materialCount: mesh.materialCount,
                materialPolicy: .sourceMaterialGroup,
                lodPolicy: .sourceFullResolution,
                materialIDs: SM64MarioFaceResourceCatalog.materials
                    .filter { $0.meshID == mesh.meshID }
                    .map(\.materialID)
            )
        }
        let animations = zip(
            SM64MarioFaceResourceCatalog.animationBindings,
            composition.channels
        ).map { binding, channel in
            SM64MarioFaceRenderAnimationAttachment(
                componentID: binding.componentID,
                animatorID: binding.animatorID,
                parentGroupID: binding.parentGroupID,
                dataGroupID: binding.dataGroupID,
                nodeGroupID: binding.nodeGroupID,
                linkedObjectID: binding.linkedObjectID,
                available: channel.available,
                transformType: channel.transformType,
                currentSourceFrame: channel.currentSourceFrame,
                nextSourceFrame: channel.nextSourceFrame,
                fractionQ16: channel.fractionQ16,
                values: channel.values
            )
        }
        return SM64MarioFaceRenderFramePacket(
            catalogFingerprint: SM64MarioFaceResourceCatalogFingerprint.catalog(),
            masterGroupID: SM64MarioFaceResourceCatalog.masterGroupID,
            animationParentGroupID: SM64MarioFaceResourceCatalog.animationParentGroupID,
            animationBank: composition.animationBank,
            animationFrameQ16: composition.animationFrameQ16,
            face: composition.face,
            eyeOverrideState: composition.eyeOverrideState,
            eyeOverrideSource: composition.eyeOverrideSource,
            channelMask: composition.channelMask,
            residentChannelCount: composition.residentChannelCount,
            unavailableChannelCount: composition.unavailableChannelCount,
            meshes: meshes,
            lights: SM64MarioFaceResourceCatalog.lights,
            animations: animations
        )
    }
}

enum SM64MarioFaceRenderPacketFingerprint {
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

    private static func hash(_ initial: UInt64, _ value: UInt32) -> UInt64 {
        hash(initial, UInt64(value))
    }

    private static func hash(_ initial: UInt64, _ values: [UInt32]) -> UInt64 {
        values.reduce(initial) { hash($0, UInt64($1)) }
    }

    static let seed: UInt64 = hash(
        offset,
        SM64MarioFaceResourceCatalogFingerprint.catalog()
    )

    static func packet(_ packet: SM64MarioFaceRenderFramePacket) -> UInt64 {
        var result = hash(offset, packet.catalogFingerprint)
        result = hash(result, [
            packet.masterGroupID, packet.animationParentGroupID,
            packet.animationBank, packet.animationFrameQ16,
        ])
        result = hash(result, [
            packet.face.blinkFrame, packet.face.eyeCase, packet.face.handCase,
            packet.face.standRunCase, packet.face.capEffectCase,
            packet.face.capOnOffCase, packet.face.wingActive, packet.face.alpha,
            packet.face.materialMode, packet.eyeOverrideState,
            packet.eyeOverrideSource,
        ])
        result = hash(result, UInt32(truncatingIfNeeded: packet.channelMask))
        result = hash(result, UInt32(truncatingIfNeeded: packet.channelMask >> 32))
        result = hash(result, [packet.residentChannelCount, packet.unavailableChannelCount])

        result = hash(result, UInt64(packet.meshes.count))
        for mesh in packet.meshes {
            result = hash(result, [
                mesh.meshID, mesh.shapeID, mesh.vertexGroupID, mesh.planeGroupID,
                mesh.materialGroupID, mesh.vertexCount, mesh.faceCount,
                mesh.materialCount, mesh.materialPolicy.rawValue, mesh.lodPolicy.rawValue,
                UInt32(mesh.materialIDs.count),
            ])
            result = hash(result, mesh.materialIDs)
        }

        result = hash(result, UInt64(packet.lights.count))
        for light in packet.lights {
            result = hash(result, [light.objectID, light.logicalID, light.flags])
            result = hash(result, light.diffuseRGB1000)
        }

        result = hash(result, UInt64(packet.animations.count))
        for animation in packet.animations {
            result = hash(result, [
                animation.componentID, animation.animatorID, animation.parentGroupID,
                animation.dataGroupID, animation.nodeGroupID, animation.linkedObjectID,
                animation.available ? 1 : 0, animation.transformType,
                animation.currentSourceFrame, animation.nextSourceFrame,
                animation.fractionQ16, UInt32(animation.values.count),
            ])
            for value in animation.values {
                result = hash(result, UInt64(value.bitPattern))
            }
        }
        return result
    }
}
