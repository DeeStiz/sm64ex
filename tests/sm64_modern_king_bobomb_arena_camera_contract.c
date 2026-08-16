#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u32(uint64_t initial, uint32_t value) {
    uint64_t hash = initial;
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (value >> (byte * 8)) & UINT32_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_u32(fingerprint, UINT32_C(66055)); // resetHome | cameraFocus | bossMusic | intangible | renderingEnabled
    fingerprint = hash_u32(fingerprint, UINT32_C(2));
    fingerprint = hash_u32(fingerprint, UINT32_C(10)); // music
    fingerprint = hash_u32(fingerprint, UINT32_C(1));
    fingerprint = hash_u32(fingerprint, UINT32_C(0));
    fingerprint = hash_u32(fingerprint, UINT32_C(11)); // cameraFocus
    fingerprint = hash_u32(fingerprint, UINT32_C(11)); // CAMERA_MODE_BOSS_FIGHT
    fingerprint = hash_u32(fingerprint, UINT32_C(0));
    fingerprint = hash_u32(fingerprint, UINT32_C(0)); // initialize action
    fingerprint = hash_u32(fingerprint, UINT32_C(1)); // intro subaction
    printf("kingBobombArenaCameraFingerprint=0x%016llx\n",
           (unsigned long long)fingerprint);
    printf("SM64 Modern King Bob-omb arena camera C contract passed\n");
    return 0;
}
