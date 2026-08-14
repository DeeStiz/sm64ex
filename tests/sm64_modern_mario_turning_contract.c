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

static uint64_t result(uint64_t h, uint8_t intent, uint32_t action, uint16_t face,
                       float forward, float vx, float vy, float vz, uint8_t hasSlope,
                       float slopeForward, float slopeX, float slopeZ, uint8_t ground,
                       uint16_t animation, uint8_t dust, uint8_t terrain) {
    h = h8(h, intent); h = h32(h, action); h = h32(h, 0); h = h16(h, face);
    h = hf(h, forward); h = hf(h, vx); h = hf(h, vy); h = hf(h, vz);
    h = h8(h, hasSlope);
    if (hasSlope) { h = hf(h, slopeForward); h = hf(h, slopeX); h = hf(h, slopeZ); }
    h = h8(h, ground); h = h16(h, animation); h = h8(h, dust); return h8(h, terrain);
}

int main(void) {
    uint64_t h = FNV_OFFSET;
    const uint16_t face = 0x8000;

    h = result(h, 1, 0x00000050, face, 20.0f, 0.0f, 0.0f, 20.0f,
               0, 0, 0, 0, NONE8, NONE16, 0, 0);
    h = result(h, 2, 0x01000887, face, 20.0f, 0.0f, 0.0f, 20.0f,
               0, 0, 0, 0, NONE8, NONE16, 0, 0);
    h = result(h, 3, 0x04000445, face, 20.0f, 0.0f, 0.0f, 20.0f,
               0, 0, 0, 0, NONE8, NONE16, 0, 0);
    h = result(h, 4, 0x04000440, 0, 20.0f, 0.0f, 0.0f, 20.0f,
               0, 0, 0, 0, NONE8, NONE16, 0, 0);

    float forward = approach(20.0f, 0.0f, 4.0f, 4.0f);
    h = result(h, 0, NONE32, face, forward, 0.0f, 0.0f, -forward,
               1, forward, 0.0f, -forward, 1, 0x00BD, 1, 1);

    forward = approach(24.0f, 0.0f, 4.0f, 4.0f);
    h = result(h, 0, NONE32, face, forward, 0.0f, 0.0f, -forward,
               1, forward, 0.0f, -forward, 1, 0x00BC, 1, 1);

    forward = approach(4.0f, 0.0f, 4.0f, 4.0f);
    h = result(h, 5, 0x00000444, 0, 8.0f, 0.0f, 0.0f, 8.0f,
               1, 0.0f, 0.0f, -0.0f, NONE8, NONE16, 0, 0);

    forward = approach(16.0f, 0.0f, 4.0f, 4.0f);
    h = result(h, 4, 0x04000440, 0, -forward, -0.0f, 0.0f, -forward,
               1, forward, 0.0f, -forward, 1, 0x00BD, 1, 1);

    forward = approach(20.0f, 0.0f, 4.0f, 4.0f);
    h = result(h, 6, 0x0100088C, face, forward, 0.0f, 0.0f, -forward,
               1, forward, 0.0f, -forward, 0, NONE16, 0, 1);

    printf("marioTurningFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
