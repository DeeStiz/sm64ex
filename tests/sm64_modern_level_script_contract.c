#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t read_u64(const uint8_t *bytes) {
    uint64_t value = 0;
    for (unsigned byte = 0; byte < 8; ++byte) {
        value |= (uint64_t) bytes[byte] << (byte * 8u);
    }
    return value;
}

int main(void) {
    static const uint8_t program[] = {
        0x13, 0x04, 0x07, 0x00, 0, 0, 0, 0,
        0x1f, 0x08, 0x02, 0x00, 0, 0, 0, 0, 0x40, 0, 0, 0, 0, 0, 0, 0,
        0x26, 0x08, 0x0a, 0x05, 0, 0, 0, 0, 0x01, 0x02, 0x80, 0, 0, 0, 0, 0,
        0x33, 0x08, 0x01, 0x0a, 0, 0, 0, 0, 0x01, 0x02, 0x03, 0, 0, 0, 0, 0,
        0x20, 0x04, 0, 0, 0, 0, 0, 0,
        0x02, 0x04, 0, 0, 0, 0, 0, 0,
    };
    static const uint8_t opcodes[] = { 0x13, 0x1f, 0x26, 0x33, 0x20, 0x02 };
    static const uint8_t sizes[] = { 0x04, 0x08, 0x08, 0x08, 0x04, 0x04 };
    static const uint8_t lengths[] = { 8, 16, 16, 16, 8, 8 };
    static const uint32_t offsets[] = { 0, 8, 24, 40, 56, 64 };

    uint64_t hash = FNV_OFFSET;
    for (unsigned index = 0; index < 6; ++index) {
        hash = hash_u64(hash, offsets[index]);
        hash = hash_u64(hash, opcodes[index]);
        hash = hash_u64(hash, sizes[index]);
        hash = hash_u64(hash, lengths[index]);
    }
    hash = hash_u64(hash, (int16_t) (program[2] | (program[3] << 8)));
    hash = hash_u64(hash, read_u64(program + 8 + 8));
    hash = hash_u64(hash, program[24 + 2]);
    hash = hash_u64(hash, program[24 + 3]);
    hash = hash_u64(hash, program[24 + 8]);
    hash = hash_u64(hash, program[24 + 9]);
    hash = hash_u64(hash, program[24 + 10]);
    hash = hash_u64(hash, program[40 + 2]);
    hash = hash_u64(hash, program[40 + 3]);
    hash = hash_u64(hash, program[40 + 8]);
    hash = hash_u64(hash, program[40 + 9]);
    hash = hash_u64(hash, program[40 + 10]);

    printf("levelScriptFingerprint=0x%016llx\n", (unsigned long long) hash);
    return 0;
}
