#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define SAVE_BYTES 56
#define MENU_BYTES 32
#define FILE_COUNT 4
#define COURSE_COUNT 25
#define STAGE_COUNT 15
#define FILE_EXISTS UINT32_C(1)
#define CAP_ON_GROUND (UINT32_C(1) << 16)

static uint64_t h8(uint64_t h, uint8_t value) { h ^= value; return h * FNV_PRIME; }
static uint64_t h16(uint64_t h, uint16_t value) {
    for (int i = 0; i < 2; ++i) h = h8(h, (uint8_t)(value >> (i * 8)));
    return h;
}
static uint64_t h32(uint64_t h, uint32_t value) {
    for (int i = 0; i < 4; ++i) h = h8(h, (uint8_t)(value >> (i * 8)));
    return h;
}
static uint64_t hbool(uint64_t h, int value) {
    return h8(h, value < 0 ? 0xFF : (uint8_t)(value != 0));
}
static void put16(uint8_t *b, int o, uint16_t v) { b[o] = (uint8_t)v; b[o + 1] = (uint8_t)(v >> 8); }
static void put32(uint8_t *b, int o, uint32_t v) { for (int i = 0; i < 4; ++i) b[o + i] = (uint8_t)(v >> (i * 8)); }
static uint16_t checksum(const uint8_t *b, int n) { uint16_t x = 0; for (int i = 0; i < n - 2; ++i) x = (uint16_t)(x + b[i]); return x; }

static void encode_save(uint8_t *b, uint32_t flags, const uint8_t *stars, const uint8_t *scores) {
    memset(b, 0, SAVE_BYTES);
    b[0] = 7; b[1] = 2;
    put16(b, 2, (uint16_t)-10); put16(b, 4, 20); put16(b, 6, 30);
    put32(b, 8, flags);
    memcpy(b + 12, stars, COURSE_COUNT);
    memcpy(b + 37, scores, STAGE_COUNT);
    put16(b, 52, UINT16_C(0x4441));
    put16(b, 54, checksum(b, SAVE_BYTES));
}

static uint32_t get32(const uint8_t *b, int o) {
    return (uint32_t)b[o] | (uint32_t)b[o + 1] << 8
        | (uint32_t)b[o + 2] << 16 | (uint32_t)b[o + 3] << 24;
}

static int exists(const uint8_t *save) { return (get32(save, 8) & FILE_EXISTS) != 0; }

static int star_flags(const uint8_t *save, int course) {
    if (course == -1) return (int)((get32(save, 8) >> 24) & 0x7F);
    return save[12 + course] & 0x7F;
}

static int cannon_flags(const uint8_t *save, int course) {
    return (save[12 + course + 1] & 0x80) != 0;
}

static int cannon_unlocked(const uint8_t *save, int course_number) {
    return (save[12 + course_number] & 0x80) != 0;
}

static uint32_t maximum_coin_score(
    const uint8_t saves[FILE_COUNT][SAVE_BYTES],
    const uint32_t ages[FILE_COUNT], int course
) {
    int max_score = -1, max_age = -1, max_file = 0;
    for (int file = 0; file < FILE_COUNT; ++file) {
        if (star_flags(saves[file], course) == 0) continue;
        int score = saves[file][37 + course];
        int age = (int)((ages[file] >> (course * 2)) & 3);
        if (score > max_score || (score == max_score && age > max_age)) {
            max_score = score; max_age = age; max_file = file + 1;
        }
    }
    return ((uint32_t)max_file << 16) | (uint32_t)(max_score < 0 ? 0 : max_score);
}

static void expect(int condition, const char *message) {
    if (!condition) {
        fprintf(stderr, "save-file queries contract failed: %s\n", message);
        __builtin_trap();
    }
}

