#include <stdint.h>
#include <stdio.h>

enum NoteList { DETACHED = 0, DISABLED = 1, DECAYING = 2, RELEASING = 3, ACTIVE = 4 };
enum EventKind {
    CHANNEL_ALLOCATED = 1, CHANNEL_REINITIALIZED, CHANNEL_ALLOCATION_FAILED,
    LAYER_ALLOCATED, LAYER_REUSED, LAYER_ALLOCATION_FAILED, LAYER_FREED,
    NOTE_FROM_DISABLED, NOTE_FROM_DECAYING, NOTE_FROM_ACTIVE, NOTE_LAYER_REUSE,
    NOTE_BANK_UNAVAILABLE, NOTE_ALLOCATION_FAILED, CHANNEL_DISABLED
};
enum Scope { CHANNEL_SCOPE = 0, SEQUENCE_SCOPE = 1, GLOBAL_SCOPE = 2 };

struct List { int values[16]; int count; };
struct Note { int id, list, priority, parent, wanted, previous; };
struct Layer { int id, enabled, finished, channel, note, status; };
struct Channel { int id, enabled, finished, priority, policy, layers[4]; struct List lists[5]; };
struct Event { int kind, scope, index, noteID, value; };
struct Trace { struct Event events[32]; int count, selected, failed; };
struct Model {
    struct Channel channels[2];
    struct Layer layers[4];
    struct Note notes[6];
    struct List sequenceLists[5];
    struct List globalLists[5];
    int channelSlots[16];
    int freeLayers[4];
    int freeLayerCount;
};

static void append(struct List *list, int value) { list->values[list->count++] = value; }
static void prepend(struct List *list, int value) {
    for (int i = list->count; i > 0; --i) list->values[i] = list->values[i - 1];
    list->values[0] = value; list->count++;
}
static int pop_back(struct List *list) { return list->count == 0 ? -1 : list->values[--list->count]; }
static void remove_value(struct List *list, int value) {
    for (int i = 0; i < list->count; ++i) if (list->values[i] == value) {
        for (int j = i; j + 1 < list->count; ++j) list->values[j] = list->values[j + 1];
        list->count--; return;
    }
}
static int list_contains(const struct List *list, int value) {
    for (int i = 0; i < list->count; ++i) if (list->values[i] == value) return 1;
    return 0;
}
static void emit(struct Trace *trace, int kind, int scope, int index, int noteID, int value) {
    trace->events[trace->count++] = (struct Event){ kind, scope, index, noteID, value };
}
static struct Trace trace_empty(void) { return (struct Trace){ .selected = -1 }; }

static struct List *lists_for(struct Model *model, int scope, int channelID) {
    if (scope == CHANNEL_SCOPE) return model->channels[channelID].lists;
    if (scope == SEQUENCE_SCOPE) return model->sequenceLists;
    return model->globalLists;
}
static int note_scope(const struct Model *model, int noteID, int *scope, int *channelID) {
    const struct Note *note = &model->notes[noteID];
    for (int channel = 0; channel < 2; ++channel) {
        if (list_contains(&model->channels[channel].lists[note->list], noteID)) {
            *scope = CHANNEL_SCOPE; *channelID = channel; return 1;
        }
    }
    if (list_contains(&model->sequenceLists[note->list], noteID)) { *scope = SEQUENCE_SCOPE; *channelID = -1; return 1; }
    *scope = GLOBAL_SCOPE; *channelID = -1; return 1;
}
static void detach_note(struct Model *model, int noteID) {
    int scope, channelID; note_scope(model, noteID, &scope, &channelID);
    remove_value(&lists_for(model, scope, channelID)[model->notes[noteID].list], noteID);
    model->notes[noteID].list = DETACHED;
}
static void append_note(struct Model *model, int scope, int channelID, int list, int noteID, int front) {
    struct List *lists = lists_for(model, scope, channelID);
    if (front) prepend(&lists[list], noteID); else append(&lists[list], noteID);
}
static void move_note(struct Model *model, int noteID, int targetList, int front) {
    int scope, channelID; note_scope(model, noteID, &scope, &channelID);
    const int oldList = model->notes[noteID].list;
    remove_value(&lists_for(model, scope, channelID)[oldList], noteID);
    model->notes[noteID].list = targetList;
    append_note(model, scope, channelID, targetList, noteID, front);
}

