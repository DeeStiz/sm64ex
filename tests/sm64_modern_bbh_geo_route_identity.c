#include <inttypes.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <ultra64.h>
#include "sm64_modern.h"
#include "engine/graph_node.h"
#include "game/area.h"
#include "level_table.h"

/*
 * This is an authored-lifecycle identity probe for the representative
 * levels/bbh/geo.c route.  It deliberately retains only fixed-width scene
 * values after the native level script has invoked the production geo path;
 * it never calls process_geo_layout, reads command bytes, or constructs
 * fixture content.  Schema-4 C/Swift pairing is deferred until the selected
 * source resource and the runtime root identify the same area.
 */
#define BBH_GEO_SOURCE_SEGMENTED_ADDRESS UINT32_C(0x0e000f00)
#define BBH_GEO_EXPECTED_AREA_INDEX UINT8_C(1)

struct ProbeState {
    uint32_t errors;
};

struct FixedScene {
    uint32_t type;
    uint8_t area;
    int16_t x;
    int16_t y;
    int16_t width;
    int16_t height;
    int16_t views;
    bool has_views;
    uint64_t fingerprint;
};

static SM64ModernStatus platform_initialize(void *context, const char *title) {
    (void) context;
    (void) title;
    return SM64_MODERN_STATUS_OK;
}

static void platform_shutdown(void *context) {
    (void) context;
}

static uint64_t platform_current_thread(void *context) {
    (void) context;
    return (uint64_t) (uintptr_t) pthread_self();
}

static void platform_exit_requested(void *context, SM64ModernExitReason reason) {
    (void) context;
    (void) reason;
}

static void platform_error(void *context, SM64ModernStatus status, const char *message) {
    struct ProbeState *state = context;
    if (state) state->errors++;
    fprintf(stderr, "bbh_geo_route_platform_error status=%u message=%s\n",
            status, message ? message : "(none)");
}

static SM64ModernPlatformApiV1 platform_api(struct ProbeState *state) {
    SM64ModernPlatformApiV1 api;
    memset(&api, 0, sizeof(api));
    api.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    api.header.struct_size = sizeof(api);
    api.context = state;
    api.initialize = platform_initialize;
    api.shutdown = platform_shutdown;
    api.current_thread = platform_current_thread;
    api.exit_requested = platform_exit_requested;
    api.error_reported = platform_error;
    return api;
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
             "sm64-modern-bbh-geo-route.cfg");
    snprintf(config.window_title, sizeof(config.window_title), "%s",
             "SM64 Modern BBH Geo Route");
    return config;
}

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (uint32_t byte = 0; byte < 8u; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static uint64_t scene_fingerprint(const struct GraphNodeRoot *root) {
    uint64_t hash = UINT64_C(1469598103934665603);
    hash = hash_u64(hash, BBH_GEO_SOURCE_SEGMENTED_ADDRESS);
    hash = hash_u64(hash, root->node.type);
    hash = hash_u64(hash, root->areaIndex);
    hash = hash_u64(hash, (uint16_t) root->x);
    hash = hash_u64(hash, (uint16_t) root->y);
    hash = hash_u64(hash, (uint16_t) root->width);
    hash = hash_u64(hash, (uint16_t) root->height);
    hash = hash_u64(hash, (uint16_t) root->numViews);
    return hash_u64(hash, root->views != NULL ? 1u : 0u);
}

static bool same_scene(
    const struct FixedScene *left,
    const struct FixedScene *right) {
    return left->type == right->type
        && left->area == right->area
        && left->x == right->x
        && left->y == right->y
        && left->width == right->width
        && left->height == right->height
        && left->views == right->views
        && left->has_views == right->has_views
        && left->fingerprint == right->fingerprint;
}

static bool run_probe(const char *variant, const char *save_directory) {
    struct ProbeState state;
    memset(&state, 0, sizeof(state));

    SM64ModernLifecycleApiV1 lifecycle;
    memset(&lifecycle, 0, sizeof(lifecycle));
    if (sm64_modern_get_lifecycle_api(
            SM64_MODERN_ABI_VERSION_1, sizeof(lifecycle), &lifecycle)
        != SM64_MODERN_STATUS_OK) {
        return false;
    }

    if (setenv("SM64_MODERN_AUTOMATED_BBH_GEO", "1", 1) != 0) {
        return false;
    }
    const SM64ModernLifecycleConfigV1 config = lifecycle_config(save_directory);
    const SM64ModernPlatformApiV1 platform = platform_api(&state);
    const SM64ModernStatus init_status = lifecycle.initialize(&config, &platform);
    fprintf(stderr, "bbh_geo_route_init variant=%s status=%u\n", variant, init_status);
    if (init_status != SM64_MODERN_STATUS_OK) return false;

    bool stable = true;
    struct FixedScene first = { 0 };

    for (uint32_t step = 0; step < 2u; ++step) {
        const SM64ModernStatus status = lifecycle.step();
        const struct GraphNodeRoot *root =
            gCurrentArea ? gCurrentArea->unk04 : NULL;
        fprintf(stderr, "bbh_geo_route_step variant=%s index=%u status=%u\n",
                variant, step, status);
        if (status != SM64_MODERN_STATUS_OK || !root
            || gCurrLevelNum != LEVEL_BBH || !gCurrentArea) {
            stable = false;
            continue;
        }

        struct FixedScene current = {
            root->node.type,
            root->areaIndex,
            root->x,
            root->y,
            root->width,
            root->height,
            root->numViews,
            root->views != NULL,
            scene_fingerprint(root),
        };
        if (step == 0u) {
            first = current;
        } else if (!same_scene(&first, &current)) {
            stable = false;
        }
    }

    const SM64ModernStatus shutdown_status = lifecycle.shutdown();
    fprintf(stderr, "bbh_geo_route_shutdown variant=%s status=%u errors=%u\n",
            variant, shutdown_status, state.errors);
    if (shutdown_status != SM64_MODERN_STATUS_OK || state.errors != 0u) return false;

    fprintf(stdout,
            "bbh_geo_route_scene variant=%s level=%d area=%d root_type=0x%x "
            "root_area=%u root_x=%d root_y=%d root_width=%d root_height=%d "
            "views=%d has_views=%u source_segmented=0x%08" PRIx32
            " fingerprint=0x%016" PRIx64 "\n",
            variant, gCurrLevelNum, gCurrAreaIndex, first.type, first.area,
            first.x, first.y, first.width, first.height, first.views,
            first.has_views ? 1u : 0u, BBH_GEO_SOURCE_SEGMENTED_ADDRESS,
            first.fingerprint);

    const bool authored_root = stable && first.type == GRAPH_NODE_TYPE_ROOT
        && first.has_views && first.area == BBH_GEO_EXPECTED_AREA_INDEX;
    if (!authored_root) {
        fprintf(stdout,
                "bbh_geo_route_blocked variant=%s reason=runtime_root_area_identity_mismatch "
                "expected_area=%u actual_area=%u source_resource=levels/bbh/areas/1/geo.inc.c "
                "schema4_pair=deferred\n",
                variant, BBH_GEO_EXPECTED_AREA_INDEX, first.area);
        return true;
    }

    fprintf(stdout,
            "bbh_geo_route_blocked variant=%s reason=source_resource_pair_not_implemented "
            "schema4_pair=deferred\n",
            variant);
    return true;
}

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr, "usage: bbh-geo-route-identity VARIANT SAVE_DIRECTORY\n");
        return 2;
    }
    return run_probe(argv[1], argv[2]) ? 0 : 1;
}
