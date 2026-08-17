#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "sm64_modern.h"
#include "pc/sm64_modern_audio_migration.h"

struct QueueEntry {
    uint8_t priority;
    uint8_t sequence_id;
};

static struct QueueEntry queue[6];
static uint32_t queue_count;
static uint8_t player_sequences[4] = { 0xff, 0xff, 0xff, 0xff };
static uint16_t current_background_music = UINT16_MAX;
static uint64_t fingerprint = UINT64_C(1469598103934665603);

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (int shift = 0; shift <= 56; shift += 8) {
        hash ^= (value >> shift) & UINT64_C(0xff);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static void enqueue(uint16_t sequence_arguments) {
    if (queue_count >= 6) return;
    const uint8_t sequence_id = (uint8_t) sequence_arguments;
    const uint8_t priority = (uint8_t) (sequence_arguments >> 8);
    for (uint32_t index = 0; index < queue_count; ++index) {
        if (queue[index].sequence_id == sequence_id) return;
    }
    uint32_t found_index = 0;
    for (uint32_t index = 0; index < queue_count; ++index) {
        if (priority <= queue[index].priority) {
            found_index = index;
            break;
        }
    }
    if (found_index == 0) {
        queue[queue_count++] = (struct QueueEntry){ 0, 0 };
    }
    for (uint32_t index = queue_count - 1; index > found_index; --index) {
        queue[index] = queue[index - 1];
    }
    queue[found_index] = (struct QueueEntry){ priority, sequence_id };
}

static void stop_sequence(uint8_t sequence_id) {
    uint32_t found_index = queue_count;
    for (uint32_t index = 0; index < queue_count; ++index) {
        if (queue[index].sequence_id == sequence_id) {
            found_index = index;
            break;
        }
    }
    if (found_index == queue_count) return;
    for (uint32_t index = found_index; index + 1 < queue_count; ++index) {
        queue[index] = queue[index + 1];
    }
    --queue_count;
}

static SM64ModernStatus observe(
    void *context,
    const SM64ModernAudioSequenceEventV1 *event) {
    (void) context;
    if (!event || event->header.abi_version != SM64_MODERN_ABI_VERSION_1
        || event->header.struct_size < sizeof(*event)
        || event->reserved != 0) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    switch (event->event_id) {
    case SM64_MODERN_AUDIO_SEQUENCE_EVENT_TICK:
        if (event->value_count < 3) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
        current_background_music = (uint16_t) event->values[2];
        break;
    case SM64_MODERN_AUDIO_SEQUENCE_EVENT_SEQUENCE:
        if (event->value_count < 5 || event->values[0] >= 4) {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
        player_sequences[event->values[0]] = (uint8_t) event->values[1];
        break;
    case SM64_MODERN_AUDIO_SEQUENCE_EVENT_QUEUE:
        if (event->value_count >= 5) {
            if (event->values[0] >= 4) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
            if (event->values[0] == 0) enqueue((uint16_t) event->values[1]);
        } else if (event->value_count == 3
                   && event->values[1] <= 6
                   && event->values[2] == current_background_music) {
            stop_sequence((uint8_t) event->values[0]);
        } else {
            return SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
        break;
    case SM64_MODERN_AUDIO_SEQUENCE_EVENT_SECONDARY:
        if (event->value_count < 4) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
        break;
    default:
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    fingerprint = hash_u64(fingerprint, event->simulation_tick);
    fingerprint = hash_u64(fingerprint, event->event_id);
    fingerprint = hash_u64(fingerprint, event->value_count);
    for (uint32_t index = 0; index < event->value_count; ++index) {
        fingerprint = hash_u64(fingerprint, event->values[index]);
    }
    fingerprint = hash_u64(fingerprint, queue_count);
    for (uint32_t index = 0; index < queue_count; ++index) {
        fingerprint = hash_u64(fingerprint, queue[index].priority);
        fingerprint = hash_u64(fingerprint, queue[index].sequence_id);
    }
    fingerprint = hash_u64(fingerprint, 4);
    for (uint32_t index = 0; index < 4; ++index) {
        fingerprint = hash_u64(fingerprint, player_sequences[index]);
    }
    fingerprint = hash_u64(fingerprint, current_background_music);
    return SM64_MODERN_STATUS_OK;
}

static int expect(const char *operation, SM64ModernStatus actual,
                  SM64ModernStatus expected) {
    if (actual == expected) return 0;
    fprintf(stderr, "%s: got %u expected %u\n", operation, actual, expected);
    return 1;
}

int main(void) {
    SM64ModernAudioMigrationApiV1 api;
    memset(&api, 0, sizeof(api));
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    api.header.struct_size = sizeof(api);
    api.observe_sequence_event = observe;
    if (expect("validate", sm64_modern_validate_audio_migration_api(&api),
               SM64_MODERN_STATUS_OK)) return 1;
    if (expect("install", sm64_modern_install_audio_migration_api(&api),
               SM64_MODERN_STATUS_OK)) return 1;

    const uint64_t events[][8] = {
        { 60, 0x1234, 0x0402 },
        { 0, 0x0402, 0, 0, 0x0402 },
        { 0, 2, 0, 1, 1 },
        { 0, 0x0205, 0, 1, 0x0402 },
        { 5, 2, 0x0402 },
        { 7, 0x80, 0x60, 12 }
    };
    const uint32_t ids[] = {
        SM64_MODERN_AUDIO_SEQUENCE_EVENT_TICK,
        SM64_MODERN_AUDIO_SEQUENCE_EVENT_QUEUE,
        SM64_MODERN_AUDIO_SEQUENCE_EVENT_SEQUENCE,
        SM64_MODERN_AUDIO_SEQUENCE_EVENT_QUEUE,
        SM64_MODERN_AUDIO_SEQUENCE_EVENT_QUEUE,
        SM64_MODERN_AUDIO_SEQUENCE_EVENT_SECONDARY
    };
    const uint32_t counts[] = { 3, 5, 5, 5, 3, 4 };
    const uint64_t ticks[] = { 1, 1, 1, 2, 2, 3 };
    for (uint32_t index = 0; index < 6; ++index) {
        if (expect("observe", sm64_modern_audio_observe_sequence_event(
                       ids[index], ticks[index], events[index], counts[index]),
                   SM64_MODERN_STATUS_OK)) return 1;
    }
    if (fingerprint != UINT64_C(0x175790b07cad64f)) {
        fprintf(stderr, "fingerprint mismatch: 0x%llx\n",
                (unsigned long long) fingerprint);
        return 1;
    }
    if (expect("invalid_count", sm64_modern_audio_observe_sequence_event(
                   SM64_MODERN_AUDIO_SEQUENCE_EVENT_TICK, 4, events[0], 9),
               SM64_MODERN_STATUS_INVALID_ARGUMENT)) return 1;
    if (expect("status", sm64_modern_audio_migration_status(),
               SM64_MODERN_STATUS_INVALID_ARGUMENT)) return 1;
    sm64_modern_uninstall_audio_migration_api();
    if (expect("uninstalled_observe", sm64_modern_audio_observe_sequence_event(
                   SM64_MODERN_AUDIO_SEQUENCE_EVENT_TICK, 5, events[0], 3),
               SM64_MODERN_STATUS_OK)) return 1;
    printf("audioSequenceMigrationFingerprint=0x%llx\n",
           (unsigned long long) fingerprint);
    printf("SM64 Modern audio migration C contract passed\n");
    return 0;
}
