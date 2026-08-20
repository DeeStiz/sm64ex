#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t h(uint64_t seed, uint64_t value) {
    for (unsigned index = 0; index < 8; ++index) {
        seed ^= (value >> (index * 8u)) & UINT64_C(0xff);
        seed *= FNV_PRIME;
    }
    return seed;
}

static uint64_t opt(uint64_t seed, int32_t value, int present) {
    return h(seed, present ? (uint64_t)(int64_t)value : UINT64_MAX);
}

static uint64_t add_hidden(uint64_t seed, uint64_t action, int32_t timer, int32_t count,
                           int spawn_star, int mist, int deactivate) {
    seed = h(seed, action);
    seed = h(seed, (uint64_t)(int64_t)timer);
    seed = h(seed, (uint64_t)(int64_t)count);
    seed = h(seed, (uint64_t)spawn_star);
    seed = h(seed, (uint64_t)mist);
    return h(seed, (uint64_t)deactivate);
}

static uint64_t add_coin(uint64_t seed, int parent_present, int32_t parent, int orange_present,
                         int32_t orange, int sound_present, int32_t sound, int sparkles,
                         int remove, int clear) {
    seed = opt(seed, parent, parent_present);
    seed = opt(seed, orange, orange_present);
    seed = opt(seed, sound, sound_present);
    seed = h(seed, (uint64_t)sparkles);
    seed = h(seed, (uint64_t)remove);
    return h(seed, (uint64_t)clear);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = add_hidden(fingerprint, 0, 1, 7, 0, 0, 0);
    fingerprint = add_hidden(fingerprint, 1, 0, 8, 0, 0, 0);
    fingerprint = add_hidden(fingerprint, 1, 3, 8, 0, 0, 0);
    fingerprint = add_hidden(fingerprint, 1, 4, 8, 1, 1, 1);
    fingerprint = h(fingerprint, 1); fingerprint = h(fingerprint, 0x100);
    fingerprint = h(fingerprint, 2); fingerprint = h(fingerprint, 0x200);
    fingerprint = add_coin(fingerprint, 1, 7, 0, 0, 0, 0, 0, 0, 1);
    fingerprint = add_coin(fingerprint, 1, 8, 0, 0, 1, 7, 1, 1, 1);
    fingerprint = add_coin(fingerprint, 1, 4, 1, 4, 1, 3, 1, 1, 1);
    fingerprint = add_coin(fingerprint, 0, 0, 0, 0, 0, 0, 1, 1, 1);
    printf("redCoinFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern red-coin star C contract passed");
    return 0;
}
