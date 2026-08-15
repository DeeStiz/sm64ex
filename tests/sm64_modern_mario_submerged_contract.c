#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define NONE32 UINT32_MAX

static uint64_t h8(uint64_t h, uint8_t v) { h ^= v; return h * FNV_PRIME; }
static uint64_t h16(uint64_t h, uint16_t v) {
    for (unsigned i = 0; i < 2; ++i) h = h8(h, (uint8_t)(v >> (i * 8u)));
    return h;
}
static uint64_t h32(uint64_t h, uint32_t v) {
    for (unsigned i = 0; i < 4; ++i) h = h8(h, (uint8_t)(v >> (i * 8u)));
    return h;
}
static uint64_t result(uint64_t h, uint8_t variant, uint8_t intent,
                       uint32_t action, uint32_t argument, uint16_t timer,
                       uint8_t state, uint16_t animation, int32_t accel,
                       uint8_t eyes, uint8_t drop, uint8_t metal_shock,
                       uint8_t invincibility, uint8_t water_step,
                       uint8_t drowning_sound, uint8_t shock_sound,
                       uint8_t camera_shake, uint8_t death_warp) {
    h = h8(h, variant); h = h8(h, intent); h = h32(h, action);
    h = h32(h, argument); h = h16(h, timer); h = h8(h, state);
    h = h16(h, animation); h = h32(h, (uint32_t)accel); h = h8(h, eyes);
    h = h8(h, drop); h = h8(h, metal_shock); h = h8(h, invincibility);
    h = h8(h, water_step); h = h8(h, drowning_sound); h = h8(h, shock_sound);
    h = h8(h, camera_shake); return h8(h, death_warp);
}

int main(void) {
    uint64_t h = FNV_OFFSET;
    h = result(h, 0, 0, NONE32, 0, 0, 0, 0xB2, 0x30000, 0, 0, 0, 0, 1, 0, 0, 0, 0);
    h = result(h, 0, 2, UINT32_C(0x300024E1), 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0);
    h = result(h, 1, 6, UINT32_C(0x380022C0), 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0);
    h = result(h, 0, 1, UINT32_C(0x000042F4), 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0);
    h = result(h, 2, 6, UINT32_C(0x380022C0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0);
    h = result(h, 3, 0, NONE32, 1, 0, 0, 0xA3, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0);
    h = result(h, 4, 0, NONE32, 0, 0, 1, 0xA6, 0, 2, 0, 0, 0, 1, 1, 0, 0, 0);
    h = result(h, 4, 9, NONE32, 0, 0, 1, 0xA6, 0, 2, 0, 0, 0, 1, 1, 0, 0, 1);
    h = result(h, 5, 9, NONE32, 0, 0, 0, 0xA7, 0, 2, 0, 0, 0, 1, 0, 0, 0, 1);
    h = result(h, 6, 6, UINT32_C(0x380022C0), 0, 6, 0, 0x7A, 0, 0, 0, 1, 1, 1, 0, 1, 1, 0);
    h = result(h, 6, 8, UINT32_C(0x300032C7), 0, 6, 0, 0x7A, 0, 0, 0, 1, 1, 1, 0, 1, 1, 0);

    printf("marioSubmergedFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
