#include <stdint.h>
#include <stdio.h>
#include <math.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
static uint64_t h8(uint64_t h, uint8_t v) { h ^= v; return h * FNV_PRIME; }
static uint64_t h16(uint64_t h, uint16_t v) { for (unsigned i = 0; i < 2; ++i) h = h8(h, (uint8_t)(v >> (i * 8u))); return h; }
static uint64_t h32(uint64_t h, uint32_t v) { for (unsigned i = 0; i < 4; ++i) h = h8(h, (uint8_t)(v >> (i * 8u))); return h; }
static uint64_t hf(uint64_t h, float v) { uint32_t bits; __builtin_memcpy(&bits, &v, sizeof(bits)); return h32(h, bits); }
static float approach(float current, float target, float inc, float dec) {
    if (current < target) { current += inc; if (current > target) current = target; }
    else { current -= dec; if (current < target) current = target; }
    return current;
}
static uint64_t hash_result(uint64_t h, uint8_t intent, uint32_t action, uint32_t arg,
                            uint16_t state, float forward, float vx, float vy, float vz,
                            uint8_t hasPunch, uint32_t punchArg, uint16_t animation,
                            uint32_t punchTransition, uint32_t flags, uint8_t punchState,
                            uint8_t sound, uint8_t hasSlope, float slopeForward,
                            float slopeX, float slopeZ, uint8_t groundResult, uint8_t dust) {
    h = h8(h, intent); h = h32(h, action); h = h32(h, arg); h = h16(h, state);
    h = h16(h, 0); h = hf(h, forward); h = hf(h, vx); h = hf(h, vy); h = hf(h, vz);
    h = h8(h, hasPunch);
    if (hasPunch) {
        h = h32(h, punchArg); h = h16(h, animation); h = h32(h, punchTransition);
        h = h32(h, flags); h = h8(h, punchState); h = h8(h, sound);
    }
    h = h8(h, hasSlope);
    if (hasSlope) { h = hf(h, slopeForward); h = hf(h, slopeX); h = hf(h, slopeZ); }
    h = h8(h, groundResult); h = h8(h, dust); return h;
}

int main(void) {
    uint64_t h = FNV_OFFSET;
    const uint32_t NONE = UINT32_MAX;
    const uint8_t NONE8 = UINT8_MAX;

    /* actionArg 0, first punch, positive slope deceleration, ground step none */
    float forward = approach(12.0f, 0.0f, 1.0f, 1.0f);
    h = hash_result(h, 0, NONE, 1, 1, forward, 0.0f, 0.0f, forward,
                    1, 1, 0x67, NONE, 0x00100000, NONE8, 1,
                    1, forward, 0.0f, forward, 1, 1);

    /* actionArg 2 at animation end transitions to walking */
    forward = approach(12.0f, 0.0f, 1.0f, 1.0f);
    h = hash_result(h, 0, 0x04000440, 0, 0, forward, 0.0f, 0.0f, forward,
                    1, 0, 0x69, 0x04000440, 0, NONE8, 0,
                    1, forward, 0.0f, forward, 1, 1);

    /* above-slide and backward speed exit before the punch sequence */
    h = hash_result(h, 1, 0x00000050, 0, 0, -2.0f, 0.0f, 0.0f, -2.0f,
                    0, 0, 0, NONE, 0, NONE8, 0, 0, 0, 0, 0, NONE8, 0);

    /* held A on the first action frame enters jump kick with y velocity 20 */
    h = hash_result(h, 2, 0x018008AC, 0, 0, 12.0f, 0.0f, 20.0f, 12.0f,
                    0, 0, 0, NONE, 0, NONE8, 0, 0, 0, 0, 0, NONE8, 0);

    /* negative speed is pushed toward zero, then receives slope acceleration */
    float adjusted = -4.0f + 8.0f;
    if (adjusted >= 0.0f) adjusted = 0.0f;
    float slopeForward = adjusted + 1.7f * sqrtf(0.6f * 0.6f);
    float slopeZ = slopeForward;
    h = hash_result(h, 0, NONE, 1, 1, slopeForward, 0.0f, 0.0f, slopeZ,
                    1, 1, 0x67, NONE, 0x00100000, NONE8, 1,
                    1, slopeForward, 0.0f, slopeZ, 1, 1);

    /* a high starting position leaves the ground on the first quarter */
    forward = approach(12.0f, 0.0f, 1.0f, 1.0f);
    h = hash_result(h, 3, 0x0100088C, 0, 0, forward, 0.0f, 0.0f, forward,
                    1, 1, 0x67, NONE, 0x00100000, NONE8, 1,
                    1, forward, 0.0f, forward, 0, 0);

    printf("marioMovePunchFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