static struct Trace init_channels(struct Model *model, int mask) {
    struct Trace trace = trace_empty();
    for (int slot = 0; slot < 16; ++slot) if ((mask & (1 << slot)) != 0) {
        int channelID = model->channelSlots[slot];
        if (channelID >= 0) {
            model->channels[channelID].enabled = 0;
            model->channels[channelID].finished = 1;
            emit(&trace, CHANNEL_REINITIALIZED, slot, channelID, -1, 0);
        }
        channelID = -1;
        for (int i = 0; i < 2; ++i) if (!model->channels[i].enabled) { channelID = i; break; }
        if (channelID < 0) { emit(&trace, CHANNEL_ALLOCATION_FAILED, slot, -1, -1, 0); trace.failed = 1; model->channelSlots[slot] = -1; continue; }
        model->channels[channelID].enabled = 1;
        model->channels[channelID].finished = 0;
        model->channels[channelID].priority = 3;
        model->channels[channelID].policy = 0;
        for (int i = 0; i < 4; ++i) model->channels[channelID].layers[i] = -1;
        for (int i = 0; i < 5; ++i) model->channels[channelID].lists[i].count = 0;
        model->channelSlots[slot] = channelID;
        emit(&trace, CHANNEL_ALLOCATED, slot, channelID, -1, 3);
    }
    return trace;
}

static struct Trace set_layer(struct Model *model, int slot, int layerIndex) {
    struct Trace trace = trace_empty();
    if (slot < 0 || slot >= 16 || model->channelSlots[slot] < 0) { emit(&trace, LAYER_ALLOCATION_FAILED, slot, layerIndex, -1, 0); trace.failed = 1; return trace; }
    const int channelID = model->channelSlots[slot];
    if (model->channels[channelID].layers[layerIndex] >= 0) {
        const int layerID = model->channels[channelID].layers[layerIndex];
        emit(&trace, LAYER_REUSED, channelID, layerID, model->layers[layerID].note, layerIndex);
        model->layers[layerID].note = -1;
        model->layers[layerID].enabled = 1;
        return trace;
    }
    if (model->freeLayerCount == 0) { emit(&trace, LAYER_ALLOCATION_FAILED, channelID, layerIndex, -1, 0); trace.failed = 1; return trace; }
    const int layerID = model->freeLayers[--model->freeLayerCount];
    model->channels[channelID].layers[layerIndex] = layerID;
    model->layers[layerID] = (struct Layer){ layerID, 1, 0, channelID, -1, 0 };
    emit(&trace, LAYER_ALLOCATED, channelID, layerID, -1, layerIndex);
    return trace;
}

static void init_note(struct Model *model, int noteID, int layerID, int scope, int channelID) {
    model->notes[noteID].parent = layerID;
    model->notes[noteID].wanted = -1;
    model->notes[noteID].previous = -1;
    model->notes[noteID].list = ACTIVE;
    append_note(model, scope, channelID, ACTIVE, noteID, 1);
    model->layers[layerID].note = noteID;
    model->layers[layerID].status = 3;
}

