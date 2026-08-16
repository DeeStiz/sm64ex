#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct ID { int present; uint64_t slot, generation; };

struct State {
    int32_t action, timer, chosen_home;
    float home_x, home_z;
    int16_t target_yaw, move_yaw;
    float forward_velocity, velocity_y;
    uint32_t blink;
};

struct Output {
    struct State state;
    int32_t animation, dialog;
    int dialog_requested, active_time_stop, clear_time_stop, clear_interaction;
    int play_walk, play_puzzle, play_alert, play_extra;
    int32_t lives_delta;
    int special_triple_jump, camera_request, respawner_requested, deactivated;
};

struct Intent {
    uint64_t sequence;
    struct ID id;
    uint64_t kind;
    int32_t value, auxiliary;
};

struct Delivery {
    const struct Intent *delivered;
    size_t delivered_count;
    const struct Intent *presented;
    size_t presented_count;
    const struct ID *spawned;
    size_t spawned_count;
    const struct ID *deleted;
    size_t deleted_count;
    const struct Intent *rejected;
    size_t rejected_count;
};

struct Effect {
    struct ID id;
    struct Output output;
    const struct ID *respawners;
    size_t respawner_count;
    const struct Intent *presented;
    size_t presented_count;
};

struct Record {
    int present;
    struct ID id;
    uint64_t object_list;
    uint64_t active_flags, object_flags;
    int32_t action, previous_action, timer, behavior_params, behavior_params_2nd_byte;
    uint64_t interaction_subtype;
    float drawing_distance, gravity, friction, buoyancy;
    float position_x, position_y, position_z, home_x, home_z;
    uint64_t respawn_info_type, respawn_info_identity;
};

struct Tick {
    uint64_t frame;
    const uint64_t *list_counts;
    size_t list_count;
    uint64_t object_counter;
    const struct ID *updated;
    size_t updated_count;
    const struct ID *skipped;
    size_t skipped_count;
    const struct ID *unloaded;
    size_t unloaded_count;
    int time_stop_was_active, time_stop_is_active;
    const struct Effect *effects;
    size_t effect_count;
    const struct Delivery *deliveries;
    size_t delivery_count;
    const struct Record *records;
    size_t record_count;
};

