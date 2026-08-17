import Darwin
import Foundation
import os

private let frontEndMigrationLogger = Logger(
    subsystem: "io.github.deestiz.sm64modern",
    category: "FrontEndMigration"
)

private func frontendCurrentThreadIdentity() -> UInt64 {
    var identifier: UInt64 = 0
    let result = pthread_threadid_np(nil, &identifier)
    precondition(result == 0, "pthread_threadid_np must produce an owner token")
    return identifier
}

private func frontEndMigrationService(
    from context: UnsafeMutableRawPointer?
) -> SwiftFrontEndMigrationService? {
    guard let context else { return nil }
    return Unmanaged<SwiftFrontEndMigrationService>.fromOpaque(context)
        .takeUnretainedValue()
}

private let swiftFrontEndEvaluate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernFrontEndInputV1>?,
    UnsafeMutablePointer<SM64ModernFrontEndOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = frontEndMigrationService(from: context),
          let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.evaluate(input: input.pointee, output: output)
}

/// Owner-thread value bridge for the front-end/menu model. C remains the
/// compatibility owner for live menu globals, save-slot mutation, text
/// rendering, and transition side effects. This service consumes the exact
/// input edge sampled by the C input path and makes the Swift state machine
/// replayable before a later menu-authority cutover.
final class SwiftFrontEndMigrationService {
    private let ownerThreadToken: UInt64
    private let ownerThreadIdentity: UInt64
    private var model = SM64FrontEndModel()
    private(set) var eventCount: UInt64 = 0
    private(set) var transitionCount: UInt64 = 0
    private(set) var boundaryFingerprint: UInt64 = 1_469_598_103_934_665_603
    private(set) var lastResult: SM64FrontEndTickResult?
    private var loggedFirstEvent = false
    private var lastError: SM64ModernStatus = SM64_MODERN_STATUS_OK

    init(ownerThreadToken: UInt64) {
        self.ownerThreadToken = ownerThreadToken
        self.ownerThreadIdentity = frontendCurrentThreadIdentity()
    }

    func makeAPI() -> SM64ModernFrontEndMigrationApiV1 {
        assertOwnerThread()
        var api = SM64ModernFrontEndMigrationApiV1()
        api.header.abi_version = SM64_MODERN_ABI_VERSION_1
        api.header.struct_size = UInt32(
            MemoryLayout<SM64ModernFrontEndMigrationApiV1>.size
        )
        api.context = Unmanaged.passUnretained(self).toOpaque()
        api.evaluate = swiftFrontEndEvaluate
        return api
    }

