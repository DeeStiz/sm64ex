#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
static uint64_t h8(uint64_t h, uint8_t v) { h ^= v; return h * FNV_PRIME; }
static uint64_t h16(uint64_t h, uint16_t v) { for (unsigned i = 0; i < 2; ++i) h = h8(h, (uint8_t)(v >> (i * 8u))); return h; }
static uint64_t h32(uint64_t h, uint32_t v) { for (unsigned i = 0; i < 4; ++i) h = h8(h, (uint8_t)(v >> (i * 8u))); return h; }
static uint64_t hf(uint64_t h, float v) { uint32_t bits; memcpy(&bits, &v, sizeof(bits)); return h32(h, bits); }
static uint64_t hi16(uint64_t h, int16_t v) { return h16(h, (uint16_t)v); }
typedef struct { float x, y, z; } Vec3;
typedef struct {
    int active, exiting;
    int16_t pitch, mode_yaw, head_pitch, head_yaw;
    Vec3 stored;
    float focus_y;
} State;
typedef struct {
    State state;
    int search, found;
    int16_t selected_yaw, transition;
    int sound;
} Result;
static uint64_t hash_vec(uint64_t h, Vec3 v) { h = hf(h, v.x); h = hf(h, v.y); return hf(h, v.z); }
static uint64_t hash_result(uint64_t h, Result v) {
    h = h8(h, (uint8_t)v.state.active); h = h8(h, (uint8_t)v.state.exiting);
    h = hi16(h, v.state.pitch); h = hi16(h, v.state.mode_yaw);
    h = hi16(h, v.state.head_pitch); h = hi16(h, v.state.head_yaw);
    h = hash_vec(h, v.state.stored); h = hf(h, v.state.focus_y);
    h = h8(h, (uint8_t)v.search); h = h8(h, (uint8_t)v.found);
    h = hi16(h, v.selected_yaw); h = hi16(h, v.transition);
    return h8(h, (uint8_t)v.sound);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    Result search = {
        { 1, 1, 0x100, -0x200, 0xC0, -0x180, { 0, 125, 100 }, 125 },
        1, 1, 0, 15, 1
    };
    fingerprint = hash_result(fingerprint, search);
    Result direct = {
        { 0, 0, 0x100, -0x200, 0xC0, -0x180, { 4, 5, 6 }, 125 },
        0, 0, 0, 0, 1
    };
    fingerprint = hash_result(fingerprint, direct);
    Result repeated = {
        { 1, 1, 0x100, -0x200, 0xC0, -0x180, { 0, 125, 100 }, 125 },
        0, 0, 0, 0, 0
    };
    fingerprint = hash_result(fingerprint, repeated);
    printf("cameraCUpExitFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    return 0;
}
