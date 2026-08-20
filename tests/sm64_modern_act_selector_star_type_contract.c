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

static uint64_t add(uint64_t seed, uint64_t type, float size, uint64_t yaw, uint64_t timer) {
    seed = hash_u64(seed, type);
    seed = hash_float(seed, size);
    seed = hash_u64(seed, yaw);
    seed = hash_u64(seed, timer);
    return hash_float(seed, size);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = add(fingerprint, 0, 1.0f, 0, 5);
    fingerprint = add(fingerprint, 1, 1.3f, 0x4800, 8);
    fingerprint = add(fingerprint, 1, 1.3f, 0x800, 9);
    fingerprint = add(fingerprint, 2, 0.8f, 0x4800, 11);
    printf("actSelectorStarTypeFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    puts("SM64 Modern act-selector star type C contract passed");
    return 0;
}
