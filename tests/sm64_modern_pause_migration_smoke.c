#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "sm64_modern.h"
#include "pc/sm64_modern_pause_migration.h"

static uint64_t fingerprint = UINT64_C(1469598103934665603);
static uint32_t event_count;
static uint32_t outcome_count;
static uint32_t last_state;

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (int shift = 0; shift <= 56; shift += 8) {
        hash ^= (value >> shift) & UINT64_C(0xff);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static SM64ModernStatus observe(
    void *context, const SM64ModernPauseMenuSnapshotV1 *snapshot) {
    (void) context;
    if (!snapshot) return SM64_MODERN_STATUS_INVALID_ARGUMENT;

    event_count++;
    outcome_count += snapshot->outcome != 0;
    last_state = snapshot->state;
    fingerprint = hash_u64(fingerprint, snapshot->simulation_tick);
    fingerprint = hash_u64(fingerprint, snapshot->state);
    fingerprint = hash_u64(fingerprint, (uint32_t) snapshot->selection);
    fingerprint = hash_u64(fingerprint, (uint32_t) snapshot->camera_selection);
    fingerprint = hash_u64(fingerprint, snapshot->text_alpha);
    fingerprint = hash_u64(fingerprint, snapshot->menu_mode_active);
    fingerprint = hash_u64(fingerprint, snapshot->can_exit_course);
    fingerprint = hash_u64(fingerprint, snapshot->confirm_pressed);
    fingerprint = hash_u64(fingerprint, (uint32_t) snapshot->vertical_selection_delta);
    fingerprint = hash_u64(fingerprint, (uint32_t) snapshot->horizontal_camera_delta);
    fingerprint = hash_u64(fingerprint, (uint32_t) snapshot->course_number);
    fingerprint = hash_u64(fingerprint, (uint32_t) snapshot->course_minimum);
    fingerprint = hash_u64(fingerprint, (uint32_t) snapshot->course_maximum);
    fingerprint = hash_u64(fingerprint, (uint32_t) snapshot->outcome);
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernPauseMenuSnapshotV1 make_snapshot(
    uint64_t tick, uint32_t state, int32_t selection, int32_t camera,
    uint32_t alpha, uint8_t active, uint8_t can_exit, uint8_t confirm,
    int32_t vertical_delta, int32_t horizontal_delta, int32_t course,
    int32_t minimum, int32_t maximum, int32_t outcome) {
    SM64ModernPauseMenuSnapshotV1 snapshot;
    memset(&snapshot, 0, sizeof(snapshot));
    snapshot.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    snapshot.header.struct_size = sizeof(snapshot);
    snapshot.simulation_tick = tick;
    snapshot.state = state;
    snapshot.selection = selection;
    snapshot.camera_selection = camera;
    snapshot.text_alpha = alpha;
    snapshot.menu_mode_active = active;
    snapshot.can_exit_course = can_exit;
    snapshot.confirm_pressed = confirm;
    snapshot.vertical_selection_delta = vertical_delta;
    snapshot.horizontal_camera_delta = horizontal_delta;
    snapshot.course_number = course;
    snapshot.course_minimum = minimum;
    snapshot.course_maximum = maximum;
    snapshot.outcome = outcome;
    return snapshot;
}

static int expect(const char *operation, SM64ModernStatus actual,
                  SM64ModernStatus expected) {
    if (actual == expected) return 0;
    fprintf(stderr, "%s: got %u expected %u\n", operation, actual, expected);
    return 1;
}

int main(void) {
    SM64ModernPauseMenuMigrationApiV1 api;
    memset(&api, 0, sizeof(api));
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    api.header.struct_size = sizeof(api);
    api.observe = observe;
    if (expect("validate", sm64_modern_validate_pause_menu_migration_api(&api),
               SM64_MODERN_STATUS_OK)) return 1;
    if (expect("install", sm64_modern_install_pause_menu_migration_api(&api),
               SM64_MODERN_STATUS_OK)) return 1;

    const SM64ModernPauseMenuSnapshotV1 snapshots[] = {
        make_snapshot(1, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 15, 0),
        make_snapshot(2, 1, 1, 1, 25, 1, 1, 0, 1, 0, 1, 1, 15, 0),
        make_snapshot(3, 0, 2, 1, 50, 0, 1, 1, 0, 0, 1, 1, 15, 2),
        make_snapshot(4, 2, 1, 2, 100, 1, 0, 0, 0, 1, 0, 1, 15, 0),
        make_snapshot(5, 0, 1, 2, 125, 0, 0, 1, 0, 0, 0, 1, 15, 1),
    };
    for (uint32_t index = 0; index < sizeof(snapshots) / sizeof(snapshots[0]); ++index) {
        if (expect("observe", sm64_modern_pause_menu_observe_snapshot(&snapshots[index]),
                   SM64_MODERN_STATUS_OK)) return 1;
    }
    if (event_count != 5 || outcome_count != 2 || last_state != 0) {
        fprintf(stderr, "pause menu summary mismatch\n");
        return 1;
    }

    SM64ModernPauseMenuSnapshotV1 invalid = snapshots[0];
    invalid.reserved0 = 1;
    if (expect("invalid_reserved", sm64_modern_pause_menu_observe_snapshot(&invalid),
               SM64_MODERN_STATUS_INVALID_ARGUMENT)) return 1;
    if (expect("status", sm64_modern_pause_menu_migration_status(),
               SM64_MODERN_STATUS_INVALID_ARGUMENT)) return 1;
    sm64_modern_uninstall_pause_menu_migration_api();
    printf("pauseMenuMigrationFingerprint=0x%llx\n",
           (unsigned long long) fingerprint);
    printf("SM64 Modern pause menu migration C contract passed\n");
    return 0;
}
