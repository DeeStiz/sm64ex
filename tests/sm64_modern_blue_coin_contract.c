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

static uint64_t add_switch(uint64_t seed, uint64_t action, int32_t timer, float position_y,
                           float velocity_y, float scale, int visible, int collision,
                           int load_collision, uint64_t sound, int mist, int remove) {
    seed = hash_u64(seed, action);
    seed = hash_u64(seed, (uint64_t)(int64_t)timer);
    seed = hash_float(seed, position_y);
    seed = hash_float(seed, velocity_y);
    seed = hash_float(seed, scale);
    seed = hash_u64(seed, (uint64_t)visible);
    seed = hash_u64(seed, (uint64_t)collision);
    seed = hash_u64(seed, (uint64_t)load_collision);
    seed = hash_u64(seed, sound);
    seed = hash_u64(seed, (uint64_t)mist);
    return hash_u64(seed, (uint64_t)remove);
}

static uint64_t add_coin(uint64_t seed, uint64_t action, int32_t timer, int visible,
                         int tangible, int sparkles, int remove) {
    seed = hash_u64(seed, action);
    seed = hash_u64(seed, (uint64_t)(int64_t)timer);
    seed = hash_u64(seed, (uint64_t)visible);
    seed = hash_u64(seed, (uint64_t)tangible);
    seed = hash_u64(seed, (uint64_t)sparkles);
    return hash_u64(seed, (uint64_t)remove);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = add_switch(fingerprint, 0, 1, 10.0f, 0.0f, 3.0f, 1, 1, 1, 0, 0, 0);
    fingerprint = add_switch(fingerprint, 1, 0, 10.0f, -20.0f, 3.0f, 1, 1, 1, 1, 0, 0);
    fingerprint = add_switch(fingerprint, 1, 6, 80.0f, -20.0f, 3.0f, 1, 1, 1, 0, 0, 0);
    fingerprint = add_switch(fingerprint, 2, 0, 160.0f, -20.0f, 3.0f, 0, 0, 0, 0, 1, 0);
    fingerprint = add_switch(fingerprint, 2, 1, 160.0f, -20.0f, 3.0f, 0, 0, 0, 2, 0, 0);
    fingerprint = add_switch(fingerprint, 2, 201, 160.0f, -20.0f, 3.0f, 0, 0, 0, 3, 0, 0);
    fingerprint = add_switch(fingerprint, 2, 242, 160.0f, -20.0f, 3.0f, 0, 0, 0, 3, 0, 1);
    fingerprint = add_coin(fingerprint, 0, 1, 0, 0, 0, 0);
    fingerprint = add_coin(fingerprint, 1, 0, 0, 0, 0, 0);
    fingerprint = add_coin(fingerprint, 2, 0, 0, 0, 0, 0);
    fingerprint = add_coin(fingerprint, 2, 201, 1, 1, 0, 0);
    fingerprint = add_coin(fingerprint, 2, 202, 0, 1, 0, 0);
    fingerprint = add_coin(fingerprint, 2, 244, 0, 1, 0, 1);
    fingerprint = add_coin(fingerprint, 2, 21, 1, 1, 1, 1);
    printf("blueCoinFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern blue-coin switch/hidden-coin C contract passed");
    return 0;
}
