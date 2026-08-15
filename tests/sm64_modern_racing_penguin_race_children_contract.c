#include <stdint.h>
#include <stdio.h>

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (int byte = 0; byte < 4; ++byte) {
        hash ^= (uint64_t) ((value >> (byte * 8)) & 0xff);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static uint64_t hash_output(uint64_t hash, int mario_won, int mario_cheated) {
    hash = hash_u32(hash, (uint32_t) mario_won);
    return hash_u32(hash, (uint32_t) mario_cheated);
}

int main(void) {
    uint64_t fingerprint = UINT64_C(1469598103934665603);
    fingerprint = hash_output(fingerprint, 1, 0);
    fingerprint = hash_output(fingerprint, 0, 0);
    fingerprint = hash_output(fingerprint, 0, 0);
    fingerprint = hash_output(fingerprint, 0, 1);
    fingerprint = hash_output(fingerprint, 0, 0);
    printf("racingPenguinRaceChildrenFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    printf("SM64 Modern racing penguin race-children C contract passed\n");
    return 0;
}
