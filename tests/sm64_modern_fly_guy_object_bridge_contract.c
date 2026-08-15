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

static uint64_t hash_state(uint64_t hash, const uint64_t *values, size_t count) {
    for (size_t index = 0; index < count; ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
}

static uint64_t hash_flame(uint64_t hash) {
    const uint64_t values[] = {
        0, 0, 1141325234, 1101266944, 1072902963, 0, 1, 0
    };
    return hash_state(hash, values, sizeof(values) / sizeof(values[0]));
}

static uint64_t hash_effect(
    uint64_t hash,
    uint64_t object_id,
    uint64_t kind,
    uint64_t effects,
    uint64_t action,
    uint64_t child_count,
    uint64_t child_id,
    uint64_t marked
) {
    const uint64_t header[] = { object_id, kind, effects, action, child_count };
    hash = hash_state(hash, header, sizeof(header) / sizeof(header[0]));
    if (child_count != 0) {
        hash = hash_u64(hash, child_id);
    }
    return hash_u64(hash, marked);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;

    const uint64_t approach[] = {
        0x207, 1,
        1092616192, 1140457472, 1106247680,
        1092616192, 1140506387, 1106247680,
        0, 0, 0, 0,
        0, 0, 1069547520, 0,
        0, 0, 0, 3, 1, 1, 0, 1
    };
    fingerprint = hash_state(fingerprint, approach, sizeof(approach) / sizeof(approach[0]));

    const uint64_t lunge[] = {
        0x20d, 2,
        0, 1140457472, 0,
        0, 1140819881, 1102628513,
        0, 0, 0, 0,
        1102628513, 1092162248, 1069547520, 0,
        61440, 3198371644, 0, 0, 1, 1, 0, 1
    };
    fingerprint = hash_state(fingerprint, lunge, sizeof(lunge) / sizeof(lunge[0]));

    const uint64_t shoot[] = {
        0x215, 3,
        0, 1140457472, 0,
        0, 1140506387, 1056964608,
        0, 0, 0, 0,
        1056964608, 0, 1069547520, 1031127695,
        0, 0, 0, 0, 1, 1, 0, 1
    };
    fingerprint = hash_state(fingerprint, shoot, sizeof(shoot) / sizeof(shoot[0]));

    const uint64_t spit[] = {
        0x271, 3,
        0, 1140457472, 0,
        0, 1140554595, 1056964608,
        0, 0, 0, 0,
        0, 0, 1066947052, 0,
        0, 0, 0, 0, 2, 1, 0, 2
    };
    fingerprint = hash_state(fingerprint, spit, sizeof(spit) / sizeof(spit[0]));

    fingerprint = hash_flame(fingerprint);

    const uint64_t wall[] = {
        0x2f1, 3,
        0, 1140457472, 0,
        0, 1140601631, 1056964608,
        0, 0, 0, 0,
        0, 0, 1066947052, 0,
        0, 0, 0, 0, 3, 1, 0, 3
    };
    fingerprint = hash_state(fingerprint, wall, sizeof(wall) / sizeof(wall[0]));

    fingerprint = hash_effect(fingerprint, 1, 0, 0x271, 3, 1, 2, 0);
    fingerprint = hash_effect(fingerprint, 2, 1, 0, 255, 0, 0, 0);

    printf("flyGuyObjectBridgeFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    return 0;
}
