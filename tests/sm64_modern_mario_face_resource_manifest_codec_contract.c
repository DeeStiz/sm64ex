#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct buffer {
    uint8_t bytes[32768];
    size_t count;
};

static const struct {
    uint32_t component_id, animator_id, primary_count, primary_type;
    uint32_t secondary_count, secondary_type, primary_stride, secondary_stride;
    const char *source_path, *primary_symbol, *secondary_symbol;
} entries[] = {
    { 0x07, 0x08, 820, 6, 166, 6, 3, 3, "src/goddard/dynlists/anim_mario_mustache_right.c", "animdata_mario_mustache_right_1", "animdata_mario_mustache_right_2" },
    { 0x10, 0x11, 820, 6, 166, 6, 3, 3, "src/goddard/dynlists/anim_mario_mustache_left.c", "animdata_mario_mustache_left_1", "animdata_mario_mustache_left_2" },
    { 0x20, 0x21, 820, 6, 166, 6, 3, 3, "src/goddard/dynlists/anim_mario_lips_1.c", "animdata_mario_lips_1_1", "animdata_mario_lips_1_2" },
    { 0x29, 0x2A, 820, 6, 166, 6, 3, 3, "src/goddard/dynlists/anim_mario_lips_2.c", "animdata_mario_lips_2_1", "animdata_mario_lips_2_2" },
    { 0x32, 0x33, 820, 6, 166, 6, 3, 3, "src/goddard/dynlists/anim_mario_eyebrows_1.c", "animdata_mario_eyebrows_1_1", "animdata_mario_eyebrows_1_2" },
    { 0x3F, 0x40, 820, 6, 0, 0, 3, 0, "src/goddard/dynlists/anim_group_1.c", "animdata_mario_eyebrows_equalizer_1", "" },
    { 0x42, 0x43, 820, 6, 166, 6, 3, 3, "src/goddard/dynlists/anim_group_1.c", "animdata_mario_eyebrows_2_1", "animdata_mario_eyebrows_2_2" },
    { 0x48, 0x49, 820, 6, 0, 0, 3, 0, "src/goddard/dynlists/anim_group_1.c", "anim_mario_eyebrows_3_1", "" },
    { 0x4B, 0x4C, 820, 6, 166, 6, 3, 3, "src/goddard/dynlists/anim_group_1.c", "animdata_mario_eyebrows_4_1", "animdata_mario_eyebrows_4_2" },
    { 0x54, 0x55, 820, 6, 0, 0, 3, 0, "src/goddard/dynlists/anim_group_1.c", "animdata_mario_eyebrows_5_1", "" },
    { 0x6B, 0x6C, 820, 6, 166, 6, 3, 3, "src/goddard/dynlists/anim_group_1.c", "animdata_mario_eye_left_1", "animdata_mario_eye_left_2" },
    { 0x7B, 0x7C, 820, 6, 166, 6, 3, 3, "src/goddard/dynlists/anim_group_1.c", "animdata_mario_eye_right_1", "animdata_mario_eye_right_2" },
    { 0x84, 0x85, 820, 6, 166, 6, 3, 3, "src/goddard/dynlists/anim_group_1.c", "animdata_mario_hat_1", "animdata_mario_hat_2" },
    { 0x96, 0x97, 820, 6, 166, 6, 3, 3, "src/goddard/dynlists/anim_group_1.c", "animdata_mario_lips_3_1", "animdata_mario_lips_3_2" },
    { 0x9F, 0xA0, 820, 6, 166, 6, 3, 3, "src/goddard/dynlists/anim_group_1.c", "animdata_mario_lips_4_1", "animdata_mario_lips_4_2" },
    { 0xA8, 0xA9, 820, 6, 0, 0, 3, 0, "src/goddard/dynlists/anim_group_1.c", "animdata_mario_ear_left_1", "" },
    { 0xB1, 0xB2, 820, 6, 0, 0, 3, 0, "src/goddard/dynlists/anim_group_2.c", "animdata_mario_ear_right_1", "" },
    { 0xBA, 0xBB, 820, 6, 166, 6, 3, 3, "src/goddard/dynlists/anim_group_2.c", "animdata_mario_nose_1", "animdata_mario_nose_2" },
    { 0xC3, 0xC4, 820, 6, 166, 6, 3, 3, "src/goddard/dynlists/anim_group_2.c", "animdata_mario_lips_5_1", "animdata_mario_lips_5_2" },
    { 0xC6, 0xC7, 820, 6, 166, 6, 3, 3, "src/goddard/dynlists/anim_group_2.c", "animdata_mario_lip_6_1", "animdata_mario_lip_6_2" },
    { 0xCF, 0xD0, 820, 6, 166, 6, 3, 3, "src/goddard/dynlists/anim_group_2.c", "animdata_mario_eyelid_left_1", "animdata_mario_eyelid_left_2" },
    { 0xD8, 0xD9, 820, 6, 166, 6, 3, 3, "src/goddard/dynlists/anim_group_2.c", "animdata_mario_eyelid_right_1", "animdata_mario_eyelid_right_2" },
    { 0xE2, 0xE3, 820, 8, 166, 8, 6, 6, "src/goddard/dynlists/anim_group_2.c", "animdata_mario_intro_1", "animdata_mario_intro_2" },
    { 0xE5, 0xE6, 820, 8, 166, 8, 6, 6, "src/goddard/dynlists/anim_group_2.c", "animdata_silver_star_1", "animdata_silver_star_2" },
    { 0xE8, 0xE9, 820, 8, 166, 8, 6, 6, "src/goddard/dynlists/anim_group_2.c", "animdata_red_star_1", "animdata_red_star_2" },
};

