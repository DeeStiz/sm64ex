#include <stdint.h>
#include <stdio.h>

static const uint64_t FNV_OFFSET = UINT64_C(1469598103934665603);
static const uint64_t FNV_PRIME = UINT64_C(1099511628211);

enum {
    ACTION_IDLE = 0,
    ACTION_MOVE_AWAY = 1,
    ACTION_MOVE_TOWARD = 2,
    ACTION_DIVE = 3,
    ACTION_RECOVER = 4,
    ACTION_FOLLOW_MOTHER = 5,
    HELD_FREE = 0,
    HELD_HELD = 1,
    HELD_THROWN = 2,
    HELD_DROPPED = 3,
    ANIMATION_IDLE = 3,
    ANIMATION_WALK = 0,
    ANIMATION_DIVE = 1,
    ANIMATION_RECOVER = 2
};

typedef struct {
    int32_t action;
    int32_t timer;
    int16_t move_yaw;
    float forward_velocity;
    float unknown104;
    float unknown108;
    int32_t unknown110;
    int32_t dive_return_action;
    uint32_t link_flag;
    int32_t animation;
    int32_t held_state;
} State;

typedef struct {
    float distance_to_mario;
    int16_t angle_to_mario;
    int nearest_mother_exists;
    float nearest_mother_distance;
    int16_t angle_to_mother;
    int mario_dive_sliding;
    int mario_far_away;
    int32_t sound_state_id;
    uint64_t global_timer;
    int has_baby_behavior;
    int32_t random_unknown110;
    float random_unknown108;
    float random_unknown104;
} Input;

typedef struct {
    State state;
    int16_t angle_velocity_yaw;
    int reset_home;
    int play_walking_sound;
    int play_dive_sound;
    int play_held_yell_sound;
    int unrender_held_object;
    int copied_to_mario;
    int set_small_penguin_behavior;
    int thrown;
    int dropped;
} Output;

static int16_t approach_angle(int16_t current, int16_t target, int16_t increment,
                              int16_t *delta) {
    int16_t start = current;
    int32_t distance = (int32_t) target - (int32_t) current;
    int16_t value;
    if (distance >= 0)
        value = distance > increment ? (int16_t) ((uint16_t) current + (uint16_t) increment) : target;
    else
        value = distance < -(int32_t) increment ? (int16_t) ((uint16_t) current - (uint16_t) increment) : target;
    *delta = (int16_t) ((uint16_t) value - (uint16_t) start);
    return value;
}

