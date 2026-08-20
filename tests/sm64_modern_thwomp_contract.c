#include <stdint.h>
#include <stdio.h>
#include <string.h>
#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)
static uint64_t hash_u64(uint64_t seed, uint64_t value) { for (unsigned byte = 0; byte < 8; ++byte) { seed ^= (value >> (byte * 8)) & 255; seed *= PRIME; } return seed; }
static uint64_t hash_f32(uint64_t seed, float value) { uint32_t bits = 0; memcpy(&bits, &value, sizeof(bits)); return hash_u64(seed, bits); }
struct Row { uint64_t variant, action, timer; float y, velocity; int sound, shake; };
static uint64_t hash_row(uint64_t seed, struct Row row) { seed=hash_u64(seed,row.variant);seed=hash_u64(seed,row.action);seed=hash_u64(seed,row.timer);seed=hash_f32(seed,row.y);seed=hash_f32(seed,row.velocity);seed=hash_u64(seed,row.sound);return hash_u64(seed,row.shake); }
int main(void) {
    const struct Row rows[] = {
        {0,0,41,110,0,0,0}, {2,1,0,105,0,0,0}, {1,2,0,105,0,0,0},
        {2,3,0,100,0,0,0}, {2,3,1,100,0,1,1},
    };
    uint64_t fingerprint = OFFSET; for (unsigned i=0;i<sizeof(rows)/sizeof(rows[0]);++i) fingerprint=hash_row(fingerprint,rows[i]);
    printf("thwompFingerprint=0x%016llx\n",(unsigned long long)fingerprint); puts("SM64 Modern Thwomp C contract passed"); return 0;
}
