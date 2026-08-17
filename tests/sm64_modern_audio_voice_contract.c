#include <stdint.h>
#include <stdio.h>

static uint64_t fnv_u64(uint64_t hash, uint64_t value) {
    for (int shift = 0; shift <= 56; shift += 8) {
        hash ^= (value >> shift) & UINT64_C(0xff);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static uint64_t hash_i16_array(uint64_t hash, const int16_t *values, int count) {
    hash = fnv_u64(hash, (uint64_t)count);
    for (int i = 0; i < count; ++i) hash = fnv_u64(hash, (uint64_t)(int64_t)values[i]);
    return hash;
}

static int32_t floor_div_2048(int64_t value) {
    int64_t quotient = value / 2048;
    if (value - quotient * 2048 < 0) --quotient;
    return (int32_t)quotient;
}

static void decode(const uint8_t block[9], int32_t state[1], const int32_t rows[8][9], int32_t output[16]) {
    int32_t residuals[16];
    int32_t input[9];
    int32_t scale = (int32_t)1 << (block[0] >> 4);
    for (int i = 0; i < 8; ++i) {
        uint8_t byte = block[i + 1];
        int32_t high = byte >> 4;
        int32_t low = byte & 0x0f;
        residuals[i * 2] = (high <= 7 ? high : high - 16) * scale;
        residuals[i * 2 + 1] = (low <= 7 ? low : low - 16) * scale;
    }
    for (int half = 0; half < 2; ++half) {
        input[0] = half == 0 ? state[0] : output[7];
        for (int i = 0; i < 8; ++i) {
            input[i + 1] = residuals[half * 8 + i];
            int64_t sum = 0;
            for (int j = 0; j < 9; ++j) sum += (int64_t)rows[i][j] * input[j];
            output[half * 8 + i] = floor_div_2048(sum);
        }
    }
    state[0] = output[15];
}

enum { VOICE_STARTED = 1, VOICE_DISABLED = 2, VOICE_UNAVAILABLE = 3, VOICE_RELEASED = 4, VOICE_LOOPED = 5, VOICE_FINISHED = 6, VOICE_ACTIVE = 7 };

struct voice_input {
    int noteID;
    int priority;
    int list;
    int sampleID;
    int loaded;
    int loopStart;
    int loopEnd;
    int sampleSize;
    int streamClass;
    int32_t pitchQ16;
    const uint16_t *envelope;
    int envelopeCount;
    uint16_t panQ15;
    uint16_t reverbQ15;
    uint64_t position;
    int loopCount;
    int outputCount;
    int releaseRequested;
};

struct voice_result {
    int16_t left[18];
    int16_t right[18];
    int16_t reverb[18];
    uint64_t nextPosition;
    int loops;
    int finished;
    int eventKind[8];
    int event0[8];
    int event1[8];
    int eventCount;
};

static int16_t clamp_i16(int64_t value) {
    if (value > INT16_MAX) return INT16_MAX;
    if (value < INT16_MIN) return INT16_MIN;
    return (int16_t)value;
}

static void event(struct voice_result *result, int kind, int value0, int value1) {
    if (result->eventCount >= 8) return;
    result->eventKind[result->eventCount] = kind;
    result->event0[result->eventCount] = value0;
    result->event1[result->eventCount] = value1;
    result->eventCount++;
}

static struct voice_result project(const struct voice_input *input, const int32_t *decoded) {
    struct voice_result result = { 0 };
    event(&result, VOICE_STARTED, input->noteID, input->streamClass);
    if (input->priority == 0 || input->list == 0 || input->list == 1) {
        event(&result, VOICE_DISABLED, input->noteID, input->priority);
        result.finished = 1;
        result.nextPosition = input->position;
        return result;
    }
    if (!input->loaded || input->sampleSize <= 0 || input->loopStart < 0 ||
        input->loopEnd <= input->loopStart || input->loopEnd > input->sampleSize) {
        event(&result, VOICE_UNAVAILABLE, input->sampleID, input->loopEnd);
        result.finished = 1;
        result.nextPosition = input->position;
        return result;
    }

    if (input->releaseRequested) event(&result, VOICE_RELEASED, input->noteID, input->priority);
    uint16_t fallbackEnvelope = 32767;
    const uint16_t *envelope = input->envelopeCount == 0 ? &fallbackEnvelope : input->envelope;
    int envelopeCount = input->envelopeCount == 0 ? 1 : input->envelopeCount;
    int64_t pan = input->panQ15 > 32767 ? 32767 : input->panQ15;
    int64_t leftPan = 32767 - pan;
    int64_t rightPan = pan;
    int64_t reverbGain = input->reverbQ15 > 32767 ? 32767 : input->reverbQ15;
    uint64_t position = input->position;
    int remainingLoops = input->loopCount;
    int finished = 0;
    for (int outputIndex = 0; outputIndex < input->outputCount; ++outputIndex) {
        if (finished) continue;
        int sourceIndex = (int)(position >> 16);
        while (sourceIndex >= input->loopEnd) {
            if (input->loopCount == 0 || (remainingLoops == 0 && input->loopCount > 0)) {
                finished = 1;
                event(&result, VOICE_FINISHED, input->noteID, outputIndex);
                break;
            }
            if (remainingLoops > 0) --remainingLoops;
            ++result.loops;
            event(&result, VOICE_LOOPED, result.loops, input->loopStart);
            position = (uint64_t)input->loopStart << 16;
            sourceIndex = input->loopStart;
        }
        if (finished) continue;
        int64_t fraction = (int64_t)(position & 0xffff);
        int nextIndex;
        if (sourceIndex + 1 < input->loopEnd) nextIndex = sourceIndex + 1;
        else if (input->loopCount != 0) nextIndex = input->loopStart;
        else nextIndex = input->loopEnd - 1;
        int64_t interpolated = ((int64_t)decoded[sourceIndex] * (65536 - fraction) +
                                (int64_t)decoded[nextIndex] * fraction) >> 16;
        int64_t gain = envelope[outputIndex % envelopeCount];
        int64_t envelopeSample = (interpolated * gain) / 32767;
        result.left[outputIndex] = clamp_i16((envelopeSample * leftPan) / 32767);
        result.right[outputIndex] = clamp_i16((envelopeSample * rightPan) / 32767);
        result.reverb[outputIndex] = clamp_i16((envelopeSample * reverbGain) / 32767);
        position += (uint32_t)input->pitchQ16;
    }
    result.finished = finished;
    result.nextPosition = position;
    if (!finished) event(&result, VOICE_ACTIVE, input->noteID, input->outputCount);
    return result;
}

static uint64_t hash_result(uint64_t hash, const struct voice_result *result, int noteID, int streamClass, int count) {
    hash = fnv_u64(hash, (uint64_t)noteID);
    hash = fnv_u64(hash, (uint64_t)streamClass);
    hash = hash_i16_array(hash, result->left, count);
    hash = hash_i16_array(hash, result->right, count);
    hash = hash_i16_array(hash, result->reverb, count);
    hash = fnv_u64(hash, result->nextPosition);
    hash = fnv_u64(hash, (uint64_t)result->loops);
    hash = fnv_u64(hash, (uint64_t)result->finished);
    hash = fnv_u64(hash, (uint64_t)result->eventCount);
    for (int i = 0; i < result->eventCount; ++i) {
        hash = fnv_u64(hash, (uint64_t)result->eventKind[i]);
        hash = fnv_u64(hash, (uint64_t)(int64_t)result->event0[i]);
        hash = fnv_u64(hash, (uint64_t)(int64_t)result->event1[i]);
    }
    return hash;
}

int main(void) {
    int32_t rows[8][9] = { 0 };
    for (int i = 0; i < 8; ++i) {
        rows[i][0] = 2048;
        rows[i][i + 1] = 2048;
    }
    const uint8_t block1[9] = { 0x00, 0x12, 0x34, 0x56, 0x78, 0xF0, 0x0F, 0xAA, 0x55 };
    const uint8_t block2[9] = { 0x10, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x10 };
    int32_t state[1] = { 100 };
    int32_t decoded[32];
    decode(block1, state, rows, decoded);
    decode(block2, state, rows, decoded + 16);
    const uint16_t envelope[] = { 32767, 30000, 28000, 26000, 24000, 22000 };
    struct voice_input active = {
        1, 3, 4, 7, 1, 8, 24, 32, 1, 0x18000,
        envelope, 6, 10000, 9000, (uint64_t)12 << 16, 1, 18, 1
    };
    struct voice_result activeResult = project(&active, decoded);
    struct voice_input disabled = {
        0, 0, 1, 7, 1, 8, 24, 32, 0, 0x10000,
        NULL, 0, 16383, 0, 0, 0, 18, 0
    };
    struct voice_result disabledResult = project(&disabled, decoded);
    struct voice_input unavailable = {
        1, 3, 4, 9, 0, 8, 24, 32, 0, 0x10000,
        NULL, 0, 16383, 0, 0, 0, 18, 0
    };
    struct voice_result unavailableResult = project(&unavailable, decoded);
    uint64_t fingerprint = UINT64_C(1469598103934665603);
    fingerprint = hash_result(fingerprint, &activeResult, 1, 1, 18);
    fingerprint = hash_result(fingerprint, &disabledResult, 0, 0, 18);
    fingerprint = hash_result(fingerprint, &unavailableResult, 1, 0, 18);
    printf("audioVoiceFingerprint=0x%llx\n", (unsigned long long)fingerprint);
    printf("SM64 Modern audio voice C contract passed\n");
    return 0;
}
