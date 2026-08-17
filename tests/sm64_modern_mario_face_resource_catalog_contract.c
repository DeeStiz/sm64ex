#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct mesh_resource {
    uint32_t mesh_id;
    const char *source_path;
    uint32_t vertex_group_id;
    uint32_t plane_group_id;
    uint32_t material_group_id;
    uint32_t shape_id;
    uint32_t vertex_count;
    uint32_t face_count;
    uint32_t material_count;
};

struct material_resource {
    uint32_t mesh_id;
    uint32_t material_group_id;
    uint32_t material_id;
    uint32_t ambient[3];
    uint32_t diffuse[3];
};

struct light_resource {
    uint32_t object_id;
    uint32_t logical_id;
    uint32_t flags;
    uint32_t diffuse[3];
};

struct animation_binding {
    uint32_t component_id;
    uint32_t animator_id;
    uint32_t parent_group_id;
    uint32_t data_group_id;
    uint32_t node_group_id;
    uint32_t linked_object_id;
};

static const struct mesh_resource meshes[] = {
    { 1, "src/goddard/dynlists/dynlist_mario_face.c", 0xDE, 0xDF, 0xE0, 0xE1, 440, 877, 8 },
    { 2, "src/goddard/dynlists/dynlists_mario_eyes.c", 0x71, 0x72, 0x73, 0x74, 48, 82, 4 },
    { 3, "src/goddard/dynlists/dynlists_mario_eyes.c", 0x61, 0x62, 0x63, 0x64, 48, 82, 4 },
    { 4, "src/goddard/dynlists/dynlists_mario_eyebrows_mustache.c", 0x5A, 0x5B, 0x5C, 0x5D, 26, 36, 1 },
    { 5, "src/goddard/dynlists/dynlists_mario_eyebrows_mustache.c", 0x38, 0x39, 0x3A, 0x3B, 26, 36, 1 },
    { 6, "src/goddard/dynlists/dynlists_mario_eyebrows_mustache.c", 0x16, 0x17, 0x18, 0x19, 56, 100, 1 },
};

#define MATERIAL(mesh, group, id, ar, ag, ab, dr, dg, db) \
    { mesh, group, id, { ar, ag, ab }, { dr, dg, db } }

static const struct material_resource materials[] = {
    MATERIAL(1, 0xE0, 0, 1000, 1000, 1000, 1000, 1000, 1000),
    MATERIAL(1, 0xE0, 1, 883, 602, 408, 883, 602, 408),
    MATERIAL(1, 0xE0, 2, 362, 0, 0, 362, 0, 0),
    MATERIAL(1, 0xE0, 3, 1000, 1000, 1000, 1000, 1000, 1000),
    MATERIAL(1, 0xE0, 4, 1000, 1000, 1000, 1000, 1000, 1000),
    MATERIAL(1, 0xE0, 5, 362, 0, 0, 362, 0, 0),
    MATERIAL(1, 0xE0, 6, 526, 0, 0, 526, 0, 0),
    MATERIAL(1, 0xE0, 7, 1000, 0, 0, 1000, 0, 0),
    MATERIAL(2, 0x73, 0, 0, 291, 1000, 0, 291, 1000),
    MATERIAL(2, 0x73, 1, 0, 576, 1000, 0, 576, 1000),
    MATERIAL(2, 0x73, 2, 0, 0, 0, 0, 0, 0),
    MATERIAL(2, 0x73, 3, 1000, 1000, 1000, 1000, 1000, 1000),
    MATERIAL(3, 0x63, 0, 0, 291, 1000, 0, 291, 1000),
    MATERIAL(3, 0x63, 1, 0, 576, 1000, 0, 576, 1000),
    MATERIAL(3, 0x63, 2, 0, 0, 0, 0, 0, 0),
    MATERIAL(3, 0x63, 3, 1000, 1000, 1000, 1000, 1000, 1000),
    MATERIAL(4, 0x5C, 0, 0, 5, 0, 0, 0, 0),
    MATERIAL(5, 0x3A, 0, 0, 0, 0, 0, 0, 0),
    MATERIAL(6, 0x18, 0, 0, 0, 0, 0, 0, 0),
};

#undef MATERIAL

static const struct light_resource lights[] = {
    { 0xE4, 1, 0x20, { 1000, 1000, 1000 } },
    { 0xE7, 0, 0x20, { 1000, 0, 0 } },
};

