#include <stdint.h>
#include <stdio.h>

#include "src/goddard/dynlists/animdata.h"

/* Compile the checked-in Goddard tables themselves. This inventory contract
 * intentionally reports data only; no graph or renderer code is linked. */
#include "src/goddard/dynlists/anim_mario_mustache_right.c"
#include "src/goddard/dynlists/anim_mario_mustache_left.c"
#include "src/goddard/dynlists/anim_mario_lips_1.c"
#include "src/goddard/dynlists/anim_mario_lips_2.c"
#include "src/goddard/dynlists/anim_mario_eyebrows_1.c"
#include "src/goddard/dynlists/anim_group_1.c"
#include "src/goddard/dynlists/anim_group_2.c"

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct channel_ref {
    uint32_t component_id;
    const struct AnimDataInfo *info;
};

static const struct channel_ref channels[] = {
    { 0x07, anim_mario_mustache_right },
    { 0x10, anim_mario_mustache_left },
    { 0x20, anim_mario_lips_1 },
    { 0x29, anim_mario_lips_2 },
    { 0x32, anim_mario_eyebrows_1 },
    { 0x3F, anim_mario_eyebrows_equalizer },
    { 0x42, anim_mario_eyebrows_2 },
    { 0x48, anim_mario_eyebrows_3 },
    { 0x4B, anim_mario_eyebrows_4 },
    { 0x54, anim_mario_eyebrows_5 },
    { 0x6B, anim_mario_eye_left },
    { 0x7B, anim_mario_eye_right },
    { 0x84, anim_mario_hat },
    { 0x96, anim_mario_lips_3 },
    { 0x9F, anim_mario_lips_4 },
    { 0xA8, anim_mario_ear_left },
    { 0xB1, anim_mario_ear_right },
    { 0xBA, anim_mario_nose },
    { 0xC3, anim_mario_lips_5 },
    { 0xC6, anim_mario_lips_6 },
    { 0xCF, anim_mario_eyelid_left },
    { 0xD8, anim_mario_eyelid_right },
    { 0xE2, anim_mario_intro },
    { 0xE5, anim_silver_star },
    { 0xE8, anim_red_star },
};

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (uint32_t byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint32_t stride_for_type(enum GdAnimations type) {
    switch (type) {
        case GD_ANIM_3H_SCALED:
        case GD_ANIM_3H:
            return 3;
        case GD_ANIM_6H_SCALED:
        case GD_ANIM_CAMERA:
            return 6;
        default:
            return 0;
    }
}

static uint64_t hash_bank(const struct AnimDataInfo *info, uint32_t stride) {
    uint64_t hash = FNV_OFFSET;
    const uint32_t value_count = info->count > 0 ? (uint32_t) info->count * stride : 0;
    const uint16_t *values = info->data;
    for (uint32_t index = 0; index < value_count; ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return info->count > 0 ? hash : 0;
}

int main(void) {
    uint64_t aggregate = FNV_OFFSET;
    uint64_t total_bytes = 0;
    uint32_t rows = 0;
    printf("SM64FACEINV|1|%zu\n", sizeof(channels) / sizeof(channels[0]));
    for (size_t channel_index = 0; channel_index < sizeof(channels) / sizeof(channels[0]); ++channel_index) {
        for (uint32_t bank = 0; bank < 2; ++bank) {
            const struct AnimDataInfo *info = &channels[channel_index].info[bank];
            const uint32_t stride = stride_for_type(info->type);
            const uint64_t byte_count = info->count > 0 ? (uint64_t) info->count * stride * sizeof(int16_t) : 0;
            const uint64_t hash = hash_bank(info, stride);
            aggregate = hash_u64(aggregate, channels[channel_index].component_id);
            aggregate = hash_u64(aggregate, bank);
            aggregate = hash_u64(aggregate, info->count);
            aggregate = hash_u64(aggregate, info->type);
            aggregate = hash_u64(aggregate, stride);
            aggregate = hash_u64(aggregate, byte_count);
            aggregate = hash_u64(aggregate, hash);
            total_bytes += byte_count;
            rows += 1;
            printf("ROW|%u|%u|%d|%u|%u|%llu|0x%016llx\n",
                   channels[channel_index].component_id, bank, info->count,
                   (unsigned) info->type, stride,
                   (unsigned long long) byte_count, (unsigned long long) hash);
        }
    }
    printf("TOTAL|%u|%llu|0x%016llx\n", rows, (unsigned long long) total_bytes, (unsigned long long) aggregate);
    return 0;
}
