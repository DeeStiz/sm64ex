#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define NONE32 UINT32_MAX
static uint64_t h8(uint64_t h, uint8_t v) { h ^= v; return h * FNV_PRIME; }
static uint64_t h16(uint64_t h, uint16_t v) { for (unsigned i = 0; i < 2; ++i) h = h8(h, (uint8_t)(v >> (i * 8u))); return h; }
static uint64_t h32(uint64_t h, uint32_t v) { for (unsigned i = 0; i < 4; ++i) h = h8(h, (uint8_t)(v >> (i * 8u))); return h; }
static uint64_t result_grabbed(uint64_t h, uint8_t intent, uint32_t action, uint32_t arg,
                               uint16_t anim, uint16_t yaw,
                               uint32_t px, uint32_t py, uint32_t pz,
                               uint8_t queue, uint16_t distance, uint8_t sync) {
    h = h8(h, intent); h = h32(h, action); h = h32(h, arg); h = h16(h, anim);
    h = h16(h, yaw); h = h32(h, px); h = h32(h, py); h = h32(h, pz);
    h = h8(h, queue); h = h16(h, distance); return h8(h, sync);
}
static uint64_t result_tornado(uint64_t h, uint8_t intent, uint32_t action, uint32_t arg,
                               uint16_t timer, uint16_t anim,
                               uint32_t proposed_x, uint32_t proposed_y, uint32_t proposed_z,
                               uint32_t px, uint32_t py, uint32_t pz,
                               uint32_t vx, uint32_t vy, uint32_t vz,
                               uint32_t floor, uint32_t tornado_y, uint16_t tornado_yaw,
                               uint16_t angle_yaw, uint16_t twirl_yaw, uint16_t graphics_yaw,
                               uint8_t update_floor, uint8_t sound, uint8_t reset, uint8_t sync) {
    h = h8(h, intent); h = h32(h, action); h = h32(h, arg); h = h16(h, timer); h = h16(h, anim);
    h = h32(h, proposed_x); h = h32(h, proposed_y); h = h32(h, proposed_z);
    h = h32(h, px); h = h32(h, py); h = h32(h, pz); h = h32(h, vx); h = h32(h, vy); h = h32(h, vz);
    h = h32(h, floor); h = h32(h, tornado_y); h = h16(h, tornado_yaw); h = h16(h, angle_yaw);
    h = h16(h, twirl_yaw); h = h16(h, graphics_yaw); h = h8(h, update_floor);
    h = h8(h, sound); h = h8(h, reset); return h8(h, sync);
}

int main(void) {
    uint64_t h = FNV_OFFSET;
    h = result_grabbed(h, 0, NONE32, 0, 0x58, 0x0800,
                       0x3f800000, 0x40000000, 0x40400000, 0, 0, 0);
    h = result_grabbed(h, 1, UINT32_C(0x010208bd), 1, 0, 0x2200,
                       0x3f800000, 0x40000000, 0x40400000, 1, 60, 1);
    h = result_grabbed(h, 2, UINT32_C(0x010208be), 0, 0, 0xee00,
                       0x3f800000, 0x40000000, 0x40400000, 1, 60, 1);
    h = result_tornado(h, 0, NONE32, 1, 6, 0x95,
                       0x421327ce, 0x41980000, 0xc1ccb00e,
                       0x42200000, 0x42dc0000, 0xc1c80000,
                       0x3f800000, 0xbf800000, 0x40400000,
                       0x42dc0000, 0x41980000, 0x0200, 0x0300, 0x8200, 0x9200,
                       0, 1, 1, 1);
    h = result_tornado(h, 0, NONE32, 1, 10, 0x94,
                       0x418df92c, 0x41300000, 0x41c13f9b,
                       0x40400000, 0x41400000, 0x41100000,
                       0, 0x40000000, 0,
                       0x40e00000, 0x40e00000, 0x1000, 0x3000, 0xa000, 0x9000,
                       1, 1, 1, 1);
    h = result_tornado(h, 1, UINT32_C(0x108008a4), 1, 5, 0,
                       0x42200000, 0x42f00000, 0xc1c80000,
                       0x42200000, 0x42f00000, 0xc1c80000,
                       0x00000000, 0x41a00000, 0x00000000,
                       0x42dc0000, 0x43990000, 0x0100, 0x0200, 0x7f00, 0x8f00,
                       0, 0, 0, 0);
    printf("marioGrabbedTornadoFingerprint=0x%016llx\n", (unsigned long long)h);
    return 0;
}
