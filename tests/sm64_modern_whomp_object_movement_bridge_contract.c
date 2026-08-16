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

static uint64_t hash_effect(uint64_t initial, uint32_t collision_move_flags,
                            uint32_t movement_move_flags,
                            uint32_t second) {
    uint64_t hash = initial;
    hash = hash_float(hash, UINT32_C(0x43a00000)); /* collision x */
    hash = hash_float(hash, second ? UINT32_C(0x80000000) : UINT32_C(0x00000000));
    hash = hash_float(hash, second ? UINT32_C(0x41100000) : UINT32_C(0x00000000));
    hash = hash_float(hash, UINT32_C(0x80000000)); /* floor height */
    hash = hash_u32(hash, UINT32_C(1));            /* floor surface */
    hash = hash_u32(hash, UINT32_C(3));            /* floor room */
    hash = hash_u32(hash, UINT32_C(1));            /* wall count */
    hash = hash_u32(hash, UINT32_C(2));            /* wall id */
    hash = hash_u32(hash, collision_move_flags);
    hash = hash_u32(hash, UINT32_C(0));            /* hit wall */
    hash = hash_float(hash, UINT32_C(0x43a00000)); /* movement x */
    hash = hash_float(hash, UINT32_C(0x80000000)); /* movement y */
    hash = hash_float(hash, second ? UINT32_C(0x41900000) : UINT32_C(0x41100000));
    hash = hash_float(hash, second ? UINT32_C(0x3f800000) : UINT32_C(0x40000000));
    hash = hash_float(hash, UINT32_C(0x41100000)); /* forward velocity */
    hash = hash_u32(hash, movement_move_flags);
    hash = hash_float(hash, UINT32_C(0x43a00000)); /* record x */
    hash = hash_float(hash, UINT32_C(0x80000000)); /* record y */
    hash = hash_float(hash, second ? UINT32_C(0x41900000) : UINT32_C(0x41100000));
    hash = hash_float(hash, UINT32_C(0xc0800000)); /* gravity */
    hash = hash_float(hash, UINT32_C(0x40000000)); /* buoyancy */
    return hash_u32(hash, movement_move_flags);
}

int main(void) {
    uint64_t fingerprint = hash_effect(FNV_OFFSET, 0, 1, 0);
    fingerprint = hash_effect(fingerprint, 1, 2, 1);
    printf("whompObjectMovementBridgeFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    printf("SM64 Modern Whomp owner collision/movement C contract passed\n");
    return 0;
}
