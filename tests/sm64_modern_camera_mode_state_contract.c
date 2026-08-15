#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
static uint64_t h8(uint64_t h, uint8_t v) { h ^= v; return h * FNV_PRIME; }
static uint64_t h16(uint64_t h, uint16_t v) { for (unsigned i = 0; i < 2; ++i) h = h8(h, (uint8_t)(v >> (i * 8u))); return h; }
static uint64_t h32(uint64_t h, uint32_t v) { for (unsigned i = 0; i < 4; ++i) h = h8(h, (uint8_t)(v >> (i * 8u))); return h; }
static uint64_t hf(uint64_t h, float value) { uint32_t bits; memcpy(&bits, &value, sizeof(bits)); return h32(h, bits); }

enum {
    MODE_MARIO_ACTIVE = 0x0001,
    MODE_LAKITU_WAS_ZOOMED_OUT = 0x0002,
    MODE_MARIO_SELECTED = 0x0004,
    MOVE_RETURN_TO_MIDDLE = 0x0001,
    MOVE_ZOOMED_OUT = 0x0002,
    MOVE_ROTATE_RIGHT = 0x0004,
    MOVE_ROTATE_LEFT = 0x0008,
    MOVE_ENTERED_ROTATE_SURFACE = 0x0010,
    MOVE_FIX_IN_PLACE = 0x0040,
    MOVE_RESTRICT = 0x0010 | 0x0020 | 0x0040 | 0x0080,
    MOVE_ROTATE = 0x0001 | 0x0004 | 0x0008,
    SOUND_MARIO_ACTIVE = 0x0002,
    SOUND_NORMAL_ACTIVE = 0x0004,
    SOUND_UNUSED_SELECT_MARIO = 0x0008,
    SOUND_UNUSED_SELECT_FIXED = 0x0010,
    FLAG_FRAME_AFTER_CAM_INIT = 0x0004,
    FLAG_START_TRANSITION = 0x0400,
    FLAG_TRANSITION_OUT_OF_C_UP = 0x0800
};

struct State {
    uint16_t selectionFlags, movementFlags, soundFlags, statusFlags;
    int16_t mode, defaultMode, lastMode, newMode;
    int32_t transitionFramesLeft;
    int16_t transitionMax, transitionFrame;
    int16_t cUpCameraPitch, modeOffsetYaw, lakituDistance, lakituPitch, areaYawChange;
    float panDistance, cannonYOffset;
};

static int16_t set_angle(int16_t angle, struct State *s) {
    if (angle == 1 && !(s->selectionFlags & MODE_MARIO_ACTIVE)) {
        s->selectionFlags |= MODE_MARIO_ACTIVE;
        if (s->movementFlags & MOVE_ZOOMED_OUT) {
            s->selectionFlags |= MODE_LAKITU_WAS_ZOOMED_OUT;
            s->movementFlags &= (uint16_t)~MOVE_ZOOMED_OUT;
        }
        s->soundFlags |= SOUND_MARIO_ACTIVE;
    }
    if (angle == 2 && (s->selectionFlags & MODE_MARIO_ACTIVE)) {
        s->selectionFlags &= (uint16_t)~MODE_MARIO_ACTIVE;
        if (s->selectionFlags & MODE_LAKITU_WAS_ZOOMED_OUT) {
            s->selectionFlags &= (uint16_t)~MODE_LAKITU_WAS_ZOOMED_OUT;
            s->movementFlags |= MOVE_ZOOMED_OUT;
        } else {
            s->movementFlags &= (uint16_t)~MOVE_ZOOMED_OUT;
        }
        s->soundFlags |= SOUND_NORMAL_ACTIVE;
    }
    return (s->selectionFlags & MODE_MARIO_ACTIVE) ? 1 : 2;
}

static int16_t select_alt(int16_t selection, struct State *s) {
    if (selection == 1) {
        s->selectionFlags |= MODE_MARIO_SELECTED;
        s->soundFlags |= SOUND_UNUSED_SELECT_MARIO;
    }
    if (selection == 2 && (s->selectionFlags & MODE_MARIO_SELECTED)) {
        (void)set_angle(2, s);
        s->selectionFlags &= (uint16_t)~MODE_MARIO_SELECTED;
        s->soundFlags |= SOUND_UNUSED_SELECT_FIXED;
    }
    return (s->selectionFlags & MODE_MARIO_SELECTED) ? 1 : 2;
}

static int transition_next(int16_t frames, struct State *s) {
    if (s->statusFlags & FLAG_FRAME_AFTER_CAM_INIT) return 0;
    s->statusFlags |= FLAG_START_TRANSITION | FLAG_TRANSITION_OUT_OF_C_UP;
    s->transitionFramesLeft = frames;
    return 1;
}

static int transition_mode(int16_t new_mode, int16_t frames, struct State *s) {
    if (s->mode == new_mode) return 0;
    s->newMode = (new_mode != -1) ? new_mode : s->lastMode;
    s->lastMode = s->mode;
    s->mode = s->newMode;
    s->movementFlags &= (uint16_t)~(MOVE_RESTRICT | MOVE_ROTATE);
    if (s->statusFlags & FLAG_FRAME_AFTER_CAM_INIT) return 1;
    (void)transition_next(frames, s);
    s->cUpCameraPitch = 0;
    s->modeOffsetYaw = 0;
    s->lakituDistance = 0;
    s->lakituPitch = 0;
    s->areaYawChange = 0;
    s->panDistance = 0.f;
    s->cannonYOffset = 0.f;
    return 1;
}

