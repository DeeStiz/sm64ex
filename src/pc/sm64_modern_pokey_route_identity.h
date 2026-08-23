#ifndef SM64_MODERN_POKEY_ROUTE_IDENTITY_H
#define SM64_MODERN_POKEY_ROUTE_IDENTITY_H

#include <stdint.h>

#include "sm64_modern.h"

#define SM64_MODERN_POKEY_ROUTE_SHARD_ID UINT64_C(0x132a22db8f8e0945)
#define SM64_MODERN_POKEY_ROUTE_INPUT_SEED UINT64_C(0x88bd956f3e11b0e)
#define SM64_MODERN_POKEY_ROUTE_SAVE_SEED UINT64_C(0x2b82b65e014d17b6)
#define SM64_MODERN_POKEY_ROUTE_PARENT_BEHAVIOR_ID \
    UINT64_C(0xd4f1950ecd83e02f) /* bhvPokey */
#define SM64_MODERN_POKEY_ROUTE_CHILD_BEHAVIOR_ID \
    UINT64_C(0x02f9d54516b2cb5a) /* bhvPokeyBodyPart */
#define SM64_MODERN_POKEY_ROUTE_HITBOX_ID \
    UINT64_C(0x12cf919fbb098397) /* sPokeyBodyPartHitbox */

#define SM64_MODERN_POKEY_ROUTE_LEVEL UINT32_C(8) /* LEVEL_SSL */
#define SM64_MODERN_POKEY_ROUTE_AREA UINT32_C(1)
#define SM64_MODERN_POKEY_ROUTE_PARENT_MODEL UINT32_C(0)
#define SM64_MODERN_POKEY_ROUTE_HEAD_MODEL UINT32_C(0x54)
#define SM64_MODERN_POKEY_ROUTE_BODY_MODEL UINT32_C(0x55)
#define SM64_MODERN_POKEY_ROUTE_PARAMETER UINT32_C(0)
#define SM64_MODERN_POKEY_ROUTE_CHILD_COUNT UINT32_C(5)
#define SM64_MODERN_POKEY_ROUTE_INITIAL_MASK UINT32_C(0x1f)

typedef struct SM64ModernPokeyRouteSourceTupleV1 {
    int32_t x;
    int32_t y;
    int32_t z;
    int32_t yaw;
} SM64ModernPokeyRouteSourceTupleV1;

typedef struct SM64ModernPokeyRouteInputV1 {
    uint32_t source_subject;
    uint32_t source_generation;
    uint32_t level;
    uint32_t area;
    uint32_t act;
    uint32_t parent_model;
    uint32_t behavior_parameter;
    uint32_t child_index;
    uint32_t child_model;
    int32_t child_offset_y;
    uint32_t alive_mask_before;
    uint32_t alive_mask_after;
    uint32_t alive_count_before;
    uint32_t alive_count_after;
    uint32_t action_before;
    uint32_t action_after;
    uint32_t timer;
    uint32_t attacked;
    uint32_t should_delete;
    uint64_t parent_behavior_identity;
    uint64_t child_behavior_identity;
    uint64_t hitbox_identity;
} SM64ModernPokeyRouteInputV1;

const SM64ModernPokeyRouteSourceTupleV1 *
sm64_modern_pokey_route_source_tuple(uint32_t ordinal);
SM64ModernStatus sm64_modern_pokey_route_validate(
    const SM64ModernPokeyRouteInputV1 *input);

#endif
