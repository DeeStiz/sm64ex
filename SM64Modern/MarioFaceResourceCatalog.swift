import Foundation

struct SM64MarioFaceMeshResource: Equatable, Sendable {
    let meshID: UInt32
    let sourcePath: String
    let vertexGroupID: UInt32
    let planeGroupID: UInt32
    let materialGroupID: UInt32
    let shapeID: UInt32
    let vertexCount: UInt32
    let faceCount: UInt32
    let materialCount: UInt32
}

struct SM64MarioFaceMaterialResource: Equatable, Sendable {
    let meshID: UInt32
    let materialGroupID: UInt32
    let materialID: UInt32
    /// Source Goddard colors are stored as thousandths to avoid a platform-
    /// dependent floating-point serialization boundary in the resource graph.
    let ambientRGB1000: [UInt32]
    let diffuseRGB1000: [UInt32]
}

struct SM64MarioFaceLightingResource: Equatable, Sendable {
    let objectID: UInt32
    let logicalID: UInt32
    let flags: UInt32
    let diffuseRGB1000: [UInt32]
}

struct SM64MarioFaceAnimationBinding: Equatable, Sendable {
    let componentID: UInt32
    let animatorID: UInt32
    let parentGroupID: UInt32
    let dataGroupID: UInt32
    let nodeGroupID: UInt32
    let linkedObjectID: UInt32
}

/// Pointer-free bindings for the Mario Goddard face graph. This is an
/// immutable source catalog only: it names graph IDs and geometry/material
/// metadata, but does not make the C dynlists or a Metal renderer authoritative.
enum SM64MarioFaceResourceCatalog {
    static let masterGroupID: UInt32 = 0x3E8
    static let animationParentGroupID: UInt32 = 0x3E9

    static let meshes: [SM64MarioFaceMeshResource] = [
        .init(
            meshID: 1,
            sourcePath: "src/goddard/dynlists/dynlist_mario_face.c",
            vertexGroupID: 0xDE,
            planeGroupID: 0xDF,
            materialGroupID: 0xE0,
            shapeID: 0xE1,
            vertexCount: 440,
            faceCount: 877,
            materialCount: 8
        ),
        .init(
            meshID: 2,
            sourcePath: "src/goddard/dynlists/dynlists_mario_eyes.c",
            vertexGroupID: 0x71,
            planeGroupID: 0x72,
            materialGroupID: 0x73,
            shapeID: 0x74,
            vertexCount: 48,
            faceCount: 82,
            materialCount: 4
        ),
        .init(
            meshID: 3,
            sourcePath: "src/goddard/dynlists/dynlists_mario_eyes.c",
            vertexGroupID: 0x61,
            planeGroupID: 0x62,
            materialGroupID: 0x63,
            shapeID: 0x64,
            vertexCount: 48,
            faceCount: 82,
            materialCount: 4
        ),
        .init(
            meshID: 4,
            sourcePath: "src/goddard/dynlists/dynlists_mario_eyebrows_mustache.c",
            vertexGroupID: 0x5A,
            planeGroupID: 0x5B,
            materialGroupID: 0x5C,
            shapeID: 0x5D,
            vertexCount: 26,
            faceCount: 36,
            materialCount: 1
        ),
        .init(
            meshID: 5,
            sourcePath: "src/goddard/dynlists/dynlists_mario_eyebrows_mustache.c",
            vertexGroupID: 0x38,
            planeGroupID: 0x39,
            materialGroupID: 0x3A,
            shapeID: 0x3B,
            vertexCount: 26,
            faceCount: 36,
            materialCount: 1
        ),
        .init(
            meshID: 6,
            sourcePath: "src/goddard/dynlists/dynlists_mario_eyebrows_mustache.c",
            vertexGroupID: 0x16,
            planeGroupID: 0x17,
            materialGroupID: 0x18,
            shapeID: 0x19,
            vertexCount: 56,
            faceCount: 100,
            materialCount: 1
        ),
    ]

