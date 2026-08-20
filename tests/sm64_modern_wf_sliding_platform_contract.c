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

struct Init { float position_x, home_x, speed; int32_t face_yaw, timer; };
struct Input { int32_t action, timer, position_x, home_x, forward, face_yaw, move_yaw; float speed; };
struct Output { int32_t action, face_yaw, move_yaw; float position_x, position_y, position_z, forward, velocity_x, velocity_z; };

static struct Init initialize(float x, int32_t face_yaw, uint8_t behavior, int32_t timer) {
    float speed = behavior == 1 ? 10.0f : behavior == 2 ? 15.0f : 20.0f;
    return (struct Init){x + 2.0f, x + 2.0f, speed, face_yaw - 0x4000, timer};
}

static struct Output update(struct Input input) {
    struct Output result = {input.action, input.face_yaw, input.move_yaw, input.position_x, 0, 0, input.forward, 0, 0};
    float threshold = 500.0f / input.speed;
    if (input.action == 0) {
        if ((float)input.timer >= 101.0f) { result.action = 1; result.forward = input.speed; }
    } else if (input.action == 1) {
        if ((float)input.timer >= threshold) { result.forward = 0; result.position_x = input.home_x + 510.0f; }
        if (input.timer == 60) { result.action = 2; result.forward = input.speed; result.move_yaw -= 0x8000; }
    } else if (input.action == 2) {
        if ((float)input.timer >= threshold) { result.forward = 0; result.position_x = input.home_x; }
        if (input.timer == 90) { result.action = 1; result.forward = input.speed; result.move_yaw -= 0x8000; }
    }
    float sine = result.move_yaw == 0x4000 ? 1.0f : result.move_yaw == -0x4000 ? -1.0f : 0.0f;
    result.velocity_x = result.forward * sine;
    result.velocity_z = result.forward * 0.0f;
    result.position_x += result.velocity_x;
    result.position_z += result.velocity_z;
    return result;
}

static uint64_t append_init(uint64_t hash, struct Init value) {
    hash = hash_f32(hash, value.position_x); hash = hash_f32(hash, value.home_x);
    hash = hash_u32(hash, (uint32_t)value.face_yaw); hash = hash_f32(hash, value.speed);
    return hash_u32(hash, (uint32_t)value.timer);
}

static uint64_t append_output(uint64_t hash, struct Output value) {
    hash = hash_u32(hash, (uint32_t)value.action); hash = hash_f32(hash, value.position_x);
    hash = hash_f32(hash, value.position_y); hash = hash_f32(hash, value.position_z);
    hash = hash_f32(hash, value.forward); hash = hash_u32(hash, (uint32_t)value.face_yaw);
    hash = hash_u32(hash, (uint32_t)value.move_yaw); hash = hash_f32(hash, value.velocity_x);
    return hash_f32(hash, value.velocity_z);
}

int main(void) {
    struct Init initialization = initialize(0, 0x8000, 1, 37);
    struct Output waiting = update((struct Input){0, 100, 2, 2, 0, -0x4000, 0x4000, 10});
    struct Output start = update((struct Input){0, 101, 2, 2, 0, -0x4000, 0x4000, 10});
    struct Output extend_end = update((struct Input){1, 50, 12, 2, 10, -0x4000, 0x4000, 10});
    struct Output retract_turn = update((struct Input){1, 60, 12, 2, 0, -0x4000, 0x4000, 10});
    if (initialization.position_x != 2 || initialization.face_yaw != 0x4000 ||
        waiting.action != 0 || start.action != 1 || start.position_x != 12 ||
        extend_end.position_x != 512 || retract_turn.action != 2 || retract_turn.move_yaw != -0x4000) return 2;
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = append_init(fingerprint, initialization);
    fingerprint = append_output(fingerprint, waiting);
    fingerprint = append_output(fingerprint, start);
    fingerprint = append_output(fingerprint, extend_end);
    fingerprint = append_output(fingerprint, retract_turn);
    printf("wfSlidingPlatformFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern WF sliding platform C contract passed");
    return 0;
}
