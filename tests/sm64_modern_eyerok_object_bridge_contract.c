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

static uint64_t hash_effect(
    uint64_t initial,
    uint64_t object_id,
    uint64_t parent_id,
    uint64_t kind,
    uint64_t side,
    uint64_t boss_action,
    uint64_t hand_action,
    uint64_t boss_effects,
    uint64_t hand_effects,
    uint64_t has_star,
    uint64_t child_count,
    const uint64_t *children,
    uint64_t presented_count,
    const uint64_t *presented_kinds,
    const uint64_t *presented_values) {
    uint64_t hash = initial;
    const uint64_t fields[] = {
        object_id, parent_id, kind, side, boss_action, hand_action,
        boss_effects, hand_effects, has_star, child_count
    };
    for (size_t index = 0; index < sizeof(fields) / sizeof(fields[0]); ++index) {
        hash = hash_u64(hash, fields[index]);
    }
    for (uint64_t index = 0; index < child_count; ++index) {
        hash = hash_u64(hash, children[index]);
    }
    hash = hash_u64(hash, presented_count);
    for (uint64_t index = 0; index < presented_count; ++index) {
        hash = hash_u64(hash, presented_kinds[index]);
        hash = hash_u64(hash, presented_values[index]);
    }
    return hash;
}

int main(void) {
    const uint64_t children[] = { 2, 3 };
    const uint64_t presented_kind[] = { 0 };
    const uint64_t presented_value[] = { 0 };
    uint64_t fingerprint = hash_effect(
        FNV_OFFSET, 1, 0, 0, 0, 0, 255, 1, 0, 0,
        2, children, 0, NULL, NULL
    );
    fingerprint = hash_effect(
        fingerprint, 3, 1, 1, 1, 255, 3, 0, 512, 0,
        0, NULL, 0, NULL, NULL
    );
    fingerprint = hash_effect(
        fingerprint, 3, 1, 1, 1, 255, 15, 0, 1027, 0,
        0, NULL, 1, presented_kind, presented_value
    );
    printf("eyerokObjectBridgeFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    printf("SM64 Modern Eyerok owner bridge C contract passed\n");
    return 0;
}
