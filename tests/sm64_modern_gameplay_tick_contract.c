#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u8(uint64_t hash, uint8_t value) {
    return (hash ^ value) * FNV_PRIME;
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

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_tick(uint64_t hash, uint64_t simulation_tick,
                          uint8_t focused, uint8_t demo_ended,
                          uint8_t demo_timer, uint16_t button_down,
                          uint16_t button_pressed, uint16_t raw_x,
                          uint16_t raw_y, uint16_t camera_down,
                          uint16_t camera_pressed, uint16_t mario_input,
                          uint32_t magnitude_bits, uint16_t intended_yaw,
                          uint16_t geometry_flags, uint8_t rumble_request,
                          uint64_t next_simulation_tick,
                          uint64_t global_timer, uint8_t next_demo_timer,
                          uint8_t frames_since_a, uint8_t frames_since_b,
                          uint8_t rumble_command, uint8_t rumble_advanced,
                          uint16_t rumble_duration, uint16_t rumble_warmup) {
    hash = hash_u64(hash, simulation_tick);
    hash = hash_u8(hash, focused);
    hash = hash_u8(hash, demo_ended);
    hash = hash_u8(hash, demo_timer);
    hash = hash_u16(hash, button_down);
    hash = hash_u16(hash, button_pressed);
    hash = hash_u16(hash, raw_x);
    hash = hash_u16(hash, raw_y);
    hash = hash_u16(hash, camera_down);
    hash = hash_u16(hash, camera_pressed);
    hash = hash_u16(hash, mario_input);
    hash = hash_u32(hash, magnitude_bits);
    hash = hash_u16(hash, intended_yaw);
    hash = hash_u16(hash, geometry_flags);
    hash = hash_u8(hash, rumble_request);
    hash = hash_u64(hash, next_simulation_tick);
    hash = hash_u64(hash, global_timer);
    hash = hash_u8(hash, next_demo_timer);
    hash = hash_u8(hash, frames_since_a);
    hash = hash_u8(hash, frames_since_b);
    hash = hash_u8(hash, rumble_command);
    hash = hash_u8(hash, rumble_advanced);
    hash = hash_u16(hash, rumble_duration);
    return hash_u16(hash, rumble_warmup);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_tick(fingerprint, 0, 1, 0, 0xff, 0x8000, 0x0000,
                             38, 0, 0x0005, 0x0000, 0x0081,
                             UINT32_C(0x41000000), 0x4200, 0, 0,
                             1, 0, 0xff, 8, 10, 0, 0, 0, 0);
    fingerprint = hash_tick(fingerprint, 1, 1, 0, 0xff, 0x8000, 0x8000,
                             38, 0, 0x0005, 0x0005, 0x0083,
                             UINT32_C(0x41000000), 0x4200, 0, 1,
                             2, 1, 0xff, 0, 11, 2, 1, 0, 0);
    fingerprint = hash_tick(fingerprint, 2, 1, 0, 0xff, 0x0000, 0x0000,
                             0, 0, 0x0000, 0x0000, 0x0020,
                             UINT32_C(0x00000000), 0x1111, 0, 0,
                             3, 1, 0xff, 1, 12, 0, 0, 0, 0);
    fingerprint = hash_tick(fingerprint, 3, 1, 0, 0xff, 0x0000, 0x0000,
                             0, 0, 0x0000, 0x0000, 0x0020,
                             UINT32_C(0x00000000), 0x1111, 0, 0,
                             4, 2, 0xff, 2, 13, 2, 1, 0, 0);
    fingerprint = hash_tick(fingerprint, 4, 1, 0, 0, 0x9000, 0x9000,
                             24, UINT16_C(0xfff4), 0x0000, 0x0000, 0x0083,
                             UINT32_C(0x4033ffff), 0x34e7, 0, 0,
                             5, 3, 0, 0, 14, 1, 1, 80, 3);
    fingerprint = hash_tick(fingerprint, 5, 1, 1, 0, 0x1080, 0x0080,
                             0, 0, 0x0000, 0x0000, 0x0020,
                             UINT32_C(0x00000000), 0x1111, 0, 0,
                             6, 4, 0, 1, 15, 1, 1, 80, 2);
    printf("gameplayTickFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    return 0;
}
