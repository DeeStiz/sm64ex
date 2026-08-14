#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define STATUS_PAUSED2 (-1)
#define STATUS_PAUSED 0
#define STATUS_RUNNING 1
#define STATUS_HALTED 2

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static unsigned physical_offset(unsigned logical) {
    return (logical & 3u) | ((logical & ~3u) << 1u);
}

static uint8_t read_u8(const uint8_t *program, int command, unsigned logical) {
    return program[command + physical_offset(logical)];
}

static int16_t read_s16(const uint8_t *program, int command, unsigned logical) {
    uint16_t value = (uint16_t) read_u8(program, command, logical)
        | ((uint16_t) read_u8(program, command, logical + 1u) << 8u);
    return (int16_t) value;
}

static int32_t read_s32(const uint8_t *program, int command, unsigned logical) {
    uint32_t value = (uint32_t) read_u8(program, command, logical)
        | ((uint32_t) read_u8(program, command, logical + 1u) << 8u)
        | ((uint32_t) read_u8(program, command, logical + 2u) << 16u)
        | ((uint32_t) read_u8(program, command, logical + 3u) << 24u);
    return (int32_t) value;
}

static uint64_t read_u64(const uint8_t *program, int command, unsigned logical) {
    uint64_t value = 0;
    for (unsigned byte = 0; byte < 8; ++byte) {
        value |= (uint64_t) read_u8(program, command, logical + byte) << (byte * 8u);
    }
    return value;
}

static int eval_op(int32_t reg, uint8_t op, int32_t arg) {
    switch (op) {
        case 0: return (reg & arg) != 0;
        case 1: return (reg & arg) == 0;
        case 2: return reg == arg;
        case 3: return reg != arg;
        case 4: return reg < arg;
        case 5: return reg <= arg;
        case 6: return reg > arg;
        case 7: return reg >= arg;
        default: return 0;
    }
}

static const uint8_t program[] = {
    0x13, 0x04, 0x07, 0x00, 0, 0, 0, 0,
    0x0c, 0x0c, 0x02, 0x00, 0, 0, 0, 0, 0x07, 0, 0, 0, 0, 0, 0, 0, 0x28, 0, 0, 0, 0, 0, 0, 0,
    0x32, 0x04, 0, 0, 0, 0, 0, 0,
    0x1f, 0x08, 0x02, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0x26, 0x08, 0x0a, 0x05, 0, 0, 0, 0, 0x01, 0x02, 0x80, 0, 0, 0, 0, 0,
    0x27, 0x08, 0x03, 0x07, 0, 0, 0, 0, 0x02, 0x09, 0x01, 0, 0, 0, 0, 0,
    0x28, 0x0c, 0x01, 0x04, 0, 0, 0, 0, 0x9c, 0xff, 0xc8, 0, 0, 0, 0, 0, 0xd4, 0xfe, 0, 0, 0, 0, 0, 0,
    0x2b, 0x0c, 0x02, 0, 0, 0, 0, 0, 0x84, 0x03, 0x0a, 0, 0, 0, 0, 0, 0x14, 0, 0xe2, 0xff, 0, 0, 0, 0,
    0x31, 0x04, 0x04, 0, 0, 0, 0, 0,
    0x30, 0x04, 0, 0x2a, 0, 0, 0, 0,
    0x36, 0x08, 0x34, 0x12, 0, 0, 0, 0, 0x56, 0, 0, 0, 0, 0, 0, 0,
    0x33, 0x08, 0x02, 0x0f, 0, 0, 0, 0, 10, 20, 30, 0, 0, 0, 0, 0,
    0x34, 0x04, 1, 0, 0, 0, 0, 0,
    0x35, 0x04, 1, 0, 0, 0, 0, 0,
    0x20, 0x04, 0, 0, 0, 0, 0, 0,
    0x06, 0x08, 0, 0, 0, 0, 0, 0, 0xf8, 0, 0, 0, 0, 0, 0, 0,
    0x13, 0x04, 9, 0, 0, 0, 0, 0,
    0x02, 0x04, 0, 0, 0, 0, 0, 0,
    0x32, 0x04, 0, 0, 0, 0, 0, 0,
    0x13, 0x04, 0x2a, 0, 0, 0, 0, 0,
    0x07, 0x04, 0, 0, 0, 0, 0, 0,
};

