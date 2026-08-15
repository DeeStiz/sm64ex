#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define FILE_EXISTS (1u << 0)
#define WING_CAP (1u << 1)

static uint64_t h8(uint64_t h, uint8_t value) { h ^= value; return h * FNV_PRIME; }
static uint64_t h16(uint64_t h, uint16_t value) {
    for (unsigned i = 0; i < 2; ++i) h = h8(h, (uint8_t)(value >> (i * 8u)));
    return h;
}
static uint64_t h32(uint64_t h, uint32_t value) {
    for (unsigned i = 0; i < 4; ++i) h = h8(h, (uint8_t)(value >> (i * 8u)));
    return h;
}
static uint64_t hi16(uint64_t h, int16_t value) { return h16(h, (uint16_t)value); }

typedef struct {
    uint8_t red_coins, red_star, cap_switches, level_completed;
    uint32_t flags;
    uint8_t stars[25], scores[15];
    int16_t coins;
    uint8_t save_modified;
} State;

static uint64_t hash_result(uint64_t h, const State *state, uint16_t effects,
                            uint16_t progression_effects, uint8_t accepted) {
    h = h8(h, state->red_coins); h = h8(h, state->red_star);
    h = h8(h, state->cap_switches); h = h8(h, state->level_completed);
    h = h32(h, state->flags);
    for (unsigned i = 0; i < 25; ++i) h = h8(h, state->stars[i]);
    for (unsigned i = 0; i < 15; ++i) h = h8(h, state->scores[i]);
    h = hi16(h, state->coins); h = h8(h, state->save_modified);
    h = h16(h, effects); h = h16(h, progression_effects); return h8(h, accepted);
}

static void collect_red_coin(State *s, uint16_t *effects, uint16_t *pfx, uint8_t *accepted) {
    if (s->red_coins >= 8 || s->red_star) {
        *effects = 0; *pfx = 0; *accepted = 0; return;
    }
    s->coins += 2; s->red_coins += 1; *effects = 0x81; *pfx = 0x401; *accepted = 1;
    if (s->red_coins == 8) *effects |= 0x0A;
}

static void press_cap_switch(State *s, uint8_t index, uint16_t *effects,
                             uint16_t *pfx, uint8_t *accepted) {
    if (index >= 3) { *accepted = 0; return; }
    uint32_t bit = UINT32_C(1) << (index + 1);
    if (s->flags & bit) { *effects = 0; *pfx = 0; *accepted = 0; return; }
    s->flags |= bit | FILE_EXISTS; s->save_modified = 1; s->cap_switches |= (uint8_t)(1u << index);
    *effects = 0x8C; *pfx = 0x200; *accepted = 1;
}

static void complete_level(State *s, uint16_t *effects, uint16_t *pfx, uint8_t *accepted) {
    if (s->level_completed) { *effects = 0; *pfx = 0; *accepted = 0; return; }
    s->flags |= FILE_EXISTS; s->stars[2] |= 0x04; s->scores[2] = 100; s->save_modified = 1;
    s->level_completed = 1; *effects = 0x38; *pfx = 0x602; *accepted = 1;
}

int main(void) {
    State state = { 0 }; state.flags = FILE_EXISTS; state.coins = 10;
    uint64_t fingerprint = FNV_OFFSET;
    for (int i = 0; i < 8; ++i) {
        uint16_t effects = 0, pfx = 0; uint8_t accepted = 0;
        collect_red_coin(&state, &effects, &pfx, &accepted);
        if (i == 7) state.red_star = 1;
        fingerprint = hash_result(fingerprint, &state, effects, pfx, accepted);
    }
    // Swift marks the star-spawn intent on the eighth result; retain that state
    // before hashing the duplicate event to mirror the actor boundary.
    state.red_star = 1;
    uint16_t effects = 0, pfx = 0; uint8_t accepted = 0;
    collect_red_coin(&state, &effects, &pfx, &accepted);
    fingerprint = hash_result(fingerprint, &state, effects, pfx, accepted);

    press_cap_switch(&state, 0, &effects, &pfx, &accepted);
    fingerprint = hash_result(fingerprint, &state, effects, pfx, accepted);
    press_cap_switch(&state, 0, &effects, &pfx, &accepted);
    fingerprint = hash_result(fingerprint, &state, effects, pfx, accepted);
    complete_level(&state, &effects, &pfx, &accepted);
    fingerprint = hash_result(fingerprint, &state, effects, pfx, accepted);
    complete_level(&state, &effects, &pfx, &accepted);
    fingerprint = hash_result(fingerprint, &state, effects, pfx, accepted);

    printf("progressionActorsFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    return 0;
}
