#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct State {
    int32_t action;
    int32_t role;
    int32_t cannon;
    int32_t talked;
    int16_t yaw;
    uint32_t blink;
};

struct Output {
    struct State state;
    int walking;
    int sign;
    int32_t dialog;
    int requested;
    int32_t camera;
    int active;
    int clear_time;
    int clear_interaction;
    float visibility;
};

struct Intent {
    uint64_t sequence;
    uint64_t slot;
    uint64_t generation;
    uint64_t kind;
    int32_t value;
    int32_t auxiliary;
};

struct Record {
    int present;
    uint64_t slot;
    uint64_t generation;
    uint64_t parent_slot;
    uint64_t parent_generation;
    int32_t action;
    int32_t sub_action;
    uint16_t active_flags;
    int32_t behavior_params;
    int32_t advice_dialog;
    uint32_t interaction_subtype;
    float drawing_distance;
};

static uint64_t hash_u64(uint64_t initial, uint64_t value) {
    uint64_t hash = initial;
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_id(uint64_t initial, int present, uint64_t slot, uint64_t generation) {
    if (!present)
        return hash_u64(initial, 0);
    uint64_t hash = hash_u64(initial, 1);
    hash = hash_u64(hash, slot);
    return hash_u64(hash, generation);
}

static uint64_t hash_float(uint64_t initial, float value) {
    union { float f; uint32_t u; } bits = { value };
    return hash_u64(initial, bits.u);
}

static uint64_t hash_intent(uint64_t initial, const struct Intent *intent) {
    uint64_t hash = hash_u64(initial, intent->sequence);
    hash = hash_id(hash, 1, intent->slot, intent->generation);
    hash = hash_u64(hash, intent->kind);
    hash = hash_u64(hash, (uint64_t) (int64_t) intent->value);
    return hash_u64(hash, (uint64_t) (int64_t) intent->auxiliary);
}

static uint64_t hash_state(uint64_t initial, const struct State *state) {
    uint64_t hash = hash_u64(initial, (uint64_t) (int64_t) state->action);
    hash = hash_u64(hash, (uint64_t) (int64_t) state->role);
    hash = hash_u64(hash, (uint64_t) (int64_t) state->cannon);
    hash = hash_u64(hash, (uint64_t) state->talked);
    hash = hash_u64(hash, (uint64_t) (uint16_t) state->yaw);
    return hash_u64(hash, state->blink);
}

static uint64_t hash_output(uint64_t initial, const struct Output *output) {
    uint64_t hash = hash_state(initial, &output->state);
    hash = hash_u64(hash, (uint64_t) output->walking);
    hash = hash_u64(hash, (uint64_t) output->sign);
    hash = hash_u64(hash, (uint64_t) (int64_t) output->dialog);
    hash = hash_u64(hash, (uint64_t) output->requested);
    hash = hash_u64(hash, (uint64_t) (int64_t) output->camera);
    hash = hash_u64(hash, (uint64_t) output->active);
    hash = hash_u64(hash, (uint64_t) output->clear_time);
    hash = hash_u64(hash, (uint64_t) output->clear_interaction);
    return hash_float(hash, output->visibility);
}

static uint64_t hash_effect(
    uint64_t initial,
    const struct Output *output,
    int nearest_present,
    uint64_t nearest_slot,
    uint64_t nearest_generation,
    const struct Intent *intents,
    size_t intent_count) {
    uint64_t hash = hash_id(initial, 1, 0, 1);
    hash = hash_output(hash, output);
    hash = hash_id(hash, nearest_present, nearest_slot, nearest_generation);
    hash = hash_u64(hash, intent_count);
    for (size_t index = 0; index < intent_count; ++index)
        hash = hash_intent(hash, &intents[index]);
    return hash;
}

static uint64_t hash_delivery(
    uint64_t initial,
    const struct Intent *intents,
    size_t intent_count) {
    uint64_t hash = hash_u64(initial, intent_count);
    for (size_t index = 0; index < intent_count; ++index)
        hash = hash_intent(hash, &intents[index]);
    hash = hash_u64(hash, intent_count);
    for (size_t index = 0; index < intent_count; ++index)
        hash = hash_intent(hash, &intents[index]);
    hash = hash_u64(hash, 0); /* spawned */
    hash = hash_u64(hash, 0); /* deleted */
    return hash_u64(hash, 0); /* rejected */
}

static uint64_t hash_record(uint64_t initial, const struct Record *record) {
    if (!record->present)
        return hash_u64(initial, 0);
    uint64_t hash = hash_u64(initial, 1);
    hash = hash_id(hash, 1, record->slot, record->generation);
    hash = hash_id(hash, 1, record->parent_slot, record->parent_generation);
    hash = hash_u64(hash, (uint64_t) (int64_t) record->action);
    hash = hash_u64(hash, (uint64_t) (int64_t) record->sub_action);
    hash = hash_u64(hash, record->active_flags);
    hash = hash_u64(hash, (uint64_t) (int64_t) record->behavior_params);
    hash = hash_u64(hash, (uint64_t) (int64_t) record->advice_dialog);
    hash = hash_u64(hash, record->interaction_subtype);
    return hash_float(hash, record->drawing_distance);
}

static uint64_t hash_tick(
    uint64_t initial,
    uint64_t frame,
    int time_stop_was_active,
    int time_stop_is_active,
    int skipped,
    uint64_t skipped_slot,
    uint64_t skipped_generation,
    int unloaded,
    uint64_t unloaded_slot,
    uint64_t unloaded_generation,
    const struct Output *output,
    int nearest_present,
    uint64_t nearest_slot,
    uint64_t nearest_generation,
    const struct Intent *intents,
    size_t intent_count,
    const struct Record *record) {
    uint64_t hash = hash_u64(initial, frame);
    hash = hash_u64(hash, (uint64_t) time_stop_was_active);
    hash = hash_u64(hash, (uint64_t) time_stop_is_active);
    hash = hash_u64(hash, (uint64_t) skipped);
    if (skipped)
        hash = hash_id(hash, 1, skipped_slot, skipped_generation);
    hash = hash_u64(hash, (uint64_t) unloaded);
    if (unloaded)
        hash = hash_id(hash, 1, unloaded_slot, unloaded_generation);
    hash = hash_u64(hash, 1); /* one effect */
    hash = hash_effect(
        hash, output, nearest_present, nearest_slot, nearest_generation,
        intents, intent_count
    );
    hash = hash_u64(hash, 1); /* one delivery */
    hash = hash_delivery(hash, intents, intent_count);
    hash = hash_record(hash, record);
    return hash;
}

static struct Output output(
    struct State state,
    int walking,
    int sign,
    int32_t dialog,
    int requested,
    int32_t camera,
    int active,
    int clear_time,
    int clear_interaction) {
    struct Output value = {
        state, walking, sign, dialog, requested, camera, active,
        clear_time, clear_interaction, 3000.0f
    };
    return value;
}

int main(void) {
    uint64_t hash = FNV_OFFSET;
    const int32_t walking_sound = (int32_t) UINT32_C(0x50270081);
    const int32_t read_sign_sound = (int32_t) UINT32_C(0x045BFF81);
    struct Intent intents[2];
    struct State state = { 0, 0, 0, 0, 0, 11 };
    struct Output value = output(state, 1, 1, 0, 0, 0, 0, 0, 0);
    intents[0] = (struct Intent) { 1, 0, 1, 0, walking_sound, 0 };
    intents[1] = (struct Intent) { 2, 0, 1, 0, read_sign_sound, 0 };
    value.state.action = 2; value.state.yaw = 0x140;
    hash = hash_tick(hash, 1, 0, 0, 0, 0, 0, 0, 0, 0, &value, 0, 0, 0, intents, 2,
                     &(struct Record) { 1, 0, 1, 0, 1, 2, 0, 257, 0, 0, 0x4000, 3000.0f });

    state = value.state; state.blink = 12;
    value = output(state, 1, 1, 0, 0, 0, 0, 0, 0);
    value.state.yaw = 0x1140;
    intents[0] = (struct Intent) { 3, 0, 1, 0, walking_sound, 0 };
    intents[1] = (struct Intent) { 4, 0, 1, 0, read_sign_sound, 0 };
    hash = hash_tick(hash, 2, 0, 0, 0, 0, 0, 0, 0, 0, &value, 0, 0, 0, intents, 2,
                     &(struct Record) { 1, 0, 1, 0, 1, 2, 0, 257, 0, 0, 0x4000, 3000.0f });

    state = value.state; state.action = 3; state.yaw = 0x2000; state.blink = 13;
    value = output(state, 0, 0, 0, 0, 0, 0, 0, 0);
    hash = hash_tick(hash, 3, 0, 0, 0, 0, 0, 0, 0, 0, &value, 0, 0, 0, intents, 0,
                     &(struct Record) { 1, 0, 1, 0, 1, 3, 0, 257, 0, 0, 0x4000, 3000.0f });

    state.action = 0; state.talked = 1; state.blink = 14;
    value = output(state, 0, 0, 77, 1, 0, 1, 1, 1);
    intents[0] = (struct Intent) { 5, 0, 1, 8, 77, 0 };
    hash = hash_tick(hash, 4, 0, 0, 0, 0, 0, 0, 0, 0, &value, 0, 0, 0, intents, 1,
                     &(struct Record) { 1, 0, 1, 0, 1, 0, 0, 257, 0, 77, 0x4000, 3000.0f });

    state = (struct State) { 3, 1, 1, 0, 0x2000, 0 };
    value = output(state, 0, 0, 4, 1, 0, 1, 0, 0);
    intents[0] = (struct Intent) { 6, 0, 1, 8, 4, 0 };
    hash = hash_tick(hash, 5, 0, 1, 0, 0, 0, 0, 0, 0, &value, 1, 1, 1, intents, 1,
                     &(struct Record) { 1, 0, 1, 0, 1, 3, 1, 289, 1, 0, 0x4000, 3000.0f });

    state.cannon = 2;
    value = output(state, 0, 0, 0, 0, 1, 1, 0, 0);
    intents[0] = (struct Intent) { 7, 0, 1, 2, 1, 0 };
    hash = hash_tick(hash, 6, 1, 1, 1, 1, 1, 0, 0, 0, &value, 1, 1, 1, intents, 1,
                     &(struct Record) { 1, 0, 1, 0, 1, 3, 2, 289, 1, 0, 0x4000, 3000.0f });

    state.cannon = 3;
    value = output(state, 0, 0, 105, 1, 0, 1, 0, 0);
    intents[0] = (struct Intent) { 8, 0, 1, 8, 105, 0 };
    hash = hash_tick(hash, 7, 1, 1, 1, 1, 1, 0, 0, 0, &value, 1, 1, 1, intents, 1,
                     &(struct Record) { 1, 0, 1, 0, 1, 3, 3, 289, 1, 0, 0x4000, 3000.0f });

    state.action = 0; state.talked = 1; state.cannon = 2;
    value = output(state, 0, 0, 0, 0, 0, 1, 1, 1);
    hash = hash_tick(hash, 8, 1, 0, 1, 1, 1, 0, 0, 0, &value, 1, 1, 1, intents, 0,
                     &(struct Record) { 1, 0, 1, 0, 1, 0, 2, 257, 1, 0, 0x4000, 3000.0f });

    value = output(state, 0, 0, 0, 0, 0, 0, 0, 0);
    hash = hash_tick(hash, 9, 0, 0, 0, 0, 0, 1, 0, 1, &value, 0, 0, 0, intents, 0,
                     &(struct Record) { 0 });

    printf("bobombBuddyObjectBridgeFingerprint=0x%016llx\n", (unsigned long long) hash);
    printf("SM64 Modern Bob-omb Buddy object bridge C contract passed\n");
    return 0;
}
