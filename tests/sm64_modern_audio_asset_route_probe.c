#include <inttypes.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sm64_modern.h"
#include "engine/behavior_script.h"
#include "pc/sm64_modern_audio_pcm_migration.h"
#include "pc/sm64_modern_gameplay_parity.h"
#include "pc/sm64_modern_timebase.h"

/*
 * Phase 85ar is a source-identity reachability probe, not a route fixture.
 * The selected source asset is the US high-score sequence.  A real native
 * gameplay lifecycle must emit the sequence-12 audio receipt before a C/Swift
 * schema-4 pair can be attempted.  This probe never calls play_sequence(),
 * play_star_fanfare(), injects a star/save state, or fabricates a PCM record.
 */
#define AUDIO_ASSET_ROUTE_SHARD_ID UINT64_C(0x03345fc560c65b75)
#define AUDIO_ASSET_INPUT_SEED UINT64_C(0x014f93c6ae7e2e59)
#define AUDIO_ASSET_SAVE_SEED UINT64_C(0x2a3582ec48614066)
#define AUDIO_ASSET_SEQUENCE_ID UINT64_C(0x12)
#define AUDIO_ASSET_TRACE_STEPS 720u
#define AUDIO_ASSET_SOURCE_PATH "sound/sequences/us/12_event_high_score.m64"
#define AUDIO_ASSET_SOURCE_SHA256 \
    "2e0170f20353d6ba772af9df92f2d53e8b8d807e2b5bca24ac87bc022f08fade"

struct ProbeState {
    FILE *trace_file;
    FILE *pcm_trace_file;
    FILE *receipt_file;
    uint64_t records;
    uint64_t audio_sequence_records;
    uint64_t audio_pcm_records;
    uint64_t pcm_receipts;
    uint64_t audio_asset_sequence_records;
    uint64_t first_asset_tick;
    uint64_t last_asset_tick;
    uint64_t audio_play_callbacks;
    uint64_t audio_play_frames;
    uint64_t pcm_trace_records;
    uint64_t header_coverage_fingerprint;
    uint64_t unrelated_records;
    uint64_t owner_thread;
    bool have_owner_thread;
    uint32_t errors;
};

