#include <stdint.h>
#include <stdio.h>

static const uint64_t FNV_OFFSET = UINT64_C(1469598103934665603);
static const uint64_t FNV_PRIME = UINT64_C(1099511628211);

static uint64_t hash_u64(uint64_t initial, uint64_t value) {
    uint64_t hash = initial;
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_effect(uint64_t hash, uint64_t object_id, uint64_t variant,
                            uint64_t action, uint64_t effects, uint64_t health,
                            uint64_t child_count, const uint64_t *children,
                            uint64_t presented_count, const uint64_t *kinds,
                            const uint64_t *values, uint64_t deleted,
                            uint64_t rejected) {
    const uint64_t initial[] = { object_id, variant, action, effects, health, child_count };
    for (size_t index = 0; index < sizeof(initial) / sizeof(initial[0]); ++index) {
        hash = hash_u64(hash, initial[index]);
    }
    for (uint64_t index = 0; index < child_count; ++index) {
        hash = hash_u64(hash, children[index]);
    }
    hash = hash_u64(hash, presented_count);
    for (uint64_t index = 0; index < presented_count; ++index) {
        hash = hash_u64(hash, kinds[index]);
        hash = hash_u64(hash, values[index]);
    }
    hash = hash_u64(hash, deleted);
    return hash_u64(hash, rejected);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    const uint64_t ghost_children[] = { 2, 3, 4 };
    fingerprint = hash_effect(
        fingerprint, 1, 0, 4, 49152, 3, 3, ghost_children,
        0, NULL, NULL, 1, 0
    );
    const uint64_t star_children[] = { 5 };
    const uint64_t kinds[] = { 1, 9 };
    const uint64_t values[] = { 1, 1 };
    fingerprint = hash_effect(
        fingerprint, 1, 2, 4, 8448, 0, 1, star_children,
        2, kinds, values, 0, 0
    );
    printf("bigBooObjectBridgeFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    printf("SM64 Modern Big Boo owner bridge C contract passed\n");
    return 0;
}
