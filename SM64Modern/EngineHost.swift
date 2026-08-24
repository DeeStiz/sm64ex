import AppKit
import Darwin
import Foundation
import Metal
import QuartzCore
import os

private let engineLogger = Logger(subsystem: "io.github.deestiz.sm64modern", category: "EngineHost")
private let audioLogger = Logger(subsystem: "io.github.deestiz.sm64modern", category: "Audio")

private func residentMemoryBytes() -> UInt64? {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(
        MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size
    )
    let result = withUnsafeMutablePointer(to: &info) { pointer in
        pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            task_info(
                mach_task_self_,
                task_flavor_t(MACH_TASK_BASIC_INFO),
                $0,
                &count
            )
        }
    }
    guard result == KERN_SUCCESS else { return nil }
    return UInt64(info.resident_size)
}

private func engineHost(from context: UnsafeMutableRawPointer?) -> EngineHost? {
    guard let context else { return nil }
    return Unmanaged<EngineHost>.fromOpaque(context).takeUnretainedValue()
}

private func platformInitialize(
    _ context: UnsafeMutableRawPointer?,
    _ windowTitle: UnsafePointer<CChar>?
) -> SM64ModernStatus {
    guard let host = engineHost(from: context), host.isCurrentEngineThread else {
        return SM64_MODERN_STATUS_INVALID_STATE
    }
    let title = windowTitle.map(String.init(cString:)) ?? ""
    do {
        try host.initializeMetalOnEngineThread()
    } catch {
        engineLogger.error("metal_initialize_failed error=\(error.localizedDescription, privacy: .public)")
        return SM64_MODERN_STATUS_PLATFORM_ERROR
    }
    var rendering = makeMetalRenderingAPI(host: host)
    let renderingStatus = sm64_modern_install_rendering_api(&rendering)
    guard renderingStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("rendering_bridge_install_failed status=\(renderingStatus)")
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return renderingStatus
    }
    var renderingBatch = makeMetalRenderingBatchAPI(host: host)
    let renderingBatchStatus = sm64_modern_install_rendering_batch_api(&renderingBatch)
    guard renderingBatchStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("rendering_batch_bridge_install_failed status=\(renderingBatchStatus)")
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return renderingBatchStatus
    }
    engineLogger.notice("rendering_batch_bridge_installed abi=1")
    guard let inputService = host.inputServiceOnEngineThread else {
        sm64_modern_uninstall_rendering_batch_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return SM64_MODERN_STATUS_INVALID_STATE
    }
    var input = makeAppleInputAPI(service: inputService)
    let inputStatus = sm64_modern_install_input_api(&input)
    guard inputStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("input_bridge_install_failed status=\(inputStatus)")
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return inputStatus
    }
    engineLogger.notice("input_bridge_installed abi=1")
    do {
        try host.initializeFrontEndOnEngineThread()
    } catch {
        engineLogger.error("frontend_bridge_install_failed error=\(error.localizedDescription, privacy: .public)")
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_batch_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return SM64_MODERN_STATUS_PLATFORM_ERROR
    }
    do {
        try host.initializePauseMenuOnEngineThread()
    } catch {
        engineLogger.error("pause_menu_bridge_install_failed error=\(error.localizedDescription, privacy: .public)")
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_batch_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return SM64_MODERN_STATUS_PLATFORM_ERROR
    }
    let gameplayService = host.gameplayServiceOnEngineThread
    var gameplay = makeSwiftGameplayMigrationAPI(service: gameplayService)
    let gameplayStatus = sm64_modern_install_gameplay_migration_api(&gameplay)
    guard gameplayStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("gameplay_bridge_install_failed status=\(gameplayStatus)")
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return gameplayStatus
    }
    var marioGroundSpeed = makeSwiftMarioGroundSpeedAPI(service: gameplayService)
    let marioGroundSpeedStatus = sm64_modern_install_mario_ground_speed_api(&marioGroundSpeed)
    guard marioGroundSpeedStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_ground_speed_bridge_install_failed status=\(marioGroundSpeedStatus)")
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioGroundSpeedStatus
    }
    var marioAction = makeSwiftMarioActionAPI(service: gameplayService)
    let marioActionStatus = sm64_modern_install_mario_action_api(&marioAction)
    guard marioActionStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_action_bridge_install_failed status=\(marioActionStatus)")
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioActionStatus
    }
    var marioActionCancel = makeSwiftMarioActionCancelAPI(service: gameplayService)
    let marioActionCancelStatus = sm64_modern_install_mario_action_cancel_api(&marioActionCancel)
    guard marioActionCancelStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_action_cancel_bridge_install_failed status=\(marioActionCancelStatus)")
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioActionCancelStatus
    }
    var marioGroundStep = makeSwiftMarioGroundStepAPI(service: gameplayService)
    let marioGroundStepStatus = sm64_modern_install_mario_ground_step_api(&marioGroundStep)
    guard marioGroundStepStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_ground_step_bridge_install_failed status=\(marioGroundStepStatus)")
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioGroundStepStatus
    }
    var marioAirStep = makeSwiftMarioAirStepAPI(service: gameplayService)
    let marioAirStepStatus = sm64_modern_install_mario_air_step_api(&marioAirStep)
    guard marioAirStepStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_air_step_bridge_install_failed status=\(marioAirStepStatus)")
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioAirStepStatus
    }
    var marioWaterStep = makeSwiftMarioWaterStepAPI(service: gameplayService)
    let marioWaterStepStatus = sm64_modern_install_mario_water_step_api(&marioWaterStep)
    guard marioWaterStepStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_water_step_bridge_install_failed status=\(marioWaterStepStatus)")
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioWaterStepStatus
    }
    var marioBonk = makeSwiftMarioBonkAPI(service: gameplayService)
    let marioBonkStatus = sm64_modern_install_mario_bonk_api(&marioBonk)
    guard marioBonkStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_bonk_bridge_install_failed status=\(marioBonkStatus)")
        sm64_modern_uninstall_mario_water_step_api()
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioBonkStatus
    }
    var marioTerrainImpulse = makeSwiftMarioTerrainImpulseAPI(service: gameplayService)
    let marioTerrainImpulseStatus = sm64_modern_install_mario_terrain_impulse_api(&marioTerrainImpulse)
    guard marioTerrainImpulseStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_terrain_impulse_bridge_install_failed status=\(marioTerrainImpulseStatus)")
        sm64_modern_uninstall_mario_bonk_api()
        sm64_modern_uninstall_mario_water_step_api()
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioTerrainImpulseStatus
    }
    var marioQuicksand = makeSwiftMarioQuicksandAPI(service: gameplayService)
    let marioQuicksandStatus = sm64_modern_install_mario_quicksand_api(&marioQuicksand)
    guard marioQuicksandStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_quicksand_bridge_install_failed status=\(marioQuicksandStatus)")
        sm64_modern_uninstall_mario_terrain_impulse_api()
        sm64_modern_uninstall_mario_bonk_api()
        sm64_modern_uninstall_mario_water_step_api()
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioQuicksandStatus
    }
    var marioSteepPush = makeSwiftMarioSteepPushAPI(service: gameplayService)
    let marioSteepPushStatus = sm64_modern_install_mario_steep_push_api(&marioSteepPush)
    guard marioSteepPushStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_steep_push_bridge_install_failed status=\(marioSteepPushStatus)")
        sm64_modern_uninstall_mario_quicksand_api()
        sm64_modern_uninstall_mario_terrain_impulse_api()
        sm64_modern_uninstall_mario_bonk_api()
        sm64_modern_uninstall_mario_water_step_api()
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioSteepPushStatus
    }
    var marioTerrainSound = makeSwiftMarioTerrainSoundAPI(service: gameplayService)
    let marioTerrainSoundStatus = sm64_modern_install_mario_terrain_sound_api(&marioTerrainSound)
    guard marioTerrainSoundStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_terrain_sound_bridge_install_failed status=\(marioTerrainSoundStatus)")
        sm64_modern_uninstall_mario_steep_push_api()
        sm64_modern_uninstall_mario_quicksand_api()
        sm64_modern_uninstall_mario_terrain_impulse_api()
        sm64_modern_uninstall_mario_bonk_api()
        sm64_modern_uninstall_mario_water_step_api()
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioTerrainSoundStatus
    }
    var marioFloorPredicates = makeSwiftMarioFloorPredicatesAPI(service: gameplayService)
    let marioFloorPredicateStatus = sm64_modern_install_mario_floor_predicates_api(&marioFloorPredicates)
    guard marioFloorPredicateStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_floor_predicates_bridge_install_failed status=\(marioFloorPredicateStatus)")
        sm64_modern_uninstall_mario_terrain_sound_api()
        sm64_modern_uninstall_mario_steep_push_api()
        sm64_modern_uninstall_mario_quicksand_api()
        sm64_modern_uninstall_mario_terrain_impulse_api()
        sm64_modern_uninstall_mario_bonk_api()
        sm64_modern_uninstall_mario_water_step_api()
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioFloorPredicateStatus
    }
    var marioForwardVelocity = makeSwiftMarioForwardVelocityAPI(service: gameplayService)
    let marioForwardVelocityStatus = sm64_modern_install_mario_forward_velocity_api(&marioForwardVelocity)
    guard marioForwardVelocityStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_forward_velocity_bridge_install_failed status=\(marioForwardVelocityStatus)")
        sm64_modern_uninstall_mario_floor_predicates_api()
        sm64_modern_uninstall_mario_terrain_sound_api()
        sm64_modern_uninstall_mario_steep_push_api()
        sm64_modern_uninstall_mario_quicksand_api()
        sm64_modern_uninstall_mario_terrain_impulse_api()
        sm64_modern_uninstall_mario_bonk_api()
        sm64_modern_uninstall_mario_water_step_api()
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioForwardVelocityStatus
    }
    var marioVelocityDerivation = makeSwiftMarioVelocityDerivationAPI(service: gameplayService)
    let marioVelocityDerivationStatus = sm64_modern_install_mario_velocity_derivation_api(&marioVelocityDerivation)
    guard marioVelocityDerivationStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_velocity_derivation_bridge_install_failed status=\(marioVelocityDerivationStatus)")
        sm64_modern_uninstall_mario_forward_velocity_api()
        sm64_modern_uninstall_mario_floor_predicates_api()
        sm64_modern_uninstall_mario_terrain_sound_api()
        sm64_modern_uninstall_mario_steep_push_api()
        sm64_modern_uninstall_mario_quicksand_api()
        sm64_modern_uninstall_mario_terrain_impulse_api()
        sm64_modern_uninstall_mario_bonk_api()
        sm64_modern_uninstall_mario_water_step_api()
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioVelocityDerivationStatus
    }
    var marioPunch = makeSwiftMarioPunchAPI(service: gameplayService)
    let marioPunchStatus = sm64_modern_install_mario_punch_api(&marioPunch)
    guard marioPunchStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_punch_bridge_install_failed status=\(marioPunchStatus)")
        sm64_modern_uninstall_mario_velocity_derivation_api()
        sm64_modern_uninstall_mario_forward_velocity_api()
        sm64_modern_uninstall_mario_floor_predicates_api()
        sm64_modern_uninstall_mario_terrain_sound_api()
        sm64_modern_uninstall_mario_steep_push_api()
        sm64_modern_uninstall_mario_quicksand_api()
        sm64_modern_uninstall_mario_terrain_impulse_api()
        sm64_modern_uninstall_mario_bonk_api()
        sm64_modern_uninstall_mario_water_step_api()
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioPunchStatus
    }
    var marioWallResponse = makeSwiftMarioWallResponseAPI(service: gameplayService)
    let marioWallResponseStatus = sm64_modern_install_mario_wall_response_api(&marioWallResponse)
    guard marioWallResponseStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_wall_response_bridge_install_failed status=\(marioWallResponseStatus)")
        sm64_modern_uninstall_mario_punch_api()
        sm64_modern_uninstall_mario_velocity_derivation_api()
        sm64_modern_uninstall_mario_forward_velocity_api()
        sm64_modern_uninstall_mario_floor_predicates_api()
        sm64_modern_uninstall_mario_terrain_sound_api()
        sm64_modern_uninstall_mario_steep_push_api()
        sm64_modern_uninstall_mario_quicksand_api()
        sm64_modern_uninstall_mario_terrain_impulse_api()
        sm64_modern_uninstall_mario_bonk_api()
        sm64_modern_uninstall_mario_water_step_api()
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioWallResponseStatus
    }
    var marioWalkAnimation = makeSwiftMarioWalkAnimationAPI(service: gameplayService)
    let marioWalkAnimationStatus = sm64_modern_install_mario_walk_animation_api(&marioWalkAnimation)
    guard marioWalkAnimationStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_walk_animation_bridge_install_failed status=\(marioWalkAnimationStatus)")
        sm64_modern_uninstall_mario_wall_response_api()
        sm64_modern_uninstall_mario_punch_api()
        sm64_modern_uninstall_mario_velocity_derivation_api()
        sm64_modern_uninstall_mario_forward_velocity_api()
        sm64_modern_uninstall_mario_floor_predicates_api()
        sm64_modern_uninstall_mario_terrain_sound_api()
        sm64_modern_uninstall_mario_steep_push_api()
        sm64_modern_uninstall_mario_quicksand_api()
        sm64_modern_uninstall_mario_terrain_impulse_api()
        sm64_modern_uninstall_mario_bonk_api()
        sm64_modern_uninstall_mario_water_step_api()
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioWalkAnimationStatus
    }
    var marioHeldWalkAnimation = makeSwiftMarioHeldWalkAnimationAPI(service: gameplayService)
    let marioHeldWalkAnimationStatus = sm64_modern_install_mario_held_walk_animation_api(&marioHeldWalkAnimation)
    guard marioHeldWalkAnimationStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_held_walk_animation_bridge_install_failed status=\(marioHeldWalkAnimationStatus)")
        sm64_modern_uninstall_mario_walk_animation_api()
        sm64_modern_uninstall_mario_wall_response_api()
        sm64_modern_uninstall_mario_punch_api()
        sm64_modern_uninstall_mario_velocity_derivation_api()
        sm64_modern_uninstall_mario_forward_velocity_api()
        sm64_modern_uninstall_mario_floor_predicates_api()
        sm64_modern_uninstall_mario_terrain_sound_api()
        sm64_modern_uninstall_mario_steep_push_api()
        sm64_modern_uninstall_mario_quicksand_api()
        sm64_modern_uninstall_mario_terrain_impulse_api()
        sm64_modern_uninstall_mario_bonk_api()
        sm64_modern_uninstall_mario_water_step_api()
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioHeldWalkAnimationStatus
    }
    var marioSlopeAcceleration = makeSwiftMarioSlopeAccelerationAPI(service: gameplayService)
    let marioSlopeAccelerationStatus = sm64_modern_install_mario_slope_acceleration_api(&marioSlopeAcceleration)
    guard marioSlopeAccelerationStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_slope_acceleration_bridge_install_failed status=\(marioSlopeAccelerationStatus)")
        sm64_modern_uninstall_mario_held_walk_animation_api()
        sm64_modern_uninstall_mario_walk_animation_api()
        sm64_modern_uninstall_mario_wall_response_api()
        sm64_modern_uninstall_mario_punch_api()
        sm64_modern_uninstall_mario_velocity_derivation_api()
        sm64_modern_uninstall_mario_forward_velocity_api()
        sm64_modern_uninstall_mario_floor_predicates_api()
        sm64_modern_uninstall_mario_terrain_sound_api()
        sm64_modern_uninstall_mario_steep_push_api()
        sm64_modern_uninstall_mario_quicksand_api()
        sm64_modern_uninstall_mario_terrain_impulse_api()
        sm64_modern_uninstall_mario_bonk_api()
        sm64_modern_uninstall_mario_water_step_api()
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioSlopeAccelerationStatus
    }
    var marioSlopeDeceleration = makeSwiftMarioSlopeDecelerationAPI(service: gameplayService)
    let marioSlopeDecelerationStatus = sm64_modern_install_mario_slope_deceleration_api(&marioSlopeDeceleration)
    guard marioSlopeDecelerationStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_slope_deceleration_bridge_install_failed status=\(marioSlopeDecelerationStatus)")
        sm64_modern_uninstall_mario_slope_acceleration_api()
        sm64_modern_uninstall_mario_held_walk_animation_api()
        sm64_modern_uninstall_mario_walk_animation_api()
        sm64_modern_uninstall_mario_wall_response_api()
        sm64_modern_uninstall_mario_punch_api()
        sm64_modern_uninstall_mario_velocity_derivation_api()
        sm64_modern_uninstall_mario_forward_velocity_api()
        sm64_modern_uninstall_mario_floor_predicates_api()
        sm64_modern_uninstall_mario_terrain_sound_api()
        sm64_modern_uninstall_mario_steep_push_api()
        sm64_modern_uninstall_mario_quicksand_api()
        sm64_modern_uninstall_mario_terrain_impulse_api()
        sm64_modern_uninstall_mario_bonk_api()
        sm64_modern_uninstall_mario_water_step_api()
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioSlopeDecelerationStatus
    }
    var marioDeceleratingSpeed = makeSwiftMarioDeceleratingSpeedAPI(service: gameplayService)
    let marioDeceleratingSpeedStatus = sm64_modern_install_mario_decelerating_speed_api(&marioDeceleratingSpeed)
    guard marioDeceleratingSpeedStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_decelerating_speed_bridge_install_failed status=\(marioDeceleratingSpeedStatus)")
        sm64_modern_uninstall_mario_slope_deceleration_api()
        sm64_modern_uninstall_mario_slope_acceleration_api()
        sm64_modern_uninstall_mario_held_walk_animation_api()
        sm64_modern_uninstall_mario_walk_animation_api()
        sm64_modern_uninstall_mario_wall_response_api()
        sm64_modern_uninstall_mario_punch_api()
        sm64_modern_uninstall_mario_velocity_derivation_api()
        sm64_modern_uninstall_mario_forward_velocity_api()
        sm64_modern_uninstall_mario_floor_predicates_api()
        sm64_modern_uninstall_mario_terrain_sound_api()
        sm64_modern_uninstall_mario_steep_push_api()
        sm64_modern_uninstall_mario_quicksand_api()
        sm64_modern_uninstall_mario_terrain_impulse_api()
        sm64_modern_uninstall_mario_bonk_api()
        sm64_modern_uninstall_mario_water_step_api()
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioDeceleratingSpeedStatus
    }
    var marioShellSpeed = makeSwiftMarioShellSpeedAPI(service: gameplayService)
    let marioShellSpeedStatus = sm64_modern_install_mario_shell_speed_api(&marioShellSpeed)
    guard marioShellSpeedStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_shell_speed_bridge_install_failed status=\(marioShellSpeedStatus)")
        sm64_modern_uninstall_mario_decelerating_speed_api()
        sm64_modern_uninstall_mario_slope_deceleration_api()
        sm64_modern_uninstall_mario_slope_acceleration_api()
        sm64_modern_uninstall_mario_held_walk_animation_api()
        sm64_modern_uninstall_mario_walk_animation_api()
        sm64_modern_uninstall_mario_wall_response_api()
        sm64_modern_uninstall_mario_punch_api()
        sm64_modern_uninstall_mario_velocity_derivation_api()
        sm64_modern_uninstall_mario_forward_velocity_api()
        sm64_modern_uninstall_mario_floor_predicates_api()
        sm64_modern_uninstall_mario_terrain_sound_api()
        sm64_modern_uninstall_mario_steep_push_api()
        sm64_modern_uninstall_mario_quicksand_api()
        sm64_modern_uninstall_mario_terrain_impulse_api()
        sm64_modern_uninstall_mario_bonk_api()
        sm64_modern_uninstall_mario_water_step_api()
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioShellSpeedStatus
    }
    var marioLandingAcceleration = makeSwiftMarioLandingAccelerationAPI(service: gameplayService)
    let marioLandingAccelerationStatus = sm64_modern_install_mario_landing_acceleration_api(&marioLandingAcceleration)
    guard marioLandingAccelerationStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_landing_acceleration_bridge_install_failed status=\(marioLandingAccelerationStatus)")
        sm64_modern_uninstall_mario_shell_speed_api()
        sm64_modern_uninstall_mario_decelerating_speed_api()
        sm64_modern_uninstall_mario_slope_deceleration_api()
        sm64_modern_uninstall_mario_slope_acceleration_api()
        sm64_modern_uninstall_mario_held_walk_animation_api()
        sm64_modern_uninstall_mario_walk_animation_api()
        sm64_modern_uninstall_mario_wall_response_api()
        sm64_modern_uninstall_mario_punch_api()
        sm64_modern_uninstall_mario_velocity_derivation_api()
        sm64_modern_uninstall_mario_forward_velocity_api()
        sm64_modern_uninstall_mario_floor_predicates_api()
        sm64_modern_uninstall_mario_terrain_sound_api()
        sm64_modern_uninstall_mario_steep_push_api()
        sm64_modern_uninstall_mario_quicksand_api()
        sm64_modern_uninstall_mario_terrain_impulse_api()
        sm64_modern_uninstall_mario_bonk_api()
        sm64_modern_uninstall_mario_water_step_api()
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioLandingAccelerationStatus
    }
    var marioGravity = makeSwiftMarioGravityAPI(service: gameplayService)
    let marioGravityStatus = sm64_modern_install_mario_gravity_api(&marioGravity)
    guard marioGravityStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_gravity_bridge_install_failed status=\(marioGravityStatus)")
        sm64_modern_uninstall_mario_landing_acceleration_api()
        sm64_modern_uninstall_mario_shell_speed_api()
        sm64_modern_uninstall_mario_decelerating_speed_api()
        sm64_modern_uninstall_mario_slope_deceleration_api()
        sm64_modern_uninstall_mario_slope_acceleration_api()
        sm64_modern_uninstall_mario_held_walk_animation_api()
        sm64_modern_uninstall_mario_walk_animation_api()
        sm64_modern_uninstall_mario_wall_response_api()
        sm64_modern_uninstall_mario_punch_api()
        sm64_modern_uninstall_mario_velocity_derivation_api()
        sm64_modern_uninstall_mario_forward_velocity_api()
        sm64_modern_uninstall_mario_floor_predicates_api()
        sm64_modern_uninstall_mario_terrain_sound_api()
        sm64_modern_uninstall_mario_steep_push_api()
        sm64_modern_uninstall_mario_quicksand_api()
        sm64_modern_uninstall_mario_terrain_impulse_api()
        sm64_modern_uninstall_mario_bonk_api()
        sm64_modern_uninstall_mario_water_step_api()
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioGravityStatus
    }
    var marioVerticalWind = makeSwiftMarioVerticalWindAPI(service: gameplayService)
    let marioVerticalWindStatus = sm64_modern_install_mario_vertical_wind_api(&marioVerticalWind)
    guard marioVerticalWindStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_vertical_wind_bridge_install_failed status=\(marioVerticalWindStatus)")
        sm64_modern_uninstall_mario_gravity_api()
        sm64_modern_uninstall_mario_landing_acceleration_api()
        sm64_modern_uninstall_mario_shell_speed_api()
        sm64_modern_uninstall_mario_decelerating_speed_api()
        sm64_modern_uninstall_mario_slope_deceleration_api()
        sm64_modern_uninstall_mario_slope_acceleration_api()
        sm64_modern_uninstall_mario_held_walk_animation_api()
        sm64_modern_uninstall_mario_walk_animation_api()
        sm64_modern_uninstall_mario_wall_response_api()
        sm64_modern_uninstall_mario_punch_api()
        sm64_modern_uninstall_mario_velocity_derivation_api()
        sm64_modern_uninstall_mario_forward_velocity_api()
        sm64_modern_uninstall_mario_floor_predicates_api()
        sm64_modern_uninstall_mario_terrain_sound_api()
        sm64_modern_uninstall_mario_steep_push_api()
        sm64_modern_uninstall_mario_quicksand_api()
        sm64_modern_uninstall_mario_terrain_impulse_api()
        sm64_modern_uninstall_mario_bonk_api()
        sm64_modern_uninstall_mario_water_step_api()
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioVerticalWindStatus
    }
    var marioSliding = makeSwiftMarioSlidingAPI(service: gameplayService)
    let marioSlidingStatus = sm64_modern_install_mario_sliding_api(&marioSliding)
    guard marioSlidingStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_sliding_bridge_install_failed status=\(marioSlidingStatus)")
        sm64_modern_uninstall_mario_vertical_wind_api()
        sm64_modern_uninstall_mario_gravity_api()
        sm64_modern_uninstall_mario_landing_acceleration_api()
        sm64_modern_uninstall_mario_shell_speed_api()
        sm64_modern_uninstall_mario_decelerating_speed_api()
        sm64_modern_uninstall_mario_slope_deceleration_api()
        sm64_modern_uninstall_mario_slope_acceleration_api()
        sm64_modern_uninstall_mario_held_walk_animation_api()
        sm64_modern_uninstall_mario_walk_animation_api()
        sm64_modern_uninstall_mario_wall_response_api()
        sm64_modern_uninstall_mario_punch_api()
        sm64_modern_uninstall_mario_velocity_derivation_api()
        sm64_modern_uninstall_mario_forward_velocity_api()
        sm64_modern_uninstall_mario_floor_predicates_api()
        sm64_modern_uninstall_mario_terrain_sound_api()
        sm64_modern_uninstall_mario_steep_push_api()
        sm64_modern_uninstall_mario_quicksand_api()
        sm64_modern_uninstall_mario_terrain_impulse_api()
        sm64_modern_uninstall_mario_bonk_api()
        sm64_modern_uninstall_mario_water_step_api()
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioSlidingStatus
    }
    var marioGroundDivePunch = makeSwiftMarioGroundDivePunchAPI(service: gameplayService)
    let marioGroundDivePunchStatus = sm64_modern_install_mario_ground_dive_punch_api(&marioGroundDivePunch)
    guard marioGroundDivePunchStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_ground_dive_punch_bridge_install_failed status=\(marioGroundDivePunchStatus)")
        sm64_modern_uninstall_mario_sliding_api()
        sm64_modern_uninstall_mario_vertical_wind_api()
        sm64_modern_uninstall_mario_gravity_api()
        sm64_modern_uninstall_mario_landing_acceleration_api()
        sm64_modern_uninstall_mario_shell_speed_api()
        sm64_modern_uninstall_mario_decelerating_speed_api()
        sm64_modern_uninstall_mario_slope_deceleration_api()
        sm64_modern_uninstall_mario_slope_acceleration_api()
        sm64_modern_uninstall_mario_held_walk_animation_api()
        sm64_modern_uninstall_mario_walk_animation_api()
        sm64_modern_uninstall_mario_wall_response_api()
        sm64_modern_uninstall_mario_punch_api()
        sm64_modern_uninstall_mario_velocity_derivation_api()
        sm64_modern_uninstall_mario_forward_velocity_api()
        sm64_modern_uninstall_mario_floor_predicates_api()
        sm64_modern_uninstall_mario_terrain_sound_api()
        sm64_modern_uninstall_mario_steep_push_api()
        sm64_modern_uninstall_mario_quicksand_api()
        sm64_modern_uninstall_mario_terrain_impulse_api()
        sm64_modern_uninstall_mario_bonk_api()
        sm64_modern_uninstall_mario_water_step_api()
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioGroundDivePunchStatus
    }
    var marioSlidePredicates = makeSwiftMarioSlidePredicatesAPI(service: gameplayService)
    let marioSlidePredicatesStatus = sm64_modern_install_mario_slide_predicates_api(&marioSlidePredicates)
    guard marioSlidePredicatesStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_slide_predicates_bridge_install_failed status=\(marioSlidePredicatesStatus)")
        sm64_modern_uninstall_mario_ground_dive_punch_api()
        sm64_modern_uninstall_mario_sliding_api()
        sm64_modern_uninstall_mario_vertical_wind_api()
        sm64_modern_uninstall_mario_gravity_api()
        sm64_modern_uninstall_mario_landing_acceleration_api()
        sm64_modern_uninstall_mario_shell_speed_api()
        sm64_modern_uninstall_mario_decelerating_speed_api()
        sm64_modern_uninstall_mario_slope_deceleration_api()
        sm64_modern_uninstall_mario_slope_acceleration_api()
        sm64_modern_uninstall_mario_held_walk_animation_api()
        sm64_modern_uninstall_mario_walk_animation_api()
        sm64_modern_uninstall_mario_wall_response_api()
        sm64_modern_uninstall_mario_punch_api()
        sm64_modern_uninstall_mario_velocity_derivation_api()
        sm64_modern_uninstall_mario_forward_velocity_api()
        sm64_modern_uninstall_mario_floor_predicates_api()
        sm64_modern_uninstall_mario_terrain_sound_api()
        sm64_modern_uninstall_mario_steep_push_api()
        sm64_modern_uninstall_mario_quicksand_api()
        sm64_modern_uninstall_mario_terrain_impulse_api()
        sm64_modern_uninstall_mario_bonk_api()
        sm64_modern_uninstall_mario_water_step_api()
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioSlidePredicatesStatus
    }
    var marioBeginBraking = makeSwiftMarioBeginBrakingAPI(service: gameplayService)
    let marioBeginBrakingStatus = sm64_modern_install_mario_begin_braking_api(&marioBeginBraking)
    guard marioBeginBrakingStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_begin_braking_bridge_install_failed status=\(marioBeginBrakingStatus)")
        sm64_modern_uninstall_mario_slide_predicates_api()
        sm64_modern_uninstall_mario_ground_dive_punch_api()
        sm64_modern_uninstall_mario_sliding_api()
        sm64_modern_uninstall_mario_vertical_wind_api()
        sm64_modern_uninstall_mario_gravity_api()
        sm64_modern_uninstall_mario_landing_acceleration_api()
        sm64_modern_uninstall_mario_shell_speed_api()
        sm64_modern_uninstall_mario_decelerating_speed_api()
        sm64_modern_uninstall_mario_slope_deceleration_api()
        sm64_modern_uninstall_mario_slope_acceleration_api()
        sm64_modern_uninstall_mario_held_walk_animation_api()
        sm64_modern_uninstall_mario_walk_animation_api()
        sm64_modern_uninstall_mario_wall_response_api()
        sm64_modern_uninstall_mario_punch_api()
        sm64_modern_uninstall_mario_velocity_derivation_api()
        sm64_modern_uninstall_mario_forward_velocity_api()
        sm64_modern_uninstall_mario_floor_predicates_api()
        sm64_modern_uninstall_mario_terrain_sound_api()
        sm64_modern_uninstall_mario_steep_push_api()
        sm64_modern_uninstall_mario_quicksand_api()
        sm64_modern_uninstall_mario_terrain_impulse_api()
        sm64_modern_uninstall_mario_bonk_api()
        sm64_modern_uninstall_mario_water_step_api()
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioBeginBrakingStatus
    }
    var marioTripleJumpSelector = makeSwiftMarioTripleJumpSelectorAPI(service: gameplayService)
    let marioTripleJumpSelectorStatus = sm64_modern_install_mario_triple_jump_selector_api(&marioTripleJumpSelector)
    guard marioTripleJumpSelectorStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_triple_jump_selector_bridge_install_failed status=\(marioTripleJumpSelectorStatus)")
        sm64_modern_uninstall_mario_begin_braking_api()
        sm64_modern_uninstall_mario_slide_predicates_api()
        sm64_modern_uninstall_mario_ground_dive_punch_api()
        sm64_modern_uninstall_mario_sliding_api()
        sm64_modern_uninstall_mario_vertical_wind_api()
        sm64_modern_uninstall_mario_gravity_api()
        sm64_modern_uninstall_mario_landing_acceleration_api()
        sm64_modern_uninstall_mario_shell_speed_api()
        sm64_modern_uninstall_mario_decelerating_speed_api()
        sm64_modern_uninstall_mario_slope_deceleration_api()
        sm64_modern_uninstall_mario_slope_acceleration_api()
        sm64_modern_uninstall_mario_held_walk_animation_api()
        sm64_modern_uninstall_mario_walk_animation_api()
        sm64_modern_uninstall_mario_wall_response_api()
        sm64_modern_uninstall_mario_punch_api()
        sm64_modern_uninstall_mario_velocity_derivation_api()
        sm64_modern_uninstall_mario_forward_velocity_api()
        sm64_modern_uninstall_mario_floor_predicates_api()
        sm64_modern_uninstall_mario_terrain_sound_api()
        sm64_modern_uninstall_mario_steep_push_api()
        sm64_modern_uninstall_mario_quicksand_api()
        sm64_modern_uninstall_mario_terrain_impulse_api()
        sm64_modern_uninstall_mario_bonk_api()
        sm64_modern_uninstall_mario_water_step_api()
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioTripleJumpSelectorStatus
    }
    var marioYVelocity = makeSwiftMarioYVelocityAPI(service: gameplayService)
    let marioYVelocityStatus = sm64_modern_install_mario_y_velocity_api(&marioYVelocity)
    guard marioYVelocityStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_y_velocity_bridge_install_failed status=\(marioYVelocityStatus)")
        sm64_modern_uninstall_mario_triple_jump_selector_api()
        sm64_modern_uninstall_mario_begin_braking_api()
        sm64_modern_uninstall_mario_slide_predicates_api()
        sm64_modern_uninstall_mario_ground_dive_punch_api()
        sm64_modern_uninstall_mario_sliding_api()
        sm64_modern_uninstall_mario_vertical_wind_api()
        sm64_modern_uninstall_mario_gravity_api()
        sm64_modern_uninstall_mario_landing_acceleration_api()
        sm64_modern_uninstall_mario_shell_speed_api()
        sm64_modern_uninstall_mario_decelerating_speed_api()
        sm64_modern_uninstall_mario_slope_deceleration_api()
        sm64_modern_uninstall_mario_slope_acceleration_api()
        sm64_modern_uninstall_mario_held_walk_animation_api()
        sm64_modern_uninstall_mario_walk_animation_api()
        sm64_modern_uninstall_mario_wall_response_api()
        sm64_modern_uninstall_mario_punch_api()
        sm64_modern_uninstall_mario_velocity_derivation_api()
        sm64_modern_uninstall_mario_forward_velocity_api()
        sm64_modern_uninstall_mario_floor_predicates_api()
        sm64_modern_uninstall_mario_terrain_sound_api()
        sm64_modern_uninstall_mario_steep_push_api()
        sm64_modern_uninstall_mario_quicksand_api()
        sm64_modern_uninstall_mario_terrain_impulse_api()
        sm64_modern_uninstall_mario_bonk_api()
        sm64_modern_uninstall_mario_water_step_api()
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioYVelocityStatus
    }
    var marioSteepJump = makeSwiftMarioSteepJumpAPI(service: gameplayService)
    let marioSteepJumpStatus = sm64_modern_install_mario_steep_jump_api(&marioSteepJump)
    guard marioSteepJumpStatus == SM64_MODERN_STATUS_OK else {
        engineLogger.error("mario_steep_jump_bridge_install_failed status=\(marioSteepJumpStatus)")
        sm64_modern_uninstall_mario_y_velocity_api()
        sm64_modern_uninstall_mario_triple_jump_selector_api()
        sm64_modern_uninstall_mario_begin_braking_api()
        sm64_modern_uninstall_mario_slide_predicates_api()
        sm64_modern_uninstall_mario_ground_dive_punch_api()
        sm64_modern_uninstall_mario_sliding_api()
        sm64_modern_uninstall_mario_vertical_wind_api()
        sm64_modern_uninstall_mario_gravity_api()
        sm64_modern_uninstall_mario_landing_acceleration_api()
        sm64_modern_uninstall_mario_shell_speed_api()
        sm64_modern_uninstall_mario_decelerating_speed_api()
        sm64_modern_uninstall_mario_slope_deceleration_api()
        sm64_modern_uninstall_mario_slope_acceleration_api()
        sm64_modern_uninstall_mario_held_walk_animation_api()
        sm64_modern_uninstall_mario_walk_animation_api()
        sm64_modern_uninstall_mario_wall_response_api()
        sm64_modern_uninstall_mario_punch_api()
        sm64_modern_uninstall_mario_velocity_derivation_api()
        sm64_modern_uninstall_mario_forward_velocity_api()
        sm64_modern_uninstall_mario_floor_predicates_api()
        sm64_modern_uninstall_mario_terrain_sound_api()
        sm64_modern_uninstall_mario_steep_push_api()
        sm64_modern_uninstall_mario_quicksand_api()
        sm64_modern_uninstall_mario_terrain_impulse_api()
        sm64_modern_uninstall_mario_bonk_api()
        sm64_modern_uninstall_mario_water_step_api()
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return marioSteepJumpStatus
    }
    engineLogger.notice("gameplay_bridge_installed abi=1 slices=mario_buttons,mario_ground_speed,mario_action,mario_action_cancel,mario_ground_step,mario_air_step,mario_water_step,mario_bonk,mario_terrain_impulse,mario_quicksand,mario_steep_push,mario_terrain_sound,mario_floor_predicates,mario_forward_velocity,mario_velocity_derivation,mario_punch,mario_wall_response,mario_walk_animation,mario_held_walk_animation,mario_slope_acceleration,mario_slope_deceleration,mario_decelerating_speed,mario_shell_speed,mario_landing_acceleration,mario_gravity,mario_vertical_wind,mario_sliding,mario_ground_dive_punch,mario_slide_predicates,mario_begin_braking,mario_triple_jump_selector,mario_y_velocity,mario_steep_jump,bobomb_release")
    do {
        try host.initializeAudioOnEngineThread()
    } catch {
        audioLogger.error("audio_initialize_failed error=\(error.localizedDescription, privacy: .public)")
        sm64_modern_uninstall_mario_steep_jump_api()
        sm64_modern_uninstall_mario_y_velocity_api()
        sm64_modern_uninstall_mario_triple_jump_selector_api()
        sm64_modern_uninstall_mario_begin_braking_api()
        sm64_modern_uninstall_mario_slide_predicates_api()
        sm64_modern_uninstall_mario_ground_dive_punch_api()
        sm64_modern_uninstall_mario_sliding_api()
        sm64_modern_uninstall_mario_vertical_wind_api()
        sm64_modern_uninstall_mario_gravity_api()
        sm64_modern_uninstall_mario_landing_acceleration_api()
        sm64_modern_uninstall_mario_shell_speed_api()
        sm64_modern_uninstall_mario_decelerating_speed_api()
        sm64_modern_uninstall_mario_slope_deceleration_api()
        sm64_modern_uninstall_mario_slope_acceleration_api()
        sm64_modern_uninstall_mario_held_walk_animation_api()
        sm64_modern_uninstall_mario_walk_animation_api()
        sm64_modern_uninstall_mario_wall_response_api()
        sm64_modern_uninstall_mario_punch_api()
        sm64_modern_uninstall_mario_velocity_derivation_api()
        sm64_modern_uninstall_mario_forward_velocity_api()
        sm64_modern_uninstall_mario_floor_predicates_api()
        sm64_modern_uninstall_mario_terrain_sound_api()
        sm64_modern_uninstall_mario_steep_push_api()
        sm64_modern_uninstall_mario_quicksand_api()
        sm64_modern_uninstall_mario_terrain_impulse_api()
        sm64_modern_uninstall_mario_bonk_api()
        sm64_modern_uninstall_mario_water_step_api()
        sm64_modern_uninstall_mario_air_step_api()
        sm64_modern_uninstall_mario_ground_step_api()
        sm64_modern_uninstall_mario_action_cancel_api()
        sm64_modern_uninstall_mario_action_api()
        sm64_modern_uninstall_mario_ground_speed_api()
        sm64_modern_uninstall_gameplay_migration_api()
        sm64_modern_uninstall_pause_menu_migration_api()
        host.discardPauseMenuMigrationOnEngineThread()
        sm64_modern_uninstall_frontend_migration_api()
        host.discardFrontEndMigrationOnEngineThread()
        sm64_modern_uninstall_input_api()
        sm64_modern_uninstall_rendering_api()
        do { try host.shutdownMetalOnEngineThread() } catch {
            engineLogger.fault("metal_rollback_failed error=\(error.localizedDescription, privacy: .public)")
        }
        return SM64_MODERN_STATUS_PLATFORM_ERROR
    }
    engineLogger.notice("platform_initialized title=\(title, privacy: .public)")
    return SM64_MODERN_STATUS_OK
}

