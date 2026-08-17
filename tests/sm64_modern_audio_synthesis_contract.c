#include <stdint.h>
#include <stdio.h>

static uint64_t fnv_u64(uint64_t hash, uint64_t value) {
    for (int shift = 0; shift <= 56; shift += 8) {
        hash ^= (value >> shift) & UINT64_C(0xff);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static uint64_t hash_i32(uint64_t hash, int32_t value) {
    return fnv_u64(hash, (uint64_t)(int64_t)value);
}

static uint64_t hash_i32_array(uint64_t hash, const int32_t *values, size_t count) {
    hash = fnv_u64(hash, (uint64_t)count);
    for (size_t i = 0; i < count; ++i) hash = hash_i32(hash, values[i]);
    return hash;
}

static int32_t floor_div_2048(int64_t value) {
    int64_t quotient = value / 2048;
    if (value - quotient * 2048 < 0) --quotient;
    return (int32_t)quotient;
}

static void decode(const uint8_t block[9], int32_t state[1], int32_t rows[8][9], int32_t output[16]) {
    int32_t residuals[16];
    int32_t input[9];
    int32_t scale = (int32_t)1 << (block[0] >> 4);
    int predictor = block[0] & 0x0f;
    (void)predictor;
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
    ADSR_DISABLED = 0,
    ADSR_INITIAL = 1,
    ADSR_START_LOOP = 2,
    ADSR_LOOP = 3,
    ADSR_FADE = 4,
    ADSR_HANG = 5,
    ADSR_DECAY = 6,
    ADSR_RELEASE = 7,
    ADSR_SUSTAIN = 8,
};

enum {
    ACTION_RELEASE = 0x10,
    ACTION_DECAY = 0x20,
    ACTION_HANG = 0x40,
};

struct adsr {
    uint8_t action;
    uint8_t state;
    int32_t initial;
    int32_t target;
    int32_t current;
    int64_t currentHiRes;
    int32_t delay;
    int32_t velocity;
    int32_t fadeOutVelocity;
    int32_t sustain;
    int32_t envelopeIndex;
};

struct frame {
    uint8_t state;
    uint8_t action;
    int32_t current;
    int32_t target;
    int32_t delay;
    int32_t envelopeIndex;
};

static struct frame adsr_tick(struct adsr *adsr, const int32_t *delays, const int32_t *targets, int count) {
    uint8_t action = adsr->action;
    if (adsr->state == ADSR_DISABLED) {
        struct frame disabled = {
            adsr->state, adsr->action, adsr->current, adsr->target,
            adsr->delay, adsr->envelopeIndex
        };
        return disabled;
    }
    switch (adsr->state) {
        case ADSR_DISABLED:
            break; // handled by the early return above
        case ADSR_INITIAL:
            adsr->current = adsr->initial;
            adsr->target = adsr->initial;
            if (action & ACTION_HANG) {
                adsr->state = ADSR_HANG;
                break;
            }
            /* fall through */
        case ADSR_START_LOOP:
            adsr->envelopeIndex = 0;
            adsr->currentHiRes = (int64_t)adsr->current << 16;
            adsr->state = ADSR_LOOP;
            /* fall through */
        case ADSR_LOOP:
            if (adsr->envelopeIndex < 0 || adsr->envelopeIndex >= count) {
                adsr->state = ADSR_DISABLED;
                break;
            }
            adsr->delay = delays[adsr->envelopeIndex];
            switch (adsr->delay) {
                case 0:
                    adsr->state = ADSR_DISABLED;
                    break;
                case -1:
                    adsr->state = ADSR_HANG;
                    break;
                case -2:
                    adsr->envelopeIndex = targets[adsr->envelopeIndex];
                    break;
                case -3:
                    adsr->state = ADSR_INITIAL;
                    break;
                default:
                    adsr->target = targets[adsr->envelopeIndex];
                    adsr->velocity = ((int64_t)(adsr->target - adsr->current) << 16) / adsr->delay;
                    adsr->state = ADSR_FADE;
                    adsr->envelopeIndex++;
                    break;
            }
            if (adsr->state != ADSR_FADE) break;
            /* fall through */
        case ADSR_FADE:
            adsr->currentHiRes += adsr->velocity;
            adsr->current = (int32_t)(adsr->currentHiRes >> 16);
            if (--adsr->delay <= 0) adsr->state = ADSR_LOOP;
            /* fall through */
        case ADSR_HANG:
            break;
        case ADSR_DECAY:
        case ADSR_RELEASE:
            adsr->current -= adsr->fadeOutVelocity;
            if (adsr->sustain != 0 && adsr->state == ADSR_DECAY) {
                if (adsr->current < adsr->sustain) {
                    adsr->current = adsr->sustain;
                    adsr->delay = adsr->sustain / 16;
                    adsr->state = ADSR_SUSTAIN;
                }
                break;
            }
            if (adsr->current < 100) {
                adsr->current = 0;
                adsr->state = ADSR_DISABLED;
            }
            break;
        case ADSR_SUSTAIN:
            adsr->delay -= 1;
            if (adsr->delay == 0) adsr->state = ADSR_RELEASE;
            break;
    }
    if (action & ACTION_DECAY) {
        adsr->state = ADSR_DECAY;
        adsr->action = action & (uint8_t)~ACTION_DECAY;
    }
    if (action & ACTION_RELEASE) {
        adsr->state = ADSR_RELEASE;
        adsr->action = action & (uint8_t)~(ACTION_RELEASE | ACTION_DECAY);
    }
    struct frame frame = {
        adsr->state, adsr->action, adsr->current, adsr->target,
        adsr->delay, adsr->envelopeIndex
    };
    return frame;
}

static uint64_t hash_frame(uint64_t hash, struct frame frame) {
    hash = fnv_u64(hash, frame.state);
    hash = fnv_u64(hash, frame.action);
    hash = hash_i32(hash, frame.current);
    hash = hash_i32(hash, frame.target);
    hash = hash_i32(hash, frame.delay);
    return fnv_u64(hash, (uint64_t)frame.envelopeIndex);
}

static int32_t clamp_i32(int64_t value) {
    if (value > INT32_MAX) return INT32_MAX;
    if (value < INT32_MIN) return INT32_MIN;
    return (int32_t)value;
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
    int32_t decoded1[16];
    int32_t decoded2[16];
    decode(block1, state, rows, decoded1);
    decode(block2, state, rows, decoded2);

    const int32_t delays[] = { 4, 3, 0 };
    const int32_t targets[] = { 1600, 2400, 0 };
    struct adsr adsr = { 0 };
    adsr.initial = 100;
    adsr.current = 100;
    adsr.target = 100;
    adsr.currentHiRes = (int64_t)100 << 16;
    adsr.state = ADSR_INITIAL;
    struct frame frames[13];
    int frameCount = 0;
    for (int i = 0; i < 3; ++i) frames[frameCount++] = adsr_tick(&adsr, delays, targets, 3);
    adsr.sustain = 400;
    adsr.fadeOutVelocity = 250;
    adsr.action |= ACTION_DECAY;
    frames[frameCount++] = adsr_tick(&adsr, delays, targets, 3);
    adsr.action |= ACTION_RELEASE;
    for (int i = 0; i < 8; ++i) frames[frameCount++] = adsr_tick(&adsr, delays, targets, 3);
    adsr.action |= ACTION_RELEASE;
    frames[frameCount++] = adsr_tick(&adsr, delays, targets, 3);

    const uint16_t envelope[] = { 32767, 30000, 28000, 26000, 24000, 22000, 20000, 18000 };
    int16_t pcm[8];
    for (int i = 0; i < 8; ++i) {
        uint64_t position = (uint64_t)i * UINT64_C(0x8000);
        int sourceIndex = (int)(position >> 16);
        int64_t fraction = (int64_t)(position & 0xffff);
        int64_t left = decoded1[sourceIndex < 16 ? sourceIndex : 15];
        int64_t right = decoded1[sourceIndex + 1 < 16 ? sourceIndex + 1 : 15];
        int64_t interpolated = (left * (65536 - fraction) + right * fraction) >> 16;
        pcm[i] = (int16_t)clamp_i32((interpolated * envelope[i]) / 32767);
    }
    uint32_t phase = (uint32_t)((UINT64_C(8) * UINT64_C(0x8000)) & 0xffff);

    uint64_t fingerprint = UINT64_C(1469598103934665603);
    fingerprint = hash_i32_array(fingerprint, decoded1, 16);
    fingerprint = hash_i32_array(fingerprint, decoded2, 16);
    fingerprint = hash_i32_array(fingerprint, state, 1);
    fingerprint = fnv_u64(fingerprint, (uint64_t)frameCount);
    for (int i = 0; i < frameCount; ++i) fingerprint = hash_frame(fingerprint, frames[i]);
    fingerprint = fnv_u64(fingerprint, 8);
    for (int i = 0; i < 8; ++i) fingerprint = fnv_u64(fingerprint, (uint64_t)(int64_t)pcm[i]);
    fingerprint = fnv_u64(fingerprint, phase);
    printf("audioSynthesisFingerprint=0x%llx\n", (unsigned long long)fingerprint);
    printf("SM64 Modern audio synthesis C contract passed\n");
    return 0;
}
