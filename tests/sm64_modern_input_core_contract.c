#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define VALID_BUTTONS UINT16_C(0xFF3F)

struct State {
    int16_t rawX, rawY, extX, extY;
    float x, y, magnitude;
    uint16_t down, pressed;
};

static uint64_t hash_u16(uint64_t hash, uint16_t value) {
    for (unsigned byte = 0; byte < 2; ++byte) { hash ^= (value >> (byte * 8u)) & UINT16_C(0xff); hash *= FNV_PRIME; }
    return hash;
}

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (unsigned byte = 0; byte < 4; ++byte) { hash ^= (value >> (byte * 8u)) & UINT32_C(0xff); hash *= FNV_PRIME; }
    return hash;
}

static uint64_t hash_state(uint64_t hash, const struct State *state) {
    uint32_t bits;
    hash = hash_u16(hash, (uint16_t) state->rawX);
    hash = hash_u16(hash, (uint16_t) state->rawY);
    hash = hash_u16(hash, (uint16_t) state->extX);
    hash = hash_u16(hash, (uint16_t) state->extY);
    memcpy(&bits, &state->x, sizeof(bits)); hash = hash_u32(hash, bits);
    memcpy(&bits, &state->y, sizeof(bits)); hash = hash_u32(hash, bits);
    memcpy(&bits, &state->magnitude, sizeof(bits)); hash = hash_u32(hash, bits);
    hash = hash_u16(hash, state->down);
    return hash_u16(hash, state->pressed);
}

static struct State update(uint16_t *pending, uint16_t *previous, int connected,
                           uint16_t buttons, int16_t rawX, int16_t rawY,
                           int16_t extX, int16_t extY, int advance) {
    struct State result = { 0 };
    if (!connected) { *pending = 0; *previous = 0; return result; }
    buttons &= VALID_BUTTONS;
    *pending |= buttons & (uint16_t) (buttons ^ *previous);
    *previous = buttons;
    result.pressed = advance ? *pending : 0;
    if (advance) *pending = 0;
    result.rawX = rawX; result.rawY = rawY; result.extX = extX; result.extY = extY; result.down = buttons;
    result.x = 0; result.y = 0;
    if (rawX <= -8) result.x = rawX + 6;
    if (rawX >= 8) result.x = rawX - 6;
    if (rawY <= -8) result.y = rawY + 6;
    if (rawY >= 8) result.y = rawY - 6;
    result.magnitude = sqrtf(result.x * result.x + result.y * result.y);
    if (result.magnitude > 64) {
        float scale = 64 / result.magnitude;
        result.x *= scale; result.y *= scale; result.magnitude = 64;
    }
    return result;
}

int main(void) {
    const uint16_t a = UINT16_C(0x8000), b = UINT16_C(0x4000);
    uint16_t pending = 0, previous = 0;
    uint64_t fingerprint = FNV_OFFSET;
    struct State state;
    state = update(&pending, &previous, 1, a, 0, 0, 0, 0, 1); fingerprint = hash_state(fingerprint, &state);
    state = update(&pending, &previous, 1, a, 7, -7, 0, 0, 0); fingerprint = hash_state(fingerprint, &state);
    state = update(&pending, &previous, 1, a | b, 8, -8, 0, 0, 0); fingerprint = hash_state(fingerprint, &state);
    state = update(&pending, &previous, 1, b, 63, -63, 0, 0, 1); fingerprint = hash_state(fingerprint, &state);
    state = update(&pending, &previous, 1, 0, -128, 127, 0, 0, 1); fingerprint = hash_state(fingerprint, &state);
    state = update(&pending, &previous, 0, 0, 0, 0, 0, 0, 1); fingerprint = hash_state(fingerprint, &state);
    printf("inputCoreFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    return 0;
}
