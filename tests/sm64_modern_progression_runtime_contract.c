#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define FILE_EXISTS (1u << 0)

static uint64_t h8(uint64_t h, uint8_t v) { h ^= v; return h * FNV_PRIME; }
static uint64_t h16(uint64_t h, uint16_t v) { for (unsigned i = 0; i < 2; ++i) h = h8(h, (uint8_t)(v >> (i * 8u))); return h; }
static uint64_t h32(uint64_t h, uint32_t v) { for (unsigned i = 0; i < 4; ++i) h = h8(h, (uint8_t)(v >> (i * 8u))); return h; }
static uint64_t h64(uint64_t h, uint64_t v) { for (unsigned i = 0; i < 8; ++i) h = h8(h, (uint8_t)(v >> (i * 8u))); return h; }

typedef struct {
    uint8_t red_coins, red_star, cap_switches, level_completed;
    uint32_t flags;
    int16_t coins;
    uint8_t score;
    uint32_t ages[4];
    uint8_t menu_modified, save_modified;
} Runtime;

static uint64_t hash_result(uint64_t h, uint64_t tick, uint32_t event_id,
                            uint8_t accepted, const Runtime *r,
                            uint16_t actor_effects, uint16_t progression_effects,
                            uint8_t persistence_needed) {
    h = h64(h, tick); h = h32(h, event_id); h = h8(h, accepted);
    h = h64(h, r->red_coins); h = h64(h, r->red_coins == 8);
    h = h64(h, r->cap_switches); h = h64(h, r->level_completed);
    h = h64(h, r->flags); h = h64(h, (uint64_t)(int64_t)r->coins);
    h = h64(h, r->score); h = h64(h, (r->ages[0] >> 4) & 3u);
    h = h16(h, actor_effects); h = h16(h, progression_effects);
    return h8(h, persistence_needed);
}

int main(void) {
    Runtime r = { 0 }; r.flags = FILE_EXISTS; r.coins = 10;
    r.ages[0] = UINT32_C(0x3FFFFFFF); r.ages[1] = UINT32_C(0x2AAAAAAA);
    r.ages[2] = UINT32_C(0x15555555); r.ages[3] = 0;
    uint64_t fingerprint = FNV_OFFSET;
    for (unsigned tick = 0; tick < 8; ++tick) {
        r.coins += 2; r.red_coins += 1; uint16_t effects = 0x81; if (r.red_coins == 8) { r.red_star = 1; effects |= 0x0A; }
        fingerprint = hash_result(fingerprint, tick, 2, 1, &r, effects, 0x401, 0);
    }
    r.score = 100; r.level_completed = 1; r.flags |= FILE_EXISTS; r.save_modified = 1;
    r.ages[0] &= ~UINT32_C(0x30);
    r.ages[1] = (r.ages[1] & ~UINT32_C(0x30)) | UINT32_C(0x30);
    r.ages[2] = (r.ages[2] & ~UINT32_C(0x30)) | UINT32_C(0x20);
    r.ages[3] = (r.ages[3] & ~UINT32_C(0x30)) | UINT32_C(0x10);
    r.menu_modified = 1;
    fingerprint = hash_result(fingerprint, 8, 4, 1, &r, 0x38, 0x602, 1);
    printf("progressionRuntimeFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    return 0;
}
