#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

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

static uint64_t fingerprint = FNV_OFFSET;
static uint64_t byte_count = 0;
static uint64_t raw_byte_count = 0;

static void append_byte(FILE *file, uint8_t value) {
    if (fputc(value, file) == EOF) {
        perror("mario face payload bundle write");
        exit(1);
    }
    fingerprint ^= value;
    fingerprint *= FNV_PRIME;
    byte_count += 1;
}

static void append_u16(FILE *file, uint16_t value) {
    append_byte(file, (uint8_t) value);
    append_byte(file, (uint8_t) (value >> 8));
}

static void append_u32(FILE *file, uint32_t value) {
    append_byte(file, (uint8_t) value);
    append_byte(file, (uint8_t) (value >> 8));
    append_byte(file, (uint8_t) (value >> 16));
    append_byte(file, (uint8_t) (value >> 24));
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

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "usage: %s output.mfpb\n", argv[0]);
        return 2;
    }
    FILE *file = fopen(argv[1], "wb");
    if (file == NULL) {
        perror("mario face payload bundle");
        return 1;
    }

    append_byte(file, 'M');
    append_byte(file, 'F');
    append_byte(file, 'P');
    append_byte(file, 'B');
    append_u32(file, 1);
    append_u32(file, (uint32_t) (sizeof(channels) / sizeof(channels[0]) * 2));

    for (size_t channel_index = 0; channel_index < sizeof(channels) / sizeof(channels[0]); ++channel_index) {
        for (uint32_t bank = 0; bank < 2; ++bank) {
            const struct AnimDataInfo *info = &channels[channel_index].info[bank];
            const uint32_t stride = stride_for_type(info->type);
            const uint32_t value_count = info->count > 0 ? (uint32_t) info->count * stride : 0;
            append_u32(file, channels[channel_index].component_id);
            append_u32(file, bank);
            append_u32(file, info->count > 0 ? (uint32_t) info->count : 0);
            append_u32(file, info->type);
            append_u32(file, stride);
            append_u32(file, value_count);
            const uint16_t *values = info->data;
            for (uint32_t value_index = 0; value_index < value_count; ++value_index) {
                append_u16(file, values[value_index]);
                raw_byte_count += 2;
            }
        }
    }
    if (fclose(file) != 0) {
        perror("mario face payload bundle close");
        return 1;
    }

    printf("marioFacePayloadBundleFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    printf("marioFacePayloadBundleBytes=%llu\n", (unsigned long long) byte_count);
    printf("marioFacePayloadBundleRows=%zu\n", sizeof(channels) / sizeof(channels[0]) * 2);
    printf("marioFacePayloadBundleRawBytes=%llu\n", (unsigned long long) raw_byte_count);
    printf("SM64 Modern Mario face payload bundle C contract passed\n");
    return 0;
}
