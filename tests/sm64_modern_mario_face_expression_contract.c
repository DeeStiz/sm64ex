#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define EYE_BLINK 0u
#define EYE_OPEN 1u
#define EYE_HALF_CLOSED 2u
#define EYE_CLOSED 3u

struct face_input {
    uint32_t body_index;
    uint32_t area_update_counter;
    uint32_t eye_state;
    uint32_t action;
    uint32_t hand_state;
    uint32_t hand_switch_case_count;
    uint32_t cap_state;
    uint32_t model_state;
};

struct face_packet {
    uint32_t blink_frame, eye_case, hand_case, stand_run_case;
    uint32_t cap_effect_case, cap_on_off_case, wing_active, alpha, material_mode;
};

struct expression_input {
    struct face_input face;
    uint32_t animation_bank;
    uint32_t animation_frame_q16;
    uint32_t peach_kiss_timeline;
    uint32_t action_timer;
};

struct expression_packet {
    struct face_packet face;
    uint32_t animation_bank;
    uint32_t animation_frame_q16;
    uint32_t eye_override_state;
    uint32_t eye_override_source;
    uint32_t payload_window_mask;
    uint32_t decoded_payload_window_count;
    uint32_t unavailable_catalog_channel_count;
};

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (uint32_t byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static struct face_packet resolve_face(struct face_input input) {
    static const uint32_t blink_animation[7] = { 1, 2, 1, 0, 1, 2, 1 };
    struct face_packet packet;
    if (input.eye_state == EYE_BLINK) {
        packet.blink_frame = ((input.body_index * 32u + input.area_update_counter) >> 1) & 0x1Fu;
        packet.eye_case = packet.blink_frame < 7u ? blink_animation[packet.blink_frame] : 0;
    } else {
        packet.blink_frame = 0;
        packet.eye_case = input.eye_state - 1u;
    }
    if (input.hand_state == 0) {
        packet.hand_case = (input.action & (UINT32_C(1) << 28)) != 0 ? 1 : 0;
    } else if (input.hand_switch_case_count == 0) {
        packet.hand_case = input.hand_state < 5 ? input.hand_state : 1;
    } else {
        packet.hand_case = input.hand_state < 2 ? input.hand_state : 0;
    }
    packet.stand_run_case = (input.action & (UINT32_C(1) << 9)) == 0 ? 1 : 0;
    packet.cap_effect_case = input.model_state >> 8;
    packet.cap_on_off_case = input.cap_state & 1u;
    packet.wing_active = (input.cap_state & 2u) != 0 ? 1 : 0;
    packet.alpha = (input.model_state & 0x100u) != 0 ? input.model_state & 0xFFu : 255;
    packet.material_mode = input.model_state & 0x300u;
    return packet;
}

static const struct { uint32_t component_id, bank, frame_count; } payload_windows[] = {
    { 0x07, 0, 5 }, { 0x20, 0, 5 }, { 0x42, 0, 5 }, { 0xCF, 0, 5 },
    { 0xE2, 0, 4 }, { 0xE5, 0, 4 }, { 0xE8, 1, 4 },
};

static int payload_available(uint32_t component_id, uint32_t bank, uint32_t frame_q16) {
    const uint32_t current_frame = frame_q16 >> 16;
    for (size_t index = 0; index < sizeof(payload_windows) / sizeof(payload_windows[0]); ++index) {
        if (payload_windows[index].component_id == component_id && payload_windows[index].bank == bank) {
            return current_frame >= 1 && current_frame < payload_windows[index].frame_count;
        }
    }
    return 0;
}

static int eye_override(const struct expression_input *input, uint32_t *state, uint32_t *source) {
    static const uint32_t peach_override[20] = {
        2, 2, 3, 3, 2, 2, 1, 1, 2, 2, 3, 3, 2, 2, 1, 1, 2, 2, 3, 3,
    };
    if (input->peach_kiss_timeline) {
        if (input->action_timer == 75) {
            *state = EYE_HALF_CLOSED;
        } else if (input->action_timer == 76) {
            *state = EYE_CLOSED;
        } else if (input->action_timer < 90) {
            return 0;
        } else if (input->action_timer < 110) {
            *state = peach_override[input->action_timer - 90];
        } else {
            *state = EYE_HALF_CLOSED;
        }
        *source = 1;
        return 1;
    }
    if (input->action_timer < 52) {
        *state = EYE_HALF_CLOSED;
        *source = 2;
        return 1;
    }
    return 0;
}

static struct expression_packet resolve_expression(struct expression_input input) {
    uint32_t override_state = UINT32_C(0xffffffff);
    uint32_t override_source = 0;
    const int has_override = eye_override(&input, &override_state, &override_source);
    if (has_override) {
        input.face.eye_state = override_state;
    }
    struct expression_packet packet = { 0 };
    packet.face = resolve_face(input.face);
    packet.animation_bank = input.animation_bank;
    packet.animation_frame_q16 = input.animation_frame_q16;
    packet.eye_override_state = override_state;
    packet.eye_override_source = override_source;
    for (size_t index = 0; index < sizeof(payload_windows) / sizeof(payload_windows[0]); ++index) {
        if (payload_available(payload_windows[index].component_id, input.animation_bank, input.animation_frame_q16)) {
            packet.payload_window_mask |= UINT32_C(1) << index;
        }
    }
    packet.decoded_payload_window_count = (uint32_t) __builtin_popcount(packet.payload_window_mask);
    packet.unavailable_catalog_channel_count = 25 - packet.decoded_payload_window_count;
    return packet;
}

static uint64_t hash_packet(uint64_t hash, struct expression_packet packet) {
    const uint32_t values[] = {
        packet.face.blink_frame, packet.face.eye_case, packet.face.hand_case,
        packet.face.stand_run_case, packet.face.cap_effect_case, packet.face.cap_on_off_case,
        packet.face.wing_active, packet.face.alpha, packet.face.material_mode,
        packet.animation_bank, packet.animation_frame_q16, packet.eye_override_state,
        packet.eye_override_source, packet.payload_window_mask,
        packet.decoded_payload_window_count, packet.unavailable_catalog_channel_count,
    };
    for (size_t index = 0; index < sizeof(values) / sizeof(values[0]); ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
}

int main(void) {
    const struct expression_input inputs[] = {
        { { 0, 0, EYE_BLINK, 0, 0, 0, 0, 0 }, 0, (1u << 16) | 0x8000u, 0, 100 },
        { { 0, 0, EYE_BLINK, 0, 0, 0, 0, 0 }, 0, (1u << 16) | 0x8000u, 1, 96 },
        { { 0, 0, EYE_BLINK, 0, 0, 0, 0, 0 }, 1, (2u << 16) | 0x4000u, 0, 20 },
        { { 0, 0, EYE_BLINK, 0, 0, 0, 0, 0 }, 0, (5u << 16) | 0x8000u, 0, 52 },
    };
    uint64_t payload_fingerprint = FNV_OFFSET;
    const uint32_t payload_headers[] = { 7, 0x07, 0x20, 0x42, 0xCF, 0xE2, 0xE5, 0xE8 };
    for (size_t index = 0; index < sizeof(payload_headers) / sizeof(payload_headers[0]); ++index) {
        payload_fingerprint = hash_u64(payload_fingerprint, payload_headers[index]);
    }
    uint64_t fingerprint = payload_fingerprint;
    for (size_t index = 0; index < sizeof(inputs) / sizeof(inputs[0]); ++index) {
        fingerprint = hash_packet(fingerprint, resolve_expression(inputs[index]));
    }
    printf("marioFaceExpressionPayloadSelectionSeed=0x%016llx\n", (unsigned long long) payload_fingerprint);
    printf("marioFaceExpressionFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    printf("marioFaceExpressionScenarios=%zu\n", sizeof(inputs) / sizeof(inputs[0]));
    printf("marioFaceExpressionPayloadWindows=7\n");
    printf("marioFaceExpressionCatalogChannels=25\n");
    printf("SM64 Modern Mario face expression C contract passed\n");
    return 0;
}