static int take_disabled(struct Model *model, int scope, int channelID, int layerID, int bankAvailable, struct Trace *trace) {
    struct List *lists = lists_for(model, scope, channelID);
    const int noteID = pop_back(&lists[DISABLED]);
    if (noteID < 0) return -1;
    if (!bankAvailable) {
        model->notes[noteID].list = DISABLED;
        prepend(&model->globalLists[DISABLED], noteID);
        emit(trace, NOTE_BANK_UNAVAILABLE, layerID, 0, noteID, 0);
        return -1;
    }
    init_note(model, noteID, layerID, scope, channelID);
    emit(trace, NOTE_FROM_DISABLED, scope == CHANNEL_SCOPE ? channelID : (scope == SEQUENCE_SCOPE ? -2 : -1), layerID, noteID, 0);
    return noteID;
}
static int take_decaying(struct Model *model, int scope, int channelID, int layerID, struct Trace *trace) {
    struct List *lists = lists_for(model, scope, channelID);
    const int noteID = pop_back(&lists[DECAYING]);
    if (noteID < 0) return -1;
    model->notes[noteID].wanted = layerID;
    model->notes[noteID].priority = 1;
    model->notes[noteID].list = RELEASING;
    append(&lists[RELEASING], noteID);
    model->layers[layerID].note = noteID;
    model->layers[layerID].status = 3;
    emit(trace, NOTE_FROM_DECAYING, scope == CHANNEL_SCOPE ? channelID : (scope == SEQUENCE_SCOPE ? -2 : -1), layerID, noteID, 1);
    return noteID;
}
static int take_active(struct Model *model, int scope, int channelID, int layerID, struct Trace *trace) {
    struct List *lists = lists_for(model, scope, channelID);
    if (lists[ACTIVE].count == 0) return -1;
    int best = lists[ACTIVE].values[0];
    for (int i = 1; i < lists[ACTIVE].count; ++i) {
        const int candidate = lists[ACTIVE].values[i];
        if (model->notes[best].priority >= model->notes[candidate].priority) best = candidate;
    }
    if (model->channels[channelID].priority < model->notes[best].priority) return -1;
    remove_value(&lists[ACTIVE], best);
    model->notes[best].wanted = layerID;
    model->notes[best].list = RELEASING;
    append(&lists[RELEASING], best);
    model->layers[layerID].note = best;
    model->layers[layerID].status = 3;
    emit(trace, NOTE_FROM_ACTIVE, scope == CHANNEL_SCOPE ? channelID : (scope == SEQUENCE_SCOPE ? -2 : -1), layerID, best, model->notes[best].priority);
    return best;
}

static struct Trace allocate_note(struct Model *model, int slot, int layerIndex, int bankAvailable) {
    struct Trace trace = trace_empty();
    const int channelID = model->channelSlots[slot];
    const int layerID = model->channels[channelID].layers[layerIndex];
    const int policy = model->channels[channelID].policy;
    if (policy & 1) {
        const int noteID = model->layers[layerID].note;
        if (noteID >= 0 && model->notes[noteID].previous == layerID && model->notes[noteID].wanted < 0) {
            move_note(model, noteID, RELEASING, 0);
            model->notes[noteID].wanted = layerID;
            emit(&trace, NOTE_LAYER_REUSE, layerID, layerIndex, noteID, 0);
            trace.selected = noteID; return trace;
        }
    }
    int scopes[3], scopeCount = 0;
    if (policy & 2) scopes[scopeCount++] = CHANNEL_SCOPE;
    if (policy & 4) { scopes[scopeCount++] = CHANNEL_SCOPE; scopes[scopeCount++] = SEQUENCE_SCOPE; }
    if (policy & 8) scopes[scopeCount++] = GLOBAL_SCOPE;
    if (scopeCount == 0) { scopes[scopeCount++] = CHANNEL_SCOPE; scopes[scopeCount++] = SEQUENCE_SCOPE; scopes[scopeCount++] = GLOBAL_SCOPE; }
    for (int i = 0; i < scopeCount; ++i) {
        const int scope = scopes[i];
        const int channelForScope = scope == CHANNEL_SCOPE ? channelID : -1;
        int noteID = take_disabled(model, scope, channelForScope, layerID, bankAvailable, &trace);
        if (noteID >= 0) { trace.selected = noteID; return trace; }
        noteID = take_decaying(model, scope, channelForScope, layerID, &trace);
        if (noteID >= 0) { trace.selected = noteID; return trace; }
        noteID = take_active(model, scope, channelForScope < 0 ? 0 : channelForScope, layerID, &trace);
        if (noteID >= 0) { trace.selected = noteID; return trace; }
    }
    model->layers[layerID].status = 0;
    emit(&trace, NOTE_ALLOCATION_FAILED, layerID, layerIndex, -1, policy);
    trace.failed = 1;
    return trace;
}

