import Foundation

/// The value-only configuration contract shared by the Swift host and the
/// legacy `configfile.c` surface.  The C engine still owns application of
/// these values in M24a; this type makes defaults, parsing, recovery, and
/// serialization deterministic before that cutover.
struct SM64ModernConfiguration: Equatable, Sendable {
    static let maxBindings = 3
    static let centerPosition = UInt32.max
    static let defaultWindowWidth: UInt32 = 640
    static let defaultWindowHeight: UInt32 = 480
    static let maxVolume: UInt32 = 127
    static let swiftOnlyKeys: Set<String> = [
        "precache",
        "bettercam_enable",
        "bettercam_analog",
        "bettercam_mouse_look",
        "bettercam_invertx",
        "bettercam_inverty",
        "bettercam_xsens",
        "bettercam_ysens",
        "bettercam_aggression",
        "bettercam_pan_level",
        "bettercam_degrade",
        "hud",
        "discordrpc_enable",
        "language",
        "legal_rom_accepted",
        "cheats_enable",
        "cheat_moon_jump",
        "cheat_god_mode",
        "cheat_infinite_lives",
        "cheat_super_speed",
        "cheat_responsive",
        "cheat_exit_anywhere",
        "cheat_huge_mario",
        "cheat_tiny_mario"
    ]

    enum Binding: String, CaseIterable, Hashable, Sendable {
        case a = "key_a"
        case b = "key_b"
        case start = "key_start"
        case l = "key_l"
        case r = "key_r"
        case z = "key_z"
        case cUp = "key_cup"
        case cDown = "key_cdown"
        case cLeft = "key_cleft"
        case cRight = "key_cright"
        case stickUp = "key_stickup"
        case stickDown = "key_stickdown"
        case stickLeft = "key_stickleft"
        case stickRight = "key_stickright"
    }

    enum Language: String, CaseIterable, Sendable {
        case english
    }

    struct Window: Equatable, Sendable {
        var fullscreen: Bool
        var x: UInt32
        var y: UInt32
        var width: UInt32
        var height: UInt32
        var vsync: Bool
    }

    struct Audio: Equatable, Sendable {
        var masterVolume: UInt32
        var musicVolume: UInt32
        var sfxVolume: UInt32
        var environmentVolume: UInt32
    }

    struct Camera: Equatable, Sendable {
        var enabled: Bool
        var analog: Bool
        var mouseLook: Bool
        var invertX: Bool
        var invertY: Bool
        var xSensitivity: UInt32
        var ySensitivity: UInt32
        var aggression: UInt32
        var panLevel: UInt32
        var degrade: UInt32
    }

    struct Cheats: Equatable, Sendable {
        var enabled: Bool
        var moonJump: Bool
        var godMode: Bool
        var infiniteLives: Bool
        var superSpeed: Bool
        var responsive: Bool
        var exitAnywhere: Bool
        var hugeMario: Bool
        var tinyMario: Bool
    }

    struct ParseResult: Equatable, Sendable {
        let configuration: SM64ModernConfiguration
        let repairedKeys: [String]
        let unknownKeys: [String]
        let malformedLines: [Int]

        var didRepair: Bool {
            !repairedKeys.isEmpty || !malformedLines.isEmpty
        }
    }

    var window: Window
    var textureFiltering: UInt32
    var audio: Audio
    var bindings: [Binding: [UInt32]]
    var stickDeadzone: UInt32
    var rumbleStrength: UInt32
    var precacheResources: Bool
    var camera: Camera
    var hudEnabled: Bool
    var skipIntro: Bool
    var discordRPCEnabled: Bool
    var language: Language
    var legalROMAccepted: Bool
    var cheats: Cheats

