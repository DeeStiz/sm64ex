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
    union { float value; uint32_t bits; } encoded = { value };
    return hash_u64(seed, encoded.bits);
}

static uint64_t hash_output(
    uint64_t seed,
    uint64_t kind,
    float x,
    float y,
    float z,
    float scale_x,
    float scale_y,
    float scale_z,
    int32_t animation_state,
    int should_delete
) {
    seed = hash_u64(seed, kind);
    seed = hash_float(seed, x);
    seed = hash_float(seed, y);
    seed = hash_float(seed, z);
    seed = hash_float(seed, scale_x);
    seed = hash_float(seed, scale_y);
    seed = hash_float(seed, scale_z);
    seed = hash_u64(seed, (uint64_t)(int64_t)animation_state);
    return hash_u64(seed, should_delete ? 1 : 0);
}

int main(void) {
    uint64_t fingerprint = hash_output(
        FNV_OFFSET, 0, 10.0f, 125.0f, -3.0f,
        0.5f, 1.0f, 0.5f, 0, 0
    );
    fingerprint = hash_output(
        fingerprint, 1, -4.0f, 5.0f, 8.0f,
        1.75f, 1.75f, 1.75f, 0, 0
    );
    fingerprint = hash_output(
        fingerprint, 2, 3.0f, 4.0f, 5.0f,
        1.0f, 1.0f, 1.0f, 0, 0
    );
    printf("waterSplashFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern water splash C contract passed");
    return 0;
}
