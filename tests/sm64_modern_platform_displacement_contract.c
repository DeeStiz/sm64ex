#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "PR/ultratypes.h"

#define AVOID_UB 1
#include "trig_tables.inc.c"

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct Vec3 { float x, y, z; };
struct Angles { int16_t pitch, yaw, roll; };
struct Input {
    struct Vec3 position;
    struct Vec3 platform_position;
    struct Vec3 velocity;
    struct Angles angle_velocity;
    struct Angles face_angles;
    float native_step_scale;
    int is_mario;
    int16_t face_yaw;
};
struct Output { struct Vec3 position; int16_t face_yaw; int rotation_applied; };

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT32_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static void rotate_zxy(float *dest, struct Vec3 translation, struct Angles angles) {
    float sx = gSineTable[(uint16_t) angles.pitch >> 4];
    float cx = gSineTable[0x400 + ((uint16_t) angles.pitch >> 4)];
    float sy = gSineTable[(uint16_t) angles.yaw >> 4];
    float cy = gSineTable[0x400 + ((uint16_t) angles.yaw >> 4)];
    float sz = gSineTable[(uint16_t) angles.roll >> 4];
    float cz = gSineTable[0x400 + ((uint16_t) angles.roll >> 4)];
    dest[0] = cy * cz + sx * sy * sz; dest[1] = cx * sz; dest[2] = -sy * cz + sx * cy * sz; dest[3] = 0;
    dest[4] = -cy * sz + sx * sy * cz; dest[5] = cx * cz; dest[6] = sy * sz + sx * cy * cz; dest[7] = 0;
    dest[8] = cx * sy; dest[9] = -sx; dest[10] = cx * cy; dest[11] = 0;
    dest[12] = translation.x; dest[13] = translation.y; dest[14] = translation.z; dest[15] = 1;
}

static struct Vec3 transpose_mul(const float *matrix, struct Vec3 vector) {
    return (struct Vec3) {
        matrix[0] * vector.x + matrix[1] * vector.y + matrix[2] * vector.z,
        matrix[4] * vector.x + matrix[5] * vector.y + matrix[6] * vector.z,
        matrix[8] * vector.x + matrix[9] * vector.y + matrix[10] * vector.z,
    };
}

static struct Vec3 linear_mul(const float *matrix, struct Vec3 vector) {
    return (struct Vec3) {
        matrix[0] * vector.x + matrix[4] * vector.y + matrix[8] * vector.z,
        matrix[1] * vector.x + matrix[5] * vector.y + matrix[9] * vector.z,
        matrix[2] * vector.x + matrix[6] * vector.y + matrix[10] * vector.z,
    };
}

static struct Output apply(struct Input input) {
    struct Output output = { input.position, input.face_yaw, 0 };
    output.position.x += input.velocity.x * input.native_step_scale;
    output.position.z += input.velocity.z * input.native_step_scale;
    output.rotation_applied = input.angle_velocity.pitch != 0
        || input.angle_velocity.yaw != 0 || input.angle_velocity.roll != 0;
    if (!output.rotation_applied) return output;

    if (input.is_mario) {
        output.face_yaw = (int16_t)((uint16_t) output.face_yaw
            + (uint16_t) input.angle_velocity.yaw);
    }
    struct Vec3 current_offset = {
        output.position.x - input.platform_position.x,
        output.position.y - input.platform_position.y,
        output.position.z - input.platform_position.z,
    };
    struct Angles previous_angles = {
        (int16_t)(input.face_angles.pitch - input.angle_velocity.pitch),
        (int16_t)(input.face_angles.yaw - input.angle_velocity.yaw),
        (int16_t)(input.face_angles.roll - input.angle_velocity.roll),
    };
    float previous[16];
    rotate_zxy(previous, current_offset, previous_angles);
    struct Vec3 relative_offset = transpose_mul(previous, current_offset);
    float current[16];
    rotate_zxy(current, current_offset, input.face_angles);
    struct Vec3 new_offset = linear_mul(current, relative_offset);
    output.position = (struct Vec3) {
        input.platform_position.x + new_offset.x,
        input.platform_position.y + new_offset.y,
        input.platform_position.z + new_offset.z,
    };
    return output;
}

static void append_output(uint64_t *fingerprint, struct Output output) {
    uint32_t bits;
    memcpy(&bits, &output.position.x, sizeof(bits)); *fingerprint = hash_u32(*fingerprint, bits);
    memcpy(&bits, &output.position.y, sizeof(bits)); *fingerprint = hash_u32(*fingerprint, bits);
    memcpy(&bits, &output.position.z, sizeof(bits)); *fingerprint = hash_u32(*fingerprint, bits);
    *fingerprint = hash_u32(*fingerprint, (uint16_t) output.face_yaw);
    *fingerprint = hash_u32(*fingerprint, (uint32_t) output.rotation_applied);
}

int main(void) {
    struct Output mario = apply((struct Input) {
        { 12.5f, 40.0f, -8.0f }, { 10.0f, 20.0f, 30.0f }, { 3.0f, 9.0f, -4.0f },
        { 0x0400, 0x0800, 0x0200 }, { 0x1000, 0x2000, 0x3000 }, 0.5f, 1, 0x1111,
    });
    struct Output object = apply((struct Input) {
        { -4.0f, 1.5f, 8.0f }, { 0.0f, 0.0f, 0.0f }, { 2.0f, -3.0f, 5.0f },
        { 0, 0, 0 }, { 0x2000, 0x3000, 0x4000 }, 2.0f, 0, 0x2222,
    });
    uint64_t fingerprint = FNV_OFFSET;
    append_output(&fingerprint, mario);
    append_output(&fingerprint, object);
    printf("platformDisplacementFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    return mario.rotation_applied && !object.rotation_applied
        && mario.face_yaw == (int16_t) 0x1911
        && object.position.x == 0.0f && object.position.y == 1.5f
        && object.position.z == 18.0f ? 0 : 1;
}
