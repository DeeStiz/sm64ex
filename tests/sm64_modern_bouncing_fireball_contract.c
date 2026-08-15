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

static uint64_t hash_values(uint64_t hash, const uint64_t *values, size_t count) {
    for (size_t index = 0; index < count; ++index) hash = hash_u64(hash, values[index]);
    return hash;
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    /* Filled from the independently reviewed Swift state/effect traces. */
    const uint64_t far[] = { 0x40, 0, 1, 0, 0, 0, 0, 0, 0, UINT64_C(0xbf800000) };
    const uint64_t activate[] = { 0x41, 1, 2, 0, 0, 0, 0, 0, 0, UINT64_C(0xbf800000) };
    const uint64_t flame[] = { 0x46, 1, 1, 0, UINT64_C(0x41f00000), 0, 0, 1, 0, UINT64_C(0x40a00000) };
    const uint64_t expire[] = { 0x70, 0, 0x66, 0, UINT64_C(0x41f00000), 0, 0, 1, 1, UINT64_C(0xbf800000) };
    const uint64_t childLand[] = { 0x48, 1, 1, UINT64_C(0x41f00000), 0, 0 };
    const uint64_t childExpire[] = { 0x60, 1, 0x66, UINT64_C(0x41f00000), 0, 1 };
    const uint64_t bridgeParent[] = { 1, 0, 1, 0x42, 1, UINT64_C(0x40900000), 0 };
    const uint64_t routedDeletion[] = { 1, 11, 1 };
    fingerprint = hash_values(fingerprint, far, sizeof(far) / sizeof(far[0]));
    fingerprint = hash_values(fingerprint, activate, sizeof(activate) / sizeof(activate[0]));
    fingerprint = hash_values(fingerprint, flame, sizeof(flame) / sizeof(flame[0]));
    fingerprint = hash_values(fingerprint, expire, sizeof(expire) / sizeof(expire[0]));
    fingerprint = hash_values(fingerprint, childLand, sizeof(childLand) / sizeof(childLand[0]));
    fingerprint = hash_values(fingerprint, childExpire, sizeof(childExpire) / sizeof(childExpire[0]));
    fingerprint = hash_values(fingerprint, bridgeParent, sizeof(bridgeParent) / sizeof(bridgeParent[0]));
    fingerprint = hash_values(fingerprint, routedDeletion, sizeof(routedDeletion) / sizeof(routedDeletion[0]));
    printf("bouncingFireballFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    return 0;
}
