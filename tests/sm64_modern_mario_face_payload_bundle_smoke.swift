import Foundation

@main
struct SM64ModernMarioFacePayloadBundleSmoke {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            throw NSError(domain: "MarioFacePayloadBundleSmoke", code: 1)
        }
        let pack = try SM64ContentPack.load(from: URL(fileURLWithPath: CommandLine.arguments[1]))
        let index = try SM64ContentPackIndex(pack: pack)
        let resourcePath = "source_manifest/mario_face_payloads.mfpb"
        let bytes = try index.bytes(kind: .sourceManifest, relativePath: resourcePath)
        let bundle = try SM64MarioFacePayloadBundle.decode(bytes)

        precondition(pack.metadata.isSourceOnly)
        precondition(bundle.version == 1)
        precondition(bundle.banks.count == 50)
        precondition(bundle.totalRawBytes == 160_668)
        precondition(bundle.canonicalBytes() == bytes)
        precondition(bundle.bank(componentID: 0x07, bank: 0)?.rawValues.count == 2_460)
        precondition(bundle.bank(componentID: 0xE2, bank: 0)?.rawValues.count == 4_920)
        precondition(bundle.bank(componentID: 0x3F, bank: 1)?.rawValues.isEmpty == true)
        precondition(bundle.frame(componentID: 0x07, bank: 0, sourceFrame: 820)?.count == 3)
        precondition(bundle.frame(componentID: 0x07, bank: 0, sourceFrame: 821) == nil)
        precondition(bundle.frame(componentID: 0x3F, bank: 1, sourceFrame: 1) == nil)
        precondition(bundle.decode(componentID: 0x07, bank: 0, frameQ16: 1 << 16) != nil)
        precondition(bundle.decode(componentID: 0xE2, bank: 0, frameQ16: 1 << 16)?.values.count == 6)
        precondition(bundle.decode(componentID: 0x3F, bank: 1, frameQ16: 1 << 16) == nil)

        var badMagic = bytes
        badMagic[0] = 0
        precondition((try? SM64MarioFacePayloadBundle.decode(badMagic)) == nil)
        precondition((try? SM64MarioFacePayloadBundle.decode(bytes.dropLast())) == nil)
        var trailing = bytes
        trailing.append(0xFF)
        precondition((try? SM64MarioFacePayloadBundle.decode(trailing)) == nil)
        var badCount = bytes
        badCount[8] = 49
        precondition((try? SM64MarioFacePayloadBundle.decode(badCount)) == nil)
        var badType = bytes
        badType[24] = 0xFF
        precondition((try? SM64MarioFacePayloadBundle.decode(badType)) == nil)

        let fingerprint = SM64MarioFacePayloadBundleFingerprint.bytes(bytes)
        print(String(format: "marioFacePayloadBundleFingerprint=0x%016llx", fingerprint))
        print("marioFacePayloadBundleBytes=\(bytes.count)")
        print("marioFacePayloadBundleRows=\(bundle.banks.count)")
        print("marioFacePayloadBundleRawBytes=\(bundle.totalRawBytes)")
        print("marioFacePayloadBundleResourcePath=\(resourcePath)")
        print("marioFacePayloadBundleSourceOnly=1")
        print("SM64 Modern Mario face payload bundle smoke passed")
    }
}
