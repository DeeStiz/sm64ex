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
typedef struct { Vec3 focus, position; float distance; int16_t pitch, yaw, next; int finished, head_pitch, head_yaw; } Result;
static uint64_t hash_vec(uint64_t h, Vec3 v) { h = hf(h, v.x); h = hf(h, v.y); return hf(h, v.z); }
static uint64_t hash_result(uint64_t h, Result v) {
    h = hash_vec(h, v.focus); h = hash_vec(h, v.position); h = hf(h, v.distance);
    h = hi16(h, v.pitch); h = hi16(h, v.yaw); h = hi16(h, v.next);
    h = h8(h, (uint8_t)v.finished); h = hi16(h, (int16_t)v.head_pitch); return hi16(h, (int16_t)v.head_yaw);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_result(fingerprint, (Result){
        { 12, 24, 36 }, { 12, 24, 186 }, 150, 0, 0, 3, 0, 0, 0
    });
    fingerprint = hash_result(fingerprint, (Result){
        { 13, 26, 39 }, { 13, 26, 214 }, 175, 0, 0, 4, 1, 0, 0
    });
    printf("cameraCUpTransitionFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    return 0;
}