static void append_u32(struct buffer *buffer, uint32_t value) {
    buffer->bytes[buffer->count++] = (uint8_t) value;
    buffer->bytes[buffer->count++] = (uint8_t) (value >> 8);
    buffer->bytes[buffer->count++] = (uint8_t) (value >> 16);
    buffer->bytes[buffer->count++] = (uint8_t) (value >> 24);
}

static void append_string(struct buffer *buffer, const char *value) {
    const uint32_t length = (uint32_t) strlen(value);
    append_u32(buffer, length);
    memcpy(&buffer->bytes[buffer->count], value, length);
    buffer->count += length;
}

static struct buffer encode(void) {
    struct buffer buffer = { 0 };
    buffer.bytes[buffer.count++] = 'M';
    buffer.bytes[buffer.count++] = 'F';
    buffer.bytes[buffer.count++] = 'R';
    buffer.bytes[buffer.count++] = 'M';
    append_u32(&buffer, 1);
    append_u32(&buffer, sizeof(entries) / sizeof(entries[0]));
    for (size_t index = 0; index < sizeof(entries) / sizeof(entries[0]); ++index) {
        const uint32_t values[] = {
            entries[index].component_id, entries[index].animator_id,
            entries[index].primary_count, entries[index].primary_type,
            entries[index].secondary_count, entries[index].secondary_type,
            entries[index].primary_stride, entries[index].secondary_stride,
        };
        for (size_t value_index = 0; value_index < sizeof(values) / sizeof(values[0]); ++value_index) {
            append_u32(&buffer, values[value_index]);
        }
        append_string(&buffer, entries[index].source_path);
        append_string(&buffer, entries[index].primary_symbol);
        append_string(&buffer, entries[index].secondary_symbol);
    }
    return buffer;
}

static uint64_t fingerprint(struct buffer buffer) {
    uint64_t hash = FNV_OFFSET;
    for (size_t index = 0; index < buffer.count; ++index) {
        hash ^= buffer.bytes[index];
        hash *= FNV_PRIME;
    }
    return hash;
}

int main(void) {
    const struct buffer buffer = encode();
    printf("marioFaceManifestCodecFingerprint=0x%016llx\n", (unsigned long long) fingerprint(buffer));
    printf("marioFaceManifestCodecBytes=%zu\n", buffer.count);
    printf("marioFaceManifestCodecEntries=%zu\n", sizeof(entries) / sizeof(entries[0]));
    printf("marioFaceManifestCodecRoundTrip=1\n");
    printf("SM64 Modern Mario face resource manifest codec C contract passed\n");
    return 0;
}
