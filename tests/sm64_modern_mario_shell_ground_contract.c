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
                       uint32_t argument, uint16_t face, uint16_t animation,
                       uint8_t verticalStar, uint8_t stopRiding,
                       uint8_t tilt, uint8_t resetRumble, uint8_t sound,
                       uint32_t addend, uint8_t ground) {
    h = h8(h, intent);
    h = h32(h, action);
    h = h32(h, argument);
    h = h16(h, face);
    h = h16(h, animation);
    h = h8(h, verticalStar);
    h = h8(h, stopRiding);
    h = h8(h, tilt);
    h = h8(h, resetRumble);
    h = h8(h, sound);
    h = h32(h, addend);
    return h8(h, ground);
}

int main(void) {
    uint64_t h = FNV_OFFSET;

    /* A: ACT_RIDING_SHELL_JUMP. */
    h = result(h, 1, UINT32_C(0x0281089A), 0, 0, NONE16,
               0, 0, 0, 0, NONE8, 0, NONE8);
    /* Z: stop riding and enter ACT_CROUCH_SLIDE. */
    h = result(h, 2, UINT32_C(0x04808459), 0, 0, NONE16,
               0, 1, 0, 0, NONE8, 0, NONE8);
    /* Initial shell animation on ordinary ground. */
    h = result(h, 0, NONE32, 0, 0, UINT16_C(0x006D),
               0, 0, 1, 1, 0, 3, 1);
    /* Continuing shell animation on lava. */
    h = result(h, 0, NONE32, 0, 0, UINT16_C(0x0047),
               0, 0, 1, 1, 1, 3, 1);
    /* A shell leaving the floor. */
    h = result(h, 3, UINT32_C(0x0081089B), 0, 0, UINT16_C(0x0047),
               0, 0, 1, 1, 0, 3, 0);
    /* A shell wall bonk. */
    h = result(h, 4, UINT32_C(0x00020462), 0, 0, UINT16_C(0x0047),
               1, 1, 1, 1, 2, 0, 2);
    /* Slow floor still respects the minimum shell target speed. */
    h = result(h, 0, NONE32, 0, 0, UINT16_C(0x0047),
               0, 0, 1, 1, 0, 3, 1);

    printf("marioShellGroundFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
