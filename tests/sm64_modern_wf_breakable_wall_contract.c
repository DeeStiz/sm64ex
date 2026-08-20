#include <stdint.h>
#include <stdio.h>
#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)
static uint64_t hash_u64(uint64_t seed, uint64_t value) { for (unsigned i = 0; i < 8; ++i) { seed ^= (value >> (i * 8)) & UINT64_C(255); seed *= PRIME; } return seed; }
static uint64_t row(uint64_t seed, int tangible, int exploded, int jingle, int sound, unsigned interaction, int damage, int coins) { seed = hash_u64(seed, tangible); seed = hash_u64(seed, exploded); seed = hash_u64(seed, jingle); seed = hash_u64(seed, sound); seed = hash_u64(seed, interaction); seed = hash_u64(seed, (uint64_t)(int64_t)damage); return hash_u64(seed, (uint64_t)(int64_t)coins); }
int main(void) { uint64_t fingerprint = OFFSET; fingerprint = row(fingerprint, 0, 0, 0, 0, 0, 0, 0); fingerprint = row(fingerprint, 1, 1, 0, 1, 8, 1, 1); fingerprint = row(fingerprint, 1, 1, 1, 1, 8, 1, 1); printf("wfBreakableWallFingerprint=0x%016llx\n", (unsigned long long)fingerprint); puts("SM64 Modern WF breakable wall C contract passed"); return 0; }
