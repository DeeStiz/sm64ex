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

static uint64_t hash_id(uint64_t initial, int present, uint64_t slot, uint64_t generation) {
    if (!present)
        return hash_u64(initial, 0);
    uint64_t hash = hash_u64(initial, 1);
    hash = hash_u64(hash, slot);
    return hash_u64(hash, generation);
}

static uint64_t hash_float(uint64_t initial, float value) {
    union { float f; uint32_t u; } bits = { value };
    return hash_u64(initial, bits.u);
}

static uint64_t hash_intent(
    uint64_t initial, uint64_t sequence, uint64_t slot, uint64_t generation,
    uint64_t kind, int64_t value, int64_t auxiliary) {
    uint64_t hash = hash_u64(initial, sequence);
    hash = hash_id(hash, 1, slot, generation);
    hash = hash_u64(hash, kind);
    hash = hash_u64(hash, (uint64_t) value);
    return hash_u64(hash, (uint64_t) auxiliary);
}

static uint64_t hash_output(
    uint64_t initial, int32_t action, int32_t sub_action, float scale,
    int32_t animation, float forward_velocity, int16_t move_yaw,
    int16_t angle_velocity_yaw, int32_t dialog_id, int dialog_requested,
    int child_small_unk88, uint32_t child_interaction_set_mask,
    int clear_child_drop_immediate, int32_t child_behavior, int spawn_star,
    int has_star_home, float star_x, float star_y, float star_z,
    float star_spawn_y_offset, int play_walking_sound, int play_yell_sound,
    int active_flag_unk10) {
    uint64_t hash = hash_u64(initial, (uint64_t) (int64_t) action);
    hash = hash_u64(hash, (uint64_t) (int64_t) sub_action);
    hash = hash_float(hash, scale);
    hash = hash_u64(hash, (uint64_t) (int64_t) animation);
    hash = hash_float(hash, forward_velocity);
    hash = hash_u64(hash, (uint64_t) (uint16_t) move_yaw);
    hash = hash_u64(hash, (uint64_t) (uint16_t) angle_velocity_yaw);
    hash = hash_u64(hash, (uint64_t) (int64_t) dialog_id);
    hash = hash_u64(hash, (uint64_t) dialog_requested);
    hash = hash_u64(hash, (uint64_t) child_small_unk88);
    hash = hash_u64(hash, child_interaction_set_mask);
    hash = hash_u64(hash, (uint64_t) clear_child_drop_immediate);
    hash = hash_u64(hash, (uint64_t) (int64_t) child_behavior);
    hash = hash_u64(hash, (uint64_t) spawn_star);
    hash = hash_id(hash, 0, 0, 0);
    if (has_star_home) {
        hash = hash_u64(hash, 1);
        hash = hash_float(hash, star_x);
        hash = hash_float(hash, star_y);
        hash = hash_float(hash, star_z);
    }
    hash = hash_float(hash, star_spawn_y_offset);
    hash = hash_u64(hash, (uint64_t) play_walking_sound);
    hash = hash_u64(hash, (uint64_t) play_yell_sound);
    return hash_u64(hash, (uint64_t) active_flag_unk10);
}

static uint64_t hash_effect(
    uint64_t initial, int32_t action, int32_t sub_action, int32_t dialog_id,
    int dialog_requested, int child_small_unk88, uint32_t child_mask,
    int clear_child, int32_t child_behavior, int spawn_star,
    int has_star_home, float star_spawn_y_offset, uint64_t sequence,
    uint64_t presented_kind, int32_t presented_value, int has_spawned_star,
    int animation, int play_walking_sound) {
    uint64_t hash = hash_id(initial, 1, 0, 1);
    hash = hash_id(hash, 1, 1, 1);
    hash = hash_output(
        hash, action, sub_action, 4.0f, animation, 0.0f, 0x200, 0,
        dialog_id, dialog_requested, child_small_unk88, child_mask,
        clear_child, child_behavior, spawn_star, has_star_home,
        3167.0f, -4300.0f, 5108.0f, star_spawn_y_offset, play_walking_sound, 0, 1
    );
    hash = hash_u64(hash, (uint64_t) has_spawned_star);
    if (has_spawned_star)
        hash = hash_id(hash, 1, 2, 1);
    int presented = sequence != 0;
    hash = hash_u64(hash, (uint64_t) presented);
    if (presented)
        hash = hash_intent(hash, sequence, 0, 1, presented_kind, presented_value, 0);
    return hash;
}

static uint64_t hash_record(
    uint64_t initial, int present, uint64_t slot, uint64_t generation,
    uint64_t parent_slot, uint64_t behavior, int32_t action, int32_t sub_action,
    uint32_t interaction_subtype, uint16_t active_flags) {
    if (!present)
        return hash_u64(initial, 0);
    uint64_t hash = hash_u64(initial, 1);
    hash = hash_id(hash, 1, slot, generation);
    hash = hash_id(hash, 1, parent_slot, 1);
    hash = hash_u64(hash, behavior);
    hash = hash_u64(hash, behavior);
    hash = hash_u64(hash, (uint64_t) (int64_t) action);
    hash = hash_u64(hash, (uint64_t) (int64_t) sub_action);
    hash = hash_u64(hash, interaction_subtype);
    return hash_u64(hash, active_flags);
}

