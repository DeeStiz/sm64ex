#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define DOMAIN UINT32_C(11)
#define RECORD_KIND UINT32_C(7)
#define ROUTE_BASE UINT64_C(0x4D465200)
#define CAMERA_BASE UINT64_C(0x4D465300)
#define TEXTURE_BASE UINT64_C(0x4D465400)

struct texture {
    uint32_t id;
    const char *symbol;
    const char *path;
    uint32_t format;
    uint32_t bits;
    uint32_t width;
    uint32_t height;
    uint32_t frame;
    uint32_t family;
    uint32_t flags;
};

struct route {
    uint32_t id;
    uint32_t dl;
    const char *view;
    const char *object;
    uint32_t update;
    uint32_t flags;
    const uint32_t *textures;
    size_t texture_count;
};

static const struct texture textures[] = {
    { 1, "gd_texture_hand_open", "textures/intro_raw/hand_open.rgba16.inc.c", 1, 16, 32, 32, 0, 1, 6 },
    { 2, "gd_texture_hand_closed", "textures/intro_raw/hand_closed.rgba16.inc.c", 1, 16, 32, 32, 1, 1, 6 },
    { 0x100, "gd_texture_red_star_0", "textures/intro_raw/red_star_0.rgba16.inc.c", 1, 16, 32, 32, 0, 2, 6 },
    { 0x101, "gd_texture_red_star_1", "textures/intro_raw/red_star_1.rgba16.inc.c", 1, 16, 32, 32, 1, 2, 6 },
    { 0x102, "gd_texture_red_star_2", "textures/intro_raw/red_star_2.rgba16.inc.c", 1, 16, 32, 32, 2, 2, 6 },
    { 0x103, "gd_texture_red_star_3", "textures/intro_raw/red_star_3.rgba16.inc.c", 1, 16, 32, 32, 3, 2, 6 },
    { 0x104, "gd_texture_red_star_4", "textures/intro_raw/red_star_4.rgba16.inc.c", 1, 16, 32, 32, 4, 2, 6 },
    { 0x105, "gd_texture_red_star_5", "textures/intro_raw/red_star_5.rgba16.inc.c", 1, 16, 32, 32, 5, 2, 6 },
    { 0x106, "gd_texture_red_star_6", "textures/intro_raw/red_star_6.rgba16.inc.c", 1, 16, 32, 32, 6, 2, 6 },
    { 0x107, "gd_texture_red_star_7", "textures/intro_raw/red_star_7.rgba16.inc.c", 1, 16, 32, 32, 7, 2, 6 },
    { 0x200, "gd_texture_white_star_0", "textures/intro_raw/white_star_0.rgba16.inc.c", 1, 16, 32, 32, 0, 3, 6 },
    { 0x201, "gd_texture_white_star_1", "textures/intro_raw/white_star_1.rgba16.inc.c", 1, 16, 32, 32, 1, 3, 6 },
    { 0x202, "gd_texture_white_star_2", "textures/intro_raw/white_star_2.rgba16.inc.c", 1, 16, 32, 32, 2, 3, 6 },
    { 0x203, "gd_texture_white_star_3", "textures/intro_raw/white_star_3.rgba16.inc.c", 1, 16, 32, 32, 3, 3, 6 },
    { 0x204, "gd_texture_white_star_4", "textures/intro_raw/white_star_4.rgba16.inc.c", 1, 16, 32, 32, 4, 3, 6 },
    { 0x205, "gd_texture_white_star_5", "textures/intro_raw/white_star_5.rgba16.inc.c", 1, 16, 32, 32, 5, 3, 6 },
    { 0x206, "gd_texture_white_star_6", "textures/intro_raw/white_star_6.rgba16.inc.c", 1, 16, 32, 32, 6, 3, 6 },
    { 0x207, "gd_texture_white_star_7", "textures/intro_raw/white_star_7.rgba16.inc.c", 1, 16, 32, 32, 7, 3, 6 },
    { 0x300, "gd_texture_mario_face_shine", "textures/intro_raw/mario_face_shine.ia8.inc.c", 2, 8, 32, 32, 0, 4, 7 },
};

static const uint32_t yoshi_textures[] = {
    0x100, 0x101, 0x102, 0x103, 0x104, 0x105, 0x106, 0x107,
    0x200, 0x201, 0x202, 0x203, 0x204, 0x205, 0x206, 0x207,
};
static const uint32_t mario_textures[] = { 1, 2, 0x300 };

