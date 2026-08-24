#include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "levels/castle_inside/header.h"
#include "pc/sm64_modern_display_list_next_route_identity.h"

#define ROUTE_TICKS 2u
#define ROUTE_DOMAIN SM64_MODERN_ORACLE_DOMAIN_RENDER
#define ROUTE_KIND SM64_MODERN_ORACLE_RECORD_RENDER_PACKET
#define ROUTE_FNV_OFFSET UINT64_C(1469598103934665603)
#define ROUTE_FNV_PRIME UINT64_C(1099511628211)

struct TraceFile {
    FILE *file;
    uint64_t records;
    uint64_t last_tick;
    uint32_t failures;
    bool have_record;
};

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (uint32_t byte = 0; byte < 4u; ++byte) {
        hash ^= (uint64_t) ((value >> (byte * 8u)) & 0xffu);
        hash *= ROUTE_FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_string(const char *value) {
    uint64_t hash = ROUTE_FNV_OFFSET;
    for (const unsigned char *cursor = (const unsigned char *) value;
         cursor && *cursor;
         ++cursor) {
        hash ^= *cursor;
        hash *= ROUTE_FNV_PRIME;
    }
    return hash;
}

static uint64_t resource_fingerprint(
    const SM64ModernDisplayListNextRoutePacketV1 *packet) {
    uint64_t hash = ROUTE_FNV_OFFSET;
    for (uint32_t index = 0; index < packet->word_count; ++index) {
        hash = hash_u32(hash, packet->resource_ids[index]);
    }
    return hash;
}

static bool write_bytes(struct TraceFile *trace, const void *data, size_t size) {
    return trace && trace->file && data && fwrite(data, 1, size, trace->file) == size;
}

static bool valid_record(const SM64ModernOracleTraceRecordV1 *record) {
    return record
        && record->header.abi_version == SM64_MODERN_ABI_VERSION_1
        && record->header.struct_size >= sizeof(*record)
        && record->simulation_tick >= 1u
        && record->simulation_tick <= ROUTE_TICKS
        && record->domain == ROUTE_DOMAIN
        && record->record_kind == ROUTE_KIND
        && record->subject_id == SM64_MODERN_DISPLAY_LIST_NEXT_ROUTE_SHARD_ID
        && record->record_id == SM64_MODERN_DISPLAY_LIST_NEXT_ROUTE_EVENT
        && record->value_count == 8u
        && record->canonical_hash == sm64_modern_oracle_trace_hash_record(record);
}

static SM64ModernStatus trace_write_header(
    void *context,
    const SM64ModernOracleTraceConfigV1 *config) {
    struct TraceFile *trace = context;
    if (!trace || !config
        || config->header.abi_version != SM64_MODERN_ABI_VERSION_1
        || config->header.struct_size < sizeof(*config)
        || config->schema_version != SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION
        || config->region_code != 0x5553u
        || config->mode != SM64_MODERN_ORACLE_TRACE_RECORD
        || config->build_fingerprint != hash_string(
            "sm64-modern-display-list-next-route-build-v1")
        || config->content_fingerprint != hash_string(
            "levels/castle_inside/areas/1/2/model.inc.c|"
            "inside_castle_seg7_dl_070287C0|render_packet")
        || config->configuration_fingerprint != hash_string(
            "region=5553;fullscreen=off;skip_intro=1;"
            "shard=0x00a5aebe36897ac4;parent=inside_castle_seg7_dl_07028FD0;layer=1")
        || config->initial_save_fingerprint != hash_string(
            "save=empty-us-slot-0;seed=0x7684a9567f71ff45")
        || config->coverage_fingerprint != 0u) {
        if (trace) trace->failures++;
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    return write_bytes(trace, config, sizeof(*config))
        ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_PLATFORM_ERROR;
}

static SM64ModernStatus trace_write_record(
    void *context,
    const SM64ModernOracleTraceRecordV1 *record) {
    struct TraceFile *trace = context;
    if (!trace || !valid_record(record)) {
        if (trace) trace->failures++;
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (!trace->have_record) {
        if (record->simulation_tick != 1u || record->sequence != 0u) {
            trace->failures++;
            return SM64_MODERN_STATUS_PARITY_DIVERGED;
        }
    } else if (record->simulation_tick != trace->last_tick + 1u
               || record->sequence != 0u) {
        trace->failures++;
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    if (!write_bytes(trace, record, sizeof(*record))) {
        trace->failures++;
        return SM64_MODERN_STATUS_PLATFORM_ERROR;
    }
    trace->records++;
    trace->last_tick = record->simulation_tick;
    trace->have_record = true;
    return SM64_MODERN_STATUS_OK;
}

static void write_hex_u32(FILE *file, uint32_t value) {
    fprintf(file, "%08" PRIx32, value);
}

static bool write_packet_sidecar(const char *path) {
    const SM64ModernDisplayListNextRoutePacketV1 *packet =
        sm64_modern_display_list_next_route_last_packet();
    FILE *file = fopen(path, "wb");
    if (!file) return false;

    fprintf(file,
        "source_identity=0x%016" PRIx64
        "|owner_identity=0x%016" PRIx64
        "|word_count=%" PRIu32
        "|drawing_layer=%" PRIu32
        "|triangle_count=%" PRIu32
        "|flags=%" PRIu32
        "|packet_fingerprint=0x%016" PRIx64
        "|words=",
        packet->source_identity,
        packet->owner_identity,
        packet->word_count,
        packet->drawing_layer,
        packet->triangle_count,
        packet->flags,
        packet->packet_fingerprint);
    for (uint32_t index = 0; index < packet->word_count * 2u; ++index) {
        if (index != 0u) fputc(',', file);
        write_hex_u32(file, packet->words[index]);
    }
    fputs("|resources=", file);
    for (uint32_t index = 0; index < packet->word_count; ++index) {
        if (index != 0u) fputc(',', file);
        write_hex_u32(file, packet->resource_ids[index]);
    }
    fputc('\n', file);
    return fclose(file) == 0;
}

static SM64ModernOracleTraceConfigV1 route_config(void) {
    SM64ModernOracleTraceConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION;
    config.region_code = 0x5553u;
    config.mode = SM64_MODERN_ORACLE_TRACE_RECORD;
    config.build_fingerprint = hash_string(
        "sm64-modern-display-list-next-route-build-v1");
    config.content_fingerprint = hash_string(
        "levels/castle_inside/areas/1/2/model.inc.c|"
        "inside_castle_seg7_dl_070287C0|render_packet");
    config.timebase_fingerprint = hash_u32(hash_u32(ROUTE_FNV_OFFSET, 60u), 30u);
    config.configuration_fingerprint = hash_string(
        "region=5553;fullscreen=off;skip_intro=1;"
        "shard=0x00a5aebe36897ac4;parent=inside_castle_seg7_dl_07028FD0;layer=1");
    config.initial_save_fingerprint = hash_string(
        "save=empty-us-slot-0;seed=0x7684a9567f71ff45");
    config.coverage_fingerprint = 0u;
    return config;
}

static int run_route(const char *trace_path, const char *packet_path) {
    struct TraceFile trace = {0};
    trace.file = fopen(trace_path, "wb");
    if (!trace.file) return 2;

    const SM64ModernOracleTraceConfigV1 config = route_config();
    const SM64ModernOracleTraceStreamApiV1 stream = {
        .header = {
            .abi_version = SM64_MODERN_ABI_VERSION_1,
            .struct_size = sizeof(stream),
        },
        .context = &trace,
        .write_header = trace_write_header,
        .read_header = NULL,
        .write_record = trace_write_record,
        .read_record = NULL,
    };

    sm64_modern_display_list_next_route_reset();
    sm64_modern_oracle_trace_reset();
    SM64ModernStatus status = sm64_modern_oracle_trace_begin(&config, &stream);
    if (status != SM64_MODERN_STATUS_OK) {
        fclose(trace.file);
        return 3;
    }

    for (uint64_t tick = 1u; tick <= ROUTE_TICKS; ++tick) {
        sm64_modern_oracle_trace_begin_tick();
        status = sm64_modern_display_list_next_route_observe_scene_graph_append(
            inside_castle_seg7_dl_07028FD0, 1u);
        sm64_modern_oracle_trace_end_tick();
        if (status != SM64_MODERN_STATUS_OK) {
            fprintf(stderr,
                "display_list_next_route_step tick=%" PRIu64
                " status=%" PRIu32 "\n", tick, status);
            sm64_modern_oracle_trace_end();
            fclose(trace.file);
            return 4;
        }
    }

    status = sm64_modern_oracle_trace_end();
    fflush(trace.file);
    fclose(trace.file);
    const SM64ModernDisplayListNextRoutePacketV1 *packet =
        sm64_modern_display_list_next_route_last_packet();
    const bool packet_values_are_canonical =
        packet->source_identity == SM64_MODERN_DISPLAY_LIST_NEXT_ROUTE_SOURCE_ID
        && packet->owner_identity == SM64_MODERN_DISPLAY_LIST_NEXT_ROUTE_OWNER_ID
        && packet->word_count == 8u
        && packet->drawing_layer == 1u
        && packet->triangle_count == 4u
        && packet->flags == 3u
        && packet->resource_ids[0] == SM64_MODERN_DISPLAY_LIST_NEXT_ROUTE_TEXTURE_RESOURCE_ID
        && packet->resource_ids[3] == SM64_MODERN_DISPLAY_LIST_NEXT_ROUTE_LIGHT_RESOURCE_ID
        && packet->resource_ids[4] == SM64_MODERN_DISPLAY_LIST_NEXT_ROUTE_AMBIENT_RESOURCE_ID
        && packet->resource_ids[5] == SM64_MODERN_DISPLAY_LIST_NEXT_ROUTE_VERTEX_RESOURCE_ID;
    if (status != SM64_MODERN_STATUS_OK
        || trace.failures != 0u
        || trace.records != ROUTE_TICKS
        || sm64_modern_display_list_next_route_matches() != ROUTE_TICKS
        || sm64_modern_display_list_next_route_invocations() != ROUTE_TICKS
        || !packet_values_are_canonical
        || !write_packet_sidecar(packet_path)) {
        fprintf(stderr,
            "display_list_next_route_debug oracle_end=%" PRIu32
            " trace_status=%" PRIu32
            " records=%" PRIu64
            " invocations=%" PRIu32
            " matches=%" PRIu32
            " failures=%" PRIu32 "\n",
            status,
            sm64_modern_oracle_trace_status(),
            trace.records,
            sm64_modern_display_list_next_route_invocations(),
            sm64_modern_display_list_next_route_matches(),
            trace.failures);
        return 5;
    }

    printf(
        "c_display_list_next_route_recorded shard=0x%016" PRIx64
        " records=%" PRIu64 " ticks=1,2 source=0x%016" PRIx64
        " owner=0x%016" PRIx64 " words=%" PRIu32
        " triangles=%" PRIu32 " packet=0x%016" PRIx64
        " resource=0x%016" PRIx64 "\n",
        SM64_MODERN_DISPLAY_LIST_NEXT_ROUTE_SHARD_ID,
        trace.records,
        packet->source_identity,
        packet->owner_identity,
        packet->word_count,
        packet->triangle_count,
        packet->packet_fingerprint,
        resource_fingerprint(packet));
    printf(
        "display_list_next_route_debug oracle_end=0 result_status=0 records=%" PRIu64
        " invocations=%" PRIu32 " matches=%" PRIu32 " failures=0\n",
        trace.records,
        sm64_modern_display_list_next_route_invocations(),
        sm64_modern_display_list_next_route_matches());

    const uint32_t matches = sm64_modern_display_list_next_route_matches();
    sm64_modern_display_list_next_route_observe_scene_graph_append(NULL, 1u);
    sm64_modern_display_list_next_route_observe_scene_graph_append(
        sm64_modern_inside_castle_display_list_070287C0_source(), 1u);
    if (sm64_modern_display_list_next_route_matches() != matches) {
        fprintf(stderr, "display_list_next_route_owner_fence_failed=1\n");
        return 6;
    }
    printf("display_list_next_route_owner_fence=1 pointer_free_packet=1\n");
    return 0;
}

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr, "usage: %s TRACE PACKET_SIDECAR\n", argv[0]);
        return 64;
    }
    return run_route(argv[1], argv[2]);
}
