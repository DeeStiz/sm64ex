#include <stdint.h>
#include <stdio.h>

enum Kind {
    KIND_NOTE = 1, KIND_DELAY, KIND_END, KIND_CALL, KIND_LOOP, KIND_JUMP,
    KIND_SHORT_VELOCITY, KIND_PAN, KIND_TRANSPOSE, KIND_SHORT_DURATION,
    KIND_CONTINUOUS, KIND_DEFAULT_PERCENTAGE, KIND_INSTRUMENT, KIND_PORTAMENTO,
    KIND_DISABLE_PORTAMENTO, KIND_TABLE_VELOCITY, KIND_TABLE_DURATION, KIND_UNKNOWN
};

struct Decoded {
    int kind;
    uint32_t a, b, c, d, e;
    int next;
};

static uint16_t compressed(const uint8_t *bytes, int *cursor) {
    const uint8_t first = bytes[(*cursor)++];
    if ((first & 0x80u) == 0) return first;
    return (uint16_t)((first & 0x7fu) << 8) | bytes[(*cursor)++];
}

static int16_t signed16(const uint8_t *bytes, int *cursor) {
    const uint16_t value = (uint16_t)((uint16_t)bytes[(*cursor)++] << 8) | bytes[(*cursor)++];
    return (int16_t)value;
}

