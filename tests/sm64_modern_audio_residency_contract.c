#include <stdint.h>
#include <stdio.h>

enum Status { NOT_LOADED = 0, IN_PROGRESS = 1, COMPLETE = 2, DISCARDABLE = 3 };
enum Resource { SEQUENCE = 0, BANK = 1 };
enum StreamClass { SHORT_STREAM = 0, LONG_STREAM = 1 };
enum EventKind {
    POOL_SIDE_SELECTED = 1, RESOURCE_EVICTED, ALLOCATION_FAILED, LOAD_STARTED,
    LOAD_COMPLETED, RESOURCE_DISCARDABLE, RESIDENCY_TOUCHED,
    INSTRUMENT_UNAVAILABLE, INSTRUMENT_OUT_OF_RANGE, INSTRUMENT_MISSING,
    INSTRUMENT_RESOLVED, DRUM_OUT_OF_RANGE, DRUM_MISSING, DRUM_RESOLVED,
    SOUND_RANGE_SELECTED, SAMPLE_UNAVAILABLE, SAMPLE_RESOLVED, STREAM_HIT,
    STREAM_MISS, STREAM_ALLOCATED, STREAM_EXPIRED, STREAM_ALLOCATION_FAILED
};

struct Event { int kind, resource, id, index, value; };
struct Trace { struct Event events[32]; int count, selected, failed; };
struct Slot { int side, id, size, status, generation; };
struct StreamSlot { int index, sampleID, source, bufferSize, ttl, reuseIndex; };
struct Sound { int has, sampleID, tuningMilli; };
struct Instrument {
    int present, id, loaded, low, high, releaseRate;
    struct Sound lowSound, normalSound, highSound;
};
struct Drum { int present, id, loaded, releaseRate, pan; struct Sound sound; };
struct Bank { int present, instrumentsCount, drumsCount; struct Instrument instruments[3]; struct Drum drums[2]; };
struct Model {
    int bankStatus[12], sequenceStatus[16], bankNextSide, sequenceNextSide;
    struct Slot bankSlots[2], sequenceSlots[2];
    struct Bank banks[12];
    int sampleLoaded[13];
    struct StreamSlot shortSlots[2], longSlots[2];
    int shortQueue[4], shortQueueCount, longQueue[4], longQueueCount;
};

static struct Trace trace_empty(void) { return (struct Trace){ .selected = -1 }; }
static void emit(struct Trace *trace, int kind, int resource, int id, int index, int value) {
    trace->events[trace->count++] = (struct Event){ kind, resource, id, index, value };
}
static struct Trace failure(int kind, int resource, int id, int index) {
    struct Trace trace = trace_empty();
    emit(&trace, kind, resource, id, index, 0); trace.failed = 1; return trace;
}
static int *statuses(struct Model *model, int resource) { return resource == BANK ? model->bankStatus : model->sequenceStatus; }
static struct Slot *slots(struct Model *model, int resource) { return resource == BANK ? model->bankSlots : model->sequenceSlots; }
static int *next_side(struct Model *model, int resource) { return resource == BANK ? &model->bankNextSide : &model->sequenceNextSide; }
static int valid_resource(int resource, int id) { return resource == BANK ? id >= 0 && id < 12 : id >= 0 && id < 16; }
static int slot_index(struct Model *model, int resource, int id) {
    struct Slot *pool = slots(model, resource);
    for (int i = 0; i < 2; ++i) if (pool[i].id == id) return i;
    return -1;
}
static void set_status(struct Model *model, int resource, int id, int status) {
    if (valid_resource(resource, id)) statuses(model, resource)[id] = status;
}

