import Darwin
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
/// Immutable, sendable descriptor for owner-thread persistence operations. The
/// file system is external state; every operation still requires the adapter's
/// engine token and construction-thread token before accessing it.
final class SM64OwnerThreadPersistenceAdapter: Sendable {
    let bundleURL: URL
    private let ownerThreadToken: UInt64
    private let ownerThreadIdentity: UInt64

    init(
        rootURL: URL,
        ownerThreadToken: UInt64
    ) throws {
        self.bundleURL = rootURL.appendingPathComponent("save-bundle.bin")
        self.ownerThreadToken = ownerThreadToken
        self.ownerThreadIdentity = Self.currentThreadIdentity()
        try FileManager.default.createDirectory(
            at: rootURL, withIntermediateDirectories: true
        )
    }

    func commit(
        save: SM64SaveFileSnapshot,
        menu: SM64MenuDataSnapshot,
        ownerThreadToken: UInt64
    ) throws {
        assertOwnerThread(ownerThreadToken)
        let saveBytes = SM64SaveFileCodec.encode(save)
        let menuBytes = SM64MenuDataCodec.encode(menu)
        let bundle = SM64PersistenceBundle(
            savePrimary: saveBytes, saveBackup: saveBytes,
            menuPrimary: menuBytes, menuBackup: menuBytes
        )
        try Data(bundle.bytes).write(to: bundleURL, options: .atomic)
    }

    func load(ownerThreadToken: UInt64) throws -> SM64PersistenceLoadResult {
        assertOwnerThread(ownerThreadToken)
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
        assertOwnerThread(ownerThreadToken)
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
        guard FileManager.default.fileExists(atPath: bundleURL.path) else { return nil }
        let bytes = Array(try Data(contentsOf: bundleURL))
        return SM64PersistenceBundle.decode(bytes)
    }

    private func assertOwnerThread(_ token: UInt64) {
        precondition(token == ownerThreadToken)
        precondition(
            Self.currentThreadIdentity() == ownerThreadIdentity,
            "SM64OwnerThreadPersistenceAdapter is owner-thread-only"
        )
    }

    private static func currentThreadIdentity() -> UInt64 {
        var identifier: UInt64 = 0
        precondition(
            pthread_threadid_np(nil, &identifier) == 0,
            "pthread_threadid_np must produce an owner token"
        )
        return identifier
    }
}

/// Normalized little-endian image of the C `SaveBuffer`.
///
/// The legacy adapter above is intentionally kept as the single-bundle
/// composition fixture used by the earlier M17 milestones. The live migration
/// bridge uses this image adapter so all four save files share one atomic menu
/// block, exactly like C's four save slots plus two menu slots.
struct SM64PersistenceImage: Equatable, Sendable {
    static let fileCount = SM64CoinScoreAgeState.fileCount
    static let byteCount =
        SM64SaveFileSnapshot.byteCount * fileCount * 2
            + SM64MenuDataSnapshot.byteCount * 2

    var savePrimary: [[UInt8]]
    var saveBackup: [[UInt8]]
    var menuPrimary: [UInt8]
    var menuBackup: [UInt8]

    init(
        savePrimary: [[UInt8]], saveBackup: [[UInt8]],
        menuPrimary: [UInt8], menuBackup: [UInt8]
    ) {
        precondition(savePrimary.count == Self.fileCount)
        precondition(saveBackup.count == Self.fileCount)
        precondition(savePrimary.allSatisfy {
            $0.count == SM64SaveFileSnapshot.byteCount
        })
        precondition(saveBackup.allSatisfy {
            $0.count == SM64SaveFileSnapshot.byteCount
        })
        precondition(menuPrimary.count == SM64MenuDataSnapshot.byteCount)
        precondition(menuBackup.count == SM64MenuDataSnapshot.byteCount)
        self.savePrimary = savePrimary
        self.saveBackup = saveBackup
        self.menuPrimary = menuPrimary
        self.menuBackup = menuBackup
    }

    static func empty() -> SM64PersistenceImage {
        let save = SM64SaveFileCodec.encode(SM64SaveFileSnapshot())
        let menu = SM64MenuDataCodec.encode(SM64MenuDataSnapshot())
        return SM64PersistenceImage(
            savePrimary: Array(repeating: save, count: Self.fileCount),
            saveBackup: Array(repeating: save, count: Self.fileCount),
            menuPrimary: menu, menuBackup: menu
        )
    }

