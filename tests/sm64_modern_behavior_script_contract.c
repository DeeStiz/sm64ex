#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static const uint32_t program[] = {
    UINT32_C(0x00010000), UINT32_C(0x10020007), UINT32_C(0x0f020003),
    UINT32_C(0x05000002), UINT32_C(0x10020009), UINT32_C(0x07000000),
    UINT32_C(0x01000002), UINT32_C(0x0d030004), UINT32_C(0x0c000000),
    UINT32_C(0), UINT32_C(0x0a000000),
};

static unsigned command_length(uint8_t opcode) {
    switch (opcode) {
        case 0x02: case 0x04: case 0x0c: case 0x27: case 0x2a:
        case 0x2f: case 0x31: case 0x33: case 0x37: return 2;
        case 0x1c: case 0x29: case 0x2c: return 3;
        case 0x2b: return 3;
        case 0x30: return 5;
        case 0x13: case 0x14: case 0x15: case 0x16: case 0x17:
        case 0x23: case 0x2e: case 0x36: return 2;
        default: return 1;
    }
}

int main(void) {
    int current = 0;
    int status = 1;
    int64_t stack[32];
    unsigned stack_top = 0;
    int32_t ints[256] = { 0 };
    float floats[256] = { 0 };
    uint32_t active_flags = 1;
    uint32_t gfx_flags = 1;
    int32_t model_id = 0;
    int16_t hitbox_radius = 0;
    int16_t hitbox_height = 0;
    uint32_t spawn_count = 0;
    uint32_t droplet_count = 0;
    uint32_t last_model = 0;
    uint64_t last_behavior = 0;
    int16_t last_parameter = 0;
    uint32_t timer = 0;
    int32_t delay_timer = 0;
    uint64_t command_count = 0;
    uint32_t tick = 0;
    uint64_t trace_hash = FNV_OFFSET;

    for (unsigned tick_index = 0; tick_index < 3; ++tick_index) {
        tick = tick_index + 1;
        status = 1;
        unsigned guard = 0;
        while (status == 1 && current >= 0) {
            if (++guard > 10000) return 2;
            int executed = current;
            uint32_t word = program[current];
            uint8_t opcode = (uint8_t) (word >> 24);
            unsigned length = command_length(opcode);
            int next = current + (int) length;
            int proc = 1;

            switch (opcode) {
                case 0x00: current = next; break;
                case 0x01: {
                    int32_t frames = (int16_t) (word & UINT32_C(0xffff));
                    if (delay_timer < frames - 1) delay_timer++;
                    else { delay_timer = 0; current = next; }
                    proc = 0;
                    break;
                }
                case 0x05:
                    stack[stack_top++] = next;
                    stack[stack_top++] = (int16_t) (word & UINT32_C(0xffff));
                    current = next;
                    break;
                case 0x07: {
                    int64_t count = stack[--stack_top];
                    int target = (int) stack[--stack_top];
                    if (--count != 0) {
                        current = target;
                        stack[stack_top++] = target;
                        stack[stack_top++] = count;
                    } else current = next;
                    break;
                }
                case 0x0a: proc = 0; break;
                case 0x0c:
                    ints[4] += 1;
                    current = next;
                    break;
                case 0x0d:
                    floats[(word >> 16) & 0xff] += (float) (int16_t) (word & UINT32_C(0xffff));
                    current = next;
                    break;
                case 0x0f:
                    ints[(word >> 16) & 0xff] += (int16_t) (word & UINT32_C(0xffff));
                    current = next;
                    break;
                case 0x10:
                    ints[(word >> 16) & 0xff] = (int16_t) (word & UINT32_C(0xffff));
                    current = next;
                    break;
                default: return 3;
            }

            ++command_count;
            trace_hash = hash_u64(trace_hash, tick);
            trace_hash = hash_u64(trace_hash, (uint64_t) executed);
            trace_hash = hash_u64(trace_hash, opcode);
            trace_hash = hash_u64(trace_hash, (uint64_t) (int64_t) proc);
            trace_hash = hash_u64(trace_hash, 0);
            trace_hash = hash_u64(trace_hash, timer);
            trace_hash = hash_u64(trace_hash, (uint64_t) current);
            if (proc == 0) status = 0;
        }
        if (timer < UINT32_C(0x3fffffff)) ++timer;
    }

    uint64_t state_hash = FNV_OFFSET;
    state_hash = hash_u64(state_hash, 0);
    state_hash = hash_u64(state_hash, 10);
    state_hash = hash_u64(state_hash, stack_top);
    state_hash = hash_u64(state_hash, timer);
    state_hash = hash_u64(state_hash, (uint64_t) (int64_t) delay_timer);
    state_hash = hash_u64(state_hash, command_count);
    state_hash = hash_u64(state_hash, tick);
    state_hash = hash_u64(state_hash, 0);
    state_hash = hash_u64(state_hash, active_flags);
    state_hash = hash_u64(state_hash, gfx_flags);
    state_hash = hash_u64(state_hash, (uint64_t) (int64_t) model_id);
    state_hash = hash_u64(state_hash, (uint64_t) (int64_t) hitbox_radius);
    state_hash = hash_u64(state_hash, (uint64_t) (int64_t) hitbox_height);
    state_hash = hash_u64(state_hash, spawn_count);
    state_hash = hash_u64(state_hash, droplet_count);
    state_hash = hash_u64(state_hash, last_model);
    state_hash = hash_u64(state_hash, last_behavior);
    state_hash = hash_u64(state_hash, (uint64_t) (int64_t) last_parameter);
    const uint8_t fields[] = { 2, 3, 4 };
    for (unsigned index = 0; index < 3; ++index) {
        uint8_t field = fields[index];
        uint32_t float_bits;
        __builtin_memcpy(&float_bits, &floats[field], sizeof(float_bits));
        state_hash = hash_u64(state_hash, field);
        state_hash = hash_u64(state_hash, (uint64_t) (int64_t) ints[field]);
        state_hash = hash_u64(state_hash, float_bits);
    }

    printf("behaviorTraceFingerprint=0x%016llx\n", (unsigned long long) trace_hash);
    printf("behaviorStateFingerprint=0x%016llx\n", (unsigned long long) state_hash);
    return 0;
}
