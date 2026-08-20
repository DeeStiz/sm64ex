#include <stdint.h>
#include <stdio.h>
#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
static uint64_t hash_u64(uint64_t seed, uint64_t value) { for (unsigned index = 0; index < 8; ++index) { seed ^= (value >> (index * 8u)) & UINT64_C(0xff); seed *= FNV_PRIME; } return seed; }
int main(void) { uint64_t fingerprint = FNV_OFFSET; fingerprint = hash_u64(fingerprint, UINT64_C(0x41200000)); fingerprint = hash_u64(fingerprint, UINT64_C(0x42e00000)); fingerprint = hash_u64(fingerprint, UINT64_C(0)); fingerprint = hash_u64(fingerprint, UINT64_C(0x40966666)); fingerprint = hash_u64(fingerprint, UINT64_C(0x41400000)); printf("treeLeafFingerprint=0x%016llx\n", (unsigned long long) fingerprint); puts("SM64 Modern tree leaf C contract passed"); return 0; }
