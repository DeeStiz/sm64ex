#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "sm64_modern.h"
#include "pc/sm64_modern_progression_migration.h"

static unsigned gCallbackCount;
static SM64ModernProgressionEventV1 gLastEvent;
static SM64ModernStatus gCallbackStatus = SM64_MODERN_STATUS_OK;

uint64_t sm64_modern_oracle_trace_simulation_tick(void) {
    return UINT64_C(17);
}

static SM64ModernStatus record_event(
    void *context, const SM64ModernProgressionEventV1 *event) {
    if (context != (void *) (uintptr_t) 0x1234 || !event) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    gCallbackCount++;
    memcpy(&gLastEvent, event, sizeof(gLastEvent));
    return gCallbackStatus;
}

static void expect(int condition, const char *message) {
    if (!condition) {
        fprintf(stderr, "progression migration smoke failed: %s\n", message);
        __builtin_trap();
    }
}

int main(void) {
    SM64ModernProgressionMigrationApiV1 api;
    memset(&api, 0, sizeof(api));
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    api.header.struct_size = sizeof(api);
    api.context = (void *) (uintptr_t) 0x1234;
    api.record_event = record_event;

    expect(sm64_modern_validate_progression_migration_api(&api)
               == SM64_MODERN_STATUS_OK,
           "valid api");
    expect(sm64_modern_progression_migration_status()
               == SM64_MODERN_STATUS_INVALID_STATE,
           "cold status");
    expect(sm64_modern_install_progression_migration_api(&api)
               == SM64_MODERN_STATUS_OK,
           "install");
    expect(sm64_modern_install_progression_migration_api(&api)
               == SM64_MODERN_STATUS_INVALID_STATE,
           "duplicate install");
    expect(sm64_modern_progression_migration_status()
               == SM64_MODERN_STATUS_OK,
           "installed status");

    expect(sm64_modern_progression_record_event(
               SM64_MODERN_PROGRESSION_EVENT_LEVEL_REWARD,
               2, 7, SM64_MODERN_PROGRESSION_COLLECTION_KEY_1,
               3, 120, 130, 0, 0x40u) == SM64_MODERN_STATUS_OK,
           "event callback");
    expect(gCallbackCount == 1, "callback count");
    expect(gLastEvent.header.abi_version == SM64_MODERN_ABI_VERSION_1,
           "event abi");
    expect(gLastEvent.header.struct_size == sizeof(gLastEvent),
           "event size");
    expect(gLastEvent.simulation_tick == 17, "event tick");
    expect(gLastEvent.event_kind == SM64_MODERN_PROGRESSION_EVENT_LEVEL_REWARD,
           "event kind");
    expect(gLastEvent.save_file_index == 2 && gLastEvent.course_number == 7,
           "event identity");
    expect(gLastEvent.collection_kind == SM64_MODERN_PROGRESSION_COLLECTION_KEY_1,
           "event collection");
    expect(gLastEvent.star_index == 3 && gLastEvent.coin_score == 120
               && gLastEvent.global_max_coin_score == 130,
           "event reward values");
    expect(gLastEvent.flags == 0x40u, "event flags");

    expect(sm64_modern_progression_record_event(
               SM64_MODERN_PROGRESSION_EVENT_SAVE_MUTATION,
               0, 0, 0, -1, 0, 0, 0,
               SM64_MODERN_PROGRESSION_SAVE_MUTATION_STARS)
               == SM64_MODERN_STATUS_OK,
           "mutation callback");
    expect(gCallbackCount == 2
               && gLastEvent.event_kind
                   == SM64_MODERN_PROGRESSION_EVENT_SAVE_MUTATION,
           "mutation event kind");
    expect(sm64_modern_progression_record_event(
               SM64_MODERN_PROGRESSION_EVENT_SAVE_MUTATION + 1u,
               0, 0, 0, -1, 0, 0, 0, 0)
               == SM64_MODERN_STATUS_INVALID_ARGUMENT,
           "unknown event kind");
    expect(sm64_modern_progression_migration_status()
               == SM64_MODERN_STATUS_INVALID_ARGUMENT,
           "unknown event latch");
    sm64_modern_uninstall_progression_migration_api();
    expect(sm64_modern_install_progression_migration_api(&api)
               == SM64_MODERN_STATUS_OK,
           "reinstall after invalid event");

    gCallbackStatus = SM64_MODERN_STATUS_PLATFORM_ERROR;
    expect(sm64_modern_progression_record_event(
               SM64_MODERN_PROGRESSION_EVENT_SAVE_PERSIST,
               0, 0, 0, -1, 0, 0, 0, 0) == SM64_MODERN_STATUS_PLATFORM_ERROR,
           "callback failure");
    expect(sm64_modern_progression_migration_status()
               == SM64_MODERN_STATUS_PLATFORM_ERROR,
           "latched failure");
    sm64_modern_uninstall_progression_migration_api();
    expect(sm64_modern_progression_migration_status()
               == SM64_MODERN_STATUS_INVALID_STATE,
           "uninstalled status");
    expect(sm64_modern_progression_migration_active_status()
               == SM64_MODERN_STATUS_OK,
           "inactive status");
    puts("progressionMigrationFingerprint=0x5f56c0c4d6b0e8b1");
    return 0;
}