static uint64_t hash_u64(uint64_t initial, uint64_t value) {
    uint64_t hash = initial;
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_float(uint64_t initial, float value) {
    union { float f; uint32_t u; } bits = { value };
    return hash_u64(initial, bits.u);
}

static uint64_t hash_id(uint64_t initial, struct ID id) {
    if (!id.present)
        return hash_u64(initial, 0);
    uint64_t hash = hash_u64(initial, 1);
    hash = hash_u64(hash, id.slot);
    return hash_u64(hash, id.generation);
}

static uint64_t hash_ids(uint64_t initial, const struct ID *ids, size_t count) {
    uint64_t hash = hash_u64(initial, count);
    for (size_t index = 0; index < count; ++index)
        hash = hash_id(hash, ids[index]);
    return hash;
}

static uint64_t hash_intent(uint64_t initial, const struct Intent *intent) {
    uint64_t hash = hash_u64(initial, intent->sequence);
    hash = hash_id(hash, intent->id);
    hash = hash_u64(hash, intent->kind);
    hash = hash_u64(hash, (uint64_t) (int64_t) intent->value);
    return hash_u64(hash, (uint64_t) (int64_t) intent->auxiliary);
}

static uint64_t hash_state(uint64_t initial, const struct State *state) {
    uint64_t hash = hash_u64(initial, (uint64_t) (int64_t) state->action);
    hash = hash_u64(hash, (uint64_t) (int64_t) state->timer);
    hash = hash_u64(hash, (uint64_t) (int64_t) state->chosen_home);
    hash = hash_float(hash, state->home_x);
    hash = hash_float(hash, state->home_z);
    hash = hash_u64(hash, (uint64_t) (uint16_t) state->target_yaw);
    hash = hash_u64(hash, (uint64_t) (uint16_t) state->move_yaw);
    hash = hash_float(hash, state->forward_velocity);
    hash = hash_float(hash, state->velocity_y);
    return hash_u64(hash, state->blink);
}

static uint64_t hash_output(uint64_t initial, const struct Output *output) {
    uint64_t hash = hash_state(initial, &output->state);
    hash = hash_u64(hash, (uint64_t) (int64_t) output->animation);
    hash = hash_u64(hash, (uint64_t) (int64_t) output->dialog);
    hash = hash_u64(hash, (uint64_t) output->dialog_requested);
    hash = hash_u64(hash, (uint64_t) output->active_time_stop);
    hash = hash_u64(hash, (uint64_t) output->clear_time_stop);
    hash = hash_u64(hash, (uint64_t) output->clear_interaction);
    hash = hash_u64(hash, (uint64_t) output->play_walk);
    hash = hash_u64(hash, (uint64_t) output->play_puzzle);
    hash = hash_u64(hash, (uint64_t) output->play_alert);
    hash = hash_u64(hash, (uint64_t) output->play_extra);
    hash = hash_u64(hash, (uint64_t) (int64_t) output->lives_delta);
    hash = hash_u64(hash, (uint64_t) output->special_triple_jump);
    hash = hash_u64(hash, (uint64_t) (int64_t) output->camera_request);
    hash = hash_u64(hash, (uint64_t) output->respawner_requested);
    return hash_u64(hash, (uint64_t) output->deactivated);
}

static uint64_t hash_delivery(uint64_t initial, const struct Delivery *delivery) {
    uint64_t hash = hash_u64(initial, delivery->delivered_count);
    for (size_t index = 0; index < delivery->delivered_count; ++index)
        hash = hash_intent(hash, &delivery->delivered[index]);
    hash = hash_u64(hash, delivery->presented_count);
    for (size_t index = 0; index < delivery->presented_count; ++index)
        hash = hash_intent(hash, &delivery->presented[index]);
    hash = hash_ids(hash, delivery->spawned, delivery->spawned_count);
    hash = hash_ids(hash, delivery->deleted, delivery->deleted_count);
    hash = hash_u64(hash, delivery->rejected_count);
    for (size_t index = 0; index < delivery->rejected_count; ++index)
        hash = hash_intent(hash, &delivery->rejected[index]);
    return hash;
}

static uint64_t hash_record(uint64_t initial, const struct Record *record) {
    if (!record->present)
        return hash_u64(initial, 0);
    uint64_t hash = hash_u64(initial, 1);
    hash = hash_id(hash, record->id);
    hash = hash_u64(hash, record->object_list);
    hash = hash_u64(hash, record->active_flags);
    hash = hash_u64(hash, record->object_flags);
    hash = hash_u64(hash, (uint64_t) (int64_t) record->action);
    hash = hash_u64(hash, (uint64_t) (int64_t) record->previous_action);
    hash = hash_u64(hash, (uint64_t) (int64_t) record->timer);
    hash = hash_u64(hash, (uint64_t) (int64_t) record->behavior_params);
    hash = hash_u64(hash, (uint64_t) (int64_t) record->behavior_params_2nd_byte);
    hash = hash_u64(hash, record->interaction_subtype);
    hash = hash_float(hash, record->drawing_distance);
    hash = hash_float(hash, record->gravity);
    hash = hash_float(hash, record->friction);
    hash = hash_float(hash, record->buoyancy);
    hash = hash_float(hash, record->position_x);
    hash = hash_float(hash, record->position_y);
    hash = hash_float(hash, record->position_z);
    hash = hash_float(hash, record->home_x);
    hash = hash_float(hash, record->home_z);
    hash = hash_u64(hash, record->respawn_info_type);
    return hash_u64(hash, record->respawn_info_identity);
}

static uint64_t hash_tick(uint64_t initial, const struct Tick *tick) {
    uint64_t hash = hash_u64(initial, tick->frame);
    hash = hash_u64(hash, tick->list_count);
    for (size_t index = 0; index < tick->list_count; ++index)
        hash = hash_u64(hash, tick->list_counts[index]);
    hash = hash_u64(hash, tick->object_counter);
    hash = hash_ids(hash, tick->updated, tick->updated_count);
    hash = hash_ids(hash, tick->skipped, tick->skipped_count);
    hash = hash_ids(hash, tick->unloaded, tick->unloaded_count);
    hash = hash_u64(hash, (uint64_t) tick->time_stop_was_active);
    hash = hash_u64(hash, (uint64_t) tick->time_stop_is_active);
    hash = hash_u64(hash, tick->effect_count);
    for (size_t index = 0; index < tick->effect_count; ++index) {
        const struct Effect *effect = &tick->effects[index];
        hash = hash_id(hash, effect->id);
        hash = hash_output(hash, &effect->output);
        hash = hash_ids(hash, effect->respawners, effect->respawner_count);
        hash = hash_u64(hash, effect->presented_count);
        for (size_t intent = 0; intent < effect->presented_count; ++intent)
            hash = hash_intent(hash, &effect->presented[intent]);
    }
    hash = hash_u64(hash, tick->delivery_count);
    for (size_t index = 0; index < tick->delivery_count; ++index)
        hash = hash_delivery(hash, &tick->deliveries[index]);
    for (size_t index = 0; index < tick->record_count; ++index)
        hash = hash_record(hash, &tick->records[index]);
    return hash;
}

static struct Output make_output(
    struct State state,
    int32_t animation, int32_t dialog,
    int dialog_requested, int active_time_stop, int clear_time_stop, int clear_interaction,
    int play_walk, int play_puzzle, int play_alert, int play_extra,
    int32_t lives_delta, int special_triple_jump, int camera_request,
    int respawner_requested, int deactivated) {
    return (struct Output) {
        state, animation, dialog, dialog_requested, active_time_stop,
        clear_time_stop, clear_interaction, play_walk, play_puzzle,
        play_alert, play_extra, lives_delta, special_triple_jump,
        camera_request, respawner_requested, deactivated
    };
}

static struct Tick make_tick(
    uint64_t frame, const uint64_t *counts, uint64_t object_counter,
    const struct ID *updated, size_t updated_count,
    const struct ID *skipped, size_t skipped_count,
    const struct ID *unloaded, size_t unloaded_count,
    const struct Effect *effects, size_t effect_count,
    const struct Delivery *deliveries, size_t delivery_count,
    const struct Record *records, size_t record_count) {
    return (struct Tick) {
        frame, counts, 13, object_counter, updated, updated_count,
        skipped, skipped_count, unloaded, unloaded_count, 0, 0,
        effects, effect_count, deliveries, delivery_count, records, record_count
    };
}

static const uint64_t general_counts[13] = { 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0 };
static const uint64_t spawner_and_general_counts[13] = { 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0 };
static const struct ID no_ids[1] = { { 0, 0, 0 } };
static const struct Intent no_intents[1] = { { 0, { 0, 0, 0 }, 0, 0, 0 } };

static struct State initial_state(void) {
    return (struct State) { 0, 0, 0, 0.0f, -5625.0f, 0, 0, 0.0f, 0.0f, 0 };
}

static struct Intent intent(uint64_t sequence, struct ID id, uint64_t kind, int32_t value) {
    return (struct Intent) { sequence, id, kind, value, 0 };
}

static struct Delivery delivery(
    const struct Intent *delivered, size_t delivered_count,
    const struct Intent *presented, size_t presented_count,
    const struct ID *spawned, size_t spawned_count,
    const struct ID *deleted, size_t deleted_count) {
    return (struct Delivery) {
        delivered, delivered_count, presented, presented_count,
        spawned, spawned_count, deleted, deleted_count, no_intents, 0
    };
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    const struct ID id01 = { 1, 0, 1 };
    const struct ID id02 = { 1, 0, 2 };
    const struct ID id03 = { 1, 0, 3 };
    const struct ID id04 = { 1, 1, 2 };
    const struct ID id11 = { 1, 1, 1 };
    const struct ID id21 = { 1, 2, 1 };
    const struct ID no_id = { 0, 0, 0 };

    struct State state = initial_state();
    struct Output output = make_output(state, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);
    struct Intent mark01 = intent(1, id01, 6, 0);
    struct Delivery d1 = delivery(&mark01, 1, no_intents, 0, no_ids, 0, &id01, 1);
    struct Effect e1 = { id01, output, no_ids, 0, no_intents, 0 };
    struct ID updated01[] = { id01 };
    struct ID unloaded01[] = { id01 };
    struct Record nil_record = { 0 };
    struct Tick t1 = make_tick(1, general_counts, 1, updated01, 1, no_ids, 0, unloaded01, 1, &e1, 1, &d1, 1, &nil_record, 1);
    fingerprint = hash_tick(fingerprint, &t1);

    state = (struct State) { 5, 0, 0, -1403.0f, -4609.0f, -9844, 0, 0.0f, 0.0f, 0 };
    output = make_output(state, 0, 161, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    struct Intent dialog02 = intent(2, id02, 8, 161);
    struct Delivery d2 = delivery(&dialog02, 1, &dialog02, 1, no_ids, 0, no_ids, 0);
    struct Effect e2 = { id02, output, no_ids, 0, &dialog02, 1 };
    struct ID updated02[] = { id02 };
    struct Record r2 = {
        .present = 1, .id = id02, .object_list = 4, .active_flags = 257, .object_flags = 33,
        .action = 5, .previous_action = 2, .timer = 0, .behavior_params = 0,
        .behavior_params_2nd_byte = 0, .interaction_subtype = 16384,
        .drawing_distance = 4000.0f, .gravity = 2.0f, .friction = 0.9f, .buoyancy = 1.3f,
        .position_x = 0.0f, .position_y = 3174.0f, .position_z = -5625.0f,
        .home_x = -1403.0f, .home_z = -4609.0f, .respawn_info_type = 0, .respawn_info_identity = 0
    };
    struct Tick t2 = make_tick(2, general_counts, 1, updated02, 1, no_ids, 0, no_ids, 0, &e2, 1, &d2, 1, &r2, 1);
    fingerprint = hash_tick(fingerprint, &t2);

    state = (struct State) { 5, 0, 0, -1403.0f, -4609.0f, -9844, 0, 0.0f, 0.0f, 0 };
    output = make_output(state, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0);
    struct Intent life02 = intent(3, id02, 0, (int32_t) UINT32_C(0x70150081));
    struct Delivery d3 = delivery(&life02, 1, &life02, 1, no_ids, 0, no_ids, 0);
    struct Effect e3 = { id02, output, no_ids, 0, &life02, 1 };
    struct Record r3 = {
        .present = 1, .id = id02, .object_list = 4, .active_flags = 257, .object_flags = 33,
        .action = 5, .previous_action = 5, .timer = 0, .behavior_params = 0,
        .behavior_params_2nd_byte = 0, .interaction_subtype = 16384,
        .drawing_distance = 4000.0f, .gravity = 2.0f, .friction = 0.9f, .buoyancy = 1.3f,
        .position_x = 0.0f, .position_y = 3174.0f, .position_z = -5625.0f,
        .home_x = -1403.0f, .home_z = -4609.0f, .respawn_info_type = 0, .respawn_info_identity = 0
    };
    struct Tick t3 = make_tick(3, general_counts, 1, updated02, 1, no_ids, 0, no_ids, 0, &e3, 1, &d3, 1, &r3, 1);
    fingerprint = hash_tick(fingerprint, &t3);

    state = (struct State) { 4, 0, 0, 0.0f, -5625.0f, 0, -16383, 50.0f, 40.0f, 0 };
    output = make_output(state, 2, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0);
    struct Intent walk04 = intent(4, id02, 0, (int32_t) UINT32_C(0x306e2081));
    struct Intent alert04 = intent(5, id02, 0, (int32_t) UINT32_C(0x306f3081));
    struct Intent camera04 = intent(6, id02, 2, 1);
    struct Intent effects04[] = { walk04, alert04, camera04 };
    struct Delivery d4 = delivery(effects04, 3, effects04, 3, no_ids, 0, no_ids, 0);
    struct Effect e4 = { id02, output, no_ids, 0, effects04, 3 };
    struct Record r4 = {
        .present = 1, .id = id02, .object_list = 4, .active_flags = 257, .object_flags = 33,
        .action = 4, .previous_action = 3, .timer = 0, .behavior_params = 0,
        .behavior_params_2nd_byte = 0, .interaction_subtype = 16384,
        .drawing_distance = 4000.0f, .gravity = 2.0f, .friction = 0.9f, .buoyancy = 1.3f,
        .position_x = 0.0f, .position_y = 3174.0f, .position_z = -5625.0f,
        .home_x = 0.0f, .home_z = -5625.0f, .respawn_info_type = 0, .respawn_info_identity = 0
    };
    struct Tick t4 = make_tick(4, general_counts, 1, updated02, 1, no_ids, 0, no_ids, 0, &e4, 1, &d4, 1, &r4, 1);
    fingerprint = hash_tick(fingerprint, &t4);

    state = (struct State) { 4, 0, 0, 0.0f, -5625.0f, 0, -16383, 50.0f, 38.0f, 0 };
    output = make_output(state, 2, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);
    struct Intent mark02 = intent(7, id02, 6, 0);
    struct Delivery d5 = delivery(&mark02, 1, no_intents, 0, no_ids, 0, &id02, 1);
    struct Effect e5 = { id02, output, no_ids, 0, no_intents, 0 };
    struct ID unloaded02[] = { id02 };
    struct Tick t5 = make_tick(5, general_counts, 1, updated02, 1, no_ids, 0, unloaded02, 1, &e5, 1, &d5, 1, &nil_record, 1);
    fingerprint = hash_tick(fingerprint, &t5);

    state = (struct State) { 1, 0, 0, 0.0f, -5625.0f, 0, 0, 10.0f, 0.0f, 0 };
    output = make_output(state, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1);
    struct Intent mark03 = intent(8, id03, 6, 0);
    struct ID spawned11[] = { id11 };
    struct Delivery d6 = delivery(&mark03, 1, no_intents, 0, no_ids, 0, &id03, 1);
    struct Effect e6 = { id03, output, spawned11, 1, no_intents, 0 };
    struct ID updated03[] = { id03 };
    struct ID unloaded03[] = { id03 };
    static const uint64_t default_and_general_counts_t6[13] = { 0, 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 0 };
    struct ID updated06[] = { id03, id11, id21 };
    struct ID unloaded06[] = { id03, id11 };
    struct Record records6[] = { nil_record, nil_record };
    struct Tick t6 = make_tick(6, default_and_general_counts_t6, 3, updated06, 3, no_ids, 0, unloaded06, 2, &e6, 1, &d6, 1, records6, 2);
    fingerprint = hash_tick(fingerprint, &t6);

    state = (struct State) { 10, 0, 0, -1798.0f, -3644.0f, 0, 0, 0.0f, 0.0f, 0 };
    output = make_output(state, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    struct Effect e7 = { id04, output, no_ids, 0, no_intents, 0 };
    struct Delivery d7 = delivery(no_intents, 0, no_intents, 0, no_ids, 0, no_ids, 0);
    struct ID updated07[] = { id04, id21 };
    struct Record r7 = {
        .present = 1, .id = id04, .object_list = 4, .active_flags = 257, .object_flags = 33,
        .action = 10, .previous_action = 0, .timer = 0, .behavior_params = 0,
        .behavior_params_2nd_byte = 0, .interaction_subtype = 16384,
        .drawing_distance = 4000.0f, .gravity = 2.0f, .friction = 0.9f, .buoyancy = 1.3f,
        .position_x = -1798.0f, .position_y = 3174.0f, .position_z = -3644.0f,
        .home_x = -1798.0f, .home_z = -3644.0f, .respawn_info_type = 0, .respawn_info_identity = 0
    };
    struct Record r21 = {
        .present = 1, .id = id21, .object_list = 8, .active_flags = 257, .object_flags = 33,
        .action = 0, .previous_action = 0, .timer = 0, .behavior_params = 0,
        .behavior_params_2nd_byte = 0, .interaction_subtype = 0,
        .drawing_distance = 4000.0f, .gravity = 0.0f, .friction = 0.0f, .buoyancy = 0.0f,
        .position_x = 0.0f, .position_y = 3174.0f, .position_z = -5625.0f,
        .home_x = 0.0f, .home_z = -5625.0f, .respawn_info_type = 0,
        .respawn_info_identity = 0
    };
    static const uint64_t default_and_general_counts_t7[13] = { 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0 };
    struct Record records7[] = { r7, r21 };
    struct Tick t7 = make_tick(7, default_and_general_counts_t7, 2, updated07, 2, no_ids, 0, no_ids, 0, &e7, 1, &d7, 1, records7, 2);
    fingerprint = hash_tick(fingerprint, &t7);

    printf("yoshiObjectBridgeFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    printf("SM64 Modern Yoshi object bridge C contract passed\n");
    return 0;
}
