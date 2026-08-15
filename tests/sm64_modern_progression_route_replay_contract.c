#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t h8(uint64_t h, uint8_t value) {
    h ^= value;
    return h * FNV_PRIME;
}

static uint64_t h32(uint64_t h, uint32_t value) {
    for (unsigned i = 0; i < 4; ++i)
        h = h8(h, (uint8_t) (value >> (i * 8u)));
    return h;
}

static uint64_t h64(uint64_t h, uint64_t value) {
    for (unsigned i = 0; i < 8; ++i)
        h = h8(h, (uint8_t) (value >> (i * 8u)));
    return h;
}

int main(void) {
    static const uint8_t route_ids[9] = { 1, 2, 3, 4, 5, 6, 7, 8, 9 };
    static const uint32_t generations[9] = { 0, 0, 1, 1, 1, 1, 1, 1, 1 };
    static const uint64_t save_hashes[9] = {
        UINT64_C(0x5e18c6abd66788eb), UINT64_C(0x5e18c6abd66788eb),
        UINT64_C(0x5e18c6abd66788eb), UINT64_C(0x5d4fd8ed21bba565),
        UINT64_C(0x1efbd14a86ef3095), UINT64_C(0x1efbd14a86ef3095),
        UINT64_C(0x75ff25253d40f8bd), UINT64_C(0x75ff25253d40f8bd),
        UINT64_C(0x75ff25253d40f8bd)
    };
    static const uint64_t menu_hashes[9] = {
        UINT64_C(0x69fcb2c3fec8933a), UINT64_C(0x69fcb2c3fec8933a),
        UINT64_C(0x69fcb2c3fec8933a), UINT64_C(0x69fcb2c3fec8933a),
        UINT64_C(0xffd95ebad935703a), UINT64_C(0xffd95ebad935703a),
        UINT64_C(0xffd95ebad935703a), UINT64_C(0xffd95ebad935703a),
        UINT64_C(0xffd95ebad935703a)
    };

    uint64_t fingerprint = FNV_OFFSET;
    for (unsigned i = 0; i < 9; ++i) {
        fingerprint = h8(fingerprint, route_ids[i]);
        fingerprint = h32(fingerprint, generations[i]);
        fingerprint = h8(fingerprint, 1);
        fingerprint = h64(fingerprint, save_hashes[i]);
        fingerprint = h64(fingerprint, menu_hashes[i]);
    }
    printf("progressionRouteReplayFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    return 0;
}
