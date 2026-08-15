#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

enum {
    GOOMBA_WALK = 0,
    GOOMBA_ATTACKED = 1,
    GOOMBA_JUMP = 2,
    EFFECT_ALERT = 1 << 0,
    EFFECT_WALK_SOUND = 1 << 1,
    EFFECT_JUMP = 1 << 2,
    EFFECT_ATTACK = 1 << 3,
    EFFECT_DEATH = 1 << 4,
    EFFECT_COIN = 1 << 5,
    EFFECT_RESPAWN = 1 << 6,
    EFFECT_ANIMATE = 1 << 7,
    EFFECT_LANDED = 1 << 8
};

struct State {
    uint8_t size;
    float scale;
    uint8_t action;
    int16_t yaw;
    int16_t target;
    float forward;
    float velocity_y;
    float relative_speed;
    int16_t walk_timer;
    uint8_t turning;
    uint32_t timer;
    int16_t health;
    uint8_t loot;
    uint8_t marked;
    uint8_t respawn;
    float animation_speed;
};

struct Input {
    float distance;
    int16_t angle;
    uint8_t on_ground;
    uint16_t random_u16;
    float random_fraction;
    uint8_t attack;
};

static uint64_t h8(uint64_t h, uint8_t value) { h ^= value; return h * FNV_PRIME; }
static uint64_t h16(uint64_t h, uint16_t value) { for (unsigned i = 0; i < 2; ++i) h = h8(h, (uint8_t)(value >> (i * 8u))); return h; }
static uint64_t h32(uint64_t h, uint32_t value) { for (unsigned i = 0; i < 4; ++i) h = h8(h, (uint8_t)(value >> (i * 8u))); return h; }
static uint32_t float_bits(float value) { uint32_t bits; memcpy(&bits, &value, sizeof(bits)); return bits; }

static float approach(float value, float target, float increment) {
    float distance = target - value;
    if (distance > increment) return value + increment;
    if (distance < -increment) return value - increment;
    return target;
}

static int16_t approach_yaw(int16_t value, int16_t target, int16_t increment) {
    int32_t distance = (int32_t) target - value;
    if (distance > increment) return (int16_t) (value + increment);
    if (distance < -increment) return (int16_t) (value - increment);
    return target;
}

static int16_t random_offset(int16_t base, int16_t range, float fraction) {
    if (fraction < 0) fraction = 0;
    if (fraction > 0.999999f) fraction = 0.999999f;
    return (int16_t) (base + (int32_t) ((float) range * fraction));
}

static uint16_t tick(struct State *state, struct Input input) {
    uint16_t effects = EFFECT_ANIMATE;
    state->animation_speed = state->forward / state->scale * 0.4f;
    if (state->animation_speed < 1) state->animation_speed = 1;

    if (state->action == GOOMBA_WALK) {
        state->forward = approach(
            state->forward, state->relative_speed * state->scale, 0.4f);
        if (state->relative_speed > 4.0f / 3.0f)
            effects |= EFFECT_WALK_SOUND;
        if (state->turning) {
            int16_t next = approach_yaw(state->yaw, state->target, 0x200);
            state->turning = next == state->yaw ? 0 : state->turning;
            state->yaw = next;
        } else if (input.distance < 500) {
            if (state->relative_speed <= 2) {
                state->action = GOOMBA_JUMP;
                state->forward = 0;
                state->velocity_y = 50.0f / 3.0f * state->scale;
                effects |= EFFECT_ALERT | EFFECT_JUMP;
            }
            state->target = input.angle;
            state->relative_speed = 20;
            state->yaw = approach_yaw(state->yaw, state->target, 0x200);
        } else {
            state->relative_speed = 4.0f / 3.0f;
            if (state->walk_timer != 0) {
                state->walk_timer--;
            } else if ((input.random_u16 & 3) != 0) {
                int16_t sign = input.random_u16 >= 0x7FFF ? 1 : -1;
                state->target = (int16_t) (state->yaw + sign * 0x2000);
                state->walk_timer = random_offset(100, 100, input.random_fraction);
                state->yaw = approach_yaw(state->yaw, state->target, 0x200);
            } else {
                state->action = GOOMBA_JUMP;
                state->forward = 0;
                state->velocity_y = 50.0f / 3.0f * state->scale;
                effects |= EFFECT_ALERT | EFFECT_JUMP;
                int16_t sign = input.random_u16 >= 0x7FFF ? 1 : -1;
                state->target = (int16_t) (state->yaw + sign * 0x6000);
                state->yaw = approach_yaw(state->yaw, state->target, 0x200);
            }
        }
    } else if (state->action == GOOMBA_ATTACKED) {
        if (state->size == 2) {
            state->loot = 0;
            state->marked = 1;
            state->respawn = 1;
            effects |= EFFECT_RESPAWN | EFFECT_DEATH | EFFECT_COIN;
        } else {
            state->action = GOOMBA_JUMP;
            state->forward = 0;
            state->velocity_y = 50.0f / 3.0f * state->scale;
            effects |= EFFECT_ALERT | EFFECT_JUMP;
            state->target = input.angle;
            state->turning = 0;
        }
    } else if (state->action == GOOMBA_JUMP) {
        if (input.on_ground) {
            state->action = GOOMBA_WALK;
            effects |= EFFECT_LANDED;
        } else {
            state->yaw = approach_yaw(state->yaw, state->target, 0x800);
        }
    }

    if (input.attack == 1 || input.attack == 2 || input.attack == 3) {
        state->action = GOOMBA_ATTACKED;
        effects |= EFFECT_ATTACK;
        if ((input.attack == 2 || input.attack == 3) && state->size == 2)
            state->health = 0;
    }
    if (state->timer < UINT32_C(0x3FFFFFFF)) state->timer++;
    return effects;
}

