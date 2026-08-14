#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "PR/ultratypes.h"

#define AVOID_UB 1
#include "trig_tables.inc.c"

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT32_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static void rotate_zxy(float *dest, float x, float y, float z, int16_t pitch, int16_t yaw, int16_t roll) {
    float sx = gSineTable[(uint16_t) pitch >> 4];
    float cx = gSineTable[0x400 + ((uint16_t) pitch >> 4)];
    float sy = gSineTable[(uint16_t) yaw >> 4];
    float cy = gSineTable[0x400 + ((uint16_t) yaw >> 4)];
    float sz = gSineTable[(uint16_t) roll >> 4];
    float cz = gSineTable[0x400 + ((uint16_t) roll >> 4)];
    dest[0] = cy * cz + sx * sy * sz; dest[1] = cx * sz; dest[2] = -sy * cz + sx * cy * sz; dest[3] = 0;
    dest[4] = -cy * sz + sx * sy * cz; dest[5] = cx * cz; dest[6] = sy * sz + sx * cy * cz; dest[7] = 0;
    dest[8] = cx * sy; dest[9] = -sx; dest[10] = cx * cy; dest[11] = 0;
    dest[12] = x; dest[13] = y; dest[14] = z; dest[15] = 1;
}

static void scale(float *matrix, float x, float y, float z) {
    for (unsigned row = 0; row < 3; ++row) matrix[row] *= x;
    for (unsigned row = 0; row < 3; ++row) matrix[4 + row] *= y;
    for (unsigned row = 0; row < 3; ++row) matrix[8 + row] *= z;
}

static void multiply(float *dest, const float *a, const float *b) {
    float result[16] = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 };
    for (unsigned column = 0; column < 3; ++column) {
        for (unsigned row = 0; row < 3; ++row) {
            result[column * 4 + row] =
                a[column * 4 + 0] * b[0 * 4 + row]
                + a[column * 4 + 1] * b[1 * 4 + row]
                + a[column * 4 + 2] * b[2 * 4 + row];
        }
    }
    for (unsigned row = 0; row < 3; ++row) {
        result[12 + row] =
            a[12 + 0] * b[0 * 4 + row]
            + a[12 + 1] * b[1 * 4 + row]
            + a[12 + 2] * b[2 * 4 + row]
            + b[12 + row];
    }
    memcpy(dest, result, sizeof(result));
}

int main(void) {
    float root[16];
    float child[16];
    float world[16];
    rotate_zxy(root, 10.25f, -20.5f, 30.75f, 0x1234, 0x2A00, (int16_t) 0xD000);
    rotate_zxy(child, 5.5f, 6.25f, -7.75f, 0x4000, 0x1000, 0x2000);
    scale(child, 1.25f, 0.75f, 2.0f);
    multiply(world, child, root);

    uint64_t fingerprint = FNV_OFFSET;
    uint32_t bits;
    for (unsigned index = 0; index < 16; ++index) { memcpy(&bits, &root[index], sizeof(bits)); fingerprint = hash_u32(fingerprint, bits); }
    for (unsigned index = 0; index < 16; ++index) { memcpy(&bits, &world[index], sizeof(bits)); fingerprint = hash_u32(fingerprint, bits); }
    for (unsigned index = 0; index < 3; ++index) { memcpy(&bits, &world[12 + index], sizeof(bits)); fingerprint = hash_u32(fingerprint, bits); }
    float gfx[] = { world[12], world[13] + 11.5f, world[14] };
    for (unsigned index = 0; index < 3; ++index) { memcpy(&bits, &gfx[index], sizeof(bits)); fingerprint = hash_u32(fingerprint, bits); }
    printf("objectTransformFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    return 0;
}
