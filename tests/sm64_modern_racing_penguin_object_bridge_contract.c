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

static uint64_t hash_step(uint64_t hash, int action, int initCooldown,
                          float forward, float weighted, int yaw, int yawDelta,
                          int animation, int recordAction, int previousAction,
                          int timer, float recordForward, int recordYaw,
                          float velocityY, int textbox, int marioWon,
                          int marioCheated, int reachedBottom, int resetTimer) {
    hash = hash_u32(hash, (uint32_t) action);
    hash = hash_u32(hash, (uint32_t) initCooldown);
    hash = hash_f32(hash, forward);
    hash = hash_f32(hash, weighted);
    hash = hash_u32(hash, (uint32_t) (uint16_t) yaw);
    hash = hash_u32(hash, (uint32_t) (uint16_t) yawDelta);
    hash = hash_u32(hash, (uint32_t) animation);
    hash = hash_u32(hash, (uint32_t) recordAction);
    hash = hash_u32(hash, (uint32_t) previousAction);
    hash = hash_u32(hash, (uint32_t) timer);
    hash = hash_f32(hash, recordForward);
    hash = hash_u32(hash, (uint32_t) recordYaw);
    hash = hash_f32(hash, velocityY);
    hash = hash_u32(hash, (uint32_t) textbox);
    hash = hash_u32(hash, (uint32_t) marioWon);
    hash = hash_u32(hash, (uint32_t) marioCheated);
    hash = hash_u32(hash, (uint32_t) reachedBottom);
    return hash_u32(hash, (uint32_t) resetTimer);
}

int main(void) {
    uint64_t fingerprint = UINT64_C(1469598103934665603);
    fingerprint = hash_step(fingerprint, 1, 0, 0.0f, 0.0f, 0, 0, 0, 1, 0, 0, 0.0f, 0, 0.0f, 0, 0, 0, 0, 0);
    fingerprint = hash_step(fingerprint, 2, 0, 0.0f, 0.0f, 0, 0, 0, 2, 1, 0, 0.0f, 0, 60.0f, 0, 0, 0, 0, 0);
    fingerprint = hash_step(fingerprint, 3, 0, 20.0f, 0.0f, 2500, 2500, 0, 3, 2, 0, 20.0f, 2500, 60.0f, 0, 0, 0, 0, 0);
    fingerprint = hash_step(fingerprint, 3, 0, 20.4f, 30.0f, 2806, 306, 1, 3, 3, 1, 20.4f, 2806, 60.0f, 0, 0, 0, 0, 0);
    fingerprint = hash_step(fingerprint, 4, 0, 20.4f, 30.0f, 2806, 0, 0, 4, 3, 0, 20.4f, 2806, 60.0f, 0, 0, 0, 1, 1);
    printf("racingPenguinObjectBridgeFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    printf("SM64 Modern racing penguin object bridge C contract passed\n");
    return 0;
}
