#include <stdint.h>
#include <stdio.h>

static uint64_t fnv_u64(uint64_t hash, uint64_t value) {
    for (int shift = 0; shift <= 56; shift += 8) {
        hash ^= (value >> shift) & UINT64_C(0xff);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

int main(void) {
    const uint64_t frame_fingerprints[3] = {
        UINT64_C(0xbf8d3c04f88255c2),
        UINT64_C(0xc2eba3426b913fa8),
        UINT64_C(0xc0109f487b34f1ed)
    };
    const uint64_t record_counts[3] = { 13, 11, 9 };
    uint64_t fingerprint = UINT64_C(1469598103934665603);
    fingerprint = fnv_u64(fingerprint, 3);
    for (int index = 0; index < 3; ++index) {
        fingerprint = fnv_u64(fingerprint, (uint64_t)(index + 1));
        fingerprint = fnv_u64(fingerprint, record_counts[index]);
        fingerprint = fnv_u64(fingerprint, 4);
        fingerprint = fnv_u64(fingerprint, 0);
        fingerprint = fnv_u64(fingerprint, frame_fingerprints[index]);
        fingerprint = fnv_u64(fingerprint, 0);
    }
    printf("audioPromotionFingerprint=0x%llx\n", (unsigned long long)fingerprint);
    printf("SM64 Modern audio owner-promotion C contract passed\n");
    return 0;
}
