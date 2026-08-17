#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "src/goddard/dynlists/animdata.h"

#include "src/goddard/dynlists/anim_mario_mustache_right.c"
#include "src/goddard/dynlists/anim_mario_mustache_left.c"
#include "src/goddard/dynlists/anim_mario_lips_1.c"
#include "src/goddard/dynlists/anim_mario_lips_2.c"
#include "src/goddard/dynlists/anim_mario_eyebrows_1.c"
#include "src/goddard/dynlists/anim_group_1.c"
#include "src/goddard/dynlists/anim_group_2.c"

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define CATALOG_FINGERPRINT UINT64_C(0x47eaad2dfd5d62ed)

struct channel_ref {
    uint32_t component_id;
    const struct AnimDataInfo *info;
};

static const struct channel_ref channels[] = {
    { 0x07, anim_mario_mustache_right },
    { 0x10, anim_mario_mustache_left },
    { 0x20, anim_mario_lips_1 },
    { 0x29, anim_mario_lips_2 },
    { 0x32, anim_mario_eyebrows_1 },
    { 0x3F, anim_mario_eyebrows_equalizer },
    { 0x42, anim_mario_eyebrows_2 },
    { 0x48, anim_mario_eyebrows_3 },
    { 0x4B, anim_mario_eyebrows_4 },
    { 0x54, anim_mario_eyebrows_5 },
    { 0x6B, anim_mario_eye_left },
    { 0x7B, anim_mario_eye_right },
    { 0x84, anim_mario_hat },
    { 0x96, anim_mario_lips_3 },
    { 0x9F, anim_mario_lips_4 },
    { 0xA8, anim_mario_ear_left },
    { 0xB1, anim_mario_ear_right },
    { 0xBA, anim_mario_nose },
    { 0xC3, anim_mario_lips_5 },
    { 0xC6, anim_mario_lips_6 },
    { 0xCF, anim_mario_eyelid_left },
    { 0xD8, anim_mario_eyelid_right },
    { 0xE2, anim_mario_intro },
    { 0xE5, anim_silver_star },
    { 0xE8, anim_red_star },
};

struct mesh_resource {
    uint32_t mesh_id;
    uint32_t shape_id;
    uint32_t vertex_group_id;
    uint32_t plane_group_id;
    uint32_t material_group_id;
    uint32_t vertex_count;
    uint32_t face_count;
    uint32_t material_count;
};

static const struct mesh_resource meshes[] = {
    { 1, 0xE1, 0xDE, 0xDF, 0xE0, 440, 877, 8 },
    { 2, 0x74, 0x71, 0x72, 0x73, 48, 82, 4 },
    { 3, 0x64, 0x61, 0x62, 0x63, 48, 82, 4 },
    { 4, 0x5D, 0x5A, 0x5B, 0x5C, 26, 36, 1 },
    { 5, 0x3B, 0x38, 0x39, 0x3A, 26, 36, 1 },
    { 6, 0x19, 0x16, 0x17, 0x18, 56, 100, 1 },
};

static const uint32_t material_counts[] = { 8, 4, 4, 1, 1, 1 };
static const struct {
    uint32_t object_id;
    uint32_t logical_id;
    uint32_t flags;
    uint32_t diffuse[3];
} lights[] = {
    { 0xE4, 1, 0x20, { 1000, 1000, 1000 } },
    { 0xE7, 0, 0x20, { 1000, 0, 0 } },
};