    static let defaults: Self = {
        var bindings: [Binding: [UInt32]] = [:]
        bindings[.a] = [0x0026, 0x1000, 0x1103]
        bindings[.b] = [0x0033, 0x1002, 0x1101]
        bindings[.start] = [0x0039, 0x1006, 0xFFFF]
        bindings[.l] = [0x002A, 0x1009, 0x1104]
        bindings[.r] = [0x0036, 0x100A, 0x101B]
        bindings[.z] = [0x0025, 0x1007, 0x101A]
        bindings[.cUp] = [0x0148, 0xFFFF, 0xFFFF]
        bindings[.cDown] = [0x0150, 0xFFFF, 0xFFFF]
        bindings[.cLeft] = [0x014B, 0xFFFF, 0xFFFF]
        bindings[.cRight] = [0x014D, 0xFFFF, 0xFFFF]
        bindings[.stickUp] = [0x0011, 0xFFFF, 0xFFFF]
        bindings[.stickDown] = [0x001F, 0xFFFF, 0xFFFF]
        bindings[.stickLeft] = [0x001E, 0xFFFF, 0xFFFF]
        bindings[.stickRight] = [0x0020, 0xFFFF, 0xFFFF]
        return Self(
            window: Window(
                fullscreen: false,
                x: centerPosition,
                y: centerPosition,
                width: defaultWindowWidth,
                height: defaultWindowHeight,
                vsync: true
            ),
            textureFiltering: 1,
            audio: Audio(
                masterVolume: (maxVolume + 1) / 2,
                musicVolume: maxVolume,
                sfxVolume: maxVolume,
                environmentVolume: maxVolume
            ),
            bindings: bindings,
            stickDeadzone: 16,
            rumbleStrength: 50,
            precacheResources: true,
            camera: Camera(
                enabled: false,
                analog: true,
                mouseLook: false,
                invertX: true,
                invertY: false,
                xSensitivity: 50,
                ySensitivity: 50,
                aggression: 0,
                panLevel: 0,
                degrade: 10
            ),
            hudEnabled: true,
            skipIntro: false,
            discordRPCEnabled: true,
            language: .english,
            legalROMAccepted: false,
            cheats: Cheats(
                enabled: false,
                moonJump: false,
                godMode: false,
                infiniteLives: false,
                superSpeed: false,
                responsive: false,
                exitAnywhere: false,
                hugeMario: false,
                tinyMario: false
            )
        )
    }()

    private struct Diagnostics {
        var repairedKeys: [String] = []
        var unknownKeys: [String] = []
        var malformedLines: [Int] = []

        mutating func repair(_ key: String) {
            if !repairedKeys.contains(key) {
                repairedKeys.append(key)
            }
        }

        mutating func unknown(_ key: String) {
            if !unknownKeys.contains(key) {
                unknownKeys.append(key)
            }
        }
    }

