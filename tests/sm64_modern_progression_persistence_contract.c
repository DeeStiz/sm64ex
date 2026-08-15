#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define SAVE_BYTES 56
#define MENU_BYTES 32
#define BUNDLE_BYTES (SAVE_BYTES * 2 + MENU_BYTES * 2)
#define SAVE_MAGIC UINT16_C(0x4441)
#define MENU_MAGIC UINT16_C(0x4849)
#define FILE_EXISTS (1u << 0)
#define WING_CAP (1u << 1)

static uint64_t h8(uint64_t h, uint8_t value) { h ^= value; return h * FNV_PRIME; }
static uint64_t h16(uint64_t h, uint16_t value) { for (unsigned i = 0; i < 2; ++i) h = h8(h, (uint8_t)(value >> (i * 8u))); return h; }
static uint64_t h32(uint64_t h, uint32_t value) { for (unsigned i = 0; i < 4; ++i) h = h8(h, (uint8_t)(value >> (i * 8u))); return h; }
static void put16(uint8_t *b, int o, uint16_t v) { b[o] = (uint8_t)v; b[o + 1] = (uint8_t)(v >> 8); }
static void put32(uint8_t *b, int o, uint32_t v) { for (int i = 0; i < 4; ++i) b[o + i] = (uint8_t)(v >> (i * 8)); }
static uint16_t get16(const uint8_t *b, int o) { return (uint16_t)b[o] | (uint16_t)b[o + 1] << 8; }
static uint16_t checksum(const uint8_t *b, int n) { uint16_t sum = 0; for (int i = 0; i < n - 2; ++i) sum = (uint16_t)(sum + b[i]); return sum; }

static void encode_save(uint8_t *b) {
    memset(b, 0, SAVE_BYTES); b[0] = 7; b[1] = 2;
    put16(b, 2, (uint16_t)-10); put16(b, 4, 20); put16(b, 6, 30);
    put32(b, 8, FILE_EXISTS | WING_CAP); b[12 + 2] = 4; b[37 + 2] = 100;
    put16(b, 52, SAVE_MAGIC); put16(b, 54, checksum(b, SAVE_BYTES));
}
static void encode_menu(uint8_t *b) {
    memset(b, 0, MENU_BYTES); put32(b, 0, UINT32_C(0x3FFFFFFF));
    put32(b, 4, UINT32_C(0x2AAAAAAA)); put32(b, 8, UINT32_C(0x15555555));
    put16(b, 16, UINT16_C(0x1234)); for (int i = 0; i < 10; ++i) b[18 + i] = (uint8_t)(0xA0 + i);
    put16(b, 28, MENU_MAGIC); put16(b, 30, checksum(b, MENU_BYTES));
}
static int valid_save(const uint8_t *b) { return get16(b, 52) == SAVE_MAGIC && get16(b, 54) == checksum(b, SAVE_BYTES); }
static int valid_menu(const uint8_t *b) { return get16(b, 28) == MENU_MAGIC && get16(b, 30) == checksum(b, MENU_BYTES); }
static uint64_t hash_bytes(uint64_t h, const uint8_t *b) { for (int i = 0; i < BUNDLE_BYTES; ++i) h = h8(h, b[i]); return h; }
static uint64_t hash_result(uint64_t h, const uint8_t *bundle, uint8_t save_decision, uint8_t menu_decision) {
    h = h8(h, save_decision); h = h8(h, menu_decision);
    if (save_decision == 3) {
        h = h32(h, 0);
        for (int i = 0; i < 25; ++i) h = h8(h, 0);
        for (int i = 0; i < 15; ++i) h = h8(h, 0);
    } else {
        h = h32(h, (uint32_t)bundle[8] | (uint32_t)bundle[9] << 8 | (uint32_t)bundle[10] << 16 | (uint32_t)bundle[11] << 24);
        for (int i = 0; i < 25; ++i) h = h8(h, bundle[12 + i]);
        for (int i = 0; i < 15; ++i) h = h8(h, bundle[37 + i]);
    }
    if (menu_decision == 3) {
        h = h32(h, UINT32_C(0x3FFFFFFF));
        h = h32(h, UINT32_C(0x2AAAAAAA));
        h = h32(h, UINT32_C(0x15555555));
        h = h32(h, 0);
        return h16(h, 0);
    }
    for (int i = 0; i < 4; ++i) h = h32(h, (uint32_t)bundle[112 + i * 4] | (uint32_t)bundle[113 + i * 4] << 8 | (uint32_t)bundle[114 + i * 4] << 16 | (uint32_t)bundle[115 + i * 4] << 24);
    return h16(h, get16(bundle, 112 + 16));
}

int main(void) {
    uint8_t bundle[BUNDLE_BYTES]; memset(bundle, 0, sizeof(bundle));
    encode_save(bundle); encode_save(bundle + SAVE_BYTES); encode_menu(bundle + SAVE_BYTES * 2); encode_menu(bundle + SAVE_BYTES * 2 + MENU_BYTES);
    uint64_t fingerprint = hash_bytes(FNV_OFFSET, bundle);
    fingerprint = hash_result(fingerprint, bundle, 0, 0);

    bundle[0] ^= 1;
    fingerprint = hash_bytes(fingerprint, bundle); fingerprint = hash_result(fingerprint, bundle, 2, 0);

    bundle[SAVE_BYTES] ^= 1;
    bundle[SAVE_BYTES * 2] ^= 1;
    bundle[SAVE_BYTES * 2 + MENU_BYTES] ^= 1;
    fingerprint = hash_bytes(fingerprint, bundle); fingerprint = hash_result(fingerprint, bundle, 3, 3);

    // Route identity/lifetime: level 7, area 2, behavior 0x123456789ABCDEF0,
    // instance 4, hidden-star kind 1, generations 1 active then inactive.
    fingerprint = h16(fingerprint, 7); fingerprint = h8(fingerprint, 2);
    fingerprint = h32(fingerprint, UINT32_C(0x9ABCDEF0)); fingerprint = h8(fingerprint, 0x78);
    fingerprint = h16(fingerprint, 4); fingerprint = h8(fingerprint, 1); fingerprint = h32(fingerprint, 1); fingerprint = h8(fingerprint, 1);
    fingerprint = h16(fingerprint, 7); fingerprint = h8(fingerprint, 2);
    fingerprint = h32(fingerprint, UINT32_C(0x9ABCDEF0)); fingerprint = h8(fingerprint, 0x78);
    fingerprint = h16(fingerprint, 4); fingerprint = h8(fingerprint, 1); fingerprint = h32(fingerprint, 1); fingerprint = h8(fingerprint, 0);

    printf("progressionPersistenceFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    return 0;
}