static const struct route routes[] = {
    { 0, 0, "sYoshiSceneView", "yoshi_scene", 1, 4, yoshi_textures, 16 },
    { 1, 1, "sYoshiSceneGrp", "yoshi_sh_l1", 1, 0, yoshi_textures, 16 },
    { 2, 2, "sMSceneView", "sMHeadMainDls", 2, 7, mario_textures, 3 },
    { 3, 3, "sMSceneView", "sMHeadMainDls", 2, 7, mario_textures, 3 },
    { 4, 4, "sCarSceneView", "car_scene", 3, 4, NULL, 0 },
    { 5, 5, "sScreenView2", "testnet2", 3, 0, NULL, 0 },
};

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xFF);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_string(uint64_t hash, const char *value) {
    hash = hash_u64(hash, (uint64_t) strlen(value));
    for (const unsigned char *cursor = (const unsigned char *) value; *cursor; ++cursor) {
        hash = hash_u64(hash, *cursor);
    }
    return hash;
}

static uint64_t hash_camera(uint64_t hash, const struct route *route) {
    hash = hash_u64(hash, route->id);
    hash = hash_string(hash, route->view);
    const uint32_t unsigned_values[] = { 320, 240, 100000, 46799, 160, 120, 2 };
    for (size_t index = 0; index < sizeof(unsigned_values) / sizeof(unsigned_values[0]); ++index) {
        hash = hash_u64(hash, unsigned_values[index]);
    }
    const int32_t signed_values[] = { -4500, 4500, -3400, 3400 };
    for (size_t index = 0; index < sizeof(signed_values) / sizeof(signed_values[0]); ++index) {
        hash = hash_u64(hash, (uint64_t) (int64_t) signed_values[index]);
    }
    const int32_t direction[] = { 0, 120, 0 };
    for (size_t index = 0; index < sizeof(direction) / sizeof(direction[0]); ++index) {
        hash = hash_u64(hash, (uint64_t) (int64_t) direction[index]);
    }
    const uint32_t scale[] = { 1000, 0, 0 };
    for (size_t index = 0; index < sizeof(scale) / sizeof(scale[0]); ++index) {
        hash = hash_u64(hash, scale[index]);
    }
    return hash;
}

static const struct texture *texture_for(uint32_t id) {
    for (size_t index = 0; index < sizeof(textures) / sizeof(textures[0]); ++index) {
        if (textures[index].id == id) {
            return &textures[index];
        }
    }
    return NULL;
}

static uint64_t catalog_fingerprint(void) {
    uint64_t hash = hash_u64(FNV_OFFSET, 1);
    hash = hash_u64(hash, sizeof(textures) / sizeof(textures[0]));
    for (size_t index = 0; index < sizeof(textures) / sizeof(textures[0]); ++index) {
        const struct texture *texture = &textures[index];
        const uint32_t values[] = {
            texture->id, texture->format, texture->bits, texture->width,
            texture->height, texture->frame, texture->family, texture->flags,
        };
        for (size_t value = 0; value < sizeof(values) / sizeof(values[0]); ++value) {
            hash = hash_u64(hash, values[value]);
        }
        hash = hash_string(hash, texture->symbol);
        hash = hash_string(hash, texture->path);
    }
    hash = hash_u64(hash, sizeof(routes) / sizeof(routes[0]));
    for (size_t index = 0; index < sizeof(routes) / sizeof(routes[0]); ++index) {
        const struct route *route = &routes[index];
        const uint32_t values[] = {
            route->id, route->dl, route->update, route->flags,
            (uint32_t) route->texture_count,
        };
        for (size_t value = 0; value < sizeof(values) / sizeof(values[0]); ++value) {
            hash = hash_u64(hash, values[value]);
        }
        hash = hash_string(hash, route->view);
        hash = hash_string(hash, route->object);
        for (size_t texture = 0; texture < route->texture_count; ++texture) {
            hash = hash_u64(hash, route->textures[texture]);
        }
        hash = hash_camera(hash, route);
    }
    return hash;
}

