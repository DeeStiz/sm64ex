#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define ANIM_EMPTY 0u
#define ANIM_THREE_H_SCALED 6u
#define ANIM_SIX_H_SCALED 8u

struct manifest_entry {
    uint32_t component_id;
    uint32_t animator_id;
    const char *source_path;
    const char *primary_symbol;
    const char *secondary_symbol;
    uint32_t primary_count;
    uint32_t primary_type;
    uint32_t secondary_count;
    uint32_t secondary_type;
    uint32_t primary_stride;
    uint32_t secondary_stride;
};

static const struct manifest_entry entries[] = {
    { 0x07, 0x08, "src/goddard/dynlists/anim_mario_mustache_right.c", "animdata_mario_mustache_right_1", "animdata_mario_mustache_right_2", 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED, 3, 3 },
    { 0x10, 0x11, "src/goddard/dynlists/anim_mario_mustache_left.c", "animdata_mario_mustache_left_1", "animdata_mario_mustache_left_2", 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED, 3, 3 },
    { 0x20, 0x21, "src/goddard/dynlists/anim_mario_lips_1.c", "animdata_mario_lips_1_1", "animdata_mario_lips_1_2", 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED, 3, 3 },
    { 0x29, 0x2A, "src/goddard/dynlists/anim_mario_lips_2.c", "animdata_mario_lips_2_1", "animdata_mario_lips_2_2", 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED, 3, 3 },
    { 0x32, 0x33, "src/goddard/dynlists/anim_mario_eyebrows_1.c", "animdata_mario_eyebrows_1_1", "animdata_mario_eyebrows_1_2", 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED, 3, 3 },
    { 0x3F, 0x40, "src/goddard/dynlists/anim_group_1.c", "animdata_mario_eyebrows_equalizer_1", "", 820, ANIM_THREE_H_SCALED, 0, ANIM_EMPTY, 3, 0 },
    { 0x42, 0x43, "src/goddard/dynlists/anim_group_1.c", "animdata_mario_eyebrows_2_1", "animdata_mario_eyebrows_2_2", 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED, 3, 3 },
    { 0x48, 0x49, "src/goddard/dynlists/anim_group_1.c", "anim_mario_eyebrows_3_1", "", 820, ANIM_THREE_H_SCALED, 0, ANIM_EMPTY, 3, 0 },
    { 0x4B, 0x4C, "src/goddard/dynlists/anim_group_1.c", "animdata_mario_eyebrows_4_1", "animdata_mario_eyebrows_4_2", 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED, 3, 3 },
    { 0x54, 0x55, "src/goddard/dynlists/anim_group_1.c", "animdata_mario_eyebrows_5_1", "", 820, ANIM_THREE_H_SCALED, 0, ANIM_EMPTY, 3, 0 },
    { 0x6B, 0x6C, "src/goddard/dynlists/anim_group_1.c", "animdata_mario_eye_left_1", "animdata_mario_eye_left_2", 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED, 3, 3 },
    { 0x7B, 0x7C, "src/goddard/dynlists/anim_group_1.c", "animdata_mario_eye_right_1", "animdata_mario_eye_right_2", 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED, 3, 3 },
    { 0x84, 0x85, "src/goddard/dynlists/anim_group_1.c", "animdata_mario_hat_1", "animdata_mario_hat_2", 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED, 3, 3 },
    { 0x96, 0x97, "src/goddard/dynlists/anim_group_1.c", "animdata_mario_lips_3_1", "animdata_mario_lips_3_2", 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED, 3, 3 },
    { 0x9F, 0xA0, "src/goddard/dynlists/anim_group_1.c", "animdata_mario_lips_4_1", "animdata_mario_lips_4_2", 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED, 3, 3 },
    { 0xA8, 0xA9, "src/goddard/dynlists/anim_group_1.c", "animdata_mario_ear_left_1", "", 820, ANIM_THREE_H_SCALED, 0, ANIM_EMPTY, 3, 0 },
    { 0xB1, 0xB2, "src/goddard/dynlists/anim_group_2.c", "animdata_mario_ear_right_1", "", 820, ANIM_THREE_H_SCALED, 0, ANIM_EMPTY, 3, 0 },
    { 0xBA, 0xBB, "src/goddard/dynlists/anim_group_2.c", "animdata_mario_nose_1", "animdata_mario_nose_2", 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED, 3, 3 },
    { 0xC3, 0xC4, "src/goddard/dynlists/anim_group_2.c", "animdata_mario_lips_5_1", "animdata_mario_lips_5_2", 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED, 3, 3 },
    { 0xC6, 0xC7, "src/goddard/dynlists/anim_group_2.c", "animdata_mario_lip_6_1", "animdata_mario_lip_6_2", 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED, 3, 3 },
    { 0xCF, 0xD0, "src/goddard/dynlists/anim_group_2.c", "animdata_mario_eyelid_left_1", "animdata_mario_eyelid_left_2", 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED, 3, 3 },
    { 0xD8, 0xD9, "src/goddard/dynlists/anim_group_2.c", "animdata_mario_eyelid_right_1", "animdata_mario_eyelid_right_2", 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED, 3, 3 },
    { 0xE2, 0xE3, "src/goddard/dynlists/anim_group_2.c", "animdata_mario_intro_1", "animdata_mario_intro_2", 820, ANIM_SIX_H_SCALED, 166, ANIM_SIX_H_SCALED, 6, 6 },
    { 0xE5, 0xE6, "src/goddard/dynlists/anim_group_2.c", "animdata_silver_star_1", "animdata_silver_star_2", 820, ANIM_SIX_H_SCALED, 166, ANIM_SIX_H_SCALED, 6, 6 },
    { 0xE8, 0xE9, "src/goddard/dynlists/anim_group_2.c", "animdata_red_star_1", "animdata_red_star_2", 820, ANIM_SIX_H_SCALED, 166, ANIM_SIX_H_SCALED, 6, 6 },
};

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (uint32_t byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_string(uint64_t hash, const char *value) {
    const size_t length = strlen(value);
    hash = hash_u64(hash, length);
    for (size_t index = 0; index < length; ++index) {
        hash = hash_u64(hash, (uint8_t) value[index]);
    }
    return hash;
}

static uint64_t hash_manifest(void) {
    uint64_t hash = hash_u64(FNV_OFFSET, sizeof(entries) / sizeof(entries[0]));
    for (size_t index = 0; index < sizeof(entries) / sizeof(entries[0]); ++index) {
        const struct manifest_entry entry = entries[index];
        const uint32_t values[] = {
            entry.component_id, entry.animator_id, entry.primary_count,
            entry.primary_type, entry.secondary_count, entry.secondary_type,
            entry.primary_stride, entry.secondary_stride,
        };
        for (size_t value_index = 0; value_index < sizeof(values) / sizeof(values[0]); ++value_index) {
            hash = hash_u64(hash, values[value_index]);
        }
        hash = hash_string(hash, entry.source_path);
        hash = hash_string(hash, entry.primary_symbol);
        hash = hash_string(hash, entry.secondary_symbol);
    }
    return hash;
}

int main(void) {
    uint32_t empty_secondary = 0;
    uint32_t scaled_three_h = 0;
    uint32_t scaled_six_h = 0;
    for (size_t index = 0; index < sizeof(entries) / sizeof(entries[0]); ++index) {
        if (entries[index].secondary_count == 0) {
            empty_secondary += 1;
        }
        if (entries[index].primary_type == ANIM_THREE_H_SCALED) {
            scaled_three_h += 1;
        }
        if (entries[index].primary_type == ANIM_SIX_H_SCALED) {
            scaled_six_h += 1;
        }
    }
    printf("marioFaceManifestFingerprint=0x%016llx\n", (unsigned long long) hash_manifest());
    printf("marioFaceManifestEntries=%zu\n", sizeof(entries) / sizeof(entries[0]));
    printf("marioFaceManifestEmptySecondary=%u\n", empty_secondary);
    printf("marioFaceManifestThreeH=%u\n", scaled_three_h);
    printf("marioFaceManifestSixH=%u\n", scaled_six_h);
    printf("SM64 Modern Mario face resource manifest C contract passed\n");
    return 0;
}
