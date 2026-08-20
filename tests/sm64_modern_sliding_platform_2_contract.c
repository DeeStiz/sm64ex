#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct init { float distance, speed, vertical_sign; int32_t move_yaw; };
struct output { float x, y, z, offset, speed; int32_t timer; };

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}
static uint64_t hash_f32(uint64_t hash, float value) {
    uint32_t bits = 0; memcpy(&bits, &value, sizeof(bits));
    return hash_u64(hash, bits);
}
static struct init initialize(uint32_t params, int32_t yaw) {
    uint16_t packed = (uint16_t)(params >> 16);
    int variant = (packed & 0x0380) >> 7;
    struct init output = { (float)(packed & 0x3f) * 50.0f, 15.0f, 0, yaw };
    if (variant < 5 || variant > 6) {
        if (packed & 0x40) output.move_yaw += 0x8000;
    } else {
        output.speed = 10;
        output.vertical_sign = packed & 0x40 ? -1 : 1;
    }
    return output;
}
static struct output update(int32_t timer, float home_x, float home_y, float home_z,
                            int32_t yaw, float offset, float speed, float distance,
                            float vertical_sign) {
    struct output output = { home_x, home_y, home_z, offset, speed, timer };
    if (timer > 10) {
        output.offset += output.speed;
        if (output.offset < -distance) { output.offset = -distance; output.speed = -output.speed; output.timer = 0; }
        else if (output.offset > 0) { output.offset = 0; output.speed = -output.speed; output.timer = 0; }
    }
    output.timer += 1;
    if (vertical_sign != 0) output.y = home_y + output.offset * vertical_sign;
    else output.x = home_x + output.offset * 1.0f;
    (void)yaw; (void)home_z;
    return output;
}
int main(void) {
    const struct init horizontal = initialize(UINT32_C(0x00100000), 0);
    const struct init reversed = initialize(UINT32_C(0x00CF0000), 0);
    const struct init vertical = initialize(UINT32_C(0x02C50000), 0);
    const struct output outputs[] = {
        update(0, 10, 20, 30, 0, 0, 15, 800, 0),
        update(11, 10, 20, 30, 0, 0, 15, 10, 0),
        update(0, 10, 20, 30, 0, -50, 10, 250, -1),
    };
    if (horizontal.distance != 800 || horizontal.speed != 15 || reversed.distance != 750 ||
        reversed.move_yaw != 0x8000 || vertical.distance != 250 || vertical.speed != 10 ||
        vertical.vertical_sign != -1 || outputs[0].x != 10 || outputs[0].y != 20 ||
        outputs[0].z != 30 || outputs[0].timer != 1 || outputs[1].offset != 0 ||
        outputs[1].speed != -15 || outputs[1].timer != 1 || outputs[2].y != 70 ||
        outputs[2].timer != 1) return 1;
    uint64_t fingerprint = FNV_OFFSET;
    for (unsigned i = 0; i < 3; ++i) {
        fingerprint = hash_f32(fingerprint, outputs[i].x);
        fingerprint = hash_f32(fingerprint, outputs[i].y);
        fingerprint = hash_f32(fingerprint, outputs[i].z);
        fingerprint = hash_f32(fingerprint, outputs[i].offset);
        fingerprint = hash_f32(fingerprint, outputs[i].speed);
        fingerprint = hash_u64(fingerprint, (uint64_t)(int64_t)outputs[i].timer);
    }
    printf("slidingPlatform2Fingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern sliding platform 2 C contract passed");
    return 0;
}
