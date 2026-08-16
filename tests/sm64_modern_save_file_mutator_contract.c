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
#define CAP_ON_UKIKI (UINT32_C(1) << 18)
#define CAP_ON_MR_BLIZZARD (UINT32_C(1) << 19)

static uint64_t h8(uint64_t h, uint8_t v) { h ^= v; return h * FNV_PRIME; }
static uint64_t h32(uint64_t h, uint32_t v) { for (int i = 0; i < 4; ++i) h = h8(h, (uint8_t)(v >> (i * 8))); return h; }
static uint64_t hash_bytes(uint64_t h, const uint8_t *b, int n) { for (int i = 0; i < n; ++i) h = h8(h, b[i]); return h; }
static void put16(uint8_t *b, int o, uint16_t v) { b[o] = (uint8_t)v; b[o + 1] = (uint8_t)(v >> 8); }
static void put32(uint8_t *b, int o, uint32_t v) { for (int i = 0; i < 4; ++i) b[o + i] = (uint8_t)(v >> (i * 8)); }
static uint32_t get32(const uint8_t *b, int o) { return (uint32_t)b[o] | (uint32_t)b[o + 1] << 8 | (uint32_t)b[o + 2] << 16 | (uint32_t)b[o + 3] << 24; }
static uint16_t checksum(const uint8_t *b, int n) { uint16_t x = 0; for (int i = 0; i < n - 2; ++i) x = (uint16_t)(x + b[i]); return x; }
static void encode_save(uint8_t *b, uint32_t flags, uint8_t star0, uint8_t star1, uint8_t cap_level, uint8_t cap_area, int16_t x, int16_t y, int16_t z) {
    memset(b, 0, SAVE_BYTES); b[0] = cap_level; b[1] = cap_area;
    put16(b, 2, (uint16_t)x); put16(b, 4, (uint16_t)y); put16(b, 6, (uint16_t)z);
    put32(b, 8, flags); b[12] = star0; b[13] = star1;
    put16(b, 52, UINT16_C(0x4441)); put16(b, 54, checksum(b, SAVE_BYTES));
}
static void encode_menu(uint8_t *b, uint16_t sound) {
    const uint32_t ages[4] = { UINT32_C(0x3FFFFFFF), UINT32_C(0x2AAAAAAA), UINT32_C(0x15555555), 0 };
    memset(b, 0, MENU_BYTES); for (int i = 0; i < 4; ++i) put32(b, i * 4, ages[i]);
    put16(b, 16, sound); for (int i = 0; i < 10; ++i) b[18 + i] = (uint8_t)(0xA0 + i);
    put16(b, 28, UINT16_C(0x4849)); put16(b, 30, checksum(b, MENU_BYTES));
}
static void expect(int condition, const char *message) { if (!condition) { fprintf(stderr, "save-file mutator contract failed: %s\n", message); __builtin_trap(); } }

int main(void) {
    uint8_t base[SAVE_BYTES], set[SAVE_BYTES], cleared[SAVE_BYTES], secret[SAVE_BYTES], course[SAVE_BYTES], cannon[SAVE_BYTES], cap[SAVE_BYTES], klepto[SAVE_BYTES], mr_blizzard[SAVE_BYTES], ukiki[SAVE_BYTES], unknown[SAVE_BYTES];
    encode_save(base, FILE_EXISTS | CAP_ON_GROUND | CAP_ON_KLEPTO, 0x04, 0, 7, 2, -10, 20, 30);
    memcpy(set, base, SAVE_BYTES); put32(set, 8, get32(set, 8) | (UINT32_C(1) << 10)); put16(set, 54, checksum(set, SAVE_BYTES));
    memcpy(cleared, set, SAVE_BYTES); put32(cleared, 8, (get32(cleared, 8) & ~(FILE_EXISTS | CAP_ON_GROUND)) | FILE_EXISTS); put16(cleared, 54, checksum(cleared, SAVE_BYTES));
    memcpy(secret, base, SAVE_BYTES); put32(secret, 8, get32(secret, 8) | UINT32_C(3) << 24); put16(secret, 54, checksum(secret, SAVE_BYTES));
    memcpy(course, base, SAVE_BYTES); course[12] |= 0x82; put16(course, 54, checksum(course, SAVE_BYTES));
    memcpy(cannon, base, SAVE_BYTES); cannon[13] |= 0x80; put16(cannon, 54, checksum(cannon, SAVE_BYTES));
    encode_save(cap, get32(base, 8), 0x04, 0, 9, 3, -100, 200, 300);
    memcpy(klepto, base, SAVE_BYTES); put32(klepto, 8, (get32(klepto, 8) | CAP_ON_KLEPTO) & ~CAP_ON_GROUND); put16(klepto, 54, checksum(klepto, SAVE_BYTES));
    memcpy(mr_blizzard, base, SAVE_BYTES); put32(mr_blizzard, 8, (get32(mr_blizzard, 8) | CAP_ON_MR_BLIZZARD) & ~CAP_ON_GROUND); put16(mr_blizzard, 54, checksum(mr_blizzard, SAVE_BYTES));
    memcpy(ukiki, base, SAVE_BYTES); put32(ukiki, 8, (get32(ukiki, 8) | CAP_ON_UKIKI) & ~CAP_ON_GROUND); put16(ukiki, 54, checksum(ukiki, SAVE_BYTES));
    memcpy(unknown, base, SAVE_BYTES); put32(unknown, 8, get32(unknown, 8) & ~CAP_ON_GROUND); put16(unknown, 54, checksum(unknown, SAVE_BYTES));
    uint8_t menu[MENU_BYTES], sound[MENU_BYTES]; encode_menu(menu, UINT16_C(0x1234)); encode_menu(sound, UINT16_C(0x4321));

    expect((get32(set, 8) & (UINT32_C(1) << 10)) != 0, "set flags");
    expect((get32(cleared, 8) & FILE_EXISTS) != 0 && (get32(cleared, 8) & CAP_ON_GROUND) == 0, "clear flags");
    expect((get32(secret, 8) >> 24) == 3, "secret stars");
    expect(course[12] == 0x86, "course stars");
    expect((cannon[13] & 0x80) != 0, "cannon");

    uint64_t fingerprint = FNV_OFFSET;
    const uint8_t *saves[] = { base, set, cleared, secret, course, cannon, cap, klepto, mr_blizzard, ukiki, unknown };
    for (unsigned i = 0; i < sizeof(saves) / sizeof(saves[0]); ++i) {
        fingerprint = hash_bytes(fingerprint, saves[i], SAVE_BYTES);
    }
    fingerprint = h8(fingerprint, 2); fingerprint = h8(fingerprint, 4); fingerprint = h8(fingerprint, 3); fingerprint = h8(fingerprint, 0);
    fingerprint = hash_bytes(fingerprint, menu, MENU_BYTES);
    fingerprint = hash_bytes(fingerprint, sound, MENU_BYTES);
    fingerprint = h32(fingerprint, get32(set, 8)); fingerprint = h32(fingerprint, get32(cleared, 8));
    printf("saveFileMutatorFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    return 0;
}