    func evaluate(
        input: SM64ModernFrontEndInputV1,
        output: UnsafeMutablePointer<SM64ModernFrontEndOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard input.header.abi_version == SM64_MODERN_ABI_VERSION_1,
              input.header.struct_size >= UInt32(
                MemoryLayout<SM64ModernFrontEndInputV1>.size
              ),
              input.advance_legacy_domain <= 1,
              input.start_pressed <= 1,
              input.confirm_pressed <= 1,
              input.back_pressed <= 1,
              input.has_activity <= 1,
              input.debug_level_select <= 1,
              input.demo_complete <= 1,
              input.credits_complete <= 1,
              input.ending_complete <= 1,
              input.reserved == 0 else {
            return fail(SM64_MODERN_STATUS_INVALID_ARGUMENT)
        }

        let modelInput = SM64FrontEndInput(
            advanceLegacyDomain: input.advance_legacy_domain != 0,
            startPressed: input.start_pressed != 0,
            confirmPressed: input.confirm_pressed != 0,
            backPressed: input.back_pressed != 0,
            hasActivity: input.has_activity != 0,
            selectionDelta: input.selection_delta,
            debugLevelSelect: input.debug_level_select != 0,
            demoComplete: input.demo_complete != 0,
            creditsComplete: input.credits_complete != 0,
            endingComplete: input.ending_complete != 0
        )
        let result = model.tick(modelInput, demoCount: input.demo_count)
        eventCount &+= 1
        if result.transition != .none {
            transitionCount &+= 1
        }
        lastResult = result
        boundaryFingerprint = Self.hashResult(
            boundaryFingerprint, tick: input.simulation_tick, input: input, result: result
        )

        var next = SM64ModernFrontEndOutputV1()
        next.header.abi_version = SM64_MODERN_ABI_VERSION_1
        next.header.struct_size = UInt32(
            MemoryLayout<SM64ModernFrontEndOutputV1>.size
        )
        next.simulation_tick = input.simulation_tick
        next.screen = UInt32(result.screen.rawValue)
        next.transition = UInt32(result.transition.rawValue)
        next.selected_file = Int32(result.selectedFile)
        next.selected_course = Int32(result.selectedCourse)
        next.selected_level = Int32(result.selectedLevel)
        next.demo_index = Int32(result.demoIndex)
        next.title_zoom_counter = Int32(result.titleZoomCounter)
        next.title_fade_counter = Int32(result.titleFadeCounter)
        next.reserved = 0
        output.pointee = next

        if !loggedFirstEvent {
            loggedFirstEvent = true
            frontEndMigrationLogger.notice(
                "swift_frontend_observer screen=\(result.screen.rawValue, privacy: .public) tick=\(input.simulation_tick, privacy: .public)"
            )
        }
        if result.transition != .none {
            frontEndMigrationLogger.notice(
                "swift_frontend_transition transition=\(result.transition.rawValue, privacy: .public) screen=\(result.screen.rawValue, privacy: .public) tick=\(input.simulation_tick, privacy: .public)"
            )
        }
        return SM64_MODERN_STATUS_OK
    }

    func summary() -> (
        events: UInt64,
        transitions: UInt64,
        screen: UInt8,
        fingerprint: UInt64
    ) {
        assertOwnerThread()
        return (
            eventCount,
            transitionCount,
            lastResult?.screen.rawValue ?? SM64FrontEndScreen.title.rawValue,
            boundaryFingerprint
        )
    }

    private func assertOwnerThread() {
        precondition(frontendCurrentThreadIdentity() == ownerThreadIdentity)
        precondition(frontendCurrentThreadIdentity() == ownerThreadToken)
    }

    private func fail(_ status: SM64ModernStatus) -> SM64ModernStatus {
        lastError = status
        return status
    }

    private static func hash(
        _ hash: UInt64,
        _ value: UInt64
    ) -> UInt64 {
        var result = hash
        for shift in stride(from: 0, through: 56, by: 8) {
            result ^= (value >> UInt64(shift)) & 0xFF
            result &*= 1_099_511_628_211
        }
        return result
    }

    private static func hashResult(
        _ initialHash: UInt64,
        tick: UInt64,
        input: SM64ModernFrontEndInputV1,
        result: SM64FrontEndTickResult
    ) -> UInt64 {
        var resultHash = hash(initialHash, tick)
        resultHash = hash(resultHash, UInt64(input.advance_legacy_domain))
        resultHash = hash(resultHash, UInt64(input.start_pressed))
        resultHash = hash(resultHash, UInt64(input.confirm_pressed))
        resultHash = hash(resultHash, UInt64(input.back_pressed))
        resultHash = hash(resultHash, UInt64(input.has_activity))
        resultHash = hash(resultHash, UInt64(UInt16(bitPattern: input.selection_delta)))
        resultHash = hash(resultHash, UInt64(result.screen.rawValue))
        resultHash = hash(resultHash, UInt64(result.transition.rawValue))
        resultHash = hash(resultHash, UInt64(UInt8(bitPattern: result.selectedFile)))
        resultHash = hash(resultHash, UInt64(UInt16(bitPattern: result.selectedCourse)))
        resultHash = hash(resultHash, UInt64(UInt16(bitPattern: result.selectedLevel)))
        resultHash = hash(resultHash, UInt64(result.demoIndex))
        resultHash = hash(resultHash, UInt64(UInt16(bitPattern: result.titleZoomCounter)))
        return hash(resultHash, UInt64(UInt16(bitPattern: result.titleFadeCounter)))
    }
}
