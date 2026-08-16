#include <stdint.h>
#include <stdio.h>
#include <stddef.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct ID { int present; uint64_t slot, generation; };

struct State {
    int32_t action, sub_action, health, animation_phase, grab_turn_timer;
    int32_t grab_escape_count, release_cooldown, interaction_mode;
    int16_t move_yaw;
    float forward_velocity, velocity_y, gravity, home_y, position_y;
    uint64_t timer;
    int tangible, hidden, holdable, using_home_movement, interaction_grab_cleared;
};

struct Output {
    struct State state;
    int32_t animation, dialog;
    int dialog_requested;
    uint64_t effects;
    const int32_t *sounds;
    size_t sound_count;
    const int32_t *sound_spawners;
    size_t sound_spawner_count;
    int32_t camera_shake;
    int star_present;
    float star_x, star_y, star_z;
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
    const struct Intent *presented;
    size_t presented_count;
};

struct Record {
    int present;
    struct ID id;
    uint64_t object_list, active_flags, object_flags, held_state, graph_flags;
    uint64_t interaction_type, interaction_subtype;
    int32_t intangible_timer, action, previous_action, sub_action, timer;
    int32_t animation_state, health;
    float drawing_distance, gravity, position_y, home_y;
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
    const struct Record *record;
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
    if (!id.present) return hash_u64(initial, 0);
    uint64_t hash = hash_u64(initial, 1);
    hash = hash_u64(hash, id.slot);
    return hash_u64(hash, id.generation);
}

static uint64_t hash_ids(uint64_t initial, const struct ID *ids, size_t count) {
    uint64_t hash = hash_u64(initial, count);
    for (size_t index = 0; index < count; ++index) hash = hash_id(hash, ids[index]);
    return hash;
}

static uint64_t hash_intent(uint64_t initial, const struct Intent *intent) {
    uint64_t hash = hash_u64(initial, intent->sequence);
    hash = hash_id(hash, intent->id);
    hash = hash_u64(hash, intent->kind);
    hash = hash_u64(hash, (uint64_t)(int64_t)intent->value);
    return hash_u64(hash, (uint64_t)(int64_t)intent->auxiliary);
}

static uint64_t hash_state(uint64_t initial, const struct State *state) {
    uint64_t hash = hash_u64(initial, (uint64_t)(int64_t)state->action);
    hash = hash_u64(hash, (uint64_t)(int64_t)state->sub_action);
    hash = hash_u64(hash, (uint64_t)(int64_t)state->health);
    hash = hash_u64(hash, (uint64_t)(int64_t)state->animation_phase);
    hash = hash_u64(hash, (uint64_t)(int64_t)state->grab_turn_timer);
    hash = hash_u64(hash, (uint64_t)(int64_t)state->grab_escape_count);
    hash = hash_u64(hash, (uint64_t)(int64_t)state->release_cooldown);
    hash = hash_u64(hash, (uint64_t)(int64_t)state->interaction_mode);
    hash = hash_u64(hash, (uint64_t)(uint16_t)state->move_yaw);
    hash = hash_float(hash, state->forward_velocity);
    hash = hash_float(hash, state->velocity_y);
    hash = hash_float(hash, state->gravity);
    hash = hash_float(hash, state->home_y);
    hash = hash_float(hash, state->position_y);
    hash = hash_u64(hash, state->timer);
    hash = hash_u64(hash, state->tangible ? 1 : 0);
    hash = hash_u64(hash, state->hidden ? 1 : 0);
    hash = hash_u64(hash, state->holdable ? 1 : 0);
    hash = hash_u64(hash, state->using_home_movement ? 1 : 0);
    return hash_u64(hash, state->interaction_grab_cleared ? 1 : 0);
}

