#include <stdbool.h>
#include <stdint.h>
#include <string.h>

#include "sm64_modern.h"

#include "../configfile.h"
#include "controller_api.h"
#include "controller_sdl.h"
#include "controller_sm64_modern.h"

#define VK_OFS_MODERN_MOUSE 0x0100u
#define VK_BASE_MODERN_MOUSE (VK_BASE_SDL_GAMEPAD + VK_OFS_MODERN_MOUSE)
// Four stick directions, ten N64 buttons, and MAX_BINDS persisted keys each.
#define MODERN_BIND_GROUP_COUNT 14u
#define MODERN_BIND_CAPACITY (MODERN_BIND_GROUP_COUNT * MAX_BINDS)
// Match the legacy SDL half-axis threshold while consuming normalized input.
#define MODERN_RIGHT_STICK_C_THRESHOLD 0x4000

struct ModernBind {
    uint32_t virtual_key;
    uint32_t mask;
};

static SM64ModernInputApiV1 sInput;
static SM64ModernStatus sInputStatus = SM64_MODERN_STATUS_INVALID_STATE;
static bool sInputInstalled;
static struct ModernBind sBinds[MODERN_BIND_CAPACITY];
static uint32_t sBindCount;
static uint32_t sLastRawKey = VK_INVALID;

// The native core is also linked by standalone C smoke tests.  Keep the
// Swift haptic bridge weak so those tools retain their existing no-device
// behavior while the signed app resolves the symbol from AppleInputService.
extern void sm64_modern_input_rumble_play(void *context, float strength, float duration)
    __attribute__((weak));
extern void sm64_modern_input_rumble_stop(void *context) __attribute__((weak));

static bool snapshot_key_down(const SM64ModernInputSnapshotV1 *snapshot, uint32_t virtual_key) {
    if (virtual_key < VK_BASE_SDL_GAMEPAD) {
        const uint32_t word = virtual_key / 32u;
        const uint32_t bit = virtual_key % 32u;
        return word < SM64_MODERN_INPUT_KEYBOARD_WORD_COUNT
            && (snapshot->keyboard_keys[word] & (1u << bit)) != 0;
    }
    if (virtual_key >= VK_BASE_MODERN_MOUSE
        && virtual_key < VK_BASE_MODERN_MOUSE + SM64_MODERN_INPUT_MOUSE_BUTTON_COUNT) {
        const uint32_t button = virtual_key - VK_BASE_MODERN_MOUSE;
        return (snapshot->mouse_buttons & (1u << button)) != 0;
    }
    if (virtual_key < VK_BASE_SDL_GAMEPAD + SM64_MODERN_INPUT_GAMEPAD_BUTTON_COUNT) {
        const uint32_t button = virtual_key - VK_BASE_SDL_GAMEPAD;
        return (snapshot->gamepad_buttons & (1u << button)) != 0;
    }
    return false;
}

static void add_binds(uint32_t mask, const unsigned int *virtual_keys) {
    for (uint32_t index = 0; index < MAX_BINDS && sBindCount < MODERN_BIND_CAPACITY; ++index) {
        const uint32_t virtual_key = virtual_keys[index];
        const bool keyboard = virtual_key < SM64_MODERN_INPUT_KEYBOARD_WORD_COUNT * 32u;
        const bool gamepad = virtual_key >= VK_BASE_SDL_GAMEPAD
            && virtual_key < VK_BASE_SDL_GAMEPAD + SM64_MODERN_INPUT_GAMEPAD_BUTTON_COUNT;
        const bool mouse = virtual_key >= VK_BASE_MODERN_MOUSE
            && virtual_key < VK_BASE_MODERN_MOUSE + SM64_MODERN_INPUT_MOUSE_BUTTON_COUNT;
        if (keyboard || gamepad || mouse) {
            sBinds[sBindCount++] = (struct ModernBind) { virtual_key, mask };
        }
    }
}

static void bind_controls(void) {
    memset(sBinds, 0, sizeof(sBinds));
    sBindCount = 0;
    add_binds(STICK_UP, configKeyStickUp);
    add_binds(STICK_LEFT, configKeyStickLeft);
    add_binds(STICK_DOWN, configKeyStickDown);
    add_binds(STICK_RIGHT, configKeyStickRight);
    add_binds(A_BUTTON, configKeyA);
    add_binds(B_BUTTON, configKeyB);
    add_binds(Z_TRIG, configKeyZ);
    add_binds(U_CBUTTONS, configKeyCUp);
    add_binds(L_CBUTTONS, configKeyCLeft);
    add_binds(D_CBUTTONS, configKeyCDown);
    add_binds(R_CBUTTONS, configKeyCRight);
    add_binds(L_TRIG, configKeyL);
    add_binds(R_TRIG, configKeyR);
    add_binds(START_BUTTON, configKeyStart);
}