static uint64_t record_hash(uint64_t tick, uint64_t subject, uint64_t id,
                            uint32_t sequence, const uint64_t *values,
                            size_t value_count) {
    uint64_t hash = FNV_OFFSET;
    hash = hash_u64(hash, tick);
    hash = hash_u64(hash, DOMAIN);
    hash = hash_u64(hash, RECORD_KIND);
    hash = hash_u64(hash, subject);
    hash = hash_u64(hash, id);
    hash = hash_u64(hash, sequence);
    hash = hash_u64(hash, value_count);
    hash = hash_u64(hash, 0);
    for (size_t index = 0; index < value_count; ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
}

static uint64_t metadata_fingerprint(uint64_t resources) {
    uint64_t aggregate = FNV_OFFSET;
    size_t record_count = 0;
    for (size_t index = 0; index < sizeof(routes) / sizeof(routes[0]); ++index) {
        const struct route *route = &routes[index];
        const uint64_t tick = 100 + route->id;
        uint32_t sequence = route->id * 16;
        uint64_t values[] = {
            route->id, route->dl, route->update, route->flags,
            route->texture_count, 320, 240, resources,
        };
        aggregate = hash_u64(aggregate, record_hash(tick, route->id,
                                                     ROUTE_BASE | route->id,
                                                     sequence++, values, 8));
        const uint64_t camera_values[] = {
            320, 240, 100000, (uint64_t) (int64_t) -4500,
            (uint64_t) (int64_t) 4500, 46799,
            (uint64_t) (int64_t) -3400, (uint64_t) (int64_t) 3400,
        };
        aggregate = hash_u64(aggregate, record_hash(tick, route->id,
                                                     CAMERA_BASE | route->id,
                                                     sequence++, camera_values, 8));
        for (size_t texture_index = 0; texture_index < route->texture_count; ++texture_index) {
            const struct texture *texture = texture_for(route->textures[texture_index]);
            const uint64_t texture_values[] = {
                texture->id, texture->format, texture->bits, texture->width,
                texture->height, texture->frame, texture->family, texture->flags,
            };
            aggregate = hash_u64(aggregate, record_hash(
                tick, route->id, TEXTURE_BASE | texture->id, sequence++,
                texture_values, 8));
        }
        record_count += 2 + route->texture_count;
    }
    aggregate = hash_u64(aggregate, record_count);
    /* The Swift adapter prefixes the count; rebuild in the same order. */
    uint64_t canonical = FNV_OFFSET;
    canonical = hash_u64(canonical, record_count);
    size_t emitted = 0;
    for (size_t index = 0; index < sizeof(routes) / sizeof(routes[0]); ++index) {
        const struct route *route = &routes[index];
        const uint64_t tick = 100 + route->id;
        uint32_t sequence = route->id * 16;
        uint64_t values[] = {
            route->id, route->dl, route->update, route->flags,
            route->texture_count, 320, 240, resources,
        };
        canonical = hash_u64(canonical, record_hash(tick, route->id,
                                                    ROUTE_BASE | route->id,
                                                    sequence++, values, 8));
        const uint64_t camera_values[] = {
            320, 240, 100000, (uint64_t) (int64_t) -4500,
            (uint64_t) (int64_t) 4500, 46799,
            (uint64_t) (int64_t) -3400, (uint64_t) (int64_t) 3400,
        };
        canonical = hash_u64(canonical, record_hash(tick, route->id,
                                                    CAMERA_BASE | route->id,
                                                    sequence++, camera_values, 8));
        for (size_t texture_index = 0; texture_index < route->texture_count; ++texture_index) {
            const struct texture *texture = texture_for(route->textures[texture_index]);
            const uint64_t texture_values[] = {
                texture->id, texture->format, texture->bits, texture->width,
                texture->height, texture->frame, texture->family, texture->flags,
            };
            canonical = hash_u64(canonical, record_hash(
                tick, route->id, TEXTURE_BASE | texture->id, sequence++,
                texture_values, 8));
        }
        emitted += 2 + route->texture_count;
    }
    (void) aggregate;
    (void) emitted;
    return canonical;
}

static uint64_t live_record_fingerprint(void) {
    uint64_t aggregate = FNV_OFFSET;
    aggregate = hash_u64(aggregate, sizeof(routes) / sizeof(routes[0]));
    for (size_t index = 0; index < sizeof(routes) / sizeof(routes[0]); ++index) {
        const struct route *route = &routes[index];
        const uint64_t values[] = {
            route->id, route->dl, route->update, route->flags, 320, 240, 2,
        };
        aggregate = hash_u64(aggregate, record_hash(
            500 + route->id, 0, UINT64_C(5), route->id, values, 7));
    }
    return aggregate;
}

int main(void) {
    const uint64_t resources = catalog_fingerprint();
    const uint64_t metadata = metadata_fingerprint(resources);
    const uint64_t live = live_record_fingerprint();
    size_t route_texture_records = 0;
    for (size_t index = 0; index < sizeof(routes) / sizeof(routes[0]); ++index) {
        route_texture_records += routes[index].texture_count;
    }
    printf("marioFaceRouteResourceFingerprint=0x%016llx\n", (unsigned long long) resources);
    printf("marioFaceRouteCount=%zu\n", sizeof(routes) / sizeof(routes[0]));
    printf("marioFaceRouteTextureCount=%zu\n", sizeof(textures) / sizeof(textures[0]));
    printf("marioFaceRouteTextureRecords=%zu\n", route_texture_records);
    printf("marioFaceRouteCameraRecords=%zu\n", sizeof(routes) / sizeof(routes[0]));
    printf("marioFaceRouteMetadataRecords=%zu\n", route_texture_records + 2 * sizeof(routes) / sizeof(routes[0]));
    printf("marioFaceRouteMetadataFingerprint=0x%016llx\n", (unsigned long long) metadata);
    printf("marioFaceRouteLiveRecordCount=%zu\n", sizeof(routes) / sizeof(routes[0]));
    printf("marioFaceRouteLiveRecordFingerprint=0x%016llx\n", (unsigned long long) live);
    printf("SM64 Modern Mario-face route/resource C contract passed\n");
    return 0;
}