private func platformShutdown(_ context: UnsafeMutableRawPointer?) {
    guard let host = engineHost(from: context) else { return }
    assert(host.isCurrentEngineThread)
    host.shutdownAudioOnEngineThread()
    _ = sm64_modern_camera_set_authority(0)
    sm64_modern_uninstall_camera_migration_api()
    _ = sm64_modern_progression_set_persistence_authority(0)
    sm64_modern_uninstall_progression_migration_api()
    sm64_modern_uninstall_mario_steep_jump_api()
    sm64_modern_uninstall_mario_y_velocity_api()
    sm64_modern_uninstall_mario_triple_jump_selector_api()
    sm64_modern_uninstall_mario_begin_braking_api()
    sm64_modern_uninstall_mario_slide_predicates_api()
    sm64_modern_uninstall_mario_ground_dive_punch_api()
    sm64_modern_uninstall_mario_sliding_api()
    sm64_modern_uninstall_mario_vertical_wind_api()
    sm64_modern_uninstall_mario_gravity_api()
    sm64_modern_uninstall_mario_landing_acceleration_api()
    sm64_modern_uninstall_mario_shell_speed_api()
    sm64_modern_uninstall_mario_decelerating_speed_api()
    sm64_modern_uninstall_mario_slope_deceleration_api()
    sm64_modern_uninstall_mario_slope_acceleration_api()
    sm64_modern_uninstall_mario_held_walk_animation_api()
    sm64_modern_uninstall_mario_walk_animation_api()
    sm64_modern_uninstall_mario_wall_response_api()
    sm64_modern_uninstall_mario_punch_api()
    sm64_modern_uninstall_mario_velocity_derivation_api()
    sm64_modern_uninstall_mario_forward_velocity_api()
    sm64_modern_uninstall_mario_floor_predicates_api()
    sm64_modern_uninstall_mario_terrain_sound_api()
    sm64_modern_uninstall_mario_steep_push_api()
    sm64_modern_uninstall_mario_quicksand_api()
    sm64_modern_uninstall_mario_terrain_impulse_api()
    sm64_modern_uninstall_mario_bonk_api()
    sm64_modern_uninstall_mario_water_step_api()
    sm64_modern_uninstall_mario_air_step_api()
    sm64_modern_uninstall_mario_ground_step_api()
    sm64_modern_uninstall_mario_action_cancel_api()
    sm64_modern_uninstall_mario_action_api()
    sm64_modern_uninstall_gameplay_migration_api()
    host.shutdownPauseMenuOnEngineThread()
    host.shutdownFrontEndOnEngineThread()
    sm64_modern_uninstall_input_api()
    sm64_modern_uninstall_rendering_api()
    engineLogger.notice("platform_shutdown")
}

