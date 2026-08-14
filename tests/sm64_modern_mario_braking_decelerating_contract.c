#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define NONE32 UINT32_MAX
#define NONE16 UINT16_MAX
#define NONE8 UINT8_MAX
static uint64_t h8(uint64_t h, uint8_t v) { h ^= v; return h * FNV_PRIME; }
static uint64_t h16(uint64_t h, uint16_t v) { for (unsigned i = 0; i < 2; ++i) h = h8(h, (uint8_t)(v >> (i * 8u))); return h; }
static uint64_t h32(uint64_t h, uint32_t v) { for (unsigned i = 0; i < 4; ++i) h = h8(h, (uint8_t)(v >> (i * 8u))); return h; }
static uint64_t hf(uint64_t h, float v) { uint32_t bits; __builtin_memcpy(&bits, &v, sizeof(bits)); return h32(h, bits); }
static float approach(float current, float target, float inc, float dec) {
    if (current < target) { current += inc; if (current > target) current = target; }
    else { current -= dec; if (current < target) current = target; }
    return current;
}

static uint64_t braking(uint64_t h, uint8_t intent, uint32_t action, float forward,
                        uint8_t ground, uint16_t animation, uint8_t dust, uint8_t reflected,
                        uint8_t hasSlope, float slopeForward, float slopeX, float slopeZ) {
    h = h8(h, intent); h = h32(h, action); h = h32(h, 0); h = h16(h, 0);
    h = hf(h, forward); h = hf(h, 0.0f); h = hf(h, 0.0f); h = hf(h, forward);
    h = h8(h, hasSlope);
    if (hasSlope) { h = hf(h, slopeForward); h = hf(h, slopeX); h = hf(h, slopeZ); }
    h = h8(h, ground); h = h16(h, animation); h = h8(h, dust); return h8(h, reflected);
}

static uint64_t decelerating(uint64_t h, uint8_t intent, uint32_t action, uint32_t arg,
                             float forward, float vx, float vy, float vz, uint8_t ground,
                             uint16_t animation, uint32_t acceleration, uint8_t dust,
                             uint8_t reflected) {
    h = h8(h, intent); h = h32(h, action); h = h32(h, arg); h = h16(h, 0);
    h = hf(h, forward); h = hf(h, vx); h = hf(h, vy); h = hf(h, vz);
    h = h8(h, ground); h = h16(h, animation); h = h32(h, acceleration);
    h = h8(h, dust); return h8(h, reflected);
}

int main(void) {
    uint64_t h = FNV_OFFSET;

    float forward = approach(12.0f, 0.0f, 4.0f, 4.0f);
    h = braking(h, 0, NONE32, forward, 1, 0x000F, 1, 0, 1, forward, 0.0f, forward);

    forward = approach(3.0f, 0.0f, 4.0f, 4.0f);
    h = braking(h, 1, 0x0C00023D, forward, NONE8, NONE16, 0, 0, 1, forward, 0.0f, forward);

    forward = approach(12.0f, 0.0f, 4.0f, 4.0f);
    h = braking(h, 2, 0x00800457, forward, NONE8, NONE16, 0, 0, 1, forward, 0.0f, forward);

    forward = approach(24.0f, 0.0f, 4.0f, 4.0f);
    h = braking(h, 7, 0x00020462, forward, 2, NONE16, 0, 1, 1, forward, 0.0f, forward);

    forward = approach(3.0f, 0.0f, 1.0f, 1.0f);
    h = decelerating(h, 0, NONE32, 0, forward, 0.0f, 0.0f, forward, 1,
                     0x0048, UINT32_C(0x8000), 0, 0);

    forward = approach(1.0f, 0.0f, 1.0f, 1.0f);
    h = decelerating(h, 7, 0x0C400201, 0, forward, 0.0f, 0.0f, forward, NONE8,
                     NONE16, 0, 0, 0);

    forward = approach(3.0f, 0.0f, 1.0f, 1.0f);
    h = decelerating(h, 0, NONE32, 0, forward, 0.0f, 0.0f, forward, 1,
                     0x00C3, 0, 1, 0);

    h = decelerating(h, 3, 0x0188088A, 1, 30.0f, 0.0f, 20.0f, 30.0f,
                     NONE8, NONE16, 0, 0, 0);

    h = decelerating(h, 2, 0x03000880, 0, 3.0f, 0.0f, 0.0f, 3.0f,
                     NONE8, NONE16, 0, 0, 0);

    forward = approach(3.0f, 0.0f, 1.0f, 1.0f);
    h = decelerating(h, 0, NONE32, 0, 0.0f, 0.0f, 0.0f, 0.0f, 2,
                     0x0048, UINT32_C(0x1000), 0, 0);

    h = decelerating(h, 0, NONE32, 0, -2.0f, -0.0f, 0.0f, -2.0f, 2,
                     0x00C3, 0, 1, 1);

    printf("marioBrakingDeceleratingFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
