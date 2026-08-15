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

static uint64_t hash_bug(
    uint64_t initial, uint64_t effects, uint64_t action,
    uint64_t home_x, uint64_t home_y, uint64_t home_z,
    uint64_t position_x, uint64_t position_y, uint64_t position_z,
    uint64_t move_yaw, uint64_t target_yaw, uint64_t forward_velocity,
    uint64_t velocity_y, uint64_t attack_window, uint64_t alert_timer,
    uint64_t move_flags, uint64_t animation_state, uint64_t timer,
    uint64_t tangible, uint64_t marked) {
    uint64_t hash = hash_u64(initial, effects);
    hash = hash_u64(hash, action);
    hash = hash_u64(hash, home_x);
    hash = hash_u64(hash, home_y);
    hash = hash_u64(hash, home_z);
    hash = hash_u64(hash, position_x);
    hash = hash_u64(hash, position_y);
    hash = hash_u64(hash, position_z);
    hash = hash_u64(hash, move_yaw);
    hash = hash_u64(hash, target_yaw);
    hash = hash_u64(hash, forward_velocity);
    hash = hash_u64(hash, velocity_y);
    hash = hash_u64(hash, attack_window);
    hash = hash_u64(hash, alert_timer);
    hash = hash_u64(hash, move_flags);
    hash = hash_u64(hash, animation_state);
    hash = hash_u64(hash, timer);
    hash = hash_u64(hash, tangible);
    return hash_u64(hash, marked);
}

static uint64_t hash_spawner(
    uint64_t initial, uint64_t effects, uint64_t action,
    uint64_t timer, uint64_t child_active, uint64_t child_unknown,
    uint64_t marked) {
    uint64_t hash = hash_u64(initial, effects);
    hash = hash_u64(hash, action);
    hash = hash_u64(hash, timer);
    hash = hash_u64(hash, child_active);
    hash = hash_u64(hash, child_unknown);
    return hash_u64(hash, marked);
}

static uint64_t hash_effect(
    uint64_t initial, uint64_t object_id, uint64_t kind,
    uint64_t effects, uint64_t action, uint64_t child, uint64_t marked) {
    uint64_t hash = hash_u64(initial, object_id);
    hash = hash_u64(hash, kind);
    hash = hash_u64(hash, action);
    hash = hash_u64(hash, effects);
    hash = hash_u64(hash, child);
    return hash_u64(hash, marked);
}

int main(void) {
    uint64_t hash = FNV_OFFSET;
    hash = hash_bug(hash, 7, 1,
                    1120403456, 1128792064, 1133903872,
                    1120403456, 1128792064, 1133903872,
                    0, 0, 0, 0, 0, 0, 3, 0, 1, 1, 0);
    hash = hash_bug(hash, 13, 1,
                    1120403456, 1128792064, 1133903872,
                    1120435613, 1130102784, 1134067515,
                    512, 512, 1084227584, 1101004800, 0, 1, 3, 0, 2, 1, 0);
    hash = hash_bug(hash, 133, 2,
                    1120403456, 1128792064, 1133903872,
                    1120435613, 1131413504, 1134559035,
                    0, 33280, 1097859072, 1101004800, 0, 2, 1027, 0, 3, 1, 0);
    hash = hash_bug(hash, 17, 1,
                    1120403456, 1128792064, 1133903872,
                    1120403456, 1132593152, 1134395392,
                    33280, 33280, 1084227584, 1101004800, 0, 2, 3, 0, 4, 1, 0);
    hash = hash_bug(hash, 4897, 4,
                    0, 0, 0, 0, 0, 0,
                    0, 0, 3240099840, 1106247680, 0, 0, 0, 0, 1, 0, 1);
    hash = hash_spawner(hash, 1024, 1, 32, 1, 1, 0);
    hash = hash_effect(hash, 1, 1, 1024, 255, 2, 0);
    printf("scuttlebugObjectBridgeFingerprint=0x%016llx\n", (unsigned long long)hash);
    return 0;
}
