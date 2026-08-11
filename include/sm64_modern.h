#ifndef SM64_MODERN_H
#define SM64_MODERN_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define SM64_MODERN_ABI_VERSION_1 1u
#define SM64_MODERN_PATH_MAX 1024u
#define SM64_MODERN_WINDOW_TITLE_MAX 96u
#define SM64_MODERN_INPUT_KEYBOARD_WORD_COUNT 16u
#define SM64_MODERN_INPUT_GAMEPAD_BUTTON_COUNT 32u
#define SM64_MODERN_INPUT_MOUSE_BUTTON_COUNT 8u
#define SM64_MODERN_INPUT_NO_KEY UINT32_MAX

typedef uint32_t SM64ModernStatus;

#define SM64_MODERN_STATUS_OK 0u
#define SM64_MODERN_STATUS_INVALID_ARGUMENT 1u
#define SM64_MODERN_STATUS_UNSUPPORTED_VERSION 2u
#define SM64_MODERN_STATUS_BUFFER_TOO_SMALL 3u
#define SM64_MODERN_STATUS_INVALID_STATE 4u
#define SM64_MODERN_STATUS_PLATFORM_ERROR 5u
#define SM64_MODERN_STATUS_OUT_OF_MEMORY 6u
#define SM64_MODERN_STATUS_UNSUPPORTED_AUTHORITY 7u
#define SM64_MODERN_STATUS_STOP_REQUESTED 8u
#define SM64_MODERN_STATUS_END_OF_STREAM 9u
#define SM64_MODERN_STATUS_PARITY_DIVERGED 10u

typedef uint32_t SM64ModernLifecycleState;

#define SM64_MODERN_LIFECYCLE_COLD 0u
#define SM64_MODERN_LIFECYCLE_INITIALIZING 1u
#define SM64_MODERN_LIFECYCLE_RUNNING 2u
#define SM64_MODERN_LIFECYCLE_STOP_REQUESTED 3u
#define SM64_MODERN_LIFECYCLE_STOPPED 4u
#define SM64_MODERN_LIFECYCLE_FAILED 5u

typedef uint32_t SM64ModernFullscreenMode;

#define SM64_MODERN_FULLSCREEN_CONFIG 0u
#define SM64_MODERN_FULLSCREEN_FORCE_ON 1u
#define SM64_MODERN_FULLSCREEN_FORCE_OFF 2u

typedef uint32_t SM64ModernExitReason;

#define SM64_MODERN_EXIT_USER_REQUESTED 1u
#define SM64_MODERN_EXIT_GAME_REQUESTED 2u
#define SM64_MODERN_EXIT_PLATFORM_REQUESTED 3u

typedef uint32_t SM64ModernPlatformCapabilities;

#define SM64_MODERN_PLATFORM_CAP_RENDERING (1u << 0)
#define SM64_MODERN_PLATFORM_CAP_AUDIO (1u << 1)
#define SM64_MODERN_PLATFORM_CAP_INPUT (1u << 2)

typedef uint32_t SM64ModernAuthority;

#define SM64_MODERN_AUTHORITY_C 0u
#define SM64_MODERN_AUTHORITY_SHADOW_SWIFT 1u
#define SM64_MODERN_AUTHORITY_SWIFT 2u

typedef uint32_t SM64ModernGameplaySubsystem;

#define SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL 0u
#define SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO 1u
#define SM64_MODERN_GAMEPLAY_SUBSYSTEM_INTERACTION 2u
#define SM64_MODERN_GAMEPLAY_SUBSYSTEM_CAMERA 3u
#define SM64_MODERN_GAMEPLAY_SUBSYSTEM_ACTOR_BOBOMB_BATTLEFIELD 4u
#define SM64_MODERN_GAMEPLAY_SUBSYSTEM_ACTOR_JOLLY_ROGER_BAY 5u
#define SM64_MODERN_GAMEPLAY_SUBSYSTEM_ACTOR_BOWSER_ONE 6u
#define SM64_MODERN_GAMEPLAY_SUBSYSTEM_COUNT 7u
#define SM64_MODERN_GAMEPLAY_SUBSYSTEM_MASK(subsystem) (1u << (subsystem))
#define SM64_MODERN_GAMEPLAY_SUBSYSTEM_MASK_ALL \
    ((1u << SM64_MODERN_GAMEPLAY_SUBSYSTEM_COUNT) - 1u)

