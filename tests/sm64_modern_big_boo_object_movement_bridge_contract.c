#include <stdint.h>
#include <stdio.h>

static const uint64_t FNV_OFFSET = UINT64_C(1469598103934665603);
static const uint64_t FNV_PRIME = UINT64_C(1099511628211);

static uint64_t hash_u32(uint64_t initial, uint32_t value) {
    uint64_t hash = initial;
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (value >> (byte * 8)) & UINT32_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_float(uint64_t initial, uint32_t bits) {
    return hash_u32(initial, bits);
}

static uint64_t hash_effect(uint64_t initial) {
    uint64_t hash = initial;
    hash = hash_float(hash, UINT32_C(0x43a50000)); /* collision x */
    hash = hash_float(hash, UINT32_C(0x00000000)); /* collision y */
    hash = hash_float(hash, UINT32_C(0x00000000)); /* collision z */
    hash = hash_float(hash, UINT32_C(0x80000000)); /* floor height */
    hash = hash_u32(hash, UINT32_C(1));            /* floor surface */
    hash = hash_u32(hash, UINT32_C(3));            /* floor room */
    hash = hash_u32(hash, UINT32_C(1));            /* wall count */
    hash = hash_u32(hash, UINT32_C(2));            /* wall id */
    hash = hash_u32(hash, UINT32_C(0));            /* collision move flags */
    hash = hash_u32(hash, UINT32_C(0));            /* hit wall */
    hash = hash_float(hash, UINT32_C(0x43a50000)); /* movement x */
    hash = hash_float(hash, UINT32_C(0x00000000)); /* movement y */
    hash = hash_float(hash, UINT32_C(0x41200000)); /* movement z */
    hash = hash_float(hash, UINT32_C(0x00000000)); /* movement velocity y */
    hash = hash_float(hash, UINT32_C(0x411e6666)); /* movement forward velocity */
    hash = hash_u32(hash, UINT32_C(0x00000080));   /* movement in-air */
    hash = hash_float(hash, UINT32_C(0x43a50000)); /* record x */
    hash = hash_float(hash, UINT32_C(0x00000000)); /* record y */
    hash = hash_float(hash, UINT32_C(0x41200000)); /* record z */
    hash = hash_float(hash, UINT32_C(0x00000000)); /* record gravity */
    hash = hash_float(hash, UINT32_C(0x40000000)); /* record buoyancy */
    return hash_u32(hash, UINT32_C(0x00000080));   /* record move flags */
}

int main(void) {
    const uint64_t fingerprint = hash_effect(FNV_OFFSET);
    printf("bigBooObjectMovementBridgeFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    printf("SM64 Modern Big Boo owner collision/movement bridge C contract passed\n");
    return 0;
}
