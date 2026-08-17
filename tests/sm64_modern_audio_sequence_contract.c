#include <stdint.h>
#include <stdio.h>
#include <string.h>

enum Kind {
    TATUM = 1, WAIT, END, RETURN_EVENT, CALL, LOOP, LOOP_END, JUMP, BRANCH,
    RESERVE, UNRESERVE, TRANSPOSE, TEMPO_SET, TEMPO_ADD, SET_VOLUME,
    CHANGE_VOLUME, INIT_CHANNELS, DISABLE_CHANNELS, MUTE_SCALE, MUTE,
    MUTE_BEHAVIOR, VELOCITY_TABLE, DURATION_TABLE, ALLOCATION_POLICY, SET_VALUE,
    BIT_AND, SUBTRACT, TEST_CHANNEL, SET_VARIATION, GET_VARIATION, START_CHANNEL,
    IGNORED, MALFORMED, MUTED_STOP
};

struct Event { uint8_t kind, opcode; int32_t value0, value1; };
struct Packet {
    int advanced, eventCount;
    struct Event events[64];
    int enabled, finished, pc;
    uint16_t tempo, tempoAccumulator, delay;
    uint8_t depth;
    int32_t value;
    int16_t transposition, variation;
    uint16_t enabledChannelMask;
};
struct Player {
    const uint8_t *data;
    int length, pc;
    uint16_t target, tempo, tempoAccumulator, delay;
    uint8_t enabled, finished, depth, muted, muteBehavior;
    int32_t value;
    int16_t transposition, variation;
    uint16_t enabledChannelMask, channelFinishedMask;
    int stack[4];
    uint8_t loops[4];
};

static void event(struct Packet *packet, int kind, uint8_t opcode, int32_t value0, int32_t value1) {
    packet->events[packet->eventCount++] = (struct Event){ (uint8_t)kind, opcode, value0, value1 };
}

static int read_byte(struct Player *player, uint8_t *out) {
    if (player->pc < 0 || player->pc >= player->length) return 0;
    *out = player->data[player->pc++];
    return 1;
}

static int read_compressed(struct Player *player, uint16_t *out) {
    uint8_t first, second;
    if (!read_byte(player, &first)) return 0;
    if ((first & 0x80u) == 0) { *out = first; return 1; }
    if (!read_byte(player, &second)) return 0;
    *out = (uint16_t)((first & 0x7fu) << 8) | second;
    return 1;
}

static int read_signed16(struct Player *player, int16_t *out) {
    uint8_t high, low;
    if (!read_byte(player, &high) || !read_byte(player, &low)) return 0;
    *out = (int16_t)(((uint16_t)high << 8) | low);
    return 1;
}

static int set_pc(struct Player *player, int offset) {
    return offset >= 0 && offset < player->length;
}

static int execute_control(struct Player *player, uint8_t opcode, struct Packet *packet) {
    uint8_t raw;
    uint16_t mask;
    int16_t offset;
    switch (opcode) {
    case 0xde:
        if (!read_byte(player, &raw)) return 0;
        player->transposition = (int16_t)(player->transposition + (int8_t)raw);
        event(packet, TRANSPOSE, opcode, player->transposition, 0);
        break;
    case 0xd7:
    case 0xd6:
        if (!read_signed16(player, &offset)) return 0;
        mask = (uint16_t)offset;
        if (opcode == 0xd7) {
            player->enabledChannelMask |= mask;
            player->channelFinishedMask &= (uint16_t)~mask;
            event(packet, INIT_CHANNELS, opcode, offset, 0);
        } else {
            player->enabledChannelMask &= (uint16_t)~mask;
            player->channelFinishedMask |= mask;
            event(packet, DISABLE_CHANNELS, opcode, offset, 0);
        }
        break;
    case 0xcc:
        if (!read_byte(player, &raw)) return 0;
        player->value = (int8_t)raw;
        event(packet, SET_VALUE, opcode, player->value, 0);
        break;
    case 0xc9:
        if (!read_byte(player, &raw)) return 0;
        player->value &= raw;
        event(packet, BIT_AND, opcode, player->value, 0);
        break;
    case 0xc8:
        if (!read_byte(player, &raw)) return 0;
        player->value -= raw;
        event(packet, SUBTRACT, opcode, player->value, 0);
        break;
    case 0xf8:
        if (!read_byte(player, &raw) || player->depth >= 4) return 0;
        player->loops[player->depth] = raw;
        player->stack[player->depth] = player->pc;
        player->depth++;
        event(packet, LOOP, opcode, raw == 0 ? 256 : raw, player->pc);
        break;
    case 0xf7: {
        if (player->depth == 0) return 0;
        const int index = player->depth - 1;
        player->loops[index]--;
        if (player->loops[index] != 0) player->pc = player->stack[index];
        else player->depth--;
        event(packet, LOOP_END, opcode, player->loops[index], player->pc);
        break;
    }
    case 0x90:
        if (!read_signed16(player, &offset) || !set_pc(player, offset)) return 0;
        player->enabledChannelMask |= (uint16_t)1u << (opcode & 0x0fu);
        player->channelFinishedMask &= (uint16_t)~((uint16_t)1u << (opcode & 0x0fu));
        event(packet, START_CHANNEL, opcode, opcode & 0x0f, offset);
        break;
    default:
        event(packet, IGNORED, opcode, 0, 0);
        break;
    }
    return 1;
}

