#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

enum DialogState { DIALOG_OPENING, DIALOG_VERTICAL, DIALOG_HORIZONTAL, DIALOG_CLOSING };
enum PageState { PAGE_NONE, PAGE_SCROLL, PAGE_END };
enum PauseState { PAUSE_OPENING, PAUSE_VERTICAL, PAUSE_HORIZONTAL };
enum CameraSelection { CAMERA_MARIO = 1, CAMERA_FIXED = 2 };
enum PauseOutcome { OUTCOME_NONE, OUTCOME_RESUME, OUTCOME_EXIT_COURSE };

struct Glyph {
    uint8_t glyph;
    int16_t x;
    int8_t line;
    int32_t source_position;
};

struct TextInput {
    uint8_t bytes[64];
    int32_t count;
    int32_t start_position;
    int8_t lines_per_box;
    enum DialogState box_state;
    int16_t scroll_offset_y;
    int8_t lower_bound;
    bool has_lower_bound;
    int16_t dialog_variable;
    uint8_t widths[256];
};

struct TextLayout {
    struct Glyph glyphs[64];
    int32_t glyph_count;
    enum PageState page_state;
    int32_t page_string_position;
    int32_t cursor_position;
    int8_t last_line;
    int8_t lower_bound;
};

struct PauseInput {
    bool advance_legacy_domain;
    bool confirm_pressed;
    int8_t vertical_selection_delta;
    int8_t horizontal_camera_delta;
    int16_t course_number;
    int16_t course_minimum;
    int16_t course_maximum;
    bool can_exit_course;
    enum CameraSelection current_camera_selection;
};

struct PauseResult {
    enum PauseState state;
    int8_t selection;
    enum CameraSelection camera_selection;
    uint16_t text_alpha;
    bool menu_mode_active;
    enum PauseOutcome outcome;
    bool camera_changed;
};

struct PauseModel {
    enum PauseState state;
    int8_t selection;
    enum CameraSelection camera_selection;
    uint16_t text_alpha;
    bool menu_mode_active;
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

static int16_t width_for(const struct TextInput *input, uint8_t glyph) {
    return input->widths[glyph];
}

static bool visible(int8_t line, int8_t lower_bound, int line_limit) {
    return line >= lower_bound && line <= lower_bound + line_limit;
}

static uint8_t ascii_to_dialog(char character) {
    if (character >= '0' && character <= '9') return (uint8_t)(character - '0');
    if (character >= 'A' && character <= 'Z') return (uint8_t)(character - 'A' + 0x0A);
    if (character >= 'a' && character <= 'z') return (uint8_t)(character - 'a' + 0x24);
    return 0;
}

static void append_glyph(
    struct TextLayout *layout, uint8_t glyph, int16_t x, int8_t line, int32_t source_position) {
    if (layout->glyph_count >= (int32_t)(sizeof(layout->glyphs) / sizeof(layout->glyphs[0]))) return;
    layout->glyphs[layout->glyph_count++] = (struct Glyph){ glyph, x, line, source_position };
}

static void apply_pending_space(
    int16_t *x_matrix, int16_t line_position, int16_t *cursor_x, int16_t space_width) {
    if (line_position != 0 || *x_matrix != 1)
        *cursor_x += (int16_t)(space_width * (*x_matrix - 1));
}

static struct TextLayout project_text(const struct TextInput *input) {
    struct TextLayout layout = { 0 };
    const int line_limit = input->lines_per_box < 0 ? 0 : input->lines_per_box;
    const int total_lines = input->box_state == DIALOG_HORIZONTAL
        ? line_limit * 2 + 1 : line_limit + 1;
    const int8_t derived_lower_bound = input->box_state == DIALOG_HORIZONTAL
        ? (int8_t)(input->scroll_offset_y / 16 + 1) : 1;
    const int8_t lower_bound = input->has_lower_bound
        ? (input->lower_bound < 1 ? 1 : input->lower_bound)
        : derived_lower_bound;
    int32_t str_index = input->start_position;
    if (str_index < 0) str_index = 0;
    if (str_index > input->count) str_index = input->count;
    int8_t line_number = 1;
    int16_t x_matrix = 1;
    int16_t line_position = 0;
    int16_t cursor_x = 0;
    enum PageState page_state = PAGE_NONE;
    int32_t page_string_position = 0;

