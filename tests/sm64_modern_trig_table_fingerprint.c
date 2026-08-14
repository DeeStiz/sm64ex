#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "PR/ultratypes.h"

#define AVOID_UB 1
#include "trig_tables.inc.c"

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (uint32_t byte = 0; byte < 4u; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT32_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

int main(void) {
    uint64_t hash = FNV_OFFSET;
    for (uint32_t index = 0; index < 0x1400u; ++index) {
        uint32_t bits;
        memcpy(&bits, &gSineTable[index], sizeof(bits));
        hash = hash_u32(hash, bits);
    }
    for (uint32_t index = 0; index < 0x1000u; ++index) {
        uint32_t bits;
        memcpy(&bits, &gSineTable[0x400u + index], sizeof(bits));
        hash = hash_u32(hash, bits);
    }
    for (uint32_t index = 0; index < 0x401u; ++index) {
        hash = hash_u32(hash, (uint16_t) gArctanTable[index]);
    }
    printf("0x%016llx\n", (unsigned long long) hash);
    return 0;
}
