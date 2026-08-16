#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct State {
    int32_t action, sub_action, health, animation_phase, grab_turn_timer;
    int32_t grab_escape_count, release_cooldown, interaction_mode;
    int16_t move_yaw;
    float forward_velocity, velocity_y, gravity, home_y, position_y;
    uint32_t timer;
    int tangible, hidden, holdable, using_home_movement, interaction_grab_cleared;
};

struct Output {
    struct State state;
    int32_t animation, dialog;
    int dialog_requested;
    uint32_t effects;
    int32_t sounds[2];
    size_t sound_count;
    int32_t sound_spawners[1];
    size_t sound_spawner_count;
    int32_t camera_shake;
    int star_present;
    float star_x, star_y, star_z;
};

static uint64_t hash_u64(uint64_t initial, uint64_t value) {
    uint64_t hash = initial;
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_float(uint64_t initial, float value) {
    union { float f; uint32_t u; } bits = { value };
    return hash_u64(initial, bits.u);
}

static uint64_t hash_state(uint64_t initial, const struct State *state) {
    uint64_t hash = hash_u64(initial, (uint64_t) (int64_t) state->action);
    hash = hash_u64(hash, (uint64_t) (int64_t) state->sub_action);
    hash = hash_u64(hash, (uint64_t) (int64_t) state->health);
    hash = hash_u64(hash, (uint64_t) (int64_t) state->animation_phase);
    hash = hash_u64(hash, (uint64_t) (int64_t) state->grab_turn_timer);
    hash = hash_u64(hash, (uint64_t) (int64_t) state->grab_escape_count);
    hash = hash_u64(hash, (uint64_t) (int64_t) state->release_cooldown);
    hash = hash_u64(hash, (uint64_t) (int64_t) state->interaction_mode);
    hash = hash_u64(hash, (uint64_t) (uint16_t) state->move_yaw);
    hash = hash_float(hash, state->forward_velocity);
    hash = hash_float(hash, state->velocity_y);
    hash = hash_float(hash, state->gravity);
    hash = hash_float(hash, state->home_y);
    hash = hash_float(hash, state->position_y);
    hash = hash_u64(hash, state->timer);
    hash = hash_u64(hash, (uint64_t) state->tangible);
    hash = hash_u64(hash, (uint64_t) state->hidden);
    hash = hash_u64(hash, (uint64_t) state->holdable);
    hash = hash_u64(hash, (uint64_t) state->using_home_movement);
    return hash_u64(hash, (uint64_t) state->interaction_grab_cleared);
}

static uint64_t hash_output(uint64_t initial, const struct Output *output) {
    uint64_t hash = hash_state(initial, &output->state);
    hash = hash_u64(hash, (uint64_t) (int64_t) output->animation);
    hash = hash_u64(hash, (uint64_t) (int64_t) output->dialog);
    hash = hash_u64(hash, (uint64_t) output->dialog_requested);
    hash = hash_u64(hash, output->effects);
    hash = hash_u64(hash, output->sound_count);
    for (size_t index = 0; index < output->sound_count; ++index)
        hash = hash_u64(hash, (uint64_t) (int64_t) output->sounds[index]);
    hash = hash_u64(hash, output->sound_spawner_count);
    for (size_t index = 0; index < output->sound_spawner_count; ++index)
        hash = hash_u64(hash, (uint64_t) (int64_t) output->sound_spawners[index]);
    hash = hash_u64(hash, (uint64_t) (int64_t) output->camera_shake);
    hash = hash_u64(hash, (uint64_t) output->star_present);
    if (output->star_present) {
        hash = hash_float(hash, output->star_x);
        hash = hash_float(hash, output->star_y);
        hash = hash_float(hash, output->star_z);
    }
    return hash;
}

static struct State state_default(void) {
    return (struct State) {
        0, 0, 3, 0, 0, 0, 0, 2, 0,
        0.0f, 0.0f, -4.0f, 0.0f, 0.0f, 0,
        1, 0, 0, 0, 0
    };
}

static struct Output output(
    struct State state, int32_t animation, int32_t dialog,
    uint32_t effects, const int32_t *sounds, size_t sound_count,
    const int32_t *spawners, size_t spawner_count, int32_t camera_shake,
    int star_present, float star_x, float star_y, float star_z) {
    struct Output value = {
        state, animation, dialog, dialog != 0, effects,
        { 0, 0 }, sound_count, { 0 }, spawner_count, camera_shake,
        star_present, star_x, star_y, star_z
    };
    for (size_t index = 0; index < sound_count; ++index) value.sounds[index] = sounds[index];
    for (size_t index = 0; index < spawner_count; ++index) value.sound_spawners[index] = spawners[index];
    return value;
}

int main(void) {
    const int32_t king_sound = (int32_t) UINT32_C(0x50168081);
    const int32_t damage_sound = (int32_t) UINT32_C(0x91424081);
    const int32_t death_sound = (int32_t) UINT32_C(0x5147C081);
    uint64_t fingerprint = FNV_OFFSET;

    struct State state = state_default();
    state.tangible = 0; state.sub_action = 1; state.timer = 1;
    struct Output value = output(state, 5, 0, 66055, NULL, 0, NULL, 0, 0, 0, 0, 0, 0);
    fingerprint = hash_output(fingerprint, &value);

    state = state_default();
    state.action = 2; state.sub_action = 1; state.timer = 2;
    state.tangible = 1; state.holdable = 1;
    value = output(state, 5, 17, 69123, NULL, 0, NULL, 0, 0, 0, 0, 0, 0);
    fingerprint = hash_output(fingerprint, &value);

    state = state_default();
    state.action = 2; state.animation_phase = 1; state.timer = 1;
    state.tangible = 1;
    value = output(state, 4, 0, 66576, NULL, 0, NULL, 0, 1, 0, 0, 0, 0);
    fingerprint = hash_output(fingerprint, &value);

    state = state_default();
    state.action = 2; state.animation_phase = 2; state.timer = 2;
    state.tangible = 1; state.move_yaw = 256; state.forward_velocity = 3.0f;
    value = output(state, 11, 0, 66560, NULL, 0, NULL, 0, 0, 0, 0, 0, 0);
    fingerprint = hash_output(fingerprint, &value);

    state = state_default();
    state.action = 2; state.timer = 1; state.tangible = 1;
    state.action = 2; state.sub_action = 1; state.grab_escape_count = 11;
    state.release_cooldown = 35; state.interaction_grab_cleared = 1;
    { const int32_t no_sounds[1] = { 0 };
      value = output(state, 1, 0, 69632, no_sounds, 0, NULL, 0, 0, 0, 0, 0, 0); }
    fingerprint = hash_output(fingerprint, &value);

    state = state_default();
    state.action = 6; state.health = 2; state.timer = 1;
    { const int32_t sounds[1] = { king_sound };
      value = output(state, 0, 0, 65536, sounds, 1, NULL, 0, 0, 0, 0, 0, 0); }
    fingerprint = hash_output(fingerprint, &value);

    state = state_default();
    state.action = 6; state.sub_action = 1; state.health = 3;
    state.grab_turn_timer = 4; state.interaction_mode = 8; state.timer = 1;
    { const int32_t sounds[2] = { king_sound, damage_sound };
      value = output(state, 2, 0, 66608, sounds, 2, NULL, 0, 1, 0, 0, 0, 0); }
    fingerprint = hash_output(fingerprint, &value);

    state = state_default();
    state.action = 6; state.sub_action = 2; state.grab_turn_timer = 4; state.interaction_mode = 2;
    state.tangible = 0; state.timer = 2;
    value = output(state, 10, 0, 66048, NULL, 0, NULL, 0, 0, 0, 0, 0, 0);
    fingerprint = hash_output(fingerprint, &value);

    state = state_default();
    state.action = 2; state.sub_action = 2; state.grab_turn_timer = 4;
    state.interaction_mode = 2; state.tangible = 0; state.timer = 3;
    value = output(state, 11, 0, 65536, NULL, 0, NULL, 0, 0, 0, 0, 0, 0);
    fingerprint = hash_output(fingerprint, &value);

    state = state_default();
    state.action = 8; state.hidden = 1; state.tangible = 0;
    state.position_y = 100; state.timer = 1;
    { const int32_t spawners[1] = { death_sound };
      value = output(state, 2, 0, 99312, NULL, 0, spawners, 1, 0, 1, 2000.0f, 4500.0f, -4500.0f); }
    fingerprint = hash_output(fingerprint, &value);

    state = state_default();
    state.action = 8; state.hidden = 1; state.tangible = 0;
    state.position_y = 100; state.timer = 61;
    value = output(state, 0, 0, 66056, NULL, 0, NULL, 0, 0, 0, 0, 0, 0);
    fingerprint = hash_output(fingerprint, &value);

    state = state_default();
    state.action = 2; state.tangible = 0; state.hidden = 1; state.timer = 1;
    value = output(state, 0, 0, 139264, NULL, 0, NULL, 0, 0, 0, 0, 0, 0);
    fingerprint = hash_output(fingerprint, &value);

    state = state_default();
    state.action = 4; state.tangible = 0; state.position_y = 20; state.timer = 1;
    value = output(state, 0, 0, 16384, NULL, 0, NULL, 0, 0, 0, 0, 0, 0);
    fingerprint = hash_output(fingerprint, &value);

    printf("kingBobombFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    printf("SM64 Modern King Bob-omb C contract passed\n");
    return 0;
}
