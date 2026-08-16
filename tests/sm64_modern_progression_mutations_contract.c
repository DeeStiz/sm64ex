#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define SAVE_BYTES 56
#define MENU_BYTES 32
#define FILE_COUNT 4
#define FILE_EXISTS UINT32_C(1)
#define CAP_ON_GROUND (UINT32_C(1) << 16)

static uint64_t h8(uint64_t h, uint8_t value) { h ^= value; return h * FNV_PRIME; }
static uint64_t hash_bytes(uint64_t h, const uint8_t *bytes, size_t count) {
    for (size_t i = 0; i < count; ++i) h = h8(h, bytes[i]);
    return h;
}
static void put16(uint8_t *b, int o, uint16_t v) { b[o] = (uint8_t)v; b[o + 1] = (uint8_t)(v >> 8); }
static void put32(uint8_t *b, int o, uint32_t v) { for (int i = 0; i < 4; ++i) b[o + i] = (uint8_t)(v >> (i * 8)); }
static uint16_t checksum(const uint8_t *b, int n) { uint16_t x = 0; for (int i = 0; i < n - 2; ++i) x = (uint16_t)(x + b[i]); return x; }

static void encode_save(uint8_t *b, uint32_t flags, uint8_t star0, uint8_t star1, uint8_t score0, uint8_t score1) {
    memset(b, 0, SAVE_BYTES);
    b[0] = 7; b[1] = 2;
    put16(b, 2, (uint16_t)-10); put16(b, 4, 20); put16(b, 6, 30);
    put32(b, 8, flags); b[12] = star0; b[13] = star1;
    b[37] = score0; b[38] = score1;
    put16(b, 52, UINT16_C(0x4441)); put16(b, 54, checksum(b, SAVE_BYTES));
}

static void encode_empty_save(uint8_t *b) {
    memset(b, 0, SAVE_BYTES);
    put16(b, 52, UINT16_C(0x4441)); put16(b, 54, checksum(b, SAVE_BYTES));
}

static void encode_menu(uint8_t *b, const uint32_t ages[FILE_COUNT]) {
    memset(b, 0, MENU_BYTES);
    for (int i = 0; i < FILE_COUNT; ++i) put32(b, i * 4, ages[i]);
    put16(b, 16, UINT16_C(0x1234));
    for (int i = 0; i < 10; ++i) b[18 + i] = (uint8_t)(0xA0 + i);
    put16(b, 28, UINT16_C(0x4849)); put16(b, 30, checksum(b, MENU_BYTES));
}

static void touch_all(uint32_t ages[FILE_COUNT], int file) {
    for (int course = 0; course < 15; ++course) {
        const uint32_t shift = (uint32_t)(course * 2);
        const uint32_t mask = UINT32_C(3) << shift;
        const uint32_t current = (ages[file] >> shift) & 3;
        if (current == 0) continue;
        for (int index = 0; index < FILE_COUNT; ++index) {
            const uint32_t age = (ages[index] >> shift) & 3;
            if (age < current) ages[index] = (ages[index] & ~mask) | ((age + 1) << shift);
        }
        ages[file] &= ~mask;
    }
}

static uint64_t hash_image(uint64_t h, uint8_t primary[FILE_COUNT][SAVE_BYTES], uint8_t backup[FILE_COUNT][SAVE_BYTES], uint8_t menu_primary[MENU_BYTES], uint8_t menu_backup[MENU_BYTES]) {
    for (int i = 0; i < FILE_COUNT; ++i) h = hash_bytes(h, primary[i], SAVE_BYTES);
    for (int i = 0; i < FILE_COUNT; ++i) h = hash_bytes(h, backup[i], SAVE_BYTES);
    h = hash_bytes(h, menu_primary, MENU_BYTES);
    return hash_bytes(h, menu_backup, MENU_BYTES);
}

static void expect(int condition, const char *message) {
    if (!condition) {
        fprintf(stderr, "progression mutations contract failed: %s\n", message);
        __builtin_trap();
    }
}

int main(void) {
    uint8_t primary[FILE_COUNT][SAVE_BYTES];
    uint8_t backup[FILE_COUNT][SAVE_BYTES];
    uint8_t menu_primary[MENU_BYTES];
    uint8_t menu_backup[MENU_BYTES];
    const uint8_t empty[SAVE_BYTES] = {0};
    uint32_t ages[FILE_COUNT] = {
        UINT32_C(0x3FFFFFFF), UINT32_C(0x2AAAAAAA),
        UINT32_C(0x15555555), UINT32_C(0)
    };
    for (int i = 0; i < FILE_COUNT; ++i) {
        encode_empty_save(primary[i]);
        memcpy(backup[i], primary[i], SAVE_BYTES);
    }
    encode_menu(menu_primary, ages); memcpy(menu_backup, menu_primary, MENU_BYTES);
    encode_save(primary[0], FILE_EXISTS | CAP_ON_GROUND, 0x05, 0x81, 100, 42);
    memcpy(backup[0], primary[0], SAVE_BYTES);

    uint64_t fingerprint = hash_image(FNV_OFFSET, primary, backup, menu_primary, menu_backup);
    touch_all(ages, 1);
    memcpy(primary[1], primary[0], SAVE_BYTES); memcpy(backup[1], primary[0], SAVE_BYTES);
    encode_menu(menu_primary, ages); memcpy(menu_backup, menu_primary, MENU_BYTES);
    fingerprint = hash_image(fingerprint, primary, backup, menu_primary, menu_backup);

    touch_all(ages, 2);
    encode_empty_save(primary[2]); memcpy(backup[2], primary[2], SAVE_BYTES);
    encode_menu(menu_primary, ages); memcpy(menu_backup, menu_primary, MENU_BYTES);
    fingerprint = hash_image(fingerprint, primary, backup, menu_primary, menu_backup);

    expect(memcmp(primary[1], primary[0], SAVE_BYTES) == 0, "copy destination");
    expect(memcmp(primary[2], empty, SAVE_BYTES) != 0, "empty save is signed");
    expect(memcmp(primary[2], backup[2], SAVE_BYTES) == 0, "erase backup");
    expect(ages[0] == UINT32_C(0x3FFFFFFF)
        && ages[1] == UINT32_C(0x15555555)
        && ages[2] == 0
        && ages[3] == UINT32_C(0x2AAAAAAA), "age touch order");

    printf("progressionMutationsFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    return 0;
}