typedef uint32_t SM64ModernGameplayRecordKind;

#define SM64_MODERN_GAMEPLAY_RECORD_SNAPSHOT 1u
#define SM64_MODERN_GAMEPLAY_RECORD_EFFECT 2u
#define SM64_MODERN_GAMEPLAY_RECORD_TRACE_HEADER 3u
#define SM64_MODERN_GAMEPLAY_RECORD_INPUT 4u

typedef uint32_t SM64ModernGameplayParityMode;

#define SM64_MODERN_GAMEPLAY_PARITY_OFF 0u
#define SM64_MODERN_GAMEPLAY_PARITY_RECORD 1u
#define SM64_MODERN_GAMEPLAY_PARITY_REPLAY 2u
#define SM64_MODERN_GAMEPLAY_PARITY_SHADOW 3u

#define SM64_MODERN_GAMEPLAY_PARITY_SCHEMA_VERSION 1u

typedef uint32_t SM64ModernGameplayField;

#define SM64_MODERN_FIELD_GLOBAL_TIMER 1u
#define SM64_MODERN_FIELD_LEVEL 2u
#define SM64_MODERN_FIELD_AREA 3u
#define SM64_MODERN_FIELD_ACT 4u
#define SM64_MODERN_FIELD_COURSE 5u
#define SM64_MODERN_FIELD_RANDOM_SEED 6u

#define SM64_MODERN_FIELD_MARIO_INPUT 100u
#define SM64_MODERN_FIELD_MARIO_FLAGS 101u
#define SM64_MODERN_FIELD_MARIO_PARTICLE_FLAGS 102u
#define SM64_MODERN_FIELD_MARIO_ACTION 103u
#define SM64_MODERN_FIELD_MARIO_PREVIOUS_ACTION 104u
#define SM64_MODERN_FIELD_MARIO_ACTION_STATE 105u
#define SM64_MODERN_FIELD_MARIO_ACTION_TIMER 106u
#define SM64_MODERN_FIELD_MARIO_ACTION_ARGUMENT 107u
#define SM64_MODERN_FIELD_MARIO_INTENDED_MAGNITUDE 108u
#define SM64_MODERN_FIELD_MARIO_INTENDED_YAW 109u
#define SM64_MODERN_FIELD_MARIO_FACE_ANGLE 110u
#define SM64_MODERN_FIELD_MARIO_POSITION 111u
#define SM64_MODERN_FIELD_MARIO_VELOCITY 112u
#define SM64_MODERN_FIELD_MARIO_FORWARD_VELOCITY 113u
#define SM64_MODERN_FIELD_MARIO_HEALTH 114u
#define SM64_MODERN_FIELD_MARIO_COINS 115u
#define SM64_MODERN_FIELD_MARIO_STARS 116u

#define SM64_MODERN_FIELD_INTERACTION_TYPES 200u
#define SM64_MODERN_FIELD_INTERACTION_OBJECT 201u
#define SM64_MODERN_FIELD_INTERACTION_HELD_OBJECT 202u
#define SM64_MODERN_FIELD_INTERACTION_USED_OBJECT 203u
#define SM64_MODERN_FIELD_INTERACTION_RIDDEN_OBJECT 204u
#define SM64_MODERN_FIELD_INTERACTION_HURT_COUNTER 205u
#define SM64_MODERN_FIELD_INTERACTION_HEAL_COUNTER 206u

#define SM64_MODERN_FIELD_CAMERA_MODE 300u
#define SM64_MODERN_FIELD_CAMERA_DEFAULT_MODE 301u
#define SM64_MODERN_FIELD_CAMERA_CUTSCENE 302u
#define SM64_MODERN_FIELD_CAMERA_YAW 303u
#define SM64_MODERN_FIELD_CAMERA_NEXT_YAW 304u
#define SM64_MODERN_FIELD_CAMERA_FOCUS 305u
#define SM64_MODERN_FIELD_CAMERA_POSITION 306u