    var bytes: [UInt8] {
        savePrimary.flatMap { $0 }
            + saveBackup.flatMap { $0 }
            + menuPrimary + menuBackup
    }

    static func decode(_ bytes: [UInt8]) -> SM64PersistenceImage? {
        guard bytes.count == Self.byteCount else { return nil }
        let saveBytes = SM64SaveFileSnapshot.byteCount
        let savesEnd = saveBytes * Self.fileCount
        var primary = [[UInt8]]()
        var backup = [[UInt8]]()
        primary.reserveCapacity(Self.fileCount)
        backup.reserveCapacity(Self.fileCount)
        for index in 0..<Self.fileCount {
            let start = index * saveBytes
            primary.append(Array(bytes[start..<(start + saveBytes)]))
            let backupStart = savesEnd + start
            backup.append(Array(bytes[backupStart..<(backupStart + saveBytes)]))
        }
        let menuStart = savesEnd * 2
        let menuEnd = menuStart + SM64MenuDataSnapshot.byteCount
        return SM64PersistenceImage(
            savePrimary: primary, saveBackup: backup,
            menuPrimary: Array(bytes[menuStart..<menuEnd]),
            menuBackup: Array(bytes[menuEnd..<Self.byteCount])
        )
    }
}

/// Owner-thread adapter for the complete normalized C EEPROM image.
///
/// `commit` replaces the entire 512-byte image atomically, while `load` and
/// `reload` select one save file against the shared menu slots. `load` also
/// performs C-compatible one-bad-copy repair (or wipes both copies when both
/// signatures fail) in the same atomic replacement boundary. A legacy
/// 176-byte M17 bundle is accepted once as slot zero and upgraded on the first
/// owner-thread load/commit, making the bridge migration-safe without
/// weakening checksums.
/// Immutable, sendable descriptor for the normalized EEPROM image. All file
/// access remains owner-thread-only and is guarded by the engine token plus the
/// construction pthread identity.
final class SM64OwnerThreadEEPROMAdapter: Sendable {
    let imageURL: URL
    private let legacyBundleURL: URL
    private let ownerThreadToken: UInt64
    private let ownerThreadIdentity: UInt64

    init(
        rootURL: URL,
        ownerThreadToken: UInt64
    ) throws {
        self.imageURL = rootURL.appendingPathComponent("eeprom-image.bin")
        self.legacyBundleURL = rootURL.appendingPathComponent("save-bundle.bin")
        self.ownerThreadToken = ownerThreadToken
        self.ownerThreadIdentity = Self.currentThreadIdentity()
        try FileManager.default.createDirectory(
            at: rootURL, withIntermediateDirectories: true
        )
    }

    func commit(
        saveFileIndex: Int,
        save: SM64SaveFileSnapshot,
        menu: SM64MenuDataSnapshot,
        ownerThreadToken: UInt64
    ) throws {
        assertOwnerThread(ownerThreadToken)
        guard (0..<SM64PersistenceImage.fileCount).contains(saveFileIndex) else {
            throw SM64PersistenceAdapterError.invalidSaveFileIndex
        }
        var image = try readImage() ?? .empty()
        let saveBytes = SM64SaveFileCodec.encode(save)
        let menuBytes = SM64MenuDataCodec.encode(menu)
        image.savePrimary[saveFileIndex] = saveBytes
        image.saveBackup[saveFileIndex] = saveBytes
        image.menuPrimary = menuBytes
        image.menuBackup = menuBytes
        try Data(image.bytes).write(to: imageURL, options: .atomic)
    }

    /// C `save_file_erase`: touch the destination file's high-score ages,
    /// clear its complete SaveFile payload, and persist both save copies plus
    /// the shared menu pair in one owner-thread atomic image replacement.
    func erase(
        saveFileIndex: Int,
        ownerThreadToken: UInt64
    ) throws {
        assertOwnerThread(ownerThreadToken)
        try validate(saveFileIndex: saveFileIndex)
        _ = try load(
            saveFileIndex: saveFileIndex,
            ownerThreadToken: ownerThreadToken
        )
        var image = try readImage() ?? .empty()
        let menu = try menuSnapshot(from: image)
        let aged = SM64CoinScoreAgeReducer.touchAll(
            fileIndex: saveFileIndex,
            state: SM64CoinScoreAgeState(ages: menu.coinScoreAges)
        ) ?? SM64CoinScoreAgeState(ages: menu.coinScoreAges)
        let nextMenu = SM64MenuDataSnapshot(
            coinScoreAges: aged.ages,
            soundMode: menu.soundMode,
            filler: menu.filler
        )
        let emptySave = SM64SaveFileCodec.encode(SM64SaveFileSnapshot())
        image.savePrimary[saveFileIndex] = emptySave
        image.saveBackup[saveFileIndex] = emptySave
        let menuBytes = SM64MenuDataCodec.encode(nextMenu)
        image.menuPrimary = menuBytes
        image.menuBackup = menuBytes
        try writeImage(image)
    }