static struct Trace load_resource(struct Model *model, int resource, int id, int size, int asynchronous) {
    if (!valid_resource(resource, id)) return failure(ALLOCATION_FAILED, resource, id, -1);
    int *table = statuses(model, resource); struct Slot *pool = slots(model, resource);
    int first = pool[0].id < 0 ? NOT_LOADED : table[pool[0].id];
    int second = pool[1].id < 0 ? NOT_LOADED : table[pool[1].id];
    int side = -1;
    if (first == NOT_LOADED) side = 0;
    else if (second == NOT_LOADED) side = 1;
    else if (first == DISCARDABLE && second == DISCARDABLE) side = *next_side(model, resource);
    else if (first == DISCARDABLE) side = 0;
    else if (second == DISCARDABLE) side = 1;
    else if (first != IN_PROGRESS) side = 0;
    else if (second != IN_PROGRESS) side = 1;
    if (side < 0) return failure(ALLOCATION_FAILED, resource, id, -1);
    struct Trace trace = trace_empty();
    if (pool[side].id >= 0) {
        const int old = pool[side].id;
        set_status(model, resource, old, NOT_LOADED);
        emit(&trace, RESOURCE_EVICTED, resource, old, side, pool[side].generation);
    }
    pool[side].id = id; pool[side].size = size < 0 ? 0 : size; pool[side].generation++;
    pool[side].status = asynchronous && !(resource == SEQUENCE && size <= 0x40) ? IN_PROGRESS : COMPLETE;
    set_status(model, resource, id, pool[side].status);
    *next_side(model, resource) = side ^ 1;
    emit(&trace, POOL_SIDE_SELECTED, resource, id, side, pool[side].size);
    if (pool[side].status == IN_PROGRESS) emit(&trace, LOAD_STARTED, resource, id, side, pool[side].size);
    else emit(&trace, LOAD_COMPLETED, resource, id, side, pool[side].size);
    trace.selected = id; return trace;
}
static struct Trace complete_resource(struct Model *model, int resource, int id) {
    const int side = slot_index(model, resource, id);
    if (side < 0) return failure(ALLOCATION_FAILED, resource, id, -1);
    set_status(model, resource, id, COMPLETE);
    struct Trace trace = trace_empty(); emit(&trace, LOAD_COMPLETED, resource, id, side, 0); trace.selected = id; return trace;
}
static struct Trace discard_resource(struct Model *model, int resource, int id) {
    if (slot_index(model, resource, id) < 0) return failure(ALLOCATION_FAILED, resource, id, -1);
    set_status(model, resource, id, DISCARDABLE);
    struct Trace trace = trace_empty(); emit(&trace, RESOURCE_DISCARDABLE, resource, id, -1, 0); trace.selected = id; return trace;
}
static struct Trace touch_resource(struct Model *model, int resource, int id) {
    const int side = slot_index(model, resource, id);
    if (side < 0) return failure(ALLOCATION_FAILED, resource, id, -1);
    *next_side(model, resource) = side ^ 1;
    struct Trace trace = trace_empty(); emit(&trace, RESIDENCY_TOUCHED, resource, id, side, *next_side(model, resource)); trace.selected = id; return trace;
}

static struct Trace lookup_instrument(struct Model *model, int bankID, int instrumentID, int fallback, int clamp) {
    if (!valid_resource(BANK, bankID) || model->bankStatus[bankID] < COMPLETE) return failure(INSTRUMENT_UNAVAILABLE, BANK, bankID, instrumentID);
    struct Bank *bank = &model->banks[bankID];
    if (!bank->present || bank->instrumentsCount == 0) return failure(INSTRUMENT_MISSING, BANK, bankID, instrumentID);
    if (instrumentID < 0) return failure(INSTRUMENT_OUT_OF_RANGE, BANK, bankID, instrumentID);
    int candidate = instrumentID;
    if (candidate >= bank->instrumentsCount) {
        if (!clamp) return failure(INSTRUMENT_OUT_OF_RANGE, BANK, bankID, instrumentID);
        candidate = bank->instrumentsCount - 1;
    }
    while (candidate >= 0) {
        struct Instrument *instrument = &bank->instruments[candidate];
        if (instrument->present && instrument->loaded) {
            struct Trace trace = trace_empty(); emit(&trace, INSTRUMENT_RESOLVED, BANK, bankID, candidate, instrument->releaseRate); trace.selected = candidate; return trace;
        }
        if (!fallback) break;
        candidate--;
    }
    return failure(INSTRUMENT_MISSING, BANK, bankID, instrumentID);
}
static struct Trace lookup_drum(struct Model *model, int bankID, int drumID) {
    if (!valid_resource(BANK, bankID) || model->bankStatus[bankID] < COMPLETE) return failure(INSTRUMENT_UNAVAILABLE, BANK, bankID, drumID);
    struct Bank *bank = &model->banks[bankID];
    if (drumID < 0 || drumID >= bank->drumsCount) return failure(DRUM_OUT_OF_RANGE, BANK, bankID, drumID);
    struct Drum *drum = &bank->drums[drumID];
    if (!drum->present || !drum->loaded) return failure(DRUM_MISSING, BANK, bankID, drumID);
    struct Trace trace = trace_empty(); emit(&trace, DRUM_RESOLVED, BANK, bankID, drumID, drum->pan); trace.selected = drumID; return trace;
}
static struct Trace select_sound(struct Model *model, int bankID, int instrumentID, int semitone, int fallback) {
    struct Trace trace = lookup_instrument(model, bankID, instrumentID, fallback, fallback);
    if (trace.failed) return trace;
    const int selected = trace.selected; struct Instrument *instrument = &model->banks[bankID].instruments[selected];
    int range; struct Sound *sound;
    if (semitone < instrument->low) { range = 0; sound = &instrument->lowSound; }
    else if (semitone <= instrument->high) { range = 1; sound = &instrument->normalSound; }
    else { range = 2; sound = &instrument->highSound; }
    emit(&trace, SOUND_RANGE_SELECTED, BANK, bankID, range, semitone);
    if (!sound->has || !model->sampleLoaded[sound->sampleID]) { emit(&trace, SAMPLE_UNAVAILABLE, BANK, bankID, range, semitone); trace.selected = -1; trace.failed = 1; return trace; }
    emit(&trace, SAMPLE_RESOLVED, BANK, sound->sampleID, range, sound->tuningMilli); trace.selected = sound->sampleID; return trace;
}

