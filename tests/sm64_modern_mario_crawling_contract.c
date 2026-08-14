#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define NONE32 UINT32_MAX
#define NONE16 UINT16_MAX
#define NONE8 UINT8_MAX

static uint64_t h8(uint64_t h, uint8_t v) { h ^= v; return h * FNV_PRIME; }
static uint64_t h16(uint64_t h, uint16_t v) {
    for (unsigned i = 0; i < 2; ++i) h = h8(h, (uint8_t)(v >> (i * 8u)));
    return h;
}
static uint64_t h32(uint64_t h, uint32_t v) {
    for (unsigned i = 0; i < 4; ++i) h = h8(h, (uint8_t)(v >> (i * 8u)));
    return h;
}

static uint64_t result(uint64_t h, uint8_t intent, uint32_t action,
                       uint32_t argument, uint16_t face, uint32_t accel,
                       uint16_t animation, uint8_t align, uint8_t stepSound,
                       uint8_t ground) {
    h = h8(h, intent); h = h32(h, action); h = h32(h, argument);
    h = h16(h, face); h = h32(h, accel); h = h16(h, animation);
    h = h8(h, align); h = h8(h, stepSound); return h8(h, ground);
}

int main(void) {
    uint64_t h = FNV_OFFSET;
    h = result(h, 1, UINT32_C(0x00000050), 0, 0, 0, NONE16, 0, 0, NONE8);
    h = result(h, 2, UINT32_C(0x0C008224), 0, 0, 0, NONE16, 0, 0, NONE8);
    h = result(h, 3, UINT32_C(0x03000880), 0, 0, 0, NONE16, 0, 0, NONE8);
    h = result(h, 4, UINT32_C(0x0188088A), 1, 0, 0, NONE16, 0, 0, NONE8);
    h = result(h, 5, UINT32_C(0x00800457), 0, 0, 0, NONE16, 0, 0, NONE8);
    h = result(h, 2, UINT32_C(0x0C008224), 0, 0, 0, NONE16, 0, 0, NONE8);
    h = result(h, 2, UINT32_C(0x0C008224), 0, 0, 0, NONE16, 0, 0, NONE8);
    h = result(h, 0, NONE32, 0, 0, UINT32_C(0x00040000), UINT16_C(0x0099), 1, 1, 1);
    h = result(h, 0, NONE32, 0, 0, UINT32_C(0x00040000), UINT16_C(0x0099), 1, 1, 2);
    h = result(h, 6, UINT32_C(0x0100088C), 0, 0, UINT32_C(0x00040000), NONE16, 0, 1, 0);

    printf("marioCrawlingFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