private func platformAudioBuffered(_ context: UnsafeMutableRawPointer?) -> Int32 {
    guard let host = engineHost(from: context), host.isCurrentEngineThread else { return 0 }
    return host.audioBufferedFrames()
}

private func platformAudioDesiredBuffered(_ context: UnsafeMutableRawPointer?) -> UInt32 {
    guard let host = engineHost(from: context), host.isCurrentEngineThread else { return 0 }
    return host.audioDesiredBufferedFrames()
}

private func platformAudioPlay(
    _ context: UnsafeMutableRawPointer?,
    _ samples: UnsafePointer<Int16>?,
    _ frameCount: UInt32
) {
    guard let host = engineHost(from: context), host.isCurrentEngineThread else { return }
    guard let samples else {
        precondition(frameCount == 0, "Non-empty audio packets require sample storage")
        return
    }
    host.audioPlay(samples: samples, frameCount: frameCount)
}

private func platformCurrentThread(_ context: UnsafeMutableRawPointer?) -> UInt64 {
    var identifier: UInt64 = 0
    let result = pthread_threadid_np(nil, &identifier)
    precondition(result == 0, "pthread_threadid_np must produce an owner token")
    return identifier
}

private func platformExitRequested(
    _ context: UnsafeMutableRawPointer?,
    _ reason: SM64ModernExitReason
) {
    guard let host = engineHost(from: context) else { return }
    host.recordCoreExit(reason: reason)
}

private func platformError(
    _ context: UnsafeMutableRawPointer?,
    _ status: SM64ModernStatus,
    _ message: UnsafePointer<CChar>?
) {
    let text = message.map(String.init(cString:)) ?? "Unknown core error"
    engineLogger.error("core_error status=\(status) message=\(text, privacy: .public)")
}