#define SM64_MODERN_FIELD_ACTOR_BEHAVIOR 400u
#define SM64_MODERN_FIELD_ACTOR_ACTIVE_FLAGS 401u
#define SM64_MODERN_FIELD_ACTOR_ACTION 402u
#define SM64_MODERN_FIELD_ACTOR_SUB_ACTION 403u
#define SM64_MODERN_FIELD_ACTOR_TIMER 404u
#define SM64_MODERN_FIELD_ACTOR_POSITION 405u
#define SM64_MODERN_FIELD_ACTOR_VELOCITY 406u
#define SM64_MODERN_FIELD_ACTOR_MOVE_ANGLE 407u
#define SM64_MODERN_FIELD_ACTOR_MOVE_FLAGS 408u
#define SM64_MODERN_FIELD_ACTOR_INTERACTION_STATUS 409u

typedef uint32_t SM64ModernGameplayEffect;

#define SM64_MODERN_EFFECT_SOUND 1u
#define SM64_MODERN_EFFECT_RUMBLE_START 2u
#define SM64_MODERN_EFFECT_RUMBLE_STOP 3u
#define SM64_MODERN_EFFECT_OBJECT_SPAWN 4u
#define SM64_MODERN_EFFECT_OBJECT_DESPAWN 5u
#define SM64_MODERN_EFFECT_PCM_CHECKSUM 6u

typedef uint32_t SM64ModernGameplayDivergenceReason;

#define SM64_MODERN_DIVERGENCE_NONE 0u
#define SM64_MODERN_DIVERGENCE_TRACE_HEADER 1u
#define SM64_MODERN_DIVERGENCE_RECORD_MISSING 2u
#define SM64_MODERN_DIVERGENCE_RECORD_EXTRA 3u
#define SM64_MODERN_DIVERGENCE_RECORD_KIND 4u
#define SM64_MODERN_DIVERGENCE_RECORD_ID 5u
#define SM64_MODERN_DIVERGENCE_SUBJECT 6u
#define SM64_MODERN_DIVERGENCE_SEQUENCE 7u
#define SM64_MODERN_DIVERGENCE_VALUE_COUNT 8u
#define SM64_MODERN_DIVERGENCE_VALUE 9u
#define SM64_MODERN_DIVERGENCE_CANDIDATE_MISSING 10u
#define SM64_MODERN_DIVERGENCE_CANDIDATE_EXTRA 11u
#define SM64_MODERN_DIVERGENCE_SUBSYSTEM 12u

typedef struct SM64ModernAbiHeader {
    uint32_t abi_version;
    uint32_t struct_size;
} SM64ModernAbiHeader;

typedef struct SM64ModernLifecycleConfigV1 {
    SM64ModernAbiHeader header;
    uint64_t main_pool_size;
    uint32_t fullscreen_mode;
    uint32_t skip_intro;
    char game_directory[SM64_MODERN_PATH_MAX];
    char save_directory[SM64_MODERN_PATH_MAX];
    char config_file[SM64_MODERN_PATH_MAX];
    char window_title[SM64_MODERN_WINDOW_TITLE_MAX];
} SM64ModernLifecycleConfigV1;

typedef SM64ModernStatus (*SM64ModernPlatformInitializeFn)(void *context, const char *window_title);
typedef void (*SM64ModernPlatformShutdownFn)(void *context);
typedef int32_t (*SM64ModernPlatformAudioBufferedFn)(void *context);
typedef uint32_t (*SM64ModernPlatformAudioDesiredFn)(void *context);
typedef void (*SM64ModernPlatformAudioPlayFn)(void *context, const int16_t *samples, uint32_t frame_count);
typedef uint64_t (*SM64ModernPlatformCurrentThreadFn)(void *context);
typedef void (*SM64ModernPlatformExitRequestedFn)(void *context, SM64ModernExitReason reason);
typedef void (*SM64ModernPlatformErrorFn)(void *context, SM64ModernStatus status, const char *message);

