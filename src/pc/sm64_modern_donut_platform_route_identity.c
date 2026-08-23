#include <stddef.h>

#include "pc/sm64_modern_donut_platform_route_identity.h"

/* Copied source values from sDonutPlatformPositions[0...30]. */
static const int16_t sSourcePositions[31][3] = {
    { 0x0B4C, 0xF7D7, 0x19A4 }, { 0xF794, 0x08A3, 0xFFA9 },
    { 0x069C, 0x09D8, 0xFFE0 }, { 0x05CF, 0x09D8, 0xFFE0 },
    { 0x0502, 0x09D8, 0xFFE0 }, { 0x054C, 0xF7D7, 0x19A4 },
    { 0x0A7F, 0xF7D7, 0x19A4 }, { 0x09B2, 0xF7D7, 0x19A4 },
    { 0x06E6, 0xF7D7, 0x19A4 }, { 0x0619, 0xF7D7, 0x19A4 },
    { 0xEFB5, 0xF7D7, 0x19A4 }, { 0x00E6, 0xF7D7, 0x19A4 },
    { 0x0019, 0xF7D7, 0x19A4 }, { 0xFF4D, 0xF7D7, 0x19A4 },
    { 0xF081, 0xF7D7, 0x19A4 }, { 0xE34F, 0xF671, 0x197A },
    { 0xEEE8, 0xF7D7, 0x19A4 }, { 0xE74F, 0xF7D7, 0x197A },
    { 0xE683, 0xF7D7, 0x197A }, { 0xE5B6, 0xF7D7, 0x197A },
    { 0xEE83, 0xF4A4, 0x19A4 }, { 0xE41C, 0xF671, 0x197A },
    { 0xE4E9, 0xF671, 0x197A }, { 0xECE9, 0xF4A4, 0x19A4 },
    { 0xEDB6, 0xF4A4, 0x19A4 }, { 0xFC3F, 0x0A66, 0xFF45 },
    { 0x00EF, 0x04CD, 0xFF53 }, { 0x0022, 0x04CD, 0xFF53 },
    { 0xFF57, 0x04CD, 0xFF53 }, { 0xFB73, 0x0A66, 0xFF45 },
    { 0xFD0C, 0x0A66, 0xFF45 },
};

const int16_t *sm64_modern_donut_platform_source_position(uint32_t index) {
    return index < SM64_MODERN_DONUT_ROUTE_CHILD_COUNT
        ? sSourcePositions[index]
        : NULL;
}

SM64ModernStatus sm64_modern_donut_platform_route_validate(
    const SM64ModernDonutPlatformRouteInputV1 *input) {
    if (!input || input->source_subject == 0u
        || input->source_generation != 1u
        || input->source_order >= SM64_MODERN_DONUT_ROUTE_CHILD_COUNT
        || input->level != SM64_MODERN_DONUT_ROUTE_LEVEL
        || input->area != SM64_MODERN_DONUT_ROUTE_AREA
        || input->act != SM64_MODERN_DONUT_ROUTE_ACT
        || input->parent_model != SM64_MODERN_DONUT_ROUTE_PARENT_MODEL
        || input->behavior_parameter != SM64_MODERN_DONUT_ROUTE_PARAMETER
        || input->parent_behavior_identity
            != SM64_MODERN_DONUT_ROUTE_PARENT_BEHAVIOR_ID
        || input->parent_mask_before
            > SM64_MODERN_DONUT_ROUTE_ALL_CHILDREN_MASK
        || input->parent_mask_after
            > SM64_MODERN_DONUT_ROUTE_ALL_CHILDREN_MASK
        || input->collision_loaded > 1u
        || input->marked_for_deletion > 1u
        || input->exploded > 1u
        || input->coin_count > 1u
        || input->effect_flags > UINT32_C(0x1f)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    if (!input->child_spawned) {
        return input->child_index == 0u && input->child_model == 0u
            && input->child_behavior_identity == 0u
            && input->collision_identity == 0u;
    }

    if (input->child_spawned != 1u
        || input->child_index >= SM64_MODERN_DONUT_ROUTE_CHILD_COUNT
        || input->child_model != SM64_MODERN_DONUT_ROUTE_CHILD_MODEL
        || input->child_behavior_identity
            != SM64_MODERN_DONUT_ROUTE_CHILD_BEHAVIOR_ID
        || input->collision_identity != SM64_MODERN_DONUT_ROUTE_COLLISION_ID
        || input->distance_sq_bits
            <= SM64_MODERN_DONUT_ROUTE_MIN_DISTANCE_SQ_BITS
        || input->distance_sq_bits
            >= SM64_MODERN_DONUT_ROUTE_MAX_DISTANCE_SQ_BITS) {
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }

    return SM64_MODERN_STATUS_OK;
}