/// Host facade with explicit owner-thread engine state. AppKit lifecycle work
/// is routed through value messages/main-actor closures, while C callbacks
/// recover this object only through the narrow unmanaged ABI leaf.
final class EngineHost {
    private struct MetalConfiguration {
        let device: any MTLDevice
        let layer: CAMetalLayer
        let drawableSize: CGSize
    }

    private struct DrawableResizeCandidate {
        let requestID: UInt64
        let size: CGSize
    }

    private struct M9ProfileConfiguration {
        let targetSteps: UInt64
        let warmupSteps: UInt64

        static func fromEnvironment() -> M9ProfileConfiguration? {
            let environment = ProcessInfo.processInfo.environment
            guard let rawTarget = environment["SM64_MODERN_M9_PROFILE_TICKS"],
                  let targetSteps = UInt64(rawTarget),
                  targetSteps > 0 else {
                return nil
            }
            let defaultWarmup = min(UInt64(600), targetSteps > 1 ? targetSteps - 1 : 0)
            let requestedWarmup = UInt64(environment["SM64_MODERN_M9_PROFILE_WARMUP_TICKS"] ?? "")
                ?? defaultWarmup
            return M9ProfileConfiguration(
                targetSteps: targetSteps,
                warmupSteps: min(requestedWarmup, targetSteps > 1 ? targetSteps - 1 : 0)
            )
        }
    }

    private enum State {
        case idle
        case starting
        case running
        case stopped
        case failed
    }

    private let engineAuthority: SM64ModernEngineAuthority
    private let condition = NSCondition()
    private var state: State = .idle
    private var stopRequested = false
    private var requestedExitReason = SM64_MODERN_EXIT_USER_REQUESTED
    private var engineThreadIdentifier: UInt64 = 0
    private var stepCount: UInt64 = 0
    private var engineRunStatus = SM64_MODERN_STATUS_OK
    private var lifecycle = SM64ModernLifecycleApiV1()
    private var timebaseSnapshot = SM64ModernTimebaseSnapshotV1()
    private var parityCoordinator: GameplayParityCoordinator?
    private var oracleTraceSession: SM64ModernOracleTraceSession?
    private var progressionMigrationService: SwiftProgressionMigrationService?
    private var cameraMigrationService: SwiftCameraMigrationService?
    private var globalStateMigrationService: SwiftGlobalStateMigrationService?
    private let gameplayService = SwiftGameplayService()
    private var automaticTerminationRequested = false
    private var inputService: AppleInputService?
    private var audioService: SM64ModernAppleAudioService?
    private var audioMigrationService: SwiftAudioMigrationService?
    private var audioPCMReceiptService: SwiftAudioPCMReceiptService?
    private var effectsMigrationService: SwiftEffectsMigrationService?
    private var frontendMigrationService: SwiftFrontEndMigrationService?
    private var pauseMenuMigrationService: SwiftPauseMenuMigrationService?
    private var audioPromotion: SM64AudioOwnerPromotion?
    private var loggedAudioEnqueue = false
    private var loggedAudioRender = false
    private var metalConfiguration: MetalConfiguration?
    private var metalRenderer: MetalRenderer?
    private var marioFacePayloadBundle: SM64MarioFacePayloadBundle?
    private var marioFaceCompositionSource: String = "fallback"
    private var pendingDrawableSize: CGSize?
    private var pendingDrawableRequestID: UInt64 = 0
    private var nextDrawableRequestID: UInt64 = 1
    private var pendingPresentationPause: Bool?
    private var presentationPaused = false
    private var presentationResumeGeneration: UInt64 = 0
    private var presentationResumeBaselineSize: CGSize?
    private var awaitingPostResumeResizeAcknowledgement = false
    private var postResumeResizeCandidate: DrawableResizeCandidate?
    private var presentedPostResumeResizeCandidate: DrawableResizeCandidate?
    private var postResumeWarmupTicks: UInt64 = 0
    private var lastOwnerAppliedDrawableRequestID: UInt64 = 0
    private var pendingDrawableAgeRequestID: UInt64 = 0
    private var pendingDrawableAgeTicks: UInt64 = 0
    private var applyingPendingDrawableSizeAtEngineBoundary = false
    private var engineRunLoop: CFRunLoop?
    private var schedulerWakeCount: UInt64 = 0
    private var schedulerLateWakeCount: UInt64 = 0
    private var schedulerCatchUpSteps: UInt64 = 0
    private var schedulerDroppedSteps: UInt64 = 0
    private var schedulerMaximumLatenessNanoseconds: UInt64 = 0
    private let m9ProfileConfiguration = M9ProfileConfiguration.fromEnvironment()
    private var m9ProfileBaselineStep: UInt64?
    private var m9ProfileStartNanoseconds: UInt64?
    private var m9ProfileStartRSSBytes: UInt64?
    private var m9ProfileStartAudioRendered: UInt64 = 0
    private var m9ProfileStartAudioUnderrun: UInt64 = 0
    private var m9ProfileStartAudioDropped: UInt64 = 0
    private var m9ProfileComplete = false
    private var engineRuntime: SM64ModernEngineRuntime?

    init(authority: SM64ModernEngineAuthority = .swift) {
        self.engineAuthority = authority
    }

    var isCurrentEngineThread: Bool {
        condition.withLock {
            engineThreadIdentifier != 0 && engineThreadIdentifier == Self.currentThreadIdentifier()
        }
    }

    func configureMetal(device: any MTLDevice, layer: CAMetalLayer, drawableSize: CGSize) {
        precondition(Thread.isMainThread, "AppKit must configure the Metal surface")
        condition.withLock {
            precondition(state == .idle, "Metal must be configured before EngineHost.start")
            metalConfiguration = MetalConfiguration(device: device, layer: layer, drawableSize: drawableSize)
        }
    }

    func configureInput(_ service: AppleInputService) {
        precondition(Thread.isMainThread, "AppKit must configure input")
        condition.withLock {
            precondition(state == .idle, "Input must be configured before EngineHost.start")
            inputService = service
        }
    }

    func requestDrawableSize(_ size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let runLoop = condition.withLock { () -> CFRunLoop? in
            pendingDrawableSize = size
            pendingDrawableRequestID = nextDrawableRequestID
            nextDrawableRequestID &+= 1
            return engineRunLoop
        }
        if let runLoop {
            CFRunLoopWakeUp(runLoop)
        }
    }

    /// Publish a main-actor pause request without touching CAMetalDisplayLink
    /// from AppKit.  The owner thread consumes the value at a simulation
    /// boundary, preserving the same thread/lifetime contract as resize.
    func requestPresentationPaused(_ paused: Bool) {
        precondition(Thread.isMainThread, "AppKit owns presentation pause requests")
        let runLoop = condition.withLock { () -> CFRunLoop? in
            pendingPresentationPause = paused
            return engineRunLoop
        }
        if let runLoop {
            CFRunLoopWakeUp(runLoop)
        }
    }

    func start() {
        condition.lock()
        precondition(state == .idle, "EngineHost.start must be called exactly once")
        state = .starting
        condition.unlock()

        // Capture only the integer address in the Thread @Sendable closure;
        // pointer recovery is the explicit owner-thread ABI leaf.
        let contextAddress = UInt(bitPattern: Unmanaged.passUnretained(self).toOpaque())
        let thread = Thread {
            guard let context = UnsafeMutableRawPointer(bitPattern: contextAddress) else {
                preconditionFailure("EngineHost thread context must be non-nil")
            }
            Unmanaged<EngineHost>.fromOpaque(context)
                .takeUnretainedValue()
                .runEngineThread()
        }
        thread.name = "SM64 Modern Engine"
        thread.qualityOfService = .userInteractive
        thread.start()
    }

    func requestStopAndWait(reason: SM64ModernExitReason) {
        precondition(Thread.isMainThread, "AppKit owns the synchronous shutdown request")

        condition.lock()
        if state == .idle || state == .stopped || state == .failed {
            condition.unlock()
            return
        }
        stopRequested = true
        requestedExitReason = reason
        let runLoop = engineRunLoop
        condition.broadcast()
        if let runLoop {
            CFRunLoopStop(runLoop)
            CFRunLoopWakeUp(runLoop)
        }
        while state != .stopped && state != .failed {
            condition.wait()
        }
        condition.unlock()
    }

    func recordCoreExit(reason: SM64ModernExitReason) {
        assert(isCurrentEngineThread)
        condition.withLock {
            requestedExitReason = reason
        }
    }

