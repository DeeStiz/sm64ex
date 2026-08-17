#include <stdint.h>
#include <stdio.h>

enum Screen { SCREEN_TITLE, SCREEN_FILE_SELECT, SCREEN_COURSE_SELECT, SCREEN_LEVEL_SELECT,
              SCREEN_DEMO, SCREEN_GAMEPLAY, SCREEN_CREDITS, SCREEN_ENDING };
enum Kind { KIND_TILE = 1, KIND_TITLE_MODEL = 2, KIND_TEXT = 3, KIND_CURSOR = 4, KIND_FADE = 5 };
enum TextID { TEXT_PRESS_START = 1, TEXT_SELECT_FILE, TEXT_SCORE, TEXT_COPY, TEXT_ERASE,
              TEXT_SOUND, TEXT_MARIO_A, TEXT_MARIO_B, TEXT_MARIO_C, TEXT_MARIO_D,
              TEXT_COURSE, TEXT_CREDITS, TEXT_ENDING, TEXT_DEMO };

struct Layout { int32_t width; int32_t height; double aspect; };
struct Command {
    enum Kind kind;
    uint16_t id;
    int32_t x;
    int32_t y;
    int32_t width;
    int32_t height;
    int32_t value;
    uint16_t alpha;
};
struct Packet {
    enum Screen screen;
    struct Layout layout;
    struct Command commands[128];
    int32_t count;
};

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (int shift = 0; shift <= 24; shift += 8) {
        hash ^= (uint64_t)((value >> shift) & 0xffu);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static void append(
    struct Packet *packet, enum Kind kind, uint16_t id, int32_t x, int32_t y,
    int32_t width, int32_t height, int32_t value, uint16_t alpha) {
    packet->commands[packet->count++] = (struct Command){ kind, id, x, y, width, height, value, alpha };
}

static void append_text(struct Packet *packet, enum TextID id, int32_t x, int32_t y) {
    append(packet, KIND_TEXT, (uint16_t)id, x, y, 0, 0, 0, 255);
}

static struct Packet project(enum Screen screen, int8_t selected_file, int16_t selected_course,
                             int16_t selected_level, int16_t zoom, int16_t fade, struct Layout layout) {
    struct Packet packet = { screen, layout, { 0 }, 0 };
    switch (screen) {
    case SCREEN_TITLE: {
        int32_t columns = (int32_t)(layout.aspect * (double)layout.height / 80.0);
        if ((double)columns < layout.aspect * (double)layout.height / 80.0) columns++;
        if (columns < 1) columns = 1;
        const int32_t origin_x = (int32_t)((double)layout.width / 2.0
            - layout.aspect * (double)layout.height / 2.0);
        for (int32_t index = 0; index < columns * 3; ++index) {
            append(&packet, KIND_TILE, (uint16_t)index,
                   origin_x + (index % columns) * 80,
                   (index / columns) * 80, 80, 80, 0, 255);
        }
        append(&packet, KIND_TITLE_MODEL, 0, 160, 120, 0, 0, zoom, 255);
        append_text(&packet, TEXT_PRESS_START, 160, 30);
        if (fade > 0) append(&packet, KIND_FADE, 0, 0, 0, 0, 0, 0, (uint16_t)fade);
        break;
    }
    case SCREEN_FILE_SELECT:
        append_text(&packet, TEXT_SELECT_FILE, 93, 35);
        append_text(&packet, TEXT_SCORE, 52, 39);
        append_text(&packet, TEXT_COPY, 117, 39);
        append_text(&packet, TEXT_ERASE, 177, 39);
        append_text(&packet, TEXT_SOUND, 235, 39);
        append_text(&packet, TEXT_MARIO_A, 92, 65);
        append_text(&packet, TEXT_MARIO_B, 207, 65);
        append_text(&packet, TEXT_MARIO_C, 92, 105);
        append_text(&packet, TEXT_MARIO_D, 207, 105);
        append(&packet, KIND_CURSOR, 0, 92, selected_file <= 2 ? 65 : 105, 16, 16, selected_file, 255);
        break;
    case SCREEN_COURSE_SELECT:
        append_text(&packet, TEXT_COURSE, 160, 35);
        append(&packet, KIND_CURSOR, 0, 160, 80 + (selected_course - 1) * 8, 16, 16, selected_course, 255);
        break;
    case SCREEN_LEVEL_SELECT:
        append_text(&packet, TEXT_COURSE, 160, 80);
        append(&packet, KIND_CURSOR, 0, 80, 60, 16, 16, selected_level, 255);
        break;
    case SCREEN_DEMO:
        append_text(&packet, TEXT_DEMO, 160, 30);
        break;
    case SCREEN_GAMEPLAY:
        break;
    case SCREEN_CREDITS:
        append_text(&packet, TEXT_CREDITS, 160, 120);
        break;
    case SCREEN_ENDING:
        append_text(&packet, TEXT_ENDING, 160, 120);
        break;
    }
    return packet;
}

static uint64_t hash_packet(uint64_t hash, const struct Packet *packet) {
    uint64_t value = hash;
    value = hash_u32(value, (uint32_t)packet->screen);
    value = hash_u32(value, (uint32_t)packet->layout.width);
    value = hash_u32(value, (uint32_t)packet->layout.height);
    value = hash_u32(value, (uint32_t)packet->count);
    for (int32_t index = 0; index < packet->count; ++index) {
        const struct Command command = packet->commands[index];
        value = hash_u32(value, (uint32_t)command.kind);
        value = hash_u32(value, command.id);
        value = hash_u32(value, (uint32_t)command.x);
        value = hash_u32(value, (uint32_t)command.y);
        value = hash_u32(value, (uint32_t)command.width);
        value = hash_u32(value, (uint32_t)command.height);
        value = hash_u32(value, (uint32_t)command.value);
        value = hash_u32(value, command.alpha);
    }
    return value;
}

int main(void) {
    const struct Layout layout = { 320, 240, 4.0 / 3.0 };
    const struct Packet title = project(SCREEN_TITLE, 1, 1, 1, 0, 0, layout);
    if (title.count != 14 || title.commands[0].x != 0 || title.commands[0].y != 0
        || title.commands[11].x != 240 || title.commands[11].y != 160
        || title.commands[12].kind != KIND_TITLE_MODEL || title.commands[13].id != TEXT_PRESS_START) return 1;
    const struct Layout wide_layout = { 1920, 1080, 16.0 / 9.0 };
    const struct Packet widescreen = project(SCREEN_TITLE, 1, 1, 1, 0, 0, wide_layout);
    if (widescreen.count != 74 || widescreen.commands[23].x != 1840) return 2;
    const struct Packet file = project(SCREEN_FILE_SELECT, 4, 1, 1, 0, 0, layout);
    if (file.count != 10 || file.commands[9].y != 105 || file.commands[9].value != 4) return 3;
    const struct Packet course = project(SCREEN_COURSE_SELECT, 4, 1, 1, 0, 0, layout);
    if (course.count != 2 || course.commands[0].id != TEXT_COURSE || course.commands[1].y != 80) return 4;
    const struct Packet demo = project(SCREEN_DEMO, 4, 15, 15, 0, 0, layout);
    if (demo.count != 1 || demo.commands[0].id != TEXT_DEMO) return 5;

    uint64_t fingerprint = UINT64_C(1469598103934665603);
    fingerprint = hash_packet(fingerprint, &title);
    fingerprint = hash_packet(fingerprint, &widescreen);
    fingerprint = hash_packet(fingerprint, &file);
    fingerprint = hash_packet(fingerprint, &course);
    fingerprint = hash_packet(fingerprint, &demo);
    printf("frontEndRenderFingerprint=0x%llx\n", (unsigned long long)fingerprint);
    printf("SM64 Modern front-end render C contract passed\n");
    return 0;
}