static void seed_note(struct Model *model, int noteID, int scope, int channelID, int list, int priority) {
    detach_note(model, noteID);
    model->notes[noteID].list = list;
    model->notes[noteID].priority = priority;
    append_note(model, scope, channelID, list, noteID, 0);
}
static void mark_reusable(struct Model *model, int slot, int layerIndex) {
    const int channelID = model->channelSlots[slot];
    const int layerID = model->channels[channelID].layers[layerIndex];
    const int noteID = model->layers[layerID].note;
    model->notes[noteID].previous = layerID;
    model->notes[noteID].wanted = -1;
}
static struct Trace disable_channel(struct Model *model, int slot) {
    struct Trace trace = trace_empty();
    const int channelID = model->channelSlots[slot];
    for (int layerIndex = 0; layerIndex < 4; ++layerIndex) {
        const int layerID = model->channels[channelID].layers[layerIndex];
        if (layerID < 0) continue;
        const int noteID = model->layers[layerID].note;
        if (noteID >= 0) { move_note(model, noteID, DECAYING, 1); model->notes[noteID].previous = layerID; }
        model->layers[layerID] = (struct Layer){ layerID, 0, 1, -1, -1, 0 };
        model->freeLayers[model->freeLayerCount++] = layerID;
        emit(&trace, LAYER_FREED, channelID, layerID, -1, layerIndex);
    }
    for (int list = DISABLED; list <= ACTIVE; ++list) {
        while (model->channels[channelID].lists[list].count > 0) {
            const int noteID = model->channels[channelID].lists[list].values[0];
            remove_value(&model->channels[channelID].lists[list], noteID);
            model->notes[noteID].list = list;
            append(&model->globalLists[list], noteID);
        }
    }
    model->channels[channelID].enabled = 0;
    model->channels[channelID].finished = 1;
    model->channelSlots[slot] = -1;
    emit(&trace, CHANNEL_DISABLED, channelID, channelID, -1, 0);
    return trace;
}

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (int shift = 0; shift <= 24; shift += 8) { hash ^= (uint64_t)((value >> shift) & 0xffu); hash *= UINT64_C(1099511628211); }
    return hash;
}
static uint64_t hash_trace(uint64_t hash, const struct Trace *trace) {
    hash = hash_u32(hash, (uint32_t)trace->count);
    for (int i = 0; i < trace->count; ++i) {
        hash = hash_u32(hash, (uint32_t)trace->events[i].kind);
        hash = hash_u32(hash, (uint32_t)trace->events[i].scope);
        hash = hash_u32(hash, (uint32_t)trace->events[i].index);
        hash = hash_u32(hash, (uint32_t)trace->events[i].noteID);
        hash = hash_u32(hash, (uint32_t)trace->events[i].value);
    }
    hash = hash_u32(hash, (uint32_t)trace->selected);
    hash = hash_u32(hash, (uint32_t)trace->failed);
    return hash;
}
static uint64_t hash_model(uint64_t hash, const struct Model *model) {
    for (int i = 0; i < 16; ++i) hash = hash_u32(hash, (uint32_t)model->channelSlots[i]);
    for (int i = 0; i < model->freeLayerCount; ++i) hash = hash_u32(hash, (uint32_t)model->freeLayers[i]);
    for (int i = 0; i < 4; ++i) {
        const struct Layer *layer = &model->layers[i];
        hash = hash_u32(hash, (uint32_t)layer->id); hash = hash_u32(hash, (uint32_t)layer->enabled);
        hash = hash_u32(hash, (uint32_t)layer->finished); hash = hash_u32(hash, (uint32_t)layer->channel);
        hash = hash_u32(hash, (uint32_t)layer->note); hash = hash_u32(hash, (uint32_t)layer->status);
    }
    for (int i = 0; i < 6; ++i) {
        const struct Note *note = &model->notes[i];
        hash = hash_u32(hash, (uint32_t)note->id); hash = hash_u32(hash, (uint32_t)note->list);
        hash = hash_u32(hash, (uint32_t)note->priority); hash = hash_u32(hash, (uint32_t)note->parent);
        hash = hash_u32(hash, (uint32_t)note->wanted); hash = hash_u32(hash, (uint32_t)note->previous);
    }
    for (int scope = 0; scope < 2; ++scope) {
        const struct List *lists = scope == 0 ? model->globalLists : model->sequenceLists;
        for (int list = DISABLED; list <= ACTIVE; ++list) {
            for (int i = 0; i < lists[list].count; ++i) hash = hash_u32(hash, (uint32_t)lists[list].values[i]);
            hash = hash_u32(hash, UINT32_C(0xffffffff));
        }
    }
    return hash;
}

