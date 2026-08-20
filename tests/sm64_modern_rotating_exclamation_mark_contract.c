#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) { hash ^= (value >> (byte * 8u)) & UINT64_C(0xff); hash *= FNV_PRIME; }
    return hash;
}
int main(void) {
    const int32_t yaws[] = {0x7fff + 0x800, -0x100 + 0x800};
    const int delete_flags[] = {0, 1};
    uint64_t fingerprint = FNV_OFFSET;
    for (unsigned i = 0; i < 2; ++i) {
        if (i == 0 && yaws[i] != 0x87ff) return 1;
        if (i == 1 && yaws[i] != 0x700) return 1;
        fingerprint = hash_u64(fingerprint, (uint64_t)(int64_t)yaws[i]);
        fingerprint = hash_u64(fingerprint, (uint64_t)delete_flags[i]);
    }
    printf("rotatingExclamationMarkFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern rotating exclamation mark C contract passed");
    return 0;
}