    /// Parses the whitespace-delimited format emitted by `configfile_save`.
    /// Unlike the historical C parser, malformed values are never allowed to
    /// overwrite a valid value: the field returns to its documented default
    /// and the key is surfaced to the caller for repair logging/persistence.
    static func parse(_ text: String) -> ParseResult {
        var configuration = defaults
        var diagnostics = Diagnostics()

        for (index, rawLine) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            var line = String(rawLine)
            if line.last == "\r" {
                line.removeLast()
            }
            let tokens = line.split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard let key = tokens.first else { continue }
            if key.hasPrefix("#") { continue }
            let values = Array(tokens.dropFirst())
            guard !values.isEmpty else {
                diagnostics.malformedLines.append(index + 1)
                if Binding(rawValue: key) != nil || isKnownKey(key) {
                    diagnostics.repair(key)
                } else {
                    diagnostics.unknown(key)
                }
                continue
            }

            switch key {
            case "fullscreen":
                if let value = boolValue(values, key: key, diagnostics: &diagnostics) {
                    configuration.window.fullscreen = value
                }
            case "window_x":
                if let value = uintValue(values, key: key, range: nil, diagnostics: &diagnostics) {
                    configuration.window.x = value
                }
            case "window_y":
                if let value = uintValue(values, key: key, range: nil, diagnostics: &diagnostics) {
                    configuration.window.y = value
                }
            case "window_w":
                if let value = uintValue(values, key: key, range: 1...16_384, diagnostics: &diagnostics) {
                    configuration.window.width = value
                }
            case "window_h":
                if let value = uintValue(values, key: key, range: 1...16_384, diagnostics: &diagnostics) {
                    configuration.window.height = value
                }
            case "vsync":
                if let value = boolValue(values, key: key, diagnostics: &diagnostics) {
                    configuration.window.vsync = value
                }
            case "texture_filtering":
                if let value = uintValue(values, key: key, range: 0...1, diagnostics: &diagnostics) {
                    configuration.textureFiltering = value
                }
            case "master_volume":
                if let value = uintValue(values, key: key, range: 0...maxVolume, diagnostics: &diagnostics) {
                    configuration.audio.masterVolume = value
                }
            case "music_volume":
                if let value = uintValue(values, key: key, range: 0...maxVolume, diagnostics: &diagnostics) {
                    configuration.audio.musicVolume = value
                }
            case "sfx_volume":
                if let value = uintValue(values, key: key, range: 0...maxVolume, diagnostics: &diagnostics) {
                    configuration.audio.sfxVolume = value
                }
            case "env_volume":
                if let value = uintValue(values, key: key, range: 0...maxVolume, diagnostics: &diagnostics) {
                    configuration.audio.environmentVolume = value
                }
            default:
                if let binding = Binding(rawValue: key) {
                    if let value = bindingValue(values, key: key, diagnostics: &diagnostics) {
                        configuration.bindings[binding] = value
                    }
                    continue
                }
                switch key {
                case "stick_deadzone":
                    if let value = uintValue(values, key: key, range: 0...100, diagnostics: &diagnostics) {
                        configuration.stickDeadzone = value
                    }
                case "rumble_strength":
                    if let value = uintValue(values, key: key, range: 0...100, diagnostics: &diagnostics) {
                        configuration.rumbleStrength = value
                    }
                case "precache":
                    if let value = boolValue(values, key: key, diagnostics: &diagnostics) {
                        configuration.precacheResources = value
                    }
                case "bettercam_enable":
                    if let value = boolValue(values, key: key, diagnostics: &diagnostics) {
                        configuration.camera.enabled = value
                    }
                case "bettercam_analog":
                    if let value = boolValue(values, key: key, diagnostics: &diagnostics) {
                        configuration.camera.analog = value
                    }
                case "bettercam_mouse_look":
                    if let value = boolValue(values, key: key, diagnostics: &diagnostics) {
                        configuration.camera.mouseLook = value
                    }
                case "bettercam_invertx":
                    if let value = boolValue(values, key: key, diagnostics: &diagnostics) {
                        configuration.camera.invertX = value
                    }
                case "bettercam_inverty":
                    if let value = boolValue(values, key: key, diagnostics: &diagnostics) {
                        configuration.camera.invertY = value
                    }
                case "bettercam_xsens":
                    if let value = uintValue(values, key: key, range: 1...100, diagnostics: &diagnostics) {
                        configuration.camera.xSensitivity = value
                    }
                case "bettercam_ysens":
                    if let value = uintValue(values, key: key, range: 1...100, diagnostics: &diagnostics) {
                        configuration.camera.ySensitivity = value
                    }
                case "bettercam_aggression":
                    if let value = uintValue(values, key: key, range: 0...100, diagnostics: &diagnostics) {
                        configuration.camera.aggression = value
                    }
                case "bettercam_pan_level":
                    if let value = uintValue(values, key: key, range: 0...100, diagnostics: &diagnostics) {
                        configuration.camera.panLevel = value
                    }
                case "bettercam_degrade":
                    if let value = uintValue(values, key: key, range: 0...100, diagnostics: &diagnostics) {
                        configuration.camera.degrade = value
                    }
                case "hud":
                    if let value = boolValue(values, key: key, diagnostics: &diagnostics) {
                        configuration.hudEnabled = value
                    }
                case "skip_intro":
                    if let value = boolValue(values, key: key, diagnostics: &diagnostics) {
                        configuration.skipIntro = value
                    }
                case "discordrpc_enable":
                    if let value = boolValue(values, key: key, diagnostics: &diagnostics) {
                        configuration.discordRPCEnabled = value
                    }
                case "language":
                    guard values.count == 1,
                          let value = Language(rawValue: values[0]) else {
                        diagnostics.repair(key)
                        continue
                    }
                    configuration.language = value
                case "legal_rom_accepted":
                    if let value = boolValue(values, key: key, diagnostics: &diagnostics) {
                        configuration.legalROMAccepted = value
                    }
                case "cheats_enable":
                    if let value = boolValue(values, key: key, diagnostics: &diagnostics) {
                        configuration.cheats.enabled = value
                    }
                case "cheat_moon_jump":
                    if let value = boolValue(values, key: key, diagnostics: &diagnostics) {
                        configuration.cheats.moonJump = value
                    }
                case "cheat_god_mode":
                    if let value = boolValue(values, key: key, diagnostics: &diagnostics) {
                        configuration.cheats.godMode = value
                    }
                case "cheat_infinite_lives":
                    if let value = boolValue(values, key: key, diagnostics: &diagnostics) {
                        configuration.cheats.infiniteLives = value
                    }
                case "cheat_super_speed":
                    if let value = boolValue(values, key: key, diagnostics: &diagnostics) {
                        configuration.cheats.superSpeed = value
                    }
                case "cheat_responsive":
                    if let value = boolValue(values, key: key, diagnostics: &diagnostics) {
                        configuration.cheats.responsive = value
                    }
                case "cheat_exit_anywhere":
                    if let value = boolValue(values, key: key, diagnostics: &diagnostics) {
                        configuration.cheats.exitAnywhere = value
                    }
                case "cheat_huge_mario":
                    if let value = boolValue(values, key: key, diagnostics: &diagnostics) {
                        configuration.cheats.hugeMario = value
                    }
                case "cheat_tiny_mario":
                    if let value = boolValue(values, key: key, diagnostics: &diagnostics) {
                        configuration.cheats.tinyMario = value
                    }
                default:
                    diagnostics.unknown(key)
                }
            }
        }

