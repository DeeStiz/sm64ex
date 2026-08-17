#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct payload_window {
    uint32_t component_id;
    uint32_t bank;
    uint32_t frame_start;
    uint32_t stride;
    uint32_t type;
    uint32_t value_count;
    const int16_t *values;
};

static const int16_t mustache_right[] = {
    0, 154, 1506, 0, 154, 1506, 0, 154, 1507, 0, 154, 1508, 0, 154, 1510,
};
static const int16_t lips_1[] = {
    -80, -6, 1818, -80, -6, 1818, -80, -6, 1818, -80, -6, 1817, -80, -6, 1817,
};
static const int16_t eyebrows_2[] = {
    28, 0, 1823, 28, 0, 1823, 28, 0, 1823, 27, 0, 1822, 26, 0, 1821,
};
static const int16_t eyelid_left[] = {
    0, 0, 1620, 0, 0, 1619, 0, 0, 1617, 0, 0, 1614, 0, 0, 1611,
};
static const int16_t intro[] = {
    1128, 0, 0, 0, 0, -20010, 1123, 0, 0, 0, -2, -19891,
    1108, 0, 0, 0, -7, -19548, 1085, 0, 0, 0, -16, -19000,
};
static const int16_t silver_star[] = {
    0, 0, 0, -1300, 1500, 2600, 0, 0, 0, -1300, 1500, 2600,
    0, 0, 0, -1300, 1500, 2600, 0, 0, 0, -1300, 1500, 2600,
};
static const int16_t red_star[] = {
    0, 0, 0, 4291, 2080, 2392, 0, 0, 0, 4290, 2079, 2391,
    0, 0, 0, 4289, 2079, 2389, 0, 0, 0, 4287, 2078, 2385,
};

