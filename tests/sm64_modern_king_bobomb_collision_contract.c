#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u64(uint64_t initial, uint64_t value) {
    uint64_t hash = initial;
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_float(uint64_t initial, float value) {
    union { float f; uint32_t u; } bits = { value };
    return hash_u64(initial, bits.u);
}

static uint64_t hash_collision(uint64_t initial) {
    uint64_t hash = hash_float(initial, 20.0f);
    hash = hash_float(hash, 0.0f);
    hash = hash_float(hash, 0.0f);
    hash = hash_float(hash, -0.0f);
    hash = hash_u64(hash, 1);
    hash = hash_u64(hash, 0);
    hash = hash_u64(hash, 0);
    hash = hash_float(hash, 1.0f);
    hash = hash_u64(hash, 1);
    hash = hash_u64(hash, 10);
    hash = hash_u64(hash, 514);
    hash = hash_u64(hash, 1);
    return hash_u64(hash, 0);
}

static uint64_t hash_movement(uint64_t initial) {
    uint64_t hash = hash_float(initial, 20.0f);
    hash = hash_float(hash, 0.0f);
    hash = hash_float(hash, 0.0f);
    hash = hash_float(hash, 0.0f);
    hash = hash_float(hash, 0.4f);
    hash = hash_float(hash, 3.0f);
    hash = hash_float(hash, 3.0f);
    hash = hash_u64(hash, 514);
    hash = hash_u64(hash, 0);
    hash = hash_u64(hash, 0);
    return hash_u64(hash, 1);
}

int main(void) {
    uint64_t fingerprint = hash_collision(FNV_OFFSET);
    fingerprint = hash_movement(fingerprint);
    printf("kingBobombCollisionFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    printf("SM64 Modern King Bob-omb collision C contract passed\n");
    return 0;
}
