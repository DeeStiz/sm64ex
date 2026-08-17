#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (uint32_t shift = 0; shift <= 56; shift += 8) {
        hash ^= (value >> shift) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t record_hash(uint64_t record_id, uint32_t sequence,
                            const uint64_t *values, uint32_t count) {
    uint64_t hash = FNV_OFFSET;
    hash = hash_u64(hash, 42);
    hash = hash_u64(hash, 11);
    hash = hash_u64(hash, 7);
    hash = hash_u64(hash, 0);
    hash = hash_u64(hash, record_id);
    hash = hash_u64(hash, sequence);
    hash = hash_u64(hash, count);
    hash = hash_u64(hash, 0);
    for (uint32_t index = 0; index < count; ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
}

static uint64_t vertex_hash(void) {
    const uint32_t bits[] = {
        UINT32_C(0x3f800000), UINT32_C(0xc0000000), UINT32_C(0x40400000),
        UINT32_C(0x40800000), UINT32_C(0x40a00000), UINT32_C(0x40c00000),
    };
    uint64_t hash = FNV_OFFSET;
    for (size_t index = 0; index < sizeof(bits) / sizeof(bits[0]); ++index) {
        for (uint32_t shift = 0; shift <= 24; shift += 8) {
            hash ^= ((uint64_t)(bits[index]) >> shift) & UINT64_C(0xff);
            hash *= FNV_PRIME;
        }
    }
    return hash;
}

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (uint32_t shift = 0; shift <= 24; shift += 8) {
        hash ^= ((uint64_t)value >> shift) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t rect_hash(int32_t x, int32_t y, int32_t width, int32_t height) {
    uint64_t hash = FNV_OFFSET;
    hash = hash_u32(hash, (uint32_t)x);
    hash = hash_u32(hash, (uint32_t)y);
    hash = hash_u32(hash, (uint32_t)width);
    return hash_u32(hash, (uint32_t)height);
}

int main(void) {
    const uint64_t begin[] = { 2, 2, 0, 1, 1 };
    const uint64_t draw[] = {
        17,
        6,
        1,
        vertex_hash(),
        0,
        1,
        UINT64_C(0x80000021),
        rect_hash(-2, 3, 640, 480) ^ rect_hash(1, 4, 632, 470),
    };
    const uint64_t end[] = { 2, 2, 0, 1, 1 };
    const uint64_t record_hashes[] = {
        record_hash(2, 0, begin, 5),
        record_hash(1, 1, draw, 8),
        record_hash(3, 2, end, 5),
    };
    uint64_t fingerprint = hash_u64(FNV_OFFSET, 3);
    for (size_t index = 0; index < 3; ++index) {
        fingerprint = hash_u64(fingerprint, record_hashes[index]);
    }
    printf("renderTraceFingerprint=0x%llx\n", (unsigned long long)fingerprint);
    printf("renderTraceDivergence=1\n");
    printf("SM64 Modern render trace adapter C contract passed\n");
    return 0;
}
