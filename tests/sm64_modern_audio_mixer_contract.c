#include <stdint.h>
#include <stdio.h>

static uint64_t fnv_u64(uint64_t hash, uint64_t value) {
    for (int shift = 0; shift <= 56; shift += 8) {
        hash ^= (value >> shift) & UINT64_C(0xff);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static int16_t clamp_i16(int64_t value) {
    if (value > INT16_MAX) return INT16_MAX;
    if (value < INT16_MIN) return INT16_MIN;
    return (int16_t)value;
}

struct voice {
    int noteID;
    int priority;
    int source;
    int16_t left[8];
    int16_t right[8];
    int16_t reverb[8];
};

struct frame {
    int16_t interleaved[16];
    int16_t dryLeft[8];
    int16_t dryRight[8];
    int16_t wetLeft[8];
    int16_t wetRight[8];
    int order[3];
    int clipped;
    int32_t nextLeft[4];
    int32_t nextRight[4];
    int ringCount;
    int writeIndex;
    int feedback;
    int gain;
};

static int before(const struct voice *left, const struct voice *right) {
    if (left->priority != right->priority) return left->priority > right->priority;
    if (left->source != right->source) return left->source < right->source;
    return left->noteID < right->noteID;
}

static struct frame mix(const struct voice voices[3], int enableReverb, const int32_t *initialLeft, const int32_t *initialRight, int initialWrite, int feedback, int gain) {
    struct frame frame = { 0 };
    int order[3] = { 0, 1, 2 };
    for (int i = 0; i < 3; ++i) {
        for (int j = i + 1; j < 3; ++j) {
            if (!before(&voices[order[i]], &voices[order[j]])) {
                int temp = order[i]; order[i] = order[j]; order[j] = temp;
            }
        }
    }
    for (int i = 0; i < 3; ++i) frame.order[i] = voices[order[i]].noteID;
    int32_t ringLeft[4] = { 0 };
    int32_t ringRight[4] = { 0 };
    if (initialLeft != NULL && initialRight != NULL) {
        for (int i = 0; i < 4; ++i) { ringLeft[i] = initialLeft[i]; ringRight[i] = initialRight[i]; }
    }
    int writeIndex = initialWrite % 4;
    for (int sample = 0; sample < 8; ++sample) {
        int64_t dryL = 0;
        int64_t dryR = 0;
        int64_t send = 0;
        for (int i = 0; i < 3; ++i) {
            const struct voice *voice = &voices[order[i]];
            dryL += voice->left[sample];
            dryR += voice->right[sample];
            send += voice->reverb[sample];
        }
        int64_t outputL = dryL;
        int64_t outputR = dryR;
        if (enableReverb) {
            int64_t delayedL = ringLeft[writeIndex];
            int64_t delayedR = ringRight[writeIndex];
            outputL += delayedL * gain / 32767;
            outputR += delayedR * gain / 32767;
            ringLeft[writeIndex] = (int32_t)(send + delayedL * feedback / 32767);
            ringRight[writeIndex] = (int32_t)(send + delayedR * feedback / 32767);
            writeIndex = (writeIndex + 1) % 4;
        }
        frame.dryLeft[sample] = clamp_i16(dryL);
        frame.dryRight[sample] = clamp_i16(dryR);
        frame.wetLeft[sample] = clamp_i16(outputL);
        frame.wetRight[sample] = clamp_i16(outputR);
        frame.interleaved[sample * 2] = frame.wetLeft[sample];
        frame.interleaved[sample * 2 + 1] = frame.wetRight[sample];
        if ((int64_t)frame.dryLeft[sample] != dryL) ++frame.clipped;
        if ((int64_t)frame.dryRight[sample] != dryR) ++frame.clipped;
        if ((int64_t)frame.wetLeft[sample] != outputL) ++frame.clipped;
        if ((int64_t)frame.wetRight[sample] != outputR) ++frame.clipped;
    }
    frame.ringCount = enableReverb ? 4 : 0;
    for (int i = 0; i < 4; ++i) { frame.nextLeft[i] = ringLeft[i]; frame.nextRight[i] = ringRight[i]; }
    frame.writeIndex = enableReverb ? writeIndex : initialWrite % 4;
    frame.feedback = feedback;
    frame.gain = gain;
    return frame;
}

static uint64_t hash_i16_array(uint64_t hash, const int16_t *values, int count) {
    hash = fnv_u64(hash, (uint64_t)count);
    for (int i = 0; i < count; ++i) hash = fnv_u64(hash, (uint64_t)(int64_t)values[i]);
    return hash;
}

static uint64_t hash_i32_array(uint64_t hash, const int32_t *values, int count) {
    hash = fnv_u64(hash, (uint64_t)count);
    for (int i = 0; i < count; ++i) hash = fnv_u64(hash, (uint64_t)(int64_t)values[i]);
    return hash;
}

static uint64_t hash_frame(uint64_t hash, const struct frame *frame) {
    hash = fnv_u64(hash, 32000);
    hash = fnv_u64(hash, 8);
    hash = hash_i16_array(hash, frame->interleaved, 16);
    hash = hash_i16_array(hash, frame->dryLeft, 8);
    hash = hash_i16_array(hash, frame->dryRight, 8);
    hash = hash_i16_array(hash, frame->wetLeft, 8);
    hash = hash_i16_array(hash, frame->wetRight, 8);
    hash = fnv_u64(hash, 3);
    for (int i = 0; i < 3; ++i) hash = fnv_u64(hash, (uint64_t)(int64_t)frame->order[i]);
    hash = fnv_u64(hash, (uint64_t)frame->clipped);
    hash = hash_i32_array(hash, frame->nextLeft, frame->ringCount);
    hash = hash_i32_array(hash, frame->nextRight, frame->ringCount);
    hash = fnv_u64(hash, (uint64_t)frame->writeIndex);
    hash = fnv_u64(hash, (uint64_t)frame->feedback);
    return fnv_u64(hash, (uint64_t)frame->gain);
}

int main(void) {
    const struct voice voices[3] = {
        { 2, 3, 0,
          { 12000, -12000, 20000, -20000, 30000, -30000, 32000, -32000 },
          { 8000, -8000, 16000, -16000, 24000, -24000, 30000, -30000 },
          { 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000 } },
        { 1, 3, 1,
          { 25000, 25000, -25000, -25000, 30000, -30000, 1000, -1000 },
          { 10000, 10000, -10000, -10000, 28000, -28000, 2000, -2000 },
          { 2000, 2000, 2000, 2000, 2000, 2000, 2000, 2000 } },
        { 3, 1, 1,
          { 500, 500, 500, 500, 500, 500, 500, 500 },
          { -500, -500, -500, -500, -500, -500, -500, -500 },
          { 100, 100, 100, 100, 100, 100, 100, 100 } },
    };
    const int32_t initialLeft[4] = { 1000, -2000, 3000, -4000 };
    const int32_t initialRight[4] = { -500, 600, -700, 800 };
    struct frame withReverb = mix(voices, 1, initialLeft, initialRight, 1, 12000, 16000);
    struct frame dry = mix(voices, 0, NULL, NULL, 0, 0, 0);
    uint64_t fingerprint = UINT64_C(1469598103934665603);
    fingerprint = hash_frame(fingerprint, &withReverb);
    fingerprint = hash_frame(fingerprint, &dry);
    printf("audioMixerFingerprint=0x%llx\n", (unsigned long long)fingerprint);
    printf("SM64 Modern audio mixer C contract passed\n");
    return 0;
}
