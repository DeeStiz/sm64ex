#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define SAVE_SIZE 56
#define SAVE_MAGIC UINT16_C(0x4441)

static uint64_t h8(uint64_t h, uint8_t value) { h ^= value; return h * FNV_PRIME; }
static uint64_t h16(uint64_t h, uint16_t value) {
    for (unsigned i = 0; i < 2; ++i) h = h8(h, (uint8_t)(value >> (i * 8u)));
    return h;
}
static uint64_t h32(uint64_t h, uint32_t value) {
    for (unsigned i = 0; i < 4; ++i) h = h8(h, (uint8_t)(value >> (i * 8u)));
    return h;
}

static uint16_t read16(const uint8_t *bytes, size_t offset) {
    return (uint16_t)bytes[offset] | (uint16_t)bytes[offset + 1] << 8;
}
static void write16(uint8_t *bytes, size_t offset, uint16_t value) {
    bytes[offset] = (uint8_t)value; bytes[offset + 1] = (uint8_t)(value >> 8);
}
static void write32(uint8_t *bytes, size_t offset, uint32_t value) {
    for (unsigned i = 0; i < 4; ++i) bytes[offset + i] = (uint8_t)(value >> (i * 8u));
}
static uint16_t checksum(const uint8_t *bytes) {
    uint16_t sum = 0;
    for (size_t i = 0; i < SAVE_SIZE - 2; ++i) sum = (uint16_t)(sum + bytes[i]);
    return sum;
}
static int verify(const uint8_t *bytes) {
    return read16(bytes, 52) == SAVE_MAGIC && read16(bytes, 54) == checksum(bytes);
}

typedef struct { uint8_t decision; int selected; } Recovery;
static Recovery recover(const uint8_t *primary, const uint8_t *backup) {
    int p = verify(primary), b = verify(backup);
    if (p && b) return (Recovery){ 0, 1 };
    if (p) return (Recovery){ 1, 1 };
    if (b) return (Recovery){ 2, 1 };
    return (Recovery){ 3, 0 };
}

static uint64_t hash_bytes(uint64_t h, const uint8_t *bytes) {
    for (size_t i = 0; i < SAVE_SIZE; ++i) h = h8(h, bytes[i]);
    return h;
}
static uint64_t hash_recovery(uint64_t h, Recovery recovery, const uint8_t *selected) {
    h = h8(h, recovery.decision); h = h8(h, recovery.selected ? 1 : 0);
    if (recovery.selected) {
        h = h8(h, selected[0]); h = h8(h, selected[1]);
        h = h16(h, read16(selected, 2)); h = h16(h, read16(selected, 4)); h = h16(h, read16(selected, 6));
        h = h32(h, (uint32_t)read16(selected, 8) | (uint32_t)read16(selected, 10) << 16);
        for (size_t i = 12; i < 37; ++i) h = h8(h, selected[i]);
        for (size_t i = 37; i < 52; ++i) h = h8(h, selected[i]);
        h = h16(h, read16(selected, 54));
    }
    return h;
}

int main(void) {
    uint8_t bytes[SAVE_SIZE] = { 0 };
    bytes[0] = 7; bytes[1] = 2;
    write16(bytes, 2, (uint16_t)-10); write16(bytes, 4, 20); write16(bytes, 6, 30);
    write32(bytes, 8, (1u << 0) | (1u << 6) | (1u << 18));
    bytes[12 + 2] = 0x04; bytes[12 + 3] = 0x80; bytes[37 + 2] = 100;
    write16(bytes, 52, SAVE_MAGIC); write16(bytes, 54, checksum(bytes));

    uint8_t corrupt_primary[SAVE_SIZE];
    uint8_t corrupt_backup[SAVE_SIZE];
    for (size_t i = 0; i < SAVE_SIZE; ++i) { corrupt_primary[i] = bytes[i]; corrupt_backup[i] = bytes[i]; }
    corrupt_primary[20] ^= 1;
    corrupt_backup[54] ^= 0x80;
    uint8_t both_corrupt[SAVE_SIZE];
    for (size_t i = 0; i < SAVE_SIZE; ++i) both_corrupt[i] = corrupt_primary[i];
    both_corrupt[52] ^= 0xFF;

    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_bytes(fingerprint, bytes);
    fingerprint = hash_recovery(fingerprint, recover(corrupt_primary, bytes), bytes);
    fingerprint = hash_recovery(fingerprint, recover(bytes, corrupt_backup), bytes);
    fingerprint = hash_recovery(fingerprint, recover(corrupt_primary, both_corrupt), NULL);
    printf("saveFileCodecFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    return 0;
}
