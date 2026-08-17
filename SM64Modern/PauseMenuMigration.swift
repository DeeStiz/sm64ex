import Darwin
import Foundation
import os

private let pauseMenuMigrationLogger = Logger(
    subsystem: "io.github.deestiz.sm64modern",
    category: "PauseMenuMigration"
)

private func pauseMenuCurrentThreadIdentity() -> UInt64 {
    var identifier: UInt64 = 0
    let result = pthread_threadid_np(nil, &identifier)
    precondition(result == 0, "pthread_threadid_np must produce an owner token")
    return identifier
}

private func pauseMenuMigrationService(
    from context: UnsafeMutableRawPointer?
) -> SwiftPauseMenuMigrationService? {
    guard let context else { return nil }
    return Unmanaged<SwiftPauseMenuMigrationService>.fromOpaque(context)
        .takeUnretainedValue()
}

private let swiftPauseMenuObserve: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernPauseMenuSnapshotV1>?
) -> SM64ModernStatus = { context, snapshot in
    guard let service = pauseMenuMigrationService(from: context), let snapshot else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.observe(snapshot: snapshot.pointee)
}

/// Owner-thread value bridge for the pause/menu reducer. The C renderer and
/// menu globals remain authoritative; this service consumes copied snapshots
/// so the reducer can be replayed and fingerprinted before a later cutover.
final class SwiftPauseMenuMigrationService {
    private let ownerThreadToken: UInt64
    private let constructionThreadToken: UInt64
    private var model = SM64PauseMenuModel()
    private(set) var eventCount: UInt64 = 0
    private(set) var outcomeCount: UInt64 = 0
    private(set) var boundaryFingerprint = SM64PauseMenuMigrationFingerprint.offset
    private var loggedFirstEvent = false
    private var lastError: SM64ModernStatus = SM64_MODERN_STATUS_OK

    init(ownerThreadToken: UInt64) {
        self.ownerThreadToken = ownerThreadToken
        self.constructionThreadToken = pauseMenuCurrentThreadIdentity()
    }

    func makeAPI() -> SM64ModernPauseMenuMigrationApiV1 {
        assertOwnerThread()
        var api = SM64ModernPauseMenuMigrationApiV1()
        api.header.abi_version = SM64_MODERN_ABI_VERSION_1
        api.header.struct_size = UInt32(
            MemoryLayout<SM64ModernPauseMenuMigrationApiV1>.size
        )
        api.context = Unmanaged.passUnretained(self).toOpaque()
        api.observe = swiftPauseMenuObserve
        return api
    }

    func observe(snapshot: SM64ModernPauseMenuSnapshotV1) -> SM64ModernStatus {
        assertOwnerThread()
        guard snapshot.header.abi_version == SM64_MODERN_ABI_VERSION_1,
              snapshot.header.struct_size >= UInt32(
                MemoryLayout<SM64ModernPauseMenuSnapshotV1>.size
              ),
              snapshot.state <= 2,
              snapshot.camera_selection >= 1,
              snapshot.camera_selection <= 2,
              snapshot.text_alpha <= 255,
              snapshot.menu_mode_active <= 1,
              snapshot.can_exit_course <= 1,
              snapshot.confirm_pressed <= 1,
              snapshot.reserved0 == 0,
              snapshot.course_minimum <= snapshot.course_maximum,
              snapshot.outcome <= 2,
              snapshot.reserved == 0,
              let state = SM64PauseMenuState(rawValue: UInt8(snapshot.state)),
              let cameraSelection = SM64PauseCameraSelection(
                rawValue: Int8(snapshot.camera_selection)
              ),
              let outcome = SM64PauseMenuOutcome(rawValue: Int8(snapshot.outcome)) else {
            return fail(SM64_MODERN_STATUS_INVALID_ARGUMENT)
        }

        let result = model.synchronize(
            state: state,
            selection: Int8(clamping: snapshot.selection),
            cameraSelection: cameraSelection,
            textAlpha: UInt16(snapshot.text_alpha),
            menuModeActive: snapshot.menu_mode_active != 0,
            outcome: outcome,
            cameraChanged: snapshot.horizontal_camera_delta != 0
        )
        eventCount &+= 1
        if outcome != .none {
            outcomeCount &+= 1
        }
        boundaryFingerprint = SM64PauseMenuMigrationFingerprint.snapshot(
            boundaryFingerprint,
            snapshot: snapshot
        )

        if !loggedFirstEvent {
            loggedFirstEvent = true
            pauseMenuMigrationLogger.notice(
                "swift_pause_menu_observer state=\(result.state.rawValue, privacy: .public) tick=\(snapshot.simulation_tick, privacy: .public)"
            )
        }
        if outcome != .none {
            pauseMenuMigrationLogger.notice(
                "swift_pause_menu_outcome outcome=\(outcome.rawValue, privacy: .public) selection=\(result.selection, privacy: .public) tick=\(snapshot.simulation_tick, privacy: .public)"
            )
        }
        return SM64_MODERN_STATUS_OK
    }

    func summary() -> (
        events: UInt64,
        outcomes: UInt64,
        state: UInt8,
        fingerprint: UInt64
    ) {
        assertOwnerThread()
        return (
            eventCount,
            outcomeCount,
            model.state.rawValue,
            boundaryFingerprint
        )
    }

    private func assertOwnerThread() {
        precondition(pauseMenuCurrentThreadIdentity() == constructionThreadToken)
        precondition(pauseMenuCurrentThreadIdentity() == ownerThreadToken)
    }

    private func fail(_ status: SM64ModernStatus) -> SM64ModernStatus {
        lastError = status
        return status
    }
}

enum SM64PauseMenuMigrationFingerprint {
    static let offset: UInt64 = 1_469_598_103_934_665_603
    static let prime: UInt64 = 1_099_511_628_211

    static func hash(_ hash: UInt64, _ value: UInt64) -> UInt64 {
        var result = hash
        for shift in stride(from: 0, through: 56, by: 8) {
            result ^= (value >> UInt64(shift)) & 0xFF
            result &*= prime
        }
        return result
    }

    static func snapshot(
        _ initialHash: UInt64,
        snapshot: SM64ModernPauseMenuSnapshotV1
    ) -> UInt64 {
        var result = hash(initialHash, snapshot.simulation_tick)
        result = hash(result, UInt64(snapshot.state))
        result = hash(result, UInt64(UInt32(bitPattern: snapshot.selection)))
        result = hash(result, UInt64(UInt32(bitPattern: snapshot.camera_selection)))
        result = hash(result, UInt64(snapshot.text_alpha))
        result = hash(result, UInt64(snapshot.menu_mode_active))
        result = hash(result, UInt64(snapshot.can_exit_course))
        result = hash(result, UInt64(snapshot.confirm_pressed))
        result = hash(
            result,
            UInt64(UInt32(bitPattern: snapshot.vertical_selection_delta))
        )
        result = hash(
            result,
            UInt64(UInt32(bitPattern: snapshot.horizontal_camera_delta))
        )
        result = hash(result, UInt64(UInt32(bitPattern: snapshot.course_number)))
        result = hash(result, UInt64(UInt32(bitPattern: snapshot.course_minimum)))
        result = hash(result, UInt64(UInt32(bitPattern: snapshot.course_maximum)))
        return hash(result, UInt64(UInt32(bitPattern: snapshot.outcome)))
    }
}
