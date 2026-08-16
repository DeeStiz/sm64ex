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

struct State { int32_t action, role, cannon, talked; int16_t yaw; uint32_t blink; };
struct Output {
    struct State state;
    int32_t walking, sign, dialog, requested, camera, active, clear_time, clear_interaction;
    float visibility;
};

static uint64_t hash_output(uint64_t hash, const struct Output *output) {
    hash = hash_u64(hash, (uint64_t) (uint32_t) output->state.action);
    hash = hash_u64(hash, (uint64_t) (uint32_t) output->state.role);
    hash = hash_u64(hash, (uint64_t) (uint32_t) output->state.cannon);
    hash = hash_u64(hash, (uint64_t) (uint32_t) output->state.talked);
    hash = hash_u64(hash, (uint64_t) (uint16_t) output->state.yaw);
    hash = hash_u64(hash, output->state.blink);
    hash = hash_u64(hash, (uint64_t) (uint32_t) output->walking);
    hash = hash_u64(hash, (uint64_t) (uint32_t) output->sign);
    hash = hash_u64(hash, (uint64_t) (uint32_t) output->dialog);
    hash = hash_u64(hash, (uint64_t) (uint32_t) output->requested);
    hash = hash_u64(hash, (uint64_t) (uint32_t) output->camera);
    hash = hash_u64(hash, (uint64_t) (uint32_t) output->active);
    hash = hash_u64(hash, (uint64_t) (uint32_t) output->clear_time);
    hash = hash_u64(hash, (uint64_t) (uint32_t) output->clear_interaction);
    union { float f; uint32_t u; } bits = { output->visibility };
    return hash_u64(hash, bits.u);
}

static struct Output base(struct State state, uint32_t blink) {
    struct Output output = { state, 0, 0, 0, 0, 0, 0, 0, 0, 3000 };
    output.state.blink = blink;
    return output;
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    struct State state = { 0, 0, 0, 0, 0, 0 };
    struct Output output = base(state, 11);
    output.state.action = 2; output.state.yaw = 0x140; output.walking = 1; output.sign = 1;
    fingerprint = hash_output(fingerprint, &output); state = output.state;
    output = base(state, 12); output.state.yaw = 0x1140; output.walking = 1; output.sign = 1;
    fingerprint = hash_output(fingerprint, &output); state = output.state;
    output = base(state, 13); output.state.action = 3; output.state.yaw = 0x2000; output.sign = 0;
    fingerprint = hash_output(fingerprint, &output); state = output.state;

    state.role = 0;
    output = base(state, 14); output.dialog = 77; output.requested = 1;
    output.state.action = 0; output.state.talked = 1; output.active = 1;
    output.clear_time = 1; output.clear_interaction = 1;
    fingerprint = hash_output(fingerprint, &output);

    state = (struct State) { 3, 1, 0, 0, 0, 0 };
    output = base(state, 0); output.dialog = 4; output.requested = 1; output.active = 1;
    output.state.cannon = 1;
    fingerprint = hash_output(fingerprint, &output); state = output.state;
    output = base(state, 0); output.active = 1; output.camera = 1; output.state.cannon = 2;
    fingerprint = hash_output(fingerprint, &output); state = output.state;
    output = base(state, 0); output.dialog = 105; output.requested = 1; output.active = 1; output.state.cannon = 3;
    fingerprint = hash_output(fingerprint, &output); state = output.state;
    output = base(state, 0); output.active = 1; output.state.action = 0; output.state.cannon = 2;
    output.state.talked = 1; output.clear_time = 1; output.clear_interaction = 1;
    fingerprint = hash_output(fingerprint, &output);

    printf("bobombBuddyFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    printf("SM64 Modern Bob-omb Buddy C contract passed\n");
    return 0;
}
