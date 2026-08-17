import Foundation

@main
struct SM64ModernMarioFaceResourceManifestCodecSmoke {
    static func main() throws {
        let entries = SM64MarioFaceAnimationResourceManifest.entries
        let encoded = SM64MarioFaceResourceManifestCodec.encode(entries)
        let decoded = try SM64MarioFaceResourceManifestCodec.decode(encoded)
        let fingerprint = SM64MarioFaceResourceManifestCodecFingerprint.bytes(encoded)

        precondition(decoded == entries)
        precondition(decoded.count == 25)
        precondition(encoded.prefix(4) == Data([0x4D, 0x46, 0x52, 0x4D]))
        precondition(encoded.count > 1000)

        var badMagic = encoded
        badMagic[0] = 0
        precondition((try? SM64MarioFaceResourceManifestCodec.decode(badMagic)) == nil)
        precondition((try? SM64MarioFaceResourceManifestCodec.decode(encoded.dropLast())) == nil)
        var trailing = encoded
        trailing.append(0xFF)
        precondition((try? SM64MarioFaceResourceManifestCodec.decode(trailing)) == nil)

        print(String(format: "marioFaceManifestCodecFingerprint=0x%016llx", fingerprint))
        print("marioFaceManifestCodecBytes=\(encoded.count)")
        print("marioFaceManifestCodecEntries=\(decoded.count)")
        print("marioFaceManifestCodecRoundTrip=1")
        print("SM64 Modern Mario face resource manifest codec smoke passed")
    }
}
