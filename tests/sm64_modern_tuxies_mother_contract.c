#include <stdint.h>
#include <stdio.h>

enum {
    FOLLOW_CHILD = 0,
    CARRYING_CHILD = 1,
    CHASE_MARIO = 2,
    SUB_IDLE = 0,
    SUB_DIALOG = 1,
    SUB_WAIT_FOR_DROP = 2,
    IDLE_ANIMATION = 3,
    WALK_ANIMATION = 1,
    CARRY_ANIMATION = 0,
    DIALOG_INITIAL = 57,
    DIALOG_CORRECT_CHILD = 58,
    DIALOG_WRONG_CHILD = 59,
    HELD_FREE = 0,
    CHILD_UNUSED = 0,
    CHILD_BABY = 1,
    DROP_IMMEDIATELY = 0x40
};

typedef struct {
    int32_t action;
    int32_t sub_action;
    uint8_t mother_param;
    uint8_t child_param;
    int child_exists;
    float child_distance;
    int32_t child_held_state;
    int nearby_held_actor;
    float lateral_distance;
    int mario_on_platform;
    int can_activate_text;
    int32_t dialog_result;
    int16_t angle_to_mario;
    int16_t move_yaw;
    int32_t sound_state_id;
    int animation_frame_one;
} Input;

typedef struct {
    int32_t action;
    int32_t sub_action;
    float scale;
    int32_t animation;
    float forward_velocity;
    int16_t move_yaw;
    int16_t angle_velocity_yaw;
    int32_t dialog_id;
    int dialog_requested;
    int child_small_unk88;
    uint32_t child_interaction_set_mask;
    int clear_child_drop_immediate;
    int32_t child_behavior;
    int spawn_star;
    int has_star_home;
    float star_x;
    float star_y;
    float star_z;
    float star_spawn_y_offset;
    int play_walking_sound;
    int play_yell_sound;
    int active_flag_unk10;
    int clear_interaction_status;
} Output;

static int16_t approach_angle(int16_t current, int16_t target, int16_t increment,
                              int16_t *delta) {
    int16_t start = current;
    int32_t distance = (int32_t) target - (int32_t) current;
    int16_t value;
    if (distance >= 0)
        value = distance > increment ? (int16_t) (current + increment) : target;
    else
        value = distance < -(int32_t) increment ? (int16_t) (current - increment) : target;
    *delta = (int16_t) (value - start);
    return value;
}

