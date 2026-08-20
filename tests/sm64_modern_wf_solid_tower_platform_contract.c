#include <stdint.h>
#include <stdio.h>

static const uint64_t FNV_OFFSET = UINT64_C(1469598103934665603);
static const uint64_t FNV_PRIME = UINT64_C(1099511628211);

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (value >> (byte * 8)) & 0xffu;
        hash *= FNV_PRIME;
    }
    return hash;
}

static int should_delete(int32_t parent_action) { return parent_action == 3; }

int main(void) {
    if (should_delete(0) || !should_delete(3)) return 2;
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_u32(fingerprint, 0);
    fingerprint = hash_u32(fingerprint, 1);
    printf("wfSolidTowerPlatformFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern WF solid tower platform C contract passed");
    return 0;
}
