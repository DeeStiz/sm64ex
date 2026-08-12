/*
 * M8c world-cadence contract smoke.
 *
 * This is intentionally a private, C-only model test.  It does not inspect
 * engine object graphs and it does not change the public parity ABI.  Legacy
 * script/event state is compared at paired boundaries, while a compact
 * fixed-point dynamics model advances on both native steps.  The latter
 * covers Mario/actor/platform motion, collision lifetime, camera following,
 * particles, painting ripple, and environmental motion without pretending to
 * be live full-engine acceptance.
 *
 * The timebase uses the first-step boundary policy: with a 60/30 cadence the
 * first admitted native step closes the logical interval (pair phase 1), and
 * the second step is held (pair phase 0).  Host input arriving on a held step
 * is latched for the next logical boundary.
 */

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "sm64_modern.h"
#include "pc/sm64_modern_timebase.h"

#define LOGICAL_INTERVAL_COUNT 12u
#define MAX_EVENTS_PER_INTERVAL 64u
#define ANIMATION_FIXED_STEP UINT32_C(0x00018001) /* 1.500015625 frames */

enum WorldCadenceEventKind {
    WORLD_EVENT_INPUT_EDGE = 1,
    WORLD_EVENT_SCRIPT_SLEEP,
    WORLD_EVENT_SCRIPT_WAKE,
    WORLD_EVENT_ACTION_RESET,
    WORLD_EVENT_RNG_DRAW,
    WORLD_EVENT_INTEGER_ANIMATION,
    WORLD_EVENT_FIXED_ANIMATION,
    WORLD_EVENT_TRANSITION_BEGIN,
    WORLD_EVENT_TRANSITION_END,
    WORLD_EVENT_HUD_COUNTER,
    WORLD_EVENT_MENU_COUNTER,
    WORLD_EVENT_TIME_STOP,
};

typedef struct {
    bool input_edge;
    bool time_stop;
    bool transition_start;
} HostControls;

typedef struct {
    uint16_t script_delay;
    uint16_t object_timer;
    uint16_t action_timer;
    uint16_t action;
    uint16_t previous_action;
    uint16_t random_seed;
    uint32_t random_draw_ordinal;
    uint16_t integer_animation_frame;
    uint32_t fixed_animation_position;
    uint32_t fixed_animation_step;
    uint16_t transition_timer;
    uint16_t hud_timer;
    uint16_t menu_counter;
    bool menu_open;
    bool transition_active;
    bool hud_timer_running;
    uint32_t mario_position;
    uint32_t actor_position;
    uint32_t platform_position;
    uint32_t camera_position;
    uint32_t painting_ripple;
    uint32_t environmental_motion;
    uint32_t collision_passes;
    uint32_t particle_updates;
    uint16_t intangible_timer;
} WorldCadenceState;

typedef struct {
    bool input_latched;
    bool time_stop_latched;
    bool transition_latched;
} WorldCadenceLatches;

typedef struct {
    uint16_t kind;
    uint16_t ordinal;
    uint32_t first;
    uint32_t second;
    uint32_t third;
} WorldCadenceEvent;

typedef struct {
    WorldCadenceState state;
    WorldCadenceLatches latches;
    WorldCadenceEvent events[MAX_EVENTS_PER_INTERVAL];
    uint32_t event_count;
    bool event_overflow;
} WorldCadenceModel;

typedef struct {
    WorldCadenceState state;
    WorldCadenceLatches latches;
    WorldCadenceEvent events[MAX_EVENTS_PER_INTERVAL];
    uint32_t event_count;
} WorldCadenceTrace;

static int failures;

static void failf(const char *operation, uint32_t interval, const char *detail) {
    fprintf(stderr, "world cadence: interval %u: %s (%s)\n",
            interval,
            operation,
            detail);
    failures++;
}

static void expect_status(const char *operation,
                          SM64ModernStatus actual,
                          SM64ModernStatus expected) {
    if (actual != expected) {
        fprintf(stderr, "world cadence: %s: expected status %u, got %u\n",
                operation,
                (unsigned) expected,
                (unsigned) actual);
        failures++;
    }
}

