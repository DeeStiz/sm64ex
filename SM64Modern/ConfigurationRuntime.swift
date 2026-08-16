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
    static let sidecarFileName = "sm64-modern-config.swift.txt"

    static func fileURL(saveDirectory: String) -> URL {
        URL(fileURLWithPath: saveDirectory, isDirectory: true).appending(path: fileName)
    }

    static func sidecarURL(saveDirectory: String) -> URL {
        URL(fileURLWithPath: saveDirectory, isDirectory: true).appending(path: sidecarFileName)
    }

    private static func sidecarURL(for fileURL: URL) -> URL {
        fileURL.deletingLastPathComponent().appending(path: sidecarFileName)
    }

    static func load(
        from url: URL,
        persistRepairs: Bool = true,
        sidecarURL explicitSidecarURL: URL? = nil
    ) throws -> SM64ModernConfigurationLoadResult {
        let primaryExists = FileManager.default.fileExists(atPath: url.path)
        let primaryText: String?
        let primaryResult: SM64ModernConfiguration.ParseResult
        if primaryExists {
            let data = try Data(contentsOf: url)
            guard let text = String(data: data, encoding: .utf8) else {
                throw SM64ModernConfigurationRuntimeError.invalidUTF8(url)
            }
            primaryText = text
            primaryResult = SM64ModernConfiguration.parse(text)
        } else {
            primaryText = nil
            primaryResult = SM64ModernConfiguration.ParseResult(
                configuration: .defaults,
                repairedKeys: [], unknownKeys: [], malformedLines: []
            )
        }

        let sidecar = explicitSidecarURL ?? sidecarURL(for: url)
        let sidecarExists = FileManager.default.fileExists(atPath: sidecar.path)
        let sidecarResult: SM64ModernConfiguration.ParseResult?
        if sidecarExists {
            let data = try Data(contentsOf: sidecar)
            guard let text = String(data: data, encoding: .utf8) else {
                throw SM64ModernConfigurationRuntimeError.invalidUTF8(sidecar)
            }
            sidecarResult = SM64ModernConfiguration.parse(text)
        } else {
            sidecarResult = nil
        }

        var configuration = primaryResult.configuration
        if let sidecarResult {
            configuration = configuration.applyingSwiftOnly(
                from: sidecarResult.configuration
            )
        }

        var repairedKeys = primaryResult.repairedKeys
        var unknownKeys = primaryResult.unknownKeys
        var malformedLines = primaryResult.malformedLines
        if let sidecarResult {
            repairedKeys += sidecarResult.repairedKeys.map { "sidecar.\($0)" }
            unknownKeys += sidecarResult.unknownKeys.map { "sidecar.\($0)" }
            malformedLines += sidecarResult.malformedLines
        }

        let shouldCreateSidecar = !sidecarExists
            && primaryText.map {
                SM64ModernConfiguration.containsSwiftOnlyKey(in: $0)
            } == true
        let shouldRepairPrimary = primaryResult.didRepair
        let shouldRepairSidecar = sidecarResult?.didRepair == true
        guard persistRepairs else {
            return SM64ModernConfigurationLoadResult(
                configuration: configuration,
                source: primaryExists ? .persisted : .defaults,
                repairedKeys: repairedKeys,
                unknownKeys: unknownKeys,
                malformedLines: malformedLines,
                repairPersisted: false,
                repairPersistenceError: nil
            )
        }

        var persistenceErrors: [String] = []
        var didPersistRepair = false
        if shouldRepairPrimary {
            do {
                try persistLegacy(primaryResult.configuration, to: url)
                didPersistRepair = true
            } catch {
                // A repaired in-memory value is safer than rejecting launch;
                // the caller logs this separately and can retry on shutdown.
                persistenceErrors.append("primary: \(error.localizedDescription)")
            }
        }
        if shouldCreateSidecar || shouldRepairSidecar {
            do {
                try persistModern(configuration, to: sidecar)
                didPersistRepair = true
            } catch {
                persistenceErrors.append("sidecar: \(error.localizedDescription)")
            }
        }

        return SM64ModernConfigurationLoadResult(
            configuration: configuration,
            source: primaryExists ? .persisted : .defaults,
            repairedKeys: repairedKeys,
            unknownKeys: unknownKeys,
            malformedLines: malformedLines,
            repairPersisted: didPersistRepair,
            repairPersistenceError: persistenceErrors.isEmpty
                ? nil : persistenceErrors.joined(separator: "; ")
        )
    }

    static func persistLegacy(
        _ configuration: SM64ModernConfiguration,
        to url: URL
    ) throws {
        let data = Data(configuration.encodeLegacy().utf8)
        try data.write(to: url, options: [.atomic])
    }

    static func persistModern(
        _ configuration: SM64ModernConfiguration,
        to url: URL
    ) throws {
        let data = Data(configuration.encodeModern().utf8)
        try data.write(to: url, options: [.atomic])
    }
}