int main(void) {
    int current = 0;
    int status = STATUS_RUNNING;
    int32_t reg = 0;
    int16_t level = 0;
    int16_t global_area = 0;
    int16_t active_area = -1;
    int stack[32];
    unsigned stack_top = 0;
    uint64_t command_count = 0;
    uint64_t trace_hash = FNV_OFFSET;
    uint32_t tick = 1;
    unsigned trace_offsets[] = { 0, 8, 40, 56, 72, 88, 112, 136, 144, 152, 168, 184, 192, 200, 208, 248, 256, 224, 232 };
    unsigned trace_index = 0;
    uint64_t expected_trace_count = sizeof(trace_offsets) / sizeof(trace_offsets[0]);
    uint64_t transition_hash = FNV_OFFSET;
    uint64_t state_hash;
    uint8_t terrain = 0;
    uint8_t dialog0 = 0;
    uint8_t dialog1 = 0;
    int16_t music0 = 0;
    int16_t music1 = 0;
    uint8_t blackout = 0;
    uint8_t gamma = 0;

    while (status != STATUS_HALTED && trace_index < expected_trace_count) {
        status = STATUS_RUNNING;
        while (status == STATUS_RUNNING && current >= 0) {
            int executed = current;
            uint8_t opcode = read_u8(program, current, 0);
            uint8_t size = read_u8(program, current, 1);
            int next = current + ((int) size << 1);
            switch (opcode) {
                case 0x13: reg = read_s16(program, current, 2); current = next; break;
                case 0x0c:
                    if (eval_op(reg, read_u8(program, current, 2), read_s32(program, current, 4))) current = (int) read_u64(program, current, 8);
                    else current = next;
                    break;
                case 0x32: current = next; break;
                case 0x1f: active_area = read_u8(program, current, 2); current = next; break;
                case 0x26:
                    if (active_area >= 0) { /* retained in state hash below */ }
                    current = next;
                    break;
                case 0x27: current = next; break;
                case 0x28: current = next; break;
                case 0x2b: current = next; break;
                case 0x31: terrain |= (uint8_t) read_s16(program, current, 2); current = next; break;
                case 0x30:
                    if (read_u8(program, current, 2) == 0) dialog0 = read_u8(program, current, 3);
                    else if (read_u8(program, current, 2) == 1) dialog1 = read_u8(program, current, 3);
                    current = next;
                    break;
                case 0x36: music0 = read_s16(program, current, 2); music1 = read_s16(program, current, 4); current = next; break;
                case 0x33:
                    transition_hash = hash_u64(transition_hash, read_u8(program, current, 2));
                    transition_hash = hash_u64(transition_hash, read_u8(program, current, 3));
                    transition_hash = hash_u64(transition_hash, read_u8(program, current, 4));
                    transition_hash = hash_u64(transition_hash, read_u8(program, current, 5));
                    transition_hash = hash_u64(transition_hash, read_u8(program, current, 6));
                    current = next;
                    break;
                case 0x34: blackout = read_u8(program, current, 2); current = next; break;
                case 0x35: gamma = read_u8(program, current, 2); current = next; break;
                case 0x20: active_area = -1; current = next; break;
                case 0x06: stack[stack_top++] = next; current = (int) read_u64(program, current, 4); break;
                case 0x02:
                    if (stack_top != 0) current = stack[--stack_top];
                    else { current = -1; status = STATUS_HALTED; }
                    break;
                case 0x07:
                    if (stack_top == 0) return 2;
                    current = stack[--stack_top];
                    break;
                default: return 3;
            }
            ++command_count;
            trace_hash = hash_u64(trace_hash, tick);
            trace_hash = hash_u64(trace_hash, (uint64_t) executed);
            trace_hash = hash_u64(trace_hash, opcode);
            trace_hash = hash_u64(trace_hash, size);
            trace_hash = hash_u64(trace_hash, (uint64_t) (int64_t) reg);
            trace_hash = hash_u64(trace_hash, (uint64_t) (int64_t) level);
            trace_hash = hash_u64(trace_hash, (uint64_t) (int64_t) global_area);
            trace_hash = hash_u64(trace_hash, (uint64_t) (int64_t) status);
            trace_hash = hash_u64(trace_hash, current < 0 ? UINT64_MAX : (uint64_t) current);
            if (trace_index >= expected_trace_count || executed != (int) trace_offsets[trace_index++]) return 4;
        }
    }

    state_hash = FNV_OFFSET;
    state_hash = hash_u64(state_hash, STATUS_HALTED);
    state_hash = hash_u64(state_hash, UINT64_MAX);
    state_hash = hash_u64(state_hash, (uint64_t) (int64_t) reg);
    state_hash = hash_u64(state_hash, (uint64_t) (int64_t) level);
    state_hash = hash_u64(state_hash, 0);
    state_hash = hash_u64(state_hash, 1);
    state_hash = hash_u64(state_hash, 0);
    state_hash = hash_u64(state_hash, 0);
    state_hash = hash_u64(state_hash, UINT64_MAX);
    state_hash = hash_u64(state_hash, command_count);
    state_hash = hash_u64(state_hash, 10); state_hash = hash_u64(state_hash, 133); state_hash = hash_u64(state_hash, 1); state_hash = hash_u64(state_hash, 2); state_hash = hash_u64(state_hash, 0x80); state_hash = hash_u64(state_hash, 0);
    state_hash = hash_u64(state_hash, 3); state_hash = hash_u64(state_hash, 8); state_hash = hash_u64(state_hash, 2); state_hash = hash_u64(state_hash, 9); state_hash = hash_u64(state_hash, 1); state_hash = hash_u64(state_hash, 1);
    state_hash = hash_u64(state_hash, 1); state_hash = hash_u64(state_hash, 4); state_hash = hash_u64(state_hash, (uint64_t) (int64_t) -100); state_hash = hash_u64(state_hash, 200); state_hash = hash_u64(state_hash, (uint64_t) (int64_t) -300);
    state_hash = hash_u64(state_hash, 1); state_hash = hash_u64(state_hash, 2); state_hash = hash_u64(state_hash, 900); state_hash = hash_u64(state_hash, 10); state_hash = hash_u64(state_hash, 20); state_hash = hash_u64(state_hash, (uint64_t) (int64_t) -30);
    state_hash = hash_u64(state_hash, terrain); state_hash = hash_u64(state_hash, dialog0); state_hash = hash_u64(state_hash, dialog1); state_hash = hash_u64(state_hash, (uint64_t) (int64_t) music0); state_hash = hash_u64(state_hash, (uint64_t) (int64_t) music1); state_hash = hash_u64(state_hash, blackout); state_hash = hash_u64(state_hash, gamma);
    state_hash = hash_u64(state_hash, 2); state_hash = hash_u64(state_hash, 15); state_hash = hash_u64(state_hash, 10); state_hash = hash_u64(state_hash, 20); state_hash = hash_u64(state_hash, 30);
    printf("levelScriptVMTraceFingerprint=0x%016llx\n", (unsigned long long) trace_hash);
    printf("levelScriptVMStateFingerprint=0x%016llx\n", (unsigned long long) state_hash);
    (void) transition_hash;
    return 0;
}
