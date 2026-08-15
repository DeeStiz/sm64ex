#include <stdint.h>
#include <stdio.h>
#include <math.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT32_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_surface(uint64_t hash, uint32_t id, int16_t type, int16_t force,
                             int8_t flags, int8_t room, int16_t lower, int16_t upper,
                             const int16_t vertices[9], const float normal[3], float origin) {
    hash = hash_u32(hash, id);
    hash = hash_u32(hash, (uint16_t) type);
    hash = hash_u32(hash, (uint16_t) force);
    hash = hash_u32(hash, (uint8_t) flags);
    hash = hash_u32(hash, (uint8_t) room);
    hash = hash_u32(hash, (uint16_t) lower);
    hash = hash_u32(hash, (uint16_t) upper);
    for (unsigned index = 0; index < 9; ++index) hash = hash_u32(hash, (uint16_t) vertices[index]);
    for (unsigned index = 0; index < 3; ++index) {
        uint32_t bits;
        __builtin_memcpy(&bits, &normal[index], sizeof(bits));
        hash = hash_u32(hash, bits);
    }
    uint32_t bits;
    __builtin_memcpy(&bits, &origin, sizeof(bits));
    return hash_u32(hash, bits);
}

static void make_surface(uint32_t id, int16_t type, int16_t force,
                         int16_t vertices[9], int8_t *flags, int16_t *lower,
                         int16_t *upper, float normal[3], float *origin) {
    int32_t x1 = vertices[0], y1 = vertices[1], z1 = vertices[2];
    int32_t x2 = vertices[3], y2 = vertices[4], z2 = vertices[5];
    int32_t x3 = vertices[6], y3 = vertices[7], z3 = vertices[8];
    float nx = (float) ((y2 - y1) * (z3 - z2) - (z2 - z1) * (y3 - y2));
    float ny = (float) ((z2 - z1) * (x3 - x2) - (x2 - x1) * (z3 - z2));
    float nz = (float) ((x2 - x1) * (y3 - y2) - (y2 - y1) * (x3 - x2));
    float magnitude = sqrtf(nx * nx + ny * ny + nz * nz);
    normal[0] = nx / magnitude;
    normal[1] = ny / magnitude;
    normal[2] = nz / magnitude;
    *flags = 1;
    if (type >= 0x76 && type <= 0x7A) *flags |= 2;
    if (normal[1] <= 0.01f && normal[1] >= -0.01f
        && (normal[0] < -0.707f || normal[0] > 0.707f)) *flags |= 8;
    int16_t min_y = y1 < y2 ? (y1 < y3 ? y1 : y3) : (y2 < y3 ? y2 : y3);
    int16_t max_y = y1 > y2 ? (y1 > y3 ? y1 : y3) : (y2 > y3 ? y2 : y3);
    *lower = (int16_t) (min_y - 5);
    *upper = (int16_t) (max_y + 5);
    *origin = -(normal[0] * (float) x1 + normal[1] * (float) y1 + normal[2] * (float) z1);
    (void) id;
    (void) force;
}

int main(void) {
    int16_t first[9] = { 10, 20, 30, 10, 20, 130, 210, 20, 30 };
    int16_t second[9] = { 10, 20, 30, 10, 20, 130, 10, 120, 30 };
    int8_t flags;
    int16_t lower, upper;
    float normal[3], origin;
    uint64_t fingerprint = FNV_OFFSET;
    make_surface(0x100, 0, 0, first, &flags, &lower, &upper, normal, &origin);
    fingerprint = hash_surface(fingerprint, 0x100, 0, 0, flags, 0, lower, upper, first, normal, origin);
    make_surface(0x101, 0x2C, 7, second, &flags, &lower, &upper, normal, &origin);
    fingerprint = hash_surface(fingerprint, 0x101, 0x2C, 7, flags, 0, lower, upper, second, normal, origin);
    printf("collisionMeshFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    return 0;
}
