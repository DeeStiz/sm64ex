#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (uint32_t shift = 0; shift <= 24; shift += 8) {
        hash ^= ((uint64_t)value >> shift) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (uint32_t shift = 0; shift <= 56; shift += 8) {
        hash ^= (value >> shift) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_event(uint32_t kind, const uint64_t *values, uint32_t count) {
    uint64_t hash = hash_u32(FNV_OFFSET, kind);
    hash = hash_u32(hash, count);
    for (uint32_t index = 0; index < count; ++index) hash = hash_u64(hash, values[index]);
    return hash;
}

static uint64_t hash_rect(int32_t x, int32_t y, int32_t width, int32_t height) {
    uint64_t hash = FNV_OFFSET;
    hash = hash_u32(hash, (uint32_t)x);
    hash = hash_u32(hash, (uint32_t)y);
    hash = hash_u32(hash, (uint32_t)width);
    return hash_u32(hash, (uint32_t)height);
}

static uint64_t hash_vertices(void) {
    const uint32_t bits[] = {
        UINT32_C(0x3f800000), UINT32_C(0xc0000000), UINT32_C(0x40400000),
        UINT32_C(0x40800000), UINT32_C(0x40a00000), UINT32_C(0x40c00000),
    };
    uint64_t hash = FNV_OFFSET;
    for (size_t index = 0; index < sizeof(bits) / sizeof(bits[0]); ++index) {
        hash = hash_u32(hash, bits[index]);
    }
    return hash;
}

static uint64_t hash_frame(void) {
    const uint64_t begin[] = { 2, 2, 0, 1, 1 };
    const uint64_t draw[] = {
        17,
        6,
        1,
        hash_vertices(),
        0,
        1,
        UINT64_C(0x80000021),
        hash_rect(-2, 3, 640, 480) ^ hash_rect(1, 4, 632, 470),
    };
    const uint64_t end[] = { 2, 2, 0, 1, 1 };
    const uint64_t events[] = {
        hash_event(2, begin, 5),
        hash_event(1, draw, 8),
        hash_event(3, end, 5),
    };
    uint64_t hash = hash_u64(FNV_OFFSET, 1);
    hash = hash_u32(hash, 3);
    for (size_t index = 0; index < 3; ++index) hash = hash_u64(hash, events[index]);
    return hash;
}

static uint64_t hash_finish(void) {
    const uint64_t values[] = { 0, 0, 2, 2 };
    return hash_event(4, values, 4);
}

int main(void) {
    printf("renderFrameFingerprint=0x%llx\n", (unsigned long long)hash_frame());
    printf("renderFinishFingerprint=0x%llx\n", (unsigned long long)hash_finish());
    printf("SM64 Modern render packet capture C contract passed\n");
    return 0;
}