static uint64_t hash_state(uint64_t h, const struct State *state, uint16_t effects) {
    h = h8(h, state->size);
    h = h8(h, state->action);
    h = h16(h, (uint16_t) state->yaw);
    h = h16(h, (uint16_t) state->target);
    h = h32(h, float_bits(state->forward));
    h = h32(h, float_bits(state->velocity_y));
    h = h32(h, float_bits(state->relative_speed));
    h = h16(h, (uint16_t) state->walk_timer);
    h = h8(h, state->turning);
    h = h32(h, state->timer);
    h = h16(h, (uint16_t) state->health);
    h = h8(h, state->loot);
    h = h8(h, state->marked);
    h = h8(h, state->respawn);
    h = h32(h, float_bits(state->animation_speed));
    return h16(h, effects);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    struct State regular = {
        .size = 0, .scale = 1.5f, .action = GOOMBA_WALK,
        .yaw = 0, .target = 0, .relative_speed = 4.0f / 3.0f,
        .health = 1, .loot = 1
    };
    uint16_t effects = tick(&regular, (struct Input){
        .distance = 10000, .angle = 0x1000,
        .on_ground = 1, .random_u16 = 1, .random_fraction = 0.25f
    });
    fingerprint = hash_state(fingerprint, &regular, effects);
    effects = tick(&regular, (struct Input){ .distance = 400, .angle = 0x3000, .on_ground = 1 });
    fingerprint = hash_state(fingerprint, &regular, effects);
    effects = tick(&regular, (struct Input){ .on_ground = 0 });
    fingerprint = hash_state(fingerprint, &regular, effects);
    effects = tick(&regular, (struct Input){ .on_ground = 1 });
    fingerprint = hash_state(fingerprint, &regular, effects);

    struct State tiny = {
        .size = 2, .scale = 0.5f, .action = GOOMBA_WALK,
        .relative_speed = 4.0f / 3.0f, .health = 1, .loot = 1
    };
    (void) tick(&tiny, (struct Input){ .distance = 10000, .on_ground = 1, .attack = 2 });
    effects = tick(&tiny, (struct Input){ .distance = 10000, .on_ground = 1 });
    fingerprint = hash_state(fingerprint, &tiny, effects);

    struct State huge = {
        .size = 1, .scale = 3.5f, .action = GOOMBA_WALK,
        .relative_speed = 4.0f / 3.0f, .health = 1, .loot = 1
    };
    (void) tick(&huge, (struct Input){ .distance = 10000, .on_ground = 1, .attack = 1 });
    effects = tick(&huge, (struct Input){ .distance = 10000, .on_ground = 1 });
    fingerprint = hash_state(fingerprint, &huge, effects);

    printf("goombaEnemyFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    return 0;
}