    private func runEngineThread() {
        let identifier = Self.currentThreadIdentifier()
        condition.withLock {
            engineThreadIdentifier = identifier
            engineRunLoop = CFRunLoopGetCurrent()
        }
        engineLogger.notice("engine_thread_started token=\(identifier) main=\(Thread.isMainThread)")

        let runtime = makeEngineRuntime()
        engineRuntime = runtime
        engineLogger.notice(
            "engine_runtime_selected authority=\(runtime.authority.rawValue, privacy: .public) implementation=\(runtime.implementation, privacy: .public)"
        )

        let initializeStatus = runtime.initialize()
        guard initializeStatus == SM64_MODERN_STATUS_OK else {
            sm64_modern_uninstall_effects_migration_api()
            effectsMigrationService = nil
            sm64_modern_uninstall_global_state_migration_api()
            globalStateMigrationService = nil
            _ = sm64_modern_camera_set_authority(0)
            sm64_modern_uninstall_camera_migration_api()
            cameraMigrationService = nil
            _ = sm64_modern_progression_set_persistence_authority(0)
            sm64_modern_uninstall_progression_migration_api()
            progressionMigrationService = nil
            sm64_modern_uninstall_frontend_migration_api()
            frontendMigrationService = nil
            finish(state: .failed, status: initializeStatus)
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
            return
        }

        condition.withLock {
            state = .running
            condition.broadcast()
        }
        engineLogger.notice(
            "lifecycle_running cadence_hz=\(self.timebaseSnapshot.simulation_rate_numerator)/\(self.timebaseSnapshot.simulation_rate_denominator) capabilities=rendering,input,audio legacy_hz=\(self.timebaseSnapshot.legacy_rate_numerator)/\(self.timebaseSnapshot.legacy_rate_denominator) paired_ticks=\(self.timebaseSnapshot.simulation_ticks_per_legacy_tick)"
        )

        engineRunStatus = SM64_MODERN_STATUS_OK
        runFixedStepLoop()

        if engineRunStatus == SM64_MODERN_STATUS_OK && condition.withLock({ stopRequested }) {
            let reason = condition.withLock { requestedExitReason }
            engineRunStatus = runtime.requestStop(reason: reason)
        }

        if engineRunStatus != SM64_MODERN_STATUS_OK && engineRunStatus != SM64_MODERN_STATUS_STOP_REQUESTED {
            engineLogger.error("lifecycle_step_failed status=\(self.engineRunStatus)")
        }

        let parityStatus = parityCoordinator?.endAndReport() ?? SM64_MODERN_STATUS_OK
        parityCoordinator = nil
        let oracleTraceStatus = oracleTraceSession?.end() ?? SM64_MODERN_STATUS_OK
        oracleTraceSession = nil
        let shutdownStatus = runtime.shutdown()
        let effectsService = effectsMigrationService
        effectsMigrationService = nil
        sm64_modern_uninstall_effects_migration_api()
        if let effectsService {
            let summary = effectsService.summary()
            let lastTick = summary.lastTick.map(String.init) ?? "none"
            engineLogger.notice(
                "swift_effects_receipt_observer_finished receipts=\(summary.receipts, privacy: .public) records=\(summary.records, privacy: .public) last_tick=\(lastTick, privacy: .public)"
            )
        }
        let globalStateService = globalStateMigrationService
        globalStateMigrationService = nil
        sm64_modern_uninstall_global_state_migration_api()
        if let globalStateService {
            let summary = globalStateService.summary()
            let lastTick = summary.lastTick.map(String.init) ?? "none"
            engineLogger.notice(
                "swift_global_state_observer_finished snapshots=\(summary.snapshots, privacy: .public) records=\(summary.records, privacy: .public) last_tick=\(lastTick, privacy: .public)"
            )
        }
        cameraMigrationService = nil
        progressionMigrationService = nil
        engineRuntime = nil
        let executionStatus = engineRunStatus != SM64_MODERN_STATUS_OK
            && engineRunStatus != SM64_MODERN_STATUS_STOP_REQUESTED
            ? engineRunStatus : SM64_MODERN_STATUS_OK
        let finalStatus = shutdownStatus != SM64_MODERN_STATUS_OK
            ? shutdownStatus
            : (executionStatus != SM64_MODERN_STATUS_OK
                ? executionStatus
                : (parityStatus != SM64_MODERN_STATUS_OK ? parityStatus : oracleTraceStatus))
        let finalState: State = finalStatus == SM64_MODERN_STATUS_OK ? .stopped : .failed
        finish(state: finalState, status: finalStatus)

        if automaticTerminationRequested || !condition.withLock({ stopRequested }) {
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private func runFixedStepLoop() {
        precondition(isCurrentEngineThread)
        var scheduler = RationalFixedStepScheduler(
            rateNumerator: timebaseSnapshot.simulation_rate_numerator,
            rateDenominator: timebaseSnapshot.simulation_rate_denominator,
            maxCatchUpSteps: timebaseSnapshot.max_catch_up_steps
        )
        scheduler.start(atNanoseconds: MonotonicClock.nowNanoseconds())
        engineLogger.notice(
            "fixed_step_scheduler_started clock=monotonic_raw max_catch_up=\(self.timebaseSnapshot.max_catch_up_steps)"
        )
        if let m9ProfileConfiguration {
            engineLogger.notice(
                "m9_profile_armed target_steps=\(m9ProfileConfiguration.targetSteps, privacy: .public) warmup_steps=\(m9ProfileConfiguration.warmupSteps, privacy: .public)"
            )
        }

        while engineRunStatus == SM64_MODERN_STATUS_OK,
              !condition.withLock({ stopRequested }) {
            let plan = scheduler.plan(atNanoseconds: MonotonicClock.nowNanoseconds())
            schedulerWakeCount += 1
            if plan.latenessNanoseconds >= 1_000_000 {
                schedulerLateWakeCount += 1
            }
            if plan.dueSteps > 1 {
                schedulerCatchUpSteps += UInt64(plan.dueSteps - 1)
            }
            schedulerDroppedSteps += plan.droppedSteps
            schedulerMaximumLatenessNanoseconds = max(
                schedulerMaximumLatenessNanoseconds,
                plan.latenessNanoseconds
            )

            if plan.dueSteps == 0 {
                let waitSeconds = min(Double(plan.waitNanoseconds) / 1_000_000_000, 1.0)
                _ = CFRunLoopRunInMode(.defaultMode, waitSeconds, true)
                continue
            }

            for _ in 0..<plan.dueSteps {
                stepCoreOnEngineThread()
                if engineRunStatus != SM64_MODERN_STATUS_OK
                    || condition.withLock({ stopRequested }) {
                    break
                }
            }
            if stepCount == 1 || stepCount.isMultiple(of: 300) {
                logSchedulerStatus()
            }
        }
        logSchedulerStatus(event: "fixed_step_scheduler_finished")
    }

    private func logSchedulerStatus(event: String = "fixed_step_scheduler_status") {
        engineLogger.notice(
            "\(event, privacy: .public) step=\(self.stepCount) wakes=\(self.schedulerWakeCount) late_wakes=\(self.schedulerLateWakeCount) catch_up_steps=\(self.schedulerCatchUpSteps) dropped_steps=\(self.schedulerDroppedSteps) max_late_ns=\(self.schedulerMaximumLatenessNanoseconds)"
        )
    }

    private func stepCoreOnEngineThread() {
        precondition(isCurrentEngineThread)
        if condition.withLock({ stopRequested }) {
            CFRunLoopStop(CFRunLoopGetCurrent())
            return
        }

        do {
            let recoveryWasPending = audioService?.recoveryPending() ?? false
            try audioService?.recoverIfNeeded()
            if recoveryWasPending, let status = audioService?.audioStatus() {
                audioLogger.notice(
                    "audio_route_recovered output_hz=\(status.output_sample_rate, privacy: .public) output_channels=\(status.output_channel_count, privacy: .public)"
                )
            }
        } catch {
            audioLogger.error("audio_recovery_failed error=\(error.localizedDescription, privacy: .public)")
            engineRunStatus = SM64_MODERN_STATUS_PLATFORM_ERROR
            CFRunLoopStop(CFRunLoopGetCurrent())
            return
        }

        // Recover and discard stale route data before the core asks how much
        // PCM is buffered, so this tick immediately refills the restarted graph.
        engineRunStatus = engineRuntime?.step() ?? SM64_MODERN_STATUS_INVALID_STATE
        guard engineRunStatus == SM64_MODERN_STATUS_OK else {
            CFRunLoopStop(CFRunLoopGetCurrent())
            return
        }

        if let pause = consumePresentationPauseOnEngineThread() {
            applyPresentationPauseOnEngineThread(pause)
        }
        // A paused or headless display link cannot consume its callback-owned
        // resize mailbox. Apply that fallback on the engine owner only when
        // paused or after a short bounded age; a normal unpaused request stays
        // queued for Metal's callback, which gives the stress gate a real
        // post-present acknowledgement rather than a layer-only mutation.
        let shouldDrainPendingSize = shouldDrainPendingDrawableSizeAtEngineBoundary()
        if presentationPaused || shouldDrainPendingSize {
            drainPendingDrawableSizeAtEngineBoundary()
        }
        if !presentationPaused, awaitingPostResumeResizeAcknowledgement {
            postResumeWarmupTicks &+= 1
            acknowledgePostResumeResizeIfWarmed()
        }
        stepCount += 1
        updateMarioFaceTransformOnEngineThread()
        if var promotion = audioPromotion {
            let receipt = promotion.tick(
                ownerToken: engineThreadIdentifier,
                simulationTick: stepCount
            )
            audioPromotion = promotion
            if receipt.admissionFailed {
                audioLogger.error(
                    "swift_audio_promotion_admission_failed tick=\(self.stepCount, privacy: .public)"
                )
                engineRunStatus = SM64_MODERN_STATUS_INVALID_STATE
                CFRunLoopStop(CFRunLoopGetCurrent())
                return
            }
            if stepCount == 1 || stepCount.isMultiple(of: 300) {
                audioLogger.notice(
                    "swift_audio_promotion_tick tick=\(self.stepCount, privacy: .public) records=\(receipt.recordsAdded, privacy: .public) frame_count=\(receipt.frameCount, privacy: .public) clipped=\(receipt.clippedSamples, privacy: .public) fingerprint=\(receipt.frameFingerprint, privacy: .public)"
                )
            }
        }
        logAudioRenderIfNeeded()
        sampleM9ProfileIfNeeded()
        if stepCount == 1 || stepCount.isMultiple(of: 300) {
            engineLogger.notice("lifecycle_step count=\(self.stepCount)")
            metalRenderer?.logSceneStatus(step: stepCount)
            logAudioStatus()
        }
        if let parityCoordinator {
            let boundary = parityCoordinator.handleTickBoundary(step: stepCount)
            if boundary.status != SM64_MODERN_STATUS_OK {
                engineRunStatus = boundary.status
                CFRunLoopStop(CFRunLoopGetCurrent())
                return
            }
            if boundary.shouldStop {
                condition.withLock {
                    stopRequested = true
                    requestedExitReason = SM64_MODERN_EXIT_PLATFORM_REQUESTED
                    automaticTerminationRequested = true
                }
                engineLogger.notice("bounded_parity_run_complete steps=\(self.stepCount)")
                CFRunLoopStop(CFRunLoopGetCurrent())
            }
        }
        if let oracleTraceSession, oracleTraceSession.shouldStop(after: stepCount) {
            condition.withLock {
                stopRequested = true
                requestedExitReason = SM64_MODERN_EXIT_PLATFORM_REQUESTED
                automaticTerminationRequested = true
            }
            engineLogger.notice("bounded_oracle_trace_run_complete steps=\(self.stepCount)")
            CFRunLoopStop(CFRunLoopGetCurrent())
        }
    }

    private func sampleM9ProfileIfNeeded() {
        precondition(isCurrentEngineThread)
        guard let configuration = m9ProfileConfiguration else { return }

        if m9ProfileBaselineStep == nil, stepCount >= configuration.warmupSteps {
            let audio = audioService?.audioStatus().ring
            m9ProfileBaselineStep = stepCount
            m9ProfileStartNanoseconds = MonotonicClock.nowNanoseconds()
            m9ProfileStartRSSBytes = residentMemoryBytes()
            m9ProfileStartAudioRendered = audio?.rendered_frames ?? 0
            m9ProfileStartAudioUnderrun = audio?.underrun_frames ?? 0
            m9ProfileStartAudioDropped = audio?.dropped_frames ?? 0
            engineLogger.notice(
                "m9_profile_warmup_complete step=\(self.stepCount, privacy: .public) rss_bytes=\((self.m9ProfileStartRSSBytes ?? 0), privacy: .public) audio_rendered=\(self.m9ProfileStartAudioRendered, privacy: .public)"
            )
        }

        guard !m9ProfileComplete,
              m9ProfileBaselineStep != nil,
              stepCount >= configuration.targetSteps else {
            return
        }

        m9ProfileComplete = true
        let endNanoseconds = MonotonicClock.nowNanoseconds()
        let startNanoseconds = m9ProfileStartNanoseconds ?? endNanoseconds
        let elapsedNanoseconds = endNanoseconds >= startNanoseconds
            ? endNanoseconds - startNanoseconds
            : 0
        let endRSSBytes = residentMemoryBytes()
        let startRSSBytes = m9ProfileStartRSSBytes ?? endRSSBytes ?? 0
        let endRSS = endRSSBytes ?? startRSSBytes
        let rssDeltaBytes: Int64 = endRSS >= startRSSBytes
            ? Int64(endRSS - startRSSBytes)
            : -Int64(startRSSBytes - endRSS)
        let audio = audioService?.audioStatus().ring
        let rendered = audio?.rendered_frames ?? m9ProfileStartAudioRendered
        let underrun = audio?.underrun_frames ?? m9ProfileStartAudioUnderrun
        let dropped = audio?.dropped_frames ?? m9ProfileStartAudioDropped
        let renderedDelta = rendered >= m9ProfileStartAudioRendered
            ? rendered - m9ProfileStartAudioRendered
            : 0
        let underrunDelta = underrun >= m9ProfileStartAudioUnderrun
            ? underrun - m9ProfileStartAudioUnderrun
            : 0
        let droppedDelta = dropped >= m9ProfileStartAudioDropped
            ? dropped - m9ProfileStartAudioDropped
            : 0
        let underrunRateBPS = renderedDelta == 0
            ? 0
            : (underrunDelta * 10_000) / renderedDelta
        engineLogger.notice(
            "m9_profile_complete steps=\(self.stepCount, privacy: .public) elapsed_ns=\(elapsedNanoseconds, privacy: .public) scheduler_dropped_steps=\(self.schedulerDroppedSteps, privacy: .public) scheduler_catch_up_steps=\(self.schedulerCatchUpSteps, privacy: .public) audio_rendered_delta=\(renderedDelta, privacy: .public) audio_underrun_delta=\(underrunDelta, privacy: .public) audio_underrun_rate_bps=\(underrunRateBPS, privacy: .public) audio_dropped_delta=\(droppedDelta, privacy: .public) rss_start_bytes=\(startRSSBytes, privacy: .public) rss_end_bytes=\(endRSS, privacy: .public) rss_delta_bytes=\(rssDeltaBytes, privacy: .public)"
        )
        condition.withLock {
            stopRequested = true
            requestedExitReason = SM64_MODERN_EXIT_PLATFORM_REQUESTED
            automaticTerminationRequested = true
        }
        CFRunLoopStop(CFRunLoopGetCurrent())
    }

    private func makeEngineRuntime() -> SM64ModernEngineRuntime {
        let cAdapter = SM64ModernCEngineRuntimeAdapter(
            callbacks: SM64ModernEngineRuntimeCallbacks(
                initialize: { [unowned self] in self.initializeCEngineOnEngineThread() },
                step: { [unowned self] in self.stepCEngineOnEngineThread() },
                requestStop: { [unowned self] reason in self.requestStopCEngineOnEngineThread(reason: reason) },
                shutdown: { [unowned self] in self.shutdownCEngineOnEngineThread() }
            )
        )
        switch engineAuthority {
        case .swift:
            let swiftContext = SM64ModernSwiftEngineContext(
                traceSink: { [unowned self] record in
                    self.recordSwiftOracleTrace(record)
                }
            )
            return SM64ModernSwiftEngineRuntime(
                cFallback: cAdapter,
                swiftContext: swiftContext
            )
        case .cCompatibility:
            return cAdapter
        }
    }

    private func recordSwiftOracleTrace(
        _ record: SM64OracleTraceRecord
    ) -> SM64ModernStatus {
        precondition(isCurrentEngineThread)
        guard sm64_modern_oracle_trace_is_active() != 0 else {
            return SM64_MODERN_STATUS_OK
        }

        // The C lifecycle closes its trace tick before the Swift sidecar
        // context advances. Give the sidecar an explicit owner-thread tick so
        // schema-4 record/replay remains canonical without reopening the C
        // gameplay tick or sharing mutable C state with Swift.
        sm64_modern_oracle_trace_begin_tick()
        defer { sm64_modern_oracle_trace_end_tick() }
        let values = record.values
        let status = values.withUnsafeBufferPointer { buffer in
            sm64_modern_oracle_trace_record(
                record.domain,
                record.recordKind,
                record.subjectID,
                record.recordID,
                record.flags,
                buffer.baseAddress,
                UInt32(buffer.count)
            )
        }
        return status == SM64_MODERN_STATUS_OK
            ? sm64_modern_oracle_trace_status()
            : status
    }

    private func initializeCEngineOnEngineThread() -> SM64ModernStatus {
        var lifecycle = SM64ModernLifecycleApiV1()
        var status = sm64_modern_get_lifecycle_api(
            SM64_MODERN_ABI_VERSION_1,
            UInt32(MemoryLayout<SM64ModernLifecycleApiV1>.size),
            &lifecycle
        )
        guard status == SM64_MODERN_STATUS_OK else { return status }
        self.lifecycle = lifecycle

        var timebase = SM64ModernTimebaseApiV1()
        status = sm64_modern_get_timebase_api(
            SM64_MODERN_ABI_VERSION_1,
            UInt32(MemoryLayout<SM64ModernTimebaseApiV1>.size),
            &timebase
        )
        guard status == SM64_MODERN_STATUS_OK else { return status }
        var timebaseConfig = SM64ModernTimebaseConfigV1()
        timebaseConfig.header.abi_version = SM64_MODERN_ABI_VERSION_1
        timebaseConfig.header.struct_size = UInt32(MemoryLayout<SM64ModernTimebaseConfigV1>.size)
        // M8d activates the native product clock after M8b/M8c moved legacy
        // state and world dynamics behind the paired-boundary contract.
        // Legacy builds still configure 30/1 in their own host path.
        timebaseConfig.simulation_rate_numerator = 60
        timebaseConfig.simulation_rate_denominator = 1
        timebaseConfig.legacy_rate_numerator = 30
        timebaseConfig.legacy_rate_denominator = 1
        timebaseConfig.max_catch_up_steps = 2
        status = timebase.configure(&timebaseConfig)
        guard status == SM64_MODERN_STATUS_OK else { return status }
        var timebaseSnapshot = SM64ModernTimebaseSnapshotV1()
        status = timebase.get_snapshot(&timebaseSnapshot)
        guard status == SM64_MODERN_STATUS_OK else { return status }
        self.timebaseSnapshot = timebaseSnapshot
        engineLogger.notice(
            "timebase_configured simulation_hz=\(timebaseSnapshot.simulation_rate_numerator)/\(timebaseSnapshot.simulation_rate_denominator) legacy_hz=\(timebaseSnapshot.legacy_rate_numerator)/\(timebaseSnapshot.legacy_rate_denominator) paired_ticks=\(timebaseSnapshot.simulation_ticks_per_legacy_tick) fingerprint=\(timebaseSnapshot.fingerprint)"
        )

        var config = SM64ModernLifecycleConfigV1()
        config.header.abi_version = SM64_MODERN_ABI_VERSION_1
        config.header.struct_size = UInt32(MemoryLayout<SM64ModernLifecycleConfigV1>.size)
        config.main_pool_size = 0
        config.fullscreen_mode = SM64_MODERN_FULLSCREEN_FORCE_OFF

        let paths: HostPaths
        do {
            paths = try HostPaths.resolve()
            try withUnsafeMutableBytes(of: &config.game_directory) { try Self.copyCString(paths.gameDirectory, into: $0) }
            try withUnsafeMutableBytes(of: &config.save_directory) { try Self.copyCString(paths.saveDirectory, into: $0) }
            try withUnsafeMutableBytes(of: &config.config_file) { try Self.copyCString(SM64ModernConfigurationRuntime.fileName, into: $0) }
            try withUnsafeMutableBytes(of: &config.window_title) { try Self.copyCString("SM64 Modern", into: $0) }
            engineLogger.notice("host_paths_resolved")
        } catch {
            engineLogger.error("host_path_error \(error.localizedDescription, privacy: .private)")
            return SM64_MODERN_STATUS_PLATFORM_ERROR
        }

        let configuration: SM64ModernConfigurationLoadResult
        do {
            configuration = try SM64ModernConfigurationRuntime.load(
                from: SM64ModernConfigurationRuntime.fileURL(saveDirectory: paths.saveDirectory)
            )
        } catch {
            engineLogger.error(
                "configuration_load_failed error=\(error.localizedDescription, privacy: .public)"
            )
            return SM64_MODERN_STATUS_PLATFORM_ERROR
        }
        if configuration.didRepair {
            engineLogger.warning(
                "configuration_repaired keys=\(configuration.repairedKeys.joined(separator: ","), privacy: .public) malformed_lines=\(configuration.malformedLines.map(String.init).joined(separator: ","), privacy: .public) persisted=\(configuration.repairPersisted, privacy: .public)"
            )
        }
        if !configuration.unknownKeys.isEmpty {
            engineLogger.notice(
                "configuration_unknown_keys keys=\(configuration.unknownKeys.joined(separator: ","), privacy: .public)"
            )
        }
        if let repairPersistenceError = configuration.repairPersistenceError {
            engineLogger.error(
                "configuration_repair_persist_failed error=\(repairPersistenceError, privacy: .public)"
            )
        }

        // Swift owns the parsed cheat configuration at startup, then applies
        // the scalar snapshot into the legacy CheatList compatibility owner.
        // The C options menu may still mutate those fields live after this
        // boundary; gameplay callbacks observe that current C snapshot.
        var cheatState = SM64ModernCheatStateV1()
        cheatState.header.abi_version = SM64_MODERN_ABI_VERSION_1
        cheatState.header.struct_size = UInt32(MemoryLayout<SM64ModernCheatStateV1>.size)
        let cheats = configuration.configuration.cheats
        cheatState.enabled = cheats.enabled ? 1 : 0
        cheatState.moon_jump = cheats.moonJump ? 1 : 0
        cheatState.god_mode = cheats.godMode ? 1 : 0
        cheatState.infinite_lives = cheats.infiniteLives ? 1 : 0
        cheatState.super_speed = cheats.superSpeed ? 1 : 0
        cheatState.responsive = cheats.responsive ? 1 : 0
        cheatState.exit_anywhere = cheats.exitAnywhere ? 1 : 0
        cheatState.huge_mario = cheats.hugeMario ? 1 : 0
        cheatState.tiny_mario = cheats.tinyMario ? 1 : 0
        status = sm64_modern_apply_cheat_state(&cheatState)
        guard status == SM64_MODERN_STATUS_OK else {
            engineLogger.error("cheat_state_apply_failed status=\(status)")
            return status
        }
        engineLogger.notice(
            "cheat_state_applied enabled=\(cheatState.enabled) moon_jump=\(cheatState.moon_jump) god_mode=\(cheatState.god_mode) infinite_lives=\(cheatState.infinite_lives) super_speed=\(cheatState.super_speed) responsive=\(cheatState.responsive) exit_anywhere=\(cheatState.exit_anywhere) huge_mario=\(cheatState.huge_mario) tiny_mario=\(cheatState.tiny_mario)"
        )

        // Headless migration gates opt into the same level script with a
        // deterministic save-backed spawn, so the Peach intro cutscene cannot
        // consume the entire bounded callback window. Configuration is read
        // before the C lifecycle starts; C remains the compatibility consumer.
        let environment = ProcessInfo.processInfo.environment
        config.fullscreen_mode = configuration.configuration.window.fullscreen
            ? SM64_MODERN_FULLSCREEN_FORCE_ON
            : SM64_MODERN_FULLSCREEN_FORCE_OFF
        config.skip_intro = configuration.configuration.skipIntro
            || environment["SM64_MODERN_AUTOMATED_GAMEPLAY"] != nil
            || environment["SM64_MODERN_AUTOMATED_BOBOMB"] != nil ? 1 : 0

        var platform = SM64ModernPlatformApiV1()
        platform.header.abi_version = SM64_MODERN_ABI_VERSION_1
        platform.header.struct_size = UInt32(MemoryLayout<SM64ModernPlatformApiV1>.size)
        platform.capabilities = SM64_MODERN_PLATFORM_CAP_RENDERING
            | SM64_MODERN_PLATFORM_CAP_INPUT
            | SM64_MODERN_PLATFORM_CAP_AUDIO
        platform.reserved = 0
        platform.context = Unmanaged.passUnretained(self).toOpaque()
        platform.initialize = platformInitialize
        platform.shutdown = platformShutdown
        platform.audio_buffered = platformAudioBuffered
        platform.audio_desired_buffered = platformAudioDesiredBuffered
        platform.audio_play = platformAudioPlay
        platform.current_thread = platformCurrentThread
        platform.exit_requested = platformExitRequested
        platform.error_reported = platformError

        status = sm64_modern_validate_platform_api(&platform)
        guard status == SM64_MODERN_STATUS_OK else { return status }

        if engineAuthority == .swift {
            do {
                let service = try SwiftProgressionMigrationService(
                    saveDirectory: paths.saveDirectory,
                    ownerThreadToken: engineThreadIdentifier,
                    authority: engineAuthority
                )
                try service.initialize()
                var migration = service.makeAPI()
                status = sm64_modern_install_progression_migration_api(&migration)
                guard status == SM64_MODERN_STATUS_OK else {
                    return status
                }
                status = sm64_modern_progression_set_persistence_authority(1)
                guard status == SM64_MODERN_STATUS_OK else {
                    sm64_modern_uninstall_progression_migration_api()
                    return status
                }
                progressionMigrationService = service
                engineLogger.notice(
                    "progression_bridge_installed abi=1 authority=swift persistence_authority=swift"
                )

                let cameraService = SwiftCameraMigrationService(
                    ownerThreadToken: engineThreadIdentifier
                )
                var cameraMigration = cameraService.makeAPI()
                status = sm64_modern_install_camera_migration_api(
                    &cameraMigration
                )
                guard status == SM64_MODERN_STATUS_OK else {
                    _ = sm64_modern_progression_set_persistence_authority(0)
                    sm64_modern_uninstall_progression_migration_api()
                    return status
                }
                status = sm64_modern_camera_set_authority(1)
                guard status == SM64_MODERN_STATUS_OK else {
                    sm64_modern_uninstall_camera_migration_api()
                    _ = sm64_modern_progression_set_persistence_authority(0)
                    sm64_modern_uninstall_progression_migration_api()
                    return status
                }
                cameraMigrationService = cameraService
                engineLogger.notice(
                    "camera_selection_bridge_installed abi=1 authority=swift geometry_authority=c"
                )

                let globalStateService = SwiftGlobalStateMigrationService(
                    ownerThreadToken: engineThreadIdentifier
                )
                var globalStateMigration = globalStateService.makeAPI()
                status = sm64_modern_install_global_state_migration_api(
                    &globalStateMigration
                )
                guard status == SM64_MODERN_STATUS_OK else {
                    _ = sm64_modern_camera_set_authority(0)
                    sm64_modern_uninstall_camera_migration_api()
                    cameraMigrationService = nil
                    _ = sm64_modern_progression_set_persistence_authority(0)
                    sm64_modern_uninstall_progression_migration_api()
                    progressionMigrationService = nil
                    return status
                }
                globalStateMigrationService = globalStateService
                engineLogger.notice(
                    "global_state_bridge_installed abi=1 authority=c swift_mirror=true owner_thread=true"
                )

                let effectsService = SwiftEffectsMigrationService(
                    ownerThreadToken: engineThreadIdentifier
                )
                var effectsMigration = effectsService.makeAPI()
                status = sm64_modern_install_effects_migration_api(
                    &effectsMigration
                )
                guard status == SM64_MODERN_STATUS_OK else {
                    return status
                }
                effectsMigrationService = effectsService
                engineLogger.notice(
                    "effects_receipt_bridge_installed abi=1 authority=c swift_mirror=true owner_thread=true"
                )
            } catch {
                engineLogger.error(
                    "progression_bridge_initialize_failed error=\(error.localizedDescription, privacy: .public)"
                )
                return SM64_MODERN_STATUS_PLATFORM_ERROR
            }
        }
        status = self.lifecycle.initialize(&config, &platform)
        guard status == SM64_MODERN_STATUS_OK else {
            sm64_modern_uninstall_effects_migration_api()
            effectsMigrationService = nil
            sm64_modern_uninstall_global_state_migration_api()
            globalStateMigrationService = nil
            _ = sm64_modern_camera_set_authority(0)
            sm64_modern_uninstall_camera_migration_api()
            cameraMigrationService = nil
            _ = sm64_modern_progression_set_persistence_authority(0)
            sm64_modern_uninstall_progression_migration_api()
            progressionMigrationService = nil
            return status
        }

        let oracleStart = SM64ModernOracleTraceSession.beginFromEnvironment(
            saveDirectory: paths.saveDirectory
        )
        guard oracleStart.status == SM64_MODERN_STATUS_OK else {
            sm64_modern_uninstall_effects_migration_api()
            effectsMigrationService = nil
            _ = self.lifecycle.shutdown()
            return oracleStart.status
        }
        oracleTraceSession = oracleStart.session

        let parityStart = GameplayParityCoordinator.beginFromEnvironment(
            saveDirectory: paths.saveDirectory,
            gameplayService: gameplayService
        )
        guard parityStart.status == SM64_MODERN_STATUS_OK else {
            _ = oracleTraceSession?.end()
            oracleTraceSession = nil
            sm64_modern_uninstall_effects_migration_api()
            effectsMigrationService = nil
            _ = self.lifecycle.shutdown()
            return parityStart.status
        }
        parityCoordinator = parityStart.coordinator
        return SM64_MODERN_STATUS_OK
    }

    private func stepCEngineOnEngineThread() -> SM64ModernStatus {
        precondition(isCurrentEngineThread)
        return lifecycle.step()
    }

    private func consumePresentationPauseOnEngineThread() -> Bool? {
        precondition(isCurrentEngineThread)
        return condition.withLock {
            defer { pendingPresentationPause = nil }
            return pendingPresentationPause
        }
    }

    private func applyPresentationPauseOnEngineThread(_ paused: Bool) {
        precondition(isCurrentEngineThread)
        let wasPaused = presentationPaused
        presentationPaused = paused
        metalRenderer?.setPresentationPaused(paused)
        guard wasPaused, !paused else { return }

        presentationResumeGeneration &+= 1
        presentationResumeBaselineSize = metalRenderer.map { renderer in
            let dimensions = renderer.dimensions()
            return CGSize(width: Int(dimensions.0), height: Int(dimensions.1))
        }
        awaitingPostResumeResizeAcknowledgement = true
        postResumeResizeCandidate = nil
        presentedPostResumeResizeCandidate = nil
        postResumeWarmupTicks = 0
        let pendingRequestID = condition.withLock { pendingDrawableRequestID }
        engineLogger.notice(
            "metal_presentation_resume_waiting resume=\(self.presentationResumeGeneration, privacy: .public) baseline=\(self.drawableSizeDescription(self.presentationResumeBaselineSize), privacy: .public) pending_request=\(pendingRequestID, privacy: .public)"
        )
    }

    private func drainPendingDrawableSizeAtEngineBoundary() {
        precondition(isCurrentEngineThread)
        guard metalRenderer != nil else { return }
        applyingPendingDrawableSizeAtEngineBoundary = true
        defer { applyingPendingDrawableSizeAtEngineBoundary = false }
        metalRenderer?.applyPendingDrawableSize()
    }

    private func shouldDrainPendingDrawableSizeAtEngineBoundary() -> Bool {
        precondition(isCurrentEngineThread)
        let requestID = condition.withLock { pendingDrawableRequestID }
        guard requestID != 0 else {
            pendingDrawableAgeRequestID = 0
            pendingDrawableAgeTicks = 0
            return false
        }
        if pendingDrawableAgeRequestID != requestID {
            pendingDrawableAgeRequestID = requestID
            pendingDrawableAgeTicks = 1
        } else {
            pendingDrawableAgeTicks &+= 1
        }
        return pendingDrawableAgeTicks >= 4
    }

    private func acknowledgePostResumeResizeIfWarmed() {
        precondition(isCurrentEngineThread)
        guard postResumeWarmupTicks >= 2,
              let candidate = presentedPostResumeResizeCandidate else { return }
        awaitingPostResumeResizeAcknowledgement = false
        presentedPostResumeResizeCandidate = nil
        engineLogger.notice(
            "metal_presentation_resize_ack post_resume=true resume=\(self.presentationResumeGeneration, privacy: .public) request=\(candidate.requestID, privacy: .public) drawable=\(self.drawableSizeDescription(candidate.size), privacy: .public) source=display_link_presented_next_callback warmed=true warmup_ticks=\(self.postResumeWarmupTicks, privacy: .public) owner_thread=true"
        )
    }

    private func requestStopCEngineOnEngineThread(reason: SM64ModernExitReason) -> SM64ModernStatus {
        precondition(isCurrentEngineThread)
        return lifecycle.request_stop(reason)
    }

    private func shutdownCEngineOnEngineThread() -> SM64ModernStatus {
        precondition(isCurrentEngineThread)
        return lifecycle.shutdown()
    }

    fileprivate var gameplayServiceOnEngineThread: SwiftGameplayService {
        precondition(isCurrentEngineThread)
        return gameplayService
    }

    private func finish(state: State, status: SM64ModernStatus) {
        condition.withLock {
            self.state = state
            engineRunLoop = nil
            condition.broadcast()
        }
        engineLogger.notice("engine_thread_finished status=\(status) steps=\(self.stepCount)")
    }

    fileprivate func initializeMetalOnEngineThread() throws {
        precondition(isCurrentEngineThread)
        let configuration = condition.withLock { metalConfiguration }
        guard let configuration else {
            throw MetalRendererError.configurationUnavailable
        }
        precondition(configuration.layer.drawableSize == configuration.drawableSize)
        let renderer = try MetalRenderer(
            device: configuration.device,
            layer: configuration.layer,
            isOwnerThread: { [weak self] in self?.isCurrentEngineThread == true },
            consumeDrawableSize: { [weak self] in self?.consumePendingDrawableSize() }
        )
        metalRenderer = renderer
        renderer.start(on: .current)
        if ProcessInfo.processInfo.environment["SM64_MODERN_MARIO_FACE_TEXTURE_UPLOAD"] == "1" {
            try admitMarioFaceTextureUploadOnEngineThread(renderer)
        }
        if ProcessInfo.processInfo.environment["SM64_MODERN_MARIO_FACE_DRAW"] == "1" {
            try admitMarioFaceSourceGeometryOnEngineThread(renderer)
        }
    }

    private func admitMarioFaceTextureUploadOnEngineThread(_ renderer: MetalRenderer) throws {
        precondition(isCurrentEngineThread)
        let environment = ProcessInfo.processInfo.environment
        guard let gameDirectory = environment["SM64_MODERN_GAME_DIR"] else {
            throw HostPathError.missingGameDirectory
        }
        let rootURL = URL(fileURLWithPath: gameDirectory, isDirectory: true).standardizedFileURL
        let routeID: SM64MarioFaceGoddardRouteID = .marioNormal
        guard let route = SM64MarioFaceRouteResourceCatalog.route(routeID),
              let binding = SM64MarioFaceMetalBindingPacketBuilder.make(routeID: routeID) else {
            throw SM64MarioFaceTextureUploadAdmissionError.payloadMismatch(
                textureID: 0, reason: "mario_normal_route_unavailable"
            )
        }
        let payloads = try SM64MarioFaceTextureProvider.load(route: route, rootURL: rootURL)
        let plan = try SM64MarioFaceTextureUploadPlanBuilder.make(
            ownerToken: engineThreadIdentifier,
            expectedOwnerToken: engineThreadIdentifier,
            routeID: routeID,
            binding: binding,
            payloads: payloads
        )
        let receipt = try renderer.admitMarioFaceTextureUpload(plan)
        engineLogger.notice(
            "mario_face_texture_upload_admitted route=\(receipt.route.rawValue) entries=\(receipt.admittedEntries) source_bytes=\(receipt.sourceByteCount) upload_bytes=\(receipt.uploadByteCount) generations=\(receipt.firstGeneration)-\(receipt.lastGeneration) pending_residency=\(receipt.pendingResidencyCount) fingerprint=\(receipt.planFingerprint, privacy: .public)"
        )
    }

    private func admitMarioFaceSourceGeometryOnEngineThread(_ renderer: MetalRenderer) throws {
        precondition(isCurrentEngineThread)
        let environment = ProcessInfo.processInfo.environment
        guard let gameDirectory = environment["SM64_MODERN_GAME_DIR"] else {
            throw HostPathError.missingGameDirectory
        }
        let rootURL = URL(fileURLWithPath: gameDirectory, isDirectory: true).standardizedFileURL
        let packet = try SM64MarioFaceSourceGeometryProvider.load(rootURL: rootURL)
        let initialFrameQ16: UInt32 = 1 << 16
        let transform: SM64MarioFaceMetalTransformPacket
        if let payloadPath = ProcessInfo.processInfo.environment["SM64_MODERN_MARIO_FACE_PAYLOAD_PATH"],
           !payloadPath.isEmpty,
           let bundle = try? SM64MarioFacePayloadBundle.decode(Data(contentsOf: URL(fileURLWithPath: payloadPath))) {
            let renderPacket = makeMarioFaceRenderPacket(bundle: bundle, frameQ16: initialFrameQ16)
            guard let composedTransform = SM64MarioFaceMetalTransformPacketBuilder.make(
                routeID: .marioNormal,
                face: renderPacket
            ) else {
                throw NSError(
                    domain: "io.github.deestiz.sm64modern.MarioFace",
                    code: Int(SM64_MODERN_STATUS_INVALID_STATE),
                    userInfo: [NSLocalizedDescriptionKey: "Mario-normal composed transform attachment was not resident"]
                )
            }
            marioFacePayloadBundle = bundle
            marioFaceCompositionSource = "mfpb"
            transform = composedTransform
            engineLogger.notice(
                "mario_face_composition_admitted source=mfpb bank=0 frame_q16=\(initialFrameQ16) resident_channels=\(renderPacket.residentChannelCount) unavailable_channels=\(renderPacket.unavailableChannelCount) packet_fingerprint=\(SM64MarioFaceRenderPacketFingerprint.packet(renderPacket), privacy: .public)"
            )
        } else if let decoded = SM64MarioFaceAnimationPayload.decode(
            componentID: 0xE2, bank: 0, frameQ16: initialFrameQ16
        ), let boundedTransform = SM64MarioFaceMetalTransformPacketBuilder.make(
            routeID: .marioNormal,
            animationFrameQ16: initialFrameQ16,
            animationValues: decoded.values
        ) {
            marioFacePayloadBundle = nil
            marioFaceCompositionSource = "bounded_payload_window"
            transform = boundedTransform
            engineLogger.notice(
                "mario_face_composition_admitted source=bounded_payload_window bank=0 frame_q16=\(initialFrameQ16) component=226 values=\(decoded.values.count)"
            )
        } else if let fallbackTransform = SM64MarioFaceMetalTransformPacketBuilder.make(
            routeID: .marioNormal,
            animationFrameQ16: initialFrameQ16
        ) {
            marioFacePayloadBundle = nil
            marioFaceCompositionSource = "static_source_fallback"
            transform = fallbackTransform
            engineLogger.notice(
                "mario_face_composition_admitted source=static_source_fallback bank=0 frame_q16=\(initialFrameQ16)"
            )
        } else {
            throw NSError(
                domain: "io.github.deestiz.sm64modern.MarioFace",
                code: Int(SM64_MODERN_STATUS_INVALID_STATE),
                userInfo: [NSLocalizedDescriptionKey: "Mario-normal transform attachment was not resident"]
            )
        }
        try renderer.admitMarioFaceSourceGeometry(packet, transform: transform)
        engineLogger.notice(
            "mario_face_geometry_source_admitted source_path=\(packet.sourcePath, privacy: .public) schema=\(packet.schemaVersion) vertices=\(packet.vertices.count) faces=\(packet.triangles.count) materials=\(packet.materials.count) source_digest=\(packet.sourceDigestWords.map { String($0, radix: 16) }.joined(separator: ":"), privacy: .public) packet_fingerprint=\(SM64MarioFaceSourceGeometryFingerprint.packet(packet), privacy: .public)"
        )
        engineLogger.notice(
            "mario_face_transform_admitted route=\(transform.routeID) schema=\(transform.schemaVersion) component=\(transform.animationComponentID) frame_q16=\(transform.animationFrameQ16) viewport=\(transform.viewportWidth)x\(transform.viewportHeight) transform_fingerprint=\(SM64MarioFaceMetalTransformFingerprint.packet(transform), privacy: .public)"
        )
    }

    private func makeMarioFaceRenderPacket(
        bundle: SM64MarioFacePayloadBundle,
        frameQ16: UInt32
    ) -> SM64MarioFaceRenderFramePacket {
        let baseFace = SM64MarioFaceInput(
            bodyIndex: 0,
            areaUpdateCounter: 0,
            eyeState: SM64MarioFaceEyeState.blink.rawValue,
            action: 0,
            handState: SM64MarioFaceHandState.fists.rawValue,
            handSwitchCaseCount: 0,
            capState: 0,
            modelState: 0
        )
        return SM64MarioFaceRenderPacketBuilder.make(
            input: SM64MarioFaceExpressionInput(
                face: baseFace,
                animationBank: 0,
                animationFrameQ16: frameQ16,
                peachKissTimeline: false,
                actionTimer: 100
            ),
            bundle: bundle
        )
    }

    private func updateMarioFaceTransformOnEngineThread() {
        precondition(isCurrentEngineThread)
        guard let renderer = metalRenderer,
              marioFacePayloadBundle != nil,
              ProcessInfo.processInfo.environment["SM64_MODERN_MARIO_FACE_DRAW"] == "1" else {
            return
        }
        // The full MFPB has the source 820-frame bank. Keep the frame and
        // interpolation in the same Q16.16 domain as move_animator, so the
        // transform packet changes with the qualified M30j composition rather
        // than remaining on the admission-time sample.
        let sourceFrame = UInt32((stepCount % 820) + 1)
        let frameQ16 = (sourceFrame << 16) | UInt32((stepCount * 0x1000) & 0xFFFF)
        guard let bundle = marioFacePayloadBundle else { return }
        let renderPacket = makeMarioFaceRenderPacket(bundle: bundle, frameQ16: frameQ16)
        guard let transform = SM64MarioFaceMetalTransformPacketBuilder.make(
            routeID: .marioNormal,
            face: renderPacket
        ) else { return }
        renderer.updateMarioFaceTransform(transform)
        if stepCount == 1 || stepCount.isMultiple(of: 300) {
            engineLogger.notice(
                "mario_face_composition_tick source=\(self.marioFaceCompositionSource, privacy: .public) bank=0 frame_q16=\(frameQ16) resident_channels=\(renderPacket.residentChannelCount) unavailable_channels=\(renderPacket.unavailableChannelCount) packet_fingerprint=\(SM64MarioFaceRenderPacketFingerprint.packet(renderPacket), privacy: .public) transform_fingerprint=\(SM64MarioFaceMetalTransformFingerprint.packet(transform), privacy: .public)"
            )
        }
    }

    fileprivate var inputServiceOnEngineThread: AppleInputService? {
        precondition(isCurrentEngineThread)
        return condition.withLock { inputService }
    }

    fileprivate func initializeFrontEndOnEngineThread() throws {
        precondition(isCurrentEngineThread)
        guard engineAuthority == .swift else { return }
        guard frontendMigrationService == nil else {
            throw NSError(
                domain: "io.github.deestiz.sm64modern.FrontEnd",
                code: Int(SM64_MODERN_STATUS_INVALID_STATE),
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "The Swift front-end observer is already initialized"
                ]
            )
        }
        let service = SwiftFrontEndMigrationService(
            ownerThreadToken: engineThreadIdentifier
        )
        var migration = service.makeAPI()
        let status = sm64_modern_install_frontend_migration_api(&migration)
        guard status == SM64_MODERN_STATUS_OK else {
            throw NSError(
                domain: "io.github.deestiz.sm64modern.FrontEnd",
                code: Int(status),
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Could not install the Swift front-end observer"
                ]
            )
        }
        frontendMigrationService = service
        engineLogger.notice(
            "frontend_bridge_installed abi=1 authority=swift state_authority=c render_authority=c"
        )
    }

