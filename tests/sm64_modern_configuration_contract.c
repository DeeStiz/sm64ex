#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define MAX_BINDS 3
#define BINDING_COUNT 14

struct configuration {
    bool fullscreen;
    uint32_t window_x, window_y, window_w, window_h;
    bool vsync;
    uint32_t texture_filtering;
    uint32_t master_volume, music_volume, sfx_volume, env_volume;
    uint32_t bindings[BINDING_COUNT][MAX_BINDS];
    uint32_t stick_deadzone, rumble_strength;
    bool precache;
    bool camera_enabled, camera_analog, camera_mouse, camera_invert_x, camera_invert_y;
    uint32_t camera_x, camera_y, camera_aggression, camera_pan, camera_degrade;
    bool hud, skip_intro, discord;
    const char *language;
    bool legal_rom;
    bool cheats[9];
};

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (unsigned shift = 0; shift <= 24; shift += 8) {
        hash ^= (uint64_t) ((value >> shift) & 0xffu);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (unsigned shift = 0; shift <= 56; shift += 8) {
        hash ^= (value >> shift) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_bool(uint64_t hash, bool value) {
    return hash_u32(hash, value ? 1u : 0u);
}

static uint64_t hash_bytes(uint64_t hash, const unsigned char *bytes, size_t count) {
    for (size_t index = 0; index < count; ++index) {
        hash ^= bytes[index];
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_string(uint64_t hash, const char *value) {
    return hash_bytes(hash, (const unsigned char *) value, strlen(value));
}

static uint64_t fingerprint(const struct configuration *config) {
    uint64_t hash = FNV_OFFSET;
    hash = hash_bool(hash, config->fullscreen);
    hash = hash_u32(hash, config->window_x);
    hash = hash_u32(hash, config->window_y);
    hash = hash_u32(hash, config->window_w);
    hash = hash_u32(hash, config->window_h);
    hash = hash_bool(hash, config->vsync);
    hash = hash_u32(hash, config->texture_filtering);
    hash = hash_u32(hash, config->master_volume);
    hash = hash_u32(hash, config->music_volume);
    hash = hash_u32(hash, config->sfx_volume);
    hash = hash_u32(hash, config->env_volume);
    for (unsigned binding = 0; binding < BINDING_COUNT; ++binding) {
        for (unsigned slot = 0; slot < MAX_BINDS; ++slot) {
            hash = hash_u32(hash, config->bindings[binding][slot]);
        }
    }
    hash = hash_u32(hash, config->stick_deadzone);
    hash = hash_u32(hash, config->rumble_strength);
    hash = hash_bool(hash, config->precache);
    hash = hash_bool(hash, config->camera_enabled);
    hash = hash_bool(hash, config->camera_analog);
    hash = hash_bool(hash, config->camera_mouse);
    hash = hash_bool(hash, config->camera_invert_x);
    hash = hash_bool(hash, config->camera_invert_y);
    hash = hash_u32(hash, config->camera_x);
    hash = hash_u32(hash, config->camera_y);
    hash = hash_u32(hash, config->camera_aggression);
    hash = hash_u32(hash, config->camera_pan);
    hash = hash_u32(hash, config->camera_degrade);
    hash = hash_bool(hash, config->hud);
    hash = hash_bool(hash, config->skip_intro);
    hash = hash_bool(hash, config->discord);
    hash = hash_string(hash, config->language);
    hash = hash_bool(hash, config->legal_rom);
    for (unsigned cheat = 0; cheat < 9; ++cheat) {
        hash = hash_bool(hash, config->cheats[cheat]);
    }
    return hash;
}

static void defaults(struct configuration *config) {
    memset(config, 0, sizeof(*config));
    config->window_x = UINT32_MAX;
    config->window_y = UINT32_MAX;
    config->window_w = 640;
    config->window_h = 480;
    config->vsync = true;
    config->texture_filtering = 1;
    config->master_volume = (127 + 1) / 2;
    config->music_volume = 127;
    config->sfx_volume = 127;
    config->env_volume = 127;
    const uint32_t values[BINDING_COUNT][MAX_BINDS] = {
        {0x0026, 0x1000, 0x1103}, {0x0033, 0x1002, 0x1101},
        {0x0039, 0x1006, 0xffff}, {0x002a, 0x1009, 0x1104},
        {0x0036, 0x100a, 0x101b}, {0x0025, 0x1007, 0x101a},
        {0x0148, 0xffff, 0xffff}, {0x0150, 0xffff, 0xffff},
        {0x014b, 0xffff, 0xffff}, {0x014d, 0xffff, 0xffff},
        {0x0011, 0xffff, 0xffff}, {0x001f, 0xffff, 0xffff},
        {0x001e, 0xffff, 0xffff}, {0x0020, 0xffff, 0xffff}
    };
    memcpy(config->bindings, values, sizeof(values));
    config->stick_deadzone = 16;
    config->rumble_strength = 50;
    config->precache = true;
    config->camera_analog = true;
    config->camera_invert_x = true;
    config->camera_x = 50;
    config->camera_y = 50;
    config->camera_degrade = 10;
    config->hud = true;
    config->discord = true;
    config->language = "english";
}

static void rich(struct configuration *config) {
    defaults(config);
    config->fullscreen = true;
    config->window_x = 128;
    config->window_y = 256;
    config->window_w = 1920;
    config->window_h = 1080;
    config->vsync = false;
    config->texture_filtering = 0;
    config->master_volume = 80;
    config->music_volume = 70;
    config->sfx_volume = 60;
    config->env_volume = 50;
    config->bindings[0][0] = 0x0041;
    config->bindings[6][1] = 0x100b;
    config->stick_deadzone = 24;
    config->rumble_strength = 75;
    config->precache = false;
    config->camera_enabled = true;
    config->camera_analog = false;
    config->camera_mouse = true;
    config->camera_invert_x = false;
    config->camera_invert_y = true;
    config->camera_x = 90;
    config->camera_y = 11;
    config->camera_aggression = 33;
    config->camera_pan = 44;
    config->camera_degrade = 55;
    config->hud = false;
    config->skip_intro = true;
    config->discord = false;
    config->legal_rom = true;
    config->cheats[0] = true;
    config->cheats[1] = true;
    config->cheats[2] = false;
    config->cheats[3] = true;
    config->cheats[5] = true;
    config->cheats[6] = true;
    config->cheats[8] = true;
}

static void recovered(struct configuration *config) {
    defaults(config);
    config->legal_rom = true;
    config->cheats[1] = true;
}

int main(void) {
    struct configuration config;
    defaults(&config);
    printf("configurationDefaultFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint(&config));
    rich(&config);
    printf("configurationRichFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint(&config));
    recovered(&config);
    uint64_t recovery = FNV_OFFSET;
    recovery = hash_u64(recovery, fingerprint(&config));
    recovery = hash_string(recovery,
                           "fullscreen,window_w,window_h,texture_filtering,master_volume,music_volume,key_a,stick_deadzone,bettercam_xsens,language");
    recovery = hash_string(recovery, "unknown_future_option,malformed_only");
    recovery = hash_string(recovery, "14");
    printf("configurationRecoveryFingerprint=0x%016llx\n",
           (unsigned long long) recovery);
    return 0;
}
