#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u8(uint64_t h, uint8_t v) { return (h ^ v) * FNV_PRIME; }
static uint64_t hash_u16(uint64_t h, uint16_t v) {
    for (unsigned i = 0; i < 2; ++i) { h ^= (v >> (i * 8u)) & 0xffu; h *= FNV_PRIME; }
    return h;
}
static uint64_t hash_mutation(uint64_t h, int16_t health, uint8_t heal,
                              uint8_t hurt, uint8_t rumble) {
    h = hash_u16(h, (uint16_t) health); h = hash_u8(h, heal); h = hash_u8(h, hurt);
    return hash_u8(h, rumble);
}

int main(void) {
    uint64_t h = FNV_OFFSET;
    h = hash_mutation(h, 0x3fc, 0, 0, 0);
    h = hash_mutation(h, 0x880, 0, 0, 0);
    h = hash_mutation(h, 0x24d, 0, 0, 1);
    h = hash_mutation(h, 0x500, 1, 0, 0);
    h = hash_mutation(h, 0x0ff, 0, 0, 0);
    printf("marioHealthFingerprint=0x%016llx\n", (unsigned long long) h);
    return 0;
}