    static let materials: [SM64MarioFaceMaterialResource] = [
        // Face material group 0xE0.
        .init(meshID: 1, materialGroupID: 0xE0, materialID: 0, ambientRGB1000: [1000, 1000, 1000], diffuseRGB1000: [1000, 1000, 1000]),
        .init(meshID: 1, materialGroupID: 0xE0, materialID: 1, ambientRGB1000: [883, 602, 408], diffuseRGB1000: [883, 602, 408]),
        .init(meshID: 1, materialGroupID: 0xE0, materialID: 2, ambientRGB1000: [362, 0, 0], diffuseRGB1000: [362, 0, 0]),
        .init(meshID: 1, materialGroupID: 0xE0, materialID: 3, ambientRGB1000: [1000, 1000, 1000], diffuseRGB1000: [1000, 1000, 1000]),
        .init(meshID: 1, materialGroupID: 0xE0, materialID: 4, ambientRGB1000: [1000, 1000, 1000], diffuseRGB1000: [1000, 1000, 1000]),
        .init(meshID: 1, materialGroupID: 0xE0, materialID: 5, ambientRGB1000: [362, 0, 0], diffuseRGB1000: [362, 0, 0]),
        .init(meshID: 1, materialGroupID: 0xE0, materialID: 6, ambientRGB1000: [526, 0, 0], diffuseRGB1000: [526, 0, 0]),
        .init(meshID: 1, materialGroupID: 0xE0, materialID: 7, ambientRGB1000: [1000, 0, 0], diffuseRGB1000: [1000, 0, 0]),

        // Both eye dynlists use the same four material colors.
        .init(meshID: 2, materialGroupID: 0x73, materialID: 0, ambientRGB1000: [0, 291, 1000], diffuseRGB1000: [0, 291, 1000]),
        .init(meshID: 2, materialGroupID: 0x73, materialID: 1, ambientRGB1000: [0, 576, 1000], diffuseRGB1000: [0, 576, 1000]),
        .init(meshID: 2, materialGroupID: 0x73, materialID: 2, ambientRGB1000: [0, 0, 0], diffuseRGB1000: [0, 0, 0]),
        .init(meshID: 2, materialGroupID: 0x73, materialID: 3, ambientRGB1000: [1000, 1000, 1000], diffuseRGB1000: [1000, 1000, 1000]),
        .init(meshID: 3, materialGroupID: 0x63, materialID: 0, ambientRGB1000: [0, 291, 1000], diffuseRGB1000: [0, 291, 1000]),
        .init(meshID: 3, materialGroupID: 0x63, materialID: 1, ambientRGB1000: [0, 576, 1000], diffuseRGB1000: [0, 576, 1000]),
        .init(meshID: 3, materialGroupID: 0x63, materialID: 2, ambientRGB1000: [0, 0, 0], diffuseRGB1000: [0, 0, 0]),
        .init(meshID: 3, materialGroupID: 0x63, materialID: 3, ambientRGB1000: [1000, 1000, 1000], diffuseRGB1000: [1000, 1000, 1000]),

        .init(meshID: 4, materialGroupID: 0x5C, materialID: 0, ambientRGB1000: [0, 5, 0], diffuseRGB1000: [0, 0, 0]),
        .init(meshID: 5, materialGroupID: 0x3A, materialID: 0, ambientRGB1000: [0, 0, 0], diffuseRGB1000: [0, 0, 0]),
        .init(meshID: 6, materialGroupID: 0x18, materialID: 0, ambientRGB1000: [0, 0, 0], diffuseRGB1000: [0, 0, 0]),
    ]

    static let lights: [SM64MarioFaceLightingResource] = [
        .init(objectID: 0xE4, logicalID: 1, flags: 0x20, diffuseRGB1000: [1000, 1000, 1000]),
        .init(objectID: 0xE7, logicalID: 0, flags: 0x20, diffuseRGB1000: [1000, 0, 0]),
    ]