static void execute_low(struct Player *player, uint8_t opcode, struct Packet *packet) {
    const uint8_t low = opcode & 0x0f;
    const uint16_t bit = (uint16_t)1u << low;
    switch (opcode & 0xf0u) {
    case 0x00:
        if ((player->enabledChannelMask & bit) != 0) {
            player->value = (player->channelFinishedMask & bit) != 0;
        }
        event(packet, TEST_CHANNEL, opcode, player->value, 0);
        break;
    case 0x50:
        player->value -= player->variation;
        event(packet, SUBTRACT, opcode, player->value, 0);
        break;
    case 0x70:
        player->variation = (int16_t)player->value;
        event(packet, SET_VARIATION, opcode, player->value, 0);
        break;
    case 0x80:
        player->value = player->variation;
        event(packet, GET_VARIATION, opcode, player->value, 0);
        break;
    case 0x90: {
        int16_t offset;
        if (!read_signed16(player, &offset) || !set_pc(player, offset)) {
            event(packet, MALFORMED, opcode, player->pc, 0);
            return;
        }
        player->enabledChannelMask |= bit;
        player->channelFinishedMask &= (uint16_t)~bit;
        event(packet, START_CHANNEL, opcode, low, offset);
        break;
    }
    default:
        event(packet, IGNORED, opcode, 0, 0);
        break;
    }
}

static struct Packet make_packet(const struct Player *player, int advanced, const struct Event *events, int count) {
    struct Packet packet = { 0 };
    packet.advanced = advanced;
    packet.eventCount = count;
    memcpy(packet.events, events, (size_t)count * sizeof(*events));
    packet.enabled = player->enabled;
    packet.finished = player->finished;
    packet.pc = player->pc;
    packet.tempo = player->tempo;
    packet.tempoAccumulator = player->tempoAccumulator;
    packet.delay = player->delay;
    packet.depth = player->depth;
    packet.value = player->value;
    packet.transposition = player->transposition;
    packet.variation = player->variation;
    packet.enabledChannelMask = player->enabledChannelMask;
    return packet;
}

