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

static uint64_t result(uint64_t h, uint8_t body, uint8_t intent, uint32_t action,
                       uint16_t timer, uint16_t face, uint16_t slideYaw,
                       float forward, float slideX, float slideZ, float vx, float vy, float vz,
                       uint8_t hasSliding, uint8_t slidingStopped, uint16_t slidingFace,
                       uint16_t slidingYaw, float slidingForward, float slidingX, float slidingZ,
                       uint8_t ground, uint16_t animation, uint8_t dust, uint8_t star,
                       uint8_t reflected, uint8_t align, uint8_t tilt, uint8_t hoohoo) {
    h = h8(h, body); h = h8(h, intent); h = h32(h, action); h = h32(h, 0); h = h16(h, timer);
    h = h16(h, face); h = h16(h, slideYaw); h = hf(h, forward); h = hf(h, slideX); h = hf(h, slideZ);
    h = hf(h, vx); h = hf(h, vy); h = hf(h, vz); h = h8(h, hasSliding);
    if (hasSliding) {
        h = h8(h, slidingStopped); h = h16(h, slidingFace); h = h16(h, slidingYaw);
        h = hf(h, slidingForward); h = hf(h, slidingX); h = hf(h, slidingZ);
    }
    h = h8(h, ground); h = h16(h, animation); h = h8(h, dust); h = h8(h, star);
    h = h8(h, reflected); h = h8(h, align); h = h8(h, tilt); return h8(h, hoohoo);
}

int main(void) {
    uint64_t h = FNV_OFFSET;
    const float slide10 = 10.0f * 0.92f;
    const float slide20 = 20.0f * 0.92f;
    const float slide2 = 2.0f * 0.92f;
    const float slideVery = 10.0f * 0.98f;
    const float slideWall = slideVery * 0.9f;

    h = result(h, 0, 0, NONE32, 1, 0, 0, slide10, 0.0f, slide10,
               0.0f, 0.0f, slide10, 1, 0, 0, 0, slide10, 0.0f, slide10,
               1, 0x0091, 1, 0, 0, 1, 1, 0);

    h = result(h, 0, 1, 0x03000880, 5, 0, 0, 10.0f, 0.0f, 10.0f,
               0.0f, 0.0f, 10.0f, 0, 0, 0, 0, 0, 0, 0,
               NONE8, NONE16, 0, 0, 0, 0, 1, 0);

    h = result(h, 1, 2, 0x010008AD, 5, 0, 0, -10.0f, 0.0f, -10.0f,
               0.0f, 0.0f, -10.0f, 0, 0, 0, 0, 0, 0, 0,
               NONE8, NONE16, 0, 0, 0, 0, 0, 0);

    h = result(h, 0, 3, 0x0C00023E, 1, 0, 0, 0.0f, 0.0f, 0.0f,
               0.0f, 0.0f, 0.0f, 1, 1, 0, 0, 0.0f, 0.0f, 0.0f,
               NONE8, NONE16, 0, 0, 0, 0, 1, 0);

    h = result(h, 0, 5, 0x00020466, 1, 0, 0, slide20, 0.0f, slide20,
               0.0f, 0.0f, slide20, 1, 0, 0, 0, slide20, 0.0f, slide20,
               2, NONE16, 0, 1, 1, 1, 1, 0);

    h = result(h, 0, 4, 0x0300088E, 1, 0, 0, slide20, 0.0f, slide20,
               0.0f, 0.0f, slide20, 1, 0, 0, 0, slide20, 0.0f, slide20,
               0, NONE16, 0, 0, 0, 0, 1, 0);

    h = result(h, 0, 0, NONE32, 1, 0, 0x8000, slideVery, 0.0f, -slideWall,
               0.0f, 0.0f, -slideWall, 1, 0, 0, 0x8000, slideVery, 0.0f, -slideWall,
               2, 0x0091, 0, 0, 0, 1, 1, 0);

    printf("marioSlideFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