static uint64_t fnv_string(const char *value) {
    uint64_t hash = UINT64_C(1469598103934665603);
    for (const unsigned char *cursor = (const unsigned char *) value;
         cursor && *cursor;
         ++cursor) {
        hash ^= *cursor;
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static uint64_t thread_token(void) {
    return (uint64_t) (uintptr_t) pthread_self();
}

static bool owner_thread(struct ProbeState *state) {
    const uint64_t current = thread_token();
    if (!state->have_owner_thread) {
        state->owner_thread = current;
        state->have_owner_thread = true;
        return true;
    }
    if (state->owner_thread != current) {
        state->errors++;
        return false;
    }
    return true;
}

static bool valid_trace_record(const SM64ModernOracleTraceRecordV1 *record) {
    return record
        && record->header.abi_version == SM64_MODERN_ABI_VERSION_1
        && record->header.struct_size >= sizeof(*record)
        && record->domain < SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT
        && record->record_kind >= SM64_MODERN_ORACLE_RECORD_STATE
        && record->record_kind <= SM64_MODERN_ORACLE_RECORD_COVERAGE
        && record->value_count <= SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY
        && record->canonical_hash == sm64_modern_oracle_trace_hash_record(record);
}

static SM64ModernStatus trace_write_header(
    void *context, const SM64ModernOracleTraceConfigV1 *config) {
    struct ProbeState *state = context;
    const char *mode = getenv("SM64_MODERN_ORACLE_AUDIO_ASSET_ONLY");
    const bool audio_asset_only = mode && strcmp(mode, "1") == 0;
    if (!state || !config
        || config->mode != SM64_MODERN_ORACLE_TRACE_RECORD
        || config->schema_version != SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION
        || (audio_asset_only && config->coverage_fingerprint == 0u)
        || (!audio_asset_only && config->coverage_fingerprint != 0u)
        || !state->trace_file) {
        if (state) state->errors++;
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    state->header_coverage_fingerprint = config->coverage_fingerprint;
    if (fwrite(config, sizeof(*config), 1, state->trace_file) != 1) {
        return SM64_MODERN_STATUS_PLATFORM_ERROR;
    }
    if (state->pcm_trace_file
        && fwrite(config, sizeof(*config), 1, state->pcm_trace_file) != 1) {
        return SM64_MODERN_STATUS_PLATFORM_ERROR;
    }
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus trace_write_record(
    void *context, const SM64ModernOracleTraceRecordV1 *record) {
    struct ProbeState *state = context;
    if (!state || !valid_trace_record(record) || !state->trace_file) {
        if (state) state->errors++;
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    state->records++;
    const char *mode = getenv("SM64_MODERN_ORACLE_AUDIO_ASSET_ONLY");
    if (mode && strcmp(mode, "1") == 0
        && record->domain != SM64_MODERN_ORACLE_DOMAIN_AUDIO) {
        state->unrelated_records++;
        state->errors++;
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (record->domain == SM64_MODERN_ORACLE_DOMAIN_AUDIO
        && record->record_kind == SM64_MODERN_ORACLE_RECORD_EVENT) {
        if (record->record_id == SM64_MODERN_ORACLE_AUDIO_EVENT_SEQUENCE) {
            state->audio_sequence_records++;
            /* The sequence receipt's second value is the authored seq ID. */
            if (record->value_count >= 2u
                && record->values[1] == AUDIO_ASSET_SEQUENCE_ID) {
                state->audio_asset_sequence_records++;
                if (state->first_asset_tick == 0u) {
                    state->first_asset_tick = record->simulation_tick;
                }
                state->last_asset_tick = record->simulation_tick;
            }
        }
    } else if (record->domain == SM64_MODERN_ORACLE_DOMAIN_AUDIO
               && record->record_kind == SM64_MODERN_ORACLE_RECORD_AUDIO_PCM
               && record->record_id == SM64_MODERN_ORACLE_AUDIO_EVENT_PCM) {
        state->audio_pcm_records++;
    }
    if (fwrite(record, sizeof(*record), 1, state->trace_file) != 1) {
        return SM64_MODERN_STATUS_PLATFORM_ERROR;
    }
    if (record->domain == SM64_MODERN_ORACLE_DOMAIN_AUDIO
        && record->record_kind == SM64_MODERN_ORACLE_RECORD_AUDIO_PCM
        && record->record_id == SM64_MODERN_ORACLE_AUDIO_EVENT_PCM) {
        state->pcm_trace_records++;
        if (state->pcm_trace_file
            && fwrite(record, sizeof(*record), 1, state->pcm_trace_file) != 1) {
            return SM64_MODERN_STATUS_PLATFORM_ERROR;
        }
    }
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernOracleTraceStreamApiV1 trace_stream(struct ProbeState *state) {
    SM64ModernOracleTraceStreamApiV1 stream;
    memset(&stream, 0, sizeof(stream));
    stream.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    stream.header.struct_size = sizeof(stream);
    stream.context = state;
    stream.write_header = trace_write_header;
    stream.write_record = trace_write_record;
    return stream;
}

static SM64ModernStatus input_read(
    void *context, SM64ModernInputSnapshotV1 *snapshot) {
    (void) context;
    if (!snapshot) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    memset(snapshot, 0, sizeof(*snapshot));
    snapshot->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    snapshot->header.struct_size = sizeof(*snapshot);
    snapshot->last_virtual_key = SM64_MODERN_INPUT_NO_KEY;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus platform_initialize(void *context, const char *title) {
    (void) context;
    (void) title;
    return SM64_MODERN_STATUS_OK;
}

static void platform_shutdown(void *context) { (void) context; }
static int32_t platform_audio_buffered(void *context) { (void) context; return 0; }
static uint32_t platform_audio_desired(void *context) { (void) context; return 0; }

static void platform_audio_play(
    void *context, const int16_t *samples, uint32_t frame_count) {
    struct ProbeState *state = context;
    if (!state || !samples || frame_count == 0u || !owner_thread(state)) {
        if (state) state->errors++;
        return;
    }
    state->audio_play_callbacks++;
    state->audio_play_frames += frame_count;
}

static uint64_t platform_current_thread(void *context) {
    struct ProbeState *state = context;
    if (state) (void) owner_thread(state);
    return thread_token();
}

static void platform_exit_requested(void *context, SM64ModernExitReason reason) {
    (void) context;
    (void) reason;
}

static void platform_error(
    void *context, SM64ModernStatus status, const char *message) {
    (void) status;
    (void) message;
    struct ProbeState *state = context;
    if (state) state->errors++;
}

static SM64ModernPlatformApiV1 platform_api(struct ProbeState *state) {
    SM64ModernPlatformApiV1 api;
    memset(&api, 0, sizeof(api));
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    api.header.struct_size = sizeof(api);
    api.capabilities = SM64_MODERN_PLATFORM_CAP_INPUT
        | SM64_MODERN_PLATFORM_CAP_AUDIO;
    api.context = state;
    api.initialize = platform_initialize;
    api.shutdown = platform_shutdown;
    api.audio_buffered = platform_audio_buffered;
    api.audio_desired_buffered = platform_audio_desired;
    api.audio_play = platform_audio_play;
    api.current_thread = platform_current_thread;
    api.exit_requested = platform_exit_requested;
    api.error_reported = platform_error;
    return api;
}

static SM64ModernStatus observe_pcm_receipt(
    void *context, const SM64ModernAudioPCMReceiptV1 *receipt) {
    struct ProbeState *state = context;
    if (!state || !receipt
        || receipt->header.abi_version != SM64_MODERN_ABI_VERSION_1
        || receipt->header.struct_size < sizeof(*receipt)
        || receipt->frame_count == 0u
        || receipt->sample_rate_hz != SM64_MODERN_AUDIO_PCM_SAMPLE_RATE_HZ
        || receipt->channel_count != SM64_MODERN_AUDIO_PCM_CHANNEL_COUNT
        || receipt->sample_format != SM64_MODERN_AUDIO_PCM_FORMAT_S16_INTERLEAVED_STEREO
        || receipt->reserved != 0u
        || !owner_thread(state)) {
        if (state) state->errors++;
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    state->pcm_receipts++;
    if (state->receipt_file
        && fwrite(receipt, sizeof(*receipt), 1, state->receipt_file) != 1) {
        state->errors++;
        return SM64_MODERN_STATUS_PLATFORM_ERROR;
    }
    return SM64_MODERN_STATUS_OK;
}

static bool configure_timebase(uint64_t *out_fingerprint) {
    SM64ModernTimebaseApiV1 api;
    memset(&api, 0, sizeof(api));
    if (sm64_modern_get_timebase_api(
            SM64_MODERN_ABI_VERSION_1, sizeof(api), &api)
        != SM64_MODERN_STATUS_OK) {
        return false;
    }
    SM64ModernTimebaseConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.simulation_rate_numerator = 60u;
    config.simulation_rate_denominator = 1u;
    config.legacy_rate_numerator = 30u;
    config.legacy_rate_denominator = 1u;
    config.max_catch_up_steps = 2u;
    if (api.configure(&config) != SM64_MODERN_STATUS_OK) return false;
    SM64ModernTimebaseSnapshotV1 snapshot;
    memset(&snapshot, 0, sizeof(snapshot));
    if (api.get_snapshot(&snapshot) != SM64_MODERN_STATUS_OK
        || snapshot.simulation_ticks_per_legacy_tick != 2u) {
        return false;
    }
    if (out_fingerprint) *out_fingerprint = snapshot.fingerprint;
    return true;
}

static SM64ModernLifecycleConfigV1 lifecycle_config(const char *save_directory) {
    SM64ModernLifecycleConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.fullscreen_mode = SM64_MODERN_FULLSCREEN_FORCE_OFF;
    config.skip_intro = 1u;
    snprintf(config.game_directory, sizeof(config.game_directory), "%s", "res");
    snprintf(config.save_directory, sizeof(config.save_directory), "%s", save_directory);
    snprintf(config.config_file, sizeof(config.config_file), "%s",
             "sm64-modern-audio-asset-route-probe.cfg");
    snprintf(config.window_title, sizeof(config.window_title), "%s",
             "SM64 Modern Audio Asset Route Probe");
    return config;
}

static SM64ModernOracleTraceConfigV1 trace_config(uint64_t timebase_fingerprint) {
    SM64ModernOracleTraceConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION;
    config.region_code = UINT32_C(0x5553);
    config.mode = SM64_MODERN_ORACLE_TRACE_RECORD;
    config.build_fingerprint = fnv_string("sm64-modern-audio-asset-route-v1");
    char content[256];
    snprintf(content, sizeof(content), "%s|sha256=%s",
             AUDIO_ASSET_SOURCE_PATH, AUDIO_ASSET_SOURCE_SHA256);
    config.content_fingerprint = fnv_string(content);
    config.timebase_fingerprint = timebase_fingerprint;
    char configuration[512];
    snprintf(configuration, sizeof(configuration),
             "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
             "input_seed=0x%016" PRIx64 ";save_seed=0x%016" PRIx64
             ";shard=0x%016" PRIx64 ";asset=%s;asset_sha256=%s",
             AUDIO_ASSET_INPUT_SEED, AUDIO_ASSET_SAVE_SEED,
             AUDIO_ASSET_ROUTE_SHARD_ID, AUDIO_ASSET_SOURCE_PATH,
             AUDIO_ASSET_SOURCE_SHA256);
    config.configuration_fingerprint = fnv_string(configuration);
    const char *audio_asset_mode = getenv("SM64_MODERN_ORACLE_AUDIO_ASSET_ONLY");
    if (audio_asset_mode && strcmp(audio_asset_mode, "1") == 0) {
    // The oracle owns the source-backed audio-only coverage contract and fills
    // this field immediately before the header is emitted. Keeping the probe
    // input zero avoids duplicating the inventory hash in a second owner.
    config.coverage_fingerprint = 0;
    }
    char initial_save[128];
    snprintf(initial_save, sizeof(initial_save),
             "save=empty-us-slot-0;seed=0x%016" PRIx64,
             AUDIO_ASSET_SAVE_SEED);
    config.initial_save_fingerprint = fnv_string(initial_save);
    return config;
}

static bool record_probe(
    const char *trace_path,
    const char *save_directory,
    const char *pcm_trace_path,
    const char *receipt_path) {
    uint64_t timebase_fingerprint = 0;
    if (!configure_timebase(&timebase_fingerprint)) return false;

    struct ProbeState state;
    memset(&state, 0, sizeof(state));
    state.trace_file = fopen(trace_path, "wb");
    if (!state.trace_file) return false;
    if (pcm_trace_path) {
        state.pcm_trace_file = fopen(pcm_trace_path, "wb");
    }
    if (receipt_path) {
        state.receipt_file = fopen(receipt_path, "wb");
    }
    if ((pcm_trace_path && !state.pcm_trace_file)
        || (receipt_path && !state.receipt_file)) {
        if (state.pcm_trace_file) fclose(state.pcm_trace_file);
        if (state.receipt_file) fclose(state.receipt_file);
        fclose(state.trace_file);
        return false;
    }

    SM64ModernInputApiV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.context = &state;
    input.read = input_read;

    SM64ModernAudioPCMMigrationApiV1 pcm_migration;
    memset(&pcm_migration, 0, sizeof(pcm_migration));
    pcm_migration.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    pcm_migration.header.struct_size = sizeof(pcm_migration);
    pcm_migration.context = &state;
    pcm_migration.observe_pcm_receipt = observe_pcm_receipt;

    const SM64ModernPlatformApiV1 platform = platform_api(&state);
    const SM64ModernOracleTraceStreamApiV1 stream = trace_stream(&state);
    bool ok = sm64_modern_install_input_api(&input) == SM64_MODERN_STATUS_OK
        && sm64_modern_install_audio_pcm_migration_api(&pcm_migration)
            == SM64_MODERN_STATUS_OK;

    SM64ModernLifecycleApiV1 lifecycle;
    memset(&lifecycle, 0, sizeof(lifecycle));
    ok = ok && sm64_modern_get_lifecycle_api(
        SM64_MODERN_ABI_VERSION_1, sizeof(lifecycle), &lifecycle)
        == SM64_MODERN_STATUS_OK;
    SM64ModernOracleTraceConfigV1 config = trace_config(timebase_fingerprint);
    if (ok) {
        setenv("SM64_MODERN_AUTOMATED_GAMEPLAY", "1", 1);
        const SM64ModernLifecycleConfigV1 lifecycle_value =
            lifecycle_config(save_directory);
        const SM64ModernStatus init_status = lifecycle.initialize(
            &lifecycle_value, &platform);
        ok = init_status == SM64_MODERN_STATUS_OK;
        if (ok) {
            random_seed_set((uint16_t) (AUDIO_ASSET_INPUT_SEED & UINT64_C(0xffff)));
            ok = sm64_modern_oracle_trace_begin(&config, &stream)
                == SM64_MODERN_STATUS_OK;
            for (uint32_t step = 0; ok && step < AUDIO_ASSET_TRACE_STEPS; ++step) {
                const SM64ModernStatus status = lifecycle.step();
                if (status != SM64_MODERN_STATUS_OK) ok = false;
            }
            ok = lifecycle.shutdown() == SM64_MODERN_STATUS_OK && ok;
        }
    }

    const SM64ModernStatus oracle_end = sm64_modern_oracle_trace_is_active()
        ? sm64_modern_oracle_trace_end() : sm64_modern_oracle_trace_status();
    SM64ModernOracleTraceResultV1 result;
    memset(&result, 0, sizeof(result));
    (void) sm64_modern_oracle_trace_get_result(&result);
    sm64_modern_uninstall_input_api();
    sm64_modern_uninstall_audio_pcm_migration_api();
    const bool trace_closed = fclose(state.trace_file) == 0;
    state.trace_file = NULL;
    const bool pcm_trace_closed = !state.pcm_trace_file
        || fclose(state.pcm_trace_file) == 0;
    state.pcm_trace_file = NULL;
    const bool receipt_closed = !state.receipt_file
        || fclose(state.receipt_file) == 0;
    state.receipt_file = NULL;
    const bool trace_ok = oracle_end == SM64_MODERN_STATUS_OK
        && result.status == SM64_MODERN_STATUS_OK
        && result.coverage_fingerprint != 0u
        && state.header_coverage_fingerprint == result.coverage_fingerprint
        && state.unrelated_records == 0u
        && state.errors == 0u
        && state.have_owner_thread
        && state.audio_pcm_records == state.pcm_receipts
        && state.audio_pcm_records == state.pcm_trace_records
        && state.audio_pcm_records > 0u;
    printf(
        "audio_asset_route_probe shard=0x%016" PRIx64
        " source=%s source_sha256=%s input_seed=0x%016" PRIx64
        " save_seed=0x%016" PRIx64 " steps=%u records=%" PRIu64
        " audio_sequence=%" PRIu64 " audio_pcm=%" PRIu64
        " pcm_receipts=%" PRIu64 " sequence12=%" PRIu64
        " asset_ticks=%" PRIu64 ",%" PRIu64
        " audio_play_callbacks=%" PRIu64 " audio_play_frames=%" PRIu64
        " pcm_trace_records=%" PRIu64
        " coverage=0x%016" PRIx64
        " oracle_end=%u result_status=%u errors=%u\n",
        AUDIO_ASSET_ROUTE_SHARD_ID, AUDIO_ASSET_SOURCE_PATH,
        AUDIO_ASSET_SOURCE_SHA256, AUDIO_ASSET_INPUT_SEED,
        AUDIO_ASSET_SAVE_SEED, AUDIO_ASSET_TRACE_STEPS, state.records,
        state.audio_sequence_records, state.audio_pcm_records,
        state.pcm_receipts, state.audio_asset_sequence_records,
        state.first_asset_tick, state.last_asset_tick,
        state.audio_play_callbacks, state.audio_play_frames,
        state.pcm_trace_records, result.coverage_fingerprint,
        oracle_end, result.status, state.errors);
    return ok && trace_closed && pcm_trace_closed && receipt_closed && trace_ok;
}

int main(int argc, char **argv) {
    if (argc != 3 && argc != 5) {
        fprintf(stderr,
                "usage: sm64-modern-audio-asset-route-probe TRACE SAVE_DIRECTORY [PCM_TRACE RECEIPTS]\n");
        return 2;
    }
    return record_probe(
        argv[1], argv[2], argc == 5 ? argv[3] : NULL,
        argc == 5 ? argv[4] : NULL) ? 0 : 1;
}
