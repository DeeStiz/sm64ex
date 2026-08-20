#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)
static uint64_t hash_u64(uint64_t seed, uint64_t value) { for (unsigned byte = 0; byte < 8; ++byte) { seed ^= (value >> (byte * 8)) & 0xff; seed *= PRIME; } return seed; }
static uint64_t hash_f32(uint64_t seed, float value) { uint32_t bits; memcpy(&bits, &value, sizeof(bits)); return hash_u64(seed, bits); }
static uint64_t hash_row(uint64_t seed, int action, int timer, int yaw, int pitch, float speed, float velocityY, float animation, int deleted) {
    seed = hash_u64(seed, (uint64_t)(int64_t)action); seed = hash_u64(seed, (uint64_t)(int64_t)timer);
    seed = hash_u64(seed, (uint64_t)(int64_t)yaw); seed = hash_u64(seed, (uint64_t)(int64_t)pitch);
    seed = hash_f32(seed, speed); seed = hash_f32(seed, velocityY); seed = hash_f32(seed, animation);
    return hash_u64(seed, (uint64_t)deleted);
}
int main(void) {
    uint64_t fingerprint = OFFSET;
    fingerprint = hash_row(fingerprint, 0, 1, 0, 0, 5, -0.0f, 1, 0);
    fingerprint = hash_row(fingerprint, 2, 0, 256, 0, 5, -0.0f, 2, 0);
    fingerprint = hash_row(fingerprint, 3, 1, 256, 0, 5, -0.0f, 2, 1);
    fingerprint = hash_u64(fingerprint, 1); fingerprint = hash_u64(fingerprint, 1); fingerprint = hash_u64(fingerprint, 15);
    fingerprint = hash_u64(fingerprint, 2); fingerprint = hash_u64(fingerprint, 0); fingerprint = hash_u64(fingerprint, 0);
    fingerprint = hash_u64(fingerprint, 0); fingerprint = hash_u64(fingerprint, 0); fingerprint = hash_u64(fingerprint, 0);
    printf("blueFishFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern blue-fish C contract passed");
    return 0;
}