static int covers(const struct StreamSlot *slot, int address, int size) {
    return slot->sampleID >= 0 && address >= slot->source && size >= 0 && address - slot->source <= slot->bufferSize - size;
}
static void remove_queue(int *queue, int *count, int value) {
    for (int i = 0; i < *count; ++i) if (queue[i] == value) { for (int j = i; j + 1 < *count; ++j) queue[j] = queue[j + 1]; (*count)--; return; }
}
static int take_queue(int *queue, int *count) {
    if (*count == 0) return -1;
    const int value = queue[0];
    for (int i = 0; i + 1 < *count; ++i) queue[i] = queue[i + 1];
    (*count)--;
    return value;
}
static struct Trace request_stream(struct Model *model, int sampleID, int address, int size, int streamClass, int hint) {
    if (sampleID < 0 || sampleID >= 13 || !model->sampleLoaded[sampleID]) return failure(SAMPLE_UNAVAILABLE, BANK, sampleID, -1);
    struct StreamSlot *pool = streamClass == SHORT_STREAM ? model->shortSlots : model->longSlots;
    int *queue = streamClass == SHORT_STREAM ? model->shortQueue : model->longQueue;
    int *queueCount = streamClass == SHORT_STREAM ? &model->shortQueueCount : &model->longQueueCount;
    const int capacity = 2, lifetime = streamClass == SHORT_STREAM ? 2 : 60;
    int hit = -1;
    if (streamClass == SHORT_STREAM && hint >= 0 && hint < capacity && covers(&pool[hint], address, size)) hit = hint;
    if (hit < 0) for (int i = 0; i < capacity; ++i) if (covers(&pool[i], address, size)) { hit = i; break; }
    struct Trace trace = trace_empty();
    if (hit >= 0) {
        emit(&trace, STREAM_HIT, BANK, sampleID, hit, streamClass); pool[hit].ttl = lifetime; remove_queue(queue, queueCount, hit);
        emit(&trace, SAMPLE_RESOLVED, BANK, sampleID, hit, lifetime); trace.selected = hit; return trace;
    }
    emit(&trace, STREAM_MISS, BANK, sampleID, -1, streamClass);
    const int slot = take_queue(queue, queueCount);
    if (slot < 0) { emit(&trace, STREAM_ALLOCATION_FAILED, BANK, sampleID, -1, streamClass); trace.failed = 1; return trace; }
    pool[slot].sampleID = sampleID; pool[slot].source = address & ~0xF; pool[slot].ttl = lifetime; pool[slot].reuseIndex = -1;
    emit(&trace, STREAM_ALLOCATED, BANK, sampleID, slot, pool[slot].source); trace.selected = slot; return trace;
}
static struct Trace advance_streams(struct Model *model) {
    struct Trace trace = trace_empty();
    for (int streamClass = SHORT_STREAM; streamClass <= LONG_STREAM; ++streamClass) {
        struct StreamSlot *pool = streamClass == SHORT_STREAM ? model->shortSlots : model->longSlots;
        int *queue = streamClass == SHORT_STREAM ? model->shortQueue : model->longQueue;
        int *queueCount = streamClass == SHORT_STREAM ? &model->shortQueueCount : &model->longQueueCount;
        for (int i = 0; i < 2; ++i) if (pool[i].sampleID >= 0 && pool[i].ttl > 0) {
            pool[i].ttl--;
            if (pool[i].ttl == 0) { pool[i].reuseIndex = *queueCount; queue[(*queueCount)++] = i; emit(&trace, STREAM_EXPIRED, BANK, pool[i].sampleID, i, streamClass); }
        }
    }
    return trace;
}

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (int shift = 0; shift <= 24; shift += 8) { hash ^= (uint64_t)((value >> shift) & 0xffu); hash *= UINT64_C(1099511628211); }
    return hash;
}
static uint64_t hash_trace(uint64_t hash, const struct Trace *trace) {
    hash = hash_u32(hash, (uint32_t)trace->count);
    for (int i = 0; i < trace->count; ++i) {
        hash = hash_u32(hash, (uint32_t)trace->events[i].kind); hash = hash_u32(hash, (uint32_t)trace->events[i].resource);
        hash = hash_u32(hash, (uint32_t)trace->events[i].id); hash = hash_u32(hash, (uint32_t)trace->events[i].index); hash = hash_u32(hash, (uint32_t)trace->events[i].value);
    }
    hash = hash_u32(hash, (uint32_t)trace->selected); hash = hash_u32(hash, (uint32_t)trace->failed); return hash;
}
static uint64_t hash_slot(uint64_t hash, const struct Slot *slot) {
    hash = hash_u32(hash, (uint32_t)slot->side); hash = hash_u32(hash, (uint32_t)slot->id); hash = hash_u32(hash, (uint32_t)slot->size); hash = hash_u32(hash, (uint32_t)slot->status); hash = hash_u32(hash, (uint32_t)slot->generation); return hash;
}
static uint64_t hash_stream_slot(uint64_t hash, const struct StreamSlot *slot) {
    hash = hash_u32(hash, (uint32_t)slot->index); hash = hash_u32(hash, (uint32_t)slot->sampleID); hash = hash_u32(hash, (uint32_t)slot->source); hash = hash_u32(hash, (uint32_t)slot->bufferSize); hash = hash_u32(hash, (uint32_t)slot->ttl); hash = hash_u32(hash, (uint32_t)slot->reuseIndex); return hash;
}
static uint64_t hash_model(uint64_t hash, const struct Model *model) {
    for (int i = 0; i < 12; ++i) hash = hash_u32(hash, (uint32_t)model->bankStatus[i]);
    for (int i = 0; i < 16; ++i) hash = hash_u32(hash, (uint32_t)model->sequenceStatus[i]);
    hash = hash_u32(hash, (uint32_t)model->bankNextSide); hash = hash_u32(hash, (uint32_t)model->sequenceNextSide);
    for (int i = 0; i < 2; ++i) hash = hash_slot(hash, &model->bankSlots[i]);
    for (int i = 0; i < 2; ++i) hash = hash_slot(hash, &model->sequenceSlots[i]);
    for (int i = 0; i < 2; ++i) hash = hash_stream_slot(hash, &model->shortSlots[i]);
    for (int i = 0; i < 2; ++i) hash = hash_stream_slot(hash, &model->longSlots[i]);
    for (int i = 0; i < model->shortQueueCount; ++i) hash = hash_u32(hash, (uint32_t)model->shortQueue[i]);
    hash = hash_u32(hash, UINT32_C(0xffffffff));
    for (int i = 0; i < model->longQueueCount; ++i) hash = hash_u32(hash, (uint32_t)model->longQueue[i]);
    hash = hash_u32(hash, UINT32_C(0xffffffff)); return hash;
}

