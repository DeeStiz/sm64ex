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

struct Input { int32_t rectangular, action, oscillation_timer, face_pitch; float position_y; };
struct Output { int32_t action, oscillation_timer, face_pitch; float position_y; };

static float sine(int32_t angle) { return (angle & 0xffff) == 0x4000 ? 1.0f : 0.0f; }

static struct Output update(struct Input input) {
    struct Output result = { input.action, input.oscillation_timer, input.face_pitch, input.position_y };
    if (input.rectangular) {
        switch (input.action) {
            case 0: result.action = 1; break;
            case 1:
                result.position_y -= sine(result.oscillation_timer) * 0.4f;
                result.oscillation_timer += 0x100;
                break;
            default: break;
        }
    } else {
        result.face_pitch = (int32_t)(sine(result.oscillation_timer) * 512.0f);
        result.oscillation_timer += 0x100;
    }
    return result;
}

static uint64_t append(uint64_t hash, struct Output value) {
    hash = hash_u32(hash, (uint32_t)value.action);
    hash = hash_u32(hash, (uint32_t)value.oscillation_timer);
    hash = hash_f32(hash, value.position_y);
    return hash_u32(hash, (uint32_t)value.face_pitch);
}

int main(void) {
    struct Output rectangular_init = update((struct Input){1, 0, 0, 0, 100});
    struct Output rectangular_move = update((struct Input){1, 1, 0x4000, 0, 100});
    struct Output square_move = update((struct Input){0, 0, 0x4000, 100, 100});
    struct Output held = update((struct Input){1, 2, 0x5000, 12, 90});
    if (rectangular_init.action != 1 || rectangular_move.oscillation_timer != 0x4100 ||
        rectangular_move.position_y != 99.6f || square_move.face_pitch != 512 ||
        square_move.oscillation_timer != 0x4100 || held.position_y != 90) return 2;
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = append(fingerprint, rectangular_init);
    fingerprint = append(fingerprint, rectangular_move);
    fingerprint = append(fingerprint, square_move);
    fingerprint = append(fingerprint, held);
    printf("lllSinkingPlatformFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern LLL sinking platform C contract passed");
    return 0;
}
