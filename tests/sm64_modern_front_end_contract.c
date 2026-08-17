#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

enum Screen { SCREEN_TITLE, SCREEN_FILE_SELECT, SCREEN_COURSE_SELECT, SCREEN_LEVEL_SELECT,
              SCREEN_DEMO, SCREEN_GAMEPLAY, SCREEN_CREDITS, SCREEN_ENDING };
enum Transition { TRANSITION_NONE, TRANSITION_OPEN_FILE, TRANSITION_OPEN_COURSE,
                  TRANSITION_START_LEVEL, TRANSITION_OPEN_LEVEL, TRANSITION_START_DEMO,
                  TRANSITION_RETURN_TITLE, TRANSITION_OPEN_CREDITS, TRANSITION_OPEN_ENDING };

struct Intro {
    int16_t zoom_counter;
    int16_t fade_counter;
};

struct Demo {
    uint16_t idle_counter;
    uint8_t demo_index;
};

struct LevelSelect {
    int16_t minimum;
    int16_t maximum;
    int16_t level;
};

struct Input {
    bool advance_legacy_domain;
    bool start_pressed;
    bool confirm_pressed;
    bool back_pressed;
    bool has_activity;
    int16_t selection_delta;
    bool debug_level_select;
    bool demo_complete;
    bool credits_complete;
    bool ending_complete;
};

struct Result {
    enum Screen screen;
    enum Transition transition;
    int8_t selected_file;
    int16_t selected_course;
    int16_t selected_level;
    uint8_t demo_index;
    int16_t title_zoom_counter;
    int16_t title_fade_counter;
};

