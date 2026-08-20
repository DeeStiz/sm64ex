#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct parent_output { int32_t action; int spawn_children; int visible; };
struct platform_output {
    int32_t action, angle_velocity_pitch, angle_velocity_roll, face_pitch, face_roll;
    float position_y, velocity_y;
    int should_delete, play_sound;
};

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_f32(uint64_t hash, float value) {
    uint32_t bits = 0;
    memcpy(&bits, &value, sizeof(bits));
    return hash_u64(hash, bits);
}

static struct parent_output update_parent(int32_t action, float distance, int variant) {
    struct parent_output output = { action, 0, 1 };
    if (action == 0) {
        if (variant == 2 || distance < 1000) output.action = 1;
    } else if (action == 1) {
        output.action = 2;
        output.spawn_children = 1;
    } else if (action == 2) {
        if (variant == 2) {
            output.visible = 1;
        } else if (distance > 1200) {
            output.action = 3;
        } else {
            output.visible = 0;
        }
    } else if (action == 3) {
        output.action = 0;
    } else {
        output.action = 0;
    }
    return output;
}

static struct platform_output update_platform(
    int32_t action, int32_t timer, int mario_on_platform,
    int32_t angle_velocity_pitch, int32_t angle_velocity_roll,
    int32_t face_pitch, int32_t face_roll, float position_y,
    float velocity_y, float floor_height, int32_t parent_action, int32_t roll_step
) {
    struct platform_output output = {
        action, angle_velocity_pitch, angle_velocity_roll, face_pitch, face_roll,
        position_y, velocity_y, parent_action == 3, 0,
    };
    if (action == 0) {
        if (mario_on_platform) output.action = 1;
    } else if (action == 1) {
        if (timer > 5) { output.action = 2; output.play_sound = 1; }
    } else if (action == 2) {
        if (output.angle_velocity_pitch < 0x400) output.angle_velocity_pitch += 0x80;
        if (output.angle_velocity_roll > -0x400 && output.angle_velocity_roll < 0x400)
            output.angle_velocity_roll += roll_step;
        output.velocity_y += -3.0f;
        output.position_y += output.velocity_y;
        output.face_pitch += output.angle_velocity_pitch;
        output.face_roll += output.angle_velocity_roll;
        if (output.position_y < floor_height - 300.0f) output.action = 3;
    }
    return output;
}

int main(void) {
    const struct parent_output parents[] = {
        update_parent(0, 900, 0), update_parent(1, 900, 0),
        update_parent(2, 1300, 0), update_parent(2, 1000, 1),
        update_parent(0, 5000, 2),
    };
    const struct platform_output platforms[] = {
        update_platform(0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 2, 0x80),
        update_platform(1, 6, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0x80),
        update_platform(2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0x80),
        update_platform(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, -0x80),
    };
    if (parents[0].action != 1 || parents[1].action != 2 || !parents[1].spawn_children ||
        parents[2].action != 3 || parents[3].visible != 0 || parents[4].action != 1 ||
        platforms[0].action != 1 || platforms[1].action != 2 || !platforms[1].play_sound ||
        platforms[2].angle_velocity_pitch != 0x80 || platforms[2].angle_velocity_roll != 0x80 ||
        platforms[2].position_y != -3.0f || platforms[2].velocity_y != -3.0f ||
        !platforms[3].should_delete) return 1;

    uint64_t fingerprint = FNV_OFFSET;
    for (unsigned i = 0; i < sizeof(parents) / sizeof(parents[0]); ++i) {
        fingerprint = hash_u64(fingerprint, (uint64_t)(int64_t)parents[i].action);
        fingerprint = hash_u64(fingerprint, (uint64_t)parents[i].spawn_children);
        fingerprint = hash_u64(fingerprint, (uint64_t)parents[i].visible);
    }
    for (unsigned i = 0; i < sizeof(platforms) / sizeof(platforms[0]); ++i) {
        fingerprint = hash_u64(fingerprint, (uint64_t)(int64_t)platforms[i].action);
        fingerprint = hash_u64(fingerprint, (uint64_t)(int64_t)platforms[i].angle_velocity_pitch);
        fingerprint = hash_u64(fingerprint, (uint64_t)(int64_t)platforms[i].angle_velocity_roll);
        fingerprint = hash_u64(fingerprint, (uint64_t)(int64_t)platforms[i].face_pitch);
        fingerprint = hash_u64(fingerprint, (uint64_t)(int64_t)platforms[i].face_roll);
        fingerprint = hash_f32(fingerprint, platforms[i].position_y);
        fingerprint = hash_f32(fingerprint, platforms[i].velocity_y);
        fingerprint = hash_u64(fingerprint, (uint64_t)platforms[i].should_delete);
        fingerprint = hash_u64(fingerprint, (uint64_t)platforms[i].play_sound);
    }
    printf("tumblingBridgeFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern tumbling bridge C contract passed");
    return 0;
}
