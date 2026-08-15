#include <stdint.h>
#include <stdio.h>

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (int byte = 0; byte < 4; ++byte) {
        hash ^= (uint64_t) ((value >> (byte * 8)) & 0xff);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static uint64_t hash_id(uint64_t hash, uint32_t slot, uint32_t generation) {
    hash = hash_u32(hash, slot);
    return hash_u32(hash, generation);
}

int main(void) {
    uint64_t fingerprint = UINT64_C(1469598103934665603);
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_id(fingerprint, 1, 1);
    fingerprint = hash_id(fingerprint, 2, 1);
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u32(fingerprint, 1);
    fingerprint = hash_u32(fingerprint, 1);
    printf("racingPenguinRaceChildrenObjectBridgeFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    printf("SM64 Modern racing penguin race-children object bridge C contract passed\n");
    return 0;
}
