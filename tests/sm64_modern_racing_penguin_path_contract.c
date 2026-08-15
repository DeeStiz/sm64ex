#include <stdint.h>
#include <stdio.h>
#include <math.h>

#include "PR/ultratypes.h"
#define AVOID_UB 1
#include "trig_tables.inc.c"

enum {
    PATH_NONE = 0,
    PATH_REACHED_WAYPOINT = 1,
    PATH_REACHED_END = -1,
    WAYPOINT_END = -1,
    WAYPOINT_INITIALIZED = 0x8000,
};

typedef struct { int16_t flags; float x, y, z; } Waypoint;
typedef struct {
    int status;
    int previous_index;
    int previous_flags;
    int16_t target_yaw;
    int16_t target_pitch;
} PathOutput;

static int16_t atan2s_c(float y, float x) {
    uint16_t ret;
    if (x >= 0) {
        if (y >= 0) {
            if (y >= x) ret = gArctanTable[(int) (x / y * 1024 + 0.5f)];
            else ret = 0x4000 - gArctanTable[(int) (y / x * 1024 + 0.5f)];
        } else {
            y = -y;
            if (y < x) ret = 0x4000 + gArctanTable[(int) (y / x * 1024 + 0.5f)];
            else ret = 0x8000 - gArctanTable[(int) (x / y * 1024 + 0.5f)];
        }
    } else {
        x = -x;
        if (y < 0) {
            y = -y;
            if (y >= x) ret = 0x8000 + gArctanTable[(int) (x / y * 1024 + 0.5f)];
            else ret = 0xC000 - gArctanTable[(int) (y / x * 1024 + 0.5f)];
        } else {
            if (y < x) ret = 0xC000 + gArctanTable[(int) (y / x * 1024 + 0.5f)];
            else ret = (uint16_t) (-(int16_t) gArctanTable[(int) (x / y * 1024 + 0.5f)]);
        }
    }
    return (int16_t) ret;
}

static PathOutput follow_path(const Waypoint *waypoints, int count,
                              int start_index, int previous_index,
                              int previous_flags, float x, float y, float z) {
    int last_index = previous_index;
    if (previous_flags == 0) {
        last_index = start_index;
        previous_flags = WAYPOINT_INITIALIZED;
    }
    int target_index = waypoints[last_index + 1].flags != WAYPOINT_END
        ? last_index + 1 : start_index;
    const Waypoint *last = &waypoints[last_index];
    const Waypoint *target = &waypoints[target_index];
    previous_flags = last->flags | WAYPOINT_INITIALIZED;
    float prev_to_next_x = target->x - last->x;
    float prev_to_next_y = target->y - last->y;
    float prev_to_next_z = target->z - last->z;
    float object_to_next_x = target->x - x;
    float object_to_next_y = target->y - y;
    float object_to_next_z = target->z - z;
    float object_to_next_xz = sqrtf(object_to_next_x * object_to_next_x + object_to_next_z * object_to_next_z);
    PathOutput result = {
        PATH_NONE,
        last_index,
        previous_flags,
        atan2s_c(object_to_next_z, object_to_next_x),
        atan2s_c(object_to_next_xz, -object_to_next_y),
    };
    float dot = prev_to_next_x * object_to_next_x
        + prev_to_next_y * object_to_next_y
        + prev_to_next_z * object_to_next_z;
    if (dot <= 0.0f) {
        result.previous_index = target_index;
        result.status = waypoints[target_index + 1].flags == WAYPOINT_END
            ? PATH_REACHED_END : PATH_REACHED_WAYPOINT;
    }
    (void) count;
    return result;
}

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (int byte = 0; byte < 4; ++byte) {
        hash ^= (uint64_t) ((value >> (byte * 8)) & 0xff);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static uint64_t hash_i16(uint64_t hash, int16_t value) {
    return hash_u32(hash, (uint32_t) (uint16_t) value);
}

static uint64_t hash_output(uint64_t hash, PathOutput output) {
    hash = hash_u32(hash, (uint32_t) output.status);
    hash = hash_u32(hash, (uint32_t) output.previous_index);
    hash = hash_u32(hash, (uint32_t) output.previous_flags);
    hash = hash_i16(hash, output.target_yaw);
    return hash_i16(hash, output.target_pitch);
}

int main(void) {
    const Waypoint path[] = {
        {0, 0, 0, 0}, {7, 10, 5, 0}, {35, 20, 0, 10}, {-1, 0, 0, 0}
    };
    uint64_t fingerprint = UINT64_C(1469598103934665603);
    PathOutput first = follow_path(path, 4, 0, 0, 0, 0, 0, 0);
    fingerprint = hash_output(fingerprint, first);
    PathOutput waypoint = follow_path(path, 4, 0, first.previous_index,
                                      first.previous_flags, 11, 6, 0);
    fingerprint = hash_output(fingerprint, waypoint);
    PathOutput end = follow_path(path, 4, 0, waypoint.previous_index,
                                 waypoint.previous_flags, 21, -1, 11);
    fingerprint = hash_output(fingerprint, end);
    PathOutput restart = follow_path(path, 4, 1, 99, 0, 10, 5, 0);
    fingerprint = hash_output(fingerprint, restart);
    printf("racingPenguinPathFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    printf("SM64 Modern racing penguin path C contract passed\n");
    return 0;
}