typedef struct SM64ModernPlatformApiV1 {
    SM64ModernAbiHeader header;
    SM64ModernPlatformCapabilities capabilities;
    uint32_t reserved;
    void *context;
    SM64ModernPlatformInitializeFn initialize;
    SM64ModernPlatformShutdownFn shutdown;
    SM64ModernPlatformAudioBufferedFn audio_buffered;
    SM64ModernPlatformAudioDesiredFn audio_desired_buffered;
    SM64ModernPlatformAudioPlayFn audio_play;
    SM64ModernPlatformCurrentThreadFn current_thread;
    SM64ModernPlatformExitRequestedFn exit_requested;
    SM64ModernPlatformErrorFn error_reported;
} SM64ModernPlatformApiV1;

// Input crosses the Swift/C boundary as physical state in the legacy virtual
// key namespace. The C controller adapter remains authoritative for bindings
// and N64 pad conversion, so existing configuration files keep their meaning.
typedef struct SM64ModernInputSnapshotV1 {
    SM64ModernAbiHeader header;
    uint32_t keyboard_keys[SM64_MODERN_INPUT_KEYBOARD_WORD_COUNT];
    uint32_t gamepad_buttons;
    uint32_t mouse_buttons;
    int16_t left_stick_x;
    int16_t left_stick_y;
    int16_t right_stick_x;
    int16_t right_stick_y;
    uint32_t last_virtual_key;
    uint32_t reserved;
} SM64ModernInputSnapshotV1;

typedef SM64ModernStatus (*SM64ModernInputReadFn)(void *context,
                                                   SM64ModernInputSnapshotV1 *out_snapshot);

typedef struct SM64ModernInputApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernInputReadFn read;
} SM64ModernInputApiV1;

// The native renderer is installed from the platform initialize callback, on
// the lifecycle owner thread. Every pointer passed to a callback is borrowed
// for that callback only; hosts must copy scene and texture data synchronously.
typedef SM64ModernStatus (*SM64ModernRenderInitializeFn)(void *context,
                                                         uint32_t filtering_mode);
typedef void (*SM64ModernRenderShutdownFn)(void *context);
typedef SM64ModernStatus (*SM64ModernRenderCreateShaderFn)(void *context,
                                                           uint32_t shader_id,
                                                           uint32_t filtering_mode,
                                                           uint32_t num_inputs,
                                                           uint32_t used_texture_mask);
typedef void (*SM64ModernRenderSelectShaderFn)(void *context, uint32_t shader_id);
typedef SM64ModernStatus (*SM64ModernRenderCreateTextureFn)(void *context,
                                                            uint32_t texture_id);
typedef void (*SM64ModernRenderSelectTextureFn)(void *context,
                                                uint32_t tile,
                                                uint32_t texture_id);
typedef SM64ModernStatus (*SM64ModernRenderUploadTextureFn)(void *context,
                                                            uint32_t tile,
                                                            uint32_t texture_id,
                                                            const uint8_t *rgba8,
                                                            uint32_t width,
                                                            uint32_t height);
typedef void (*SM64ModernRenderSetSamplerFn)(void *context,
                                             uint32_t tile,
                                             uint32_t texture_id,
                                             uint32_t linear_filter,
                                             uint32_t cms,
                                             uint32_t cmt);
typedef void (*SM64ModernRenderSetBoolStateFn)(void *context, uint32_t enabled);
typedef void (*SM64ModernRenderSetRectFn)(void *context,
                                          int32_t x,
                                          int32_t y,
                                          int32_t width,
                                          int32_t height);
typedef SM64ModernStatus (*SM64ModernRenderDrawTrianglesFn)(void *context,
                                                            const float *vertices,
                                                            uint32_t float_count,
                                                            uint32_t triangle_count);
typedef SM64ModernStatus (*SM64ModernRenderFrameFn)(void *context);
typedef void (*SM64ModernRenderGetDimensionsFn)(void *context,
                                                uint32_t *out_width,
                                                uint32_t *out_height);

