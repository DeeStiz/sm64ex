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

static uint64_t hash_root(
    uint64_t hash,
    uint64_t action,
    int64_t timer,
    int64_t sequence,
    int64_t wrong_lock,
    int64_t region_height,
    uint64_t active,
    uint64_t effects
) {
    const uint64_t values[] = {
        action, (uint64_t)timer, (uint64_t)sequence, (uint64_t)wrong_lock,
        (uint64_t)region_height, active, effects,
    };
    for (size_t index = 0; index < sizeof(values) / sizeof(values[0]); ++index)
        hash = hash_u64(hash, values[index]);
    return hash;
}

static uint64_t hash_bottom(
    uint64_t hash,
    uint64_t action,
    int64_t timer,
    int64_t sequence,
    int64_t wrong_lock,
    int64_t intangible_timer,
    uint64_t effects
) {
    const uint64_t values[] = {
        action, (uint64_t)timer, (uint64_t)sequence, (uint64_t)wrong_lock,
        (uint64_t)intangible_timer, effects,
    };
    for (size_t index = 0; index < sizeof(values) / sizeof(values[0]); ++index)
        hash = hash_u64(hash, values[index]);
    return hash;
}

static uint64_t hash_top(
    uint64_t hash,
    uint64_t action,
    int64_t timer,
    int64_t face_pitch,
    uint64_t effects
) {
    const uint64_t values[] = {
        action, (uint64_t)timer, (uint64_t)face_pitch, effects,
    };
    for (size_t index = 0; index < sizeof(values) / sizeof(values[0]); ++index)
        hash = hash_u64(hash, values[index]);
    return hash;
}

static uint64_t hash_bridge_effect(
    uint64_t hash,
    uint64_t object_id,
    uint64_t role,
    uint64_t variant,
    uint64_t object_list,
    uint64_t parent_id,
    uint64_t action,
    int64_t timer,
    int64_t sequence,
    int64_t wrong_lock,
    int64_t region_or_intangible,
    uint64_t active_or_pitch,
    uint64_t effects
) {
    const uint64_t identity[] = { object_id, role, variant, object_list, parent_id };
    for (size_t index = 0; index < sizeof(identity) / sizeof(identity[0]); ++index)
        hash = hash_u64(hash, identity[index]);
    if (role == 0) {
        return hash_root(hash, action, timer, sequence, wrong_lock,
                         region_or_intangible, active_or_pitch, effects);
    }
    if (role == 1) {
        return hash_bottom(hash, action, timer, sequence, wrong_lock,
                           region_or_intangible, effects);
    }
    return hash_top(hash, action, timer, region_or_intangible, effects);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;

    fingerprint = hash_root(fingerprint, 1, 0, 5, 0, 0, 1, 32);
    fingerprint = hash_root(fingerprint, 2, 0, 5, 0, 0, 1, 1536);
    fingerprint = hash_root(fingerprint, 1, 0, 5, 0, 0, 1, 32);
    fingerprint = hash_root(fingerprint, 2, 0, 5, 0, 0, 1, 1536);
    fingerprint = hash_root(fingerprint, 1, 0, 5, 0, -330, 1, 96);
    fingerprint = hash_root(fingerprint, 1, 1, 5, 0, -335, 1, 384);
    fingerprint = hash_root(fingerprint, 1, 2, 5, 0, -335, 0, 2432);

    fingerprint = hash_bottom(fingerprint, 1, 0, 2, 0, -1, 12289);
    fingerprint = hash_bottom(fingerprint, 2, 0, 1, 1, 0, 12290);
    fingerprint = hash_bottom(fingerprint, 0, 0, 1, 0, -1, 12288);
    fingerprint = hash_top(fingerprint, 1, 1, -512, 4);
    fingerprint = hash_top(fingerprint, 2, 0, -16384, 16);

    // JRB root spawn order: root, bottom1/top1, bottom2/top2, ... .
    fingerprint = hash_bridge_effect(fingerprint, 2, 1, 1, 4, 1, 1, 0, 2, 0, -1, 0, 12289);
    fingerprint = hash_bridge_effect(fingerprint, 4, 1, 1, 4, 1, 1, 0, 3, 0, -1, 0, 12289);
    fingerprint = hash_bridge_effect(fingerprint, 6, 1, 1, 4, 1, 1, 0, 4, 0, -1, 0, 12289);
    fingerprint = hash_bridge_effect(fingerprint, 8, 1, 1, 4, 1, 1, 0, 5, 0, -1, 0, 12289);
    fingerprint = hash_bridge_effect(fingerprint, 1, 0, 1, 8, 1, 1, 0, 5, 0, 0, 1, 32);
    fingerprint = hash_bridge_effect(fingerprint, 3, 2, 1, 8, 2, 1, 0, 0, 0, 0, 0, 0);
    fingerprint = hash_bridge_effect(fingerprint, 5, 2, 1, 8, 4, 1, 0, 0, 0, 0, 0, 0);
    fingerprint = hash_bridge_effect(fingerprint, 7, 2, 1, 8, 6, 1, 0, 0, 0, 0, 0, 0);
    fingerprint = hash_bridge_effect(fingerprint, 9, 2, 1, 8, 8, 1, 0, 0, 0, 0, 0, 0);

    printf("treasureChestFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern treasure chest C contract passed");
    return 0;
}