    /// C `save_file_copy`: age the destination's coin-score entries before
    /// copying the source SaveFile into both destination copies.
    func copy(
        saveFileIndex sourceSaveFileIndex: Int,
        to destinationSaveFileIndex: Int,
        ownerThreadToken: UInt64
    ) throws {
        assertOwnerThread(ownerThreadToken)
        try validate(saveFileIndex: sourceSaveFileIndex)
        try validate(saveFileIndex: destinationSaveFileIndex)
        _ = try load(
            saveFileIndex: destinationSaveFileIndex,
            ownerThreadToken: ownerThreadToken
        )
        var image = try readImage() ?? .empty()
        let source = SM64SaveFileCodec.decode(
            image.savePrimary[sourceSaveFileIndex]
        ) ?? SM64SaveFileSnapshot()
        let menu = try menuSnapshot(from: image)
        let aged = SM64CoinScoreAgeReducer.touchAll(
            fileIndex: destinationSaveFileIndex,
            state: SM64CoinScoreAgeState(ages: menu.coinScoreAges)
        ) ?? SM64CoinScoreAgeState(ages: menu.coinScoreAges)
        let nextMenu = SM64MenuDataSnapshot(
            coinScoreAges: aged.ages,
            soundMode: menu.soundMode,
            filler: menu.filler
        )
        let saveBytes = SM64SaveFileCodec.encode(source)
        image.savePrimary[destinationSaveFileIndex] = saveBytes
        image.saveBackup[destinationSaveFileIndex] = saveBytes
        let menuBytes = SM64MenuDataCodec.encode(nextMenu)
        image.menuPrimary = menuBytes
        image.menuBackup = menuBytes
        try writeImage(image)
    }

    func load(
        saveFileIndex: Int,
        ownerThreadToken: UInt64
    ) throws -> SM64PersistenceLoadResult {
        assertOwnerThread(ownerThreadToken)
        guard (0..<SM64PersistenceImage.fileCount).contains(saveFileIndex) else {
            throw SM64PersistenceAdapterError.invalidSaveFileIndex
        }
        let image = try readImage()
        let result = recover(image: image, saveFileIndex: saveFileIndex)
        var repaired = image ?? .empty()
        var needsWrite = image == nil
        // C validates and repairs every save file during save_file_load_all,
        // even though the caller later selects only one current file. Keep
        // that whole-image behavior here so a background slot cannot remain
        // corrupt merely because the selected index was healthy.
        for index in 0..<SM64PersistenceImage.fileCount {
            let saveRecovery = SM64SaveFileCodec.recover(
                primary: repaired.savePrimary[index],
                backup: repaired.saveBackup[index]
            )
            switch saveRecovery.decision {
            case .usePrimary:
                break
            case .usePrimaryAndRewriteBackup, .useBackupAndRewritePrimary,
                 .eraseAndRewriteBoth:
                let selectedSave = saveRecovery.selected ?? SM64SaveFileSnapshot()
                let bytes = SM64SaveFileCodec.encode(selectedSave)
                repaired.savePrimary[index] = bytes
                repaired.saveBackup[index] = bytes
                needsWrite = true
            }
        }
        let menuRecovery = SM64MenuDataCodec.recover(
            primary: repaired.menuPrimary,
            backup: repaired.menuBackup
        )
        switch menuRecovery.decision {
        case .usePrimary:
            break
        case .usePrimaryAndRewriteBackup, .useBackupAndRewritePrimary,
             .wipeAndRewriteBoth:
            let selectedMenu = menuRecovery.selected ?? SM64MenuDataSnapshot()
            let bytes = SM64MenuDataCodec.encode(selectedMenu)
            repaired.menuPrimary = bytes
            repaired.menuBackup = bytes
            needsWrite = true
        }
        // A legacy 176-byte bundle is read as slot zero by readImage(). Once
        // the owner thread observes it, publish the normalized 512-byte C
        // SaveBuffer image even when every legacy checksum was already valid.
        // This is the same one-way upgrade boundary used by the native bridge.
        let needsLegacyUpgrade = !FileManager.default.fileExists(
            atPath: imageURL.path
        ) && FileManager.default.fileExists(atPath: legacyBundleURL.path)
        if needsLegacyUpgrade { needsWrite = true }
        if needsWrite {
            try writeImage(repaired)
        }
        return result
    }

