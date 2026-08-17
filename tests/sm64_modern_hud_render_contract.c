#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

enum HudFlag {
    HUD_LIVES = 0x0001,
    HUD_COINS = 0x0002,
    HUD_STARS = 0x0004,
    HUD_CAMERA_POWER = 0x0008,
    HUD_KEYS = 0x0010,
    HUD_TIMER = 0x0040,
};

enum CommandKind {
    COMMAND_GLYPH = 1,
    COMMAND_POWER_BASE = 2,
    COMMAND_POWER_HEALTH = 3,
};

enum PowerAnimation {
    POWER_HIDDEN,
    POWER_EMPHASIZED,
    POWER_DEEMPHASIZING,
    POWER_HIDING,
    POWER_VISIBLE,
};

struct Layout {
    int32_t width;
    int32_t height;
    double aspect;
    bool japanese;
};

struct Command {
    enum CommandKind kind;
    int16_t glyph;
    int32_t x;
    int32_t y;
    int32_t width;
    int32_t height;
    int32_t advance;
    int16_t health_wedges;
};

struct Packet {
    struct Layout layout;
    struct Command commands[128];
    uint32_t count;
};

struct PowerState {
    enum PowerAnimation animation;
    int16_t x;
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

static int32_t left_edge(struct Layout layout, int32_t offset) {
    double value = (double)layout.width / 2.0
        - (double)layout.height / 2.0 * layout.aspect + (double)offset;
    return (int32_t)value;
}

static int32_t right_edge(struct Layout layout, int32_t offset) {
    double value = (double)layout.width / 2.0
        + (double)layout.height / 2.0 * layout.aspect - (double)offset;
    int32_t result = (int32_t)value;
    if ((double)result < value)
        result += 1;
    return result;
}

static void append_command(
    struct Packet *packet, enum CommandKind kind, int16_t glyph,
    int32_t x, int32_t y, int32_t width, int32_t height,
    int32_t advance, int16_t health_wedges) {
    if (packet->count >= sizeof(packet->commands) / sizeof(packet->commands[0]))
        return;
    packet->commands[packet->count++] = (struct Command){
        kind, glyph, x, y, width, height, advance, health_wedges
    };
}

static void append_glyph(struct Packet *packet, int16_t glyph, int32_t x, int32_t y) {
    append_command(packet, COMMAND_GLYPH, glyph, x, y, 16, 16, 12, 0);
}

static void append_power_base(struct Packet *packet, int16_t x, int16_t y) {
    append_command(packet, COMMAND_POWER_BASE, -1, x - 32, y - 32, 64, 64, 0, 0);
}

static void append_power_health(
    struct Packet *packet, int16_t x, int16_t y, int16_t wedges) {
    append_command(packet, COMMAND_POWER_HEALTH, -1, x - 16, y - 16, 32, 32, 0, wedges);
}

static int16_t glyph_id(char character) {
    if (character >= 'A' && character <= 'Z') return (int16_t)(character - 55);
    if (character >= 'a' && character <= 'z') return (int16_t)(character - 87);
    if (character >= '0' && character <= '9') return (int16_t)(character - '0');
    switch (character) {
    case '*': return 50;
    case '+': return 51;
    case ',': return 52;
    case '-': return 53;
    case '.': return 54;
    case '/': return 55;
    case '\'': return 56;
    case '"': return 57;
    default: return -1;
    }
}

static void append_text(struct Packet *packet, int32_t x, int32_t y, const char *text) {
    for (int32_t index = 0; text[index] != '\0'; ++index) {
        int16_t glyph = glyph_id(text[index]);
        if (glyph >= 0)
            append_glyph(packet, glyph, x + index * 12, y);
    }
}

static void append_number(
    struct Packet *packet, int32_t value, int32_t x, int32_t y,
    int32_t width, bool zero_pad) {
    char buffer[32];
    char digits[32];
    int32_t count = 0;
    bool negative = value < 0;
    int32_t magnitude = negative ? -value : value;
    snprintf(buffer, sizeof(buffer), "%d", magnitude);
    if (negative)
        digits[count++] = 'M';
    const int32_t digit_count = (int32_t)strlen(buffer);
    while (count + digit_count < width)
        digits[count++] = zero_pad ? '0' : ' ';
    memcpy(digits + count, buffer, (size_t)digit_count);
    count += digit_count;
    for (int32_t index = 0; index < count; ++index) {
        int16_t glyph = glyph_id(digits[index]);
        if (glyph >= 0)
            append_glyph(packet, glyph, x + index * 12, y);
    }
}

static struct PowerState power_step(
    struct PowerState state, int16_t health, uint16_t flags,
    bool swimming, bool advance, bool *render) {
    if (!advance) {
        *render = state.animation != POWER_HIDDEN;
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
    *render = state.animation != POWER_HIDDEN;
    if (*render) {
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
    if (*render)
        state.visible_timer += 1;
    return state;
}

static struct Projection project(struct Input input, struct PowerState *power) {
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
    if (output.show_camera_power) {
        bool power_render = false;
        *power = power_step(
            *power, input.health_wedges, input.flags, input.swimming,
            input.advance_legacy, &power_render);
        output.power_render = power_render;
    }
    output.power = *power;
    return output;
}

static struct Packet render_packet(
    struct Projection projection, int16_t keys, struct Layout layout) {
    struct Packet packet = { .layout = layout };
    if (!projection.input.config_hud || projection.input.flags == 0)
        return packet;
    const int32_t top_y = layout.japanese ? 210 : 209;
    const int32_t stars_x = layout.japanese ? 73 : 78;
    if (projection.show_lives) {
        append_glyph(&packet, 52, left_edge(layout, 22), top_y);
        append_glyph(&packet, 50, left_edge(layout, 38), top_y);
        append_number(&packet, projection.input.lives, left_edge(layout, 54), top_y, 0, false);
    }
    if (projection.show_coins) {
        append_glyph(&packet, 51, 168, top_y);
        append_glyph(&packet, 50, 184, top_y);
        append_number(&packet, projection.input.coins, 198, top_y, 0, false);
    }
    if (projection.show_stars) {
        const int32_t star_x = right_edge(layout, stars_x);
        append_glyph(&packet, 53, star_x, top_y);
        if (projection.show_star_multiplier)
            append_glyph(&packet, 50, star_x + 16, top_y);
        append_number(
            &packet, projection.input.stars,
            right_edge(layout, stars_x - 16)
                + (projection.show_star_multiplier ? 14 : 0),
            top_y, 0, false);
    }
    if (projection.show_keys) {
        for (int16_t index = 0; index < keys; ++index)
            append_glyph(&packet, 55, (int32_t)index * 16 + 220, 142);
    }
    if (projection.show_camera_power && projection.power_render) {
        append_power_base(&packet, projection.power.x, projection.power.y);
        if (projection.input.health_wedges != 0)
            append_power_health(&packet, projection.power.x, projection.power.y,
                                projection.input.health_wedges);
    }
    if (projection.show_timer) {
        append_text(&packet, right_edge(layout, 150), 185, "TIME");
        append_number(&packet, projection.minutes, right_edge(layout, 91), 185, 0, false);
        append_number(&packet, projection.seconds, right_edge(layout, 71), 185, 2, true);
        append_number(&packet, projection.fraction, right_edge(layout, 37), 185, 0, false);
        append_glyph(&packet, 56, right_edge(layout, 81), 32);
        append_glyph(&packet, 57, right_edge(layout, 46), 32);
    }
    return packet;
}

static uint64_t record(uint64_t hash, const struct Packet *packet) {
    hash = hash_u32(hash, (uint32_t)packet->layout.width);
    hash = hash_u32(hash, (uint32_t)packet->layout.height);
    hash = hash_bool(hash, packet->layout.japanese);
    hash = hash_u32(hash, packet->count);
    for (uint32_t index = 0; index < packet->count; ++index) {
        const struct Command *command = &packet->commands[index];
        hash = hash_u32(hash, (uint32_t)command->kind);
        hash = hash_u32(hash, (uint32_t)(int32_t)command->glyph);
        hash = hash_u32(hash, (uint32_t)command->x);
        hash = hash_u32(hash, (uint32_t)command->y);
        hash = hash_u32(hash, (uint32_t)command->width);
        hash = hash_u32(hash, (uint32_t)command->height);
        hash = hash_u32(hash, (uint32_t)command->advance);
        hash = hash_u32(hash, (uint32_t)(int32_t)command->health_wedges);
    }
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

static bool command_equals(
    struct Command command, enum CommandKind kind, int16_t glyph,
    int32_t x, int32_t y) {
    return command.kind == kind && command.glyph == glyph
        && command.x == x && command.y == y;
}

int main(void) {
    struct Layout layout = { 320, 240, 4.0 / 3.0, false };
    struct PowerState power = {
        POWER_HIDDEN, 140, 166, 8, 0
    };
    uint64_t fingerprint = UINT64_C(1469598103934665603);
    const uint16_t flags = HUD_LIVES | HUD_COINS | HUD_STARS
        | HUD_CAMERA_POWER | HUD_KEYS | HUD_TIMER;

    struct Input full_input = input(flags);
    full_input.health_wedges = 6;
    struct Projection full = project(full_input, &power);
    struct Packet full_packet = render_packet(full, 1, layout);
    if (full_packet.count != 24
        || !command_equals(full_packet.commands[0], COMMAND_GLYPH, 52, 22, 209)
        || !command_equals(full_packet.commands[2], COMMAND_GLYPH, 4, 54, 209)
        || !command_equals(full_packet.commands[7], COMMAND_GLYPH, 53, 242, 209)) {
        return 1;
    }
    bool power_found = false;
    bool health_found = false;
    for (uint32_t index = 0; index < full_packet.count; ++index) {
        power_found |= full_packet.commands[index].kind == COMMAND_POWER_BASE
            && full_packet.commands[index].x == 108
            && full_packet.commands[index].y == 134;
        health_found |= full_packet.commands[index].kind == COMMAND_POWER_HEALTH
            && full_packet.commands[index].health_wedges == 6;
    }
    if (!power_found || !health_found)
        return 1;
    fingerprint = record(fingerprint, &full_packet);

    struct Input flashing_input = input(HUD_STARS);
    flashing_input.stars = 100;
    flashing_input.hud_flash = true;
    flashing_input.global_timer = 8;
    struct Packet flashing_packet = render_packet(
        project(flashing_input, &power), 0, layout);
    if (flashing_packet.count != 0) {
        return 1;
    }
    fingerprint = record(fingerprint, &flashing_packet);

    struct Input damaged_input = input(HUD_CAMERA_POWER);
    damaged_input.health_wedges = 6;
    struct Packet damaged_packet = render_packet(
        project(damaged_input, &power), 0, layout);
    if (damaged_packet.count != 2
        || damaged_packet.commands[0].kind != COMMAND_POWER_BASE
        || damaged_packet.commands[1].health_wedges != 6) {
        return 1;
    }
    fingerprint = record(fingerprint, &damaged_packet);

    struct Input timer_input = input(HUD_TIMER);
    struct Packet timer_packet = render_packet(
        project(timer_input, &power), 0, layout);
    if (timer_packet.count != 10
        || !command_equals(timer_packet.commands[0], COMMAND_GLYPH, 29, 170, 185)
        || !command_equals(timer_packet.commands[4], COMMAND_GLYPH, 1, 229, 185)
        || !command_equals(timer_packet.commands[8], COMMAND_GLYPH, 56, 239, 32)) {
        return 1;
    }
    fingerprint = record(fingerprint, &timer_packet);

    struct Layout japanese_layout = { 320, 240, 4.0 / 3.0, true };
    struct Packet japanese_packet = render_packet(full, 1, japanese_layout);
    bool japanese_star_found = false;
    for (uint32_t index = 0; index < japanese_packet.count; ++index) {
        japanese_star_found |= japanese_packet.commands[index].x == 247
            && japanese_packet.commands[index].y == 210;
    }
    if (!japanese_star_found) {
        return 1;
    }
    fingerprint = record(fingerprint, &japanese_packet);

    printf("hudRenderFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern HUD render C contract passed");
    return 0;
}
