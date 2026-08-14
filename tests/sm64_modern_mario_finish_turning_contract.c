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

static uint64_t result(uint64_t h, uint8_t intent, uint32_t action, uint16_t face,
                       float forward, float vx, float vy, float vz, uint16_t animation,
                       uint8_t ground, uint8_t hasSlope, float slopeForward,
                       float slopeX, float slopeZ, uint16_t graphicsDelta) {
    h = h8(h, intent); h = h32(h, action); h = h32(h, 0); h = h16(h, face);
    h = hf(h, forward); h = hf(h, vx); h = hf(h, vy); h = hf(h, vz);
    h = h16(h, animation); h = h8(h, ground); h = h8(h, hasSlope);
    if (hasSlope) { h = hf(h, slopeForward); h = hf(h, slopeX); h = hf(h, slopeZ); }
    return h16(h, graphicsDelta);
}

int main(void) {
    uint64_t h = FNV_OFFSET;
    const float speed = 12.0f + 1.1f - 12.0f / 43.0f;

    h = result(h, 1, 0x00000050, 0, 12.0f, 0.0f, 0.0f, 12.0f,
               NONE16, NONE8, 0, 0, 0, 0, 0);
    h = result(h, 2, 0x01000887, 0, 12.0f, 0.0f, 0.0f, 12.0f,
               NONE16, NONE8, 0, 0, 0, 0, 0);

    h = result(h, 0, NONE32, 0, speed, 0.0f, 0.0f, speed,
               0x00BD, 1, 1, speed, 0.0f, speed, 0x8000);
    h = result(h, 3, 0x04000440, 0, speed, 0.0f, 0.0f, speed,
               0x00BD, 1, 1, speed, 0.0f, speed, 0x8000);
    h = result(h, 4, 0x0100088C, 0, speed, 0.0f, 0.0f, speed,
               0x00BD, 0, 1, speed, 0.0f, speed, 0x8000);

    printf("marioFinishTurningFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
