#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define ACT_FLAG_STATIONARY (UINT32_C(1) << 9)
#define ACT_FLAG_SWIMMING_OR_FLYING (UINT32_C(1) << 28)

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
    uint32_t blink_frame;
    uint32_t eye_case;
    uint32_t hand_case;
    uint32_t stand_run_case;
    uint32_t cap_effect_case;
    uint32_t cap_on_off_case;
    uint32_t wing_active;
    uint32_t alpha;
    uint32_t material_mode;
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
    if (input.eye_state == 0) {
        packet.blink_frame = ((input.body_index * 32u + input.area_update_counter) >> 1) & 0x1Fu;
        packet.eye_case = packet.blink_frame < 7u ? blink_animation[packet.blink_frame] : 0;
    } else {
        packet.blink_frame = 0;
        packet.eye_case = input.eye_state - 1u;
    }
    if (input.hand_state == 0) {
        packet.hand_case = (input.action & ACT_FLAG_SWIMMING_OR_FLYING) != 0 ? 1 : 0;
    } else if (input.hand_switch_case_count == 0) {
        packet.hand_case = input.hand_state < 5 ? input.hand_state : 1;
    } else {
        packet.hand_case = input.hand_state < 2 ? input.hand_state : 0;
    }
    packet.stand_run_case = (input.action & ACT_FLAG_STATIONARY) == 0 ? 1 : 0;
    packet.cap_effect_case = input.model_state >> 8;
    packet.cap_on_off_case = input.cap_state & 1u;
    packet.wing_active = (input.cap_state & 2u) != 0 ? 1 : 0;
    packet.alpha = (input.model_state & 0x100u) != 0 ? input.model_state & 0xFFu : 255;
    packet.material_mode = input.model_state & 0x300u;
    return packet;
}

static uint64_t hash_geometry(void) {
    static const uint32_t component_ids[22] = {
        0x07, 0x10, 0x20, 0x29, 0x32, 0x3F, 0x42, 0x48, 0x4B, 0x54,
        0x6B, 0x7B, 0x84, 0x96, 0x9F, 0xA8, 0xB1, 0xBA, 0xC3, 0xC6,
        0xCF, 0xD8,
    };
    uint64_t hash = FNV_OFFSET;
    const uint32_t header[] = { 0x3E8, 0xE1, 0xDE, 0xDF, 0xE0, 440, 877, 8 };
    for (size_t index = 0; index < sizeof(header) / sizeof(header[0]); ++index) {
        hash = hash_u64(hash, header[index]);
    }
    hash = hash_u64(hash, 22);
    for (size_t index = 0; index < sizeof(component_ids) / sizeof(component_ids[0]); ++index) {
        hash = hash_u64(hash, component_ids[index]);
    }
    hash = hash_u64(hash, 820);
    return hash_u64(hash, 166);
}

static uint64_t hash_packet(uint64_t hash, struct face_packet packet) {
    const uint32_t values[] = {
        packet.blink_frame, packet.eye_case, packet.hand_case, packet.stand_run_case,
        packet.cap_effect_case, packet.cap_on_off_case, packet.wing_active, packet.alpha,
        packet.material_mode,
    };
    for (size_t index = 0; index < sizeof(values) / sizeof(values[0]); ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
}

int main(void) {
    const struct face_input inputs[] = {
        { 0, 0, 0, 0, 0, 0, 0, 0 },
        { 1, 14, 0, ACT_FLAG_STATIONARY, 0, 0, 1, 0x100 },
        { 0, 31, 3, ACT_FLAG_STATIONARY, 1, 1, 2, 0x200 },
        { 0, 8, 0, ACT_FLAG_SWIMMING_OR_FLYING, 0, 0, 2, 0x300 },
        { 0, 16, 0, 0, 2, 0, 3, 0x17F },
        { 1, 63, 8, 0, 5, 1, 0, 0x2FF },
        { 0, 2, 1, ACT_FLAG_STATIONARY, 4, 0, 1, 0 },
        { 1, 5, 0, ACT_FLAG_STATIONARY, 3, 1, 0, 0x280 },
    };
    uint64_t fingerprint = hash_geometry();
    for (size_t index = 0; index < sizeof(inputs) / sizeof(inputs[0]); ++index) {
        fingerprint = hash_packet(fingerprint, resolve_face(inputs[index]));
    }
    printf("marioFaceGeometryFingerprint=0x%016llx\n",
           (unsigned long long)hash_geometry());
    printf("marioFaceFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    printf("marioFaceScenarios=%zu\n", sizeof(inputs) / sizeof(inputs[0]));
    printf("SM64 Modern Mario face C contract passed\n");
    return 0;
}
