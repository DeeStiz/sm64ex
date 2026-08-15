#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
static uint64_t h8(uint64_t h, uint8_t v) { h ^= v; return h * FNV_PRIME; }
static uint64_t h32(uint64_t h, uint32_t v) { for (unsigned i = 0; i < 4; ++i) h = h8(h, (uint8_t)(v >> (i * 8u))); return h; }
static uint64_t h64(uint64_t h, uint64_t v) { for (unsigned i = 0; i < 8; ++i) h = h8(h, (uint8_t)(v >> (i * 8u))); return h; }
static uint64_t hf(uint64_t h, float value) { uint32_t bits; memcpy(&bits, &value, sizeof(bits)); return h32(h, bits); }

static uint64_t hash_approach(uint64_t h, float y, int moving) {
    h = hf(h, y); return h8(h, (uint8_t)(moving != 0));
}
static uint64_t hash_wall(uint64_t h, float x, float y, float z,
                          uint64_t count, uint64_t id, int has_id, int collided) {
    h = hf(h, x); h = hf(h, y); h = hf(h, z); h = h64(h, count);
    if (has_id) h = h64(h, id);
    return h8(h, (uint8_t)(collided != 0));
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_approach(fingerprint, 13, 1);
    fingerprint = hash_approach(fingerprint, 10, 0);
    fingerprint = hash_approach(fingerprint, 20, 0);
    fingerprint = hash_wall(fingerprint, 20, 0, 0, 1, 10, 1, 1);
    fingerprint = hash_wall(fingerprint, 500, 0, 0, 0, 0, 0, 0);
    printf("cameraCollisionFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    return 0;
}
