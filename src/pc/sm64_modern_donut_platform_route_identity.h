#ifndef SM64_MODERN_DONUT_PLATFORM_ROUTE_IDENTITY_H
#define SM64_MODERN_DONUT_PLATFORM_ROUTE_IDENTITY_H

#include <stdint.h>

#include "sm64_modern.h"

/* Private value-only schema for the authored Rainbow Ride donut spawner. */
#define SM64_MODERN_DONUT_ROUTE_SHARD_ID UINT64_C(0x0114376397887ece)
#define SM64_MODERN_DONUT_ROUTE_INPUT_SEED UINT64_C(0x27d6933446a8918a)
#define SM64_MODERN_DONUT_ROUTE_SAVE_SEED UINT64_C(0xf4deeec2364eb433)
#define SM64_MODERN_DONUT_ROUTE_PARENT_BEHAVIOR_ID \
    UINT64_C(0xb89a584a58be7f64) /* bhvDonutPlatformSpawner */
#define SM64_MODERN_DONUT_ROUTE_CHILD_BEHAVIOR_ID \
    UINT64_C(0xc64efae40e66f6a0) /* bhvDonutPlatform */
#define SM64_MODERN_DONUT_ROUTE_COLLISION_ID \
    UINT64_C(0x6f109fd6259228fc) /* rr_seg7_collision_donut_platform */

#define SM64_MODERN_DONUT_ROUTE_LEVEL UINT32_C(15) /* LEVEL_RR */
#define SM64_MODERN_DONUT_ROUTE_AREA UINT32_C(1)
#define SM64_MODERN_DONUT_ROUTE_ACT UINT32_C(1)
#define SM64_MODERN_DONUT_ROUTE_PARENT_MODEL UINT32_C(0)
#define SM64_MODERN_DONUT_ROUTE_CHILD_MODEL UINT32_C(0x3f)
#define SM64_MODERN_DONUT_ROUTE_PARAMETER UINT32_C(0)
#define SM64_MODERN_DONUT_ROUTE_CHILD_COUNT UINT32_C(31)
#define SM64_MODERN_DONUT_ROUTE_ALL_CHILDREN_MASK UINT32_C(0x7fffffff)
#define SM64_MODERN_DONUT_ROUTE_MIN_DISTANCE_SQ_BITS UINT32_C(0x49742400)
#define SM64_MODERN_DONUT_ROUTE_MAX_DISTANCE_SQ_BITS UINT32_C(0x4a742400)

typedef struct SM64ModernDonutPlatformRouteInputV1 {
    uint32_t source_subject;
    uint32_t source_generation;
    uint32_t source_order;
    uint32_t level;
    uint32_t area;
    uint32_t act;
    uint32_t parent_model;
    uint32_t behavior_parameter;
    uint32_t parent_mask_before;
    uint32_t parent_mask_after;
    uint32_t child_spawned;
    uint32_t child_index;
    uint32_t child_model;
    uint64_t parent_behavior_identity;
    uint64_t child_behavior_identity;
    uint64_t collision_identity;
    uint32_t distance_sq_bits;
    uint32_t collision_loaded;
    uint32_t marked_for_deletion;
    uint32_t exploded;
    uint32_t coin_count;
    uint32_t effect_flags;
} SM64ModernDonutPlatformRouteInputV1;

typedef struct SM64ModernDonutPlatformRouteReceiptV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint64_t invocation;
    uint64_t source_identity;
    uint64_t owner_identity;
    SM64ModernDonutPlatformRouteInputV1 input;
    SM64ModernStatus observe_status;
} SM64ModernDonutPlatformRouteReceiptV1;

const int16_t *sm64_modern_donut_platform_source_position(uint32_t index);
SM64ModernStatus sm64_modern_donut_platform_route_validate(
    const SM64ModernDonutPlatformRouteInputV1 *input);

#endif