static uint16_t hud_status(int cutscene, int right_trigger, const struct State *s) {
    int alternate = (s->selectionFlags & MODE_MARIO_SELECTED) ? 1 : 2;
    int angle = (s->selectionFlags & MODE_MARIO_ACTIVE) ? 1 : 2;
    uint16_t status;
    if (cutscene || (right_trigger && alternate == 2)) status = 1 << 2;
    else if (angle == 1) status = 1 << 0;
    else status = 1 << 1;
    if (s->movementFlags & MOVE_ZOOMED_OUT) status |= 1 << 3;
    if (s->movementFlags & 0x2000) status |= 1 << 4;
    return status;
}

static uint64_t hash_state(uint64_t h, const struct State *s) {
    h = h16(h, s->selectionFlags); h = h16(h, s->movementFlags);
    h = h16(h, s->soundFlags); h = h16(h, s->statusFlags);
    h = h16(h, (uint16_t)s->mode); h = h16(h, (uint16_t)s->defaultMode);
    h = h16(h, (uint16_t)s->lastMode); h = h16(h, (uint16_t)s->newMode);
    h = h32(h, (uint32_t)s->transitionFramesLeft);
    h = h16(h, (uint16_t)s->transitionMax); h = h16(h, (uint16_t)s->transitionFrame);
    h = h16(h, (uint16_t)s->cUpCameraPitch); h = h16(h, (uint16_t)s->modeOffsetYaw);
    h = h16(h, (uint16_t)s->lakituDistance); h = h16(h, (uint16_t)s->lakituPitch);
    h = h16(h, (uint16_t)s->areaYawChange); h = hf(h, s->panDistance);
    return hf(h, s->cannonYOffset);
}

static uint64_t hash_selection(uint64_t h, const struct State *s, int16_t selection) {
    h = hash_state(h, s); return h16(h, (uint16_t)selection);
}
static uint64_t hash_angle(uint64_t h, const struct State *s, int16_t angle) {
    h = hash_state(h, s); return h16(h, (uint16_t)angle);
}
static uint64_t hash_mode(uint64_t h, const struct State *s, int changed) {
    h = hash_state(h, s); return h8(h, (uint8_t)(changed != 0));
}

int main(void) {
    struct State seeded = {
        .selectionFlags = 0,
        .movementFlags = MOVE_ZOOMED_OUT | MOVE_ROTATE_RIGHT | MOVE_ENTERED_ROTATE_SURFACE,
        .soundFlags = 0,
        .statusFlags = 0,
        .mode = 1, .defaultMode = 4, .lastMode = 16, .newMode = 0,
        .transitionFramesLeft = 7, .transitionMax = 8, .transitionFrame = 3,
        .cUpCameraPitch = 0x1234, .modeOffsetYaw = -0x2345,
        .lakituDistance = -300, .lakituPitch = 0x123,
        .areaYawChange = -0x456, .panDistance = 12.5f, .cannonYOffset = -3.25f
    };
    uint64_t fingerprint = FNV_OFFSET;
    struct State state = seeded;
    int16_t selected = select_alt(1, &state);
    fingerprint = hash_selection(fingerprint, &state, selected);
    int16_t angle = set_angle(1, &state);
    fingerprint = hash_angle(fingerprint, &state, angle);
    struct State mario_hud_state = state;
    selected = select_alt(2, &state);
    fingerprint = hash_selection(fingerprint, &state, selected);

    state = seeded;
    int changed = transition_mode(16, 12, &state);
    fingerprint = hash_mode(fingerprint, &state, changed);
    struct State unchanged = seeded;
    changed = transition_mode(seeded.mode, 99, &unchanged);
    fingerprint = hash_mode(fingerprint, &unchanged, changed);

    struct State post_init = {
        .selectionFlags = 0,
        .movementFlags = MOVE_ROTATE_LEFT | MOVE_FIX_IN_PLACE,
        .statusFlags = FLAG_FRAME_AFTER_CAM_INIT,
        .mode = 6, .lastMode = 3, .newMode = 6,
        .transitionFramesLeft = 4,
        .cUpCameraPitch = 100, .modeOffsetYaw = -200,
        .lakituDistance = 300, .lakituPitch = 20, .areaYawChange = 4,
        .panDistance = 8, .cannonYOffset = 9
    };
    struct State original_post_init = post_init;
    changed = transition_mode(-1, 20, &post_init);
    fingerprint = hash_mode(fingerprint, &post_init, changed);
    struct State blocked_transition = original_post_init;
    changed = transition_next(20, &blocked_transition);
    fingerprint = hash_mode(fingerprint, &blocked_transition, changed);

    fingerprint = h16(fingerprint, hud_status(0, 0, &mario_hud_state));
    fingerprint = h16(fingerprint, hud_status(1, 0, &seeded));
    seeded.movementFlags |= 0x2000;
    fingerprint = h16(fingerprint, hud_status(0, 0, &seeded));

    printf("cameraModeStateFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    return 0;
}