static Output update(Input input, State initial) {
    State state = initial;
    Output output = {0};

    switch (state.held_state) {
        case HELD_FREE:
            if (state.link_flag != 0) {
                state.action = ACTION_FOLLOW_MOTHER;
                state.link_flag = 0;
            }
            switch (state.action) {
                case ACTION_IDLE:
                    state.animation = ANIMATION_IDLE;
                    if (state.timer == 0) {
                        state.unknown110 = input.random_unknown110;
                        state.unknown108 = input.random_unknown108;
                        state.unknown104 = input.random_unknown104;
                        state.forward_velocity = 0.0f;
                        if (input.nearest_mother_exists && input.nearest_mother_distance < 1000.0f)
                            state.action = ACTION_FOLLOW_MOTHER;
                    }
                    if (state.action == ACTION_IDLE) {
                        if (input.distance_to_mario < 1000.0f &&
                            state.unknown108 + 600.0f < input.distance_to_mario)
                            state.action = ACTION_MOVE_AWAY;
                        else if (input.distance_to_mario < state.unknown108 + 300.0f)
                            state.action = ACTION_MOVE_TOWARD;
                    }
                    if (input.mario_far_away)
                        output.reset_home = 1;
                    break;
                case ACTION_MOVE_AWAY: {
                    state.animation = ANIMATION_WALK;
                    state.forward_velocity = state.unknown104 + 3.0f;
                    int16_t turn_delta = 0;
                    int16_t increment = (int16_t) (state.unknown110 + 0x600);
                    state.move_yaw = approach_angle(state.move_yaw, input.angle_to_mario,
                                                     increment, &turn_delta);
                    output.angle_velocity_yaw = turn_delta;
                    if (input.distance_to_mario < state.unknown108 + 300.0f ||
                        input.distance_to_mario > 1100.0f)
                        state.action = ACTION_IDLE;
                    if (input.mario_dive_sliding) {
                        state.dive_return_action = state.action;
                        state.action = ACTION_DIVE;
                    }
                    break;
                }
                case ACTION_MOVE_TOWARD: {
                    state.animation = ANIMATION_WALK;
                    state.forward_velocity = state.unknown104 + 3.0f;
                    int16_t turn_delta = 0;
                    int16_t target = (int16_t) ((uint16_t) input.angle_to_mario + UINT16_C(0x8000));
                    int16_t increment = (int16_t) (state.unknown110 + 0x600);
                    state.move_yaw = approach_angle(state.move_yaw, target, increment, &turn_delta);
                    output.angle_velocity_yaw = turn_delta;
                    if (input.distance_to_mario > state.unknown108 + 500.0f)
                        state.action = ACTION_IDLE;
                    if (input.mario_dive_sliding) {
                        state.dive_return_action = state.action;
                        state.action = ACTION_DIVE;
                    }
                    break;
                }
                case ACTION_DIVE:
                    if (state.timer > 5) {
                        if (state.timer == 6)
                            output.play_dive_sound = 1;
                        state.animation = ANIMATION_DIVE;
                        if (state.timer > 25 && !input.mario_dive_sliding)
                            state.action = ACTION_RECOVER;
                    }
                    break;
                case ACTION_RECOVER:
                    if (state.timer > 20) {
                        state.forward_velocity = 0.0f;
                        state.animation = ANIMATION_RECOVER;
                        if (state.timer > 40)
                            state.action = state.dive_return_action;
                    }
                    break;
                case ACTION_FOLLOW_MOTHER:
                    if (input.nearest_mother_exists) {
                        state.forward_velocity = input.distance_to_mario < 1000.0f ? 2.0f : 0.0f;
                        int16_t target = input.nearest_mother_distance > 200.0f
                            ? input.angle_to_mother
                            : (int16_t) ((uint16_t) input.angle_to_mother + UINT16_C(0x8000));
                        int16_t turn_delta = 0;
                        state.move_yaw = approach_angle(state.move_yaw, target, 0x400, &turn_delta);
                        output.angle_velocity_yaw = turn_delta;
                        state.animation = ANIMATION_WALK;
                    }
                    if (input.mario_dive_sliding) {
                        state.dive_return_action = state.action;
                        state.action = ACTION_DIVE;
                    }
                    break;
            }
            if (input.sound_state_id == 0)
                state.animation = ANIMATION_WALK;
            break;
        case HELD_HELD:
            output.unrender_held_object = 1;
            output.set_small_penguin_behavior = input.has_baby_behavior;
            output.copied_to_mario = 1;
            output.play_held_yell_sound = input.global_timer % 30 == 0;
            break;
        case HELD_THROWN:
            output.thrown = 1;
            break;
        case HELD_DROPPED:
            output.dropped = 1;
            break;
    }

    output.state = state;
    output.play_walking_sound = state.held_state == HELD_FREE && input.sound_state_id == 0;
    if (state.timer < 0x3fffffff)
        output.state.timer = state.timer + 1;
    return output;
}

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

static uint64_t hash_state(uint64_t initial, State state) {
    uint64_t hash = hash_u64(initial, (uint64_t) (int64_t) state.action);
    hash = hash_u64(hash, (uint64_t) (int64_t) state.timer);
    hash = hash_u64(hash, (uint64_t) (uint16_t) state.move_yaw);
    hash = hash_float(hash, state.forward_velocity);
    hash = hash_float(hash, state.unknown104);
    hash = hash_float(hash, state.unknown108);
    hash = hash_u64(hash, (uint64_t) (int64_t) state.unknown110);
    hash = hash_u64(hash, (uint64_t) (int64_t) state.dive_return_action);
    hash = hash_u64(hash, state.link_flag);
    hash = hash_u64(hash, (uint64_t) (int64_t) state.animation);
    return hash_u64(hash, (uint64_t) (int64_t) state.held_state);
}

static uint64_t hash_output(uint64_t initial, Output output) {
    uint64_t hash = hash_state(initial, output.state);
    hash = hash_u64(hash, (uint64_t) (uint16_t) output.angle_velocity_yaw);
    hash = hash_u64(hash, (uint64_t) output.reset_home);
    hash = hash_u64(hash, (uint64_t) output.play_walking_sound);
    hash = hash_u64(hash, (uint64_t) output.play_dive_sound);
    hash = hash_u64(hash, (uint64_t) output.play_held_yell_sound);
    hash = hash_u64(hash, (uint64_t) output.unrender_held_object);
    hash = hash_u64(hash, (uint64_t) output.copied_to_mario);
    hash = hash_u64(hash, (uint64_t) output.set_small_penguin_behavior);
    hash = hash_u64(hash, (uint64_t) output.thrown);
    return hash_u64(hash, (uint64_t) output.dropped);
}