    while (page_state == PAGE_NONE) {
        if (str_index >= input->count) {
            page_state = PAGE_END;
            page_string_position = -1;
            break;
        }
        const uint8_t character = input->bytes[str_index];
        switch (character) {
        case 0xFF:
            page_state = PAGE_END;
            page_string_position = -1;
            break;
        case 0xFE:
            line_number++;
            if (line_number == total_lines) {
                page_state = PAGE_SCROLL;
                str_index++;
                page_string_position = str_index;
                continue;
            }
            line_position = 0;
            x_matrix = 1;
            cursor_x = 0;
            break;
        case 0x9E:
            x_matrix++;
            line_position++;
            break;
        case 0xD0:
            x_matrix += 2;
            line_position += 2;
            break;
        case 0xD1:
        case 0xD2: {
            const uint8_t expansion[3] = {
                character == 0xD1 ? ascii_to_dialog('t') : ascii_to_dialog('y'),
                character == 0xD1 ? ascii_to_dialog('h') : ascii_to_dialog('o'),
                character == 0xD1 ? ascii_to_dialog('e') : ascii_to_dialog('u'),
            };
            if (visible(line_number, lower_bound, line_limit)) {
                apply_pending_space(&x_matrix, line_position, &cursor_x, width_for(input, 0x9E));
                for (size_t index = 0; index < 3; ++index) {
                    append_glyph(&layout, expansion[index], cursor_x, line_number, str_index);
                    cursor_x += width_for(input, expansion[index]);
                }
                x_matrix = 1;
                line_position += 3;
            } else {
                line_position += 3;
            }
            break;
        }
        case 0xE0: {
            const int value = input->dialog_variable > 99 ? 99 : input->dialog_variable;
            const uint8_t expansion[2] = { (uint8_t)(value / 10), (uint8_t)(value % 10) };
            const int count = value >= 10 ? 2 : 1;
            if (visible(line_number, lower_bound, line_limit)) {
                apply_pending_space(&x_matrix, line_position, &cursor_x, width_for(input, 0x9E));
                for (int index = count == 2 ? 0 : 1; index < 2; ++index) {
                    append_glyph(&layout, expansion[index], cursor_x, line_number, str_index);
                    cursor_x += width_for(input, expansion[index]);
                }
                x_matrix = 1;
                line_position += (int16_t)count;
            } else {
                line_position += (int16_t)count;
            }
            break;
        }
        default:
            if (visible(line_number, lower_bound, line_limit)) {
                apply_pending_space(&x_matrix, line_position, &cursor_x, width_for(input, 0x9E));
                append_glyph(&layout, character, cursor_x, line_number, str_index);
                cursor_x += width_for(input, character);
                x_matrix = 1;
                line_position++;
            }
            break;
        }
        str_index++;
    }
    if (page_state == PAGE_END) page_string_position = -1;
    layout.page_state = page_state;
    layout.page_string_position = page_string_position;
    layout.cursor_position = str_index;
    layout.last_line = line_number;
    layout.lower_bound = lower_bound;
    return layout;
}

static enum CameraSelection clamp_camera(enum CameraSelection value, int8_t delta) {
    int next = (int)value + delta;
    if (next < CAMERA_MARIO) next = CAMERA_MARIO;
    if (next > CAMERA_FIXED) next = CAMERA_FIXED;
    return (enum CameraSelection)next;
}

static struct PauseResult pause_tick(struct PauseModel *model, const struct PauseInput *input) {
    struct PauseResult result = {
        model->state, model->selection, model->camera_selection, model->text_alpha,
        model->menu_mode_active, OUTCOME_NONE, false
    };
    if (!input->advance_legacy_domain) return result;

