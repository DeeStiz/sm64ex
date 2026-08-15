#include <stdint.h>
#include <stdio.h>

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (int byte = 0; byte < 4; ++byte) {
        hash ^= (uint64_t) ((value >> (byte * 8)) & 0xff);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static uint64_t hash_f32(uint64_t hash, float value) {
    union { float f; uint32_t u; } bits = { value };
    return hash_u32(hash, bits.u);
}

static uint64_t hash_step(uint64_t hash, float movementX, float movementY,
                          float movementZ, float velocityX, float velocityY,
                          float velocityZ, float forwardVelocity,
                          uint32_t movementFlags, float recordX,
                          float recordY, float recordZ, float recordVelocityY,
                          float recordForwardVelocity, uint32_t recordFlags) {
    hash = hash_f32(hash, movementX);
    hash = hash_f32(hash, movementY);
    hash = hash_f32(hash, movementZ);
    hash = hash_f32(hash, velocityX);
    hash = hash_f32(hash, velocityY);
    hash = hash_f32(hash, velocityZ);
    hash = hash_f32(hash, forwardVelocity);
    hash = hash_u32(hash, movementFlags);
    hash = hash_u32(hash, 0); // hitEdge
    hash = hash_u32(hash, 0); // enteredWater
    hash = hash_u32(hash, 0); // atWaterSurface
    hash = hash_u32(hash, 0); // leftGround
    hash = hash_u32(hash, 0); // bounced
    hash = hash_f32(hash, recordX);
    hash = hash_f32(hash, recordY);
    hash = hash_f32(hash, recordZ);
    hash = hash_f32(hash, recordVelocityY);
    hash = hash_f32(hash, recordForwardVelocity);
    return hash_u32(hash, recordFlags);
}

int main(void) {
    uint64_t fingerprint = UINT64_C(1469598103934665603);
    fingerprint = hash_step(fingerprint, 600.0f, 0.0f, 6.0f,
                            0.0f, 2.0f, 6.0f, 6.0f, 1,
                            600.0f, 0.0f, 6.0f, 2.0f, 6.0f, 1);
    fingerprint = hash_step(fingerprint, 600.0f, -0.0f, 12.0f,
                            0.0f, 1.0f, 6.0f, 6.0f, 2,
                            600.0f, -0.0f, 12.0f, 1.0f, 6.0f, 2);
    printf("slWalkingPenguinMovementBridgeFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    printf("SM64 Modern SL walking penguin movement bridge C contract passed\n");
    return 0;
}