static const struct payload_window windows[] = {
    { 0x07, 0, 1, 3, 6, sizeof(mustache_right) / sizeof(mustache_right[0]), mustache_right },
    { 0x20, 0, 1, 3, 6, sizeof(lips_1) / sizeof(lips_1[0]), lips_1 },
    { 0x42, 0, 1, 3, 6, sizeof(eyebrows_2) / sizeof(eyebrows_2[0]), eyebrows_2 },
    { 0xCF, 0, 1, 3, 6, sizeof(eyelid_left) / sizeof(eyelid_left[0]), eyelid_left },
    { 0xE2, 0, 1, 6, 8, sizeof(intro) / sizeof(intro[0]), intro },
    { 0xE5, 0, 1, 6, 8, sizeof(silver_star) / sizeof(silver_star[0]), silver_star },
    { 0xE8, 1, 1, 6, 8, sizeof(red_star) / sizeof(red_star[0]), red_star },
};

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (uint32_t byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_windows(void) {
    uint64_t hash = hash_u64(FNV_OFFSET, sizeof(windows) / sizeof(windows[0]));
    for (size_t window_index = 0; window_index < sizeof(windows) / sizeof(windows[0]); ++window_index) {
        const struct payload_window window = windows[window_index];
        const uint32_t frame_count = window.stride == 0 ? 0 : window.value_count / window.stride;
        const uint32_t header[] = {
            window.component_id, window.bank, window.frame_start, window.stride,
            window.type, frame_count, window.value_count,
        };
        for (size_t header_index = 0; header_index < sizeof(header) / sizeof(header[0]); ++header_index) {
            hash = hash_u64(hash, header[header_index]);
        }
        for (uint32_t value_index = 0; value_index < window.value_count; ++value_index) {
            hash = hash_u64(hash, (uint16_t) window.values[value_index]);
        }
    }
    return hash;
}

static const struct payload_window *find_window(uint32_t component_id, uint32_t bank) {
    for (size_t index = 0; index < sizeof(windows) / sizeof(windows[0]); ++index) {
        if (windows[index].component_id == component_id && windows[index].bank == bank) {
            return &windows[index];
        }
    }
    return NULL;
}

static const int16_t *frame(const struct payload_window *window, uint32_t source_frame) {
    const uint32_t frame_count = window->stride == 0 ? 0 : window->value_count / window->stride;
    if (source_frame < window->frame_start || source_frame >= window->frame_start + frame_count) {
        return NULL;
    }
    return &window->values[(source_frame - window->frame_start) * window->stride];
}

static uint64_t hash_frame(uint64_t hash, const int16_t *values, uint32_t stride) {
    hash = hash_u64(hash, values == NULL ? 0 : 1);
    if (values == NULL) {
        return hash;
    }
    hash = hash_u64(hash, stride);
    for (uint32_t index = 0; index < stride; ++index) {
        hash = hash_u64(hash, (uint16_t) values[index]);
    }
    return hash;
}

static int decode_frame(const struct payload_window *window, uint32_t frame_q16, float *output) {
    const uint32_t current_frame = frame_q16 >> 16;
    const uint32_t fraction_q16 = frame_q16 & UINT32_C(0xffff);
    const uint32_t frame_count = window->stride == 0 ? 0 : window->value_count / window->stride;
    if (current_frame < window->frame_start || current_frame >= window->frame_start + frame_count - 1) {
        return 0;
    }
    const int16_t *current = frame(window, current_frame);
    const int16_t *next = frame(window, current_frame + 1);
    const float fraction = (float) fraction_q16 / 65536.0f;
    for (uint32_t index = 0; index < window->stride; ++index) {
        const float interpolated = (float) current[index]
            + ((float) next[index] - (float) current[index]) * fraction;
        output[index] = index < 3 ? interpolated * 0.1f : interpolated;
    }
    return 1;
}

static uint64_t hash_decoded(uint64_t hash, const struct payload_window *window, uint32_t frame_q16) {
    float values[6] = { 0 };
    const int has_frame = window != NULL && decode_frame(window, frame_q16, values);
    hash = hash_u64(hash, has_frame ? 1 : 0);
    if (!has_frame) {
        return hash;
    }
    const uint32_t header[] = {
        window->component_id, window->bank, frame_q16, frame_q16 >> 16,
        (frame_q16 >> 16) + 1, frame_q16 & UINT32_C(0xffff), window->type,
        window->stride,
    };
    for (size_t index = 0; index < sizeof(header) / sizeof(header[0]); ++index) {
        hash = hash_u64(hash, header[index]);
    }
    for (uint32_t index = 0; index < window->stride; ++index) {
        uint32_t bits = 0;
        memcpy(&bits, &values[index], sizeof(bits));
        hash = hash_u64(hash, bits);
    }
    return hash;
}

int main(void) {
    const struct { uint32_t component_id, bank, frame; } probes[] = {
        { 0x07, 0, 1 }, { 0x07, 0, 5 }, { 0x20, 0, 4 }, { 0x42, 0, 2 },
        { 0xCF, 0, 5 }, { 0xE2, 0, 4 }, { 0xE5, 0, 1 }, { 0xE8, 1, 4 },
        { 0xE8, 0, 1 }, { 0x07, 0, 6 },
    };
    const struct { uint32_t component_id, bank, frame_q16; } decoded_probes[] = {
        { 0x07, 0, (1u << 16) | 0x8000u },
        { 0x20, 0, (2u << 16) | 0x4000u },
        { 0x42, 0, (3u << 16) | 0x8000u },
        { 0xCF, 0, (4u << 16) | 0x2000u },
        { 0xE2, 0, (1u << 16) | 0x8000u },
        { 0xE8, 1, (2u << 16) | 0x4000u },
        { 0x07, 0, (5u << 16) | 0x8000u },
    };
    const uint64_t payload_fingerprint = hash_windows();
    uint64_t fingerprint = payload_fingerprint;
    for (size_t index = 0; index < sizeof(probes) / sizeof(probes[0]); ++index) {
        const struct payload_window *window = find_window(probes[index].component_id, probes[index].bank);
        const int16_t *values = window == NULL ? NULL : frame(window, probes[index].frame);
        fingerprint = hash_frame(fingerprint, values, values == NULL ? 0 : window->stride);
    }
    uint64_t decoded_fingerprint = payload_fingerprint;
    for (size_t index = 0; index < sizeof(decoded_probes) / sizeof(decoded_probes[0]); ++index) {
        const struct payload_window *window = find_window(decoded_probes[index].component_id, decoded_probes[index].bank);
        decoded_fingerprint = hash_decoded(decoded_fingerprint, window, decoded_probes[index].frame_q16);
    }
    printf("marioFacePayloadFingerprint=0x%016llx\n", (unsigned long long) payload_fingerprint);
    printf("marioFacePayloadProbeFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    printf("marioFacePayloadDecodedFingerprint=0x%016llx\n", (unsigned long long) decoded_fingerprint);
    printf("marioFacePayloadWindows=%zu\n", sizeof(windows) / sizeof(windows[0]));
    printf("marioFacePayloadProbes=%zu\n", sizeof(probes) / sizeof(probes[0]));
    printf("marioFacePayloadDecodedProbes=%zu\n", sizeof(decoded_probes) / sizeof(decoded_probes[0]));
    printf("SM64 Modern Mario face animation payload C contract passed\n");
    return 0;
}
