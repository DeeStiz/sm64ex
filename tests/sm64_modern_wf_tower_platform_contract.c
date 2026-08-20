#include <stdint.h>
#include <stdio.h>

static const uint64_t FNV_OFFSET = UINT64_C(1469598103934665603);
static const uint64_t FNV_PRIME = UINT64_C(1099511628211);

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (value >> (byte * 8)) & 0xffu;
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_f32(uint64_t hash, float value) {
    union { float f; uint32_t u; } bits = { value };
    return hash_u32(hash, bits.u);
}

struct Input {
    int32_t kind, action, timer, x, y, z, yaw, distance, mario_on, parent_action;
    float speed;
};
struct Output {
    int32_t action, should_delete, sound;
    float x, y, z, forward, velocity_x, velocity_z;
};

static struct Output update(struct Input input) {
    struct Output result = {input.action, 0, 0, input.x, input.y, input.z, 0, 0, 0};
    if (input.kind == 0) {
        if (input.action == 0) {
            if (input.mario_on) result.action = 1;
        } else if (input.action == 1) {
            result.sound = 1;
            if (input.timer > 140) result.action = 2;
            else result.y += 5;
        } else if (input.action == 2) {
            if (input.timer > 60) result.action = 3;
        } else if (input.action == 3) {
            result.sound = 1;
            if (input.timer > 140) result.action = 0;
            else result.y -= 5;
        }
    } else {
        int32_t duration = input.speed == 0 ? 0 : input.distance / (int32_t)input.speed;
        if (input.action == 0) {
            if (input.timer > duration) result.action = 1;
            result.forward = -input.speed;
        } else {
            if (input.timer > duration) result.action = 0;
            result.forward = input.speed;
        }
        result.velocity_x = result.forward * 0.0f;
        result.velocity_z = result.forward * 1.0f;
        result.x += result.velocity_x;
        result.z += result.velocity_z;
    }
    result.should_delete = input.parent_action == 3;
    return result;
}

static uint64_t append(uint64_t hash, struct Output value) {
    hash = hash_u32(hash, (uint32_t)value.action);
    hash = hash_f32(hash, value.x); hash = hash_f32(hash, value.y); hash = hash_f32(hash, value.z);
    hash = hash_f32(hash, value.forward); hash = hash_f32(hash, value.velocity_x);
    hash = hash_f32(hash, value.velocity_z);
    hash = hash_u32(hash, (uint32_t)value.should_delete);
    return hash_u32(hash, (uint32_t)value.sound);
}

int main(void) {
    struct Output elevator_idle = update((struct Input){0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0});
    struct Output elevator_start = update((struct Input){0, 0, 0, 0, 100, 0, 0, 0, 1, 0, 0});
    struct Output elevator_up = update((struct Input){0, 1, 140, 0, 100, 0, 0, 0, 1, 0, 0});
    struct Output sliding_back = update((struct Input){1, 0, 0, 0, 100, 0, 0, 380, 0, 0, 3});
    struct Output sliding_turn = update((struct Input){1, 0, 127, 0, 100, 0, 0, 380, 0, 3, 3});
    if (elevator_start.action != 1 || elevator_up.y != 105 || sliding_back.forward != -3 ||
        sliding_back.z != -3 || sliding_turn.action != 1 || !sliding_turn.should_delete) return 2;
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = append(fingerprint, elevator_idle);
    fingerprint = append(fingerprint, elevator_start);
    fingerprint = append(fingerprint, elevator_up);
    fingerprint = append(fingerprint, sliding_back);
    fingerprint = append(fingerprint, sliding_turn);
    printf("wfTowerPlatformFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern WF tower platform C contract passed");
    return 0;
}
