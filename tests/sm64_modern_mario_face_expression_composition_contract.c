#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "src/goddard/dynlists/animdata.h"

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

struct scenario {
    uint32_t bank;
    uint32_t frame_q16;
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

static uint32_t float_bits(float value) {
    uint32_t bits = 0;
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

static const struct AnimDataInfo *selected_info(const struct channel_ref *channel, uint32_t bank) {
    return bank < 2 ? &channel->info[bank] : NULL;
}

static int is_decodable(const struct AnimDataInfo *info, uint32_t current_frame) {
    return info != NULL && info->count > 1 && current_frame > 0
        && current_frame <= (uint32_t) info->count;
}

static uint64_t compose_packet(uint64_t hash, struct scenario scenario) {
    const uint32_t current_frame = scenario.frame_q16 >> 16;
    const uint32_t fraction_q16 = scenario.frame_q16 & UINT32_C(0xffff);
    uint64_t channel_mask = 0;
    uint32_t resident_count = 0;
    for (size_t index = 0; index < sizeof(channels) / sizeof(channels[0]); ++index) {
        if (is_decodable(selected_info(&channels[index], scenario.bank), current_frame)) {
            channel_mask |= UINT64_C(1) << index;
            resident_count += 1;
        }
    }
    hash = hash_u64(hash, scenario.bank);
    hash = hash_u64(hash, scenario.frame_q16);
    hash = hash_u64(hash, (uint32_t) channel_mask);
    hash = hash_u64(hash, (uint32_t) (channel_mask >> 32));
    hash = hash_u64(hash, resident_count);
    hash = hash_u64(hash, (uint32_t) (sizeof(channels) / sizeof(channels[0])) - resident_count);

    for (size_t index = 0; index < sizeof(channels) / sizeof(channels[0]); ++index) {
        const struct AnimDataInfo *info = selected_info(&channels[index], scenario.bank);
        const int available = is_decodable(info, current_frame);
        const uint32_t type = available ? (uint32_t) info->type : 0;
        const uint32_t stride = available ? stride_for_type(info->type) : 0;
        const uint32_t next_frame = available && current_frame == (uint32_t) info->count
            ? 1 : current_frame + 1;
        const uint32_t source_frame = available ? current_frame : 0;
        const uint32_t source_next = available ? next_frame : 0;
        const uint32_t value_count = available ? stride : 0;
        const float fraction = (float) fraction_q16 / 65536.0f;
        hash = hash_u64(hash, channels[index].component_id);
        hash = hash_u64(hash, scenario.bank);
        hash = hash_u64(hash, available ? 1 : 0);
        hash = hash_u64(hash, type);
        hash = hash_u64(hash, source_frame);
        hash = hash_u64(hash, source_next);
        hash = hash_u64(hash, fraction_q16);
        hash = hash_u64(hash, value_count);
        if (!available) {
            continue;
        }
        const uint16_t *values = info->data;
        const uint32_t current_offset = (current_frame - 1) * stride;
        const uint32_t next_offset = (next_frame - 1) * stride;
        for (uint32_t component = 0; component < stride; ++component) {
            const float current = (float) (int16_t) values[current_offset + component];
            const float next = (float) (int16_t) values[next_offset + component];
            float interpolated = current + (next - current) * fraction;
            if (component < 3) {
                interpolated *= 0.1f;
            }
            hash = hash_u64(hash, float_bits(interpolated));
        }
    }
    return hash;
}

int main(void) {
    const struct scenario scenarios[] = {
        { 0, (1u << 16) | 0x8000u },
        { 0, (820u << 16) | 0x8000u },
        { 1, (165u << 16) | 0x4000u },
        { 1, (166u << 16) | 0x8000u },
        { 2, (1u << 16) | 0x8000u },
    };
    uint64_t seed = hash_u64(FNV_OFFSET, sizeof(channels) / sizeof(channels[0]));
    for (size_t index = 0; index < sizeof(channels) / sizeof(channels[0]); ++index) {
        seed = hash_u64(seed, channels[index].component_id);
    }
    uint64_t fingerprint = seed;
    for (size_t index = 0; index < sizeof(scenarios) / sizeof(scenarios[0]); ++index) {
        fingerprint = compose_packet(fingerprint, scenarios[index]);
    }
    printf("marioFaceExpressionCompositionSeed=0x%016llx\n", (unsigned long long) seed);
    printf("marioFaceExpressionCompositionFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    printf("marioFaceExpressionCompositionScenarios=%zu\n", sizeof(scenarios) / sizeof(scenarios[0]));
    printf("marioFaceExpressionCompositionChannels=%zu\n", sizeof(channels) / sizeof(channels[0]));
    printf("SM64 Modern Mario face expression composition C contract passed\n");
    return 0;
}
