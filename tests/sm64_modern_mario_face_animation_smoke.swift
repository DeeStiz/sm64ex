import Foundation

@main
struct SM64ModernMarioFaceAnimationSmoke {
    static func main() {
        let samples: [SM64MarioFaceAnimationSample?] = [
            SM64MarioFaceAnimationTimeline.sample(componentID: 0x07, bank: 0, frame: 1),
            SM64MarioFaceAnimationTimeline.sample(componentID: 0x07, bank: 0, frame: 820),
            SM64MarioFaceAnimationTimeline.sample(componentID: 0x07, bank: 0, frame: 821),
            SM64MarioFaceAnimationTimeline.sample(componentID: 0x07, bank: 1, frame: -2),
            SM64MarioFaceAnimationTimeline.sample(componentID: 0xE2, bank: 1, frame: 166),
            SM64MarioFaceAnimationTimeline.sample(componentID: 0x3F, bank: 1, frame: 4),
            SM64MarioFaceAnimationTimeline.sample(componentID: 0xBA, bank: 0, frame: 0),
            SM64MarioFaceAnimationTimeline.sample(componentID: 0xFF, bank: 0, frame: 1),
        ]
        let peachTimers: [UInt32] = [0, 74, 75, 76, 89, 90, 91, 96, 99, 100, 109, 110, 136]
        let creditsTimers: [UInt32] = [0, 51, 52, 100]

        let catalogFingerprint = SM64MarioFaceAnimationFingerprint.catalog(
            SM64MarioFaceAnimationTimeline.catalog
        )
        var fingerprint = catalogFingerprint
        for sample in samples {
            fingerprint = SM64MarioFaceAnimationFingerprint.sample(fingerprint, sample)
        }
        for timer in peachTimers {
            fingerprint = SM64MarioFaceAnimationFingerprint.eye(
                fingerprint,
                SM64MarioFaceAnimationTimeline.eyeTimelineSample(actionTimer: timer, peachKiss: true)
            )
        }
        for timer in creditsTimers {
            fingerprint = SM64MarioFaceAnimationFingerprint.eye(
                fingerprint,
                SM64MarioFaceAnimationTimeline.eyeTimelineSample(actionTimer: timer, peachKiss: false)
            )
        }

        precondition(SM64MarioFaceAnimationTimeline.catalog.count == 25)
        precondition(SM64MarioFaceAnimationTimeline.catalog.filter { $0.secondaryCount == 0 }.count == 5)
        precondition(samples[0]?.currentIndex == 0 && samples[0]?.nextIndex == 1)
        precondition(samples[1]?.currentIndex == 819 && samples[1]?.nextIndex == 0)
        precondition(samples[2]?.normalizedFrame == 1)
        precondition(samples[3]?.normalizedFrame == 166)
        precondition(samples[4]?.type == .sixHScaled)
        precondition(samples[5] == nil && samples[6] == nil && samples[7] == nil)
        precondition(SM64MarioFaceAnimationTimeline.peachKissEyeState(actionTimer: 75) == SM64MarioFaceEyeState.halfClosed.rawValue)
        precondition(SM64MarioFaceAnimationTimeline.peachKissEyeState(actionTimer: 76) == SM64MarioFaceEyeState.closed.rawValue)
        precondition(SM64MarioFaceAnimationTimeline.peachKissEyeState(actionTimer: 90) == SM64MarioFaceEyeState.halfClosed.rawValue)
        precondition(SM64MarioFaceAnimationTimeline.peachKissEyeState(actionTimer: 96) == SM64MarioFaceEyeState.open.rawValue)
        precondition(SM64MarioFaceAnimationTimeline.peachKissEyeState(actionTimer: 110) == SM64MarioFaceEyeState.halfClosed.rawValue)
        precondition(SM64MarioFaceAnimationTimeline.creditsOpeningEyeState(actionTimer: 51) == SM64MarioFaceEyeState.halfClosed.rawValue)
        precondition(SM64MarioFaceAnimationTimeline.creditsOpeningEyeState(actionTimer: 52) == nil)

        print(String(format: "marioFaceAnimationCatalogFingerprint=0x%016llx", catalogFingerprint))
        print(String(format: "marioFaceAnimationFingerprint=0x%016llx", fingerprint))
        print("marioFaceAnimationChannels=\(SM64MarioFaceAnimationTimeline.catalog.count)")
        print("marioFaceAnimationSamples=\(samples.count)")
        print("SM64 Modern Mario face animation smoke passed")
    }
}
