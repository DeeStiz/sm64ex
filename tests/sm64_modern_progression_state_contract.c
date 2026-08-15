#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define FILE_EXISTS (1u << 0)
#define BASEMENT_DOOR (1u << 6)
#define CAP_GROUND (1u << 16)
#define CAP_UKIKI (1u << 18)

static uint64_t h8(uint64_t h, uint8_t value) { h ^= value; return h * FNV_PRIME; }
static uint64_t h16(uint64_t h, uint16_t value) {
    for (unsigned i = 0; i < 2; ++i) h = h8(h, (uint8_t)(value >> (i * 8u)));
    return h;
}
static uint64_t h32(uint64_t h, uint32_t value) {
    for (unsigned i = 0; i < 4; ++i) h = h8(h, (uint8_t)(value >> (i * 8u)));
    return h;
}
static uint64_t hf(uint64_t h, float value) { uint32_t bits; memcpy(&bits, &value, sizeof(bits)); return h32(h, bits); }
static uint64_t hi16(uint64_t h, int16_t value) { return h16(h, (uint16_t)value); }

typedef struct { float x, y, z; } Vec3;
typedef struct { uint8_t act, course, level, area, node; } Checkpoint;
typedef struct { int16_t level, area, node; int32_t argument; } Warp;
typedef struct {
    uint32_t flags;
    uint8_t course_stars[25];
    uint8_t course_scores[15];
    uint8_t secret_stars;
    uint32_t switches;
    int16_t coins, lives, course, last_course, last_star;
    uint8_t cap_location, cap_level, cap_area;
    Vec3 cap_pos;
    Checkpoint checkpoint;
    uint8_t has_checkpoint, save_modified;
} State;
typedef struct { State state; uint16_t effects; uint8_t accepted, has_warp; Warp warp; } Result;

static int16_t total_stars(const State *state) {
    int16_t total = 0;
    for (unsigned i = 0; i < 25; ++i) {
        uint8_t bits = state->course_stars[i] & 0x7F;
        for (; bits != 0; bits &= (uint8_t)(bits - 1)) ++total;
    }
    uint8_t bits = state->secret_stars & 0x7F;
    for (; bits != 0; bits &= (uint8_t)(bits - 1)) ++total;
    return total;
}

static Result result(State state, uint16_t effects, uint8_t accepted) {
    return (Result){ state, effects, accepted, 0, { 0, 0, 0, 0 } };
}

static Result collect_coin(State state, int16_t value) {
    state.coins = (int16_t)(state.coins + value);
    return result(state, 0x401, 1);
}

static Result collect_star(State state, uint8_t kind, int16_t index, int16_t score, int16_t global_max) {
    int course_index = state.course - 1;
    uint8_t star_flag = (uint8_t)(1u << (unsigned)index);
    uint16_t effects = 0x402;
    state.flags |= FILE_EXISTS;
    state.last_course = state.course;
    state.last_star = (int16_t)(index + 1);
    if (kind == 0) {
        if (score > state.course_scores[course_index]) {
            state.course_scores[course_index] = (uint8_t)score;
            state.save_modified = 1; effects |= 0x200;
        }
        if ((state.course_stars[course_index] & star_flag) == 0) {
            state.course_stars[course_index] |= star_flag;
            state.save_modified = 1; effects |= 0x200;
        }
    } else if (kind == 1) {
        state.secret_stars |= star_flag; state.save_modified = 1; effects |= 0x200;
    }
    if (kind == 2) { state.flags |= 1u << 4; state.save_modified = 1; effects |= 0x200; }
    if (kind == 3) { state.flags |= 1u << 5; state.save_modified = 1; effects |= 0x200; }
    if (score > global_max) effects |= 0x200;
    return result(state, effects, 1);
}

static Result unlock_cannon(State state) {
    state.course_stars[state.course] |= 0x80;
    state.flags |= FILE_EXISTS; state.save_modified = 1;
    return result(state, 0x204, 1);
}

static Result press_switch(State state, uint8_t index) {
    state.switches |= 1u << index;
    return result(state, 0x408, 1);
}

static Result open_door(State state, int16_t required, uint32_t flag) {
    if (total_stars(&state) < required) return result(state, 0, 0);
    state.flags |= flag; state.save_modified = 1;
    return result(state, 0x210, 1);
}