static uint64_t hash_output(uint64_t initial, const struct Output *output) {
    uint64_t hash = hash_state(initial, &output->state);
    hash = hash_u64(hash, (uint64_t)(int64_t)output->animation);
    hash = hash_u64(hash, (uint64_t)(int64_t)output->dialog);
    hash = hash_u64(hash, (uint64_t)output->dialog_requested);
    hash = hash_u64(hash, output->effects);
    hash = hash_u64(hash, output->sound_count);
    for (size_t index = 0; index < output->sound_count; ++index)
        hash = hash_u64(hash, (uint64_t)(int64_t)output->sounds[index]);
    hash = hash_u64(hash, output->sound_spawner_count);
    for (size_t index = 0; index < output->sound_spawner_count; ++index)
        hash = hash_u64(hash, (uint64_t)(int64_t)output->sound_spawners[index]);
    hash = hash_u64(hash, (uint64_t)(int64_t)output->camera_shake);
    if (!output->star_present) return hash_u64(hash, 0);
    hash = hash_u64(hash, 1);
    hash = hash_float(hash, output->star_x);
    hash = hash_float(hash, output->star_y);
    return hash_float(hash, output->star_z);
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
    if (!record->present) return hash_u64(initial, 0);
    uint64_t hash = hash_u64(initial, 1);
    hash = hash_id(hash, record->id);
    hash = hash_u64(hash, record->object_list);
    hash = hash_u64(hash, record->active_flags);
    hash = hash_u64(hash, record->object_flags);
    hash = hash_u64(hash, record->held_state);
    hash = hash_u64(hash, record->graph_flags);
    hash = hash_u64(hash, record->interaction_type);
    hash = hash_u64(hash, record->interaction_subtype);
    hash = hash_u64(hash, (uint64_t)(int64_t)record->intangible_timer);
    hash = hash_u64(hash, (uint64_t)(int64_t)record->action);
    hash = hash_u64(hash, (uint64_t)(int64_t)record->previous_action);
    hash = hash_u64(hash, (uint64_t)(int64_t)record->sub_action);
    hash = hash_u64(hash, (uint64_t)(int64_t)record->timer);
    hash = hash_u64(hash, (uint64_t)(int64_t)record->animation_state);
    hash = hash_u64(hash, (uint64_t)(int64_t)record->health);
    hash = hash_float(hash, record->drawing_distance);
    hash = hash_float(hash, record->gravity);
    hash = hash_float(hash, record->position_y);
    return hash_float(hash, record->home_y);
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
    hash = hash_u64(hash, (uint64_t)tick->time_stop_was_active);
    hash = hash_u64(hash, (uint64_t)tick->time_stop_is_active);
    hash = hash_u64(hash, tick->effect_count);
    for (size_t index = 0; index < tick->effect_count; ++index) {
        hash = hash_id(hash, tick->effects[index].id);
        hash = hash_output(hash, &tick->effects[index].output);
        hash = hash_u64(hash, tick->effects[index].presented_count);
        for (size_t intent = 0; intent < tick->effects[index].presented_count; ++intent)
            hash = hash_intent(hash, &tick->effects[index].presented[intent]);
    }
    hash = hash_u64(hash, tick->delivery_count);
    for (size_t index = 0; index < tick->delivery_count; ++index)
        hash = hash_delivery(hash, &tick->deliveries[index]);
    return hash_record(hash, tick->record);
}

static const uint64_t general_counts[13] = {
    0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0
};
static const struct ID no_ids[1] = { { 0, 0, 0 } };
static const struct Intent no_intents[1] = { { 0, { 0, 0, 0 }, 0, 0, 0 } };
static const struct Record no_record = { 0 };

static struct State state(
    int32_t action, int32_t sub_action, int32_t health,
    float position_y, uint64_t timer, int tangible, int hidden, int holdable) {
    return (struct State) {
        action, sub_action, health, 0, 0, 0, 0, 2, 0,
        0.0f, 0.0f, -4.0f, position_y == 200.0f ? 100.0f : position_y,
        position_y, timer, tangible, hidden, holdable, 0, 0
    };
}

static struct Output output(
    struct State value, int32_t animation, int32_t dialog,
    uint64_t effects, const int32_t *sounds, size_t sound_count,
    const int32_t *sound_spawners, size_t sound_spawner_count,
    int star_present) {
    return (struct Output) {
        value, animation, dialog, dialog != 0, effects,
        sounds, sound_count, sound_spawners, sound_spawner_count,
        0, star_present, 2000.0f, 4500.0f, -4500.0f
    };
}

static struct Record record(
    struct ID id, uint64_t held_state, uint64_t graph_flags,
    uint64_t interaction_type, uint64_t interaction_subtype,
    int32_t intangible_timer, int32_t action, int32_t previous_action,
    int32_t sub_action, int32_t timer, int32_t animation_state,
    int32_t health, float position_y, float home_y) {
    return (struct Record) {
        1, id, 4, 257, 33, held_state, graph_flags,
        interaction_type, interaction_subtype, intangible_timer,
        action, previous_action, sub_action, timer, animation_state, health,
        5000.0f, -4.0f, position_y, home_y
    };
}

static struct Tick tick(
    uint64_t frame, struct ID id, const struct ID *unloaded, size_t unloaded_count,
    struct Effect *effect, struct Delivery *delivery, struct Record *record_value) {
    return (struct Tick) {
        frame, general_counts, 13, 1, &id, 1, no_ids, 0,
        unloaded, unloaded_count, 0, 0, effect, 1, delivery, 1, record_value
    };
}

