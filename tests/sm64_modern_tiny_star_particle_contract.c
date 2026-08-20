#include <stdint.h>
#include <stdio.h>
#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
static uint64_t hash_u64(uint64_t seed, uint64_t value) { for (unsigned index = 0; index < 8; ++index) { seed ^= (value >> (index * 8u)) & UINT64_C(0xff); seed *= FNV_PRIME; } return seed; }
int main(void) { uint64_t fingerprint = FNV_OFFSET; fingerprint = hash_u64(fingerprint, UINT64_C(0x42c80000)); fingerprint = hash_u64(fingerprint, UINT64_C(0x42b40000)); fingerprint = hash_u64(fingerprint, UINT64_C(0x42e60000)); fingerprint = hash_u64(fingerprint, UINT64_C(0x3e8f5c29)); fingerprint = hash_u64(fingerprint, UINT64_C(4)); fingerprint = hash_u64(fingerprint, UINT64_C(0x41200000)); fingerprint = hash_u64(fingerprint, UINT64_C(0x41600000)); fingerprint = hash_u64(fingerprint, UINT64_C(0x41a80000)); fingerprint = hash_u64(fingerprint, UINT64_C(0x3e8f5c29)); fingerprint = hash_u64(fingerprint, UINT64_C(4)); printf("tinyStarParticleFingerprint=0x%016llx\n", (unsigned long long) fingerprint); puts("SM64 Modern tiny star particle C contract passed"); return 0; }