int main(void) {
    uint8_t saves[FILE_COUNT][SAVE_BYTES];
    uint8_t stars[FILE_COUNT][COURSE_COUNT];
    uint8_t scores[FILE_COUNT][STAGE_COUNT];
    memset(stars, 0, sizeof(stars)); memset(scores, 0, sizeof(scores));
    stars[0][0] = 0x05; stars[0][1] = 0x81; stars[0][4] = 0x02;
    scores[0][0] = 100; scores[0][1] = 42;
    stars[1][0] = 0x03; stars[1][1] = 0x01;
    scores[1][0] = 120; scores[1][1] = 42;
    encode_save(saves[0], FILE_EXISTS | CAP_ON_GROUND, stars[0], scores[0]);
    encode_save(saves[1], FILE_EXISTS, stars[1], scores[1]);
    encode_save(saves[2], 0, stars[2], scores[2]);
    encode_save(saves[3], 0, stars[3], scores[3]);
    const uint32_t ages[FILE_COUNT] = {
        UINT32_C(0x3FFFFFFF), UINT32_C(0x2AAAAAAA),
        UINT32_C(0x15555555), UINT32_C(0)
    };

    expect(exists(saves[0]) && !exists(saves[2]), "file existence");
    expect(star_flags(saves[0], -1) == 0, "secret stars");
    expect(star_flags(saves[0], 0) == 0x05, "course stars");
    expect(cannon_flags(saves[0], 0) == 1, "cannon flags");
    expect(cannon_unlocked(saves[0], 1) == 1, "current cannon");
    expect((saves[0][37 + 1] == 42), "course score");
    expect(__builtin_popcount(star_flags(saves[0], 0)) == 2, "course count");
    expect(__builtin_popcount(star_flags(saves[0], 0))
        + __builtin_popcount(star_flags(saves[0], 1))
        + __builtin_popcount(star_flags(saves[0], 2))
        + __builtin_popcount(star_flags(saves[0], 3))
        + __builtin_popcount(star_flags(saves[0], 4)) == 4, "total count");
    expect(maximum_coin_score(saves, ages, 0) == UINT32_C(0x00020078), "max score course 0");
    expect(maximum_coin_score(saves, ages, 1) == UINT32_C(0x0001002A), "max score course 1");

    uint64_t fingerprint = FNV_OFFSET;
    for (int file = 0; file < FILE_COUNT; ++file)
        for (int i = 0; i < SAVE_BYTES; ++i) fingerprint = h8(fingerprint, saves[file][i]);
    for (int file = 0; file < FILE_COUNT; ++file) fingerprint = h32(fingerprint, ages[file]);
    fingerprint = h16(fingerprint, UINT16_C(0x1234));
    for (int file = 0; file < FILE_COUNT; ++file) {
        fingerprint = hbool(fingerprint, exists(saves[file]));
        const int courses[] = {-1, 0, 1, 4};
        for (unsigned i = 0; i < sizeof(courses) / sizeof(courses[0]); ++i)
            fingerprint = h8(fingerprint, (uint8_t)star_flags(saves[file], courses[i]));
        fingerprint = h8(fingerprint, (uint8_t)cannon_flags(saves[file], 0));
        fingerprint = hbool(fingerprint, cannon_unlocked(saves[file], 1));
        fingerprint = h8(fingerprint, saves[file][37 + 1]);
        fingerprint = h32(fingerprint, (uint32_t)__builtin_popcount(star_flags(saves[file], 0)));
        int total = 0;
        for (int course = 0; course <= 4; ++course) total += __builtin_popcount(star_flags(saves[file], course));
        total += __builtin_popcount(star_flags(saves[file], -1));
        fingerprint = h32(fingerprint, (uint32_t)total);
        if ((get32(saves[file], 8) & CAP_ON_GROUND) != 0) {
            fingerprint = h16(fingerprint, (uint16_t)-10);
            fingerprint = h16(fingerprint, 20);
            fingerprint = h16(fingerprint, 30);
        } else {
            fingerprint = h8(fingerprint, 0xFF);
        }
    }
    for (int course = 0; course < STAGE_COUNT; ++course)
        fingerprint = h32(fingerprint, maximum_coin_score(saves, ages, course));

    printf("saveFileQueriesFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    return 0;
}
