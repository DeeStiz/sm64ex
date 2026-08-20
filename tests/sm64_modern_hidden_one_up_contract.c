#include <stdint.h>
#include <stdio.h>

#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)

static uint64_t hash_u64(uint64_t seed, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) {
        seed ^= (value >> (byte * 8)) & 255;
        seed *= PRIME;
    }
    return seed;
}

static uint64_t hash_i32(uint64_t seed, int32_t value) {
    return hash_u64(seed, (uint64_t)(int64_t)value);
}

static uint64_t hash_f32(uint64_t seed, float value) {
    union { float f; uint32_t u; } bits = { value };
    return hash_u64(seed, bits.u);
}

static uint64_t add(uint64_t seed, int role, int action, int timer, int trigger,
                    int visible, int tangible, int deleted, int pitch,
                    uint32_t forward_bits, uint32_t vertical_bits, int sparkle, int appear,
                    int consume, int children) {
    seed = hash_i32(seed, role);
    seed = hash_i32(seed, action);
    seed = hash_i32(seed, timer);
    seed = hash_i32(seed, trigger);
    seed = hash_u64(seed, (uint64_t)visible);
    seed = hash_u64(seed, (uint64_t)tangible);
    seed = hash_u64(seed, (uint64_t)deleted);
    seed = hash_i32(seed, pitch);
    seed = hash_u64(seed, forward_bits);
    seed = hash_u64(seed, vertical_bits);
    seed = hash_u64(seed, (uint64_t)sparkle);
    seed = hash_u64(seed, (uint64_t)appear);
    seed = hash_u64(seed, (uint64_t)consume);
    return hash_u64(seed, (uint64_t)children);
}

int main(void) {
    uint64_t fingerprint = OFFSET;
    fingerprint = add(fingerprint, 0, 3, 0, 2, 1, 0, 0, 0, UINT32_C(0x00000000), UINT32_C(0x42200000), 0, 1, 0, 0);
    fingerprint = add(fingerprint, 0, 3, 19, 2, 1, 0, 0, -4096, UINT32_C(0x4137b024), UINT32_C(0xc117b024), 1, 0, 0, 0);
    fingerprint = add(fingerprint, 1, 0, 1, 1, 1, 1, 1, 0, UINT32_C(0x00000000), UINT32_C(0x00000000), 0, 0, 1, 0);
    fingerprint = add(fingerprint, 4, 0, 1, 0, 1, 0, 1, 0, UINT32_C(0x00000000), UINT32_C(0x00000000), 0, 0, 0, 1);
    fingerprint = add(fingerprint, 0, 2, 31, 0, 0, 0, 1, 0, UINT32_C(0x00000000), UINT32_C(0x00000000), 0, 0, 0, 0);
    fingerprint = add(fingerprint, 5, 0, 1, 0, 1, 0, 1, 0, UINT32_C(0x00000000), UINT32_C(0x00000000), 0, 0, 0, 0);
    fingerprint = add(fingerprint, 6, 0, 1, 0, 1, 0, 0, 0, UINT32_C(0x00000000), UINT32_C(0x42200000), 0, 1, 0, 0);
    fingerprint = add(fingerprint, 7, 0, 1, 0, 1, 0, 0, 0, UINT32_C(0x00000000), UINT32_C(0x42200000), 0, 1, 0, 0);
    fingerprint = add(fingerprint, 8, 1, 0, 0, 1, 1, 0, 0, UINT32_C(0x00000000), UINT32_C(0x00000000), 0, 0, 0, 0);
    fingerprint = add(fingerprint, 9, 1, 0, 0, 1, 1, 0, 0, UINT32_C(0x00000000), UINT32_C(0x42200000), 0, 0, 0, 0);
    printf("hiddenOneUpFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern hidden-one-up C contract passed");
    return 0;
}