int main(void) {
    struct Model model = { 0 };
    for (int i = 0; i < 16; ++i) model.channelSlots[i] = -1;
    for (int i = 0; i < 2; ++i) { model.channels[i].id = i; for (int j = 0; j < 4; ++j) model.channels[i].layers[j] = -1; }
    for (int i = 0; i < 4; ++i) { model.layers[i] = (struct Layer){ i, 0, 0, -1, -1, 0 }; model.freeLayers[i] = i; }
    model.freeLayerCount = 4;
    for (int i = 0; i < 6; ++i) { model.notes[i] = (struct Note){ i, DISABLED, 3, -1, -1, -1 }; append(&model.globalLists[DISABLED], i); }

    uint64_t fingerprint = UINT64_C(1469598103934665603);
    struct Trace channels = init_channels(&model, 3); if (channels.failed) return 1; fingerprint = hash_trace(fingerprint, &channels);
    struct Trace layer00 = set_layer(&model, 0, 0); struct Trace layer01 = set_layer(&model, 0, 1); struct Trace layer10 = set_layer(&model, 1, 0);
    fingerprint = hash_trace(fingerprint, &layer00); fingerprint = hash_trace(fingerprint, &layer01); fingerprint = hash_trace(fingerprint, &layer10);
    seed_note(&model, 0, CHANNEL_SCOPE, 0, DISABLED, 3); seed_note(&model, 1, CHANNEL_SCOPE, 0, DECAYING, 2);
    seed_note(&model, 2, CHANNEL_SCOPE, 0, ACTIVE, 2); seed_note(&model, 3, SEQUENCE_SCOPE, -1, DISABLED, 3); seed_note(&model, 4, GLOBAL_SCOPE, -1, DISABLED, 3);
    model.channels[0].policy = 2;
    struct Trace disabled = allocate_note(&model, 0, 0, 1); fingerprint = hash_trace(fingerprint, &disabled); if (disabled.selected != 0) return 2;
    struct Trace decaying = allocate_note(&model, 0, 1, 1); fingerprint = hash_trace(fingerprint, &decaying); if (decaying.selected != 1) return 3;
    struct Trace active = allocate_note(&model, 0, 0, 1); fingerprint = hash_trace(fingerprint, &active); if (active.selected != 2) return 4;
    model.channels[1].policy = 4;
    struct Trace sequence = allocate_note(&model, 1, 0, 1); fingerprint = hash_trace(fingerprint, &sequence); if (sequence.selected != 3) return 5;
    model.channels[0].policy = 8;
    struct Trace global = allocate_note(&model, 0, 1, 1); fingerprint = hash_trace(fingerprint, &global); if (global.selected != 4) return 6;
    model.channels[0].policy = 1; mark_reusable(&model, 0, 0);
    struct Trace reused = allocate_note(&model, 0, 0, 1); fingerprint = hash_trace(fingerprint, &reused); if (reused.selected != 2) return 7;
    model.channels[1].policy = 8;
    struct Trace unavailable = allocate_note(&model, 1, 0, 0); fingerprint = hash_trace(fingerprint, &unavailable); if (unavailable.selected != 4 || unavailable.failed) return 8;
    struct Trace disabledChannel = disable_channel(&model, 1); fingerprint = hash_trace(fingerprint, &disabledChannel); if (model.channelSlots[1] != -1) return 9;
    fingerprint = hash_model(fingerprint, &model);
    printf("audioPoolsFingerprint=0x%llx\n", (unsigned long long)fingerprint);
    printf("SM64 Modern audio pools C contract passed\n");
    return 0;
}
