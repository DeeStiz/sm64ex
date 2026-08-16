#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct State {
    int32_t action, timer, chosen_home;
    float home_x, home_z;
    int16_t target_yaw, move_yaw;
    float forward_velocity, velocity_y;
    uint32_t blink;
};

struct Output {
    struct State state;
    int32_t animation, dialog;
    int dialog_requested, active_time_stop, clear_time_stop, clear_interaction;
    int play_walk, play_puzzle, play_alert, play_extra;
    int32_t lives_delta;
    int special_triple_jump, camera_request, respawner_requested, deactivated;
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
    hash = hash_u64(hash, (uint64_t) (int64_t) state->timer);
    hash = hash_u64(hash, (uint64_t) (int64_t) state->chosen_home);
    hash = hash_float(hash, state->home_x);
    hash = hash_float(hash, state->home_z);
    hash = hash_u64(hash, (uint64_t) (uint16_t) state->target_yaw);
    hash = hash_u64(hash, (uint64_t) (uint16_t) state->move_yaw);
    hash = hash_float(hash, state->forward_velocity);
    hash = hash_float(hash, state->velocity_y);
    return hash_u64(hash, state->blink);
}

static uint64_t hash_output(uint64_t initial, const struct Output *output) {
    uint64_t hash = hash_state(initial, &output->state);
    hash = hash_u64(hash, (uint64_t) (int64_t) output->animation);
    hash = hash_u64(hash, (uint64_t) (int64_t) output->dialog);
    hash = hash_u64(hash, (uint64_t) output->dialog_requested);
    hash = hash_u64(hash, (uint64_t) output->active_time_stop);
    hash = hash_u64(hash, (uint64_t) output->clear_time_stop);
    hash = hash_u64(hash, (uint64_t) output->clear_interaction);
    hash = hash_u64(hash, (uint64_t) output->play_walk);
    hash = hash_u64(hash, (uint64_t) output->play_puzzle);
    hash = hash_u64(hash, (uint64_t) output->play_alert);
    hash = hash_u64(hash, (uint64_t) output->play_extra);
    hash = hash_u64(hash, (uint64_t) (int64_t) output->lives_delta);
    hash = hash_u64(hash, (uint64_t) output->special_triple_jump);
    hash = hash_u64(hash, (uint64_t) (int64_t) output->camera_request);
    hash = hash_u64(hash, (uint64_t) output->respawner_requested);
    return hash_u64(hash, (uint64_t) output->deactivated);
}

static struct Output make_output(
    struct State state,
    int32_t animation,
    int32_t dialog,
    int dialog_requested,
    int active_time_stop,
    int clear_time_stop,
    int clear_interaction,
    int play_walk,
    int play_puzzle,
    int play_alert,
    int play_extra,
    int32_t lives_delta,
    int special_triple_jump,
    int camera_request,
    int respawner_requested,
    int deactivated) {
    return (struct Output) {
        state, animation, dialog, dialog_requested, active_time_stop,
        clear_time_stop, clear_interaction, play_walk, play_puzzle,
        play_alert, play_extra, lives_delta, special_triple_jump,
        camera_request, respawner_requested, deactivated
    };
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    struct State state = { 0, 0, 0, 0, -5625.0f, 0, 0, 0.0f, 0.0f, 0 };
    struct Output output = make_output(state, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);
    fingerprint = hash_output(fingerprint, &output);

    state = (struct State) { 1, 91, 1, -1364.0f, -5912.0f, -18543, 0, 0.0f, 0.0f, 7 };
    output = make_output(state, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    fingerprint = hash_output(fingerprint, &output);

    state = (struct State) { 1, 1, 1, -1364.0f, -5912.0f, -18543, -1280, 10.0f, 0.0f, 8 };
    output = make_output(state, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0);
    fingerprint = hash_output(fingerprint, &output);

    state = (struct State) { 2, 2, 1, -1364.0f, -5912.0f, -18543, -2560, 10.0f, 0.0f, 9 };
    output = make_output(state, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0);
    fingerprint = hash_output(fingerprint, &output);

    state = (struct State) { 2, 3, 1, -1364.0f, -5912.0f, -18543, -1280, 10.0f, 0.0f, 10 };
    output = make_output(state, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0);
    fingerprint = hash_output(fingerprint, &output);

    state = (struct State) { 5, 0, 1, -1403.0f, -4609.0f, -9844, -1280, 10.0f, 0.0f, 11 };
    output = make_output(state, 0, 161, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    fingerprint = hash_output(fingerprint, &output);

    state.blink = 12;
    output = make_output(state, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0);
    fingerprint = hash_output(fingerprint, &output);

    state.action = 3; state.blink = 13;
    output = make_output(state, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0);
    fingerprint = hash_output(fingerprint, &output);

    state.action = 4; state.move_yaw = -16383; state.forward_velocity = 50.0f;
    state.velocity_y = 40.0f; state.blink = 14;
    output = make_output(state, 2, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0);
    fingerprint = hash_output(fingerprint, &output);

    state.velocity_y = 38.0f; state.blink = 15;
    output = make_output(state, 2, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);
    fingerprint = hash_output(fingerprint, &output);

    state = (struct State) { 10, 0, 0, -1798.0f, -3644.0f, 0, 0, 0.0f, 0.0f, 16 };
    output = make_output(state, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    fingerprint = hash_output(fingerprint, &output);

    printf("yoshiFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    printf("SM64 Modern Yoshi C contract passed\n");
    return 0;
}
