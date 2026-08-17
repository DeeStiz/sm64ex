import Darwin
import Foundation
import os

private let cameraMigrationLogger = Logger(
    subsystem: "io.github.deestiz.sm64modern",
    category: "CameraMigration"
)

private func cameraMigrationService(
    from context: UnsafeMutableRawPointer?
) -> SwiftCameraMigrationService? {
    guard let context else { return nil }
    return Unmanaged<SwiftCameraMigrationService>.fromOpaque(context)
        .takeUnretainedValue()
}

private let swiftCameraUpdate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernCameraStateV1>?,
    UnsafeMutablePointer<SM64ModernCameraStateV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = cameraMigrationService(from: context),
          let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.update(input: input.pointee, output: output)
}

/// Owner-thread adapter for the value-only camera selection seam. The C
/// camera still owns geometry, collision, cutscenes, and Lakitu presentation;
/// this service owns the selection/angle flag transitions and their exact
/// movement/sound side effects.
final class SwiftCameraMigrationService {
    private let ownerThreadToken: UInt64
    private let ownerThreadIdentity: UInt64
    private var eventCount: UInt64 = 0
    private var lastError: SM64ModernStatus = SM64_MODERN_STATUS_OK

    init(ownerThreadToken: UInt64) {
        self.ownerThreadToken = ownerThreadToken
        self.ownerThreadIdentity = Self.currentThreadIdentity()
    }

    func makeAPI() -> SM64ModernCameraMigrationApiV1 {
        assertOwnerThread()
        var api = SM64ModernCameraMigrationApiV1()
        api.header.abi_version = SM64_MODERN_ABI_VERSION_1
        api.header.struct_size = UInt32(
            MemoryLayout<SM64ModernCameraMigrationApiV1>.size
        )
        api.context = Unmanaged.passUnretained(self).toOpaque()
        api.update = swiftCameraUpdate
        return api
    }

    func update(
        input: SM64ModernCameraStateV1,
        output: UnsafeMutablePointer<SM64ModernCameraStateV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard lastError == SM64_MODERN_STATUS_OK else { return lastError }
        guard input.header.abi_version == SM64_MODERN_ABI_VERSION_1,
              input.header.struct_size >= UInt32(
                MemoryLayout<SM64ModernCameraStateV1>.size
              ),
              input.reserved == 0,
              input.command == SM64_MODERN_CAMERA_COMMAND_SELECT_ALT_MODE
                || input.command == SM64_MODERN_CAMERA_COMMAND_SET_ANGLE,
              input.pan_distance.isFinite,
              input.cannon_y_offset.isFinite else {
            return fail(SM64_MODERN_STATUS_INVALID_ARGUMENT, boundary: "input")
        }

        var state = SM64CameraModeState(
            selectionFlags: input.selection_flags,
            movementFlags: input.movement_flags,
            soundFlags: input.sound_flags,
            statusFlags: input.status_flags,
            mode: input.mode,
            defaultMode: input.default_mode,
            lastMode: input.last_mode,
            newMode: input.new_mode,
            transitionFramesLeft: input.transition_frames_left,
            transitionMax: input.transition_max,
            transitionFrame: input.transition_frame,
            cUpCameraPitch: input.c_up_camera_pitch,
            modeOffsetYaw: input.mode_offset_yaw,
            lakituDistance: input.lakitu_distance,
            lakituPitch: input.lakitu_pitch,
            areaYawChange: input.area_yaw_change,
            panDistance: input.pan_distance,
            cannonYOffset: input.cannon_y_offset
        )

        let argument = Int16(clamping: input.argument)
        let result: Int16
        switch input.command {
        case SM64_MODERN_CAMERA_COMMAND_SELECT_ALT_MODE:
            let selection = SM64CameraModeStateMachine.selectAlternateMode(
                argument, state: state
            )
            state = selection.state
            result = selection.selection.rawValue
        case SM64_MODERN_CAMERA_COMMAND_SET_ANGLE:
            let angle = SM64CameraModeStateMachine.setCameraAngle(
                argument, state: state
            )
            state = angle.state
            result = angle.angle.rawValue
        default:
            return fail(SM64_MODERN_STATUS_INVALID_ARGUMENT, boundary: "command")
        }

        var next = input
        next.header.abi_version = SM64_MODERN_ABI_VERSION_1
        next.header.struct_size = UInt32(
            MemoryLayout<SM64ModernCameraStateV1>.size
        )
        next.selection_flags = state.selectionFlags
        next.movement_flags = state.movementFlags
        next.sound_flags = state.soundFlags
        next.status_flags = state.statusFlags
        next.mode = state.mode
        next.default_mode = state.defaultMode
        next.last_mode = state.lastMode
        next.new_mode = state.newMode
        next.transition_frames_left = state.transitionFramesLeft
        next.transition_max = state.transitionMax
        next.transition_frame = state.transitionFrame
        next.c_up_camera_pitch = state.cUpCameraPitch
        next.mode_offset_yaw = state.modeOffsetYaw
        next.lakitu_distance = state.lakituDistance
        next.lakitu_pitch = state.lakituPitch
        next.area_yaw_change = state.areaYawChange
        next.pan_distance = state.panDistance
        next.cannon_y_offset = state.cannonYOffset
        next.result = Int32(result)
        next.reserved = 0
        output.pointee = next

        eventCount &+= 1
        if eventCount == 1 || eventCount.isMultiple(of: 600) {
            cameraMigrationLogger.notice(
                "swift_camera_selection_update command=\(input.command) argument=\(input.argument) result=\(next.result) event=\(self.eventCount) owner_token=\(self.ownerThreadToken, privacy: .public)"
            )
        }
        return SM64_MODERN_STATUS_OK
    }

    private func fail(
        _ status: SM64ModernStatus,
        boundary: String
    ) -> SM64ModernStatus {
        if lastError == SM64_MODERN_STATUS_OK {
            lastError = status
            cameraMigrationLogger.error(
                "swift_camera_migration_failed status=\(status) boundary=\(boundary, privacy: .public)"
            )
        }
        return status
    }

    private func assertOwnerThread() {
        precondition(
            Self.currentThreadIdentity() == ownerThreadIdentity,
            "camera migration must run on its construction thread"
        )
    }

    private static func currentThreadIdentity() -> UInt64 {
        var identifier: UInt64 = 0
        let result = pthread_threadid_np(nil, &identifier)
        precondition(result == 0, "pthread_threadid_np must produce an owner token")
        return identifier
    }
}