typedef struct SM64ModernRenderingApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernRenderInitializeFn initialize;
    SM64ModernRenderShutdownFn shutdown;
    SM64ModernRenderCreateShaderFn create_shader;
    SM64ModernRenderSelectShaderFn select_shader;
    SM64ModernRenderCreateTextureFn create_texture;
    SM64ModernRenderSelectTextureFn select_texture;
    SM64ModernRenderUploadTextureFn upload_texture;
    SM64ModernRenderSetSamplerFn set_sampler_parameters;
    SM64ModernRenderSetBoolStateFn set_depth_test;
    SM64ModernRenderSetBoolStateFn set_depth_mask;
    SM64ModernRenderSetBoolStateFn set_zmode_decal;
    SM64ModernRenderSetRectFn set_viewport;
    SM64ModernRenderSetRectFn set_scissor;
    SM64ModernRenderSetBoolStateFn set_use_alpha;
    SM64ModernRenderDrawTrianglesFn draw_triangles;
    SM64ModernRenderFrameFn start_frame;
    SM64ModernRenderFrameFn end_frame;
    SM64ModernRenderFrameFn finish_render;
    SM64ModernRenderGetDimensionsFn get_dimensions;
} SM64ModernRenderingApiV1;

typedef struct SM64ModernGameplayRecordEnvelopeV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t subsystem;
    SM64ModernGameplayRecordKind record_kind;
    uint32_t payload_size;
    uint32_t reserved;
} SM64ModernGameplayRecordEnvelopeV1;

#define SM64_MODERN_GAMEPLAY_RECORD_VALUE_CAPACITY 4u

// All trace values use fixed-width canonical encodings. Floating-point values
// cross the ABI as their IEEE-754 bit pattern, and object identities are stable
// one-based object-pool slots rather than process addresses.
typedef struct SM64ModernGameplayTraceRecordV1 {
    SM64ModernGameplayRecordEnvelopeV1 envelope;
    uint32_t record_id;
    uint32_t subject_id;
    uint32_t sequence;
    uint32_t value_count;
    uint64_t values[SM64_MODERN_GAMEPLAY_RECORD_VALUE_CAPACITY];
    uint64_t canonical_hash;
} SM64ModernGameplayTraceRecordV1;

typedef SM64ModernGameplayTraceRecordV1 SM64ModernGameplayInputRecordV1;
typedef SM64ModernGameplayTraceRecordV1 SM64ModernGameplaySnapshotRecordV1;
typedef SM64ModernGameplayTraceRecordV1 SM64ModernGameplayEffectRecordV1;

typedef struct SM64ModernGameplayParityConfigV1 {
    SM64ModernAbiHeader header;
    SM64ModernGameplayParityMode mode;
    uint32_t subsystem_mask;
    uint64_t build_fingerprint;
    uint64_t initial_state_fingerprint;
} SM64ModernGameplayParityConfigV1;

typedef SM64ModernStatus (*SM64ModernGameplayTraceWriteFn)(
    void *context,
    const SM64ModernGameplayTraceRecordV1 *record);
typedef SM64ModernStatus (*SM64ModernGameplayTraceReadFn)(
    void *context,
    SM64ModernGameplayTraceRecordV1 *out_record);

typedef struct SM64ModernGameplayTraceStreamApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernGameplayTraceWriteFn write;
    SM64ModernGameplayTraceReadFn read;
} SM64ModernGameplayTraceStreamApiV1;

typedef struct SM64ModernGameplayParityResultV1 {
    SM64ModernAbiHeader header;
    uint32_t subsystem;
    SM64ModernAuthority authority;
    uint32_t eligible_for_swift;
    SM64ModernStatus status;
    uint64_t expected_records;
    uint64_t actual_records;
    uint64_t candidate_records;
    uint64_t matched_records;
    uint64_t expected_hash;
    uint64_t actual_hash;
    uint64_t candidate_hash;
} SM64ModernGameplayParityResultV1;

