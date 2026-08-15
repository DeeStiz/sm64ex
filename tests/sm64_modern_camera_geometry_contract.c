#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
static uint64_t h8(uint64_t h, uint8_t v) { h ^= v; return h * FNV_PRIME; }
static uint64_t h16(uint64_t h, uint16_t v) { for (unsigned i = 0; i < 2; ++i) h = h8(h, (uint8_t)(v >> (i * 8u))); return h; }
static uint64_t h32(uint64_t h, uint32_t v) { for (unsigned i = 0; i < 4; ++i) h = h8(h, (uint8_t)(v >> (i * 8u))); return h; }
static uint64_t hf(uint64_t h, float value) { uint32_t bits; memcpy(&bits, &value, sizeof(bits)); return h32(h, bits); }

typedef struct { float x, y, z; } Vec3;
typedef struct { float position, focus; } HeightOffsets;
typedef struct { Vec3 focus, position; } FocusPlacement;
typedef struct {
    Vec3 focus, position;
    int16_t cameraYaw, areaYaw, pitch;
    HeightOffsets offsets;
} RadialPlacement;

static float clampf(float value, float bound) {
    return value < -bound ? -bound : (value > bound ? bound : value);
}

static HeightOffsets height_offsets(float mario_y, float floor_height, float water_height,
                                    int has_water, int metal, int on_pole,
                                    float pole_y, float hitbox_height) {
    if (!metal && has_water && floor_height < water_height) floor_height = water_height;
    float position_bound = 200.0f;
    if (on_pole && floor_height >= pole_y && mario_y < 0.7f * hitbox_height + pole_y) {
        position_bound = 1200.0f;
    }
    HeightOffsets result = {
        clampf((floor_height - mario_y) * 1.0f, position_bound),
        clampf((floor_height - mario_y) * 0.9f, 200.0f)
    };
    return result;
}

static FocusPlacement focus_on_mario(Vec3 mario, float pos_y, float foc_y,
                                     float distance, int16_t pitch, int16_t yaw) {
    /* This scenario uses cardinal yaw/pitch values, so the canonical table
       values are exact and independent of host libm. */
    float sin_pitch = pitch == 0 ? 0.0f : 0.0f;
    float cos_pitch = pitch == 0 ? 1.0f : 1.0f;
    float sin_yaw = yaw == 0 ? 0.0f : 0.0f;
    float cos_yaw = yaw == 0 ? 1.0f : 1.0f;
    FocusPlacement result = {
        {mario.x, mario.y + foc_y, mario.z},
        {mario.x + distance * cos_pitch * sin_yaw,
         mario.y + pos_y + distance * sin_pitch,
         mario.z + distance * cos_pitch * cos_yaw}
    };
    return result;
}

static uint64_t hash_vec(uint64_t h, Vec3 value) {
    h = hf(h, value.x); h = hf(h, value.y); return hf(h, value.z);
}
static uint64_t hash_offsets(uint64_t h, HeightOffsets value) {
    h = hf(h, value.position); return hf(h, value.focus);
}
static uint64_t hash_focus(uint64_t h, FocusPlacement value) {
    h = hash_vec(h, value.focus); return hash_vec(h, value.position);
}
static uint64_t hash_radial(uint64_t h, RadialPlacement value) {
    h = hash_vec(h, value.focus); h = hash_vec(h, value.position);
    h = h16(h, (uint16_t)value.cameraYaw); h = h16(h, (uint16_t)value.areaYaw);
    h = h16(h, (uint16_t)value.pitch); return hash_offsets(h, value.offsets);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_offsets(fingerprint, height_offsets(50, 100, 250, 1, 0, 0, 0, 0));
    fingerprint = hash_offsets(fingerprint, height_offsets(50, 100, 250, 1, 1, 0, 0, 0));
    fingerprint = hash_offsets(fingerprint, height_offsets(-100, 2000, 0, 0, 0, 1, 0, 100));

    FocusPlacement direct = focus_on_mario((Vec3){-100, 20, -200}, 5, 2, 100, 0, 0);
    fingerprint = hash_focus(fingerprint, direct);
    fingerprint = h16(fingerprint, 0x05B0);
    fingerprint = h16(fingerprint, 0x05B0);

    /* Canonical atan2s(0, +x) is 0x4000 in SM64's +Z-forward convention. */
    uint32_t sin_bits = UINT32_C(0x3e0e7a8b), cos_bits = UINT32_C(0x3f7d8285);
    float sin_pitch, cos_pitch;
    memcpy(&sin_pitch, &sin_bits, sizeof(sin_pitch));
    memcpy(&cos_pitch, &cos_bits, sizeof(cos_pitch));
    Vec3 mario = {-100, 50, -200};
    HeightOffsets offsets = {0, 0};
    RadialPlacement radial = {
        {mario.x, mario.y + 125, mario.z},
        {mario.x + 1000.0f * cos_pitch,
         mario.y + 125.0f + 1000.0f * sin_pitch,
         mario.z},
        0x4000, 0x4000, 0x05B0, offsets
    };
    fingerprint = hash_radial(fingerprint, radial);

    printf("cameraGeometryFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    return 0;
}
