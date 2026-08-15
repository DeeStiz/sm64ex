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
    const uint64_t pound[] = { 0x1, UINT64_C(0xc28c0000), 0, 1 };
    const uint64_t drop[] = { 0x2, UINT64_C(0xc2340000), UINT64_C(0xc2340000), 2 };
    const uint64_t release[] = { 0x6, UINT64_C(0xc2340000), UINT64_C(0xc33e0000), 1, 3 };
    const uint64_t coins[] = { 0x18, 0, 1, 11 };
    const uint64_t gate[] = { 0x1f, 1 };
    const uint64_t bridgePost[] = { 2, 0, 0x1, 0, 0 };
    const uint64_t bridgeGate[] = { 3, 1, 0x3e0, 0, 1 };
    fingerprint = hash_values(fingerprint, pound, sizeof(pound) / sizeof(pound[0]));
    fingerprint = hash_values(fingerprint, drop, sizeof(drop) / sizeof(drop[0]));
    fingerprint = hash_values(fingerprint, release, sizeof(release) / sizeof(release[0]));
    fingerprint = hash_values(fingerprint, coins, sizeof(coins) / sizeof(coins[0]));
    fingerprint = hash_values(fingerprint, gate, sizeof(gate) / sizeof(gate[0]));
    fingerprint = hash_values(fingerprint, bridgePost, sizeof(bridgePost) / sizeof(bridgePost[0]));
    fingerprint = hash_values(fingerprint, bridgeGate, sizeof(bridgeGate) / sizeof(bridgeGate[0]));
    printf("chainChompReleaseFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    return 0;
}
