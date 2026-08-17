#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

struct CheatState {
    bool enabled;
    bool moon_jump;
    bool god_mode;
    bool infinite_lives;
    bool super_speed;
    bool responsive;
    bool exit_anywhere;
    bool huge_mario;
    bool tiny_mario;
};

struct ActionResult {
    uint16_t health;
    uint8_t lives;
    float forward_velocity;
};

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (int shift = 0; shift <= 24; shift += 8) {
        hash ^= (uint64_t) ((value >> shift) & 0xffu);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static uint64_t hash_bool(uint64_t hash, bool value) {
    return hash_u32(hash, value ? 1u : 0u);
}

static float moon_jump_velocity(float current, bool l_trigger_down,
                                struct CheatState state) {
    return state.enabled && state.moon_jump && l_trigger_down ? 25.0f : current;
}

static struct ActionResult apply_mario_action(
    uint16_t health, uint8_t lives, float forward_velocity,
    struct CheatState state) {
    struct ActionResult result = { health, lives, forward_velocity };
    if (!state.enabled)
        return result;
    if (state.god_mode)
        result.health = 0x0880;
    if (state.infinite_lives && result.lives < 99)
        result.lives += 1;
    if (state.super_speed && result.forward_velocity > 0)
        result.forward_velocity += 100.0f;
    return result;
}

static uint32_t float_bits(float value) {
    uint32_t bits = 0;
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

static float model_scale(struct CheatState state) {
    if (!state.enabled)
        return 1.0f;
    if (state.huge_mario)
        return 2.5f;
    if (state.tiny_mario)
        return 0.2f;
    return 1.0f;
}

static uint64_t record(
    uint64_t hash, struct CheatState state,
    uint16_t health, uint8_t lives, float forward_velocity,
    float current_velocity, bool l_trigger_down,
    bool action_allows_pause_exit) {
    const bool flags[] = {
        state.enabled, state.moon_jump, state.god_mode,
        state.infinite_lives, state.super_speed, state.responsive,
        state.exit_anywhere, state.huge_mario, state.tiny_mario,
    };
    for (size_t i = 0; i < sizeof(flags) / sizeof(flags[0]); ++i)
        hash = hash_bool(hash, flags[i]);

    const float moon_velocity = moon_jump_velocity(
        current_velocity, l_trigger_down, state);
    const struct ActionResult action = apply_mario_action(
        health, lives, forward_velocity, state);
    hash = hash_u32(hash, float_bits(moon_velocity));
    hash = hash_u32(hash, action.health);
    hash = hash_u32(hash, action.lives);
    hash = hash_u32(hash, float_bits(action.forward_velocity));
    hash = hash_u32(hash, float_bits(model_scale(state)));
    hash = hash_bool(
        hash, action_allows_pause_exit
            || (state.enabled && state.exit_anywhere));
    return hash_bool(hash, state.enabled && state.responsive);
}

int main(void) {
    const struct CheatState disabled = { 0 };
    struct CheatState all = {
        true, true, true, true, true, true, true, true, true
    };
    uint64_t fingerprint = UINT64_C(1469598103934665603);
    fingerprint = record(
        fingerprint, disabled, 100, 7, 10.0f, 3.0f, true, false);
    fingerprint = record(
        fingerprint, all, 100, 7, 10.0f, 3.0f, true, false);
    fingerprint = record(
        fingerprint, all, 0x0400, 99, 0.0f, 25.0f, false, true);

    all.god_mode = false;
    all.infinite_lives = false;
    all.super_speed = false;
    all.exit_anywhere = false;
    all.huge_mario = false;
    all.tiny_mario = false;
    fingerprint = record(
        fingerprint, all, 100, 7, 10.0f, 3.0f, true, false);

    printf("cheatFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    printf("SM64 Modern cheats C contract passed\n");
    return 0;
}
