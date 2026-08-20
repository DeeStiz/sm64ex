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

struct Output {
    int32_t action, timer, move_yaw;
    float x, y, z, forward_velocity, velocity_y;
};

static struct Output update(
    int32_t action, int32_t timer, int32_t behavior_byte,
    float x, float y, float z, int32_t move_yaw, float velocity_y, float gravity
) {
    struct Output output = {
        action, timer, move_yaw, x, y, z, 10.0f, velocity_y + gravity
    };
    switch (action) {
        case 0: output.action = (behavior_byte & 3) + 1; output.timer = 0; break;
        case 1: output.move_yaw = 0; if (timer > 60) { output.action = 2; output.timer = 0; } break;
        case 2: output.move_yaw = 0x4000; if (timer > 60) { output.action = 3; output.timer = 0; } break;
        case 3: output.move_yaw = 0x8000; if (timer > 60) { output.action = 4; output.timer = 0; } break;
        case 4: output.move_yaw = (int32_t)0xC000; if (timer > 60) { output.action = 1; output.timer = 0; } break;
        default: break;
    }
    // The contract samples use cardinal headings, matching the canonical N64 table.
    float sx = 0.0f, cz = 1.0f;
    switch ((uint16_t)output.move_yaw) {
        case 0x4000: sx = 1.0f; cz = 0.0f; break;
        case 0x8000: sx = 0.0f; cz = -1.0f; break;
        case 0xC000: sx = -1.0f; cz = 0.0f; break;
        default: break;
    }
    output.x += output.forward_velocity * sx;
    output.y += output.velocity_y;
    output.z += output.forward_velocity * cz;
    if (output.action == action) output.timer = timer + 1;
    return output;
}

static uint64_t append(uint64_t hash, struct Output output) {
    hash = hash_u32(hash, (uint32_t)output.action);
    hash = hash_u32(hash, (uint32_t)output.timer);
    hash = hash_float(hash, output.x);
    hash = hash_float(hash, output.y);
    hash = hash_float(hash, output.z);
    hash = hash_u32(hash, (uint32_t)output.move_yaw);
    hash = hash_float(hash, output.forward_velocity);
    return hash_float(hash, output.velocity_y);
}

int main(void) {
    struct Output initial = update(0, 0, 2, 0, 100, 0, 0, 0, 0);
    struct Output turn = update(1, 60, 0, 0, 100, 0, 0, 0, 0);
    struct Output hold = update(2, 12, 0, 0, 100, 0, 0x4000, 1, -1);
    struct Output wrap = update(4, 61, 0, 0, 100, 0, 0, 0, 0);
    if (initial.action != 3 || initial.move_yaw != 0 || initial.z != 10 ||
        turn.action != 1 || turn.move_yaw != 0 || turn.timer != 61 ||
        hold.action != 2 || hold.move_yaw != 0x4000 || hold.x != 10 ||
        wrap.action != 1 || (uint32_t)wrap.move_yaw != UINT32_C(0xC000)) return 2;
    uint64_t fingerprint = OFFSET;
    fingerprint = append(fingerprint, initial);
    fingerprint = append(fingerprint, turn);
    fingerprint = append(fingerprint, hold);
    fingerprint = append(fingerprint, wrap);
    printf("squarishPathMovingFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern squarish path moving C contract passed");
    return 0;
}
