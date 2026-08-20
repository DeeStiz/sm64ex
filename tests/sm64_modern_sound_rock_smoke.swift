import Foundation
private let offset: UInt64 = 1_469_598_103_934_665_603
private let prime: UInt64 = 1_099_511_628_211
private func hash(_ seed: UInt64, _ value: UInt64) -> UInt64 { var result = seed; for byte in 0..<8 { result ^= (value >> UInt64(byte * 8)) & 255; result &*= prime }; return result }
@main struct SM64SoundRockSmoke {
    static func main() {
        let sound = [SM64SoundSpawnerBehavior.update(.init(timer: 3, soundID: 0x1234)), SM64SoundSpawnerBehavior.update(.init(timer: 33, soundID: 0x1234))]
        let rock = SM64RockSolidBehavior.update(.init(timer: 4))
        precondition(sound[0].playSound && !sound[0].shouldDelete, "sound spawner init")
        precondition(sound[1].shouldDelete, "sound spawner expiry")
        precondition(rock.timer == 5 && rock.loadCollisionModel, "rock-solid collision")
        var fingerprint = offset
        for output in sound { fingerprint = hash(fingerprint, UInt64(output.timer)); fingerprint = hash(fingerprint, UInt64(bitPattern: Int64(output.soundID))); fingerprint = hash(fingerprint, UInt64(output.playSound ? 1 : 0)); fingerprint = hash(fingerprint, UInt64(output.shouldDelete ? 1 : 0)) }
        fingerprint = hash(fingerprint, UInt64(rock.timer)); fingerprint = hash(fingerprint, UInt64(rock.loadCollisionModel ? 1 : 0))
        print(String(format: "soundRockFingerprint=0x%016llx", fingerprint)); print("SM64 Modern sound/rock smoke passed")
    }
}
