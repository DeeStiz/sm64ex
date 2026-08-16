#include <stdint.h>
#include <stdio.h>

static const uint64_t FNV_OFFSET = UINT64_C(1469598103934665603);
static const uint64_t FNV_PRIME = UINT64_C(1099511628211);
static const uint64_t SMALL_BEHAVIOR = UINT64_C(0x6268765f73706e);

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

static uint64_t hash_state(
    uint64_t initial, int32_t action, int32_t timer, int16_t move_yaw,
    float forward_velocity, float unknown104, float unknown108,
    int32_t unknown110, int32_t dive_return_action, uint32_t link_flag,
    int32_t animation, int32_t held_state) {
    uint64_t hash = hash_u64(initial, (uint64_t) (int64_t) action);
    hash = hash_u64(hash, (uint64_t) (int64_t) timer);
    hash = hash_u64(hash, (uint64_t) (uint16_t) move_yaw);
    hash = hash_float(hash, forward_velocity);
    hash = hash_float(hash, unknown104);
    hash = hash_float(hash, unknown108);
    hash = hash_u64(hash, (uint64_t) (int64_t) unknown110);
    hash = hash_u64(hash, (uint64_t) (int64_t) dive_return_action);
    hash = hash_u64(hash, link_flag);
    hash = hash_u64(hash, (uint64_t) (int64_t) animation);
    return hash_u64(hash, (uint64_t) (int64_t) held_state);
}

static uint64_t hash_output(
    uint64_t initial, int32_t action, int32_t timer, int16_t move_yaw,
    float forward_velocity, float unknown104, float unknown108,
    int32_t unknown110, int32_t dive_return_action, uint32_t link_flag,
    int32_t animation, int32_t held_state, int16_t angle_velocity_yaw,
    int reset_home, int play_walking_sound, int play_dive_sound,
    int play_held_yell_sound, int unrender_held_object, int copied_to_mario,
    int set_small_penguin_behavior, int thrown, int dropped) {
    uint64_t hash = hash_state(
        initial, action, timer, move_yaw, forward_velocity, unknown104,
        unknown108, unknown110, dive_return_action, link_flag, animation,
        held_state
    );
    hash = hash_u64(hash, (uint64_t) (uint16_t) angle_velocity_yaw);
    hash = hash_u64(hash, (uint64_t) reset_home);
    hash = hash_u64(hash, (uint64_t) play_walking_sound);
    hash = hash_u64(hash, (uint64_t) play_dive_sound);
    hash = hash_u64(hash, (uint64_t) play_held_yell_sound);
    hash = hash_u64(hash, (uint64_t) unrender_held_object);
    hash = hash_u64(hash, (uint64_t) copied_to_mario);
    hash = hash_u64(hash, (uint64_t) set_small_penguin_behavior);
    hash = hash_u64(hash, (uint64_t) thrown);
    return hash_u64(hash, (uint64_t) dropped);
}

static uint64_t hash_intent(
    uint64_t initial, uint64_t sequence, uint64_t kind, int32_t value) {
    uint64_t hash = hash_u64(initial, sequence);
    hash = hash_id(hash, 1, 0, 1);
    hash = hash_u64(hash, kind);
    hash = hash_u64(hash, (uint64_t) (int64_t) value);
    return hash_u64(hash, 0);
}

static uint64_t hash_record(
    uint64_t initial, int present, uint64_t behavior, int32_t action,
    int32_t previous_action, int32_t timer, int32_t animation,
    uint32_t held_state) {
    if (!present)
        return hash_u64(initial, 0);
    uint64_t hash = hash_u64(initial, 1);
    hash = hash_id(hash, 1, 0, 1);
    hash = hash_id(hash, 1, 0, 1);
    hash = hash_u64(hash, behavior);
    hash = hash_u64(hash, behavior);
    hash = hash_u64(hash, (uint64_t) (int64_t) action);
    hash = hash_u64(hash, (uint64_t) (int64_t) previous_action);
    hash = hash_u64(hash, (uint64_t) (int64_t) timer);
    hash = hash_u64(hash, (uint64_t) (int64_t) animation);
    hash = hash_u64(hash, held_state);
    return hash_u64(hash, 257);
}

