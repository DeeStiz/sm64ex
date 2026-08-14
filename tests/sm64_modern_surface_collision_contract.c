#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define MISS_HEIGHT (-11000.0f)
#define CAMERA_BOUNDARY INT16_C(0x72)
#define NO_CAMERA_COLLISION INT8_C(2)

typedef struct {
    uint32_t id;
    int16_t type;
    int8_t flags;
    int16_t v[3][3];
    float normal[3];
    float origin;
} Surface;

typedef struct {
    float height;
    int present;
    uint32_t id;
    int16_t type;
    int8_t flags;
    float normal_y;
} Result;

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static int contains(const Surface *surface, int32_t x, int32_t z) {
    int32_t x1 = surface->v[0][0], z1 = surface->v[0][2];
    int32_t x2 = surface->v[1][0], z2 = surface->v[1][2];
    int32_t x3 = surface->v[2][0], z3 = surface->v[2][2];
    if ((z1 - z) * (x2 - x1) - (x1 - x) * (z2 - z1) < 0) return 0;
    if ((z2 - z) * (x3 - x2) - (x2 - x) * (z3 - z2) < 0) return 0;
    if ((z3 - z) * (x1 - x3) - (x3 - x) * (z1 - z3) < 0) return 0;
    return 1;
}

static int accepts(const Surface *surface, int checking_camera) {
    if (checking_camera) return (surface->flags & NO_CAMERA_COLLISION) == 0;
    return surface->type != CAMERA_BOUNDARY;
}

static Result floor_query(const Surface *surfaces, unsigned count, float x, float y, float z, int checking_camera) {
    Result miss = { MISS_HEIGHT, 0, 0, 0, 0, 0 };
    int32_t ix = (int32_t) x, iy = (int32_t) y, iz = (int32_t) z;
    for (unsigned index = 0; index < count; ++index) {
        const Surface *surface = &surfaces[index];
        if (!contains(surface, ix, iz) || !accepts(surface, checking_camera) || surface->normal[1] == 0) continue;
        float height = -((float) ix * surface->normal[0] + (float) iz * surface->normal[2] + surface->origin) / surface->normal[1];
        if ((float) iy - (height - 78.0f) < 0) continue;
        Result result = { height, 1, surface->id, surface->type, surface->flags, surface->normal[1] };
        return result;
    }
    return miss;
}

static Result ceil_query(const Surface *surfaces, unsigned count, float x, float y, float z, int checking_camera) {
    Result miss = { MISS_HEIGHT, 0, 0, 0, 0, 0 };
    int32_t ix = (int32_t) x, iy = (int32_t) y, iz = (int32_t) z;
    for (unsigned index = 0; index < count; ++index) {
        const Surface *surface = &surfaces[index];
        if (!contains(surface, ix, iz) || !accepts(surface, checking_camera) || surface->normal[1] == 0) continue;
        float height = -((float) ix * surface->normal[0] + (float) iz * surface->normal[2] + surface->origin) / surface->normal[1];
        if ((float) iy - (height + 78.0f) > 0) continue;
        Result result = { height, 1, surface->id, surface->type, surface->flags, surface->normal[1] };
        return result;
    }
    return miss;
}

static uint64_t hash_result(uint64_t hash, Result result) {
    uint32_t bits;
    memcpy(&bits, &result.height, sizeof(bits));
    hash = hash_u64(hash, bits);
    hash = hash_u64(hash, result.present ? result.id : UINT64_MAX);
    hash = hash_u64(hash, result.present ? (uint64_t) (int64_t) result.type : UINT64_MAX);
    hash = hash_u64(hash, result.present ? (uint64_t) (int64_t) result.flags : UINT64_MAX);
    memcpy(&bits, &result.normal_y, sizeof(bits));
    hash = hash_u64(hash, result.present ? bits : UINT64_MAX);
    return hash;
}

int main(void) {
    Surface floor = { 1, 0, 0, {{-100, 0, -100}, {-100, 0, 100}, {100, 0, -100}}, {0, 1, 0}, 0 };
    Surface dynamic_floor = { 2, 0, 0, {{-100, 50, -100}, {-100, 50, 100}, {100, 50, -100}}, {0, 1, 0}, -50 };
    Surface ceil = { 3, 0, 0, {{-100, 200, -100}, {-100, 200, 100}, {100, 200, -100}}, {0, -1, 0}, 200 };
    Surface camera_boundary = { 4, CAMERA_BOUNDARY, 0, {{-100, 10, -100}, {-100, 10, 100}, {100, 10, -100}}, {0, 1, 0}, -10 };
    Surface no_camera = { 5, 0, NO_CAMERA_COLLISION, {{-100, 20, -100}, {-100, 20, 100}, {100, 20, -100}}, {0, 1, 0}, -20 };
    Surface statics[] = { floor, ceil, camera_boundary, no_camera };
    Surface dynamics[] = { dynamic_floor };
    Result floor_hit = floor_query(dynamics, 1, 0, 100, 0, 0);
    Result static_hit = floor_query(statics, 4, 0, 100, 0, 0);
    Result selected = floor_hit.present && floor_hit.height > static_hit.height ? floor_hit : static_hit;
    Result miss = floor_query(dynamics, 1, 0, -100, 0, 0);
    Result ceiling_hit = ceil_query(statics, 4, 0, 100, 0, 0);
    Result camera_hit = floor_query(statics, 4, 0, 100, 0, 1);
    float water = 80.0f;
    float water_miss = MISS_HEIGHT;
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_result(fingerprint, selected);
    fingerprint = hash_result(fingerprint, miss);
    fingerprint = hash_result(fingerprint, ceiling_hit);
    uint32_t bits;
    memcpy(&bits, &water, sizeof(bits)); fingerprint = hash_u64(fingerprint, bits);
    memcpy(&bits, &water_miss, sizeof(bits)); fingerprint = hash_u64(fingerprint, bits);
    fingerprint = hash_result(fingerprint, camera_hit);
    float wall_x = 20.0f, wall_z = 0.0f;
    memcpy(&bits, &wall_x, sizeof(bits)); fingerprint = hash_u64(fingerprint, bits);
    memcpy(&bits, &wall_z, sizeof(bits)); fingerprint = hash_u64(fingerprint, bits);
    fingerprint = hash_u64(fingerprint, 1);
    fingerprint = hash_u64(fingerprint, 10);
    fingerprint = hash_u64(fingerprint, 2);
    float hit_x = 0.0f, hit_y = 50.0f, hit_z = 0.0f, hit_distance = 50.0f;
    memcpy(&bits, &hit_x, sizeof(bits)); fingerprint = hash_u64(fingerprint, bits);
    memcpy(&bits, &hit_y, sizeof(bits)); fingerprint = hash_u64(fingerprint, bits);
    memcpy(&bits, &hit_z, sizeof(bits)); fingerprint = hash_u64(fingerprint, bits);
    memcpy(&bits, &hit_distance, sizeof(bits)); fingerprint = hash_u64(fingerprint, bits);
    printf("surfaceCollisionFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    return 0;
}
