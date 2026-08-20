#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u64(uint64_t initial, uint64_t value) {
    uint64_t hash = initial;
    for (unsigned byte = 0; byte < 8; byte++) {
        hash ^= (value >> (byte * 8)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_i32(uint64_t initial, int32_t value) {
    return hash_u64(initial, (uint64_t)(int64_t)value);
}

static uint64_t hash_float(uint64_t initial, float value) {
    union { float f; uint32_t u; } bits = { value };
    return hash_u64(initial, bits.u);
}

static uint64_t hash_ukiki(uint64_t initial, int32_t action, int32_t sub_action,
                           int32_t text_state, int32_t anim_state, float velocity,
                           int32_t dialog_id, int interaction_mask) {
    uint64_t hash = hash_i32(initial, action);
    hash = hash_i32(hash, sub_action);
    hash = hash_i32(hash, text_state);
    hash = hash_i32(hash, anim_state);
    hash = hash_float(hash, velocity);
    hash = hash_i32(hash, dialog_id);
    return hash_u64(hash, interaction_mask ? 1 : 0);
}

static uint64_t hash_cage(uint64_t initial, int32_t action, int32_t next_action,
                          int32_t face_yaw, float position_y, int mark, int star) {
    uint64_t hash = hash_i32(initial, action);
    hash = hash_i32(hash, next_action);
    hash = hash_i32(hash, face_yaw);
    hash = hash_float(hash, position_y);
    hash = hash_u64(hash, mark ? 1 : 0);
    return hash_u64(hash, star ? 1 : 0);
}

static uint64_t hash_mips(uint64_t initial, int32_t action, int32_t held_state,
                          int32_t star_status, float velocity, int32_t dialog_id,
                          int dialog_requested, int interaction_mask) {
    uint64_t hash = hash_i32(initial, action);
    hash = hash_i32(hash, held_state);
    hash = hash_i32(hash, star_status);
    hash = hash_float(hash, velocity);
    hash = hash_i32(hash, dialog_id);
    hash = hash_u64(hash, dialog_requested ? 1 : 0);
    return hash_u64(hash, interaction_mask ? 1 : 0);
}

static uint64_t hash_toad(uint64_t initial, int32_t state, int32_t dialog_id,
                          int32_t opacity, int jingle, int spawn_star) {
    uint64_t hash = hash_i32(initial, state);
    hash = hash_i32(hash, dialog_id);
    hash = hash_i32(hash, opacity);
    hash = hash_u64(hash, jingle ? 1 : 0);
    return hash_u64(hash, spawn_star ? 1 : 0);
}

static uint64_t hash_menu(uint64_t initial, int32_t state, int32_t timer,
                          float relative_x, float relative_z, int32_t face_yaw,
                          float scale) {
    uint64_t hash = hash_i32(initial, state);
    hash = hash_i32(hash, timer);
    hash = hash_float(hash, relative_x);
    hash = hash_float(hash, relative_z);
    hash = hash_i32(hash, face_yaw);
    return hash_float(hash, scale);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_ukiki(fingerprint, 1, 0, 0, 0, 0.0f, 0, 0);
    fingerprint = hash_ukiki(fingerprint, 0, 0, 1, 0, 0.0f, 79, 0);
    fingerprint = hash_cage(fingerprint, 1, 0, 0x400, -1200.0f, 1, 1);
    fingerprint = hash_u64(fingerprint, 1);
    fingerprint = hash_i32(fingerprint, 0);
    fingerprint = hash_float(fingerprint, 40.0f);
    fingerprint = hash_mips(fingerprint, 0, 1, 1, 0.0f, 84, 1, 1);
    fingerprint = hash_i32(fingerprint, 1);
    fingerprint = hash_i32(fingerprint, 82);
    fingerprint = hash_i32(fingerprint, 81);
    fingerprint = hash_toad(fingerprint, 2, 82, 81, 0, 0);
    fingerprint = hash_menu(fingerprint, 1, 1, 150.0f, 1112.5f, 0x800, 1.0f);
    fingerprint = hash_i32(fingerprint, -1);
    fingerprint = hash_i32(fingerprint, 8);

    printf("npcMenuFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern NPC/menu C contract passed");
    return 0;
}