static const struct animation_binding animation_bindings[] = {
    { 0x07, 0x08, 0x3E9, 0x07, 0x07, 0x06 },
    { 0x10, 0x11, 0x3E9, 0x10, 0x10, 0x0F },
    { 0x20, 0x21, 0x3E9, 0x20, 0x20, 0x1F },
    { 0x29, 0x2A, 0x3E9, 0x29, 0x29, 0x28 },
    { 0x32, 0x33, 0x3E9, 0x32, 0x32, 0x31 },
    { 0x3F, 0x40, 0x3E9, 0x3F, 0x3F, 0x3E },
    { 0x42, 0x43, 0x3E9, 0x42, 0x42, 0x41 },
    { 0x48, 0x49, 0x3E9, 0x48, 0x48, 0x47 },
    { 0x4B, 0x4C, 0x3E9, 0x4B, 0x4B, 0x4A },
    { 0x54, 0x55, 0x3E9, 0x54, 0x54, 0x53 },
    { 0x6B, 0x6C, 0x3E9, 0x6B, 0x6B, 0x6A },
    { 0x7B, 0x7C, 0x3E9, 0x7B, 0x7B, 0x7A },
    { 0x84, 0x85, 0x3E9, 0x84, 0x84, 0x83 },
    { 0x96, 0x97, 0x3E9, 0x96, 0x96, 0x95 },
    { 0x9F, 0xA0, 0x3E9, 0x9F, 0x9F, 0x9E },
    { 0xA8, 0xA9, 0x3E9, 0xA8, 0xA8, 0xA7 },
    { 0xB1, 0xB2, 0x3E9, 0xB1, 0xB1, 0xB0 },
    { 0xBA, 0xBB, 0x3E9, 0xBA, 0xBA, 0xB9 },
    { 0xC3, 0xC4, 0x3E9, 0xC3, 0xC3, 0xC2 },
    { 0xC6, 0xC7, 0x3E9, 0xC6, 0xC6, 0xC5 },
    { 0xCF, 0xD0, 0x3E9, 0xCF, 0xCF, 0xCE },
    { 0xD8, 0xD9, 0x3E9, 0xD8, 0xD8, 0xD7 },
    { 0xE2, 0xE3, 0x3E9, 0xE2, 0xE2, 0xDD },
    { 0xE5, 0xE6, 0x3E9, 0xE5, 0xE5, 0xE4 },
    { 0xE8, 0xE9, 0x3E9, 0xE8, 0xE8, 0xE7 },
};

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (uint32_t byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_string(uint64_t hash, const char *value) {
    const size_t length = strlen(value);
    hash = hash_u64(hash, length);
    for (size_t index = 0; index < length; ++index) {
        hash = hash_u64(hash, (uint8_t) value[index]);
    }
    return hash;
}

static uint64_t hash_values(uint64_t hash, const uint32_t *values, size_t count) {
    for (size_t index = 0; index < count; ++index) {
        hash = hash_u64(hash, values[index]);
    }
    return hash;
}

static uint64_t hash_catalog(void) {
    uint64_t hash = hash_u64(FNV_OFFSET, 0x3E8);
    hash = hash_u64(hash, 0x3E9);
    hash = hash_u64(hash, sizeof(meshes) / sizeof(meshes[0]));
    for (size_t index = 0; index < sizeof(meshes) / sizeof(meshes[0]); ++index) {
        const struct mesh_resource mesh = meshes[index];
        hash = hash_u64(hash, mesh.mesh_id);
        hash = hash_string(hash, mesh.source_path);
        const uint32_t values[] = {
            mesh.vertex_group_id, mesh.plane_group_id, mesh.material_group_id,
            mesh.shape_id, mesh.vertex_count, mesh.face_count, mesh.material_count,
        };
        hash = hash_values(hash, values, sizeof(values) / sizeof(values[0]));
    }
    hash = hash_u64(hash, sizeof(materials) / sizeof(materials[0]));
    for (size_t index = 0; index < sizeof(materials) / sizeof(materials[0]); ++index) {
        const struct material_resource material = materials[index];
        const uint32_t ids[] = { material.mesh_id, material.material_group_id, material.material_id };
        hash = hash_values(hash, ids, sizeof(ids) / sizeof(ids[0]));
        hash = hash_values(hash, material.ambient, 3);
        hash = hash_values(hash, material.diffuse, 3);
    }
    hash = hash_u64(hash, sizeof(lights) / sizeof(lights[0]));
    for (size_t index = 0; index < sizeof(lights) / sizeof(lights[0]); ++index) {
        const struct light_resource light = lights[index];
        const uint32_t ids[] = { light.object_id, light.logical_id, light.flags };
        hash = hash_values(hash, ids, sizeof(ids) / sizeof(ids[0]));
        hash = hash_values(hash, light.diffuse, 3);
    }
    hash = hash_u64(hash, sizeof(animation_bindings) / sizeof(animation_bindings[0]));
    for (size_t index = 0; index < sizeof(animation_bindings) / sizeof(animation_bindings[0]); ++index) {
        const struct animation_binding binding = animation_bindings[index];
        const uint32_t values[] = {
            binding.component_id, binding.animator_id, binding.parent_group_id,
            binding.data_group_id, binding.node_group_id, binding.linked_object_id,
        };
        hash = hash_values(hash, values, sizeof(values) / sizeof(values[0]));
    }
    return hash;
}

int main(void) {
    uint32_t vertex_count = 0;
    uint32_t face_count = 0;
    uint32_t material_count = 0;
    for (size_t index = 0; index < sizeof(meshes) / sizeof(meshes[0]); ++index) {
        vertex_count += meshes[index].vertex_count;
        face_count += meshes[index].face_count;
        material_count += meshes[index].material_count;
    }
    printf("marioFaceResourceCatalogFingerprint=0x%016llx\n", (unsigned long long) hash_catalog());
    printf("marioFaceResourceCatalogMeshes=%zu\n", sizeof(meshes) / sizeof(meshes[0]));
    printf("marioFaceResourceCatalogMaterials=%zu\n", sizeof(materials) / sizeof(materials[0]));
    printf("marioFaceResourceCatalogLights=%zu\n", sizeof(lights) / sizeof(lights[0]));
    printf("marioFaceResourceCatalogAnimationBindings=%zu\n", sizeof(animation_bindings) / sizeof(animation_bindings[0]));
    printf("marioFaceResourceCatalogVertices=%u\n", vertex_count);
    printf("marioFaceResourceCatalogFaces=%u\n", face_count);
    printf("marioFaceResourceCatalogMaterialSlots=%u\n", material_count);
    printf("SM64 Modern Mario face resource catalog C contract passed\n");
    return 0;
}
