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
                       uint32_t action, uint32_t argument, uint16_t animation,
                       int16_t face_yaw, uint16_t burn_timer, uint16_t health,
                       uint8_t hurt_counter, uint8_t action_state, uint8_t sound,
                       uint8_t landing, uint8_t on_fire, uint8_t moving_lava,
                       uint8_t queue_rumble, uint8_t reset_rumble,
                       uint8_t drop_held, uint8_t particle_fire, uint8_t eyes_dead,
                       uint8_t reflect, uint8_t death_warp) {
    h = h8(h, variant); h = h8(h, intent); h = h32(h, action);
    h = h32(h, argument); h = h16(h, animation); h = h16(h, (uint16_t)face_yaw);
    h = h16(h, burn_timer); h = h16(h, health); h = h8(h, hurt_counter);
    h = h8(h, action_state); h = h8(h, sound); h = h8(h, landing);
    h = h8(h, on_fire); h = h8(h, moving_lava); h = h8(h, queue_rumble);
    h = h8(h, reset_rumble); h = h8(h, drop_held); h = h8(h, particle_fire);
    h = h8(h, eyes_dead); h = h8(h, reflect); return h8(h, death_warp);
}

int main(void) {
    uint64_t h = FNV_OFFSET;
    h = result(h, 0, 0, NONE32, 0, 0x4D, 0, 13, 0x876, 0, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0);
    h = result(h, 0, 1, UINT32_C(0x00020449), 0, 0x29, 0, 13, 0xFF, 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0);
    h = result(h, 1, 0, NONE32, 0, 0x56, 0, 13, 0x876, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0);
    h = result(h, 2, 2, NONE32, 0, 0x29, 0, 10, 0x880, 0, 1, 4, 1, 0, 0, 0, 1, 0, 1, 1, 0, 0);
    h = result(h, 2, 3, UINT32_C(0x08000239), 0, 0x29, 0, 10, 0x880, 0, 2, 4, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0);
    h = result(h, 2, 0, NONE32, 0, 0x29, 0, 10, 0x880, 12, 0, 3, 0, 1, 1, 1, 1, 0, 1, 1, 0, 0);
    h = result(h, 2, 4, NONE32, 0, 0x29, (int16_t)0xF000, 10, 0x880, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0);
    h = result(h, 2, 5, UINT32_C(0x010208B7), 1, 0x29, (int16_t)0xC000, 10, 0x880, 18, 0, 3, 0, 1, 0, 0, 1, 1, 0, 1, 0, 0);
    h = result(h, 2, 6, NONE32, 0, 0x29, 0, 10, 0xFF, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1);

    printf("marioBurningLavaFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