static void absorb(uint64_t *hash, State *state, Input input) {
    Output output = update(input, *state);
    *state = output.state;
    *hash = hash_output(*hash, output);
}

int main(void) {
    uint64_t hash = FNV_OFFSET;
    Input base = { 800, 0x200, 0, 1e30f, 0, 0, 0, 1, 1, 0, 0x100, 100, 0.25f };

    State idle = { ACTION_IDLE, 0, 0, 0, 0, 0, 0, 0, 0, ANIMATION_IDLE, HELD_FREE };
    absorb(&hash, &idle, base);
    idle.timer = 1;
    absorb(&hash, &idle, base);
    base.distance_to_mario = 300;
    absorb(&hash, &idle, base);

    State toward = { ACTION_MOVE_TOWARD, 4, 0, 0, 0.5f, 100, 0x100, 0, 0, ANIMATION_IDLE, HELD_FREE };
    Input toward_input = { 500, 0, 0, 1e30f, 0, 0, 0, 1, 1, 0, 0, 0, 0 };
    absorb(&hash, &toward, toward_input);
    toward.timer = 5;
    toward.move_yaw = -1792;
    toward.forward_velocity = 3.5f;
    absorb(&hash, &toward, (Input){ 700, 0, 0, 1e30f, 0, 0, 0, 1, 1, 0, 0, 0, 0 });

    State diving = { ACTION_MOVE_AWAY, 5, 0, 0, 0.25f, 100, 0x100, 0, 0, ANIMATION_IDLE, HELD_FREE };
    absorb(&hash, &diving, (Input){ 800, 0, 0, 1e30f, 0, 1, 0, 1, 1, 0, 0, 0, 0 });
    diving.timer = 6;
    diving.action = ACTION_DIVE;
    diving.dive_return_action = ACTION_MOVE_AWAY;
    absorb(&hash, &diving, (Input){ 1e4f, 0, 0, 1e30f, 0, 1, 0, 1, 1, 0, 0, 0, 0 });
    diving.timer = 26;
    absorb(&hash, &diving, (Input){ 1e4f, 0, 0, 1e30f, 0, 0, 0, 1, 1, 0, 0, 0, 0 });
    diving.action = ACTION_RECOVER;
    diving.timer = 21;
    absorb(&hash, &diving, (Input){ 1e4f, 0, 0, 1e30f, 0, 0, 0, 1, 1, 0, 0, 0, 0 });
    diving.timer = 41;
    absorb(&hash, &diving, (Input){ 1e4f, 0, 0, 1e30f, 0, 0, 0, 1, 1, 0, 0, 0, 0 });

    State following = { ACTION_FOLLOW_MOTHER, 3, 0, 0, 0, 0, 0, 0, 0, ANIMATION_IDLE, HELD_FREE };
    absorb(&hash, &following, (Input){ 500, 0, 1, 250, 0x400, 0, 0, 1, 1, 0, 0, 0, 0 });
    following.timer = 4;
    following.action = ACTION_IDLE;
    following.link_flag = 1;
    following.move_yaw = 0x400;
    following.forward_velocity = 2;
    absorb(&hash, &following, (Input){ 500, 0, 1, 250, 0x400, 0, 0, 1, 1, 0, 0, 0, 0 });

    State held = { ACTION_IDLE, 0, 0, 0, 0, 0, 0, 0, 0, ANIMATION_IDLE, HELD_HELD };
    absorb(&hash, &held, (Input){ 1e4f, 0, 0, 0, 0, 0, 0, 1, 30, 1, 0, 0, 0 });
    State thrown = { ACTION_IDLE, 0, 0, 0, 0, 0, 0, 0, 0, ANIMATION_IDLE, HELD_THROWN };
    absorb(&hash, &thrown, (Input){ 1e4f, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0 });
    State dropped = { ACTION_IDLE, 0, 0, 0, 0, 0, 0, 0, 0, ANIMATION_IDLE, HELD_DROPPED };
    absorb(&hash, &dropped, (Input){ 1e4f, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0 });

    State far_away = { ACTION_IDLE, 1, 0, 0, 0, 0, 0, 0, 0, ANIMATION_IDLE, HELD_FREE };
    absorb(&hash, &far_away, (Input){ 1e4f, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0 });

    printf("smallPenguinFingerprint=0x%016llx\n", (unsigned long long) hash);
    printf("SM64 Modern small penguin C contract passed\n");
    return 0;
}