static Result set_cap_ground(State state) {
    state.cap_location = 1; state.cap_level = 7; state.cap_area = 2;
    state.cap_pos = (Vec3){ -10.f, 20.f, 30.f };
    state.flags |= CAP_GROUND; state.flags &= ~(1u << 17 | CAP_UKIKI | (1u << 19));
    state.save_modified = 1;
    return result(state, 0x220, 1);
}

static Result set_checkpoint(State state) {
    state.checkpoint = (Checkpoint){ 2, 3, 7, 2, 4 }; state.has_checkpoint = 1;
    return result(state, 0x40, 1);
}

static Result request_warp(State state) {
    Result out = result(state, 0x80, 1);
    out.has_warp = 1; out.warp = (Warp){ 10, 2, 3, -7 };
    return out;
}

static Result add_life(State state) {
    state.lives = state.lives + 2 > 100 ? 100 : state.lives + 2;
    return result(state, 0x100, 1);
}

static Result set_cap_ukiki(State state) {
    state.cap_location = 3;
    state.flags &= ~(CAP_GROUND | (1u << 17) | CAP_UKIKI | (1u << 19));
    state.flags |= CAP_UKIKI; state.save_modified = 1;
    return result(state, 0x220, 1);
}

static uint64_t hash_state(uint64_t h, const State *state) {
    h = h32(h, state->flags);
    for (unsigned i = 0; i < 25; ++i) h = h8(h, state->course_stars[i]);
    for (unsigned i = 0; i < 15; ++i) h = h8(h, state->course_scores[i]);
    h = h8(h, state->secret_stars); h = h32(h, state->switches);
    h = hi16(h, state->coins); h = hi16(h, state->lives); h = hi16(h, state->course);
    h = hi16(h, state->last_course); h = hi16(h, state->last_star);
    h = h8(h, state->cap_location); h = h8(h, state->cap_level); h = h8(h, state->cap_area);
    h = hf(h, state->cap_pos.x); h = hf(h, state->cap_pos.y); h = hf(h, state->cap_pos.z);
    h = h8(h, state->has_checkpoint);
    if (state->has_checkpoint) {
        h = h8(h, state->checkpoint.act); h = h8(h, state->checkpoint.course);
        h = h8(h, state->checkpoint.level); h = h8(h, state->checkpoint.area); h = h8(h, state->checkpoint.node);
    }
    return h8(h, state->save_modified);
}

static uint64_t hash_result(uint64_t h, Result result) {
    h = hash_state(h, &result.state); h = h16(h, result.effects); h = h8(h, result.accepted); h = h8(h, result.has_warp);
    if (result.has_warp) { h = hi16(h, result.warp.level); h = hi16(h, result.warp.area); h = hi16(h, result.warp.node); h = h32(h, (uint32_t)result.warp.argument); }
    return h;
}

int main(void) {
    State state = { 0 };
    state.flags = FILE_EXISTS; state.coins = 95; state.lives = 4; state.course = 3;
    uint64_t fingerprint = FNV_OFFSET;
    Result out = collect_coin(state, 5); state = out.state; fingerprint = hash_result(fingerprint, out);
    out = collect_star(state, 0, 2, 100, 95); state = out.state; fingerprint = hash_result(fingerprint, out);
    out = unlock_cannon(state); state = out.state; fingerprint = hash_result(fingerprint, out);
    out = press_switch(state, 4); state = out.state; fingerprint = hash_result(fingerprint, out);
    out = open_door(state, 1, BASEMENT_DOOR); state = out.state; fingerprint = hash_result(fingerprint, out);
    out = set_cap_ground(state); state = out.state; fingerprint = hash_result(fingerprint, out);
    out = set_checkpoint(state); state = out.state; fingerprint = hash_result(fingerprint, out);
    out = request_warp(state); state = out.state; fingerprint = hash_result(fingerprint, out);
    out = add_life(state); state = out.state; fingerprint = hash_result(fingerprint, out);
    out = set_cap_ukiki(state); state = out.state; fingerprint = hash_result(fingerprint, out);
    out = collect_star(state, 1, 1, 0, 0); state = out.state; fingerprint = hash_result(fingerprint, out);
    printf("progressionStateFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    return 0;
}