    static let animationBindings: [SM64MarioFaceAnimationBinding] =
        SM64MarioFaceAnimationResourceManifest.entries.map { entry in
            .init(
                componentID: entry.componentID,
                animatorID: entry.animatorID,
                parentGroupID: animationParentGroupID,
                dataGroupID: entry.componentID,
                nodeGroupID: entry.componentID,
                linkedObjectID: entry.componentID == 0xE2 ? 0xDD : entry.componentID - 1
            )
        }

    static func mesh(meshID: UInt32) -> SM64MarioFaceMeshResource? {
        meshes.first { $0.meshID == meshID }
    }

    static func material(meshID: UInt32, materialID: UInt32) -> SM64MarioFaceMaterialResource? {
        materials.first { $0.meshID == meshID && $0.materialID == materialID }
    }

    static func animationBinding(componentID: UInt32) -> SM64MarioFaceAnimationBinding? {
        animationBindings.first { $0.componentID == componentID }
    }

    static func matchesManifest() -> Bool {
        animationBindings.count == SM64MarioFaceAnimationResourceManifest.entries.count
            && zip(animationBindings, SM64MarioFaceAnimationResourceManifest.entries).allSatisfy { binding, entry in
                binding.componentID == entry.componentID
                    && binding.animatorID == entry.animatorID
                    && binding.dataGroupID == entry.componentID
                    && binding.nodeGroupID == entry.componentID
                    && binding.linkedObjectID == (entry.componentID == 0xE2 ? 0xDD : entry.componentID - 1)
                    && binding.parentGroupID == animationParentGroupID
            }
    }
}

enum SM64MarioFaceResourceCatalogFingerprint {
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

    private static func hash(_ initial: UInt64, _ string: String) -> UInt64 {
        var result = hash(initial, UInt64(string.utf8.count))
        for byte in string.utf8 {
            result = hash(result, UInt64(byte))
        }
        return result
    }

    private static func hash(_ initial: UInt64, _ values: [UInt32]) -> UInt64 {
        values.reduce(initial) { hash($0, UInt64($1)) }
    }

    static func catalog(
        meshes: [SM64MarioFaceMeshResource] = SM64MarioFaceResourceCatalog.meshes,
        materials: [SM64MarioFaceMaterialResource] = SM64MarioFaceResourceCatalog.materials,
        lights: [SM64MarioFaceLightingResource] = SM64MarioFaceResourceCatalog.lights,
        animationBindings: [SM64MarioFaceAnimationBinding] = SM64MarioFaceResourceCatalog.animationBindings
    ) -> UInt64 {
        var result = hash(offset, UInt64(SM64MarioFaceResourceCatalog.masterGroupID))
        result = hash(result, UInt64(SM64MarioFaceResourceCatalog.animationParentGroupID))
        result = hash(result, UInt64(meshes.count))
        for mesh in meshes {
            result = hash(result, mesh.meshID)
            result = hash(result, mesh.sourcePath)
            result = hash(result, [
                mesh.vertexGroupID, mesh.planeGroupID, mesh.materialGroupID,
                mesh.shapeID, mesh.vertexCount, mesh.faceCount, mesh.materialCount,
            ])
        }
        result = hash(result, UInt64(materials.count))
        for material in materials {
            result = hash(result, [material.meshID, material.materialGroupID, material.materialID])
            result = hash(result, material.ambientRGB1000)
            result = hash(result, material.diffuseRGB1000)
        }
        result = hash(result, UInt64(lights.count))
        for light in lights {
            result = hash(result, [light.objectID, light.logicalID, light.flags])
            result = hash(result, light.diffuseRGB1000)
        }
        result = hash(result, UInt64(animationBindings.count))
        for binding in animationBindings {
            result = hash(result, [
                binding.componentID, binding.animatorID, binding.parentGroupID,
                binding.dataGroupID, binding.nodeGroupID, binding.linkedObjectID,
            ])
        }
        return result
    }
}
