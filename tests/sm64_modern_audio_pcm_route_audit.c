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
 * Phase 85z is an authority audit, not a route-admission fixture.  The
 * lifecycle emits real PCM to platform_audio_play on the owner thread.  This
 * harness counts that pre-device handoff without retaining PCM bytes and
 * counts the schema-4 records that the current production oracle emits.  It
 * deliberately does not call sm64_modern_oracle_trace_record from the audio
 * callback: the existing C owner must first expose an explicit, value-only
 * PCM receipt seam before an independent Swift pair can be admitted.
 */
#define PCM_ROUTE_SHARD_ID UINT64_C(0x4aa75cc09d180fce)
#define PCM_ROUTE_INPUT_SEED UINT64_C(0xc3e64e9c0ec5da8a)
#define PCM_ROUTE_SAVE_SEED UINT64_C(0x0ecb81238dddc733)
#define PCM_ROUTE_SEED16 ((uint16_t)(PCM_ROUTE_INPUT_SEED & UINT64_C(0xffff)))
#define PCM_ROUTE_TRACE_STEPS 2u
#define PCM_EFFECT_ID SM64_MODERN_EFFECT_PCM_CHECKSUM

struct AuditTrace {
    FILE *file;
    FILE *pcm_file;
    FILE *receipt_file;
    uint64_t schema4_records;
    uint64_t schema4_audio_pcm_records;
    uint64_t schema4_effect_pcm_records;
    uint64_t audio_play_callbacks;
    uint64_t audio_play_frames;
    uint64_t pcm_receipts;
    uint64_t pcm_trace_records;
    uint64_t owner_thread;
    bool have_owner_thread;
    uint32_t failures;
};

struct HarnessState {
    uint64_t owner_thread;
    bool have_owner_thread;
    uint32_t errors;
};

struct PlatformContext {
    struct AuditTrace *trace;
    struct HarnessState *state;
};

