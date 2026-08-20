#include <stdbool.h>
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

static uint64_t hash_i32(uint64_t hash, int32_t value) {
    return hash_u32(hash, (uint32_t) value);
}

static uint64_t hash_f32(uint64_t hash, float value) {
    union { float f; uint32_t u; } bits = { value };
    return hash_u32(hash, bits.u);
}

static uint64_t hash_bool(uint64_t hash, bool value) {
    return hash_u32(hash, value ? 1u : 0u);
}

struct Vec3 { float x, y, z; };

struct PieceInput {
    int32_t action;
    int32_t previous_action;
    int32_t timer;
    struct Vec3 home;
    struct Vec3 offset;
    bool continue_action;
    int32_t next_action_index;
    const int32_t *action_list;
    bool mario_standing;
    int32_t parent_completion_flags;
};

struct PieceOutput {
    int32_t action;
    int32_t previous_action;
    int32_t timer;
    struct Vec3 position;
    struct Vec3 offset;
    bool continue_action;
    int32_t next_action_index;
    int32_t parent_completion_flags;
    bool played_move_sound;
};

struct PuzzleInput {
    int32_t action;
    int32_t previous_action;
    int32_t timer;
    int32_t completion_flags;
    float distance_to_mario;
};

struct PuzzleOutput {
    int32_t action;
    int32_t previous_action;
    int32_t timer;
    int32_t completion_flags;
    bool spawn_pieces;
    bool spawn_coins;
};

static void make_action_lists(int32_t lists[14][27]) {
    for (unsigned piece = 0; piece < 14; ++piece) {
        for (unsigned index = 0; index < 26; ++index) lists[piece][index] = 2;
        lists[piece][26] = -1;
    }
    lists[0][1] = 3; lists[0][24] = 4;
    lists[1][2] = 3; lists[1][23] = 4;
    lists[2][11] = 6; lists[2][14] = 5;
    lists[3][12] = 3; lists[3][13] = 4;
    lists[4][3] = 5; lists[4][22] = 6;
    lists[5][4] = 3; lists[5][21] = 4;
    lists[6][10] = 4; lists[6][15] = 3;
    lists[7][9] = 6; lists[7][16] = 5;
    lists[8][6] = 4; lists[8][19] = 3;
    lists[9][5] = 5; lists[9][20] = 6;
    lists[11][8] = 4; lists[11][17] = 3;
    lists[12][7] = 5; lists[12][18] = 6;
}

static struct PieceOutput update_piece(struct PieceInput input) {
    struct PieceOutput output = {
        input.action,
        input.previous_action,
        input.timer,
        input.home,
        input.offset,
        input.continue_action,
        input.next_action_index,
        input.parent_completion_flags,
        false,
    };

    if (output.action != output.previous_action) {
        output.timer = 0;
        output.previous_action = output.action;
    }
    if (input.mario_standing) output.parent_completion_flags = 1;

    if (!output.continue_action) {
        int32_t index = output.next_action_index < 0 ? 0 : output.next_action_index;
        int32_t selected = (index >= 0 && index < 27) ? input.action_list[index] : -1;
        output.action = selected == -1 ? 2 : selected;
        output.next_action_index = index + 1;
        if (index + 1 >= 0 && index + 1 < 27 && input.action_list[index + 1] == -1) {
            output.parent_completion_flags |= 2;
            output.next_action_index = 0;
        }
        output.continue_action = true;
        output.timer = 0;
        output.previous_action = output.action;
    }

    switch (output.action) {
        case 1:
            output.action = 3;
            break;
        case 2:
            if (output.timer >= 24) output.continue_action = false;
            break;
        case 3:
        case 4:
        case 5:
        case 6:
            if (output.timer < 20) {
                output.offset.y = output.timer % 2 == 0 ? -6.0f : 0.0f;
            } else {
                if (output.timer == 20) output.played_move_sound = true;
                if (output.timer < 24) {
                    if (output.action == 3) output.offset.x -= 120.0f;
                    if (output.action == 4) output.offset.x += 120.0f;
                    if (output.action == 5) output.offset.z -= 120.0f;
                    if (output.action == 6) output.offset.z += 120.0f;
                } else {
                    output.action = 2;
                    output.continue_action = false;
                }
            }
            break;
        default:
            break;
    }

    if (output.timer < INT32_C(0x3fffffff)) ++output.timer;
    if (output.action != output.previous_action) {
        output.timer = 0;
        output.previous_action = output.action;
    }
    output.position.x = input.home.x + output.offset.x;
    output.position.y = input.home.y + output.offset.y;
    output.position.z = input.home.z + output.offset.z;
    return output;
}

