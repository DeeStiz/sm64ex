#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define ACT_GROUP_MASK UINT32_C(0x1c0)
#define ACT_GROUP_MOVING UINT32_C(0x40)
#define ACT_GROUP_AIRBORNE UINT32_C(0x80)
#define ACT_GROUP_SUBMERGED UINT32_C(0xc0)
#define ACT_GROUP_CUTSCENE UINT32_C(0x100)
#define ACT_FLAG_AIR UINT32_C(0x800)
#define MARIO_ACTION_SOUND_PLAYED UINT32_C(0x10000)
#define MARIO_MARIO_SOUND_PLAYED UINT32_C(0x20000)
#define MARIO_UNKNOWN_18 UINT32_C(0x40000)
#define MARIO_UNKNOWN_08 UINT32_C(0x100)
#define ACT_IDLE UINT32_C(0x0c400201)
#define ACT_WALKING UINT32_C(0x04000440)
#define ACT_BEGIN_SLIDING UINT32_C(0x50)
#define ACT_STOMACH_SLIDE UINT32_C(0x008c0453)
#define ACT_JUMP UINT32_C(0x03000880)
#define ACT_DOUBLE_JUMP UINT32_C(0x03000881)
#define ACT_DIVE UINT32_C(0x0188088a)
#define ACT_METAL_WATER_JUMP UINT32_C(0x000044f8)
#define ACT_FALL_AFTER_STAR_GRAB UINT32_C(0x00001904)
#define ACT_JUMP_KICK UINT32_C(0x018008ac)

typedef float f32;
typedef int16_t s16;
#include "../include/trig_tables.inc.c"
#define sins(x) gSineTable[((uint16_t)(x)) >> 4]
#define coss(x) gSineTable[((uint16_t)((x) + 0x4000)) >> 4]

struct state {
    uint32_t flags, action, prev_action, action_arg;
    uint16_t action_state, action_timer;
    float velocity[3], forward_velocity, slide_x, slide_z;
    int32_t pitch, yaw, roll;
    uint8_t wall_kick_timer, squish_timer, hurt_counter;
    float intended_magnitude, peak_height, position_y, quicksand_depth;
    uint8_t held, ridden;
};
struct mutation {
    uint32_t requested_action, action, previous_action, action_argument, flags;
    uint16_t action_state, action_timer;
    float velocity[3], forward_velocity, peak_height;
    int32_t pitch, yaw, roll;
    uint8_t wall_kick_timer, dropped_held, dropped_ridden, hurt_counter;
};