static void expect_u64(const char *operation, uint64_t actual, uint64_t expected) {
    if (actual != expected) {
        fprintf(stderr, "world cadence: %s: expected %llu, got %llu\n",
                operation,
                (unsigned long long) expected,
                (unsigned long long) actual);
        failures++;
    }
}

static SM64ModernTimebaseConfigV1 make_timebase_config(uint32_t simulation_numerator,
                                                        uint32_t simulation_denominator,
                                                        uint32_t legacy_numerator,
                                                        uint32_t legacy_denominator) {
    SM64ModernTimebaseConfigV1 config;
    memset(&config, 0, sizeof(config));
    config.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    config.header.struct_size = sizeof(config);
    config.simulation_rate_numerator = simulation_numerator;
    config.simulation_rate_denominator = simulation_denominator;
    config.legacy_rate_numerator = legacy_numerator;
    config.legacy_rate_denominator = legacy_denominator;
    config.max_catch_up_steps = 2u;
    return config;
}

static bool configure_timebase(const SM64ModernTimebaseApiV1 *timebase,
                               uint32_t simulation_numerator,
                               uint32_t simulation_denominator,
                               uint32_t legacy_numerator,
                               uint32_t legacy_denominator,
                               uint32_t expected_pair) {
    SM64ModernTimebaseConfigV1 config = make_timebase_config(simulation_numerator,
                                                              simulation_denominator,
                                                              legacy_numerator,
                                                              legacy_denominator);
    sm64_modern_timebase_set_lifecycle_active(false);
    const SM64ModernStatus status = timebase->configure(&config);
    expect_status("configure cadence", status, SM64_MODERN_STATUS_OK);
    if (status != SM64_MODERN_STATUS_OK) {
        return false;
    }

    SM64ModernTimebaseSnapshotV1 snapshot;
    memset(&snapshot, 0, sizeof(snapshot));
    expect_status("read cadence snapshot",
                  timebase->get_snapshot(&snapshot),
                  SM64_MODERN_STATUS_OK);
    expect_u64("cadence pair ratio", snapshot.simulation_ticks_per_legacy_tick, expected_pair);
    return snapshot.simulation_ticks_per_legacy_tick == expected_pair;
}

static void initialize_model(WorldCadenceModel *model) {
    memset(model, 0, sizeof(*model));
    model->state.script_delay = 2u;
    model->state.action = 1u;
    model->state.previous_action = 1u;
    model->state.random_seed = UINT16_C(0xACE1);
    model->state.fixed_animation_step = ANIMATION_FIXED_STEP;
    model->state.hud_timer_running = true;
    model->state.intangible_timer = 4u;
}

static void advance_dynamics(WorldCadenceModel *model) {
    /* Each call represents one admitted native dynamics step.  The reference
     * path runs two calls per logical interval so it models the target 60/30
     * world even while its public timebase remains ratio-one. */
    model->state.mario_position += 3u;
    model->state.actor_position += 5u;
    model->state.platform_position += 2u;
    if (model->state.camera_position < model->state.mario_position) {
        model->state.camera_position++;
    } else if (model->state.camera_position > model->state.mario_position) {
        model->state.camera_position--;
    }
    model->state.painting_ripple = (model->state.painting_ripple + 7u) % 100u;
    model->state.environmental_motion = (model->state.environmental_motion + 11u) % 256u;
    model->state.collision_passes++;
    model->state.particle_updates++;
    if (model->state.intangible_timer > 0u) {
        model->state.intangible_timer--;
    }
    model->state.action_timer++;
}

static void append_event(WorldCadenceModel *model,
                         uint16_t kind,
                         uint32_t first,
                         uint32_t second,
                         uint32_t third) {
    if (model->event_count >= MAX_EVENTS_PER_INTERVAL) {
        model->event_overflow = true;
        return;
    }
    WorldCadenceEvent *event = &model->events[model->event_count];
    event->kind = kind;
    event->ordinal = (uint16_t) model->event_count;
    event->first = first;
    event->second = second;
    event->third = third;
    model->event_count++;
}

