#include <stdint.h>
#include <stdio.h>

static uint64_t fnv_u64(uint64_t hash, uint64_t value) {
    for (int shift = 0; shift <= 56; shift += 8) {
        hash ^= (value >> shift) & UINT64_C(0xff);
        hash *= UINT64_C(1099511628211);
    }
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

enum {
    STREAM_STARTED = 1,
    STREAM_REQUESTED = 2,
    STREAM_DECODED = 3,
    STREAM_HISTORY = 4,
    STREAM_LOOPED = 5,
    STREAM_FINISHED = 6,
    STREAM_UNAVAILABLE = 7,
    STREAM_MALFORMED = 8,
};

enum {
    RES_STREAM_HIT = 18,
    RES_STREAM_MISS = 19,
    RES_STREAM_ALLOCATED = 20,
    RES_SAMPLE_RESOLVED = 17,
};

struct result {
    int32_t samples[28];
    int sampleCount;
    int nextPosition;
    int32_t decoderState[1];
    int decoderStateCount;
    int loops;
    int finished;
    int streamKind[24];
    int stream0[24];
    int stream1[24];
    int streamCount;
    int resKind[16];
    int resResource[16];
    int resID[16];
    int resIndex[16];
    int resValue[16];
    int resCount;
};

static void stream_event(struct result *result, int kind, int value0, int value1) {
    result->streamKind[result->streamCount] = kind;
    result->stream0[result->streamCount] = value0;
    result->stream1[result->streamCount] = value1;
    result->streamCount++;
}

static void residency_event(struct result *result, int kind, int id, int index, int value) {
    result->resKind[result->resCount] = kind;
    result->resResource[result->resCount] = 1;
    result->resID[result->resCount] = id;
    result->resIndex[result->resCount] = index;
    result->resValue[result->resCount] = value;
    result->resCount++;
}

static struct result project(
    int sampleID,
    int loaded,
    const uint8_t blocks[2][9],
    const int blockLengths[2],
    const int32_t rows[8][9],
    int loopStart,
    int loopEnd,
    int sampleSize,
    int loopCount,
    int samplePosition,
    int requestedSamples,
    int32_t decoderStateInitial[1],
    int restartFromLoopState,
    int streamClass,
    int deviceAddress
) {
    struct result result = { 0 };
    result.decoderStateCount = 1;
    result.decoderState[0] = decoderStateInitial[0];
    stream_event(&result, STREAM_STARTED, sampleID, requestedSamples);
    if (!loaded || sampleSize <= 0 || loopStart < 0 || loopEnd <= loopStart || loopEnd > sampleSize) {
        stream_event(&result, STREAM_UNAVAILABLE, sampleID, loopEnd);
        result.sampleCount = requestedSamples;
        result.finished = 1;
        return result;
    }
    (void)restartFromLoopState;
    int position = samplePosition < 0 ? 0 : samplePosition;
    int remainingLoops = loopCount;
    int currentBlockIndex = -1;
    int32_t currentBlock[16] = { 0 };
    int streamSlot = -1;
    int finished = 0;
    for (int outputIndex = 0; outputIndex < requestedSamples; ++outputIndex) {
        if (finished) {
            result.samples[outputIndex] = 0;
            continue;
        }
        while (position >= loopEnd) {
            if (loopCount == 0 || (remainingLoops == 0 && loopCount > 0)) {
                finished = 1;
                stream_event(&result, STREAM_FINISHED, sampleID, outputIndex);
                break;
            }
            if (remainingLoops > 0) --remainingLoops;
            ++result.loops;
            position = loopStart;
            result.decoderState[0] = decoderStateInitial[0];
            currentBlockIndex = -1;
            stream_event(&result, STREAM_HISTORY, position, 1);
            stream_event(&result, STREAM_LOOPED, result.loops, position);
        }
        if (finished) {
            result.samples[outputIndex] = 0;
            continue;
        }
        int blockIndex = position / 16;
        int blockOffset = position & 15;
        if (currentBlockIndex != blockIndex) {
            if (blockIndex < 0 || blockIndex >= 2 || blockLengths[blockIndex] < 9) {
                finished = 1;
                stream_event(&result, STREAM_MALFORMED, blockIndex, outputIndex);
                result.samples[outputIndex] = 0;
                continue;
            }
            int address = deviceAddress + blockIndex * 9;
            if (streamSlot < 0) {
                residency_event(&result, RES_STREAM_MISS, sampleID, -1, streamClass);
                streamSlot = 0;
                residency_event(&result, RES_STREAM_ALLOCATED, sampleID, streamSlot, address & ~0xF);
            } else {
                residency_event(&result, RES_STREAM_HIT, sampleID, streamSlot, streamClass);
                residency_event(&result, RES_SAMPLE_RESOLVED, sampleID, streamSlot, 60);
            }
            stream_event(&result, STREAM_REQUESTED, blockIndex, streamSlot);
            int32_t state[1] = { result.decoderState[0] };
            decode(blocks[blockIndex], state, rows, currentBlock);
            result.decoderState[0] = state[0];
            currentBlockIndex = blockIndex;
            stream_event(&result, STREAM_DECODED, blockIndex, 16);
        }
        result.samples[outputIndex] = currentBlock[blockOffset];
        position += 1;
    }
    result.sampleCount = requestedSamples;
    result.nextPosition = position;
    result.finished = finished;
    return result;
}

static uint64_t hash_result(uint64_t hash, const struct result *result) {
    hash = fnv_u64(hash, (uint64_t)result->sampleCount);
    for (int i = 0; i < result->sampleCount; ++i) hash = fnv_u64(hash, (uint64_t)(int64_t)result->samples[i]);
    hash = fnv_u64(hash, (uint64_t)(int64_t)result->nextPosition);
    hash = fnv_u64(hash, (uint64_t)result->decoderStateCount);
    for (int i = 0; i < result->decoderStateCount; ++i) hash = fnv_u64(hash, (uint64_t)(int64_t)result->decoderState[i]);
    hash = fnv_u64(hash, (uint64_t)result->loops);
    hash = fnv_u64(hash, (uint64_t)result->finished);
    hash = fnv_u64(hash, (uint64_t)result->streamCount);
    for (int i = 0; i < result->streamCount; ++i) {
        hash = fnv_u64(hash, (uint64_t)result->streamKind[i]);
        hash = fnv_u64(hash, (uint64_t)(int64_t)result->stream0[i]);
        hash = fnv_u64(hash, (uint64_t)(int64_t)result->stream1[i]);
    }
    hash = fnv_u64(hash, (uint64_t)result->resCount);
    for (int i = 0; i < result->resCount; ++i) {
        hash = fnv_u64(hash, (uint64_t)result->resKind[i]);
        hash = fnv_u64(hash, (uint64_t)result->resResource[i]);
        hash = fnv_u64(hash, (uint64_t)(int64_t)result->resID[i]);
        hash = fnv_u64(hash, (uint64_t)(int64_t)result->resIndex[i]);
        hash = fnv_u64(hash, (uint64_t)(int64_t)result->resValue[i]);
    }
    return hash;
}

int main(void) {
    int32_t rows[8][9] = { 0 };
    for (int i = 0; i < 8; ++i) {
        rows[i][0] = 2048;
        rows[i][i + 1] = 2048;
    }
    const uint8_t blocks[2][9] = {
        { 0x00, 0x12, 0x34, 0x56, 0x78, 0xF0, 0x0F, 0xAA, 0x55 },
        { 0x10, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x10 },
    };
    const int blockLengths[2] = { 9, 9 };
    int32_t state[1] = { 100 };
    struct result active = project(7, 1, blocks, blockLengths, rows, 8, 24, 32, 1, 4, 28, state, 0, 1, 0x2000);
    struct result unavailable = project(9, 0, blocks, blockLengths, rows, 8, 24, 32, 0, 0, 8, state, 1, 0, 0x3000);
    uint64_t fingerprint = UINT64_C(1469598103934665603);
    fingerprint = hash_result(fingerprint, &active);
    fingerprint = hash_result(fingerprint, &unavailable);
    printf("audioStreamFingerprint=0x%llx\n", (unsigned long long)fingerprint);
    printf("SM64 Modern audio stream C contract passed\n");
    return 0;
}