static uint64_t hash_u8(uint64_t h, uint8_t v) { return (h ^ v) * FNV_PRIME; }
static uint64_t hash_u16(uint64_t h, uint16_t v) {
    for (unsigned i = 0; i < 2; ++i) { h ^= (v >> (i * 8u)) & 0xffu; h *= FNV_PRIME; }
    return h;
}
static uint64_t hash_u32(uint64_t h, uint32_t v) {
    for (unsigned i = 0; i < 4; ++i) { h ^= (v >> (i * 8u)) & 0xffu; h *= FNV_PRIME; }
    return h;
}
static uint64_t hash_f32(uint64_t h, float value) {
    uint32_t bits; __builtin_memcpy(&bits, &value, sizeof bits); return hash_u32(h, bits);
}
static uint64_t hash_mutation(uint64_t h, struct mutation m) {
    h = hash_u32(h, m.requested_action); h = hash_u32(h, m.action);
    h = hash_u32(h, m.previous_action); h = hash_u32(h, m.action_argument);
    h = hash_u16(h, m.action_state); h = hash_u16(h, m.action_timer); h = hash_u32(h, m.flags);
    h = hash_f32(h, m.velocity[0]); h = hash_f32(h, m.velocity[1]); h = hash_f32(h, m.velocity[2]);
    h = hash_f32(h, m.forward_velocity); h = hash_u32(h, (uint32_t)m.pitch);
    h = hash_u32(h, (uint32_t)m.yaw); h = hash_u32(h, (uint32_t)m.roll);
    h = hash_u8(h, m.wall_kick_timer); h = hash_f32(h, m.peak_height);
    h = hash_u8(h, m.dropped_held); h = hash_u8(h, m.dropped_ridden);
    return hash_u8(h, m.hurt_counter);
}
static void set_forward(struct state *s, float value) {
    s->forward_velocity = value;
    s->slide_x = sins(s->yaw) * value; s->slide_z = coss(s->yaw) * value;
    s->velocity[0] = s->slide_x; s->velocity[2] = s->slide_z;
}
static void set_y(struct state *s, float initial, float multiplier) {
    s->velocity[1] = initial + s->forward_velocity * multiplier;
    if (s->squish_timer || s->quicksand_depth > 1) s->velocity[1] *= 0.5f;
}
static struct mutation finish(struct state *s, uint32_t requested, uint32_t action,
                              uint8_t dropped_held, uint8_t dropped_ridden) {
    uint32_t old_action = s->action;
    s->flags &= ~(MARIO_ACTION_SOUND_PLAYED | MARIO_MARIO_SOUND_PLAYED);
    if ((old_action & ACT_FLAG_AIR) == 0) s->flags &= ~MARIO_UNKNOWN_18;
    s->prev_action = old_action; s->action = action; s->action_arg = 0;
    s->action_state = 0; s->action_timer = 0;
    return (struct mutation){requested, s->action, s->prev_action, s->action_arg,
        s->flags, s->action_state, s->action_timer, {s->velocity[0], s->velocity[1], s->velocity[2]},
        s->forward_velocity, s->peak_height, s->pitch, s->yaw, s->roll, s->wall_kick_timer,
        dropped_held, dropped_ridden, s->hurt_counter};
}
static struct mutation set_action(struct state *s, uint32_t requested, uint32_t argument) {
    uint32_t action = requested;
    switch (requested & ACT_GROUP_MASK) {
        case ACT_GROUP_MOVING:
            if (requested == ACT_WALKING) {
                if (s->forward_velocity >= 0 && s->forward_velocity < s->intended_magnitude)
                    s->forward_velocity = s->intended_magnitude;
            } else if (requested == ACT_BEGIN_SLIDING) {
                action = ACT_STOMACH_SLIDE;
            }
            break;
        case ACT_GROUP_AIRBORNE:
            if ((s->squish_timer || s->quicksand_depth >= 1) && requested == ACT_DOUBLE_JUMP)
                action = ACT_JUMP;
            switch (action) {
                case ACT_DOUBLE_JUMP: set_y(s, 52, .25f); s->forward_velocity *= .8f; break;
                case ACT_JUMP: set_y(s, 42, .25f); s->forward_velocity *= .8f; break;
                case ACT_DIVE: {
                    float value = s->forward_velocity + 15;
                    if (value > 48) value = 48; set_forward(s, value); break;
                }
                case ACT_JUMP_KICK: s->velocity[1] = 20; break;
                default: break;
            }
            s->peak_height = s->position_y; s->flags |= MARIO_UNKNOWN_08;
            break;
        case ACT_GROUP_SUBMERGED:
            if (action == ACT_METAL_WATER_JUMP) s->velocity[1] = 32;
            break;
        case ACT_GROUP_CUTSCENE:
            if (action == ACT_FALL_AFTER_STAR_GRAB) set_forward(s, 0);
            break;
    }
    (void)argument;
    return finish(s, requested, action, 0, 0);
}

static struct state seeded(void) {
    struct state s = {0};
    s.action = ACT_IDLE; s.flags = MARIO_ACTION_SOUND_PLAYED | MARIO_MARIO_SOUND_PLAYED | MARIO_UNKNOWN_18;
    s.intended_magnitude = 6; s.yaw = 0x2000; s.pitch = 0x111; s.roll = -0x222;
    s.position_y = 37; s.forward_velocity = 2; s.velocity[0] = 3; s.velocity[1] = 4; s.velocity[2] = 5;
    return s;
}

int main(void) {
    uint64_t h = FNV_OFFSET; struct state s;
    s = seeded(); h = hash_mutation(h, set_action(&s, ACT_WALKING, 0));
    s = seeded(); h = hash_mutation(h, set_action(&s, ACT_BEGIN_SLIDING, 0));
    s = seeded(); s.forward_velocity = 20; h = hash_mutation(h, set_action(&s, ACT_DOUBLE_JUMP, 0));
    s = seeded(); s.forward_velocity = 40; h = hash_mutation(h, set_action(&s, ACT_DIVE, 0));
    s = seeded(); s.squish_timer = 1; h = hash_mutation(h, set_action(&s, ACT_DOUBLE_JUMP, 0));
    s = seeded(); h = hash_mutation(h, set_action(&s, ACT_METAL_WATER_JUMP, 0));
    s = seeded(); h = hash_mutation(h, set_action(&s, ACT_FALL_AFTER_STAR_GRAB, 0));
    s = seeded(); s.held = 1; s.ridden = 1; s.held = 0; s.ridden = 0;
    h = hash_mutation(h, finish(&s, ACT_IDLE, ACT_IDLE, 1, 1));
    s = seeded(); s.hurt_counter = 4; h = hash_mutation(h, set_action(&s, ACT_JUMP_KICK, 0));
    printf("marioActionFingerprint=0x%016llx\n", (unsigned long long) h);
    return 0;
}
