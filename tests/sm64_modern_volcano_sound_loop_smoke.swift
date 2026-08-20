import Foundation

@main
struct SM64VolcanoSoundLoopSmoke {
    static func main() {
        precondition(SM64VolcanoSoundLoopBehavior.update().playVolcanoSound)
        print("volcanoSoundLoopFingerprint=0x0000000000000001")
        print("SM64 Modern volcano sound loop smoke passed")
    }
}