static struct Sound make_sound(int sampleID, int tuning) { return (struct Sound){ 1, sampleID, tuning }; }
int main(void) {
    struct Model model = { 0 };
    for (int i = 0; i < 12; ++i) model.bankStatus[i] = NOT_LOADED;
    for (int i = 0; i < 16; ++i) model.sequenceStatus[i] = NOT_LOADED;
    for (int i = 0; i < 2; ++i) {
        model.bankSlots[i] = (struct Slot){ i, -1, 0, NOT_LOADED, 0 };
        model.sequenceSlots[i] = (struct Slot){ i, -1, 0, NOT_LOADED, 0 };
        model.shortSlots[i] = (struct StreamSlot){ i, -1, 0, 128, 0, -1 };
        model.longSlots[i] = (struct StreamSlot){ i, -1, 0, 256, 0, -1 };
        model.shortQueue[model.shortQueueCount++] = i; model.longQueue[model.longQueueCount++] = i;
    }
    model.sampleLoaded[10] = 1; model.sampleLoaded[11] = 1;
    model.banks[10].present = 1; model.banks[10].instrumentsCount = 3; model.banks[10].drumsCount = 2;
    model.banks[10].instruments[0] = (struct Instrument){ 1, 0, 1, 40, 80, 5, make_sound(10, 900), make_sound(11, 1000), make_sound(12, 1100) };
    model.banks[10].instruments[2] = (struct Instrument){ 1, 2, 0, 40, 80, 6, make_sound(10, 900), make_sound(11, 1000), make_sound(12, 1100) };
    model.banks[10].drums[0] = (struct Drum){ 1, 0, 1, 7, 64, make_sound(11, 1000) };
    uint64_t fingerprint = UINT64_C(1469598103934665603);
#define HASH(call) do { struct Trace t = (call); fingerprint = hash_trace(fingerprint, &t); } while (0)
    HASH(load_resource(&model, BANK, 7, 0x40, 0));
    struct Trace bankAsync = load_resource(&model, BANK, 8, 0x80, 1); if (bankAsync.count != 2 || bankAsync.events[1].kind != LOAD_STARTED) return 1; fingerprint = hash_trace(fingerprint, &bankAsync);
    HASH(complete_resource(&model, BANK, 8)); HASH(touch_resource(&model, BANK, 8)); HASH(discard_resource(&model, BANK, 7));
    HASH(load_resource(&model, BANK, 9, 0x90, 0)); HASH(load_resource(&model, BANK, 10, 0xA0, 0));
    struct Trace sequenceShort = load_resource(&model, SEQUENCE, 3, 0x20, 1); if (sequenceShort.events[1].kind != LOAD_COMPLETED) return 2; fingerprint = hash_trace(fingerprint, &sequenceShort);
    HASH(load_resource(&model, SEQUENCE, 4, 0x80, 1)); HASH(complete_resource(&model, SEQUENCE, 4)); HASH(discard_resource(&model, SEQUENCE, 3)); HASH(load_resource(&model, SEQUENCE, 5, 0x40, 1));
    struct Trace direct = lookup_instrument(&model, 10, 0, 0, 0); if (direct.selected != 0 || direct.failed) return 3; fingerprint = hash_trace(fingerprint, &direct);
    struct Trace fallback = lookup_instrument(&model, 10, 1, 1, 0); if (fallback.selected != 0 || fallback.failed) return 4; fingerprint = hash_trace(fingerprint, &fallback);
    struct Trace outOfRange = lookup_instrument(&model, 10, 9, 0, 0); if (!outOfRange.failed || outOfRange.events[0].kind != INSTRUMENT_OUT_OF_RANGE) return 5; fingerprint = hash_trace(fingerprint, &outOfRange);
    struct Trace drum = lookup_drum(&model, 10, 0); if (drum.selected != 0 || drum.failed) return 6; fingerprint = hash_trace(fingerprint, &drum);
    struct Trace soundNormal = select_sound(&model, 10, 0, 60, 0); if (soundNormal.selected != 11 || soundNormal.failed) return 7; fingerprint = hash_trace(fingerprint, &soundNormal);
    struct Trace soundUnavailable = select_sound(&model, 10, 0, 90, 0); if (!soundUnavailable.failed) return 8; fingerprint = hash_trace(fingerprint, &soundUnavailable);
    struct Trace evicted = lookup_instrument(&model, 7, 0, 0, 0); if (!evicted.failed || evicted.events[0].kind != INSTRUMENT_UNAVAILABLE) return 9; fingerprint = hash_trace(fingerprint, &evicted);
    struct Trace streamMiss = request_stream(&model, 10, 0x1234, 64, SHORT_STREAM, -1); if (streamMiss.selected != 0 || streamMiss.failed) return 10; fingerprint = hash_trace(fingerprint, &streamMiss);
    struct Trace streamHit = request_stream(&model, 10, 0x1240, 64, SHORT_STREAM, 0); if (streamHit.selected != 0 || streamHit.failed) return 11; fingerprint = hash_trace(fingerprint, &streamHit);
    HASH(advance_streams(&model)); struct Trace expired = advance_streams(&model); if (expired.count != 1 || expired.events[0].kind != STREAM_EXPIRED) return 12; fingerprint = hash_trace(fingerprint, &expired);
    HASH(request_stream(&model, 11, 0x2345, 32, SHORT_STREAM, -1)); HASH(request_stream(&model, 10, 0x4000, 128, LONG_STREAM, -1)); HASH(request_stream(&model, 10, 0x4010, 64, LONG_STREAM, 0));
    fingerprint = hash_model(fingerprint, &model);
    printf("audioResidencyFingerprint=0x%llx\n", (unsigned long long)fingerprint);
    printf("SM64 Modern audio residency C contract passed\n");
    return 0;
}
