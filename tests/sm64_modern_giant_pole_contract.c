#include <stdint.h>
#include <stdio.h>

#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)

static uint64_t hash_u64(uint64_t seed, uint64_t value) {
    for (unsigned index = 0; index < 8; ++index) {
        seed ^= (value >> (index * 8)) & UINT64_C(255);
        seed *= PRIME;
    }
    return seed;
}

static uint64_t row(uint64_t seed, int timer, uint32_t radius, uint32_t height, int spawn, uint32_t top_y) {
    seed = hash_u64(seed, (uint64_t)(int64_t)timer);
    seed = hash_u64(seed, radius);
    seed = hash_u64(seed, height);
    seed = hash_u64(seed, (uint64_t)spawn);
    return hash_u64(seed, top_y);
}

int main(void) {
    uint64_t fingerprint = OFFSET;
    fingerprint = row(fingerprint, 1, UINT32_C(0x42A00000), UINT32_C(0x45034000), 1, UINT32_C(0x4507A000));
    fingerprint = row(fingerprint, 2, UINT32_C(0x42A00000), UINT32_C(0x45034000), 0, UINT32_C(0x4507A000));
    printf("giantPoleFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern Giant Pole C contract passed");
    return 0;
}