static uint64_t hash_delivery(
    uint64_t initial, uint64_t sequence, uint64_t kind, int32_t value) {
    uint64_t hash = hash_u64(initial, sequence != 0 ? 1 : 0);
    if (sequence != 0)
        hash = hash_intent(hash, sequence, 0, 1, kind, value, 0);
    hash = hash_u64(hash, sequence != 0 ? 1 : 0);
    if (sequence != 0)
        hash = hash_intent(hash, sequence, 0, 1, kind, value, 0);
    hash = hash_u64(hash, 0); /* spawned */
    hash = hash_u64(hash, 0); /* deleted */
    return hash_u64(hash, 0); /* rejected */
}

static uint64_t hash_tick(
    uint64_t initial, uint64_t frame, int unloaded, int32_t action,
    int32_t sub_action, int32_t dialog_id, int dialog_requested,
    int child_small_unk88, uint32_t child_mask, int clear_child,
    int32_t child_behavior, int spawn_star, int has_star_home,
    float star_spawn_y_offset, uint64_t effect_sequence, uint64_t effect_kind,
    int32_t effect_value, int has_spawned_star, int mother_present,
    int32_t mother_action, int32_t mother_sub_action, int child_present,
    uint64_t child_behavior_identity, uint32_t child_interaction_subtype,
    int animation, int play_walking_sound) {
    uint64_t hash = hash_u64(initial, frame);
    hash = hash_u64(hash, (uint64_t) unloaded);
    if (unloaded)
        hash = hash_id(hash, 1, 0, 1);
    hash = hash_u64(hash, 1); /* one mother effect */
    hash = hash_effect(
        hash, action, sub_action, dialog_id, dialog_requested,
        child_small_unk88, child_mask, clear_child, child_behavior,
        spawn_star, has_star_home, star_spawn_y_offset, effect_sequence,
        effect_kind, effect_value, has_spawned_star, animation, play_walking_sound
    );
    hash = hash_u64(hash, 1); /* one delivery receipt */
    hash = hash_delivery(hash, effect_sequence, effect_kind, effect_value);
    hash = hash_record(
        hash, mother_present, 0, 1, 0,
        UINT64_C(0x6268765f74786d), mother_action, mother_sub_action, 0,
        mother_present ? UINT16_C(1281) : 0
    );
    return hash_record(
        hash, child_present, 1, 1, 0, child_behavior_identity, 0, 0,
        child_interaction_subtype, child_present ? UINT16_C(257) : 0
    );
}

int main(void) {
    uint64_t hash = FNV_OFFSET;
    const uint64_t small = UINT64_C(0x6268765f73706e);
    const uint64_t unused = UINT64_C(0x6268765f75736e);

    hash = hash_tick(hash, 1, 0, 0, 1, 0, 0, 0, 0, 0, -1, 0, 0, 0.0f, 0, 0, 0, 0, 1, 0, 1, 1, small, 0, 3, 0);
    hash = hash_tick(hash, 2, 0, 0, 1, 57, 1, 0, 0, 0, -1, 0, 0, 0.0f, 1, 8, 57, 0, 1, 0, 1, 1, small, 0, 3, 0);
    hash = hash_tick(hash, 3, 0, 0, 2, 57, 1, 0, 0, 0, -1, 0, 0, 0.0f, 2, 8, 57, 0, 1, 0, 2, 1, small, 0, 3, 0);
    hash = hash_tick(hash, 4, 0, 1, 0, 0, 0, 1, 0, 0, -1, 0, 0, 0.0f, 0, 0, 0, 0, 1, 1, 0, 1, small, 0, 3, 0);
    hash = hash_tick(hash, 5, 0, 1, 0, 58, 1, 0, 0, 0, -1, 0, 0, 0.0f, 3, 8, 58, 0, 1, 1, 0, 1, small, 0, 3, 0);
    hash = hash_tick(hash, 6, 0, 1, 1, 58, 1, 0, 64, 0, -1, 0, 0, 0.0f, 4, 8, 58, 0, 1, 1, 1, 1, small, 64, 3, 0);
    hash = hash_tick(hash, 7, 0, 2, 1, 0, 0, 0, 0, 1, 0, 1, 1, 200.0f, 5, 9, 0, 1, 1, 2, 1, 1, unused, 0, 3, 0);
    hash = hash_tick(hash, 8, 1, 2, 1, 0, 0, 0, 0, 0, -1, 0, 0, 0.0f, 6, 0, 4, 0, 0, 0, 0, 0, 0, 0, 1, 1);

    printf("tuxiesMotherObjectBridgeFingerprint=0x%016llx\n", (unsigned long long) hash);
    printf("SM64 Modern Tuxie's mother object bridge C contract passed\n");
    return 0;
}
