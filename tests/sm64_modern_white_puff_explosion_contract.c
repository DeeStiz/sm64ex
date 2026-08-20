#include <stdint.h>
#include <stdio.h>
#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
static uint64_t hash_u64(uint64_t seed, uint64_t value) { for (unsigned i = 0; i < 8; ++i) { seed ^= (value >> (i * 8u)) & UINT64_C(0xff); seed *= FNV_PRIME; } return seed; }
int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_u64(fingerprint, UINT64_C(0x41300000));
    fingerprint = hash_u64(fingerprint, UINT64_C(0x41b00000));
    fingerprint = hash_u64(fingerprint, UINT64_C(0xbf800000));
    fingerprint = hash_u64(fingerprint, UINT64_C(0x3f800000));
    fingerprint = hash_u64(fingerprint, UINT64_C(233));
    fingerprint = hash_u64(fingerprint, UINT64_C(0x43690000));
    fingerprint = hash_u64(fingerprint, UINT64_C(0));
    printf("whitePuffExplosionFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern white puff explosion C contract passed");
    return 0;
}
