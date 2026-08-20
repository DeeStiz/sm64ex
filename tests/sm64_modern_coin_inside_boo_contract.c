#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)
static uint64_t hash_u64(uint64_t seed, uint64_t value) { for (unsigned byte = 0; byte < 8; ++byte) { seed ^= (value >> (byte * 8)) & 0xff; seed *= PRIME; } return seed; }
static uint64_t hash_f32(uint64_t seed, float value) { uint32_t bits; memcpy(&bits, &value, sizeof(bits)); return hash_u64(seed, bits); }
static uint64_t hash_row(uint64_t seed, int action, int timer, float px, float py, float pz, float vx, float vy, float vz, int tangible, int blue, float scale, int sparkles, int deleted) {
    seed = hash_u64(seed, (uint64_t)(int64_t)action); seed = hash_u64(seed, (uint64_t)(int64_t)timer);
    seed = hash_f32(seed, px); seed = hash_f32(seed, py); seed = hash_f32(seed, pz);
    seed = hash_f32(seed, vx); seed = hash_f32(seed, vy); seed = hash_f32(seed, vz);
    seed = hash_u64(seed, (uint64_t)tangible); seed = hash_u64(seed, (uint64_t)blue);
    seed = hash_f32(seed, scale); seed = hash_u64(seed, (uint64_t)sparkles); return hash_u64(seed, (uint64_t)deleted);
}
int main(void) {
    uint64_t fingerprint = OFFSET;
    fingerprint = hash_row(fingerprint, 0, 1, 10, 20, 30, 0, 0, 0, 0, 1, 0.7f, 0, 0);
    fingerprint = hash_row(fingerprint, 1, 0, 10, 20, 30, 3, 35, 0, 0, 1, 0.7f, 0, 0);
    fingerprint = hash_row(fingerprint, 1, 92, 4, 37, 3, 3, 31, 0, 1, 0, 1, 1, 1);
    printf("coinInsideBooFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern coin-inside-Boo C contract passed");
    return 0;
}