static struct Packet tick(struct Player *player, int advance) {
    struct Event events[64];
    struct Packet packet = { 0 };
    packet.events[0] = (struct Event){ 0 };
    if (!advance || !player->enabled) return make_packet(player, 0, events, 0);
    player->tempoAccumulator = (uint16_t)(player->tempoAccumulator + player->tempo);
    if (player->tempoAccumulator < player->target) return make_packet(player, 0, events, 0);
    player->tempoAccumulator = (uint16_t)(player->tempoAccumulator - player->target);
    event(&packet, TATUM, 0, 0, 0);
    if (player->delay > 1) {
        player->delay--;
        event(&packet, WAIT, 0, player->delay, 0);
        return make_packet(player, 1, packet.events, packet.eventCount);
    }
    if (player->muted && (player->muteBehavior & 0x80u) != 0) {
        event(&packet, MUTED_STOP, 0, 0, 0);
        return make_packet(player, 1, packet.events, packet.eventCount);
    }
    while (player->enabled) {
        uint8_t opcode;
        if (!read_byte(player, &opcode)) {
            event(&packet, MALFORMED, 0, player->pc, 0);
            player->enabled = 0; player->finished = 1;
            break;
        }
        if (opcode == 0xff) {
            event(&packet, END, opcode, 0, 0);
            if (player->depth == 0) { player->enabled = 0; player->finished = 1; break; }
            player->depth--;
            player->pc = player->stack[player->depth];
            event(&packet, RETURN_EVENT, opcode, player->pc, 0);
            continue;
        }
        if (opcode == 0xfd) {
            uint16_t value;
            if (!read_compressed(player, &value)) { event(&packet, MALFORMED, opcode, player->pc, 0); player->enabled = 0; player->finished = 1; break; }
            player->delay = value;
            event(&packet, 2, opcode, value, 0);
            break;
        }
        if (opcode == 0xfe) {
            player->delay = 1;
            event(&packet, 2, opcode, 1, 0);
            break;
        }
        if (opcode >= 0xc0) {
            if (!execute_control(player, opcode, &packet)) {
                event(&packet, MALFORMED, opcode, player->pc, 0);
                player->enabled = 0; player->finished = 1; break;
            }
        } else {
            execute_low(player, opcode, &packet);
        }
    }
    return make_packet(player, 1, packet.events, packet.eventCount);
}

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (int shift = 0; shift <= 24; shift += 8) {
        hash ^= (uint64_t)((value >> shift) & 0xffu);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static uint64_t hash_packet(uint64_t hash, const struct Packet *packet) {
    hash = hash_u32(hash, (uint32_t)packet->advanced);
    hash = hash_u32(hash, (uint32_t)packet->eventCount);
    for (int i = 0; i < packet->eventCount; ++i) {
        hash = hash_u32(hash, packet->events[i].kind);
        hash = hash_u32(hash, packet->events[i].opcode);
        hash = hash_u32(hash, (uint32_t)packet->events[i].value0);
        hash = hash_u32(hash, (uint32_t)packet->events[i].value1);
    }
    hash = hash_u32(hash, (uint32_t)packet->enabled);
    hash = hash_u32(hash, (uint32_t)packet->finished);
    hash = hash_u32(hash, (uint32_t)packet->pc);
    hash = hash_u32(hash, packet->tempo);
    hash = hash_u32(hash, packet->tempoAccumulator);
    hash = hash_u32(hash, packet->delay);
    hash = hash_u32(hash, packet->depth);
    hash = hash_u32(hash, (uint32_t)packet->value);
    hash = hash_u32(hash, (uint32_t)(int32_t)packet->transposition);
    hash = hash_u32(hash, (uint32_t)(int32_t)packet->variation);
    hash = hash_u32(hash, packet->enabledChannelMask);
    return hash;
}

int main(void) {
    const uint8_t script[] = {
        0xcc, 0x05, 0xc9, 0x03, 0xc8, 0x01, 0xde, 0xfe,
        0xd7, 0x00, 0x03, 0x90, 0x00, 0x0f, 0xfd, 0x02,
        0xf8, 0x02, 0xcc, 0x07, 0xf7, 0x70, 0x80, 0xfe, 0xff
    };
    struct Player player = {
        .data = script,
        .length = (int)sizeof(script),
        .pc = 0,
        .target = 5760,
        .tempo = 5760,
        .tempoAccumulator = 0,
        .delay = 0,
        .enabled = 1,
        .finished = 0,
        .depth = 0,
        .muted = 0,
        .muteBehavior = 0xe0,
        .value = 0,
        .transposition = 0,
        .variation = -1,
        .enabledChannelMask = 0,
        .channelFinishedMask = 0
    };
    uint64_t fingerprint = UINT64_C(1469598103934665603);
    struct Packet first = tick(&player, 1);
    if (!first.advanced || first.delay != 2 || first.value != 0 || first.transposition != -2
        || first.enabledChannelMask != 3) return 1;
    fingerprint = hash_packet(fingerprint, &first);
    struct Packet waiting = tick(&player, 1);
    if (waiting.eventCount != 2 || waiting.delay != 1 || waiting.pc != 16) return 2;
    fingerprint = hash_packet(fingerprint, &waiting);
    struct Packet looped = tick(&player, 1);
    if (looped.delay != 1 || looped.value != 7 || looped.eventCount < 8) return 3;
    fingerprint = hash_packet(fingerprint, &looped);
    struct Packet ended = tick(&player, 1);
    if (!ended.finished || ended.enabled || ended.eventCount != 2) return 4;
    fingerprint = hash_packet(fingerprint, &ended);
    struct Packet frozen = tick(&player, 0);
    if (frozen.advanced || frozen.eventCount != 0 || frozen.pc != ended.pc) return 5;
    fingerprint = hash_packet(fingerprint, &frozen);
    printf("audioSequenceFingerprint=0x%llx\n", (unsigned long long)fingerprint);
    printf("SM64 Modern audio sequence C contract passed\n");
    return 0;
}
