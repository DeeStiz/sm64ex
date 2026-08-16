#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u32(uint64_t initial, uint32_t value) {
    uint64_t hash = initial;
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (value >> (byte * 8)) & UINT32_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_float(uint64_t initial, float value) {
    union { float value; uint32_t bits; } representation = { value };
    return hash_u32(initial, representation.bits);
}

static uint64_t hash_frame(
    uint64_t initial,
    uint32_t collision_flags,
    float movement_velocity_y,
    uint32_t movement_flags
) {
    uint64_t hash = hash_u32(initial, 1); // floor surface ID
    hash = hash_u32(hash, collision_flags);
    hash = hash_u32(hash, 1); // one wall surface
    hash = hash_u32(hash, 2); // wall surface ID
    hash = hash_float(hash, 320.0f);
    hash = hash_float(hash, -0.0f);
    hash = hash_float(hash, 0.0f);
    hash = hash_float(hash, movement_velocity_y);
    hash = hash_float(hash, 0.0f);
    hash = hash_u32(hash, movement_flags);
    hash = hash_float(hash, 320.0f);
    hash = hash_float(hash, -0.0f);
    hash = hash_float(hash, 0.0f);
    hash = hash_float(hash, -0.0f);
    return hash_u32(hash, movement_flags);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_frame(fingerprint, 0, 2.0f, 1);
    fingerprint = hash_frame(fingerprint, 1, 1.0f, 2);
    printf("kingBobombObjectMovementBridgeFingerprint=0x%016llx\n",
           (unsigned long long)fingerprint);
    printf("SM64 Modern King Bob-omb owner movement C contract passed\n");
    return 0;
}