static SM64ModernStatus validate_snapshot(const SM64ModernInputSnapshotV1 *snapshot) {
    if (snapshot->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (snapshot->header.struct_size < sizeof(*snapshot)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    if (snapshot->reserved != 0) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_validate_input_api(const SM64ModernInputApiV1 *input) {
    if (!input) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (input->header.abi_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (input->header.struct_size < sizeof(*input)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    return input->read ? SM64_MODERN_STATUS_OK : SM64_MODERN_STATUS_INVALID_ARGUMENT;
}

SM64ModernStatus sm64_modern_install_input_api(const SM64ModernInputApiV1 *input) {
    const SM64ModernStatus status = sm64_modern_validate_input_api(input);
    if (status != SM64_MODERN_STATUS_OK) {
        return status;
    }
    if (sInputInstalled) {
        return SM64_MODERN_STATUS_INVALID_STATE;
    }
    memcpy(&sInput, input, sizeof(sInput));
    sInputInstalled = true;
    sInputStatus = SM64_MODERN_STATUS_OK;
    sLastRawKey = VK_INVALID;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_uninstall_input_api(void) {
    memset(&sInput, 0, sizeof(sInput));
    sInputInstalled = false;
    sInputStatus = SM64_MODERN_STATUS_INVALID_STATE;
    sLastRawKey = VK_INVALID;
}

SM64ModernStatus sm64_modern_input_status(void) {
    return sInputInstalled ? sInputStatus : SM64_MODERN_STATUS_INVALID_STATE;
}

static void modern_init(void) {
    bind_controls();
}

static void modern_read(OSContPad *pad) {
    if (!sInputInstalled || sInputStatus != SM64_MODERN_STATUS_OK) {
        return;
    }

    SM64ModernInputSnapshotV1 snapshot;
    memset(&snapshot, 0, sizeof(snapshot));
    snapshot.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    snapshot.header.struct_size = sizeof(snapshot);
    snapshot.last_virtual_key = SM64_MODERN_INPUT_NO_KEY;

    sInputStatus = sInput.read(sInput.context, &snapshot);
    if (sInputStatus != SM64_MODERN_STATUS_OK) {
        return;
    }
    sInputStatus = validate_snapshot(&snapshot);
    if (sInputStatus != SM64_MODERN_STATUS_OK) {
        return;
    }

    uint32_t buttons_down = 0;
    for (uint32_t index = 0; index < sBindCount; ++index) {
        if (snapshot_key_down(&snapshot, sBinds[index].virtual_key)) {
            buttons_down |= sBinds[index].mask;
        }
    }
    pad->button |= buttons_down;

    const uint32_t digital_x = buttons_down & STICK_XMASK;
    const uint32_t digital_y = buttons_down & STICK_YMASK;
    if (digital_x == STICK_LEFT) pad->stick_x = -128;
    else if (digital_x == STICK_RIGHT) pad->stick_x = 127;
    if (digital_y == STICK_DOWN) pad->stick_y = -128;
    else if (digital_y == STICK_UP) pad->stick_y = 127;

    // GameController already applies device deadzone and saturation. Preserve
    // that normalized result instead of layering the SDL backend's deadzone.
    if (snapshot.left_stick_x != 0 || snapshot.left_stick_y != 0) {
        pad->stick_x = (s8) (snapshot.left_stick_x / 256);
        pad->stick_y = (s8) (snapshot.left_stick_y / 256);
    }
    pad->ext_stick_x = (s8) (snapshot.right_stick_x / 256);
    pad->ext_stick_y = (s8) (snapshot.right_stick_y / 256);

    if (snapshot.right_stick_x < -MODERN_RIGHT_STICK_C_THRESHOLD) pad->button |= L_CBUTTONS;
    if (snapshot.right_stick_x > MODERN_RIGHT_STICK_C_THRESHOLD) pad->button |= R_CBUTTONS;
    if (snapshot.right_stick_y > MODERN_RIGHT_STICK_C_THRESHOLD) pad->button |= U_CBUTTONS;
    if (snapshot.right_stick_y < -MODERN_RIGHT_STICK_C_THRESHOLD) pad->button |= D_CBUTTONS;

    if (snapshot.last_virtual_key != SM64_MODERN_INPUT_NO_KEY) {
        sLastRawKey = snapshot.last_virtual_key;
    }
}

static u32 modern_rawkey(void) {
    const u32 key = sLastRawKey;
    sLastRawKey = VK_INVALID;
    return key;
}

static void modern_rumble_play(float strength, float duration) {
    if (sInputInstalled && sm64_modern_input_rumble_play) {
        sm64_modern_input_rumble_play(sInput.context, strength, duration);
    }
}

static void modern_rumble_stop(void) {
    if (sInputInstalled && sm64_modern_input_rumble_stop) {
        sm64_modern_input_rumble_stop(sInput.context);
    }
}

static void modern_shutdown(void) {
    sLastRawKey = VK_INVALID;
}

struct ControllerAPI controller_sm64_modern = {
    0,
    modern_init,
    modern_read,
    modern_rawkey,
    modern_rumble_play,
    modern_rumble_stop,
    bind_controls,
    modern_shutdown,
};