        return ParseResult(
            configuration: configuration,
            repairedKeys: diagnostics.repairedKeys,
            unknownKeys: diagnostics.unknownKeys,
            malformedLines: diagnostics.malformedLines
        )
    }

    /// Serializes the keys understood by the always-on C config table. It is
    /// byte-stable and intentionally omits compile-time optional C entries.
    func encodeLegacy() -> String {
        var lines: [String] = []
        lines.append("fullscreen \(window.fullscreen ? "true" : "false")")
        lines.append("window_x \(window.x)")
        lines.append("window_y \(window.y)")
        lines.append("window_w \(window.width)")
        lines.append("window_h \(window.height)")
        lines.append("vsync \(window.vsync ? "true" : "false")")
        lines.append("texture_filtering \(textureFiltering)")
        lines.append("master_volume \(audio.masterVolume)")
        lines.append("music_volume \(audio.musicVolume)")
        lines.append("sfx_volume \(audio.sfxVolume)")
        lines.append("env_volume \(audio.environmentVolume)")
        for binding in Binding.allCases {
            let values = bindings[binding] ?? Self.defaults.bindings[binding]!
            let encoded = values.map { String(format: "%04x", Int($0)) }.joined(separator: " ")
            lines.append("\(binding.rawValue) \(encoded) ")
        }
        lines.append("stick_deadzone \(stickDeadzone)")
        lines.append("rumble_strength \(rumbleStrength)")
        lines.append("skip_intro \(skipIntro ? "true" : "false")")
        return lines.joined(separator: "\n") + "\n"
    }

    /// Adds Swift-only product settings and compile-time optional settings to
    /// the legacy serialization. C safely ignores these keys during the
    /// migration period; Swift retains them for the eventual authority cut.
    func encodeModern() -> String {
        var lines = encodeLegacy().split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        lines += [
            "precache \(precacheResources ? "true" : "false")",
            "bettercam_enable \(camera.enabled ? "true" : "false")",
            "bettercam_analog \(camera.analog ? "true" : "false")",
            "bettercam_mouse_look \(camera.mouseLook ? "true" : "false")",
            "bettercam_invertx \(camera.invertX ? "true" : "false")",
            "bettercam_inverty \(camera.invertY ? "true" : "false")",
            "bettercam_xsens \(camera.xSensitivity)",
            "bettercam_ysens \(camera.ySensitivity)",
            "bettercam_aggression \(camera.aggression)",
            "bettercam_pan_level \(camera.panLevel)",
            "bettercam_degrade \(camera.degrade)",
            "hud \(hudEnabled ? "true" : "false")",
            "discordrpc_enable \(discordRPCEnabled ? "true" : "false")",
            "language \(language.rawValue)",
            "legal_rom_accepted \(legalROMAccepted ? "true" : "false")",
            "cheats_enable \(cheats.enabled ? "true" : "false")",
            "cheat_moon_jump \(cheats.moonJump ? "true" : "false")",
            "cheat_god_mode \(cheats.godMode ? "true" : "false")",
            "cheat_infinite_lives \(cheats.infiniteLives ? "true" : "false")",
            "cheat_super_speed \(cheats.superSpeed ? "true" : "false")",
            "cheat_responsive \(cheats.responsive ? "true" : "false")",
            "cheat_exit_anywhere \(cheats.exitAnywhere ? "true" : "false")",
            "cheat_huge_mario \(cheats.hugeMario ? "true" : "false")",
            "cheat_tiny_mario \(cheats.tinyMario ? "true" : "false")"
        ]
        return lines.joined(separator: "\n") + "\n"
    }

    /// Applies only settings that the C config writer does not guarantee to
    /// preserve. Legacy window/audio/binding values continue to come from the
    /// primary file so a C menu edit cannot be overwritten by a stale Swift
    /// sidecar.
    func applyingSwiftOnly(from source: Self) -> Self {
        var merged = self
        merged.precacheResources = source.precacheResources
        merged.camera = source.camera
        merged.hudEnabled = source.hudEnabled
        merged.discordRPCEnabled = source.discordRPCEnabled
        merged.language = source.language
        merged.legalROMAccepted = source.legalROMAccepted
        merged.cheats = source.cheats
        return merged
    }

    static func containsSwiftOnlyKey(in text: String) -> Bool {
        text.split(separator: "\n", omittingEmptySubsequences: false).contains { rawLine in
            let tokens = rawLine.split(whereSeparator: { $0.isWhitespace })
            guard let key = tokens.first, !key.hasPrefix("#") else { return false }
            return swiftOnlyKeys.contains(String(key))
        }
    }

    /// Stable FNV-1a fingerprint for cross-language contract tests and trace
    /// headers. It hashes fields in schema order, never Swift's randomized
    /// `Hashable` implementation.
    var fingerprint: UInt64 {
        var hash = Self.fnvOffset
        hash = Self.hashBool(hash, window.fullscreen)
        hash = Self.hashU32(hash, window.x)
        hash = Self.hashU32(hash, window.y)
        hash = Self.hashU32(hash, window.width)
        hash = Self.hashU32(hash, window.height)
        hash = Self.hashBool(hash, window.vsync)
        hash = Self.hashU32(hash, textureFiltering)
        hash = Self.hashU32(hash, audio.masterVolume)
        hash = Self.hashU32(hash, audio.musicVolume)
        hash = Self.hashU32(hash, audio.sfxVolume)
        hash = Self.hashU32(hash, audio.environmentVolume)
        for binding in Binding.allCases {
            for value in bindings[binding] ?? Self.defaults.bindings[binding]! {
                hash = Self.hashU32(hash, value)
            }
        }
        hash = Self.hashU32(hash, stickDeadzone)
        hash = Self.hashU32(hash, rumbleStrength)
        hash = Self.hashBool(hash, precacheResources)
        hash = Self.hashBool(hash, camera.enabled)
        hash = Self.hashBool(hash, camera.analog)
        hash = Self.hashBool(hash, camera.mouseLook)
        hash = Self.hashBool(hash, camera.invertX)
        hash = Self.hashBool(hash, camera.invertY)
        hash = Self.hashU32(hash, camera.xSensitivity)
        hash = Self.hashU32(hash, camera.ySensitivity)
        hash = Self.hashU32(hash, camera.aggression)
        hash = Self.hashU32(hash, camera.panLevel)
        hash = Self.hashU32(hash, camera.degrade)
        hash = Self.hashBool(hash, hudEnabled)
        hash = Self.hashBool(hash, skipIntro)
        hash = Self.hashBool(hash, discordRPCEnabled)
        hash = Self.hashBytes(hash, Array(language.rawValue.utf8))
        hash = Self.hashBool(hash, legalROMAccepted)
        hash = Self.hashBool(hash, cheats.enabled)
        hash = Self.hashBool(hash, cheats.moonJump)
        hash = Self.hashBool(hash, cheats.godMode)
        hash = Self.hashBool(hash, cheats.infiniteLives)
        hash = Self.hashBool(hash, cheats.superSpeed)
        hash = Self.hashBool(hash, cheats.responsive)
        hash = Self.hashBool(hash, cheats.exitAnywhere)
        hash = Self.hashBool(hash, cheats.hugeMario)
        hash = Self.hashBool(hash, cheats.tinyMario)
        return hash
    }

    private static let fnvOffset: UInt64 = 1_469_598_103_934_665_603
    private static let fnvPrime: UInt64 = 1_099_511_628_211

    private static func hashU32(_ hash: UInt64, _ value: UInt32) -> UInt64 {
        var result = hash
        for shift in stride(from: 0, through: 24, by: 8) {
            result ^= UInt64((value >> UInt32(shift)) & 0xFF)
            result &*= fnvPrime
        }
        return result
    }

    private static func hashBool(_ hash: UInt64, _ value: Bool) -> UInt64 {
        hashU32(hash, value ? 1 : 0)
    }

    private static func hashBytes(_ hash: UInt64, _ bytes: [UInt8]) -> UInt64 {
        var result = hash
        for byte in bytes {
            result ^= UInt64(byte)
            result &*= fnvPrime
        }
        return result
    }

    private static func parseBool(_ value: String) -> Bool? {
        switch value {
        case "true": return true
        case "false": return false
        default: return nil
        }
    }

    private static func boolValue(
        _ values: [String],
        key: String,
        diagnostics: inout Diagnostics
    ) -> Bool? {
        guard values.count == 1, let value = parseBool(values[0]) else {
            diagnostics.repair(key)
            return nil
        }
        return value
    }

    private static func uintValue(
        _ values: [String],
        key: String,
        range: ClosedRange<UInt32>?,
        diagnostics: inout Diagnostics
    ) -> UInt32? {
        guard values.count == 1,
              let value = UInt32(values[0]),
              range?.contains(value) ?? true else {
            diagnostics.repair(key)
            return nil
        }
        return value
    }

    private static func bindingValue(
        _ values: [String],
        key: String,
        diagnostics: inout Diagnostics
    ) -> [UInt32]? {
        guard values.count == maxBindings else {
            diagnostics.repair(key)
            return nil
        }
        let parsed = values.compactMap { UInt32($0, radix: 16) }
        guard parsed.count == maxBindings else {
            diagnostics.repair(key)
            return nil
        }
        return parsed
    }

    private static func isKnownKey(_ key: String) -> Bool {
        if Binding(rawValue: key) != nil { return true }
        return [
            "fullscreen", "window_x", "window_y", "window_w", "window_h", "vsync",
            "texture_filtering", "master_volume", "music_volume", "sfx_volume", "env_volume",
            "stick_deadzone", "rumble_strength", "precache", "bettercam_enable", "bettercam_analog",
            "bettercam_mouse_look", "bettercam_invertx", "bettercam_inverty", "bettercam_xsens",
            "bettercam_ysens", "bettercam_aggression", "bettercam_pan_level", "bettercam_degrade",
            "hud", "skip_intro", "discordrpc_enable", "language", "legal_rom_accepted",
            "cheats_enable", "cheat_moon_jump", "cheat_god_mode", "cheat_infinite_lives",
            "cheat_super_speed", "cheat_responsive", "cheat_exit_anywhere", "cheat_huge_mario",
            "cheat_tiny_mario"
        ].contains(key)
    }
}
