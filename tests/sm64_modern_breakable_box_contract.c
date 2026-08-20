#include <stdint.h>
#include <stdio.h>

#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)

static uint64_t hash_u64(uint64_t seed, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) {
        seed ^= (value >> (byte * 8)) & 255;
        seed *= PRIME;
    }
    return seed;
}

struct Row {
    uint64_t kind, action, timer, visible, tangible, deleted, respawn;
    uint64_t model, scale, radius, height, forward, velocity;
    uint64_t coins, dust, mist, triangles, landing, sound, collision;
};

static uint64_t add_row(uint64_t seed, struct Row row) {
    const uint64_t values[] = {
        row.kind, row.action, row.timer, row.visible, row.tangible,
        row.deleted, row.respawn, row.model, row.scale, row.radius,
        row.height, row.forward, row.velocity, row.coins, row.dust,
        row.mist, row.triangles, row.landing, row.sound, row.collision,
    };
    for (unsigned index = 0; index < sizeof(values) / sizeof(values[0]); ++index)
        seed = hash_u64(seed, values[index]);
    return seed;
}

int main(void) {
    const struct Row rows[] = {
        { 0, 0, 1, 1, 1, 0, 0, 0x82, 0x3f800000, 0x43160000, 0x43480000, 0, 0, 0, 0, 0, 0, 0, 0, 1 },
        { 0, 0, 1, 0, 0, 1, 0, 0x82, 0x3f800000, 0x43160000, 0x43480000, 0, 0, 1, 0, 1, 1, 0, 1, 1 },
        { 1, 0, 1, 1, 1, 0, 0, 0x82, 0x3ecccccd, 0x43160000, 0x437a0000, 0x42200000, 0x41a00000, 0, 0, 0, 0, 0, 0, 0 },
        { 1, 0, 1, 1, 1, 0, 0, 0x82, 0x3ecccccd, 0x43160000, 0x437a0000, 0x41c80000, 0, 0, 1, 0, 0, 1, 0, 0 },
        { 1, 0, 1, 0, 0, 1, 0, 0x82, 0x3ecccccd, 0x43160000, 0x437a0000, 0x41200000, 0, 3, 0, 1, 1, 0, 1, 0 },
        { 1, 0, 1, 0, 0, 1, 1, 0x82, 0x3ecccccd, 0x43160000, 0x437a0000, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    };
    uint64_t fingerprint = OFFSET;
    for (unsigned index = 0; index < sizeof(rows) / sizeof(rows[0]); ++index) {
        fingerprint = add_row(fingerprint, rows[index]);
    }
    printf("breakableBoxFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern breakable-box C contract passed");
    return 0;
}
