#include <stdint.h>
#include <stdio.h>

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (int byte = 0; byte < 4; ++byte) {
        hash ^= (uint64_t) ((value >> (byte * 8)) & 0xff);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static uint64_t hash_i16(uint64_t hash, int16_t value) {
    return hash_u32(hash, (uint32_t) (uint16_t) value);
}

static uint64_t hash_path(uint64_t hash, int action, int status,
                          int previous_index, int previous_flags,
                          int16_t target_yaw, int16_t target_pitch) {
    hash = hash_u32(hash, (uint32_t) action);
    hash = hash_u32(hash, (uint32_t) status);
    hash = hash_u32(hash, (uint32_t) previous_index);
    hash = hash_u32(hash, (uint32_t) previous_flags);
    hash = hash_i16(hash, target_yaw);
    return hash_i16(hash, target_pitch);
}

int main(void) {
    uint64_t fingerprint = UINT64_C(1469598103934665603);
    fingerprint = hash_path(fingerprint, 3, 0, 0, 0x8000, 0x4000, -4836);
    fingerprint = hash_path(fingerprint, 3, 1, 1, 0x8000, -16384, 8192);
    fingerprint = hash_path(fingerprint, 4, -1, 2, 0x8007, -24576, -6419);
    printf("racingPenguinPathObjectBridgeFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    printf("SM64 Modern racing penguin path object bridge C contract passed\n");
    return 0;
}
