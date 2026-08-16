import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU32(_ hash: UInt64, _ value: UInt32) -> UInt64 {
    var result = hash
    for shift in stride(from: 0, through: 24, by: 8) {
        result ^= UInt64((value >> UInt32(shift)) & 0xFF)
        result &*= fnvPrime
    }
    return result
}

private func hashString(_ hash: UInt64, _ value: String) -> UInt64 {
    var result = hash
    for byte in value.utf8 {
        result ^= UInt64(byte)
        result &*= fnvPrime
    }
    return result
}

private func hashU64(_ hash: UInt64, _ value: UInt64) -> UInt64 {
    var result = hash
    for shift in stride(from: 0, through: 56, by: 8) {
        result ^= (value >> UInt64(shift)) & 0xFF
        result &*= fnvPrime
    }
    return result
}

@main
enum SM64ModernConfigurationSmoke {
    static func main() {
        let defaults = SM64ModernConfiguration.defaults
        let defaultRoundTrip = SM64ModernConfiguration.parse(defaults.encodeLegacy())
        precondition(defaultRoundTrip.configuration == defaults)
        precondition(!defaultRoundTrip.didRepair)
        precondition(defaultRoundTrip.unknownKeys.isEmpty)

        var rich = defaults
        rich.window = .init(fullscreen: true, x: 128, y: 256, width: 1920, height: 1080, vsync: false)
        rich.textureFiltering = 0
        rich.audio = .init(masterVolume: 80, musicVolume: 70, sfxVolume: 60, environmentVolume: 50)
        rich.bindings[.a] = [0x0041, 0x1000, 0x1103]
        rich.bindings[.cUp] = [0x0148, 0x100B, 0xFFFF]
        rich.stickDeadzone = 24
        rich.rumbleStrength = 75
        rich.precacheResources = false
        rich.camera = .init(
            enabled: true,
            analog: false,
            mouseLook: true,
            invertX: false,
            invertY: true,
            xSensitivity: 90,
            ySensitivity: 11,
            aggression: 33,
            panLevel: 44,
            degrade: 55
        )
        rich.hudEnabled = false
        rich.skipIntro = true
        rich.discordRPCEnabled = false
        rich.legalROMAccepted = true
        rich.cheats = .init(
            enabled: true,
            moonJump: true,
            godMode: false,
            infiniteLives: true,
            superSpeed: false,
            responsive: true,
            exitAnywhere: true,
            hugeMario: false,
            tinyMario: true
        )
        let richRoundTrip = SM64ModernConfiguration.parse(rich.encodeModern())
        precondition(richRoundTrip.configuration == rich)
        precondition(!richRoundTrip.didRepair)
        precondition(richRoundTrip.unknownKeys.isEmpty)

        let invalid = SM64ModernConfiguration.parse("""
        fullscreen maybe
        window_w 0
        window_h 99999
        texture_filtering 2
        master_volume 128
        music_volume nope
        key_a 0041 invalid 1103
        stick_deadzone 101
        bettercam_xsens 0
        language japanese
        legal_rom_accepted true
        cheat_moon_jump true
        unknown_future_option 1
        malformed_only
        """)
        precondition(invalid.configuration.window == defaults.window)
        precondition(invalid.configuration.textureFiltering == defaults.textureFiltering)
        precondition(invalid.configuration.audio == defaults.audio)
        precondition(invalid.configuration.bindings == defaults.bindings)
        precondition(invalid.configuration.stickDeadzone == defaults.stickDeadzone)
        precondition(invalid.configuration.camera.xSensitivity == defaults.camera.xSensitivity)
        precondition(invalid.configuration.language == defaults.language)
        precondition(invalid.configuration.legalROMAccepted)
        precondition(invalid.configuration.cheats.moonJump)
        precondition(invalid.repairedKeys == [
            "fullscreen", "window_w", "window_h", "texture_filtering", "master_volume",
            "music_volume", "key_a", "stick_deadzone", "bettercam_xsens", "language"
        ])
        precondition(invalid.unknownKeys == ["unknown_future_option", "malformed_only"])
        precondition(invalid.malformedLines == [14])

        var recoveryFingerprint = fnvOffset
        recoveryFingerprint = hashU64(recoveryFingerprint, invalid.configuration.fingerprint)
        recoveryFingerprint = hashString(recoveryFingerprint, invalid.repairedKeys.joined(separator: ","))
        recoveryFingerprint = hashString(recoveryFingerprint, invalid.unknownKeys.joined(separator: ","))
        recoveryFingerprint = hashString(recoveryFingerprint, invalid.malformedLines.map(String.init).joined(separator: ","))
        print(String(format: "configurationDefaultFingerprint=0x%016llx", defaults.fingerprint))
        print(String(format: "configurationRichFingerprint=0x%016llx", rich.fingerprint))
        print(String(format: "configurationRecoveryFingerprint=0x%016llx", recoveryFingerprint))
        print("SM64 Modern configuration smoke passed")
    }
}
