#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define SAVE_BYTES 56
#define MENU_BYTES 32
#define FILE_COUNT 4
#define IMAGE_BYTES (SAVE_BYTES * FILE_COUNT * 2 + MENU_BYTES * 2)
#define SAVE_MAGIC UINT16_C(0x4441)
#define MENU_MAGIC UINT16_C(0x4849)
#define FILE_EXISTS (1u << 0)
#define WING_CAP (1u << 1)
#define METAL_CAP (1u << 2)

static uint64_t h8(uint64_t h, uint8_t value) {
    h ^= value;
    return h * FNV_PRIME;
}

static uint64_t h16(uint64_t h, uint16_t value) {
    for (unsigned i = 0; i < 2; ++i)
        h = h8(h, (uint8_t) (value >> (i * 8u)));
    return h;
}

static uint64_t h32(uint64_t h, uint32_t value) {
    for (unsigned i = 0; i < 4; ++i)
        h = h8(h, (uint8_t) (value >> (i * 8u)));
    return h;
}

static void put16(uint8_t *bytes, int offset, uint16_t value) {
    bytes[offset] = (uint8_t) value;
    bytes[offset + 1] = (uint8_t) (value >> 8);
}

static void put32(uint8_t *bytes, int offset, uint32_t value) {
    for (int i = 0; i < 4; ++i)
        bytes[offset + i] = (uint8_t) (value >> (i * 8));
}

static uint16_t get16(const uint8_t *bytes, int offset) {
    return (uint16_t) bytes[offset] | (uint16_t) bytes[offset + 1] << 8;
}

static uint16_t checksum(const uint8_t *bytes, int count) {
    uint16_t sum = 0;
    for (int i = 0; i < count - 2; ++i)
        sum = (uint16_t) (sum + bytes[i]);
    return sum;
}

static void encode_save(
    uint8_t *bytes, uint8_t cap_level, uint8_t cap_area,
    uint32_t flags, int star_index, uint8_t star_flags,
    int score_index, uint8_t score
) {
    memset(bytes, 0, SAVE_BYTES);
    bytes[0] = cap_level;
    bytes[1] = cap_area;
    put16(bytes, 2, (uint16_t) -10);
    put16(bytes, 4, 20);
    put16(bytes, 6, 30);
    put32(bytes, 8, flags);
    bytes[12 + star_index] = star_flags;
    bytes[37 + score_index] = score;
    put16(bytes, 52, SAVE_MAGIC);
    put16(bytes, 54, checksum(bytes, SAVE_BYTES));
}

static void encode_menu(
    uint8_t *bytes, const uint32_t *ages, uint16_t sound_mode,
    uint8_t filler_start
) {
    memset(bytes, 0, MENU_BYTES);
    for (int i = 0; i < 4; ++i)
        put32(bytes, i * 4, ages[i]);
    put16(bytes, 16, sound_mode);
    for (int i = 0; i < 10; ++i)
        bytes[18 + i] = (uint8_t) (filler_start + i);
    put16(bytes, 28, MENU_MAGIC);
    put16(bytes, 30, checksum(bytes, MENU_BYTES));
}

static int valid_save(const uint8_t *bytes) {
    return get16(bytes, 52) == SAVE_MAGIC
        && get16(bytes, 54) == checksum(bytes, SAVE_BYTES);
}

static int valid_menu(const uint8_t *bytes) {
    return get16(bytes, 28) == MENU_MAGIC
        && get16(bytes, 30) == checksum(bytes, MENU_BYTES);
}

static uint64_t hash_bytes(uint64_t h, const uint8_t *bytes) {
    for (int i = 0; i < IMAGE_BYTES; ++i)
        h = h8(h, bytes[i]);
    return h;
}

static uint64_t hash_result(
    uint64_t h, const uint8_t *save, const uint8_t *menu,
    uint8_t save_decision, uint8_t menu_decision
) {
    h = h8(h, save_decision);
    h = h8(h, menu_decision);
    h = h32(h, (uint32_t) save[8] | (uint32_t) save[9] << 8
        | (uint32_t) save[10] << 16 | (uint32_t) save[11] << 24);
    for (int i = 0; i < 25; ++i)
        h = h8(h, save[12 + i]);
    for (int i = 0; i < 15; ++i)
        h = h8(h, save[37 + i]);
    for (int i = 0; i < 4; ++i) {
        h = h32(h, (uint32_t) menu[i * 4]
            | (uint32_t) menu[i * 4 + 1] << 8
            | (uint32_t) menu[i * 4 + 2] << 16
            | (uint32_t) menu[i * 4 + 3] << 24);
    }
    return h16(h, get16(menu, 16));
}