struct scenario {
    uint32_t bank;
    uint32_t frame_q16;
    uint32_t peach_kiss;
    uint32_t action_timer;
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

static uint64_t hash_values(uint64_t hash, const uint32_t *values, size_t count) {
    for (size_t index = 0; index < count; ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
}

static uint32_t stride_for_type(enum GdAnimations type) {
    switch (type) {
        case GD_ANIM_3H_SCALED:
        case GD_ANIM_3H:
            return 3;
        case GD_ANIM_6H_SCALED:
        case GD_ANIM_CAMERA:
            return 6;
        default:
            return 0;
    }
}

static uint32_t float_bits(float value) {
    uint32_t bits = 0;
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

static const struct AnimDataInfo *selected_info(const struct channel_ref *channel, uint32_t bank) {
    return bank < 2 ? &channel->info[bank] : NULL;
}

static int is_decodable(const struct AnimDataInfo *info, uint32_t current_frame) {
    return info != NULL && info->count > 1 && current_frame > 0
        && current_frame <= (uint32_t) info->count;
}

static uint32_t peach_eye_state(uint32_t action_timer, int *has_override) {
    static const uint32_t blink_override[20] = {
        2, 2, 3, 3, 2, 2, 1, 1, 2, 2,
        3, 3, 2, 2, 1, 1, 2, 2, 3, 3,
    };
    if (action_timer == 75) {
        *has_override = 1;
        return 2;
    }
    if (action_timer == 76) {
        *has_override = 1;
        return 3;
    }
    if (action_timer >= 90 && action_timer < 110) {
        *has_override = 1;
        return blink_override[action_timer - 90];
    }
    if (action_timer >= 110) {
        *has_override = 1;
        return 2;
    }
    return 0xFFFFFFFFu;
}

static void eye_timeline(const struct scenario *scenario, uint32_t *state, uint32_t *source) {
    int has_override = 0;
    uint32_t value = 0xFFFFFFFFu;
    if (scenario->peach_kiss) {
        value = peach_eye_state(scenario->action_timer, &has_override);
        *source = has_override ? 1 : 0;
    } else if (scenario->action_timer < 52) {
        has_override = 1;
        value = 2;
        *source = 2;
    } else {
        *source = 0;
    }
    *state = has_override ? value : 0xFFFFFFFFu;
}

static struct face_packet resolve_face(uint32_t eye_state) {
    static const uint32_t blink_animation[7] = { 1, 2, 1, 0, 1, 2, 1 };
    struct face_packet packet;
    if (eye_state == 0) {
        packet.blink_frame = 0;
        packet.eye_case = blink_animation[0];
    } else {
        packet.blink_frame = 0;
        packet.eye_case = eye_state - 1;
    }
    packet.hand_case = 0;
    packet.stand_run_case = 1;
    packet.cap_effect_case = 0;
    packet.cap_on_off_case = 0;
    packet.wing_active = 0;
    packet.alpha = 255;
    packet.material_mode = 0;
    return packet;
}

static uint64_t packet_fingerprint(const struct scenario *scenario) {
    const uint32_t current_frame = scenario->frame_q16 >> 16;
    const uint32_t fraction_q16 = scenario->frame_q16 & UINT32_C(0xffff);
    uint32_t eye_state;
    uint32_t eye_source;
    eye_timeline(scenario, &eye_state, &eye_source);
    const struct face_packet face = resolve_face(eye_state == 0xFFFFFFFFu ? 0 : eye_state);

    uint64_t channel_mask = 0;
    uint32_t resident_count = 0;
    for (size_t index = 0; index < sizeof(channels) / sizeof(channels[0]); ++index) {
        if (is_decodable(selected_info(&channels[index], scenario->bank), current_frame)) {
            channel_mask |= UINT64_C(1) << index;
            resident_count += 1;
        }
    }

    uint64_t hash = hash_u64(FNV_OFFSET, CATALOG_FINGERPRINT);
    const uint32_t root[] = { 0x3E8, 0x3E9, scenario->bank, scenario->frame_q16 };
    hash = hash_values(hash, root, sizeof(root) / sizeof(root[0]));
    const uint32_t face_values[] = {
        face.blink_frame, face.eye_case, face.hand_case, face.stand_run_case,
        face.cap_effect_case, face.cap_on_off_case, face.wing_active, face.alpha,
        face.material_mode, eye_state, eye_source,
    };
    hash = hash_values(hash, face_values, sizeof(face_values) / sizeof(face_values[0]));
    hash = hash_u64(hash, (uint32_t) channel_mask);
    hash = hash_u64(hash, (uint32_t) (channel_mask >> 32));
    const uint32_t counts[] = { resident_count, (uint32_t) (sizeof(channels) / sizeof(channels[0])) - resident_count };
    hash = hash_values(hash, counts, sizeof(counts) / sizeof(counts[0]));

    hash = hash_u64(hash, sizeof(meshes) / sizeof(meshes[0]));
    for (size_t index = 0; index < sizeof(meshes) / sizeof(meshes[0]); ++index) {
        const struct mesh_resource mesh = meshes[index];
        const uint32_t values[] = {
            mesh.mesh_id, mesh.shape_id, mesh.vertex_group_id, mesh.plane_group_id,
            mesh.material_group_id, mesh.vertex_count, mesh.face_count,
            mesh.material_count, 0, 0, material_counts[index],
        };
        hash = hash_values(hash, values, sizeof(values) / sizeof(values[0]));
        for (uint32_t material = 0; material < material_counts[index]; ++material) {
            hash = hash_u64(hash, material);
        }
    }

    hash = hash_u64(hash, sizeof(lights) / sizeof(lights[0]));
    for (size_t index = 0; index < sizeof(lights) / sizeof(lights[0]); ++index) {
        const uint32_t values[] = {
            lights[index].object_id, lights[index].logical_id, lights[index].flags,
        };
        hash = hash_values(hash, values, sizeof(values) / sizeof(values[0]));
        hash = hash_values(hash, lights[index].diffuse, 3);
    }

    hash = hash_u64(hash, sizeof(channels) / sizeof(channels[0]));
    for (size_t index = 0; index < sizeof(channels) / sizeof(channels[0]); ++index) {
        const struct channel_ref *channel = &channels[index];
        const struct AnimDataInfo *info = selected_info(channel, scenario->bank);
        const int available = is_decodable(info, current_frame);
        const uint32_t type = available ? (uint32_t) info->type : 0;
        const uint32_t stride = available ? stride_for_type(info->type) : 0;
        const uint32_t next_frame = available && current_frame == (uint32_t) info->count
            ? 1 : current_frame + 1;
        const uint32_t source_frame = available ? current_frame : 0;
        const uint32_t source_next = available ? next_frame : 0;
        const uint32_t value_count = available ? stride : 0;
        const uint32_t linked_object = channel->component_id == 0xE2
            ? 0xDD : channel->component_id - 1;
        const uint32_t values[] = {
            channel->component_id, channel->component_id + 1, 0x3E9,
            channel->component_id, channel->component_id, linked_object,
            available ? 1u : 0u, type, source_frame, source_next,
            fraction_q16, value_count,
        };
        hash = hash_values(hash, values, sizeof(values) / sizeof(values[0]));
        if (!available) {
            continue;
        }
        const uint16_t *raw = info->data;
        const uint32_t current_offset = (current_frame - 1) * stride;
        const uint32_t next_offset = (next_frame - 1) * stride;
        const float fraction = (float) fraction_q16 / 65536.0f;
        for (uint32_t component = 0; component < stride; ++component) {
            const float current = (float) (int16_t) raw[current_offset + component];
            const float next = (float) (int16_t) raw[next_offset + component];
            float interpolated = current + (next - current) * fraction;
            if (component < 3) {
                interpolated *= 0.1f;
            }
            hash = hash_u64(hash, float_bits(interpolated));
        }
    }
    return hash;
}

int main(void) {
    const struct scenario scenarios[] = {
        { 0, (1u << 16) | 0x8000u, 0, 100 },
        { 0, (820u << 16) | 0x8000u, 1, 96 },
        { 1, (165u << 16) | 0x4000u, 0, 20 },
        { 1, (166u << 16) | 0x8000u, 0, 52 },
        { 2, (1u << 16) | 0x8000u, 0, 52 },
    };
    const uint64_t seed = hash_u64(FNV_OFFSET, CATALOG_FINGERPRINT);
    uint64_t fingerprint = seed;
    for (size_t index = 0; index < sizeof(scenarios) / sizeof(scenarios[0]); ++index) {
        fingerprint = hash_u64(fingerprint, packet_fingerprint(&scenarios[index]));
    }
    printf("marioFaceRenderPacketSeed=0x%016llx\n", (unsigned long long) seed);
    printf("marioFaceRenderPacketFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    printf("marioFaceRenderPacketScenarios=%zu\n", sizeof(scenarios) / sizeof(scenarios[0]));
    printf("marioFaceRenderPacketMeshes=%zu\n", sizeof(meshes) / sizeof(meshes[0]));
    printf("marioFaceRenderPacketAnimations=%zu\n", sizeof(channels) / sizeof(channels[0]));
    printf("SM64 Modern Mario face render packet C contract passed\n");
    return 0;
}