static void feed_controls(WorldCadenceModel *model, HostControls controls) {
    if (controls.input_edge) {
        model->latches.input_latched = true;
    }
    if (controls.time_stop) {
        model->latches.time_stop_latched = true;
    }
    if (controls.transition_start) {
        model->latches.transition_latched = true;
    }
}

static uint16_t next_random(WorldCadenceModel *model, uint16_t *seed_before) {
    *seed_before = model->state.random_seed;
    model->state.random_seed = (uint16_t) ((uint32_t) model->state.random_seed * 25173u + 13849u);
    model->state.random_draw_ordinal++;
    return model->state.random_seed;
}

static void advance_boundary(WorldCadenceModel *model, uint32_t interval) {
    model->event_count = 0u;
    model->event_overflow = false;

    /* A stop request is consumed at the next logical boundary.  The other
     * latches remain pending so an input edge cannot disappear during a stop. */
    if (model->latches.time_stop_latched) {
        model->latches.time_stop_latched = false;
        append_event(model, WORLD_EVENT_TIME_STOP, interval, 0u, 0u);
        return;
    }

    bool action_changed = false;
    uint16_t old_action = model->state.action;
    if (model->latches.input_latched) {
        model->latches.input_latched = false;
        const uint16_t requested_action = (uint16_t) (2u + ((interval / 3u) & 1u));
        append_event(model, WORLD_EVENT_INPUT_EDGE, requested_action, interval, 0u);
        model->state.menu_open = !model->state.menu_open;
        if (requested_action != model->state.action) {
            action_changed = true;
            model->state.previous_action = model->state.action;
            model->state.action = requested_action;
            /* Reset happens before the per-boundary timer increments below. */
            model->state.object_timer = 0u;
            model->state.action_timer = 0u;
        }
    }

    model->state.object_timer++;
    if (action_changed) {
        append_event(model,
                     WORLD_EVENT_ACTION_RESET,
                     old_action,
                     model->state.action,
                     model->state.action_timer);
    }

    if (model->state.script_delay > 0u) {
        model->state.script_delay--;
        if (model->state.script_delay == 0u) {
            append_event(model, WORLD_EVENT_SCRIPT_WAKE, interval, 0u, 0u);
        }
    } else if ((interval % 4u) == 1u) {
        model->state.script_delay = 2u;
        append_event(model, WORLD_EVENT_SCRIPT_SLEEP, model->state.script_delay, interval, 0u);
    }

    const uint32_t draw_count = ((interval % 3u) == 1u) ? 2u : 1u;
    for (uint32_t draw = 0u; draw < draw_count; ++draw) {
        uint16_t seed_before;
        const uint16_t value = next_random(model, &seed_before);
        append_event(model,
                     WORLD_EVENT_RNG_DRAW,
                     model->state.random_draw_ordinal,
                     seed_before,
                     value);
    }

    const uint16_t old_integer_frame = model->state.integer_animation_frame;
    model->state.integer_animation_frame++;
    if (model->state.integer_animation_frame >= 7u) {
        model->state.integer_animation_frame = 0u;
    }
    if (model->state.integer_animation_frame == 0u
        || model->state.integer_animation_frame == 3u) {
        append_event(model,
                     WORLD_EVENT_INTEGER_ANIMATION,
                     old_integer_frame,
                     model->state.integer_animation_frame,
                     1u);
    }

    const uint32_t old_fixed_frame = model->state.fixed_animation_position >> 16u;
    model->state.fixed_animation_position += model->state.fixed_animation_step;
    const uint32_t new_fixed_frame = model->state.fixed_animation_position >> 16u;
    if (new_fixed_frame != old_fixed_frame) {
        append_event(model,
                     WORLD_EVENT_FIXED_ANIMATION,
                     old_fixed_frame,
                     new_fixed_frame,
                     model->state.fixed_animation_position & UINT32_C(0xffff));
    }

    if (model->latches.transition_latched) {
        model->latches.transition_latched = false;
        if (!model->state.transition_active) {
            model->state.transition_active = true;
            model->state.transition_timer = 3u;
            append_event(model,
                         WORLD_EVENT_TRANSITION_BEGIN,
                         model->state.transition_timer,
                         interval,
                         0u);
        }
    }
    if (model->state.transition_active) {
        model->state.transition_timer--;
        if (model->state.transition_timer == 0u) {
            model->state.transition_active = false;
            append_event(model, WORLD_EVENT_TRANSITION_END, interval, 0u, 0u);
        }
    }

    if (model->state.hud_timer_running) {
        model->state.hud_timer++;
        append_event(model, WORLD_EVENT_HUD_COUNTER, model->state.hud_timer, interval, 0u);
    }
    if (model->state.menu_open) {
        model->state.menu_counter = (uint16_t) ((model->state.menu_counter + 1u) % 5u);
        append_event(model, WORLD_EVENT_MENU_COUNTER, model->state.menu_counter, interval, 0u);
    }
}

