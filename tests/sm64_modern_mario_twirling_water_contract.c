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
                       int16_t twirl_yaw, int16_t angle_velocity_y, int16_t face_yaw,
                       uint8_t twirl_sound, uint8_t ledge_animation,
                       uint8_t default_camera, uint8_t drop_held,
                       uint8_t reflect_bonk, uint8_t lava_boost) {
    h = h8(h, variant);
    h = h8(h, intent);
    h = h32(h, action);
    h = h32(h, argument);
    h = h16(h, animation);
    h = h16(h, (uint16_t)twirl_yaw);
    h = h16(h, (uint16_t)angle_velocity_y);
    h = h16(h, (uint16_t)face_yaw);
    h = h8(h, twirl_sound);
    h = h8(h, ledge_animation);
    h = h8(h, default_camera);
    h = h8(h, drop_held);
    h = h8(h, reflect_bonk);
    return h8(h, lava_boost);
}

int main(void) {
    uint64_t h = FNV_OFFSET;
    h = result(h, 0, 0, NONE32, 0, 0x95, 0x0200, 0x0200, 0, 0, 0, 0, 0, 0, 0);
    h = result(h, 0, 5, NONE32, 1, 0x94, (int16_t)0x8DFF, (int16_t)0x7DFF, 0, 1, 0, 0, 0, 1, 0);
    h = result(h, 0, 1, UINT32_C(0x18800238), 0, 0x95, 0x0200, 0x0200, 0, 0, 0, 0, 0, 0, 0);
    h = result(h, 1, 2, UINT32_C(0x04000470), 0, 0x4D, 0, 0, 0, 0, 0, 1, 0, 0, 0);
    h = result(h, 1, 6, UINT32_C(0x0800034B), 0, 0x33, 0, 0, 0, 0, 1, 1, 0, 0, 0);
    h = result(h, 2, 0, NONE32, 0, 0x41, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    h = result(h, 2, 8, UINT32_C(0x0100088C), 0, 0x41, 0, 0, 0, 0, 0, 0, 1, 0, 0);
    h = result(h, 1, 7, UINT32_C(0x010208B7), 0, 0x4D, 0, 0, 0, 0, 0, 0, 0, 0, 1);

    printf("marioTwirlingWaterFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
