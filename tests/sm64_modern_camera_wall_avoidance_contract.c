#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
static uint64_t h8(uint64_t h, uint8_t v) { h ^= v; return h * FNV_PRIME; }
static uint64_t h16(uint64_t h, uint16_t v) { for (unsigned i = 0; i < 2; ++i) h = h8(h, (uint8_t)(v >> (i * 8u))); return h; }
static uint64_t h32(uint64_t h, uint32_t v) { for (unsigned i = 0; i < 4; ++i) h = h8(h, (uint8_t)(v >> (i * 8u))); return h; }
static uint64_t hi16(uint64_t h, int16_t v) { return h16(h, (uint16_t)v); }

typedef struct {
    int16_t status, avoid_yaw, checked_steps;
    uint16_t status_flags;
    float coarse_radius, fine_radius;
    uint32_t coarse_id, fine_id;
} Result;

static uint64_t hash_result(uint64_t h, Result v) {
    h = hi16(h, v.status); h = hi16(h, v.avoid_yaw);
    h = h16(h, v.status_flags); h = hi16(h, v.checked_steps);
    h = h32(h, *(uint32_t *)&v.coarse_radius);
    h = h32(h, *(uint32_t *)&v.fine_radius);
    h = h32(h, v.coarse_id); return h32(h, v.fine_id);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hi16(fingerprint, (int16_t)-0x4000);
    fingerprint = hash_result(fingerprint, (Result){
        0, 0x1234, 8, 0x1214, 250, 100, UINT32_MAX, UINT32_MAX
    });
    fingerprint = hash_result(fingerprint, (Result){
        1, -0x8000, 8, 0x0020, 250, 200, 10, 10
    });
    printf("cameraWallAvoidanceFingerprint=0x%016llx\n",
           (unsigned long long)fingerprint);
    return 0;
}
