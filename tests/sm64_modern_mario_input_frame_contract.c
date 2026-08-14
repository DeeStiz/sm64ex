#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u8(uint64_t hash, uint8_t value) {
    hash ^= value;
    return hash * FNV_PRIME;
}

static uint64_t hash_u16(uint64_t hash, uint16_t value) {
    for (unsigned byte = 0; byte < 2; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT16_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT32_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_frame(uint64_t hash, uint8_t focused, uint8_t demo_ended,
                           uint8_t demo_timer, uint16_t button_down,
                           uint16_t button_pressed, uint16_t raw_x,
                           uint16_t raw_y, uint16_t mario_input,
                           uint32_t magnitude_bits, uint16_t intended_yaw,
                           uint16_t geometry_flags, uint32_t rumble) {
    hash = hash_u8(hash, focused);
    hash = hash_u8(hash, demo_ended);
    hash = hash_u8(hash, demo_timer);
    hash = hash_u16(hash, button_down);
    hash = hash_u16(hash, button_pressed);
    hash = hash_u16(hash, raw_x);
    hash = hash_u16(hash, raw_y);
    hash = hash_u16(hash, mario_input);
    hash = hash_u32(hash, magnitude_bits);
    hash = hash_u16(hash, intended_yaw);
    hash = hash_u16(hash, geometry_flags);
    return hash_u32(hash, rumble);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_frame(fingerprint, 1, 0, 0xff, 0x8000, 0x8000,
                              38, 0, 0x0083, UINT32_C(0x41000000), 0x4200, 0, 1);
    fingerprint = hash_frame(fingerprint, 0, 0, 0xff, 0, 0,
                              0, 0, 0x0020, 0, 0x1111, 0, 0);
    fingerprint = hash_frame(fingerprint, 1, 0, 2, 0x9000, 0,
                              24, UINT16_C(0xfff4), 0x0081, UINT32_C(0x4033ffff), 0x34e7, 0, 0);
    fingerprint = hash_frame(fingerprint, 1, 0, 1, 0x9000, 0x9000,
                              24, UINT16_C(0xfff4), 0x0083, UINT32_C(0x4033ffff), 0x34e7, 0, 0);
    fingerprint = hash_frame(fingerprint, 1, 1, 0, 0x1080, 0x0080,
                              0, 0, 0x0020, 0, 0x1111, 0, 0);
    printf("marioInputFrameFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    return 0;
}
