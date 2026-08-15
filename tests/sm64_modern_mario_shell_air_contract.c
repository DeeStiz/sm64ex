#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define NONE32 UINT32_MAX

static uint64_t h8(uint64_t h, uint8_t v) { h ^= v; return h * FNV_PRIME; }
static uint64_t h32(uint64_t h, uint32_t v) {
    for (unsigned i = 0; i < 4; ++i) h = h8(h, (uint8_t)(v >> (i * 8u)));
    return h;
}

static uint64_t result(uint64_t h, uint8_t intent, uint32_t action,
                       uint32_t argument, uint32_t animation, uint8_t airStep,
                       uint32_t yOffset, uint8_t terrainSound, uint8_t lava) {
    h = h8(h, intent);
    h = h32(h, action);
    h = h32(h, argument);
    h = h32(h, animation);
    h = h8(h, airStep);
    h = h32(h, yOffset);
    h = h8(h, terrainSound);
    return h8(h, lava);
}

int main(void) {
    uint64_t h = FNV_OFFSET;

    /* Ordinary air frame: jump-shell animation, terrain sound, +42 gfx lift. */
    h = result(h, 0, NONE32, 0, 0x4A, 0, UINT32_C(0x42280000), 1, 0);
    /* Horizontal wind skips update_air_without_turn but preserves the same effects. */
    h = result(h, 0, NONE32, 0, 0x4A, 0, UINT32_C(0x42280000), 1, 0);
    /* Landing enters shell ground with action argument one. */
    h = result(h, 1, UINT32_C(0x20810446), 1, 0x4A, 1, UINT32_C(0x42280000), 1, 0);
    /* Wall hit zeros forward velocity; the result fingerprint records the branch. */
    h = result(h, 2, NONE32, 0, 0x4A, 2, UINT32_C(0x42280000), 1, 0);
    /* Lava wall delegates to the lava-boost action. */
    h = result(h, 3, UINT32_C(0x010208B7), 0, 0x4A, 3, UINT32_C(0x42280000), 1, 1);

    printf("marioShellAirFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
