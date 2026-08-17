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

private let swiftCameraEvaluate: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernCameraCallbackInputV1>?,
    UnsafeMutablePointer<SM64ModernCameraCallbackOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = cameraMigrationService(from: context),
          let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.evaluate(input: input.pointee, output: output)
}

private let swiftCameraEvaluateFOV: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernCameraFOVInputV1>?,
    UnsafeMutablePointer<SM64ModernCameraFOVOutputV1>?
) -> SM64ModernStatus = { context, input, output in
    guard let service = cameraMigrationService(from: context),
          let input, let output else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.evaluateFOV(input: input.pointee, output: output)
}

/// Owner-thread adapter for the value-only camera selection seam. The C
/// camera still owns geometry, collision, cutscenes, and Lakitu presentation;
/// this service owns the selection/angle flag transitions and their exact
/// movement/sound side effects.
final class SwiftCameraMigrationService {
    private let ownerThreadToken: UInt64
    private let ownerThreadIdentity: UInt64
    private var eventCount: UInt64 = 0
    private var loggedCommands: Set<UInt32> = []
    private var loggedCallbackModes: Set<Int16> = []
    private var loggedFOVModes: Set<UInt8> = []
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
        api.evaluate = swiftCameraEvaluate
        api.evaluate_fov = swiftCameraEvaluateFOV
        return api
    }

    func evaluateFOV(
        input: SM64ModernCameraFOVInputV1,
        output: UnsafeMutablePointer<SM64ModernCameraFOVOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard input.header.abi_version == SM64_MODERN_ABI_VERSION_1,
              input.header.struct_size >= UInt32(
                MemoryLayout<SM64ModernCameraFOVInputV1>.size
              ),
              input.reserved0 == 0,
              input.reserved == 0 else {
            return fail(SM64_MODERN_STATUS_INVALID_ARGUMENT, boundary: "fov_input")
        }

        guard let result = SM64CameraFOV.update(
            SM64CameraFOVInput(
                state: SM64CameraFOVState(
                    mode: Int16(input.fov_func),
                    fov: input.fov,
                    fovOffset: input.fov_offset,
                    shakeAmplitude: input.shake_amplitude,
                    shakePhase: input.shake_phase,
                    shakeSpeed: input.shake_speed,
                    decay: input.decay
                ),
                sleeping: input.sleeping != 0,
                fixedMode: input.fixed_mode != 0,
                cutsceneActive: input.cutscene_active != 0
            )
        ) else {
            return SM64_MODERN_STATUS_UNSUPPORTED_AUTHORITY
        }

        var next = SM64ModernCameraFOVOutputV1()
        next.header.abi_version = SM64_MODERN_ABI_VERSION_1
        next.header.struct_size = UInt32(
            MemoryLayout<SM64ModernCameraFOVOutputV1>.size
        )
        next.fov_func = input.fov_func
        next.sleeping = input.sleeping
        next.fixed_mode = input.fixed_mode
        next.cutscene_active = input.cutscene_active
        next.fov = result.state.fov
        next.fov_offset = result.state.fovOffset
        next.shake_amplitude = result.state.shakeAmplitude
        next.shake_phase = result.state.shakePhase
        next.shake_speed = result.state.shakeSpeed
        next.decay = result.state.decay
        next.presented_fov = result.presentedFOV
        next.reserved0 = 0
        next.reserved = 0
        output.pointee = next

        if loggedFOVModes.insert(input.fov_func).inserted {
            cameraMigrationLogger.notice(
                "swift_camera_fov mode=\(input.fov_func) fov=\(result.state.fov, privacy: .public) presented=\(result.presentedFOV, privacy: .public)"
            )
        }
        return SM64_MODERN_STATUS_OK
    }

    func evaluate(
        input: SM64ModernCameraCallbackInputV1,
        output: UnsafeMutablePointer<SM64ModernCameraCallbackOutputV1>
    ) -> SM64ModernStatus {
        assertOwnerThread()
        guard input.header.abi_version == SM64_MODERN_ABI_VERSION_1,
              input.header.struct_size >= UInt32(
                MemoryLayout<SM64ModernCameraCallbackInputV1>.size
              ),
              input.reserved1 == 0,
              input.reserved2 == 0,
              input.reserved3 == 0,
              input.reserved4 == 0,
              input.reserved == 0 else {
            return fail(SM64_MODERN_STATUS_INVALID_ARGUMENT, boundary: "callback_input")
        }

        let geometryModes: Set<Int16> = [1, 2, 14]
        let geometryFlags = input.geometry_flags
        let height: SM64CameraHeightInput?
        let slope: SM64CameraSlopeInput?
        if geometryModes.contains(input.mode) {
            height = SM64CameraHeightInput(
                marioY: input.mario_position.1,
                floorHeight: input.floor_height,
                waterHeight: geometryFlags
                    & UInt16(SM64_MODERN_CAMERA_CALLBACK_HAS_WATER_HEIGHT) != 0
                    ? input.water_height : nil,
                isMetalWater: geometryFlags
                    & UInt16(SM64_MODERN_CAMERA_CALLBACK_IS_METAL_WATER) != 0,
                isOnPole: geometryFlags
                    & UInt16(SM64_MODERN_CAMERA_CALLBACK_IS_ON_POLE) != 0,
                poleObjectY: geometryFlags
                    & UInt16(SM64_MODERN_CAMERA_CALLBACK_HAS_POLE_DATA) != 0
                    ? input.pole_object_y : nil,
                poleObjectHitboxHeight: geometryFlags
                    & UInt16(SM64_MODERN_CAMERA_CALLBACK_HAS_POLE_DATA) != 0
                    ? input.pole_hitbox_height : nil
            )
            slope = SM64CameraSlopeInput(
                marioY: input.mario_position.1,
                floorHeight: geometryFlags
                    & UInt16(SM64_MODERN_CAMERA_CALLBACK_HAS_SLOPE_FLOOR) != 0
                    ? input.slope_floor_height : nil,
                floorType: input.slope_floor_type,
                floorNormalZ: input.slope_floor_normal_z
            )
        } else {
            height = nil
            slope = nil
        }

        let callbackInput = SM64CameraCallbackInput(
            mode: input.mode,
            marioPosition: SM64ObjectVector3(
                x: input.mario_position.0,
                y: input.mario_position.1,
                z: input.mario_position.2
            ),
            areaCenter: SM64ObjectVector3(
                x: input.area_center.0,
                y: input.area_center.1,
                z: input.area_center.2
            ),
            cameraPosition: SM64ObjectVector3(
                x: input.camera_position.0,
                y: input.camera_position.1,
                z: input.camera_position.2
            ),
            cameraFocus: SM64ObjectVector3(
                x: input.camera_focus.0,
                y: input.camera_focus.1,
                z: input.camera_focus.2
            ),
            cameraDistance: input.camera_distance,
            cameraPitch: input.camera_pitch,
            cameraYaw: input.camera_yaw,
            faceYaw: input.face_yaw,
            facePitch: input.face_pitch,
            modeOffsetYaw: input.mode_offset_yaw,
            lakituPitch: input.lakitu_pitch,
            lakituDistance: input.lakitu_distance,
            zoomDistance: input.zoom_distance,
            eightDirectionBaseYaw: input.eight_direction_base_yaw,
            eightDirectionYawOffset: input.eight_direction_yaw_offset,
            cannonYOffset: input.cannon_y_offset,
            cButtonsPressed: input.c_buttons_pressed,
            sideButtonYaw: input.side_button_yaw,
            behindMarioSoundTimer: input.behind_mario_sound_timer,
            marioModeActive: input.state_flags
                & UInt16(SM64_MODERN_CAMERA_CALLBACK_MARIO_MODE_ACTIVE) != 0,
            waterOrMetalAction: input.state_flags
                & UInt16(SM64_MODERN_CAMERA_CALLBACK_WATER_OR_METAL_ACTION) != 0,
            fixedBasePosition: SM64ObjectVector3(
                x: input.fixed_base_position.0,
                y: input.fixed_base_position.1,
                z: input.fixed_base_position.2
            ),
            fixedScaleToMario: input.fixed_scale_to_mario,
            fixedHeightOffset: input.fixed_height_offset,
            fixedFloorHeight: input.fixed_flags
                & UInt16(SM64_MODERN_CAMERA_CALLBACK_HAS_FIXED_FLOOR) != 0
                ? input.fixed_floor_height : nil,
            fixedCeilingHeight: input.fixed_flags
                & UInt16(SM64_MODERN_CAMERA_CALLBACK_HAS_FIXED_CEILING) != 0
                ? input.fixed_ceiling_height : nil,
            fixedGoalHeight: input.fixed_goal_height,
            fixedFocusFloorOffset: input.fixed_focus_floor_offset,
            fixedSmoothMovement: input.fixed_flags
                & UInt16(SM64_MODERN_CAMERA_CALLBACK_FIXED_SMOOTH_MOVEMENT) != 0,
            bossSecondFocus: SM64ObjectVector3(
                x: input.boss_second_focus.0,
                y: input.boss_second_focus.1,
                z: input.boss_second_focus.2
            ),
            bossFocusDistance: input.boss_focus_distance,
            bossAngleVelocity: input.boss_angle_velocity,
            bossYaw: input.boss_yaw,
            bossHeldState: input.boss_held_state,
            bossFloorHeight: input.boss_flags
                & UInt16(SM64_MODERN_CAMERA_CALLBACK_HAS_BOSS_FLOOR_HEIGHT) != 0
                ? input.boss_floor_height : nil,
            bossForceHeight: input.boss_flags
                & UInt16(SM64_MODERN_CAMERA_CALLBACK_BOSS_FORCE_HEIGHT) != 0,
            spiralBasePosition: SM64ObjectVector3(
                x: input.spiral_base_position.0,
                y: input.spiral_base_position.1,
                z: input.spiral_base_position.2
            ),
            spiralFocusFloorOffset: input.spiral_focus_floor_offset,
            spiralFloorHeight: input.spiral_flags
                & UInt16(SM64_MODERN_CAMERA_CALLBACK_HAS_SPIRAL_FLOOR_HEIGHT) != 0
                ? input.spiral_floor_height : nil,
            spiralCurrentFloorHeight: input.spiral_current_floor_height,
            parallelPathStart: SM64ObjectVector3(
                x: input.parallel_path_start.0,
                y: input.parallel_path_start.1,
                z: input.parallel_path_start.2
            ),
            parallelPathEnd: SM64ObjectVector3(
                x: input.parallel_path_end.0,
                y: input.parallel_path_end.1,
                z: input.parallel_path_end.2
            ),
            parallelDistanceThreshold: input.parallel_dist_threshold,
            parallelZoom: input.parallel_zoom,
            parallelMarioFloorOffset: input.parallel_mario_floor_offset,
            parallelTransitionOffset: SM64ObjectVector3(
                x: input.parallel_transition_offset.0,
                y: input.parallel_transition_offset.1,
                z: input.parallel_transition_offset.2
            ),
            parallelReady: input.parallel_flags
                & UInt16(SM64_MODERN_CAMERA_CALLBACK_PARALLEL_READY) != 0,
            height: height,
            slope: slope
        )
        guard let result = SM64CameraModeCallbacks.evaluate(callbackInput) else {
            return SM64_MODERN_STATUS_UNSUPPORTED_AUTHORITY
        }

        var next = SM64ModernCameraCallbackOutputV1()
        next.header.abi_version = SM64_MODERN_ABI_VERSION_1
        next.header.struct_size = UInt32(
            MemoryLayout<SM64ModernCameraCallbackOutputV1>.size
        )
        next.focus = (result.focus.x, result.focus.y, result.focus.z)
        next.position = (result.position.x, result.position.y, result.position.z)
        next.camera_yaw = result.cameraYaw
        next.returned_yaw = result.returnedYaw
        next.area_yaw = result.areaYaw
        next.pitch = result.pitch
        next.distance = result.distance
        next.side_button_yaw = result.sideButtonYaw
        next.behind_mario_sound_timer = result.behindMarioSoundTimer
        next.flags = (result.outputsSwapped
            ? SM64_MODERN_CAMERA_CALLBACK_OUTPUTS_SWAPPED : 0)
            | (result.panAhead ? SM64_MODERN_CAMERA_CALLBACK_PANS_AHEAD : 0)
        next.reserved = 0
        output.pointee = next

        if loggedCallbackModes.insert(input.mode).inserted {
            cameraMigrationLogger.notice(
                "swift_camera_callback mode=\(input.mode) camera_yaw=\(result.cameraYaw) returned_yaw=\(result.returnedYaw) distance=\(result.distance, privacy: .public)"
            )
        }
        return SM64_MODERN_STATUS_OK
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
                || input.command == SM64_MODERN_CAMERA_COMMAND_SET_ANGLE
                || input.command == SM64_MODERN_CAMERA_COMMAND_TRANSITION_NEXT_STATE
                || input.command == SM64_MODERN_CAMERA_COMMAND_TRANSITION_TO_MODE,
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
        case SM64_MODERN_CAMERA_COMMAND_TRANSITION_NEXT_STATE:
            let transition = SM64CameraModeStateMachine.transitionNextState(
                frames: argument, state: state
            )
            state = transition.state
            result = transition.changed ? 1 : 0
        case SM64_MODERN_CAMERA_COMMAND_TRANSITION_TO_MODE:
            let transition = SM64CameraModeStateMachine.transitionToCameraMode(
                argument,
                frames: Int16(clamping: input.transition_frames_left),
                state: state
            )
            state = transition.state
            result = transition.changed ? 1 : 0
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
        if loggedCommands.insert(input.command).inserted
            || eventCount.isMultiple(of: 600) {
            cameraMigrationLogger.notice(
                "swift_camera_update command=\(input.command) argument=\(input.argument) result=\(next.result) event=\(self.eventCount) owner_token=\(self.ownerThreadToken, privacy: .public)"
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
