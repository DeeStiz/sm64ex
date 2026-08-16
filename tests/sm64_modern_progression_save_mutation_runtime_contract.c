#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define SAVE_BYTES 56
#define MENU_BYTES 32
#define FILE_EXISTS UINT32_C(1)
#define CAP_ON_GROUND (UINT32_C(1) << 16)
#define CAP_ON_KLEPTO (UINT32_C(1) << 17)

static uint64_t h8(uint64_t h, uint8_t value) {
    h ^= value;
    return h * FNV_PRIME;
}

static uint64_t hash_bytes(uint64_t h, const uint8_t *bytes, int count) {
    for (int i = 0; i < count; ++i) h = h8(h, bytes[i]);
    return h;
}

static void put16(uint8_t *bytes, int offset, uint16_t value) {
    bytes[offset] = (uint8_t)value;
    bytes[offset + 1] = (uint8_t)(value >> 8);
}

static void put32(uint8_t *bytes, int offset, uint32_t value) {
    for (int i = 0; i < 4; ++i) bytes[offset + i] = (uint8_t)(value >> (i * 8));
}

static uint16_t checksum(const uint8_t *bytes, int count) {
    uint16_t sum = 0;
    for (int i = 0; i < count - 2; ++i) sum = (uint16_t)(sum + bytes[i]);
    return sum;
}

static void encode_save(
    uint8_t *bytes, uint32_t flags, const uint8_t *stars,
    uint8_t cap_level, uint8_t cap_area, int16_t x, int16_t y, int16_t z
) {
    memset(bytes, 0, SAVE_BYTES);
    bytes[0] = cap_level;
    bytes[1] = cap_area;
    put16(bytes, 2, (uint16_t)x);
    put16(bytes, 4, (uint16_t)y);
    put16(bytes, 6, (uint16_t)z);
    put32(bytes, 8, flags);
    memcpy(bytes + 12, stars, 25);
    put16(bytes, 52, UINT16_C(0x4441));
    put16(bytes, 54, checksum(bytes, SAVE_BYTES));
}

static void encode_menu(
    uint8_t *bytes, const uint32_t *ages, uint16_t sound
) {
    memset(bytes, 0, MENU_BYTES);
    for (int i = 0; i < 4; ++i) put32(bytes, i * 4, ages[i]);
    put16(bytes, 16, sound);
    put16(bytes, 28, UINT16_C(0x4849));
    put16(bytes, 30, checksum(bytes, MENU_BYTES));
}

static uint64_t hash_state(
    uint64_t fingerprint, uint32_t flags, const uint8_t *stars,
    uint8_t cap_level, uint8_t cap_area, int16_t x, int16_t y, int16_t z,
    const uint32_t *ages, uint16_t sound, uint8_t save_modified,
    uint8_t menu_modified, uint8_t cap_location
) {
    uint8_t save[SAVE_BYTES], menu[MENU_BYTES];
    encode_save(save, flags, stars, cap_level, cap_area, x, y, z);
    encode_menu(menu, ages, sound);
    fingerprint = hash_bytes(fingerprint, save, SAVE_BYTES);
    fingerprint = hash_bytes(fingerprint, menu, MENU_BYTES);
    fingerprint = h8(fingerprint, save_modified);
    fingerprint = h8(fingerprint, menu_modified);
    return h8(fingerprint, cap_location);
}

int main(void) {
    uint8_t stars[25] = {0};
    stars[0] = 0x04;
    uint32_t ages[4] = {
        UINT32_C(0x01234567), UINT32_C(0x89ABCDEF),
        UINT32_C(0x10203040), UINT32_C(0x55667788)
    };
    uint32_t flags = FILE_EXISTS | CAP_ON_GROUND | CAP_ON_KLEPTO;
    uint8_t cap_level = 8, cap_area = 2;
    int16_t x = -10, y = 20, z = 30;
    uint16_t sound = UINT16_C(0x1234);
    uint8_t save_modified = 0, menu_modified = 0, cap_location = 1;

    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_state(
        fingerprint, flags, stars, cap_level, cap_area, x, y, z,
        ages, sound, save_modified, menu_modified, cap_location
    );

    // Paused legacy-domain work is a strict no-op, including dirty bits.
    fingerprint = hash_state(
        fingerprint, flags, stars, cap_level, cap_area, x, y, z,
        ages, sound, save_modified, menu_modified, cap_location
    );

    flags |= UINT32_C(1) << 10 | FILE_EXISTS;
    save_modified = 1;
    fingerprint = hash_state(
        fingerprint, flags, stars, cap_level, cap_area, x, y, z,
        ages, sound, save_modified, menu_modified, cap_location
    );

    flags = (flags & ~(CAP_ON_GROUND | FILE_EXISTS)) | FILE_EXISTS;
    cap_location = 2;
    fingerprint = hash_state(
        fingerprint, flags, stars, cap_level, cap_area, x, y, z,
        ages, sound, save_modified, menu_modified, cap_location
    );

    flags |= UINT32_C(3) << 24 | FILE_EXISTS;
    stars[0] |= 0x82;
    fingerprint = hash_state(
        fingerprint, flags, stars, cap_level, cap_area, x, y, z,
        ages, sound, save_modified, menu_modified, cap_location
    );

    stars[1] |= 0x80;
    fingerprint = hash_state(
        fingerprint, flags, stars, cap_level, cap_area, x, y, z,
        ages, sound, save_modified, menu_modified, cap_location
    );

    cap_level = 9; cap_area = 3; x = -100; y = 200; z = 300;
    flags |= CAP_ON_GROUND | FILE_EXISTS;
    cap_location = 1;
    fingerprint = hash_state(
        fingerprint, flags, stars, cap_level, cap_area, x, y, z,
        ages, sound, save_modified, menu_modified, cap_location
    );

    flags |= CAP_ON_KLEPTO | FILE_EXISTS;
    flags &= ~CAP_ON_GROUND;
    cap_location = 2;
    fingerprint = hash_state(
        fingerprint, flags, stars, cap_level, cap_area, x, y, z,
        ages, sound, save_modified, menu_modified, cap_location
    );

    // A second move sees no ground cap and is a no-op.
    fingerprint = hash_state(
        fingerprint, flags, stars, cap_level, cap_area, x, y, z,
        ages, sound, save_modified, menu_modified, cap_location
    );

    sound = UINT16_C(0x4321);
    menu_modified = 1;
    fingerprint = hash_state(
        fingerprint, flags, stars, cap_level, cap_area, x, y, z,
        ages, sound, save_modified, menu_modified, cap_location
    );

    // The atomic commit clears both dirty bits without changing bytes.
    save_modified = 0;
    menu_modified = 0;
    fingerprint = hash_state(
        fingerprint, flags, stars, cap_level, cap_area, x, y, z,
        ages, sound, save_modified, menu_modified, cap_location
    );

    printf(
        "progressionSaveMutationRuntimeFingerprint=0x%016llx\n",
        (unsigned long long)fingerprint
    );
    return 0;
}