static void expect(int condition, const char *message) {
    if (!condition) {
        fprintf(stderr, "progression EEPROM contract failed: %s\n", message);
        __builtin_trap();
    }
}

int main(void) {
    uint8_t image[IMAGE_BYTES];
    uint8_t save0[SAVE_BYTES];
    uint8_t save2[SAVE_BYTES];
    uint8_t menu0[MENU_BYTES];
    uint8_t menu2[MENU_BYTES];
    const uint32_t wiped[4] = {
        UINT32_C(0x3FFFFFFF), UINT32_C(0x2AAAAAAA),
        UINT32_C(0x15555555), UINT32_C(0)
    };
    const uint32_t reordered[4] = {
        UINT32_C(0), UINT32_C(0x15555555),
        UINT32_C(0x2AAAAAAA), UINT32_C(0x3FFFFFFF)
    };

    memset(image, 0, sizeof(image));
    for (int i = 0; i < FILE_COUNT; ++i) {
        encode_save(image + i * SAVE_BYTES, 0, 0, 0, 0, 0, 0, 0);
        encode_save(image + FILE_COUNT * SAVE_BYTES + i * SAVE_BYTES,
                    0, 0, 0, 0, 0, 0, 0);
        for (int copy = 0; copy < 2; ++copy) {
            uint8_t *slot = image + copy * FILE_COUNT * SAVE_BYTES
                + i * SAVE_BYTES;
            put16(slot, 2, 0);
            put16(slot, 4, 0);
            put16(slot, 6, 0);
            put16(slot, 54, checksum(slot, SAVE_BYTES));
        }
    }
    encode_menu(image + SAVE_BYTES * FILE_COUNT * 2, wiped, 0, 0);
    encode_menu(image + SAVE_BYTES * FILE_COUNT * 2 + MENU_BYTES,
                wiped, 0, 0);
    encode_save(save0, 7, 2, FILE_EXISTS | WING_CAP, 2, 4, 2, 100);
    encode_save(save2, 9, 3, FILE_EXISTS | METAL_CAP, 5, 2, 5, 88);
    encode_menu(menu0, wiped, UINT16_C(0x1234), 0xA0);
    encode_menu(menu2, reordered, UINT16_C(0x4321), 0xB0);
    memcpy(image, save0, SAVE_BYTES);
    memcpy(image + FILE_COUNT * SAVE_BYTES, save0, SAVE_BYTES);
    memcpy(image + SAVE_BYTES * FILE_COUNT * 2, menu0, MENU_BYTES);
    memcpy(image + SAVE_BYTES * FILE_COUNT * 2 + MENU_BYTES,
           menu0, MENU_BYTES);
    memcpy(image + SAVE_BYTES * 2, save2, SAVE_BYTES);
    memcpy(image + FILE_COUNT * SAVE_BYTES + SAVE_BYTES * 2,
           save2, SAVE_BYTES);
    memcpy(image + SAVE_BYTES * FILE_COUNT * 2, menu2, MENU_BYTES);
    memcpy(image + SAVE_BYTES * FILE_COUNT * 2 + MENU_BYTES,
           menu2, MENU_BYTES);

    expect(valid_save(image), "slot zero primary");
    expect(valid_save(image + SAVE_BYTES * 2), "slot two primary");
    expect(valid_menu(image + SAVE_BYTES * FILE_COUNT * 2), "menu primary");
    uint64_t fingerprint = hash_bytes(FNV_OFFSET, image);
    fingerprint = hash_result(
        fingerprint, save0, menu2, 0, 0);
    fingerprint = hash_result(
        fingerprint, save2, menu2, 0, 0);

    image[SAVE_BYTES * 2] ^= 1;
    expect(!valid_save(image + SAVE_BYTES * 2), "slot two corruption");
    fingerprint = hash_bytes(fingerprint, image);
    fingerprint = hash_result(
        fingerprint, save2, menu2, 2, 0);

    image[SAVE_BYTES * FILE_COUNT * 2] ^= 1;
    expect(!valid_menu(image + SAVE_BYTES * FILE_COUNT * 2), "menu corruption");
    fingerprint = hash_bytes(fingerprint, image);
    fingerprint = hash_result(
        fingerprint, save0, menu2, 0, 2);
    fingerprint = hash_result(
        fingerprint, save2, menu2, 0, 0);

    printf("progressionEEPROMFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    return 0;
}
