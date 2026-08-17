#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

enum animation_type {
    ANIM_EMPTY = 0,
    ANIM_MATRIX = 1,
    ANIM_TRIANGLE_F_2 = 2,
    ANIM_NINE_HALF = 3,
    ANIM_TRIANGLE_F_4 = 4,
    ANIM_STUB = 5,
    ANIM_THREE_H_SCALED = 6,
    ANIM_THREE_H = 7,
    ANIM_SIX_H_SCALED = 8,
    ANIM_MATRIX_VECTOR = 9,
    ANIM_CAMERA = 11,
};

struct channel {
    uint32_t component_id;
    uint32_t animator_id;
    uint32_t primary_count;
    uint32_t primary_type;
    uint32_t secondary_count;
    uint32_t secondary_type;
};

struct sample {
    uint32_t component_id;
    uint32_t bank;
    int32_t source_frame;
    uint32_t normalized_frame;
    uint32_t current_index;
    uint32_t next_index;
    uint32_t interpolation_q16;
    uint32_t count;
    uint32_t type;
};

struct eye_sample {
    uint32_t action_timer;
    uint32_t has_override;
    uint32_t eye_state;
    uint32_t source;
};

static const struct channel channels[] = {
    { 0x07, 0x08, 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED },
    { 0x10, 0x11, 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED },
    { 0x20, 0x21, 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED },
    { 0x29, 0x2A, 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED },
    { 0x32, 0x33, 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED },
    { 0x3F, 0x40, 820, ANIM_THREE_H_SCALED, 0, ANIM_EMPTY },
    { 0x42, 0x43, 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED },
    { 0x48, 0x49, 820, ANIM_THREE_H_SCALED, 0, ANIM_EMPTY },
    { 0x4B, 0x4C, 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED },
    { 0x54, 0x55, 820, ANIM_THREE_H_SCALED, 0, ANIM_EMPTY },
    { 0x6B, 0x6C, 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED },
    { 0x7B, 0x7C, 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED },
    { 0x84, 0x85, 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED },
    { 0x96, 0x97, 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED },
    { 0x9F, 0xA0, 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED },
    { 0xA8, 0xA9, 820, ANIM_THREE_H_SCALED, 0, ANIM_EMPTY },
    { 0xB1, 0xB2, 820, ANIM_THREE_H_SCALED, 0, ANIM_EMPTY },
    { 0xBA, 0xBB, 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED },
    { 0xC3, 0xC4, 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED },
    { 0xC6, 0xC7, 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED },
    { 0xCF, 0xD0, 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED },
    { 0xD8, 0xD9, 820, ANIM_THREE_H_SCALED, 166, ANIM_THREE_H_SCALED },
    { 0xE2, 0xE3, 820, ANIM_SIX_H_SCALED, 166, ANIM_SIX_H_SCALED },
    { 0xE5, 0xE6, 820, ANIM_SIX_H_SCALED, 166, ANIM_SIX_H_SCALED },
    { 0xE8, 0xE9, 820, ANIM_SIX_H_SCALED, 166, ANIM_SIX_H_SCALED },
};

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (uint32_t byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_catalog(void) {
    uint64_t hash = hash_u64(FNV_OFFSET, sizeof(channels) / sizeof(channels[0]));
    for (size_t index = 0; index < sizeof(channels) / sizeof(channels[0]); ++index) {
        const struct channel channel = channels[index];
        const uint32_t values[] = {
            channel.component_id, channel.animator_id, channel.primary_count,
            channel.primary_type, channel.secondary_count, channel.secondary_type,
        };
        for (size_t value_index = 0; value_index < sizeof(values) / sizeof(values[0]); ++value_index) {
            hash = hash_u64(hash, values[value_index]);
        }
    }
    return hash;
}

static const struct channel *find_channel(uint32_t component_id) {
    for (size_t index = 0; index < sizeof(channels) / sizeof(channels[0]); ++index) {
        if (channels[index].component_id == component_id) {
            return &channels[index];
        }
    }
    return NULL;
}

static int make_sample(uint32_t component_id, uint32_t bank, int32_t frame, struct sample *output) {
    const struct channel *channel = find_channel(component_id);
    if (channel == NULL || bank > 1) {
        return 0;
    }
    const uint32_t count = bank == 0 ? channel->primary_count : channel->secondary_count;
    const uint32_t type = bank == 0 ? channel->primary_type : channel->secondary_type;
    if (count == 0 || type == ANIM_EMPTY) {
        return 0;
    }
    uint32_t normalized;
    if (frame > (int32_t) count) {
        normalized = 1;
    } else if (frame < 0) {
        normalized = count;
    } else {
        normalized = (uint32_t) frame;
    }
    if (normalized == 0) {
        return 0;
    }
    *output = (struct sample) {
        component_id, bank, frame, normalized, normalized - 1,
        normalized == count ? 0 : normalized, 0, count, type,
    };
    return 1;
}

static uint64_t hash_sample(uint64_t hash, const struct sample *sample) {
    hash = hash_u64(hash, sample == NULL ? 0 : 1);
    if (sample == NULL) {
        return hash;
    }
    const uint32_t values[] = {
        sample->component_id, sample->bank, (uint32_t) sample->source_frame,
        sample->normalized_frame, sample->current_index, sample->next_index,
        sample->interpolation_q16, sample->count, sample->type,
    };
    for (size_t index = 0; index < sizeof(values) / sizeof(values[0]); ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
}

static int peach_kiss_eye_state(uint32_t timer, uint32_t *state) {
    static const uint32_t override[20] = {
        2, 2, 3, 3, 2, 2, 1, 1, 2, 2,
        3, 3, 2, 2, 1, 1, 2, 2, 3, 3,
    };
    if (timer == 75) {
        *state = 2;
        return 1;
    }
    if (timer == 76) {
        *state = 3;
        return 1;
    }
    if (timer < 90) {
        return 0;
    }
    *state = timer < 110 ? override[timer - 90] : 2;
    return 1;
}

static int credits_opening_eye_state(uint32_t timer, uint32_t *state) {
    if (timer >= 52) {
        return 0;
    }
    *state = 2;
    return 1;
}

static struct eye_sample eye_sample_for_timer(uint32_t timer, int peach_kiss) {
    uint32_t state = 0;
    const int has_override = peach_kiss
        ? peach_kiss_eye_state(timer, &state)
        : credits_opening_eye_state(timer, &state);
    return (struct eye_sample) {
        timer, (uint32_t) has_override, has_override ? state : UINT32_C(0xffffffff),
        has_override ? (peach_kiss ? 1u : 2u) : 0u,
    };
}

static uint64_t hash_eye(uint64_t hash, struct eye_sample sample) {
    const uint32_t values[] = { sample.action_timer, sample.has_override, sample.eye_state, sample.source };
    for (size_t index = 0; index < sizeof(values) / sizeof(values[0]); ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
}

int main(void) {
    const struct {
        uint32_t component_id;
        uint32_t bank;
        int32_t frame;
    } sample_inputs[] = {
        { 0x07, 0, 1 }, { 0x07, 0, 820 }, { 0x07, 0, 821 }, { 0x07, 1, -2 },
        { 0xE2, 1, 166 }, { 0x3F, 1, 4 }, { 0xBA, 0, 0 }, { 0xFF, 0, 1 },
    };
    const uint32_t peach_timers[] = { 0, 74, 75, 76, 89, 90, 91, 96, 99, 100, 109, 110, 136 };
    const uint32_t credits_timers[] = { 0, 51, 52, 100 };

    const uint64_t catalog_fingerprint = hash_catalog();
    uint64_t fingerprint = catalog_fingerprint;
    for (size_t index = 0; index < sizeof(sample_inputs) / sizeof(sample_inputs[0]); ++index) {
        struct sample sample;
        fingerprint = hash_sample(
            fingerprint,
            make_sample(sample_inputs[index].component_id, sample_inputs[index].bank,
                        sample_inputs[index].frame, &sample) ? &sample : NULL
        );
    }
    for (size_t index = 0; index < sizeof(peach_timers) / sizeof(peach_timers[0]); ++index) {
        fingerprint = hash_eye(fingerprint, eye_sample_for_timer(peach_timers[index], 1));
    }
    for (size_t index = 0; index < sizeof(credits_timers) / sizeof(credits_timers[0]); ++index) {
        fingerprint = hash_eye(fingerprint, eye_sample_for_timer(credits_timers[index], 0));
    }

    printf("marioFaceAnimationCatalogFingerprint=0x%016llx\n", (unsigned long long) catalog_fingerprint);
    printf("marioFaceAnimationFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    printf("marioFaceAnimationChannels=%zu\n", sizeof(channels) / sizeof(channels[0]));
    printf("marioFaceAnimationSamples=%zu\n", sizeof(sample_inputs) / sizeof(sample_inputs[0]));
    printf("SM64 Modern Mario face animation C contract passed\n");
    return 0;
}
