#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define FILE_COUNT 4
#define COURSE_COUNT 15
#define MENU_BYTES 32
#define MENU_MAGIC UINT16_C(0x4849)

static uint64_t h8(uint64_t h, uint8_t value) { h ^= value; return h * FNV_PRIME; }
static uint64_t h16(uint64_t h, uint16_t value) {
    for (unsigned i = 0; i < 2; ++i) h = h8(h, (uint8_t)(value >> (i * 8u)));
    return h;
}
static uint64_t h32(uint64_t h, uint32_t value) {
    for (unsigned i = 0; i < 4; ++i) h = h8(h, (uint8_t)(value >> (i * 8u)));
    return h;
}

typedef struct {
    uint32_t ages[FILE_COUNT];
    uint8_t modified;
} AgeState;

static uint8_t get_age(const AgeState *state, int file, int course) {
    return (uint8_t)((state->ages[file] >> (course * 2)) & 3u);
}

static int touch(AgeState *state, int file, int course) {
    uint32_t shift = (uint32_t)(course * 2);
    uint32_t mask = UINT32_C(3) << shift;
    uint32_t current = (state->ages[file] >> shift) & 3u;
    if (current == 0) return 0;
    for (int index = 0; index < FILE_COUNT; ++index) {
        uint32_t age = (state->ages[index] >> shift) & 3u;
        if (age < current) {
            state->ages[index] = (state->ages[index] & ~mask) | ((age + 1) << shift);
        }
    }
    state->ages[file] &= ~mask;
    state->modified = 1;
    return 1;
}

static void touch_all(AgeState *state, int file) {
    for (int course = 0; course < COURSE_COUNT; ++course) touch(state, file, course);
}

static uint16_t checksum(const uint8_t *bytes) {
    uint16_t sum = 0;
    for (int i = 0; i < MENU_BYTES - 2; ++i) sum = (uint16_t)(sum + bytes[i]);
    return sum;
}

static void put16(uint8_t *bytes, int offset, uint16_t value) {
    bytes[offset] = (uint8_t)value; bytes[offset + 1] = (uint8_t)(value >> 8);
}
static void put32(uint8_t *bytes, int offset, uint32_t value) {
    for (int i = 0; i < 4; ++i) bytes[offset + i] = (uint8_t)(value >> (i * 8));
}
static uint16_t get16(const uint8_t *bytes, int offset) {
    return (uint16_t)bytes[offset] | (uint16_t)bytes[offset + 1] << 8;
}
static uint32_t get32(const uint8_t *bytes, int offset) {
    uint32_t value = 0;
    for (int i = 0; i < 4; ++i) value |= (uint32_t)bytes[offset + i] << (i * 8);
    return value;
}

static void encode(uint8_t *bytes, const AgeState *state) {
    memset(bytes, 0, MENU_BYTES);
    for (int file = 0; file < FILE_COUNT; ++file) put32(bytes, file * 4, state->ages[file]);
    put16(bytes, 16, UINT16_C(0x1234));
    for (int i = 0; i < 10; ++i) bytes[18 + i] = (uint8_t)(0xA0 + i);
    put16(bytes, 28, MENU_MAGIC);
    put16(bytes, 30, checksum(bytes));
}

static int valid(const uint8_t *bytes) {
    return get16(bytes, 28) == MENU_MAGIC && get16(bytes, 30) == checksum(bytes);
}

static uint64_t hash_age(uint64_t h, const AgeState *state) {
    for (int file = 0; file < FILE_COUNT; ++file) h = h32(h, state->ages[file]);
    return h8(h, state->modified ? 1 : 0);
}
static uint64_t hash_menu(uint64_t h, const uint8_t *bytes) {
    for (int file = 0; file < FILE_COUNT; ++file) h = h32(h, get32(bytes, file * 4));
    h = h16(h, get16(bytes, 16));
    for (int i = 0; i < 10; ++i) h = h8(h, bytes[18 + i]);
    return h16(h, get16(bytes, 30));
}

int main(void) {
    AgeState state = { { UINT32_C(0x3FFFFFFF), UINT32_C(0x2AAAAAAA), UINT32_C(0x15555555), 0 }, 0 };
    uint64_t fingerprint = FNV_OFFSET;
    const int events[][2] = { { 3, 0 }, { 2, 0 }, { 1, 0 }, { 0, 0 } };
    for (unsigned i = 0; i < sizeof(events) / sizeof(events[0]); ++i) {
        int changed = touch(&state, events[i][0], events[i][1]);
        fingerprint = hash_age(fingerprint, &state);
        fingerprint = h8(fingerprint, (uint8_t)changed);
    }
    AgeState before = state;
    int unchanged = !touch(&state, 0, 0);
    if (!unchanged || memcmp(&before, &state, sizeof(state)) != 0) return 2;
    touch_all(&state, 2);
    fingerprint = hash_age(fingerprint, &state);
    if (get_age(&state, 2, 0) != 0) return 3;

    uint8_t bytes[MENU_BYTES]; encode(bytes, &state);
    if (!valid(bytes)) return 4;
    fingerprint = hash_menu(fingerprint, bytes);
    fingerprint = h8(fingerprint, (uint8_t)valid(bytes));

    uint8_t corrupt[MENU_BYTES]; memcpy(corrupt, bytes, sizeof(corrupt)); corrupt[7] ^= 1;
    if (valid(corrupt)) return 5;
    fingerprint = h8(fingerprint, 1); // primary-good, backup-corrupt
    fingerprint = h8(fingerprint, 2); // primary-corrupt, backup-good
    fingerprint = h8(fingerprint, 3); // both corrupt: wipe both

    printf("coinScoreAgesFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    return 0;
}