int main(void) {
    const struct ID id01 = { 1, 0, 1 };
    const struct ID id02 = { 1, 0, 2 };
    const int32_t landing_sound[] = { (int32_t)UINT32_C(0x50168081) };
    const int32_t death_sound[] = { (int32_t)UINT32_C(0x5147C081) };
    uint64_t fingerprint = FNV_OFFSET;

    struct State s1 = state(0, 1, 3, 100, 1, 0, 0, 0);
    struct Output o1 = output(s1, 5, 0, UINT64_C(66055), NULL, 0, NULL, 0, 0);
    struct Intent i1 = { 1, id01, 10, 1, 0 };
    struct Delivery d1 = { &i1, 1, &i1, 1, no_ids, 0, no_ids, 0, no_intents, 0 };
    struct Effect e1 = { id01, o1, &i1, 1 };
    struct Record r1 = record(id01, 0, 32, 0, 0, 1, 0, 0, 1, 1, 5, 3, 100, 100);
    struct Tick t1 = tick(1, id01, no_ids, 0, &e1, &d1, &r1);
    fingerprint = hash_tick(fingerprint, &t1);

    struct State s2 = state(2, 1, 3, 100, 2, 1, 0, 1);
    struct Output o2 = output(s2, 5, 17, UINT64_C(69123), NULL, 0, NULL, 0, 0);
    struct Intent i2 = { 2, id01, 8, 17, 0 };
    struct Delivery d2 = { &i2, 1, &i2, 1, no_ids, 0, no_ids, 0, no_intents, 0 };
    struct Effect e2 = { id01, o2, &i2, 1 };
    struct Record r2 = record(id01, 0, 32, 2, 4, -1, 2, 0, 1, 2, 5, 3, 100, 100);
    struct Tick t2 = tick(2, id01, no_ids, 0, &e2, &d2, &r2);
    fingerprint = hash_tick(fingerprint, &t2);

    struct State s3 = state(6, 0, 2, 100, 1, 1, 0, 0);
    struct Output o3 = output(s3, 0, 0, UINT64_C(65536), landing_sound, 1, NULL, 0, 0);
    struct Intent i3 = { 3, id01, 0, (int32_t)UINT32_C(0x50168081), 0 };
    struct Delivery d3 = { &i3, 1, &i3, 1, no_ids, 0, no_ids, 0, no_intents, 0 };
    struct Effect e3 = { id01, o3, &i3, 1 };
    struct Record r3 = record(id01, 0, 32, 2, 0, -1, 6, 4, 0, 1, 0, 2, 100, 100);
    struct Tick t3 = tick(3, id01, no_ids, 0, &e3, &d3, &r3);
    fingerprint = hash_tick(fingerprint, &t3);

    struct State s4 = state(8, 0, 3, 200, 1, 0, 1, 0);
    struct Output o4 = output(s4, 2, 0, UINT64_C(99312), NULL, 0, death_sound, 1, 1);
    struct Intent i4[] = {
        { 4, id01, 0, (int32_t)UINT32_C(0x5147C081), 1 },
        { 5, id01, 1, 1, 0 },
        { 6, id01, 1, 2, 0 },
        { 7, id01, 2, 1, 0 },
        { 8, id01, 9, 1, 0 }
    };
    struct Delivery d4 = { i4, 5, i4, 5, no_ids, 0, no_ids, 0, no_intents, 0 };
    struct Effect e4 = { id01, o4, i4, 5 };
    struct Record r4 = record(id01, 0, 48, 0, 0, 1, 8, 7, 0, 1, 2, 3, 200, 100);
    struct Tick t4 = tick(4, id01, no_ids, 0, &e4, &d4, &r4);
    fingerprint = hash_tick(fingerprint, &t4);

    struct State s5 = state(8, 0, 3, 200, 2, 0, 1, 0);
    struct Output o5 = output(s5, 0, 0, UINT64_C(66048), NULL, 0, NULL, 0, 0);
    struct Delivery d5 = { no_intents, 0, no_intents, 0, no_ids, 0, no_ids, 0, no_intents, 0 };
    struct Effect e5 = { id01, o5, no_intents, 0 };
    struct ID unloaded5[] = { id01 };
    struct Tick t5 = tick(5, id01, unloaded5, 1, &e5, &d5, (struct Record *)&no_record);
    fingerprint = hash_tick(fingerprint, &t5);

    struct State s6 = state(0, 0, 3, 0, 1, 0, 1, 0);
    struct Output o6 = output(s6, 0, 0, UINT64_C(139264), NULL, 0, NULL, 0, 0);
    struct Delivery d6 = { no_intents, 0, no_intents, 0, no_ids, 0, no_ids, 0, no_intents, 0 };
    struct Effect e6 = { id02, o6, no_intents, 0 };
    struct Record r6 = record(id02, 1, 48, 0, 0, 1, 0, 0, 0, 1, 0, 3, 0, 0);
    struct Tick t6 = tick(6, id02, no_ids, 0, &e6, &d6, &r6);
    fingerprint = hash_tick(fingerprint, &t6);

    printf("kingBobombObjectBridgeFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    printf("SM64 Modern King Bob-omb object bridge C contract passed\n");
    return 0;
}
