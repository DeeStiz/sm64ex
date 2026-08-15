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
                       uint32_t argument, uint16_t timer, uint16_t health,
                       uint16_t face, uint16_t animation, uint32_t accel,
                       uint8_t particle, uint8_t eyes, uint8_t rumble,
                       uint8_t stepSound, uint8_t sound, uint8_t ground) {
    h = h8(h, intent);
    h = h32(h, action);
    h = h32(h, argument);
    h = h16(h, timer);
    h = h16(h, health);
    h = h16(h, face);
    h = h16(h, animation);
    h = h32(h, accel);
    h = h8(h, particle);
    h = h8(h, eyes);
    h = h8(h, rumble);
    h = h8(h, stepSound);
    h = h8(h, sound);
    return h8(h, ground);
}

int main(void) {
    uint64_t h = FNV_OFFSET;

    /* A edge exits before timer increment. */
    h = result(h, 0, UINT32_C(0x010208B4), 0, 10, UINT16_C(0x1000), 0,
               NONE16, UINT32_C(0x80000000), 0, 0, 0, 0, NONE8, NONE8);
    /* Burn timer increments by two, then expires. */
    h = result(h, 1, UINT32_C(0x04000440), 0, 162, UINT16_C(0x1000), 0,
               NONE16, UINT32_C(0x80000000), 0, 0, 0, 0, NONE8, NONE8);
    /* Water extinguishes the flame and walks immediately. */
    h = result(h, 2, UINT32_C(0x04000440), 0, 12, UINT16_C(0x1000), 0,
               NONE16, UINT32_C(0x80000000), 0, 0, 0, 0, 0, NONE8);
    /* Active ground frame: speed 24, running animation, fire/lava effects. */
    h = result(h, 3, NONE32, 0, 12, UINT16_C(0x0FF6), 0, UINT16_C(0x72),
               UINT32_C(0x000C0000), 1, 1, 1, 1, 1, 1);
    /* Ground departure changes to burning fall before effects. */
    h = result(h, 4, UINT32_C(0x010208B5), 0, 12, UINT16_C(0x0FF6), 0,
               UINT16_C(0x72), UINT32_C(0x000C0000), 1, 1, 1, 1, 1, 0);
    /* Health below 0x100 overrides the fall/ground action with death. */
    h = result(h, 5, UINT32_C(0x00021311), 0, 12, UINT16_C(0x00FB), 0,
               UINT16_C(0x72), UINT32_C(0x000C0000), 1, 1, 1, 1, 1, 1);

    printf("marioBurningGroundFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
