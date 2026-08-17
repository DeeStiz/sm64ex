#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

enum HudFlag {
    HUD_LIVES = 0x0001,
    HUD_COINS = 0x0002,
    HUD_STARS = 0x0004,
    HUD_CAMERA_POWER = 0x0008,
    HUD_KEYS = 0x0010,
    HUD_TIMER = 0x0040,
};

enum PowerAnimation {
    POWER_HIDDEN,
    POWER_EMPHASIZED,
    POWER_DEEMPHASIZING,
    POWER_HIDING,
    POWER_VISIBLE,
};

struct PowerState {
    enum PowerAnimation animation;
    int16_t y;
    int16_t stored_health;
    uint32_t visible_timer;
};

struct Input {
    uint16_t flags;
    bool config_hud;
    int16_t lives;
    int16_t coins;
    int16_t stars;
    int16_t keys;
    uint16_t timer;
    bool hud_flash;
    uint32_t global_timer;
    int16_t health_wedges;
    bool swimming;
    bool advance_legacy;
};

struct Projection {
    struct Input input;
    bool show_lives;
    bool show_coins;
    bool show_stars;
    bool show_keys;
    bool show_camera_power;
    bool show_timer;
    bool show_star_multiplier;
    uint16_t minutes;
    uint16_t seconds;
    uint16_t fraction;
    struct PowerState power;
    bool power_render;
};

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (int shift = 0; shift <= 24; shift += 8) {
        hash ^= (uint64_t)((value >> shift) & 0xffu);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static uint64_t hash_bool(uint64_t hash, bool value) {
    return hash_u32(hash, value ? 1u : 0u);
}

static struct PowerState power_step(
    struct PowerState state, int16_t health, uint16_t flags,
    bool swimming, bool advance, bool *out_render) {
    if (!advance) {
        *out_render = state.animation != POWER_HIDDEN;
        return state;
    }
    if (state.animation != POWER_HIDING) {
        if (health < 8 && state.stored_health == 8
            && state.animation == POWER_HIDDEN) {
            state.animation = POWER_EMPHASIZED;
            state.y = 166;
        }
        if (health == 8 && state.stored_health == 7)
            state.visible_timer = 0;
        if (health == 8 && state.visible_timer > 45)
            state.animation = POWER_HIDING;
        state.stored_health = health;
        if (swimming) {
            if (state.animation == POWER_HIDDEN
                || state.animation == POWER_EMPHASIZED) {
                state.animation = POWER_DEEMPHASIZING;
                state.y = 166;
            }
            state.visible_timer = 0;
        }
    }
    *out_render = state.animation != POWER_HIDDEN;
    if (*out_render) {
        switch (state.animation) {
        case POWER_EMPHASIZED:
            if (!(flags & 0x8000u)) {
                if (state.visible_timer == 45)
                    state.animation = POWER_DEEMPHASIZING;
            } else {
                state.visible_timer = 0;
            }
            break;
        case POWER_DEEMPHASIZING: {
            int16_t speed = 5;
            if (state.y >= 181) speed = 3;
            if (state.y >= 191) speed = 2;
            if (state.y >= 196) speed = 1;
            state.y += speed;
            if (state.y >= 201) {
                state.y = 200;
                state.animation = POWER_VISIBLE;
            }
            break;
        }
        case POWER_HIDING:
            state.y += 20;
            if (state.y >= 301) {
                state.animation = POWER_HIDDEN;
                state.visible_timer = 0;
            }
            break;
        case POWER_HIDDEN:
        case POWER_VISIBLE:
            break;
        }
    }
    if (*out_render)
        state.visible_timer += 1;
    return state;
}

static struct Projection project(
    struct Input input, struct PowerState *power) {
    struct Projection output = { 0 };
    output.input = input;
    const bool counters = input.config_hud && input.flags != 0;
    output.show_lives = counters && (input.flags & HUD_LIVES);
    output.show_coins = counters && (input.flags & HUD_COINS);
    output.show_stars = counters && (input.flags & HUD_STARS)
        && !(input.hud_flash && (input.global_timer & 8u));
    output.show_keys = counters && (input.flags & HUD_KEYS);
    output.show_camera_power = counters && (input.flags & HUD_CAMERA_POWER);
    output.show_timer = counters && (input.flags & HUD_TIMER);
    output.show_star_multiplier = output.show_stars && input.stars < 100;
    output.minutes = input.timer / 1800;
    output.seconds = (input.timer - output.minutes * 1800) / 30;
    output.fraction = (input.timer - output.minutes * 1800
                       - output.seconds * 30) / 3;
    output.power = power_step(
        *power, input.health_wedges, input.flags, input.swimming,
        input.advance_legacy, &output.power_render);
    *power = output.power;
    return output;
}

static uint64_t record(uint64_t hash, const struct Projection *projection) {
    const struct Input *input = &projection->input;
    hash = hash_u32(hash, input->flags);
    hash = hash_bool(hash, input->config_hud);
    hash = hash_u32(hash, (uint32_t)(int32_t)input->lives);
    hash = hash_u32(hash, (uint32_t)(int32_t)input->coins);
    hash = hash_u32(hash, (uint32_t)(int32_t)input->stars);
    hash = hash_u32(hash, (uint32_t)(int32_t)input->keys);
    const bool values[] = {
        projection->show_lives, projection->show_coins,
        projection->show_stars, projection->show_keys,
        projection->show_camera_power, projection->show_timer,
        projection->show_star_multiplier, projection->power_render,
    };
    for (unsigned int i = 0; i < sizeof(values) / sizeof(values[0]); ++i)
        hash = hash_bool(hash, values[i]);
    hash = hash_u32(hash, projection->minutes);
    hash = hash_u32(hash, projection->seconds);
    hash = hash_u32(hash, projection->fraction);
    hash = hash_u32(hash, projection->power.animation);
    hash = hash_u32(hash, (uint32_t)(int32_t)projection->power.y);
    hash = hash_u32(hash, projection->power.visible_timer);
    return hash;
}

static struct Input input(uint16_t flags) {
    return (struct Input){
        .flags = flags,
        .config_hud = true,
        .lives = 4,
        .coins = 23,
        .stars = 99,
        .keys = 1,
        .timer = 1857,
        .health_wedges = 8,
        .advance_legacy = true,
    };
}

int main(void) {
    struct PowerState power = {
        .animation = POWER_HIDDEN, .y = 166, .stored_health = 8,
    };
    uint64_t fingerprint = UINT64_C(1469598103934665603);
    struct Projection full = project(
        input(HUD_LIVES | HUD_COINS | HUD_STARS | HUD_CAMERA_POWER
              | HUD_KEYS | HUD_TIMER), &power);
    if (!full.show_lives || !full.show_coins || !full.show_stars
        || !full.show_keys || !full.show_camera_power || !full.show_timer
        || !full.show_star_multiplier || full.minutes != 1
        || full.seconds != 1 || full.fraction != 9)
        return 1;
    fingerprint = record(fingerprint, &full);

    struct Input flashing_input = input(HUD_STARS);
    flashing_input.stars = 100;
    flashing_input.hud_flash = true;
    flashing_input.global_timer = 8;
    struct Projection flashing = project(flashing_input, &power);
    if (flashing.show_stars || flashing.show_star_multiplier)
        return 1;
    fingerprint = record(fingerprint, &flashing);

    struct Input damaged_input = input(HUD_CAMERA_POWER);
    damaged_input.health_wedges = 6;
    struct Projection damaged = project(damaged_input, &power);
    if (damaged.power.animation != POWER_EMPHASIZED || !damaged.power_render)
        return 1;
    fingerprint = record(fingerprint, &damaged);
    for (unsigned int i = 0; i < 45; ++i)
        (void) project(damaged_input, &power);
    struct Projection deemphasized = project(damaged_input, &power);
    if (deemphasized.power.animation != POWER_DEEMPHASIZING)
        return 1;
    fingerprint = record(fingerprint, &deemphasized);

    struct Input frozen_input = damaged_input;
    frozen_input.advance_legacy = false;
    struct Projection frozen = project(frozen_input, &power);
    if (frozen.power.y != deemphasized.power.y)
        return 1;
    printf("hudFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    puts("SM64 Modern HUD C contract passed");
    return 0;
}