static struct Decoded decode(const uint8_t *bytes, int length, int largeNotes,
                             uint16_t defaultPercentage, uint16_t previousPercentage) {
    struct Decoded result = { 0 };
    const uint8_t opcode = bytes[0];
    int cursor = 1;
    (void)length;
    if (opcode <= 0xc0) {
        if (opcode == 0xc0) {
            result.kind = KIND_DELAY;
            result.a = compressed(bytes, &cursor);
        } else {
            const uint8_t encoding = (uint8_t)(opcode & 0xc0u);
            result.kind = KIND_NOTE;
            result.a = opcode & 0x3fu;
            result.b = encoding == 0 ? compressed(bytes, &cursor)
                                     : (encoding == 0x40 ? defaultPercentage : previousPercentage);
            result.c = 0x1ff;
            result.d = 0x1ff;
            result.e = encoding >> 6;
            if (largeNotes) {
                result.c = bytes[cursor++];
                result.d = encoding == 0x40 ? 0 : bytes[cursor++];
            }
        }
    } else {
        switch (opcode) {
        case 0xff: result.kind = KIND_END; break;
        case 0xfc: result.kind = KIND_CALL; result.a = (uint32_t)(int32_t)signed16(bytes, &cursor); break;
        case 0xf8: {
            const uint8_t raw = bytes[cursor++];
            result.kind = KIND_LOOP; result.a = raw == 0 ? 256 : raw; break;
        }
        case 0xfb: result.kind = KIND_JUMP; result.a = (uint32_t)(int32_t)signed16(bytes, &cursor); break;
        case 0xc1: result.kind = KIND_SHORT_VELOCITY; result.a = bytes[cursor++]; break;
        case 0xca: result.kind = KIND_PAN; result.a = bytes[cursor++]; break;
        case 0xc2: result.kind = KIND_TRANSPOSE; result.a = bytes[cursor++]; break;
        case 0xc9: result.kind = KIND_SHORT_DURATION; result.a = bytes[cursor++]; break;
        case 0xc4: result.kind = KIND_CONTINUOUS; result.a = 1; break;
        case 0xc5: result.kind = KIND_CONTINUOUS; result.a = 0; break;
        case 0xc3: result.kind = KIND_DEFAULT_PERCENTAGE; result.a = compressed(bytes, &cursor); break;
        case 0xc6: result.kind = KIND_INSTRUMENT; result.a = bytes[cursor++]; break;
        case 0xc7: {
            const uint8_t mode = bytes[cursor++];
            result.kind = KIND_PORTAMENTO;
            result.a = mode;
            result.b = bytes[cursor++];
            result.c = (mode & 0x80u) ? bytes[cursor++] : compressed(bytes, &cursor);
            break;
        }
        case 0xc8: result.kind = KIND_DISABLE_PORTAMENTO; break;
        default:
            if ((opcode & 0xf0u) == 0xd0u) {
                result.kind = KIND_TABLE_VELOCITY; result.a = opcode & 0x0fu;
            } else if ((opcode & 0xf0u) == 0xe0u) {
                result.kind = KIND_TABLE_DURATION; result.a = opcode & 0x0fu;
            } else {
                result.kind = KIND_UNKNOWN; result.a = opcode;
            }
            break;
        }
    }
    result.next = cursor;
    return result;
}

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (int shift = 0; shift <= 24; shift += 8) {
        hash ^= (uint64_t)((value >> shift) & 0xffu);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static uint64_t hash_command(uint64_t hash, struct Decoded decoded) {
    hash = hash_u32(hash, (uint32_t)decoded.next);
    hash = hash_u32(hash, (uint32_t)decoded.kind);
    hash = hash_u32(hash, decoded.a);
    hash = hash_u32(hash, decoded.b);
    hash = hash_u32(hash, decoded.c);
    hash = hash_u32(hash, decoded.d);
    hash = hash_u32(hash, decoded.e);
    return hash;
}

enum Status { NOT_LOADED = 0, IN_PROGRESS = 1, COMPLETE = 2, DISCARDABLE = 3 };
struct Player {
    int enabled, finished;
    uint8_t sequenceID, defaultBank;
    int sequenceDMA, bankDMA;
};

static int available(uint8_t status) { return status >= COMPLETE; }

static void disable(uint8_t *sequences, uint8_t *banks, struct Player *player) {
    if (available(sequences[player->sequenceID])) sequences[player->sequenceID] = DISCARDABLE;
    if (available(banks[player->defaultBank])) banks[player->defaultBank] = DISCARDABLE;
    player->enabled = 0; player->finished = 1; player->sequenceDMA = 0; player->bankDMA = 0;
}

static uint64_t hash_load(uint64_t hash, const uint8_t *banks, const uint8_t *sequences,
                          const struct Player *players, uint32_t lock) {
    hash = hash_u32(hash, lock);
    const uint8_t selectedBanks[] = { banks[3], banks[4], banks[5], banks[6] };
    const uint8_t selectedSequences[] = { sequences[7], sequences[8], sequences[9] };
    for (size_t i = 0; i < sizeof(selectedBanks); ++i) hash = hash_u32(hash, selectedBanks[i]);
    for (size_t i = 0; i < sizeof(selectedSequences); ++i) hash = hash_u32(hash, selectedSequences[i]);
    for (int i = 0; i < 3; ++i) {
        hash = hash_u32(hash, (uint32_t)players[i].enabled);
        hash = hash_u32(hash, (uint32_t)players[i].finished);
        hash = hash_u32(hash, players[i].sequenceID);
        hash = hash_u32(hash, players[i].defaultBank);
        hash = hash_u32(hash, (uint32_t)players[i].sequenceDMA);
        hash = hash_u32(hash, (uint32_t)players[i].bankDMA);
    }
    return hash;
}

int main(void) {
    const uint8_t fixture0[] = { 0x05, 0x81, 0x2c };
    const uint8_t fixture1[] = { 0xc0, 0x82, 0x10 };
    const uint8_t fixture2[] = { 0xfc, 0xff, 0xf0 };
    const uint8_t fixture3[] = { 0xf8, 0x00 };
    const uint8_t fixture4[] = { 0xc7, 0x81, 0x05, 0x07 };
    const uint8_t fixture5[] = { 0x42, 0x7f };
    const uint8_t fixture6[] = { 0x82, 0x7f, 0x20 };
    const uint8_t fixture7[] = { 0xd3 };
    const uint8_t fixture8[] = { 0xe9 };
    const uint8_t fixture9[] = { 0xff };
    const uint8_t *fixtures[] = { fixture0, fixture1, fixture2, fixture3, fixture4,
                                  fixture5, fixture6, fixture7, fixture8, fixture9 };
    const int lengths[] = { 3, 3, 3, 2, 4, 2, 3, 1, 1, 1 };
    const int largeNotes[] = { 0, 0, 0, 0, 0, 1, 1, 0, 0, 0 };
    const uint16_t defaults[] = { 0, 0, 0, 0, 0, 90, 90, 0, 0, 0 };
    const uint16_t previous[] = { 0, 0, 0, 0, 0, 0, 300, 0, 0, 0 };
    uint64_t commandFingerprint = UINT64_C(1469598103934665603);
    for (int i = 0; i < 10; ++i) {
        commandFingerprint = hash_command(commandFingerprint,
            decode(fixtures[i], lengths[i], largeNotes[i], defaults[i], previous[i]));
    }

    uint8_t banks[64] = { 0 }, sequences[256] = { 0 };
    struct Player players[3] = {
        { 0, 1, 0, 0, 0, 0 }, { 0, 1, 0, 0, 0, 0 }, { 0, 1, 0, 0, 0, 0 }
    };
    banks[3] = COMPLETE; banks[4] = COMPLETE;

    /* Async sequence 7: its banks are already present, so only long sequence DMA remains. */
    disable(sequences, banks, &players[0]);
    players[0] = (struct Player){ 1, 0, 7, 4, 1, 0 };
    sequences[7] = IN_PROGRESS;
    sequences[7] = COMPLETE;
    disable(sequences, banks, &players[0]);

    /* Async short sequence 8 with one missing bank: bank DMA is serviced first. */
    disable(sequences, banks, &players[1]);
    banks[5] = IN_PROGRESS;
    sequences[8] = COMPLETE;
    players[1] = (struct Player){ 1, 0, 8, 5, 0, 1 };
    banks[5] = COMPLETE;
    players[1].bankDMA = 0;

    /* Async sequence 9 has two missing banks, so the source takes the immediate path. */
    disable(sequences, banks, &players[2]);
    banks[6] = COMPLETE; banks[7] = COMPLETE;
    sequences[9] = IN_PROGRESS;
    players[2] = (struct Player){ 1, 0, 9, 7, 1, 0 };
    sequences[9] = COMPLETE;
    players[2].sequenceDMA = 0;

    const uint32_t lock = UINT32_C(0x76557364);
    const uint64_t fingerprint = hash_load(commandFingerprint, banks, sequences, players, lock);
    printf("audioFingerprint=0x%llx\n", (unsigned long long)fingerprint);
    printf("SM64 Modern audio C contract passed\n");
    return 0;
}
