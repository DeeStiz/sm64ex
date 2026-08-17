import Foundation

@main
struct SM64ModernMarioFaceResourceCatalogSmoke {
    static func main() {
        let meshes = SM64MarioFaceResourceCatalog.meshes
        let materials = SM64MarioFaceResourceCatalog.materials
        let lights = SM64MarioFaceResourceCatalog.lights
        let bindings = SM64MarioFaceResourceCatalog.animationBindings
        let fingerprint = SM64MarioFaceResourceCatalogFingerprint.catalog()

        precondition(meshes.count == 6)
        precondition(materials.count == 19)
        precondition(lights.count == 2)
        precondition(bindings.count == 25)
        precondition(SM64MarioFaceResourceCatalog.matchesManifest())
        precondition(meshes.map(\.meshID) == [1, 2, 3, 4, 5, 6])
        precondition(meshes.reduce(0) { $0 + $1.vertexCount } == 644)
        precondition(meshes.reduce(0) { $0 + $1.faceCount } == 1_213)
        precondition(meshes.reduce(0) { $0 + $1.materialCount } == 19)

        let face = SM64MarioFaceResourceCatalog.mesh(meshID: 1)
        precondition(face?.shapeID == 0xE1 && face?.vertexCount == 440 && face?.faceCount == 877)
        precondition(face?.vertexGroupID == 0xDE && face?.planeGroupID == 0xDF && face?.materialGroupID == 0xE0)
        let rightEye = SM64MarioFaceResourceCatalog.mesh(meshID: 2)
        precondition(rightEye?.shapeID == 0x74 && rightEye?.vertexCount == 48 && rightEye?.faceCount == 82)
        let mustache = SM64MarioFaceResourceCatalog.mesh(meshID: 6)
        precondition(mustache?.shapeID == 0x19 && mustache?.vertexCount == 56 && mustache?.faceCount == 100)
        precondition(SM64MarioFaceResourceCatalog.mesh(meshID: 0) == nil)

        precondition(SM64MarioFaceResourceCatalog.material(meshID: 1, materialID: 1)?.ambientRGB1000 == [883, 602, 408])
        precondition(SM64MarioFaceResourceCatalog.material(meshID: 4, materialID: 0)?.ambientRGB1000 == [0, 5, 0])
        precondition(SM64MarioFaceResourceCatalog.material(meshID: 3, materialID: 3)?.diffuseRGB1000 == [1000, 1000, 1000])
        precondition(SM64MarioFaceResourceCatalog.material(meshID: 6, materialID: 1) == nil)

        precondition(lights[0] == .init(objectID: 0xE4, logicalID: 1, flags: 0x20, diffuseRGB1000: [1000, 1000, 1000]))
        precondition(lights[1] == .init(objectID: 0xE7, logicalID: 0, flags: 0x20, diffuseRGB1000: [1000, 0, 0]))
        precondition(bindings.first?.parentGroupID == 0x3E9)
        precondition(bindings.first?.linkedObjectID == 0x06)
        precondition(bindings.last?.componentID == 0xE8 && bindings.last?.linkedObjectID == 0xE7)
        precondition(SM64MarioFaceResourceCatalog.animationBinding(componentID: 0xE2)?.linkedObjectID == 0xDD)
        precondition(SM64MarioFaceResourceCatalog.animationBinding(componentID: 0x00) == nil)

        print(String(format: "marioFaceResourceCatalogFingerprint=0x%016llx", fingerprint))
        print("marioFaceResourceCatalogMeshes=\(meshes.count)")
        print("marioFaceResourceCatalogMaterials=\(materials.count)")
        print("marioFaceResourceCatalogLights=\(lights.count)")
        print("marioFaceResourceCatalogAnimationBindings=\(bindings.count)")
        print("marioFaceResourceCatalogVertices=\(meshes.reduce(0) { $0 + $1.vertexCount })")
        print("marioFaceResourceCatalogFaces=\(meshes.reduce(0) { $0 + $1.faceCount })")
        print("marioFaceResourceCatalogMaterialSlots=\(meshes.reduce(0) { $0 + $1.materialCount })")
        print("SM64 Modern Mario face resource catalog smoke passed")
    }
}