static struct PuzzleOutput update_puzzle(struct PuzzleInput input) {
    struct PuzzleOutput output = {
        input.action,
        input.previous_action,
        input.timer,
        input.completion_flags,
        false,
        false,
    };
    if (output.action != output.previous_action) {
        output.timer = 0;
        output.previous_action = output.action;
    }
    switch (output.action) {
        case 0:
            output.spawn_pieces = true;
            output.action = 1;
            break;
        case 1:
            if (output.completion_flags == 3 && input.distance_to_mario < 1000.0f) {
                output.spawn_coins = true;
                output.completion_flags = 0;
                output.action = 2;
            }
            break;
        default:
            break;
    }
    if (output.timer < INT32_C(0x3fffffff)) ++output.timer;
    if (output.action != output.previous_action) {
        output.timer = 0;
        output.previous_action = output.action;
    }
    return output;
}

static uint64_t hash_piece_output(uint64_t hash, struct PieceOutput output) {
    hash = hash_i32(hash, output.action);
    hash = hash_i32(hash, output.previous_action);
    hash = hash_i32(hash, output.timer);
    hash = hash_f32(hash, output.position.x);
    hash = hash_f32(hash, output.position.y);
    hash = hash_f32(hash, output.position.z);
    hash = hash_f32(hash, output.offset.x);
    hash = hash_f32(hash, output.offset.y);
    hash = hash_f32(hash, output.offset.z);
    hash = hash_bool(hash, output.continue_action);
    hash = hash_i32(hash, output.next_action_index);
    hash = hash_i32(hash, output.parent_completion_flags);
    return hash_bool(hash, output.played_move_sound);
}

static uint64_t hash_puzzle_output(uint64_t hash, struct PuzzleOutput output) {
    hash = hash_i32(hash, output.action);
    hash = hash_i32(hash, output.previous_action);
    hash = hash_i32(hash, output.timer);
    hash = hash_i32(hash, output.completion_flags);
    hash = hash_bool(hash, output.spawn_pieces);
    return hash_bool(hash, output.spawn_coins);
}

int main(void) {
    static const int32_t initial_actions[14] = { 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    static const int32_t offset_x[14] = { -5, 5, -15, -5, 5, 15, -15, -5, 5, 15, -15, -5, 5, 15 };
    static const int32_t offset_z[14] = { -15, -15, -5, -5, -5, -5, 5, 5, 5, 5, 15, 15, 15, 15 };
    int32_t lists[14][27];
    make_action_lists(lists);

    struct Vec3 home = { 100.0f, 200.0f, 300.0f };
    struct PieceOutput piece_initial = update_piece((struct PieceInput){
        1, 0, 99, home, { 0, 0, 0 }, false, 0, lists[0], false, 0
    });
    struct PieceOutput piece_move = update_piece((struct PieceInput){
        3, 3, 20, home, { 0, 0, 0 }, true, 2, lists[0], false, 0
    });
    struct PieceOutput piece_finished = update_piece((struct PieceInput){
        3, 3, 24, home, { -480, 0, 0 }, true, 2, lists[0], false, 0
    });
    struct PieceOutput piece_standing = update_piece((struct PieceInput){
        2, 2, 0, home, { 0, 0, 0 }, true, 0, lists[0], true, 0
    });
    struct PuzzleOutput puzzle_spawn = update_puzzle((struct PuzzleInput){ 0, 0, 0, 0, 10000.0f });
    struct PuzzleOutput puzzle_coins = update_puzzle((struct PuzzleInput){ 1, 1, 7, 3, 999.5f });

    if (piece_initial.action != 2 || piece_initial.timer != 1 ||
        piece_move.offset.x != -120.0f || piece_move.timer != 21 || !piece_move.played_move_sound ||
        piece_finished.action != 2 || piece_finished.timer != 0 || piece_finished.continue_action ||
        piece_standing.parent_completion_flags != 1 ||
        !puzzle_spawn.spawn_pieces || puzzle_spawn.action != 1 || puzzle_spawn.timer != 0 ||
        !puzzle_coins.spawn_coins || puzzle_coins.completion_flags != 0 ||
        puzzle_coins.action != 2 || puzzle_coins.timer != 0) {
        return 2;
    }

    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_u32(fingerprint, 14);
    for (unsigned piece = 0; piece < 14; ++piece) {
        fingerprint = hash_u32(fingerprint, piece);
        fingerprint = hash_u32(fingerprint, UINT32_C(0x43) + piece);
        fingerprint = hash_i32(fingerprint, initial_actions[piece]);
        fingerprint = hash_i32(fingerprint, offset_x[piece]);
        fingerprint = hash_i32(fingerprint, offset_z[piece]);
        fingerprint = hash_u32(fingerprint, 27);
        for (unsigned index = 0; index < 27; ++index) fingerprint = hash_i32(fingerprint, lists[piece][index]);
    }
    fingerprint = hash_piece_output(fingerprint, piece_initial);
    fingerprint = hash_piece_output(fingerprint, piece_move);
    fingerprint = hash_piece_output(fingerprint, piece_finished);
    fingerprint = hash_piece_output(fingerprint, piece_standing);
    fingerprint = hash_puzzle_output(fingerprint, puzzle_spawn);
    fingerprint = hash_puzzle_output(fingerprint, puzzle_coins);
    printf("lllBowserPuzzleFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    puts("SM64 Modern LLL Bowser puzzle C contract passed");
    return 0;
}