static uint64_t hash_string(const char *value) {
    uint64_t hash = UINT64_C(1469598103934665603);
    for (const unsigned char *cursor = (const unsigned char *) value;
         cursor && *cursor;
         ++cursor) {
        hash ^= *cursor;
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static bool valid_record(const SM64ModernOracleTraceRecordV1 *record) {
    return record
        && record->header.abi_version == SM64_MODERN_ABI_VERSION_1
        && record->header.struct_size >= sizeof(*record)
        && record->value_count <= SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY
        && record->canonical_hash == sm64_modern_oracle_trace_hash_record(record);
}

static SM64ModernStatus write_header(
    void *context, const SM64ModernOracleTraceConfigV1 *config) {
    struct AuditTrace *trace = context;
    if (!trace || !config
        || config->mode != SM64_MODERN_ORACLE_TRACE_RECORD
        || config->schema_version != SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION
        || config->coverage_fingerprint != 0u) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (fwrite(config, sizeof(*config), 1, trace->file) != 1) {
        return SM64_MODERN_STATUS_PLATFORM_ERROR;
    }
    if (trace->pcm_file
        && fwrite(config, sizeof(*config), 1, trace->pcm_file) != 1) {
        return SM64_MODERN_STATUS_PLATFORM_ERROR;
    }
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus write_record(
    void *context, const SM64ModernOracleTraceRecordV1 *record) {
    struct AuditTrace *trace = context;
    if (!trace || !valid_record(record)) {
        if (trace) {
            trace->failures++;
        }
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    trace->schema4_records++;
    if (record->domain == SM64_MODERN_ORACLE_DOMAIN_AUDIO
        && record->record_kind == SM64_MODERN_ORACLE_RECORD_AUDIO_PCM) {
        trace->schema4_audio_pcm_records++;
    }
    if (record->domain == SM64_MODERN_ORACLE_DOMAIN_EFFECT
        && record->record_kind == SM64_MODERN_ORACLE_RECORD_EFFECT
        && record->record_id == PCM_EFFECT_ID) {
        trace->schema4_effect_pcm_records++;
    }
    if (fwrite(record, sizeof(*record), 1, trace->file) != 1) {
        return SM64_MODERN_STATUS_PLATFORM_ERROR;
    }
    if (record->domain == SM64_MODERN_ORACLE_DOMAIN_AUDIO
        && record->record_kind == SM64_MODERN_ORACLE_RECORD_AUDIO_PCM
        && record->record_id == SM64_MODERN_ORACLE_AUDIO_EVENT_PCM) {
        trace->pcm_trace_records++;
        if (trace->pcm_file
            && fwrite(record, sizeof(*record), 1, trace->pcm_file) != 1) {
            return SM64_MODERN_STATUS_PLATFORM_ERROR;
        }
    }
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernOracleTraceStreamApiV1 make_stream(struct AuditTrace *trace) {
    SM64ModernOracleTraceStreamApiV1 stream;
    memset(&stream, 0, sizeof(stream));
    stream.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    stream.header.struct_size = sizeof(stream);
    stream.context = trace;
    stream.write_header = write_header;
    stream.write_record = write_record;
    return stream;
}

static SM64ModernStatus input_read(
    void *context, SM64ModernInputSnapshotV1 *snapshot) {
    (void) context;
    if (!snapshot) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    memset(snapshot, 0, sizeof(*snapshot));
    snapshot->header.abi_version = SM64_MODERN_ABI_VERSION_1;
    snapshot->header.struct_size = sizeof(*snapshot);
    snapshot->last_virtual_key = SM64_MODERN_INPUT_NO_KEY;
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus platform_initialize(void *context, const char *window_title) {
    (void) context;
    (void) window_title;
    return SM64_MODERN_STATUS_OK;
}

static void platform_shutdown(void *context) {
    (void) context;
}

static int32_t platform_audio_buffered(void *context) {
    (void) context;
    return 0;
}

static uint32_t platform_audio_desired(void *context) {
    (void) context;
    return 0;
}

static void platform_audio_play(
    void *context, const int16_t *samples, uint32_t frame_count) {
    struct PlatformContext *platform = context;
    struct AuditTrace *trace = platform ? platform->trace : NULL;
    if (!trace || !samples || frame_count == 0u) {
        if (trace) {
            trace->failures++;
        }
        return;
    }
    const uint64_t thread = (uint64_t) (uintptr_t) pthread_self();
    if (!trace->have_owner_thread) {
        trace->owner_thread = thread;
        trace->have_owner_thread = true;
    } else if (trace->owner_thread != thread) {
        trace->failures++;
    }
    trace->audio_play_callbacks++;
    trace->audio_play_frames += frame_count;
}

static SM64ModernStatus observe_pcm_receipt(
    void *context, const SM64ModernAudioPCMReceiptV1 *receipt) {
    struct AuditTrace *trace = context;
    if (!trace || !receipt
        || receipt->header.abi_version != SM64_MODERN_ABI_VERSION_1
        || receipt->header.struct_size < sizeof(*receipt)
        || receipt->frame_count == 0u
        || receipt->sample_rate_hz != SM64_MODERN_AUDIO_PCM_SAMPLE_RATE_HZ
        || receipt->channel_count != SM64_MODERN_AUDIO_PCM_CHANNEL_COUNT
        || receipt->sample_format != SM64_MODERN_AUDIO_PCM_FORMAT_S16_INTERLEAVED_STEREO
        || receipt->reserved != 0u) {
        if (trace) {
            trace->failures++;
        }
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    const uint64_t thread = (uint64_t) (uintptr_t) pthread_self();
    if (!trace->have_owner_thread) {
        trace->owner_thread = thread;
        trace->have_owner_thread = true;
    } else if (trace->owner_thread != thread) {
        trace->failures++;
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    if (!trace->receipt_file
        || fwrite(receipt, sizeof(*receipt), 1, trace->receipt_file) != 1) {
        trace->failures++;
        return SM64_MODERN_STATUS_PLATFORM_ERROR;
    }
    trace->pcm_receipts++;
    return SM64_MODERN_STATUS_OK;
}

static uint64_t platform_current_thread(void *context) {
    struct PlatformContext *platform = context;
    struct HarnessState *state = platform ? platform->state : NULL;
    const uint64_t thread = (uint64_t) (uintptr_t) pthread_self();
    if (state) {
        if (!state->have_owner_thread) {
            state->owner_thread = thread;
            state->have_owner_thread = true;
        } else if (state->owner_thread != thread) {
            state->errors++;
        }
    }
    return thread;
}

static void platform_exit_requested(void *context, SM64ModernExitReason reason) {
    (void) context;
    (void) reason;
}

static void platform_error(
    void *context, SM64ModernStatus status, const char *message) {
    (void) status;
    (void) message;
    struct PlatformContext *platform = context;
    struct HarnessState *state = platform ? platform->state : NULL;
    if (state) {
        state->errors++;
    }
}

static SM64ModernPlatformApiV1 make_platform_api(
    struct PlatformContext *platform) {
    SM64ModernPlatformApiV1 api;
    memset(&api, 0, sizeof(api));
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    api.header.struct_size = sizeof(api);
    api.capabilities = SM64_MODERN_PLATFORM_CAP_INPUT
        | SM64_MODERN_PLATFORM_CAP_AUDIO;
    api.context = platform;
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
    if (api.configure(&config) != SM64_MODERN_STATUS_OK) {
        return false;
    }
    SM64ModernTimebaseSnapshotV1 snapshot;
    memset(&snapshot, 0, sizeof(snapshot));
    if (api.get_snapshot(&snapshot) != SM64_MODERN_STATUS_OK) {
        return false;
    }
    if (out_fingerprint) {
        *out_fingerprint = snapshot.fingerprint;
    }
    return snapshot.simulation_ticks_per_legacy_tick == 2u;
}

static bool rewrite_header(
    struct AuditTrace *trace, const SM64ModernOracleTraceConfigV1 *config) {
    return trace && trace->file && config
        && fseek(trace->file, 0, SEEK_SET) == 0
        && fwrite(config, sizeof(*config), 1, trace->file) == 1
        && fflush(trace->file) == 0
        && fseek(trace->file, 0, SEEK_END) == 0;
}

static bool record_audit(
    const char *trace_path,
    const char *save_directory,
    const char *receipt_path,
    const char *pcm_trace_path) {
    uint64_t timebase_fingerprint = 0;
    if (!configure_timebase(&timebase_fingerprint)) {
        return false;
    }

    struct AuditTrace trace;
    memset(&trace, 0, sizeof(trace));
    trace.file = fopen(trace_path, "wb");
    if (!trace.file) {
        return false;
    }
    if (receipt_path) {
        trace.receipt_file = fopen(receipt_path, "wb");
    }
    if (pcm_trace_path) {
        trace.pcm_file = fopen(pcm_trace_path, "wb");
    }
    if ((receipt_path && !trace.receipt_file)
        || (pcm_trace_path && !trace.pcm_file)) {
        if (trace.receipt_file) fclose(trace.receipt_file);
        if (trace.pcm_file) fclose(trace.pcm_file);
        fclose(trace.file);
        return false;
    }

    struct HarnessState state;
    memset(&state, 0, sizeof(state));
    struct PlatformContext platform_context = {
        .trace = &trace,
        .state = &state,
    };
    SM64ModernInputApiV1 input;
    memset(&input, 0, sizeof(input));
    input.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    input.header.struct_size = sizeof(input);
    input.read = input_read;

    SM64ModernOracleTraceConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION;
    config.region_code = UINT32_C(0x5553);
    config.mode = SM64_MODERN_ORACLE_TRACE_RECORD;
    config.build_fingerprint = hash_string("sm64-modern-audio-pcm-route-audit-v1");
    config.content_fingerprint = hash_string(
        "src/pc/sm64_modern_gameplay_parity.c|oracle_hook|audio_pcm");
    config.timebase_fingerprint = timebase_fingerprint;
    char configuration[256];
    snprintf(configuration, sizeof(configuration),
             "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
             "input_seed=0x%016" PRIx64 ";save_seed=0x%016" PRIx64
             ";shard=0x%016" PRIx64,
             PCM_ROUTE_INPUT_SEED, PCM_ROUTE_SAVE_SEED, PCM_ROUTE_SHARD_ID);
    config.configuration_fingerprint = hash_string(configuration);
    char initial_save[128];
    snprintf(initial_save, sizeof(initial_save),
             "save=empty-us-slot-0;seed=0x%016" PRIx64, PCM_ROUTE_SAVE_SEED);
    config.initial_save_fingerprint = hash_string(initial_save);

    const SM64ModernPlatformApiV1 platform = make_platform_api(&platform_context);
    const SM64ModernOracleTraceStreamApiV1 stream = make_stream(&trace);
    SM64ModernAudioPCMMigrationApiV1 pcm_migration;
    memset(&pcm_migration, 0, sizeof(pcm_migration));
    pcm_migration.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    pcm_migration.header.struct_size = sizeof(pcm_migration);
    pcm_migration.context = &trace;
    pcm_migration.observe_pcm_receipt = observe_pcm_receipt;
    bool ok = sm64_modern_install_input_api(&input) == SM64_MODERN_STATUS_OK
        && sm64_modern_get_lifecycle_api(
            SM64_MODERN_ABI_VERSION_1, sizeof(SM64ModernLifecycleApiV1),
            &(SM64ModernLifecycleApiV1) { 0 }) == SM64_MODERN_STATUS_OK;

    SM64ModernLifecycleApiV1 lifecycle;
    memset(&lifecycle, 0, sizeof(lifecycle));
    ok = ok && sm64_modern_get_lifecycle_api(
        SM64_MODERN_ABI_VERSION_1, sizeof(lifecycle), &lifecycle)
        == SM64_MODERN_STATUS_OK;

    SM64ModernLifecycleConfigV1 lifecycle_config;
    memset(&lifecycle_config, 0, sizeof(lifecycle_config));
    lifecycle_config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    lifecycle_config.header.struct_size = sizeof(lifecycle_config);
    lifecycle_config.fullscreen_mode = SM64_MODERN_FULLSCREEN_FORCE_OFF;
    lifecycle_config.skip_intro = 1u;
    snprintf(lifecycle_config.game_directory,
             sizeof(lifecycle_config.game_directory), "%s", "res");
    snprintf(lifecycle_config.save_directory,
             sizeof(lifecycle_config.save_directory), "%s", save_directory);
    snprintf(lifecycle_config.config_file,
             sizeof(lifecycle_config.config_file), "%s",
             "sm64-modern-audio-pcm-route-audit.cfg");
    snprintf(lifecycle_config.window_title,
             sizeof(lifecycle_config.window_title), "%s",
             "SM64 Modern Audio PCM Route Audit");

    if (ok && receipt_path) {
        ok = sm64_modern_install_audio_pcm_migration_api(&pcm_migration)
            == SM64_MODERN_STATUS_OK;
    }
    if (ok) {
        ok = setenv("SM64_MODERN_AUTOMATED_GAMEPLAY", "1", 1) == 0;
        const SM64ModernStatus init_status =
            lifecycle.initialize(&lifecycle_config, &platform);
        fprintf(stderr,
                "audio_pcm_route_init status=%u oracle=%u parity=%u seed16=0x%04x\n",
                init_status, sm64_modern_oracle_trace_status(),
                sm64_modern_parity_status(), PCM_ROUTE_SEED16);
        ok = ok && init_status == SM64_MODERN_STATUS_OK;
        random_seed_set(PCM_ROUTE_SEED16);
        if (ok) {
            ok = sm64_modern_oracle_trace_begin(&config, &stream)
                == SM64_MODERN_STATUS_OK;
            if (ok) {
                sm64_modern_oracle_trace_begin_tick();
                for (uint32_t index = 0;
                     ok && index < PCM_ROUTE_TRACE_STEPS;
                     ++index) {
                    const SM64ModernStatus status = lifecycle.step();
                    fprintf(stderr,
                            "audio_pcm_route_step index=%u status=%u oracle=%u parity=%u\n",
                            index, status, sm64_modern_oracle_trace_status(),
                            sm64_modern_parity_status());
                    ok = status == SM64_MODERN_STATUS_OK;
                }
            }
        }
        if (ok) {
            ok = lifecycle.shutdown() == SM64_MODERN_STATUS_OK;
        }
    }

    const SM64ModernStatus oracle_end = sm64_modern_oracle_trace_is_active()
        ? sm64_modern_oracle_trace_end() : sm64_modern_oracle_trace_status();
    SM64ModernOracleTraceResultV1 result;
    memset(&result, 0, sizeof(result));
    (void) sm64_modern_oracle_trace_get_result(&result);
    fprintf(stderr,
            "audio_pcm_route_debug oracle_end=%u result_status=%u actual=%" PRIu64
            " schema4=%" PRIu64 " audio_pcm=%" PRIu64
            " effect_pcm=%" PRIu64 " audio_play_callbacks=%" PRIu64
            " audio_play_frames=%" PRIu64 " failures=%u owner_errors=%u\n",
            oracle_end, result.status, result.actual_records,
            trace.schema4_records, trace.schema4_audio_pcm_records,
            trace.schema4_effect_pcm_records, trace.audio_play_callbacks,
            trace.audio_play_frames, trace.failures, state.errors);

    ok = ok && oracle_end == SM64_MODERN_STATUS_OK
        && result.status == SM64_MODERN_STATUS_OK
        && trace.failures == 0u
        && state.errors == 0u
        && trace.have_owner_thread
        && trace.audio_play_callbacks == PCM_ROUTE_TRACE_STEPS
        && trace.audio_play_frames == UINT64_C(1088)
        && trace.schema4_audio_pcm_records == PCM_ROUTE_TRACE_STEPS
        && trace.pcm_trace_records == PCM_ROUTE_TRACE_STEPS
        && trace.pcm_receipts == (receipt_path ? PCM_ROUTE_TRACE_STEPS : 0u)
        && trace.schema4_effect_pcm_records == PCM_ROUTE_TRACE_STEPS
        && rewrite_header(&trace, &config);

    sm64_modern_uninstall_input_api();
    if (receipt_path) {
        sm64_modern_uninstall_audio_pcm_migration_api();
    }
    ok = fclose(trace.file) == 0 && ok;
    if (trace.receipt_file) {
        ok = fclose(trace.receipt_file) == 0 && ok;
    }
    if (trace.pcm_file) {
        ok = fclose(trace.pcm_file) == 0 && ok;
    }
    if (!ok) {
        return false;
    }
    printf("audio_pcm_route_audit_recorded shard=0x%016" PRIx64
           " schema4_records=%" PRIu64 " audio_pcm_records=%" PRIu64
           " effect_pcm_records=%" PRIu64 " audio_play_callbacks=%" PRIu64
           " audio_play_frames=%" PRIu64 " pcm_receipts=%" PRIu64
           " pcm_trace_records=%" PRIu64 " swift_pcm_seam=%s\n",
           PCM_ROUTE_SHARD_ID, trace.schema4_records,
           trace.schema4_audio_pcm_records, trace.schema4_effect_pcm_records,
           trace.audio_play_callbacks, trace.audio_play_frames,
           trace.pcm_receipts, trace.pcm_trace_records,
           receipt_path ? "present" : "missing");
    return true;
}

int main(int argc, char **argv) {
    if (argc != 3 && argc != 5) {
        return 2;
    }
    return record_audit(
        argv[1], argv[2], argc == 5 ? argv[3] : NULL,
        argc == 5 ? argv[4] : NULL) ? 0 : 1;
}
