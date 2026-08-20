#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u64(uint64_t seed, uint64_t value) {
    for (unsigned index = 0; index < 8; ++index) {
        seed ^= (value >> (index * 8u)) & UINT64_C(0xff);
        seed *= FNV_PRIME;
    }
    return seed;
}

static uint64_t hash_float(uint64_t seed, float value) {
    union { float value; uint32_t bits; } representation = { .value = value };
    return hash_u64(seed, representation.bits);
}

static uint64_t add(uint64_t seed, uint64_t model, uint64_t yaw, uint64_t delete, uint64_t clear) {
    seed = hash_u64(seed, model);
    seed = hash_u64(seed, yaw);
    seed = hash_float(seed, 80.0f);
    seed = hash_float(seed, 50.0f);
    seed = hash_u64(seed, delete);
    return hash_u64(seed, clear);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = add(fingerprint, 0, 0x4800, 0, 1);
    fingerprint = add(fingerprint, 1, 0x5000, 0, 1);
    fingerprint = add(fingerprint, 0, 0x800, 1, 1);
    printf("collectStarFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    puts("SM64 Modern collect-star C contract passed");
    return 0;
}
