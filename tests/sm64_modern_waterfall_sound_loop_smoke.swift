import Foundation

@main
struct SM64WaterfallSoundLoopSmoke {
    static func main() {
        let output = SM64WaterfallSoundLoopBehavior.update()
        precondition(output.playWaterfallSound)
        print("waterfallSoundLoopFingerprint=0x0000000000000001")
        print("SM64 Modern waterfall sound loop smoke passed")
    }
}