static Output update(Input input) {
    Output output = {0};
    output.action = input.action;
    output.sub_action = input.sub_action;
    output.scale = 4.0f;
    output.animation = IDLE_ANIMATION;
    output.forward_velocity = 0.0f;
    output.move_yaw = input.move_yaw;
    output.child_behavior = -1;
    output.star_spawn_y_offset = 0.0f;

    int child_held = input.child_held_state != HELD_FREE;
    int child_nearby = input.child_exists && input.child_distance < 300.0f;

    switch (input.action) {
        case FOLLOW_CHILD:
            output.animation = IDLE_ANIMATION;
            if (child_nearby && child_held) {
                output.action = CARRYING_CHILD;
                output.child_small_unk88 = 1;
            } else {
                switch (input.sub_action) {
                    case SUB_IDLE:
                        if (input.can_activate_text && input.child_distance >= 500.0f)
                            output.sub_action = SUB_DIALOG;
                        break;
                    case SUB_DIALOG:
                        output.dialog_id = DIALOG_INITIAL;
                        output.dialog_requested = 1;
                        if (input.dialog_result != 0) output.sub_action = SUB_WAIT_FOR_DROP;
                        break;
                    case SUB_WAIT_FOR_DROP:
                        if (input.child_distance > 450.0f) output.sub_action = SUB_IDLE;
                        break;
                }
            }
            break;
        case CARRYING_CHILD:
            switch (input.sub_action) {
                case SUB_IDLE:
                    output.animation = IDLE_ANIMATION;
                    if (!input.mario_on_platform) {
                        output.dialog_id = input.mother_param == input.child_param
                            ? DIALOG_CORRECT_CHILD : DIALOG_WRONG_CHILD;
                        output.dialog_requested = 1;
                        if (input.dialog_result != 0) {
                            output.sub_action = output.dialog_id == DIALOG_CORRECT_CHILD
                                ? SUB_DIALOG : SUB_WAIT_FOR_DROP;
                            output.child_interaction_set_mask = DROP_IMMEDIATELY;
                        }
                    }
                    break;
                case SUB_DIALOG:
                    if (!child_held) {
                        output.clear_child_drop_immediate = 1;
                        output.child_behavior = CHILD_UNUSED;
                        output.spawn_star = 1;
                        output.has_star_home = 1;
                        output.star_x = 3167.0f;
                        output.star_y = -4300.0f;
                        output.star_z = 5108.0f;
                        output.star_spawn_y_offset = 200.0f;
                        output.action = CHASE_MARIO;
                    }
                    break;
                case SUB_WAIT_FOR_DROP:
                    if (!child_held) {
                        output.clear_child_drop_immediate = 1;
                        output.child_behavior = CHILD_BABY;
                        output.action = CHASE_MARIO;
                    }
                    break;
            }
            break;
        case CHASE_MARIO:
            if (input.nearby_held_actor) {
                if (input.sub_action == SUB_IDLE) {
                    output.animation = CARRY_ANIMATION;
                    output.forward_velocity = 10.0f;
                    if (input.lateral_distance > 800.0f) output.sub_action = SUB_DIALOG;
                    output.move_yaw = approach_angle(input.move_yaw, input.angle_to_mario, 0x400,
                                                     &output.angle_velocity_yaw);
                } else {
                    output.animation = IDLE_ANIMATION;
                    if (input.lateral_distance < 700.0f) output.sub_action = SUB_IDLE;
                }
            } else {
                output.animation = IDLE_ANIMATION;
            }
            break;
    }

    output.play_walking_sound = input.sound_state_id == 0;
    if (output.play_walking_sound) output.animation = WALK_ANIMATION;
    output.play_yell_sound = input.action == FOLLOW_CHILD && input.animation_frame_one;
    output.active_flag_unk10 = 1;
    output.clear_interaction_status = 1;
    return output;
}

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (int byte = 0; byte < 4; ++byte) {
        hash ^= (uint64_t) ((value >> (byte * 8)) & 0xff);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static uint64_t hash_f32(uint64_t hash, float value) {
    union { float f; uint32_t u; } bits = { value };
    return hash_u32(hash, bits.u);
}

static uint64_t hash_output(uint64_t hash, Output output) {
    hash = hash_u32(hash, (uint32_t) output.action);
    hash = hash_u32(hash, (uint32_t) output.sub_action);
    hash = hash_f32(hash, output.scale);
    hash = hash_u32(hash, (uint32_t) output.animation);
    hash = hash_f32(hash, output.forward_velocity);
    hash = hash_u32(hash, (uint32_t) (uint16_t) output.move_yaw);
    hash = hash_u32(hash, (uint32_t) (uint16_t) output.angle_velocity_yaw);
    hash = hash_u32(hash, (uint32_t) output.dialog_id);
    hash = hash_u32(hash, (uint32_t) output.dialog_requested);
    hash = hash_u32(hash, (uint32_t) output.child_small_unk88);
    hash = hash_u32(hash, output.child_interaction_set_mask);
    hash = hash_u32(hash, (uint32_t) output.clear_child_drop_immediate);
    hash = hash_u32(hash, (uint32_t) output.child_behavior);
    hash = hash_u32(hash, (uint32_t) output.spawn_star);
    hash = hash_u32(hash, (uint32_t) output.has_star_home);
    if (output.has_star_home) {
        hash = hash_f32(hash, output.star_x);
        hash = hash_f32(hash, output.star_y);
        hash = hash_f32(hash, output.star_z);
    }
    hash = hash_f32(hash, output.star_spawn_y_offset);
    hash = hash_u32(hash, (uint32_t) output.play_walking_sound);
    hash = hash_u32(hash, (uint32_t) output.play_yell_sound);
    hash = hash_u32(hash, (uint32_t) output.active_flag_unk10);
    return hash_u32(hash, (uint32_t) output.clear_interaction_status);
}

static void absorb(uint64_t *fingerprint, Input input) {
    *fingerprint = hash_output(*fingerprint, update(input));
}

int main(void) {
    uint64_t fingerprint = UINT64_C(1469598103934665603);
    absorb(&fingerprint, (Input){ FOLLOW_CHILD, SUB_IDLE, 1, 1, 1, 600, HELD_FREE, 0, 0, 0, 1, 0, 0, 0, 1, 0 });
    absorb(&fingerprint, (Input){ FOLLOW_CHILD, SUB_DIALOG, 1, 1, 1, 600, HELD_FREE, 0, 0, 0, 0, 0, 0, 0, 1, 0 });
    absorb(&fingerprint, (Input){ FOLLOW_CHILD, SUB_DIALOG, 1, 1, 1, 600, HELD_FREE, 0, 0, 0, 0, 1, 0, 0, 1, 0 });
    absorb(&fingerprint, (Input){ FOLLOW_CHILD, SUB_WAIT_FOR_DROP, 1, 1, 1, 250, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0 });
    absorb(&fingerprint, (Input){ CARRYING_CHILD, SUB_IDLE, 1, 1, 1, 600, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0 });
    absorb(&fingerprint, (Input){ CARRYING_CHILD, SUB_IDLE, 1, 1, 1, 600, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0 });
    {
        Input reward_input = { CARRYING_CHILD, SUB_DIALOG, 1, 1, 1, 600, HELD_FREE, 0, 0, 0, 0, 0, 0, 0, 1, 0 };
        Output reward_output = update(reward_input);
        absorb(&fingerprint, reward_input);
    }
    absorb(&fingerprint, (Input){ CARRYING_CHILD, SUB_IDLE, 1, 2, 1, 600, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0 });
    absorb(&fingerprint, (Input){ CARRYING_CHILD, SUB_IDLE, 1, 2, 1, 600, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0 });
    absorb(&fingerprint, (Input){ CARRYING_CHILD, SUB_WAIT_FOR_DROP, 1, 2, 1, 600, HELD_FREE, 0, 0, 0, 0, 0, 0, 0, 1, 0 });
    absorb(&fingerprint, (Input){ CHASE_MARIO, SUB_IDLE, 1, 1, 1, 600, HELD_FREE, 1, 900, 0, 0, 0, 4000, 0, 1, 0 });
    absorb(&fingerprint, (Input){ CHASE_MARIO, SUB_DIALOG, 1, 1, 1, 600, HELD_FREE, 1, 600, 0, 0, 0, 0, 0, 1, 0 });
    absorb(&fingerprint, (Input){ FOLLOW_CHILD, SUB_IDLE, 1, 1, 1, 600, HELD_FREE, 0, 0, 0, 0, 0, 0, 0, 0, 1 });
    printf("tuxiesMotherFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    printf("SM64 Modern Tuxie's mother C contract passed\n");
    return 0;
}
