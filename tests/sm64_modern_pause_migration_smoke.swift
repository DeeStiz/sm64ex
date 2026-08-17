import Foundation

private func makeSnapshot(
    tick: UInt64,
    state: UInt32,
    selection: Int32,
    camera: Int32,
    alpha: UInt32,
    active: Bool,
    canExit: Bool,
    confirm: Bool,
    verticalDelta: Int32,
    horizontalDelta: Int32,
    course: Int32,
    minimum: Int32,
    maximum: Int32,
    outcome: Int32
) -> SM64ModernPauseMenuSnapshotV1 {
    var snapshot = SM64ModernPauseMenuSnapshotV1()
    snapshot.header.abi_version = SM64_MODERN_ABI_VERSION_1
    snapshot.header.struct_size = UInt32(
        MemoryLayout<SM64ModernPauseMenuSnapshotV1>.size
    )
    snapshot.simulation_tick = tick
    snapshot.state = state
    snapshot.selection = selection
    snapshot.camera_selection = camera
    snapshot.text_alpha = alpha
    snapshot.menu_mode_active = active ? 1 : 0
    snapshot.can_exit_course = canExit ? 1 : 0
    snapshot.confirm_pressed = confirm ? 1 : 0
    snapshot.vertical_selection_delta = verticalDelta
    snapshot.horizontal_camera_delta = horizontalDelta
    snapshot.course_number = course
    snapshot.course_minimum = minimum
    snapshot.course_maximum = maximum
    snapshot.outcome = outcome
    return snapshot
}

@main
enum SM64ModernPauseMenuMigrationSmoke {
    static func main() {
        var identifier: UInt64 = 0
        precondition(pthread_threadid_np(nil, &identifier) == 0)
        let service = SwiftPauseMenuMigrationService(ownerThreadToken: identifier)
        var api = service.makeAPI()
        precondition(
            sm64_modern_install_pause_menu_migration_api(&api)
                == SM64_MODERN_STATUS_OK
        )

        let snapshots = [
            makeSnapshot(
                tick: 1, state: 0, selection: 1, camera: 1, alpha: 0,
                active: true, canExit: false, confirm: false,
                verticalDelta: 0, horizontalDelta: 0,
                course: 1, minimum: 1, maximum: 15, outcome: 0
            ),
            makeSnapshot(
                tick: 2, state: 1, selection: 1, camera: 1, alpha: 25,
                active: true, canExit: true, confirm: false,
                verticalDelta: 1, horizontalDelta: 0,
                course: 1, minimum: 1, maximum: 15, outcome: 0
            ),
            makeSnapshot(
                tick: 3, state: 0, selection: 2, camera: 1, alpha: 50,
                active: false, canExit: true, confirm: true,
                verticalDelta: 0, horizontalDelta: 0,
                course: 1, minimum: 1, maximum: 15, outcome: 2
            ),
            makeSnapshot(
                tick: 4, state: 2, selection: 1, camera: 2, alpha: 100,
                active: true, canExit: false, confirm: false,
                verticalDelta: 0, horizontalDelta: 1,
                course: 0, minimum: 1, maximum: 15, outcome: 0
            ),
            makeSnapshot(
                tick: 5, state: 0, selection: 1, camera: 2, alpha: 125,
                active: false, canExit: false, confirm: true,
                verticalDelta: 0, horizontalDelta: 0,
                course: 0, minimum: 1, maximum: 15, outcome: 1
            )
        ]
        for var snapshot in snapshots {
            precondition(
                sm64_modern_pause_menu_observe_snapshot(&snapshot)
                    == SM64_MODERN_STATUS_OK
            )
        }

        let summary = service.summary()
        precondition(summary.events == snapshots.count)
        precondition(summary.outcomes == 2)
        precondition(summary.state == 0)
        sm64_modern_uninstall_pause_menu_migration_api()

        print("pauseMenuMigrationFingerprint=0x\(String(summary.fingerprint, radix: 16))")
        print("pauseMenuMigrationEvents=\(summary.events)")
        print("pauseMenuMigrationOutcomes=\(summary.outcomes)")
        print("SM64 Modern pause menu migration smoke passed")
    }
}
