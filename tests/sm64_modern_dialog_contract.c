#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

enum DialogState {
    DIALOG_OPENING,
    DIALOG_VERTICAL,
    DIALOG_HORIZONTAL,
    DIALOG_CLOSING,
};

enum DialogType {
    DIALOG_ROTATE,
    DIALOG_ZOOM,
};

struct DialogEffects {
    bool appearance_sound;
    bool next_page_sound;
    bool disappear_sound;
    bool response_changed;
};

struct DialogStateValue {
    enum DialogState state;
    enum DialogType type;
    int32_t open_timer_half;
    int32_t scale_half;
    int16_t scroll_offset_y;
    int16_t dialog_id;
    int16_t text_position;
    int8_t line_number;
    int8_t last_dialog_response;
    int32_t dialog_response;
};

struct DialogInput {
    bool advance_legacy;
    bool a_pressed;
    bool b_pressed;
    int16_t last_page_position;
    int16_t lines_per_box;
};

struct DialogResult {
    struct DialogStateValue state;
    int16_t lower_bound;
    struct DialogEffects effects;
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

static struct DialogResult result(
    struct DialogStateValue state, struct DialogEffects effects) {
    return (struct DialogResult){
        .state = state,
        .lower_bound = state.state == DIALOG_HORIZONTAL
            ? (int16_t)(state.scroll_offset_y / 16 + 1) : 1,
        .effects = effects,
    };
}

static struct DialogStateValue create_dialog(
    struct DialogStateValue state, int16_t dialog_id,
    enum DialogType type, bool with_response) {
    if (state.dialog_id == -1) {
        state.dialog_id = dialog_id;
        state.type = type;
        if (with_response) state.last_dialog_response = 1;
    }
    return state;
}

static struct DialogResult tick(
    struct DialogStateValue state, struct DialogInput input,
    struct DialogStateValue *out_state) {
    struct DialogEffects effects = { 0 };
    if (state.dialog_id == -1) {
        *out_state = state;
        return result(state, effects);
    }
    if (input.advance_legacy) {
        switch (state.state) {
        case DIALOG_OPENING:
            if (state.open_timer_half == 180)
                effects.appearance_sound = true;
            if (state.type == DIALOG_ROTATE) {
                state.open_timer_half -= 15;
                state.scale_half -= 3;
            } else {
                state.open_timer_half -= 20;
                state.scale_half -= 4;
            }
            if (state.open_timer_half < 0) state.open_timer_half = 0;
            if (state.scale_half < 0) state.scale_half = 0;
            if (state.open_timer_half == 0) {
                state.state = DIALOG_VERTICAL;
                state.line_number = 1;
            }
            break;
        case DIALOG_VERTICAL:
            state.open_timer_half = 0;
            if (input.a_pressed || input.b_pressed) {
                if (input.last_page_position == -1) {
                    state.state = DIALOG_CLOSING;
                } else {
                    state.state = DIALOG_HORIZONTAL;
                    effects.next_page_sound = true;
                }
            }
            break;
        case DIALOG_HORIZONTAL:
            state.scroll_offset_y += input.lines_per_box * 2;
            if (state.scroll_offset_y >= input.lines_per_box * 16) {
                state.text_position = input.last_page_position;
                state.state = DIALOG_VERTICAL;
                state.scroll_offset_y = 0;
            }
            break;
        case DIALOG_CLOSING:
            if (state.open_timer_half == 40) {
                effects.disappear_sound = true;
                effects.response_changed = true;
                state.dialog_response = state.line_number;
            }
            state.open_timer_half += 20;
            state.scale_half += 4;
            if (state.open_timer_half >= 180) {
                state.open_timer_half = 180;
                state.scale_half = 38;
                state.state = DIALOG_OPENING;
                state.dialog_id = -1;
                state.text_position = 0;
                state.last_dialog_response = 0;
                state.dialog_response = 0;
            }
            break;
        }
    }
    *out_state = state;
    return result(state, effects);
}

static uint64_t record(uint64_t hash, struct DialogResult value) {
    struct DialogStateValue state = value.state;
    hash = hash_u32(hash, (uint32_t)state.state);
    hash = hash_u32(hash, (uint32_t)state.type);
    hash = hash_u32(hash, (uint32_t)state.open_timer_half);
    hash = hash_u32(hash, (uint32_t)state.scale_half);
    hash = hash_u32(hash, (uint32_t)(int32_t)state.scroll_offset_y);
    hash = hash_u32(hash, (uint32_t)(int32_t)state.dialog_id);
    hash = hash_u32(hash, (uint32_t)(int32_t)state.text_position);
    hash = hash_u32(hash, (uint32_t)(int32_t)state.line_number);
    hash = hash_u32(hash, (uint32_t)(int32_t)state.last_dialog_response);
    hash = hash_u32(hash, (uint32_t)state.dialog_response);
    hash = hash_u32(hash, (uint32_t)(int32_t)value.lower_bound);
    hash = hash_bool(hash, value.effects.appearance_sound);
    hash = hash_bool(hash, value.effects.next_page_sound);
    hash = hash_bool(hash, value.effects.disappear_sound);
    return hash_bool(hash, value.effects.response_changed);
}

int main(void) {
    struct DialogStateValue state = {
        DIALOG_OPENING, DIALOG_ROTATE, 180, 38, 0, -1, 0, 1, 0, 0
    };
    uint64_t fingerprint = UINT64_C(1469598103934665603);
    state = create_dialog(state, 42, DIALOG_ROTATE, true);
    struct DialogInput input = { true, false, false, 0, 2 };
    struct DialogStateValue next;
    struct DialogResult opening = tick(state, input, &next);
    state = next;
    if (!opening.effects.appearance_sound || state.open_timer_half != 165)
        return 1;
    fingerprint = record(fingerprint, opening);
    for (int i = 0; i < 11; ++i) {
        struct DialogResult value = tick(state, input, &next);
        state = next;
        fingerprint = record(fingerprint, value);
    }
    if (state.state != DIALOG_VERTICAL || state.open_timer_half != 0)
        return 1;

    input.a_pressed = true;
    input.last_page_position = 12;
    struct DialogResult next_page = tick(state, input, &next);
    state = next;
    if (state.state != DIALOG_HORIZONTAL || !next_page.effects.next_page_sound)
        return 1;
    fingerprint = record(fingerprint, next_page);
    input.a_pressed = false;
    for (int i = 0; i < 7; ++i) {
        struct DialogResult value = tick(state, input, &next);
        state = next;
        if (state.state != DIALOG_HORIZONTAL) return 1;
        fingerprint = record(fingerprint, value);
    }
    struct DialogResult page_done = tick(state, input, &next);
    state = next;
    if (state.state != DIALOG_VERTICAL || state.text_position != 12
        || state.scroll_offset_y != 0)
        return 1;
    fingerprint = record(fingerprint, page_done);

    input.a_pressed = true;
    input.last_page_position = -1;
    struct DialogResult close_start = tick(state, input, &next);
    state = next;
    if (state.state != DIALOG_CLOSING) return 1;
    fingerprint = record(fingerprint, close_start);
    input.a_pressed = false;
    (void)tick(state, input, &next);
    state = next;
    (void)tick(state, input, &next);
    state = next;
    struct DialogResult close_event = tick(state, input, &next);
    state = next;
    if (!close_event.effects.disappear_sound
        || !close_event.effects.response_changed
        || state.dialog_response != 1)
        return 1;
    fingerprint = record(fingerprint, close_event);
    for (int i = 0; i < 5; ++i) {
        struct DialogResult value = tick(state, input, &next);
        state = next;
        fingerprint = record(fingerprint, value);
    }
    struct DialogResult closed = tick(state, input, &next);
    state = next;
    if (state.dialog_id != -1 || state.state != DIALOG_OPENING)
        return 1;
    fingerprint = record(fingerprint, closed);

    state = create_dialog(state, 7, DIALOG_ZOOM, false);
    input.advance_legacy = false;
    struct DialogResult paused = tick(state, input, &next);
    state = next;
    if (state.open_timer_half != 180
        || paused.effects.appearance_sound || paused.effects.next_page_sound
        || paused.effects.disappear_sound || paused.effects.response_changed)
        return 1;
    fingerprint = record(fingerprint, paused);
    printf("dialogFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern dialog C contract passed");
    return 0;
}
