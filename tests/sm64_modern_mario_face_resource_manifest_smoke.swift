import Foundation

@main
struct SM64ModernMarioFaceResourceManifestSmoke {
    static func main() {
        let manifest = SM64MarioFaceAnimationResourceManifest.entries
        let fingerprint = SM64MarioFaceAnimationResourceManifestFingerprint.manifest(manifest)
        let emptySecondary = manifest.filter { $0.secondaryCount == 0 }.count
        let threeH = manifest.filter { $0.primaryType == .threeHScaled }.count
        let sixH = manifest.filter { $0.primaryType == .sixHScaled }.count

        precondition(manifest.count == 25)
        precondition(SM64MarioFaceAnimationResourceManifest.matchesCatalog())
        precondition(emptySecondary == 5)
        precondition(threeH == 22 && sixH == 3)
        precondition(SM64MarioFaceAnimationResourceManifest.entry(componentID: 0x07)?.primarySymbol == "animdata_mario_mustache_right_1")
        precondition(SM64MarioFaceAnimationResourceManifest.entry(componentID: 0xE8)?.secondarySymbol == "animdata_red_star_2")
        precondition(SM64MarioFaceAnimationResourceManifest.entry(componentID: 0x3F)?.secondarySymbol.isEmpty == true)

        print(String(format: "marioFaceManifestFingerprint=0x%016llx", fingerprint))
        print("marioFaceManifestEntries=\(manifest.count)")
        print("marioFaceManifestEmptySecondary=\(emptySecondary)")
        print("marioFaceManifestThreeH=\(threeH)")
        print("marioFaceManifestSixH=\(sixH)")
        print("SM64 Modern Mario face resource manifest smoke passed")
    }
}