    func reload(
        saveFileIndex: Int,
        ownerThreadToken: UInt64
    ) throws -> SM64PersistenceLoadResult {
        assertOwnerThread(ownerThreadToken)
        guard (0..<SM64PersistenceImage.fileCount).contains(saveFileIndex) else {
            throw SM64PersistenceAdapterError.invalidSaveFileIndex
        }
        let image = try readImage()
        let saveBytes = image?.saveBackup[saveFileIndex] ?? []
        let menuBytes = image?.menuBackup ?? []
        return SM64PersistenceLoadResult(
            save: SM64SaveFileCodec.decode(saveBytes)
                ?? SM64SaveFileSnapshot(),
            menu: SM64MenuDataCodec.decode(menuBytes)
                ?? SM64MenuDataSnapshot(),
            saveDecision: .usePrimary, menuDecision: .usePrimary
        )
    }

    private func recover(
        image: SM64PersistenceImage?, saveFileIndex: Int
    ) -> SM64PersistenceLoadResult {
        let saveRecovery = SM64SaveFileCodec.recover(
            primary: image?.savePrimary[saveFileIndex] ?? [],
            backup: image?.saveBackup[saveFileIndex] ?? []
        )
        let menuRecovery = SM64MenuDataCodec.recover(
            primary: image?.menuPrimary ?? [],
            backup: image?.menuBackup ?? []
        )
        return SM64PersistenceLoadResult(
            save: saveRecovery.selected ?? SM64SaveFileSnapshot(),
            menu: menuRecovery.selected ?? SM64MenuDataSnapshot(),
            saveDecision: saveRecovery.decision,
            menuDecision: menuRecovery.decision
        )
    }

    private func readImage() throws -> SM64PersistenceImage? {
        let sourceURL: URL
        if FileManager.default.fileExists(atPath: imageURL.path) {
            sourceURL = imageURL
        } else if FileManager.default.fileExists(atPath: legacyBundleURL.path) {
            sourceURL = legacyBundleURL
        } else {
            return nil
        }
        let bytes = Array(try Data(contentsOf: sourceURL))
        if let image = SM64PersistenceImage.decode(bytes) {
            return image
        }
        guard let legacy = SM64PersistenceBundle.decode(bytes) else {
            return nil
        }
        let empty = SM64PersistenceImage.empty()
        var primary = empty.savePrimary
        var backup = empty.saveBackup
        primary[0] = legacy.savePrimary
        backup[0] = legacy.saveBackup
        return SM64PersistenceImage(
            savePrimary: primary, saveBackup: backup,
            menuPrimary: legacy.menuPrimary, menuBackup: legacy.menuBackup
        )
    }

    private func writeImage(_ image: SM64PersistenceImage) throws {
        try Data(image.bytes).write(to: imageURL, options: .atomic)
    }

    private func validate(saveFileIndex: Int) throws {
        guard (0..<SM64PersistenceImage.fileCount).contains(saveFileIndex) else {
            throw SM64PersistenceAdapterError.invalidSaveFileIndex
        }
    }

    private func menuSnapshot(
        from image: SM64PersistenceImage
    ) throws -> SM64MenuDataSnapshot {
        SM64MenuDataCodec.decode(image.menuPrimary)
            ?? SM64MenuDataSnapshot()
    }

    private func assertOwnerThread(_ token: UInt64) {
        precondition(token == ownerThreadToken)
        precondition(
            Self.currentThreadIdentity() == ownerThreadIdentity,
            "SM64OwnerThreadEEPROMAdapter is owner-thread-only"
        )
    }

    private static func currentThreadIdentity() -> UInt64 {
        var identifier: UInt64 = 0
        precondition(
            pthread_threadid_np(nil, &identifier) == 0,
            "pthread_threadid_np must produce an owner token"
        )
        return identifier
    }
}

enum SM64PersistenceAdapterError: Error {
    case invalidSaveFileIndex
}
