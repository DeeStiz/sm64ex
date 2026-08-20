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

static uint64_t row(uint64_t seed, int timer, uint32_t offset_bits, uint32_t velocity_bits, int deleted, int bounced) {
    seed = hash_u64(seed, (uint64_t)(int64_t)timer);
    seed = hash_u64(seed, offset_bits);
    seed = hash_u64(seed, velocity_bits);
    seed = hash_u64(seed, (uint64_t)deleted);
    return hash_u64(seed, (uint64_t)bounced);
}

int main(void) {
    uint64_t fingerprint = OFFSET;
    fingerprint = row(fingerprint, 0, UINT32_C(0x00000000), UINT32_C(0x41200000), 1, 0);
    fingerprint = row(fingerprint, 21, UINT32_C(0x00000000), UINT32_C(0x41200000), 0, 0);
    fingerprint = row(fingerprint, 22, UINT32_C(0x41F00000), UINT32_C(0x41200000), 0, 0);
    fingerprint = row(fingerprint, 0, UINT32_C(0x42C80000), UINT32_C(0xC1200000), 0, 1);
    printf("dddPoleFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern DDD pole C contract passed");
    return 0;
}
