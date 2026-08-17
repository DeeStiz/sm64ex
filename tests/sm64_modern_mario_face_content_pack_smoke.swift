import Foundation

@main
struct SM64ModernMarioFaceContentPackSmoke {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let command = arguments.first, arguments.count == 2 else {
            throw NSError(domain: "MarioFaceContentPackSmoke", code: 1)
        }
        let url = URL(fileURLWithPath: arguments[1])
        let manifest = SM64MarioFaceAnimationResourceManifest.entries
        let expected = SM64MarioFaceResourceManifestCodec.encode(manifest)
        let expectedFingerprint = SM64MarioFaceResourceManifestCodecFingerprint.bytes(expected)

        switch command {
        case "write":
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try expected.write(to: url, options: .atomic)
            print(String(format: "marioFacePackManifestFingerprint=0x%016llx", expectedFingerprint))
            print("marioFacePackManifestBytes=\(expected.count)")
        case "read":
            let pack = try SM64ContentPack.load(from: url)
            let index = try SM64ContentPackIndex(pack: pack)
            let resourcePath = "source_manifest/mario_face_manifest.mfrm"
            let bytes = try index.bytes(kind: .sourceManifest, relativePath: resourcePath)
            let decoded = try SM64MarioFaceResourceManifestCodec.decode(bytes)
            precondition(decoded == manifest)
            precondition(bytes == expected)
            precondition(pack.metadata.isSourceOnly)
            print(String(format: "marioFacePackManifestFingerprint=0x%016llx", SM64MarioFaceResourceManifestCodecFingerprint.bytes(bytes)))
            print("marioFacePackManifestBytes=\(bytes.count)")
            print("marioFacePackResourcePath=\(resourcePath)")
            print("marioFacePackSourceOnly=1")
            print("SM64 Modern Mario face content-pack smoke passed")
        default:
            throw NSError(domain: "MarioFaceContentPackSmoke", code: 2)
        }
    }
}
