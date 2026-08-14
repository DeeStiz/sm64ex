#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u8(uint64_t h, uint8_t v) { return (h ^ v) * FNV_PRIME; }
static uint64_t hash_u16(uint64_t h, uint16_t v) {
    for (unsigned i = 0; i < 2; ++i) { h ^= (v >> (i * 8u)) & 0xffu; h *= FNV_PRIME; }
    return h;
}
static uint64_t hash_u32(uint64_t h, uint32_t v) {
    for (unsigned i = 0; i < 4; ++i) { h ^= (v >> (i * 8u)) & 0xffu; h *= FNV_PRIME; }
    return h;
}
static uint64_t hash_u64(uint64_t h, uint64_t v) {
    for (unsigned i = 0; i < 8; ++i) { h ^= (v >> (i * 8u)) & 0xffu; h *= FNV_PRIME; }
    return h;
}

static uint64_t hash_state(uint64_t h, uint32_t flags, uint32_t action,
                           uint32_t magnitude_bits, uint16_t yaw,
                           uint8_t frames_a, uint8_t frames_b,
                           int16_t face_yaw, int32_t x_bits, int32_t y_bits,
                           int32_t z_bits, uint32_t ceiling_bits,
                           uint32_t floor_bits, uint32_t water_bits,
                           uint32_t floor_id, uint32_t mario_id,
                           int16_t stars, int16_t health, int16_t previous_stars) {
    h = hash_u16(h, 0); h = hash_u16(h, 0); h = hash_u32(h, flags);
    h = hash_u32(h, 0); h = hash_u32(h, action); h = hash_u32(h, 0);
    h = hash_u32(h, 0); h = hash_u16(h, 0); h = hash_u16(h, 0);
    h = hash_u32(h, 0); h = hash_u32(h, magnitude_bits); h = hash_u16(h, yaw);
    h = hash_u16(h, 0); h = hash_u8(h, frames_a); h = hash_u8(h, frames_b);
    h = hash_u8(h, 0); h = hash_u8(h, 0);
    h = hash_u32(h, 0); h = hash_u32(h, (uint32_t) face_yaw); h = hash_u32(h, 0);
    h = hash_u32(h, 0); h = hash_u32(h, 0); h = hash_u32(h, 0);
    h = hash_u16(h, 0); h = hash_u16(h, 0);
    h = hash_u32(h, (uint32_t) x_bits); h = hash_u32(h, (uint32_t) y_bits); h = hash_u32(h, (uint32_t) z_bits);
    h = hash_u32(h, 0); h = hash_u32(h, 0); h = hash_u32(h, 0);
    h = hash_u32(h, 0); h = hash_u32(h, 0); h = hash_u32(h, 0);
    h = hash_u32(h, ceiling_bits); h = hash_u32(h, floor_bits); h = hash_u32(h, water_bits);
    h = hash_u32(h, 0); h = hash_u32(h, 0); h = hash_u32(h, 0);
    h = hash_u32(h, floor_id); h = hash_u32(h, mario_id); h = hash_u32(h, 0);
    h = hash_u16(h, 0); h = hash_u16(h, (uint16_t) stars); h = hash_u8(h, 0); h = hash_u8(h, 4);
    h = hash_u16(h, (uint16_t) health); h = hash_u16(h, UINT16_C(0x00bd));
    h = hash_u8(h, 0); h = hash_u8(h, 0); h = hash_u8(h, 0); h = hash_u8(h, 0);
    h = hash_u16(h, 0); return hash_u16(h, (uint16_t) previous_stars);
}

int main(void) {
    uint64_t h = FNV_OFFSET;
    h = hash_state(h, 0, UINT32_C(0x380022c0), 0, UINT16_C(0x0000), 255, 255,
                   0x1234, UINT32_C(0x41200000), UINT32_C(0x80000000), UINT32_C(0x41a00000),
                   UINT32_C(0xc62be000), UINT32_C(0x80000000), UINT32_C(0x42c80000),
                   7, 1, 42, 0x880, 42);
    h = hash_state(h, UINT32_C(0x11), UINT32_C(0x0c400201), 0, UINT16_C(0x0000), 255, 255,
                   (int16_t)-0x2222, UINT32_C(0xc1200000), UINT32_C(0x42a00000), UINT32_C(0x41f00000),
                   UINT32_C(0xc62be000), UINT32_C(0x80000000), UINT32_C(0xc62be000),
                   7, 0, 7, 0x880, 7);
    printf("marioStateFingerprint=0x%016llx\n", (unsigned long long) h);
    return 0;
}
