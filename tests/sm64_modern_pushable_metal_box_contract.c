#include <stdint.h>
#include <stdio.h>

static const uint64_t OFFSET = UINT64_C(1469598103934665603);
static const uint64_t PRIME = UINT64_C(1099511628211);
static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (value >> (byte * 8)) & UINT32_C(0xff);
        hash *= PRIME;
    }
    return hash;
}
static uint64_t hash_float(uint64_t hash, float value) {
    union { float f; uint32_t u; } bits = { value };
    return hash_u32(hash, bits.u);
}
struct Output { float x, y, z, velocity_y, forward_velocity; int32_t move_yaw; int pushed; };
static struct Output update(
    float x, float y, float z, int32_t move_yaw, float velocity_y, float gravity,
    int collided, uint32_t mario_flags, int32_t box_to_mario_yaw,
    int32_t mario_move_yaw, float floor_delta
) {
    struct Output output = { x, y, z, velocity_y + gravity, 0, move_yaw, 0 };
    if (collided && (mario_flags & UINT32_C(0x80000000)) &&
        (box_to_mario_yaw == (int32_t)0x8000 || box_to_mario_yaw == (int32_t)0x8001) &&
        mario_move_yaw == 0 && floor_delta < 8.0f && floor_delta > -8.0f) {
        output.move_yaw = (mario_move_yaw + 0x2000) & 0xC000;
        output.forward_velocity = 4;
        output.pushed = 1;
    }
    float sx = output.move_yaw == 0x4000 ? 1.0f : output.move_yaw == (int32_t)0xC000 ? -1.0f : 0.0f;
    float cz = output.move_yaw == 0 ? 1.0f : output.move_yaw == (int32_t)0x8000 ? -1.0f : 0.0f;
    output.x += output.forward_velocity * sx;
    output.y += output.velocity_y;
    output.z += output.forward_velocity * cz;
    return output;
}
static uint64_t append(uint64_t hash, struct Output output) {
    hash = hash_float(hash, output.x); hash = hash_float(hash, output.y);
    hash = hash_float(hash, output.z); hash = hash_float(hash, output.velocity_y);
    hash = hash_float(hash, output.forward_velocity);
    hash = hash_u32(hash, (uint32_t)output.move_yaw);
    return hash_u32(hash, (uint32_t)output.pushed);
}
int main(void) {
    struct Output idle = update(0, 10, 0, 0, -2, -3, 0, 0, 0, 0, 0);
    struct Output push = update(0, 10, 0, 0, 0, 0, 1, UINT32_C(0x80000000), (int32_t)0x8000, 0, 0);
    struct Output blocked = update(0, 10, 0, 0, 0, 0, 1, UINT32_C(0x80000000), (int32_t)0x8000, 0, 10);
    if (idle.forward_velocity != 0 || idle.y != 5 || push.forward_velocity != 4 ||
        push.z != 4 || !push.pushed || blocked.forward_velocity != 0 || blocked.pushed) return 2;
    uint64_t fingerprint = OFFSET;
    fingerprint = append(fingerprint, idle); fingerprint = append(fingerprint, push); fingerprint = append(fingerprint, blocked);
    fingerprint = hash_float(fingerprint, 220); fingerprint = hash_float(fingerprint, 300);
    printf("pushableMetalBoxFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern pushable metal box C contract passed");
    return 0;
}