    fileprivate func discardFrontEndMigrationOnEngineThread() {
        precondition(isCurrentEngineThread)
        frontendMigrationService = nil
    }

    fileprivate func shutdownFrontEndOnEngineThread() {
        precondition(isCurrentEngineThread)
        let service = frontendMigrationService
        frontendMigrationService = nil
        sm64_modern_uninstall_frontend_migration_api()
        if let service {
            let summary = service.summary()
            engineLogger.notice(
                "swift_frontend_observer_finished events=\(summary.events, privacy: .public) transitions=\(summary.transitions, privacy: .public) screen=\(summary.screen, privacy: .public) fingerprint=\(summary.fingerprint, privacy: .public)"
            )
        }
    }

    fileprivate func initializePauseMenuOnEngineThread() throws {
        precondition(isCurrentEngineThread)
        guard engineAuthority == .swift else { return }
        guard pauseMenuMigrationService == nil else {
            throw NSError(
                domain: "io.github.deestiz.sm64modern.PauseMenu",
                code: Int(SM64_MODERN_STATUS_INVALID_STATE),
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "The Swift pause/menu observer is already initialized"
                ]
            )
        }
        let service = SwiftPauseMenuMigrationService(
            ownerThreadToken: engineThreadIdentifier
        )
        var migration = service.makeAPI()
        let status = sm64_modern_install_pause_menu_migration_api(&migration)
        guard status == SM64_MODERN_STATUS_OK else {
            throw NSError(
                domain: "io.github.deestiz.sm64modern.PauseMenu",
                code: Int(status),
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Could not install the Swift pause/menu observer"
                ]
            )
        }
        pauseMenuMigrationService = service
        engineLogger.notice(
            "pause_menu_bridge_installed abi=1 authority=swift state_authority=c render_authority=c"
        )
    }

    fileprivate func discardPauseMenuMigrationOnEngineThread() {
        precondition(isCurrentEngineThread)
        pauseMenuMigrationService = nil
    }

    fileprivate func shutdownPauseMenuOnEngineThread() {
        precondition(isCurrentEngineThread)
        let service = pauseMenuMigrationService
        pauseMenuMigrationService = nil
        sm64_modern_uninstall_pause_menu_migration_api()
        if let service {
            let summary = service.summary()
            engineLogger.notice(
                "swift_pause_menu_observer_finished events=\(summary.events, privacy: .public) outcomes=\(summary.outcomes, privacy: .public) state=\(summary.state, privacy: .public) fingerprint=\(summary.fingerprint, privacy: .public)"
            )
        }
    }

    fileprivate func initializeAudioOnEngineThread() throws {
        precondition(isCurrentEngineThread)
        guard audioService == nil else {
            throw NSError(
                domain: "io.github.deestiz.sm64modern.Audio",
                code: Int(SM64_MODERN_STATUS_INVALID_STATE),
                userInfo: [NSLocalizedDescriptionKey: "Native audio is already initialized"]
            )
        }
        guard let service = SM64ModernAppleAudioService.makeAudioService() else {
            throw NSError(
                domain: "io.github.deestiz.sm64modern.Audio",
                code: Int(SM64_MODERN_STATUS_OUT_OF_MEMORY),
                userInfo: [NSLocalizedDescriptionKey: "Could not allocate the native audio service"]
            )
        }
        do {
            try service.start()
        } catch {
            service.stop()
            throw error
        }
        audioService = service
        if engineAuthority == .swift {
            let migrationService = SwiftAudioMigrationService(
                ownerThreadToken: engineThreadIdentifier
            )
            var migration = migrationService.makeAPI()
            let migrationStatus = sm64_modern_install_audio_migration_api(
                &migration
            )
            guard migrationStatus == SM64_MODERN_STATUS_OK else {
                service.stop()
                audioService = nil
                throw NSError(
                    domain: "io.github.deestiz.sm64modern.Audio",
                    code: Int(migrationStatus),
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Could not install the Swift audio sequence observer"
                    ]
                )
            }
            audioMigrationService = migrationService
            let pcmReceiptService = SwiftAudioPCMReceiptService(
                ownerThreadToken: engineThreadIdentifier
            )
            var pcmMigration = pcmReceiptService.makeAPI()
            let pcmMigrationStatus = sm64_modern_install_audio_pcm_migration_api(
                &pcmMigration
            )
            guard pcmMigrationStatus == SM64_MODERN_STATUS_OK else {
                sm64_modern_uninstall_audio_migration_api()
                audioMigrationService = nil
                service.stop()
                audioService = nil
                throw NSError(
                    domain: "io.github.deestiz.sm64modern.Audio",
                    code: Int(pcmMigrationStatus),
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Could not install the Swift audio PCM receipt observer"
                    ]
                )
            }
            audioPCMReceiptService = pcmReceiptService
            audioLogger.notice(
                "audio_sequence_bridge_installed abi=1 authority=swift pcm_authority=c pcm_receipt_observer=swift"
            )
        }
        if ProcessInfo.processInfo.environment["SM64_MODERN_AUDIO_PROMOTION"] == "1" {
            let promotion = SM64AudioOwnerPromotion(ownerToken: engineThreadIdentifier)
            audioPromotion = promotion
            audioLogger.notice(
                "swift_audio_promotion_started owner_token=\(self.engineThreadIdentifier, privacy: .public)"
            )
        }
        let status = service.audioStatus()
        audioLogger.notice(
            "audio_service_started input_hz=32000 format=s16_interleaved_stereo output_hz=\(status.output_sample_rate) output_channels=\(status.output_channel_count) capacity=\(status.capacity_frames) desired=\(status.desired_buffered_frames) backlog=\(status.backlog_ceiling_frames)"
        )
        engineLogger.notice(
            "presentation_cadence native_hz=\(self.timebaseSnapshot.simulation_rate_numerator)/\(self.timebaseSnapshot.simulation_rate_denominator) legacy_hz=\(self.timebaseSnapshot.legacy_rate_numerator)/\(self.timebaseSnapshot.legacy_rate_denominator) drawable_per_native_tick=true"
        )
    }

    fileprivate func shutdownAudioOnEngineThread() {
        precondition(isCurrentEngineThread)
        let sequenceMigration = audioMigrationService
        audioMigrationService = nil
        sm64_modern_uninstall_audio_migration_api()
        let pcmReceiptMigration = audioPCMReceiptService
        audioPCMReceiptService = nil
        sm64_modern_uninstall_audio_pcm_migration_api()
        let promotion = audioPromotion
        audioPromotion = nil
        if let audioService {
            audioService.stop()
            let status = audioService.audioStatus()
            logM9ProfileAudioFinal(status.ring)
            self.audioService = nil
            audioLogger.notice(
                "audio_service_stopped enqueued=\(status.ring.enqueued_frames) rendered=\(status.ring.rendered_frames) underrun=\(status.ring.underrun_frames) dropped=\(status.ring.dropped_frames) render_calls=\(status.ring.render_calls)"
            )
        }
        if let summary = promotion?.summary() {
            audioLogger.notice(
                "swift_audio_promotion_finished ticks=\(summary.ticks, privacy: .public) records=\(summary.traceRecords, privacy: .public) pcm_frames=\(summary.pcmFrames, privacy: .public) fingerprint=\(summary.traceFingerprint, privacy: .public) admission_failed=\(summary.admissionFailed, privacy: .public)"
            )
        }
        if let sequenceMigration {
            let summary = sequenceMigration.summary()
            audioLogger.notice(
                "swift_audio_sequence_observer_finished events=\(summary.events, privacy: .public) ticks=\(summary.ticks, privacy: .public) queue=\(summary.queueCount, privacy: .public) fingerprint=\(summary.fingerprint, privacy: .public)"
            )
        }
        if let pcmReceiptMigration {
            let summary = pcmReceiptMigration.summary()
            let lastTick = summary.lastTick.map(String.init) ?? "none"
            audioLogger.notice(
                "swift_audio_pcm_receipt_observer_finished receipts=\(summary.receipts, privacy: .public) records=\(summary.records, privacy: .public) last_tick=\(lastTick, privacy: .public) fingerprint=\(summary.fingerprint, privacy: .public)"
            )
        }
    }

    private func logM9ProfileAudioFinal(_ ring: SM64ModernAudioRingStats) {
        guard m9ProfileConfiguration != nil, m9ProfileBaselineStep != nil else { return }
        let renderedDelta = ring.rendered_frames >= m9ProfileStartAudioRendered
            ? ring.rendered_frames - m9ProfileStartAudioRendered
            : 0
        let underrunDelta = ring.underrun_frames >= m9ProfileStartAudioUnderrun
            ? ring.underrun_frames - m9ProfileStartAudioUnderrun
            : 0
        let droppedDelta = ring.dropped_frames >= m9ProfileStartAudioDropped
            ? ring.dropped_frames - m9ProfileStartAudioDropped
            : 0
        let underrunRateBPS = renderedDelta == 0
            ? 0
            : (underrunDelta * 10_000) / renderedDelta
        audioLogger.notice(
            "m9_profile_audio_final audio_rendered_delta=\(renderedDelta, privacy: .public) audio_underrun_delta=\(underrunDelta, privacy: .public) audio_underrun_rate_bps=\(underrunRateBPS, privacy: .public) audio_dropped_delta=\(droppedDelta, privacy: .public)"
        )
    }

    fileprivate func audioBufferedFrames() -> Int32 {
        precondition(isCurrentEngineThread)
        guard let audioService else {
            assertionFailure("The advertised audio capability requires a live service")
            return 0
        }
        return audioService.bufferedFrames()
    }

    fileprivate func audioDesiredBufferedFrames() -> UInt32 {
        precondition(isCurrentEngineThread)
        guard let audioService else {
            assertionFailure("The advertised audio capability requires a live service")
            return 0
        }
        return audioService.desiredBufferedFrames()
    }

    fileprivate func audioPlay(samples: UnsafePointer<Int16>, frameCount: UInt32) {
        precondition(isCurrentEngineThread)
        guard let audioService else {
            assertionFailure("The advertised audio capability requires a live service")
            return
        }
        audioService.enqueueInterleavedStereoSamples(samples, frameCount: frameCount)
        if !loggedAudioEnqueue {
            loggedAudioEnqueue = true
            let blocksPerNativeStep = self.timebaseSnapshot.simulation_ticks_per_legacy_tick > 1 ? 1 : 2
            audioLogger.notice(
                "audio_enqueue_started blocks_per_native_step=\(blocksPerNativeStep) frames=\(frameCount)"
            )
        }
    }

    private func logAudioRenderIfNeeded() {
        precondition(isCurrentEngineThread)
        guard !loggedAudioRender, let status = audioService?.audioStatus(), status.ring.render_calls > 0 else {
            return
        }
        loggedAudioRender = true
        audioLogger.notice(
            "audio_render_started calls=\(status.ring.render_calls) rendered=\(status.ring.rendered_frames) underrun=\(status.ring.underrun_frames)"
        )
    }

    private func logAudioStatus() {
        precondition(isCurrentEngineThread)
        guard let status = audioService?.audioStatus() else { return }
        audioLogger.notice(
            "audio_status step=\(self.stepCount) running=\(status.running) buffered=\(status.buffered_frames) rendered=\(status.ring.rendered_frames) underrun=\(status.ring.underrun_frames) dropped=\(status.ring.dropped_frames) recovery_pending=\(status.recovery_pending)"
        )
    }

    fileprivate func shutdownMetalOnEngineThread() throws {
        precondition(isCurrentEngineThread)
        defer { metalRenderer = nil }
        try metalRenderer?.shutdownAndDrain()
    }

    func renderingInitialize(filteringMode: UInt32) -> SM64ModernStatus {
        precondition(isCurrentEngineThread)
        return metalRenderer?.initializeScene(filteringMode: filteringMode) ?? SM64_MODERN_STATUS_INVALID_STATE
    }

    func renderingShutdown() {
        precondition(isCurrentEngineThread)
        do { try shutdownMetalOnEngineThread() }
        catch { engineLogger.fault("metal_shutdown_failed error=\(error.localizedDescription, privacy: .public)") }
    }

    func renderingCreateShader(id: UInt32, filteringMode: UInt32, inputCount: UInt32, textureMask: UInt32) -> SM64ModernStatus {
        precondition(isCurrentEngineThread)
        return metalRenderer?.registerShader(id: id, filteringMode: filteringMode, inputCount: inputCount, textureMask: textureMask)
            ?? SM64_MODERN_STATUS_INVALID_STATE
    }
    func renderingSelectShader(_ id: UInt32) {
        precondition(isCurrentEngineThread)
        metalRenderer?.selectShader(id)
    }
    func renderingCreateTexture(_ id: UInt32) -> SM64ModernStatus {
        precondition(isCurrentEngineThread)
        return metalRenderer?.createTexture(id) ?? SM64_MODERN_STATUS_INVALID_STATE
    }
    func renderingSelectTexture(tile: UInt32, id: UInt32) {
        precondition(isCurrentEngineThread)
        metalRenderer?.selectTexture(tile: tile, id: id)
    }
    func renderingUploadTexture(id: UInt32, pixels: UnsafePointer<UInt8>, width: UInt32, height: UInt32) -> SM64ModernStatus {
        precondition(isCurrentEngineThread)
        return metalRenderer?.uploadTexture(id: id, pixels: pixels, width: width, height: height) ?? SM64_MODERN_STATUS_INVALID_STATE
    }
    func renderingSetSampler(tile: UInt32, id: UInt32, linear: Bool, wrapS: UInt32, wrapT: UInt32) {
        precondition(isCurrentEngineThread)
        metalRenderer?.setSampler(tile: tile, id: id, linear: linear, wrapS: wrapS, wrapT: wrapT)
    }
    func renderingSetDepthTest(_ enabled: Bool) {
        precondition(isCurrentEngineThread)
        metalRenderer?.setDepthTest(enabled)
    }
    func renderingSetDepthWrite(_ enabled: Bool) {
        precondition(isCurrentEngineThread)
        metalRenderer?.setDepthWrite(enabled)
    }
    func renderingSetDecal(_ enabled: Bool) {
        precondition(isCurrentEngineThread)
        metalRenderer?.setDecal(enabled)
    }
    func renderingSetViewport(_ rect: MetalRect) {
        precondition(isCurrentEngineThread)
        metalRenderer?.setViewport(rect)
    }
    func renderingSetScissor(_ rect: MetalRect) {
        precondition(isCurrentEngineThread)
        metalRenderer?.setScissor(rect)
    }
    func renderingSetAlphaBlend(_ enabled: Bool) {
        precondition(isCurrentEngineThread)
        metalRenderer?.setAlphaBlend(enabled)
    }
    func renderingDraw(vertices: UnsafePointer<Float>?, floatCount: UInt32, triangleCount: UInt32) -> SM64ModernStatus {
        precondition(isCurrentEngineThread)
        return metalRenderer?.draw(vertices: vertices, floatCount: floatCount, triangleCount: triangleCount) ?? SM64_MODERN_STATUS_INVALID_STATE
    }
    func renderingStartFrame() -> SM64ModernStatus {
        precondition(isCurrentEngineThread)
        return metalRenderer?.startSceneFrame() ?? SM64_MODERN_STATUS_INVALID_STATE
    }
    func renderingEndFrame() -> SM64ModernStatus {
        precondition(isCurrentEngineThread)
        return metalRenderer?.endSceneFrame() ?? SM64_MODERN_STATUS_INVALID_STATE
    }
    func renderingFinish() -> SM64ModernStatus {
        precondition(isCurrentEngineThread)
        return metalRenderer?.finishScene() ?? SM64_MODERN_STATUS_INVALID_STATE
    }
    func renderingDimensions() -> (UInt32, UInt32) {
        precondition(isCurrentEngineThread)
        return metalRenderer?.dimensions() ?? (1, 1)
    }

    private func consumePendingDrawableSize() -> CGSize? {
        precondition(isCurrentEngineThread)
        let request = condition.withLock { () -> DrawableResizeCandidate? in
            guard let pendingDrawableSize else { return nil }
            let request = DrawableResizeCandidate(
                requestID: pendingDrawableRequestID,
                size: pendingDrawableSize
            )
            self.pendingDrawableSize = nil
            self.pendingDrawableRequestID = 0
            return request
        }
        guard let request else { return nil }

        // `MetalRenderer` invokes this closure after `drawable.present()` and
        // before it mutates `CAMetalLayer.drawableSize` for the next frame.
        // Reading the current dimensions here therefore identifies the
        // drawable that was actually presented, not merely the size being
        // staged for the next callback.
        let presentedDrawableSize = applyingPendingDrawableSizeAtEngineBoundary
            ? nil
            : metalRenderer.map { renderer in
                let dimensions = renderer.dimensions()
                return CGSize(width: Int(dimensions.0), height: Int(dimensions.1))
            }

        if !applyingPendingDrawableSizeAtEngineBoundary,
           !presentationPaused,
           awaitingPostResumeResizeAcknowledgement,
           let candidate = postResumeResizeCandidate,
           let presentedDrawableSize,
           presentedPostResumeResizeCandidate == nil,
           drawableSizesMatch(presentedDrawableSize, candidate.size) {
            postResumeResizeCandidate = nil
            presentedPostResumeResizeCandidate = candidate
            engineLogger.notice(
                "metal_presentation_drawable_observed post_resume=true resume=\(self.presentationResumeGeneration, privacy: .public) request=\(candidate.requestID, privacy: .public) drawable=\(self.drawableSizeDescription(presentedDrawableSize), privacy: .public) source=display_link_presented"
            )
        }

        if applyingPendingDrawableSizeAtEngineBoundary {
            pendingDrawableAgeRequestID = request.requestID
            pendingDrawableAgeTicks = 0
            lastOwnerAppliedDrawableRequestID = max(
                lastOwnerAppliedDrawableRequestID,
                request.requestID
            )
        } else if !presentationPaused,
                  awaitingPostResumeResizeAcknowledgement,
                  request.requestID > lastOwnerAppliedDrawableRequestID,
                  postResumeResizeCandidate == nil,
                  drawableSizeChanged(request.size, from: presentationResumeBaselineSize) {
            postResumeResizeCandidate = request
            engineLogger.notice(
                "metal_presentation_resize_observed post_resume=true resume=\(self.presentationResumeGeneration, privacy: .public) request=\(request.requestID, privacy: .public) drawable=\(self.drawableSizeDescription(request.size), privacy: .public) source=display_link_post_present"
            )
        }
        return request.size
    }

    private func drawableSizeChanged(_ size: CGSize, from baseline: CGSize?) -> Bool {
        guard let baseline else { return true }
        return Int(size.width.rounded()) != Int(baseline.width.rounded())
            || Int(size.height.rounded()) != Int(baseline.height.rounded())
    }

    private func drawableSizesMatch(_ lhs: CGSize, _ rhs: CGSize) -> Bool {
        Int(lhs.width.rounded()) == Int(rhs.width.rounded())
            && Int(lhs.height.rounded()) == Int(rhs.height.rounded())
    }

    private func drawableSizeDescription(_ size: CGSize?) -> String {
        guard let size else { return "none" }
        return "\(Int(size.width.rounded()))x\(Int(size.height.rounded()))"
    }

    private static func currentThreadIdentifier() -> UInt64 {
        var identifier: UInt64 = 0
        let result = pthread_threadid_np(nil, &identifier)
        precondition(result == 0, "pthread_threadid_np must produce an owner token")
        return identifier
    }

    private static func copyCString(_ value: String, into destination: UnsafeMutableRawBufferPointer) throws {
        let bytes = Array(value.utf8)
        guard bytes.count < destination.count else {
            throw HostPathError.valueTooLong
        }
        destination.initializeMemory(as: UInt8.self, repeating: 0)
        destination.copyBytes(from: bytes)
    }
}

private struct HostPaths {
    let gameDirectory: String
    let saveDirectory: String

    static func resolve() throws -> HostPaths {
        let environment = ProcessInfo.processInfo.environment

        let gameDirectory = environment["SM64_MODERN_GAME_DIR"]
        guard let gameDirectory else { throw HostPathError.missingGameDirectory }

        let defaultSave = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appending(path: "SM64 Modern", directoryHint: .isDirectory).path
        let saveDirectory = environment["SM64_MODERN_SAVE_DIR"] ?? defaultSave
        try FileManager.default.createDirectory(atPath: saveDirectory, withIntermediateDirectories: true)
        return HostPaths(gameDirectory: gameDirectory, saveDirectory: saveDirectory)
    }
}

private enum HostPathError: LocalizedError {
    case missingGameDirectory
    case valueTooLong

    var errorDescription: String? {
        switch self {
        case .missingGameDirectory:
            "No development game directory was configured"
        case .valueTooLong:
            "A host path exceeds the public C ABI capacity"
        }
    }
}

private extension NSCondition {
    func withLock<T>(_ operation: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try operation()
    }
}
