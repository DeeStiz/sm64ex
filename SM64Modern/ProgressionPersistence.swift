import Foundation

enum SM64ProgressionRouteKind: UInt8, Equatable, Sendable {
    case redCoin = 0
    case hiddenRedCoinStar = 1
    case capSwitch = 2
    case levelReward = 3
}

struct SM64ProgressionRouteIdentity: Hashable, Equatable, Sendable {
    let level: UInt16
    let area: UInt8
    let behaviorIdentity: UInt64
    let instance: UInt16
}

struct SM64ProgressionRouteLifetime: Equatable, Sendable {
    let identity: SM64ProgressionRouteIdentity
    let kind: SM64ProgressionRouteKind
    private(set) var generation: UInt32
    private(set) var active: Bool
    let parent: SM64ProgressionRouteIdentity?

    init(
        identity: SM64ProgressionRouteIdentity,
        kind: SM64ProgressionRouteKind,
        parent: SM64ProgressionRouteIdentity? = nil
    ) {
        self.identity = identity
        self.kind = kind
        self.generation = 0
        self.active = false
        self.parent = parent
    }

    @discardableResult
    mutating func activate() -> Bool {
        guard !active else { return false }
        generation &+= 1
        active = true
        return true
    }

    @discardableResult
    mutating func deactivate() -> Bool {
        guard active else { return false }
        active = false
        return true
    }
}

struct SM64PersistenceBundle: Equatable, Sendable {
    static let byteCount =
        SM64SaveFileSnapshot.byteCount * 2 + SM64MenuDataSnapshot.byteCount * 2

    let savePrimary: [UInt8]
    let saveBackup: [UInt8]
    let menuPrimary: [UInt8]
    let menuBackup: [UInt8]

    init(
        savePrimary: [UInt8], saveBackup: [UInt8],
        menuPrimary: [UInt8], menuBackup: [UInt8]
    ) {
        precondition(savePrimary.count == SM64SaveFileSnapshot.byteCount)
        precondition(saveBackup.count == SM64SaveFileSnapshot.byteCount)
        precondition(menuPrimary.count == SM64MenuDataSnapshot.byteCount)
        precondition(menuBackup.count == SM64MenuDataSnapshot.byteCount)
        self.savePrimary = savePrimary
        self.saveBackup = saveBackup
        self.menuPrimary = menuPrimary
        self.menuBackup = menuBackup
    }

    var bytes: [UInt8] {
        savePrimary + saveBackup + menuPrimary + menuBackup
    }

    static func decode(_ bytes: [UInt8]) -> SM64PersistenceBundle? {
        guard bytes.count == Self.byteCount else { return nil }
        let saveEnd = SM64SaveFileSnapshot.byteCount
        let saveBackupEnd = saveEnd * 2
        let menuEnd = saveBackupEnd + SM64MenuDataSnapshot.byteCount
        return SM64PersistenceBundle(
            savePrimary: Array(bytes[0..<saveEnd]),
            saveBackup: Array(bytes[saveEnd..<saveBackupEnd]),
            menuPrimary: Array(bytes[saveBackupEnd..<menuEnd]),
            menuBackup: Array(bytes[menuEnd..<Self.byteCount])
        )
    }
}

struct SM64PersistenceLoadResult: Equatable, Sendable {
    let save: SM64SaveFileSnapshot
    let menu: SM64MenuDataSnapshot
    let saveDecision: SM64SaveRecoveryDecision
    let menuDecision: SM64MenuDataRecoveryDecision

    var requiresRewrite: Bool {
        saveDecision != .usePrimary || menuDecision != .usePrimary
    }
}

/// Owner-thread persistence adapter for the four C-compatible save slots.
/// The complete bundle is replaced with Data.write(.atomic), so save and menu
/// slots share one durable commit boundary while the value codecs retain C's
/// individual checksum/recovery semantics.
final class SM64OwnerThreadPersistenceAdapter: @unchecked Sendable {
    let bundleURL: URL
    private let ownerThreadToken: UInt64
    private let fileManager: FileManager

    init(
        rootURL: URL,
        ownerThreadToken: UInt64,
        fileManager: FileManager = .default
    ) throws {
        self.bundleURL = rootURL.appendingPathComponent("save-bundle.bin")
        self.ownerThreadToken = ownerThreadToken
        self.fileManager = fileManager
        try fileManager.createDirectory(
            at: rootURL, withIntermediateDirectories: true
        )
    }

    func commit(
        save: SM64SaveFileSnapshot,
        menu: SM64MenuDataSnapshot,
        ownerThreadToken: UInt64
    ) throws {
        precondition(ownerThreadToken == self.ownerThreadToken)
        let saveBytes = SM64SaveFileCodec.encode(save)
        let menuBytes = SM64MenuDataCodec.encode(menu)
        let bundle = SM64PersistenceBundle(
            savePrimary: saveBytes, saveBackup: saveBytes,
            menuPrimary: menuBytes, menuBackup: menuBytes
        )
        try Data(bundle.bytes).write(to: bundleURL, options: .atomic)
    }

    func load(ownerThreadToken: UInt64) throws -> SM64PersistenceLoadResult {
        precondition(ownerThreadToken == self.ownerThreadToken)
        let bundle = try readBundle()
        let saveRecovery = SM64SaveFileCodec.recover(
            primary: bundle?.savePrimary ?? [], backup: bundle?.saveBackup ?? []
        )
        let menuRecovery = SM64MenuDataCodec.recover(
            primary: bundle?.menuPrimary ?? [], backup: bundle?.menuBackup ?? []
        )
        return SM64PersistenceLoadResult(
            save: saveRecovery.selected ?? SM64SaveFileSnapshot(),
            menu: menuRecovery.selected ?? SM64MenuDataSnapshot(),
            saveDecision: saveRecovery.decision,
            menuDecision: menuRecovery.decision
        )
    }

    /// Game-over reload uses the durable backup copies without mutating the
    /// primary slots or emitting a persistence write.
    func reload(ownerThreadToken: UInt64) throws -> SM64PersistenceLoadResult {
        precondition(ownerThreadToken == self.ownerThreadToken)
        let bundle = try readBundle()
        let save = SM64SaveFileCodec.decode(bundle?.saveBackup ?? [])
            ?? SM64SaveFileSnapshot()
        let menu = SM64MenuDataCodec.decode(bundle?.menuBackup ?? [])
            ?? SM64MenuDataSnapshot()
        return SM64PersistenceLoadResult(
            save: save, menu: menu,
            saveDecision: .usePrimary, menuDecision: .usePrimary
        )
    }

    private func readBundle() throws -> SM64PersistenceBundle? {
        guard fileManager.fileExists(atPath: bundleURL.path) else { return nil }
        let bytes = Array(try Data(contentsOf: bundleURL))
        return SM64PersistenceBundle.decode(bytes)
    }
}