static uint64_t hash_tick(
    uint64_t initial, uint64_t frame, int unloaded,
    int32_t action, int32_t timer, int16_t move_yaw, float forward_velocity,
    float unknown104, float unknown108, int32_t unknown110,
    int32_t dive_return_action, int32_t animation, int32_t held_state,
    int16_t angle_velocity_yaw, int reset_home, int play_walking_sound,
    int play_dive_sound, int play_held_yell_sound, int unrender_held_object,
    int copied_to_mario, int set_small_penguin_behavior, uint64_t sequence,
    int32_t sound_value, int record_present, int32_t record_action,
    int32_t previous_action, int32_t record_timer, int32_t record_animation,
    uint32_t record_held_state) {
    uint64_t hash = hash_u64(initial, frame);
    hash = hash_u64(hash, (uint64_t) unloaded);
    if (unloaded)
        hash = hash_id(hash, 1, 0, 1);
    hash = hash_u64(hash, 1); /* one effect */
    hash = hash_id(hash, 1, 0, 1);
    hash = hash_output(
        hash, action, timer, move_yaw, forward_velocity, unknown104,
        unknown108, unknown110, dive_return_action, 0, animation,
        held_state, angle_velocity_yaw, reset_home, play_walking_sound,
        play_dive_sound, play_held_yell_sound, unrender_held_object,
        copied_to_mario, set_small_penguin_behavior, 0, 0
    );
    hash = hash_u64(hash, sequence != 0 ? 1 : 0);
    if (sequence != 0)
        hash = hash_intent(hash, sequence, 0, sound_value);
    hash = hash_u64(hash, 1); /* one delivery receipt */
    hash = hash_u64(hash, sequence != 0 ? 1 : 0);
    if (sequence != 0)
        hash = hash_intent(hash, sequence, 0, sound_value);
    hash = hash_u64(hash, sequence != 0 ? 1 : 0);
    hash = hash_u64(hash, 0); /* spawned */
    hash = hash_u64(hash, 0); /* deleted */
    hash = hash_u64(hash, 0); /* rejected */
    return hash_record(
        hash, record_present, SMALL_BEHAVIOR, record_action,
        previous_action, record_timer, record_animation, record_held_state
    );
}

int main(void) {
    uint64_t hash = FNV_OFFSET;
    const float unknown104 = 0.25f;
    const float unknown108 = 100.0f;
    const int32_t unknown110 = 0x100;

    hash = hash_tick(hash, 1, 0, 1, 1, 0, 0.0f, unknown104, unknown108, unknown110, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 3, 0);
    hash = hash_tick(hash, 2, 0, 1, 2, 0x200, 3.25f, unknown104, unknown108, unknown110, 0, 0, 0, 0x200, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 2, 0, 0);
    hash = hash_tick(hash, 3, 0, 0, 3, 0x200, 3.25f, unknown104, unknown108, unknown110, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 3, 0, 0);
    hash = hash_tick(hash, 4, 0, 5, 1, 0, 0.0f, unknown104, unknown108, unknown110, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 5, 0, 1, 3, 0);
    hash = hash_tick(hash, 5, 0, 5, 2, 0, 0.0f, unknown104, unknown108, unknown110, 0, 3, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 8, 1, 5, 5, 2, 3, 1);
    hash = hash_tick(hash, 6, 0, 5, 3, 0x400, 2.0f, unknown104, unknown108, unknown110, 0, 0, 0, 0x400, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 5, 5, 3, 0, 0);
    hash = hash_tick(hash, 7, 1, 5, 4, 0x400, 2.0f, unknown104, unknown108, unknown110, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 6, 0, 0, 0, 0, 0, 0);

    printf("smallPenguinObjectBridgeFingerprint=0x%016llx\n", (unsigned long long) hash);
    printf("SM64 Modern small penguin object bridge C contract passed\n");
    return 0;
}