static void capture_trace(const WorldCadenceModel *model, WorldCadenceTrace *trace) {
    trace->state = model->state;
    trace->latches = model->latches;
    trace->event_count = model->event_count;
    memcpy(trace->events,
           model->events,
           model->event_count * sizeof(model->events[0]));
    if (model->event_overflow) {
        fprintf(stderr, "world cadence: event capacity overflow\n");
        failures++;
    }
}

static void compare_state(uint32_t interval,
                          const WorldCadenceState *expected,
                          const WorldCadenceState *actual) {
#define CHECK_STATE(field) \
    do { \
        if (expected->field != actual->field) { \
            failf("state mismatch: " #field, interval, "paired boundary"); \
        } \
    } while (0)
    CHECK_STATE(script_delay);
    CHECK_STATE(object_timer);
    CHECK_STATE(action_timer);
    CHECK_STATE(action);
    CHECK_STATE(previous_action);
    CHECK_STATE(random_seed);
    CHECK_STATE(random_draw_ordinal);
    CHECK_STATE(integer_animation_frame);
    CHECK_STATE(fixed_animation_position);
    CHECK_STATE(fixed_animation_step);
    CHECK_STATE(transition_timer);
    CHECK_STATE(hud_timer);
    CHECK_STATE(menu_counter);
    CHECK_STATE(menu_open);
    CHECK_STATE(transition_active);
    CHECK_STATE(hud_timer_running);
    CHECK_STATE(mario_position);
    CHECK_STATE(actor_position);
    CHECK_STATE(platform_position);
    CHECK_STATE(camera_position);
    CHECK_STATE(painting_ripple);
    CHECK_STATE(environmental_motion);
    CHECK_STATE(collision_passes);
    CHECK_STATE(particle_updates);
    CHECK_STATE(intangible_timer);
#undef CHECK_STATE
}

static void compare_legacy_state(uint32_t interval,
                                 const WorldCadenceState *expected,
                                 const WorldCadenceState *actual) {
#define CHECK_LEGACY_STATE(field) \
    do { \
        if (expected->field != actual->field) { \
            failf("held state mismatch: " #field, interval, "legacy boundary"); \
        } \
    } while (0)
    CHECK_LEGACY_STATE(script_delay);
    CHECK_LEGACY_STATE(object_timer);
    CHECK_LEGACY_STATE(action);
    CHECK_LEGACY_STATE(previous_action);
    CHECK_LEGACY_STATE(random_seed);
    CHECK_LEGACY_STATE(random_draw_ordinal);
    CHECK_LEGACY_STATE(integer_animation_frame);
    CHECK_LEGACY_STATE(fixed_animation_position);
    CHECK_LEGACY_STATE(fixed_animation_step);
    CHECK_LEGACY_STATE(transition_timer);
    CHECK_LEGACY_STATE(hud_timer);
    CHECK_LEGACY_STATE(menu_counter);
    CHECK_LEGACY_STATE(menu_open);
    CHECK_LEGACY_STATE(transition_active);
    CHECK_LEGACY_STATE(hud_timer_running);
#undef CHECK_LEGACY_STATE
}

static void compare_latches(uint32_t interval,
                            const WorldCadenceLatches *expected,
                            const WorldCadenceLatches *actual) {
#define CHECK_LATCH(field) \
    do { \
        if (expected->field != actual->field) { \
            failf("latch mismatch: " #field, interval, "paired boundary"); \
        } \
    } while (0)
    CHECK_LATCH(input_latched);
    CHECK_LATCH(time_stop_latched);
    CHECK_LATCH(transition_latched);
#undef CHECK_LATCH
}

static void compare_events(uint32_t interval,
                           const WorldCadenceTrace *expected,
                           const WorldCadenceTrace *actual) {
    if (expected->event_count != actual->event_count) {
        failf("event count mismatch", interval, "ordered interval stream");
    }
    const uint32_t count = expected->event_count < actual->event_count
                               ? expected->event_count
                               : actual->event_count;
    for (uint32_t index = 0u; index < count; ++index) {
        const WorldCadenceEvent *expected_event = &expected->events[index];
        const WorldCadenceEvent *actual_event = &actual->events[index];
        if (memcmp(expected_event, actual_event, sizeof(*expected_event)) != 0) {
            char detail[96];
            snprintf(detail,
                     sizeof(detail),
                     "event %u expected kind %u, got %u",
                     index,
                     (unsigned) expected_event->kind,
                     (unsigned) actual_event->kind);
            failf("event mismatch", interval, detail);
            break;
        }
    }
}

static void compare_traces(uint32_t interval,
                           const WorldCadenceTrace *expected,
                           const WorldCadenceTrace *actual) {
    compare_state(interval, &expected->state, &actual->state);
    compare_latches(interval, &expected->latches, &actual->latches);
    compare_events(interval, expected, actual);
}

static void expect_first_step_boundary(uint32_t interval) {
    if (!sm64_modern_timebase_is_legacy_boundary()
        || !sm64_modern_timebase_should_advance_legacy_domain()
        || sm64_modern_timebase_pair_phase() != 1u
        || sm64_modern_timebase_legacy_tick() != (uint64_t) interval + 1u
        || sm64_modern_timebase_simulation_tick() != (uint64_t) interval * 2u + 1u) {
        failf("native first-step boundary", interval, "unexpected private timebase state");
    }
}

static void expect_held_second_step(uint32_t interval) {
    if (sm64_modern_timebase_is_legacy_boundary()
        || sm64_modern_timebase_should_advance_legacy_domain()
        || sm64_modern_timebase_pair_phase() != 0u
        || sm64_modern_timebase_legacy_tick() != (uint64_t) interval + 1u
        || sm64_modern_timebase_simulation_tick() != (uint64_t) interval * 2u + 2u) {
        failf("native held second step", interval, "unexpected private timebase state");
    }
}

static void run_reference(const SM64ModernTimebaseApiV1 *timebase,
                          const HostControls *controls,
                          WorldCadenceTrace *traces) {
    if (!configure_timebase(timebase, 30u, 1u, 30u, 1u, 1u)) {
        return;
    }
    WorldCadenceModel model;
    initialize_model(&model);
    sm64_modern_timebase_set_lifecycle_active(true);
    for (uint32_t interval = 0u; interval < LOGICAL_INTERVAL_COUNT; ++interval) {
        feed_controls(&model, controls[interval]);
        sm64_modern_timebase_begin_simulation_step();
        if (!sm64_modern_timebase_is_legacy_boundary()
            || sm64_modern_timebase_pair_phase() != 0u
            || sm64_modern_timebase_legacy_tick() != (uint64_t) interval + 1u
            || sm64_modern_timebase_simulation_tick() != (uint64_t) interval + 1u) {
            failf("reference boundary", interval, "unexpected private timebase state");
        }
        advance_dynamics(&model);
        advance_boundary(&model, interval);
        advance_dynamics(&model);
        capture_trace(&model, &traces[interval]);
    }
    sm64_modern_timebase_set_lifecycle_active(false);
}

static void run_native_pair(const SM64ModernTimebaseApiV1 *timebase,
                            const HostControls *controls,
                            const WorldCadenceTrace *expected) {
    if (!configure_timebase(timebase, 60u, 1u, 30u, 1u, 2u)) {
        return;
    }
    WorldCadenceModel model;
    initialize_model(&model);
    sm64_modern_timebase_set_lifecycle_active(true);
    for (uint32_t native_tick = 0u;
         native_tick < LOGICAL_INTERVAL_COUNT * 2u;
         ++native_tick) {
        /* Interval zero arrives before its first boundary.  Every later
         * logical sample is deliberately delivered during the previous pair's
         * held step, proving that edge state survives until the next boundary. */
        if (native_tick == 0u) {
            feed_controls(&model, controls[0]);
        }

        sm64_modern_timebase_begin_simulation_step();
        const uint32_t interval = native_tick / 2u;
        WorldCadenceState before;
        uint32_t event_count = 0u;
        if ((native_tick & 1u) != 0u) {
            before = model.state;
            event_count = model.event_count;
        }
        advance_dynamics(&model);
        if ((native_tick & 1u) == 0u) {
            expect_first_step_boundary(interval);
            advance_boundary(&model, interval);
        } else {
            expect_held_second_step(interval);
            /* A held native step advances only continuous dynamics.  Legacy
             * timers, scripts, RNG, animation, transitions, HUD/menu state,
             * and ordered events remain unchanged. */
            compare_legacy_state(interval, &before, &model.state);
            if (event_count != model.event_count
                || model.state.mario_position == before.mario_position
                || model.state.actor_position == before.actor_position
                || model.state.platform_position == before.platform_position
                || model.state.camera_position == before.camera_position
                || model.state.painting_ripple == before.painting_ripple
                || model.state.environmental_motion == before.environmental_motion
                || model.state.collision_passes == before.collision_passes
                || model.state.particle_updates == before.particle_updates) {
                failf("held native dynamics", interval, "continuous state did not advance cleanly");
            }
            WorldCadenceTrace actual;
            memset(&actual, 0, sizeof(actual));
            capture_trace(&model, &actual);
            compare_traces(interval, &expected[interval], &actual);

            /* Deliver the next interval's controls after the held sample has
             * been compared.  They are now latched during the held native
             * phase and will be consumed by the next boundary. */
            const uint32_t next_interval = interval + 1u;
            if (next_interval < LOGICAL_INTERVAL_COUNT) {
                feed_controls(&model, controls[next_interval]);
                if ((controls[next_interval].input_edge && !model.latches.input_latched)
                    || (controls[next_interval].time_stop && !model.latches.time_stop_latched)
                    || (controls[next_interval].transition_start
                        && !model.latches.transition_latched)) {
                    failf("held input/control latch", next_interval, "edge was not retained");
                }
            }
        }
    }
    sm64_modern_timebase_set_lifecycle_active(false);
}

int main(void) {
#ifndef SM64_MODERN_NATIVE
    fputs("SM64 Modern world cadence smoke requires SM64_MODERN_NATIVE=1\n", stderr);
    return 2;
#else
    SM64ModernTimebaseApiV1 timebase;
    memset(&timebase, 0, sizeof(timebase));
    const SM64ModernStatus api_status = sm64_modern_get_timebase_api(
        SM64_MODERN_ABI_VERSION_1, sizeof(timebase), &timebase);
    expect_status("timebase API", api_status, SM64_MODERN_STATUS_OK);
    if (api_status != SM64_MODERN_STATUS_OK) {
        fprintf(stderr, "SM64 Modern world cadence smoke failed: %d failure(s)\n", failures);
        return 1;
    }

    HostControls controls[LOGICAL_INTERVAL_COUNT];
    memset(controls, 0, sizeof(controls));
    /* Input edges, a next-boundary stop, and transition requests are all
     * delivered at different phases by run_native_pair(). */
    controls[0].input_edge = true;
    controls[2].input_edge = true;
    controls[2].time_stop = true;
    controls[4].transition_start = true;
    controls[6].input_edge = true;
    controls[8].transition_start = true;
    controls[9].input_edge = true;

    WorldCadenceTrace reference[LOGICAL_INTERVAL_COUNT];
    memset(reference, 0, sizeof(reference));
    run_reference(&timebase, controls, reference);
    run_native_pair(&timebase, controls, reference);

    if (failures != 0) {
        fprintf(stderr,
                "SM64 Modern world cadence smoke failed: %d failure(s)\n",
                failures);
        return 1;
    }
    puts("SM64 Modern world cadence smoke passed");
    return 0;
#endif
}