typedef struct SM64ModernGameplayDivergenceV1 {
    SM64ModernAbiHeader header;
    SM64ModernGameplayDivergenceReason reason;
    uint32_t subsystem;
    uint64_t simulation_tick;
    uint32_t expected_kind;
    uint32_t actual_kind;
    uint32_t expected_record_id;
    uint32_t actual_record_id;
    uint32_t expected_subject_id;
    uint32_t actual_subject_id;
    uint32_t expected_sequence;
    uint32_t actual_sequence;
    uint32_t value_index;
    uint32_t reserved;
    uint64_t expected_value;
    uint64_t actual_value;
} SM64ModernGameplayDivergenceV1;

typedef struct SM64ModernLifecycleApiV1 {
    SM64ModernAbiHeader header;
    SM64ModernStatus (*initialize)(const SM64ModernLifecycleConfigV1 *config,
                                   const SM64ModernPlatformApiV1 *platform);
    SM64ModernStatus (*step)(void);
    SM64ModernStatus (*request_stop)(SM64ModernExitReason reason);
    SM64ModernStatus (*shutdown)(void);
    SM64ModernStatus (*get_state)(SM64ModernLifecycleState *out_state);
} SM64ModernLifecycleApiV1;

// initialize, step, request_stop, and shutdown are single-owner-thread calls.
// The core copies the versioned lifecycle configuration and platform table
// during initialize and never retains their caller-owned storage.

typedef struct SM64ModernGameplayApiV1 {
    SM64ModernAbiHeader header;
    SM64ModernStatus (*get_authority)(SM64ModernGameplaySubsystem subsystem,
                                      SM64ModernAuthority *out_authority);
    SM64ModernStatus (*set_authority)(SM64ModernGameplaySubsystem subsystem,
                                      SM64ModernAuthority authority);
} SM64ModernGameplayApiV1;

typedef struct SM64ModernGameplayParityApiV1 {
    SM64ModernAbiHeader header;
    SM64ModernStatus (*begin_session)(const SM64ModernGameplayParityConfigV1 *config,
                                      const SM64ModernGameplayTraceStreamApiV1 *stream);
    SM64ModernStatus (*end_session)(void);
    SM64ModernStatus (*get_result)(SM64ModernGameplaySubsystem subsystem,
                                   SM64ModernGameplayParityResultV1 *out_result);
    SM64ModernStatus (*get_first_divergence)(SM64ModernGameplaySubsystem subsystem,
                                             SM64ModernGameplayDivergenceV1 *out_divergence);
    SM64ModernStatus (*submit_candidate_record)(const SM64ModernGameplayTraceRecordV1 *record);
} SM64ModernGameplayParityApiV1;

SM64ModernStatus sm64_modern_get_lifecycle_api(uint32_t requested_version,
                                               uint32_t output_size,
                                               SM64ModernLifecycleApiV1 *out_api);
SM64ModernStatus sm64_modern_validate_platform_api(const SM64ModernPlatformApiV1 *platform);
SM64ModernStatus sm64_modern_validate_input_api(const SM64ModernInputApiV1 *input);
SM64ModernStatus sm64_modern_install_input_api(const SM64ModernInputApiV1 *input);
void sm64_modern_uninstall_input_api(void);
SM64ModernStatus sm64_modern_input_status(void);
SM64ModernStatus sm64_modern_validate_rendering_api(const SM64ModernRenderingApiV1 *rendering);
SM64ModernStatus sm64_modern_install_rendering_api(const SM64ModernRenderingApiV1 *rendering);
void sm64_modern_uninstall_rendering_api(void);
SM64ModernStatus sm64_modern_rendering_status(void);
SM64ModernStatus sm64_modern_get_gameplay_api(uint32_t requested_version,
                                              uint32_t output_size,
                                              SM64ModernGameplayApiV1 *out_api);
SM64ModernStatus sm64_modern_get_gameplay_parity_api(uint32_t requested_version,
                                                     uint32_t output_size,
                                                     SM64ModernGameplayParityApiV1 *out_api);

#ifdef __cplusplus
}
#endif

#endif // SM64_MODERN_H
