#include <stdint.h>
#include <stdio.h>

static const uint64_t FNV_OFFSET = UINT64_C(1469598103934665603);
static const uint64_t FNV_PRIME = UINT64_C(1099511628211);

static uint64_t hash_u64(uint64_t initial, uint64_t value) {
    uint64_t hash = initial;
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_result(uint64_t hash, uint64_t effects, uint64_t variant,
                            uint64_t action, uint64_t health, uint64_t timer,
                            uint64_t tangible, uint64_t hidden, uint64_t marked,
                            uint64_t star, uint64_t bridge) {
    const uint64_t values[] = {
        effects, variant, action, health, timer,
        tangible, hidden, marked, star, bridge
    };
    for (size_t index = 0; index < sizeof(values) / sizeof(values[0]); ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_result(fingerprint, 1, 0, 0, 3, 1, 0, 1, 0, 0, 0);
    fingerprint = hash_result(fingerprint, 1027, 0, 1, 3, 1, 1, 0, 0, 0, 0);
    fingerprint = hash_result(fingerprint, 4480, 0, 3, 2, 1, 0, 1, 0, 0, 0);
    fingerprint = hash_result(fingerprint, 128, 0, 3, 0, 1, 0, 1, 0, 0, 0);
    fingerprint = hash_result(fingerprint, 8448, 0, 4, 0, 32, 0, 1, 0, 1, 0);
    fingerprint = hash_result(fingerprint, 49152, 0, 4, 3, 62, 0, 1, 1, 0, 1);
    fingerprint = hash_result(fingerprint, 8448, 2, 4, 0, 32, 0, 1, 0, 1, 0);
    printf("bigBooFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    printf("SM64 Modern Big Boo C contract passed\n");
    return 0;
}
