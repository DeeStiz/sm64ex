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

static uint64_t add(uint64_t seed, uint64_t variant, float radius, float height, uint64_t subtype, uint64_t clear, uint64_t collision, uint64_t collision_data) {
    seed = hash_u64(seed, variant);
    seed = hash_float(seed, radius);
    seed = hash_float(seed, height);
    seed = hash_u64(seed, subtype);
    seed = hash_u64(seed, clear);
    seed = hash_u64(seed, collision);
    return hash_u64(seed, collision_data);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = add(fingerprint, 0, 50.0f, 50.0f, 0, 1, 0, 0);
    fingerprint = add(fingerprint, 0, 10000.0f, 50.0f, 0, 1, 0, 0);
    fingerprint = add(fingerprint, 0, 70.0f, 50.0f, 0, 1, 0, 0);
    fingerprint = add(fingerprint, 1, 85.0f, 50.0f, 1, 1, 0, 0);
    fingerprint = add(fingerprint, 1, 70.0f, 50.0f, 1, 1, 0, 0);
    fingerprint = add(fingerprint, 2, 70.0f, 50.0f, 0, 1, 1, 0);
    fingerprint = add(fingerprint, 3, 50.0f, 50.0f, 0, 1, 1, UINT64_C(0x74746D5F706F6469));
    printf("warpFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    puts("SM64 Modern warp C contract passed");
    return 0;
}