    switch (model->state) {
    case PAUSE_OPENING:
        model->text_alpha = 0;
        model->menu_mode_active = true;
        model->selection = 1;
        model->camera_selection = input->current_camera_selection;
        if (input->course_number >= input->course_minimum
            && input->course_number <= input->course_maximum) {
            model->state = PAUSE_VERTICAL;
        } else {
            model->state = PAUSE_HORIZONTAL;
        }
        break;
    case PAUSE_VERTICAL:
        if (input->can_exit_course) {
            int next = model->selection + input->vertical_selection_delta;
            if (next < 1) next = 1;
            if (next > 3) next = 3;
            model->selection = (int8_t)next;
            if (model->selection == 3) {
                const enum CameraSelection next_camera = clamp_camera(
                    model->camera_selection, input->horizontal_camera_delta);
                result.camera_changed = next_camera != model->camera_selection;
                model->camera_selection = next_camera;
            }
        } else {
            model->selection = 1;
        }
        if (input->confirm_pressed) {
            result.outcome = model->selection == 2 ? OUTCOME_EXIT_COURSE : OUTCOME_RESUME;
            model->state = PAUSE_OPENING;
            model->menu_mode_active = false;
        }
        break;
    case PAUSE_HORIZONTAL: {
        const enum CameraSelection next_camera = clamp_camera(
            model->camera_selection, input->horizontal_camera_delta);
        result.camera_changed = next_camera != model->camera_selection;
        model->camera_selection = next_camera;
        if (input->confirm_pressed) {
            result.outcome = OUTCOME_RESUME;
            model->state = PAUSE_OPENING;
            model->menu_mode_active = false;
        }
        break;
    }
    }
    model->text_alpha = (uint16_t)(model->text_alpha + 25 > 250 ? 250 : model->text_alpha + 25);
    result.state = model->state;
    result.selection = model->selection;
    result.camera_selection = model->camera_selection;
    result.text_alpha = model->text_alpha;
    result.menu_mode_active = model->menu_mode_active;
    return result;
}

static uint64_t hash_layout(uint64_t hash, const struct TextLayout *layout) {
    uint64_t result = hash;
    result = hash_u32(result, (uint32_t)layout->glyph_count);
    for (int32_t index = 0; index < layout->glyph_count; ++index) {
        const struct Glyph glyph = layout->glyphs[index];
        result = hash_u32(result, glyph.glyph);
        result = hash_u32(result, (uint32_t)(int32_t)glyph.x);
        result = hash_u32(result, (uint32_t)(int32_t)glyph.line);
        result = hash_u32(result, (uint32_t)glyph.source_position);
    }
    result = hash_u32(result, (uint32_t)layout->page_state);
    result = hash_u32(result, (uint32_t)layout->page_string_position);
    result = hash_u32(result, (uint32_t)layout->cursor_position);
    result = hash_u32(result, (uint32_t)(int32_t)layout->last_line);
    result = hash_u32(result, (uint32_t)(int32_t)layout->lower_bound);
    return result;
}

static uint64_t hash_pause(uint64_t hash, const struct PauseResult *result) {
    uint64_t value = hash;
    value = hash_u32(value, (uint32_t)result->state);
    value = hash_u32(value, (uint32_t)(int32_t)result->selection);
    value = hash_u32(value, (uint32_t)(int32_t)result->camera_selection);
    value = hash_u32(value, result->text_alpha);
    value = hash_bool(value, result->menu_mode_active);
    value = hash_u32(value, (uint32_t)(int32_t)result->outcome);
    value = hash_bool(value, result->camera_changed);
    return value;
}

static void initialize_input(struct TextInput *input, const uint8_t *bytes, int32_t count) {
    memset(input, 0, sizeof(*input));
    memcpy(input->bytes, bytes, (size_t)count);
    input->count = count;
    input->lines_per_box = 2;
    input->box_state = DIALOG_VERTICAL;
    input->widths[0x9E] = 5;
    for (int index = 0; index < 10; ++index) input->widths[index] = 7;
    const uint8_t uppercase[26] = { 6, 6, 6, 6, 6, 6, 6, 6, 5, 6, 6, 5, 8, 8, 6, 6, 6, 6, 6, 5, 6, 6, 8, 7, 6, 6 };
    const uint8_t lowercase[26] = { 6, 6, 6, 5, 5, 6, 5, 5, 6, 5, 4, 5, 5, 3, 7, 5, 5, 5, 6, 5, 5, 5, 5, 5, 7, 7 };
    memcpy(input->widths + 0x0A, uppercase, sizeof(uppercase));
    memcpy(input->widths + 0x24, lowercase, sizeof(lowercase));
}

int main(void) {
    static const uint8_t bytes[] = { 0x0A, 0x9E, 0x0B, 0xFE, 0xD1, 0xFE, 0x0C, 0xD0, 0x0D, 0xFE, 0xFF };
    struct TextInput first_input;
    initialize_input(&first_input, bytes, (int32_t)sizeof(bytes));
    struct TextLayout first_page = project_text(&first_input);
    if (first_page.page_state != PAGE_SCROLL || first_page.page_string_position != 6
        || first_page.glyph_count != 5 || first_page.glyphs[0].glyph != 0x0A
        || first_page.glyphs[0].x != 0 || first_page.glyphs[1].x != 11
        || first_page.glyphs[2].line != 2 || first_page.last_line != 3) return 1;

    struct TextInput second_input;
    initialize_input(&second_input, bytes, (int32_t)sizeof(bytes));
    second_input.start_position = first_page.page_string_position;
    second_input.box_state = DIALOG_HORIZONTAL;
    second_input.scroll_offset_y = 16;
    struct TextLayout second_page = project_text(&second_input);
    if (second_page.lower_bound != 2 || second_page.page_state != PAGE_END
        || second_page.page_string_position != -1) return 2;
    for (int32_t index = 0; index < second_page.glyph_count; ++index)
        if (second_page.glyphs[index].line < 2) return 3;

    struct TextInput stars_input;
    initialize_input(&stars_input, (const uint8_t[]){ 0x9E, 0xE0, 0xFF }, 3);
    stars_input.dialog_variable = 42;
    struct TextLayout stars = project_text(&stars_input);
    if (stars.glyph_count != 2 || stars.glyphs[0].glyph != 4 || stars.glyphs[1].glyph != 2
        || stars.glyphs[0].x != 5 || stars.glyphs[1].x != 12) return 4;

    uint64_t fingerprint = UINT64_C(1469598103934665603);
    fingerprint = hash_layout(fingerprint, &first_page);
    fingerprint = hash_layout(fingerprint, &second_page);
    fingerprint = hash_layout(fingerprint, &stars);

    struct PauseModel pause = { PAUSE_OPENING, 1, CAMERA_MARIO, 0, true };
    const struct PauseInput open_input = { true, false, 0, 0, 1, 1, 15, false, CAMERA_MARIO };
    const struct PauseResult opened = pause_tick(&pause, &open_input);
    if (opened.state != PAUSE_VERTICAL || opened.text_alpha != 25) return 5;
    const struct PauseInput camera_input = { true, false, 2, 1, 1, 1, 15, true, CAMERA_MARIO };
    const struct PauseResult camera_row = pause_tick(&pause, &camera_input);
    if (camera_row.selection != 3 || camera_row.camera_selection != CAMERA_FIXED
        || !camera_row.camera_changed) return 6;
    const struct PauseInput resume_input = { true, true, 0, 0, 1, 1, 15, true, CAMERA_MARIO };
    const struct PauseResult resumed = pause_tick(&pause, &resume_input);
    if (resumed.outcome != OUTCOME_RESUME || resumed.state != PAUSE_OPENING) return 7;
    fingerprint = hash_pause(fingerprint, &opened);
    fingerprint = hash_pause(fingerprint, &camera_row);
    fingerprint = hash_pause(fingerprint, &resumed);

    struct PauseModel exit_pause = { PAUSE_OPENING, 1, CAMERA_MARIO, 0, true };
    (void)pause_tick(&exit_pause, &open_input);
    const struct PauseInput exit_select_input = { true, false, 1, 0, 1, 1, 15, true, CAMERA_MARIO };
    (void)pause_tick(&exit_pause, &exit_select_input);
    const struct PauseResult exited = pause_tick(&exit_pause, &resume_input);
    if (exited.outcome != OUTCOME_EXIT_COURSE) return 8;
    fingerprint = hash_pause(fingerprint, &exited);

    const struct PauseInput frozen_input = { false, false, 0, 0, 1, 1, 15, false, CAMERA_MARIO };
    const struct PauseResult frozen = pause_tick(&exit_pause, &frozen_input);
    if (frozen.state != PAUSE_OPENING || frozen.selection != 2 || frozen.text_alpha != 75
        || frozen.menu_mode_active || frozen.outcome != OUTCOME_NONE || frozen.camera_changed) return 9;
    fingerprint = hash_pause(fingerprint, &frozen);

    printf("dialogTextPauseFingerprint=0x%llx\n", (unsigned long long)fingerprint);
    printf("SM64 Modern dialog text/pause C contract passed\n");
    return 0;
}