struct Model {
    enum Screen screen;
    int8_t selected_file;
    int16_t selected_course;
    int16_t selected_level;
    struct Intro title;
    struct Demo demo;
    struct LevelSelect level_select;
};

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (int shift = 0; shift <= 24; shift += 8) {
        hash ^= (uint64_t)((value >> shift) & 0xffu);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static int16_t wrap_value(int value, int lower, int upper) {
    const int span = upper - lower + 1;
    int normalized = (value - lower) % span;
    if (normalized < 0) normalized += span;
    return (int16_t)(lower + normalized);
}

static void intro_tick(struct Intro *intro, bool advance, bool rendered) {
    if (!rendered) {
        intro->zoom_counter = 0;
        intro->fade_counter = 0;
        return;
    }
    if (!advance) return;
    intro->zoom_counter++;
    if (intro->zoom_counter >= 0x13) {
        intro->fade_counter += 0x1A;
        if (intro->fade_counter >= 0xFF) intro->fade_counter = 0xFF;
    }
}

static bool demo_tick(struct Demo *demo, bool advance, bool activity, uint8_t demo_count) {
    if (!advance) return false;
    if (activity) {
        demo->idle_counter = 0;
        return false;
    }
    if (demo->idle_counter >= 800) return false;
    demo->idle_counter++;
    if (demo->idle_counter != 800) return false;
    if (demo_count > 0) demo->demo_index = (uint8_t)((demo->demo_index + 1) % demo_count);
    return demo_count > 0;
}

static void enter_title(struct Model *model) {
    model->screen = SCREEN_TITLE;
    model->title.zoom_counter = 0;
    model->title.fade_counter = 0;
    model->demo.idle_counter = 0;
}

static struct Result result(const struct Model *model, enum Transition transition) {
    return (struct Result){
        model->screen, transition, model->selected_file, model->selected_course,
        model->selected_level, model->demo.demo_index,
        model->title.zoom_counter, model->title.fade_counter
    };
}

static struct Result tick(struct Model *model, const struct Input *input, uint8_t demo_count) {
    if (!input->advance_legacy_domain) return result(model, TRANSITION_NONE);
    enum Transition transition = TRANSITION_NONE;
    switch (model->screen) {
    case SCREEN_TITLE:
        intro_tick(&model->title, true, true);
        if (input->start_pressed) {
            model->title.zoom_counter = 0;
            model->title.fade_counter = 0;
            model->demo.idle_counter = 0;
            if (input->debug_level_select) {
                model->screen = SCREEN_LEVEL_SELECT;
                transition = TRANSITION_OPEN_LEVEL;
            } else {
                model->screen = SCREEN_FILE_SELECT;
                transition = TRANSITION_OPEN_FILE;
            }
        } else if (demo_tick(&model->demo, true, input->has_activity, demo_count)) {
            model->title.zoom_counter = 0;
            model->title.fade_counter = 0;
            model->screen = SCREEN_DEMO;
            transition = TRANSITION_START_DEMO;
        }
        break;
    case SCREEN_FILE_SELECT:
        model->selected_file = (int8_t)wrap_value(model->selected_file + input->selection_delta, 1, 4);
        if (input->back_pressed) {
            enter_title(model);
            transition = TRANSITION_RETURN_TITLE;
        } else if (input->confirm_pressed) {
            model->screen = SCREEN_COURSE_SELECT;
            model->selected_course = 1;
            transition = TRANSITION_OPEN_COURSE;
        }
        break;
    case SCREEN_COURSE_SELECT:
        model->selected_course = wrap_value(model->selected_course + input->selection_delta, 1, 15);
        if (input->back_pressed) {
            model->screen = SCREEN_FILE_SELECT;
            transition = TRANSITION_OPEN_FILE;
        } else if (input->confirm_pressed) {
            model->selected_level = model->selected_course;
            model->screen = SCREEN_GAMEPLAY;
            transition = TRANSITION_START_LEVEL;
        }
        break;
    case SCREEN_LEVEL_SELECT:
        model->level_select.level = wrap_value(
            model->level_select.level + input->selection_delta,
            model->level_select.minimum, model->level_select.maximum);
        model->selected_level = model->level_select.level;
        if (input->back_pressed) {
            enter_title(model);
            transition = TRANSITION_RETURN_TITLE;
        } else if (input->start_pressed || input->confirm_pressed) {
            model->screen = SCREEN_GAMEPLAY;
            transition = TRANSITION_START_LEVEL;
        }
        break;
    case SCREEN_DEMO:
        if (input->demo_complete) {
            enter_title(model);
            transition = TRANSITION_RETURN_TITLE;
        }
        break;
    case SCREEN_GAMEPLAY:
        if (input->credits_complete) {
            model->screen = SCREEN_CREDITS;
            transition = TRANSITION_OPEN_CREDITS;
        } else if (input->ending_complete) {
            model->screen = SCREEN_ENDING;
            transition = TRANSITION_OPEN_ENDING;
        }
        break;
    case SCREEN_CREDITS:
        if (input->credits_complete) {
            enter_title(model);
            transition = TRANSITION_RETURN_TITLE;
        }
        break;
    case SCREEN_ENDING:
        if (input->ending_complete) {
            enter_title(model);
            transition = TRANSITION_RETURN_TITLE;
        }
        break;
    }
    return result(model, transition);
}

static uint64_t hash_result(uint64_t hash, const struct Result *result_value) {
    uint64_t value = hash;
    value = hash_u32(value, (uint32_t)result_value->screen);
    value = hash_u32(value, (uint32_t)result_value->transition);
    value = hash_u32(value, (uint32_t)(int32_t)result_value->selected_file);
    value = hash_u32(value, (uint32_t)(int32_t)result_value->selected_course);
    value = hash_u32(value, (uint32_t)(int32_t)result_value->selected_level);
    value = hash_u32(value, result_value->demo_index);
    value = hash_u32(value, (uint32_t)(int32_t)result_value->title_zoom_counter);
    value = hash_u32(value, (uint32_t)(int32_t)result_value->title_fade_counter);
    return value;
}

int main(void) {
    struct Intro intro = { 0, 0 };
    for (int index = 0; index < 20; ++index) intro_tick(&intro, true, true);
    if (intro.zoom_counter != 20 || intro.fade_counter != 52) return 1;
    const int16_t frozen_zoom = intro.zoom_counter;
    intro_tick(&intro, false, true);
    if (intro.zoom_counter != frozen_zoom) return 2;

    struct Model model = {
        SCREEN_TITLE, 1, 1, 1, { 0, 0 }, { 0, 0 }, { 1, 64, 1 }
    };
    uint64_t fingerprint = UINT64_C(1469598103934665603);
    const struct Input idle_input = { true, false, false, false, false, 0, false, false, false, false };
    struct Result result_value = tick(&model, &idle_input, 8);
    if (result_value.screen != SCREEN_TITLE || result_value.title_zoom_counter != 1) return 3;
    fingerprint = hash_result(fingerprint, &result_value);
    for (int index = 0; index < 799; ++index) result_value = tick(&model, &idle_input, 8);
    if (result_value.screen != SCREEN_DEMO || result_value.transition != TRANSITION_START_DEMO
        || result_value.demo_index != 1) return 4;
    fingerprint = hash_result(fingerprint, &result_value);

    enter_title(&model);
    const struct Input start_input = { true, true, false, false, false, 0, false, false, false, false };
    result_value = tick(&model, &start_input, 8);
    if (result_value.screen != SCREEN_FILE_SELECT || result_value.transition != TRANSITION_OPEN_FILE) return 5;
    fingerprint = hash_result(fingerprint, &result_value);
    const struct Input file_back_input = { true, false, false, false, false, -1, false, false, false, false };
    result_value = tick(&model, &file_back_input, 8);
    if (result_value.selected_file != 4) return 6;
    const struct Input confirm_input = { true, false, true, false, false, 0, false, false, false, false };
    result_value = tick(&model, &confirm_input, 8);
    if (result_value.screen != SCREEN_COURSE_SELECT || result_value.selected_course != 1) return 7;
    fingerprint = hash_result(fingerprint, &result_value);
    result_value = tick(&model, &file_back_input, 8);
    if (result_value.selected_course != 15) return 8;
    result_value = tick(&model, &confirm_input, 8);
    if (result_value.screen != SCREEN_GAMEPLAY || result_value.selected_level != 15) return 9;
    fingerprint = hash_result(fingerprint, &result_value);

    const struct Input credits_input = { true, false, false, false, false, 0, false, false, true, false };
    result_value = tick(&model, &credits_input, 8);
    if (result_value.screen != SCREEN_CREDITS || result_value.transition != TRANSITION_OPEN_CREDITS) return 10;
    result_value = tick(&model, &credits_input, 8);
    if (result_value.screen != SCREEN_TITLE || result_value.transition != TRANSITION_RETURN_TITLE) return 11;
    fingerprint = hash_result(fingerprint, &result_value);

    const struct Input debug_start_input = { true, true, false, false, false, 0, true, false, false, false };
    result_value = tick(&model, &debug_start_input, 8);
    if (result_value.screen != SCREEN_LEVEL_SELECT || result_value.transition != TRANSITION_OPEN_LEVEL) return 12;
    result_value = tick(&model, &file_back_input, 8);
    if (result_value.selected_level != 64) return 13;
    result_value = tick(&model, &start_input, 8);
    if (result_value.screen != SCREEN_GAMEPLAY || result_value.selected_level != 64) return 14;
    fingerprint = hash_result(fingerprint, &result_value);

    const struct Input frozen_input = { false, false, false, false, false, 1, false, false, false, false };
    result_value = tick(&model, &frozen_input, 8);
    if (result_value.screen != SCREEN_GAMEPLAY || result_value.selected_file != 4
        || result_value.selected_course != 15 || result_value.selected_level != 64
        || result_value.demo_index != 1 || result_value.title_zoom_counter != 0
        || result_value.title_fade_counter != 0 || result_value.transition != TRANSITION_NONE) return 15;
    fingerprint = hash_result(fingerprint, &result_value);

    printf("frontEndFingerprint=0x%llx\n", (unsigned long long)fingerprint);
    printf("SM64 Modern front-end C contract passed\n");
    return 0;
}
