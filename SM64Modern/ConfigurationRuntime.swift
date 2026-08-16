import Foundation

enum SM64ModernConfigurationFileSource: String, Sendable {
    case defaults
    case persisted
}

struct SM64ModernConfigurationLoadResult: Sendable {
    let configuration: SM64ModernConfiguration
    let source: SM64ModernConfigurationFileSource
    let repairedKeys: [String]
    let unknownKeys: [String]
    let malformedLines: [Int]
    let repairPersisted: Bool
    let repairPersistenceError: String?

    var didRepair: Bool {
        !repairedKeys.isEmpty || !malformedLines.isEmpty
    }
}

enum SM64ModernConfigurationRuntimeError: LocalizedError {
    case invalidUTF8(URL)

    var errorDescription: String? {
        switch self {
        case let .invalidUTF8(url):
            "Configuration file is not valid UTF-8: \(url.path)"
        }
    }
}

/// Owner-thread file boundary for the configuration schema. This type does
/// no AppKit work and has no global mutable state, so EngineHost can call it
/// during lifecycle initialization without exposing a pointer across queues.
enum SM64ModernConfigurationRuntime {
    static let fileName = "sm64-modern-config.txt"

    static func fileURL(saveDirectory: String) -> URL {
        URL(fileURLWithPath: saveDirectory, isDirectory: true).appending(path: fileName)
    }

    static func load(
        from url: URL,
        persistRepairs: Bool = true
    ) throws -> SM64ModernConfigurationLoadResult {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return SM64ModernConfigurationLoadResult(
                configuration: .defaults,
                source: .defaults,
                repairedKeys: [],
                unknownKeys: [],
                malformedLines: [],
                repairPersisted: false,
                repairPersistenceError: nil
            )
        }

        let data = try Data(contentsOf: url)
        guard let text = String(data: data, encoding: .utf8) else {
            throw SM64ModernConfigurationRuntimeError.invalidUTF8(url)
        }
        let parsed = SM64ModernConfiguration.parse(text)
        guard parsed.didRepair, persistRepairs else {
            return SM64ModernConfigurationLoadResult(
                configuration: parsed.configuration,
                source: .persisted,
                repairedKeys: parsed.repairedKeys,
                unknownKeys: parsed.unknownKeys,
                malformedLines: parsed.malformedLines,
                repairPersisted: false,
                repairPersistenceError: nil
            )
        }

        do {
            try persistLegacy(parsed.configuration, to: url)
            return SM64ModernConfigurationLoadResult(
                configuration: parsed.configuration,
                source: .persisted,
                repairedKeys: parsed.repairedKeys,
                unknownKeys: parsed.unknownKeys,
                malformedLines: parsed.malformedLines,
                repairPersisted: true,
                repairPersistenceError: nil
            )
        } catch {
            // A repaired in-memory value is safer than rejecting the launch;
            // the caller logs this separately and can retry on shutdown.
            return SM64ModernConfigurationLoadResult(
                configuration: parsed.configuration,
                source: .persisted,
                repairedKeys: parsed.repairedKeys,
                unknownKeys: parsed.unknownKeys,
                malformedLines: parsed.malformedLines,
                repairPersisted: false,
                repairPersistenceError: error.localizedDescription
            )
        }
    }

    static func persistLegacy(
        _ configuration: SM64ModernConfiguration,
        to url: URL
    ) throws {
        let data = Data(configuration.encodeLegacy().utf8)
        try data.write(to: url, options: [.atomic])
    }
}
