import Foundation

@main
enum SM64ModernConfigurationRuntimeSmoke {
    static func main() throws {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "sm64-modern-configuration-runtime-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let missingURL = root.appending(path: "missing.txt")
        let missing = try SM64ModernConfigurationRuntime.load(from: missingURL)
        precondition(missing.source == .defaults)
        precondition(missing.configuration == .defaults)
        precondition(!missing.didRepair)

        let validURL = root.appending(path: "valid.txt")
        try Data(SM64ModernConfiguration.defaults.encodeLegacy().utf8).write(to: validURL)
        let valid = try SM64ModernConfigurationRuntime.load(from: validURL)
        precondition(valid.source == .persisted)
        precondition(valid.configuration == .defaults)
        precondition(!valid.didRepair)
        precondition(!valid.repairPersisted)

        let invalidURL = root.appending(path: "invalid.txt")
        try Data("""
        fullscreen true
        master_volume 200
        malformed_only
        """.utf8).write(to: invalidURL)
        let repaired = try SM64ModernConfigurationRuntime.load(from: invalidURL)
        precondition(repaired.source == .persisted)
        precondition(repaired.configuration.window.fullscreen)
        precondition(repaired.configuration.audio.masterVolume == SM64ModernConfiguration.defaults.audio.masterVolume)
        precondition(repaired.repairedKeys == ["master_volume"])
        precondition(repaired.unknownKeys == ["malformed_only"])
        precondition(repaired.malformedLines == [3])
        precondition(repaired.repairPersisted)
        precondition(repaired.repairPersistenceError == nil)

        let repairedAgain = try SM64ModernConfigurationRuntime.load(from: invalidURL)
        precondition(!repairedAgain.didRepair)
        precondition(repairedAgain.configuration.window.fullscreen)
        precondition(repairedAgain.configuration.audio.masterVolume == SM64ModernConfiguration.defaults.audio.masterVolume)

        let invalidUTF8URL = root.appending(path: "invalid-utf8.txt")
        try Data([0xFF, 0xFE, 0x00]).write(to: invalidUTF8URL)
        do {
            _ = try SM64ModernConfigurationRuntime.load(from: invalidUTF8URL)
            preconditionFailure("invalid UTF-8 must fail closed")
        } catch SM64ModernConfigurationRuntimeError.invalidUTF8 {
            // Expected: malformed bytes must not be silently treated as an empty config.
        }

        print("configurationRuntimeFingerprint=0x\(String(repaired.configuration.fingerprint, radix: 16))")
        print("SM64 Modern configuration runtime smoke passed")
    }
}
