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
#define SM64_MODERN_SAVE_FILE_BYTE_COUNT 56u
#define SM64_MODERN_MENU_DATA_BYTE_COUNT 32u
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

#define SM64_MODERN_GAMEPLAY_PARITY_SCHEMA_VERSION 3u

// Schema 4 is the additive whole-engine oracle contract. Schema 3 remains
// readable by the existing bounded gameplay parity harness above; schema 4
// deliberately has its own records so new domains can be added without
// changing the v1 ABI or invalidating existing evidence.
#define SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION 4u
#define SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY 8u

typedef uint32_t SM64ModernOracleTraceMode;

#define SM64_MODERN_ORACLE_TRACE_RECORD 1u
#define SM64_MODERN_ORACLE_TRACE_REPLAY 2u

typedef uint32_t SM64ModernOracleTraceDomain;

#define SM64_MODERN_ORACLE_DOMAIN_GLOBAL 0u
#define SM64_MODERN_ORACLE_DOMAIN_INPUT 1u
#define SM64_MODERN_ORACLE_DOMAIN_MARIO 2u
#define SM64_MODERN_ORACLE_DOMAIN_OBJECT 3u
#define SM64_MODERN_ORACLE_DOMAIN_INTERACTION 4u
#define SM64_MODERN_ORACLE_DOMAIN_CAMERA 5u
#define SM64_MODERN_ORACLE_DOMAIN_SCRIPT 6u
#define SM64_MODERN_ORACLE_DOMAIN_COLLISION 7u
#define SM64_MODERN_ORACLE_DOMAIN_RNG 8u
#define SM64_MODERN_ORACLE_DOMAIN_AUDIO 9u
#define SM64_MODERN_ORACLE_DOMAIN_SAVE 10u
#define SM64_MODERN_ORACLE_DOMAIN_RENDER 11u
#define SM64_MODERN_ORACLE_DOMAIN_EFFECT 12u
#define SM64_MODERN_ORACLE_DOMAIN_COVERAGE 13u
#define SM64_MODERN_ORACLE_TRACE_DOMAIN_COUNT 14u

typedef uint32_t SM64ModernOracleTraceRecordKind;

#define SM64_MODERN_ORACLE_RECORD_STATE 1u
#define SM64_MODERN_ORACLE_RECORD_INPUT 2u
#define SM64_MODERN_ORACLE_RECORD_EVENT 3u
#define SM64_MODERN_ORACLE_RECORD_EFFECT 4u
#define SM64_MODERN_ORACLE_RECORD_AUDIO_PCM 5u
#define SM64_MODERN_ORACLE_RECORD_SAVE_BYTES 6u
#define SM64_MODERN_ORACLE_RECORD_RENDER_PACKET 7u
#define SM64_MODERN_ORACLE_RECORD_COVERAGE 8u

// The native audio owner publishes only a fixed-width receipt at the
// owner-thread pre-device boundary. Raw samples, AVAudio pointers, and the
// realtime render callback never cross this ABI.
#define SM64_MODERN_AUDIO_PCM_SAMPLE_RATE_HZ 32000u
#define SM64_MODERN_AUDIO_PCM_CHANNEL_COUNT 2u
#define SM64_MODERN_AUDIO_PCM_FORMAT_S16_INTERLEAVED_STEREO 1u
#define SM64_MODERN_ORACLE_AUDIO_EVENT_PCM 5u

#define SM64_MODERN_TIMEBASE_RATE_LIMIT 1000u
#define SM64_MODERN_TIMEBASE_MAX_CATCH_UP_LIMIT 8u

// Stable scalar constants used by the bounded v1 Swift gameplay kernels.
// These mirror PR/os_cont.h, sm64.h, object_constants.h, and graph_node.h;
// keeping them in the public contract prevents Swift from importing engine headers.
#define SM64_MODERN_N64_BUTTON_A 0x8000u
#define SM64_MODERN_N64_BUTTON_B 0x4000u
#define SM64_MODERN_N64_BUTTON_Z 0x2000u
#define SM64_MODERN_MARIO_INPUT_A_PRESSED 0x0002u
#define SM64_MODERN_MARIO_INPUT_A_DOWN 0x0080u
#define SM64_MODERN_MARIO_INPUT_B_PRESSED 0x2000u
#define SM64_MODERN_MARIO_INPUT_Z_DOWN 0x4000u
#define SM64_MODERN_MARIO_INPUT_Z_PRESSED 0x8000u
#define SM64_MODERN_BOBOMB_HELD_FREE 0u
#define SM64_MODERN_BOBOMB_HELD_THROWN 2u
#define SM64_MODERN_BOBOMB_HELD_DROPPED 3u
#define SM64_MODERN_BOBOMB_ACTION_PATROL 0
#define SM64_MODERN_BOBOMB_ACTION_LAUNCHED 1
#define SM64_MODERN_BOBOMB_OBJECT_THROW_MATRIX_FLAG 0x8u
#define SM64_MODERN_GRAPH_RENDER_INVISIBLE 0x10u

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
#define SM64_MODERN_FIELD_MARIO_FRAMES_SINCE_A 117u
#define SM64_MODERN_FIELD_MARIO_FRAMES_SINCE_B 118u

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
#define SM64_MODERN_FIELD_ACTOR_HELD_STATE 410u
#define SM64_MODERN_FIELD_ACTOR_FLAGS 411u
#define SM64_MODERN_FIELD_ACTOR_FORWARD_VELOCITY 412u
#define SM64_MODERN_FIELD_ACTOR_GRAPH_FLAGS 413u

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

// Rates are exact rational ticks per second. The simulation rate must be an
// integer multiple of the source product's legacy rate so paired boundaries
// remain exact (for example, two 60 Hz ticks per one 30 Hz legacy tick).
typedef struct SM64ModernTimebaseConfigV1 {
    SM64ModernAbiHeader header;
    uint32_t simulation_rate_numerator;
    uint32_t simulation_rate_denominator;
    uint32_t legacy_rate_numerator;
    uint32_t legacy_rate_denominator;
    uint32_t max_catch_up_steps;
    uint32_t reserved;
} SM64ModernTimebaseConfigV1;

typedef struct SM64ModernTimebaseSnapshotV1 {
    SM64ModernAbiHeader header;
    uint32_t simulation_rate_numerator;
    uint32_t simulation_rate_denominator;
    uint32_t legacy_rate_numerator;
    uint32_t legacy_rate_denominator;
    uint32_t simulation_ticks_per_legacy_tick;
    uint32_t max_catch_up_steps;
    uint64_t fingerprint;
} SM64ModernTimebaseSnapshotV1;

// The Swift configuration owner applies the nine legacy runtime cheat flags
// before lifecycle initialization. The core copies this scalar snapshot into
// its compatibility CheatList; options-menu edits remain live C mutations
// after this startup boundary.
typedef struct SM64ModernCheatStateV1 {
    SM64ModernAbiHeader header;
    uint32_t enabled;
    uint32_t moon_jump;
    uint32_t god_mode;
    uint32_t infinite_lives;
    uint32_t super_speed;
    uint32_t responsive;
    uint32_t exit_anywhere;
    uint32_t huge_mario;
    uint32_t tiny_mario;
} SM64ModernCheatStateV1;

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

// Gameplay slices cross the language boundary as copied scalar state. Float
// fields use their IEEE-754 bit patterns so shadow candidates remain exact.
typedef struct SM64ModernMarioButtonInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t input;
    uint32_t owned_input_mask;
    uint32_t button_pressed;
    uint32_t button_down;
    uint32_t squish_timer;
    uint32_t frames_since_a;
    uint32_t frames_since_b;
    uint32_t reserved;
} SM64ModernMarioButtonInputV1;

typedef struct SM64ModernMarioButtonOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t input;
    uint32_t frames_since_a;
    uint32_t frames_since_b;
    uint32_t reserved;
} SM64ModernMarioButtonOutputV1;

// Bounded Mario ground-speed slice. Only scalar state crosses the boundary;
// slope acceleration, sand, wind, collision, and action transitions remain in
// C. Float fields use IEEE-754 bit patterns and angles are sign-extended N64
// s16 values carried in int32 slots.
typedef struct SM64ModernMarioGroundSpeedInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t intended_magnitude_bits;
    uint32_t forward_velocity_bits;
    uint32_t quicksand_depth_bits;
    uint32_t floor_normal_y_bits;
    int32_t intended_yaw;
    int32_t face_yaw;
    uint32_t floor_is_slow;
    uint32_t responsive_cheat;
    uint32_t cheats_enabled;
    uint32_t reserved;
} SM64ModernMarioGroundSpeedInputV1;

typedef struct SM64ModernMarioGroundSpeedOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t forward_velocity_bits;
    int32_t face_yaw;
    uint32_t reserved;
} SM64ModernMarioGroundSpeedOutputV1;

// Bounded Mario action-entry migration. Pointer-backed surfaces/objects stay
// in C; only the scalar state consumed and produced by the value kernel crosses
// this boundary. Unsupported action families return UNSUPPORTED_AUTHORITY so
// the legacy C entry path remains an explicit compatibility fallback.
typedef struct SM64ModernMarioActionInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t requested_action;
    uint32_t action_argument;
    uint32_t current_action;
    uint32_t flags;
    int32_t floor_class;
    uint32_t facing_downhill;
    uint32_t held_object_present;
    uint32_t ridden_object_present;
    uint32_t squish_timer;
    uint32_t quicksand_depth_bits;
    uint32_t intended_magnitude_bits;
    uint32_t forward_velocity_bits;
    int32_t intended_yaw;
    int32_t face_pitch;
    int32_t face_yaw;
    int32_t face_roll;
    uint32_t velocity_x_bits;
    uint32_t velocity_y_bits;
    uint32_t velocity_z_bits;
    uint32_t position_y_bits;
    uint32_t peak_height_bits;
    uint32_t wall_kick_timer;
    uint32_t hurt_counter;
    uint32_t reserved;
} SM64ModernMarioActionInputV1;

typedef struct SM64ModernMarioActionOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t action;
    uint32_t previous_action;
    uint32_t action_argument;
    uint32_t action_state;
    uint32_t action_timer;
    uint32_t flags;
    uint32_t forward_velocity_bits;
    int32_t face_pitch;
    int32_t face_yaw;
    int32_t face_roll;
    uint32_t velocity_x_bits;
    uint32_t velocity_y_bits;
    uint32_t velocity_z_bits;
    uint32_t wall_kick_timer;
    uint32_t peak_height_bits;
    uint32_t dropped_held_object;
    uint32_t dropped_ridden_object;
    uint32_t hurt_counter;
    uint32_t reserved;
} SM64ModernMarioActionOutputV1;

typedef struct SM64ModernBobombReleaseInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t subject_id;
    uint32_t subsystem;
    uint32_t held_state;
    uint32_t object_flags;
    uint32_t graph_flags;
    uint32_t reserved;
} SM64ModernBobombReleaseInputV1;

typedef struct SM64ModernBobombReleaseOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t held_state;
    int32_t action;
    uint32_t object_flags;
    uint32_t graph_flags;
    uint32_t forward_velocity_bits;
    uint32_t velocity_y_bits;
    uint32_t reserved;
} SM64ModernBobombReleaseOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioButtonUpdateFn)(
    void *context,
    const SM64ModernMarioButtonInputV1 *input,
    SM64ModernMarioButtonOutputV1 *out_output);
typedef SM64ModernStatus (*SM64ModernMarioGroundSpeedUpdateFn)(
    void *context,
    const SM64ModernMarioGroundSpeedInputV1 *input,
    SM64ModernMarioGroundSpeedOutputV1 *out_output);
typedef SM64ModernStatus (*SM64ModernMarioActionUpdateFn)(
    void *context,
    const SM64ModernMarioActionInputV1 *input,
    SM64ModernMarioActionOutputV1 *out_output);
typedef SM64ModernStatus (*SM64ModernBobombReleaseUpdateFn)(
    void *context,
    const SM64ModernBobombReleaseInputV1 *input,
    SM64ModernBobombReleaseOutputV1 *out_output);
struct SM64ModernGameplayTraceRecordV1;
typedef SM64ModernStatus (*SM64ModernGameplayCandidateTransformFn)(
    void *context,
    const struct SM64ModernGameplayTraceRecordV1 *actual,
    struct SM64ModernGameplayTraceRecordV1 *out_candidate);

typedef struct SM64ModernGameplayMigrationApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioButtonUpdateFn update_mario_buttons;
    SM64ModernBobombReleaseUpdateFn update_bobomb_release;
    SM64ModernGameplayCandidateTransformFn transform_candidate;
} SM64ModernGameplayMigrationApiV1;

typedef struct SM64ModernMarioActionApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioActionUpdateFn update;
} SM64ModernMarioActionApiV1;

typedef uint32_t SM64ModernMarioActionCancelFamily;
#define SM64_MODERN_MARIO_ACTION_CANCEL_IDLE 1u

typedef struct SM64ModernMarioActionCancelInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t family;
    uint32_t current_action;
    uint32_t action_argument;
    uint32_t action_state;
    uint32_t input;
    int32_t health;
    uint32_t quicksand_depth_bits;
    uint32_t floor_normal_y_bits;
    uint32_t terrain_is_snow;
    uint32_t held_object_present;
    int32_t intended_yaw;
    uint32_t reserved;
} SM64ModernMarioActionCancelInputV1;

typedef struct SM64ModernMarioActionCancelOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t action;
    uint32_t action_argument;
    int32_t face_yaw;
    uint32_t face_yaw_valid;
    uint32_t should_drop_held_object;
    uint32_t reserved;
} SM64ModernMarioActionCancelOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioActionCancelUpdateFn)(
    void *context,
    const SM64ModernMarioActionCancelInputV1 *input,
    SM64ModernMarioActionCancelOutputV1 *out_output);

typedef struct SM64ModernMarioActionCancelApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioActionCancelUpdateFn update;
} SM64ModernMarioActionCancelApiV1;

typedef struct SM64ModernMarioGroundFloorProbeV1 {
    uint32_t present;
    uint32_t surface_id;
    uint32_t height_bits;
    uint32_t normal_y_bits;
} SM64ModernMarioGroundFloorProbeV1;

typedef struct SM64ModernMarioGroundWallProbeV1 {
    uint32_t present;
    uint32_t surface_id;
    uint32_t normal_x_bits;
    uint32_t normal_z_bits;
    int32_t wall_angle;
} SM64ModernMarioGroundWallProbeV1;

typedef struct SM64ModernMarioGroundQuarterProbeV1 {
    SM64ModernMarioGroundFloorProbeV1 floor;
    uint32_t ceiling_height_bits;
    uint32_t water_level_bits;
    SM64ModernMarioGroundWallProbeV1 upper_wall;
} SM64ModernMarioGroundQuarterProbeV1;

typedef struct SM64ModernMarioGroundStepInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t position_x_bits;
    uint32_t position_y_bits;
    uint32_t position_z_bits;
    uint32_t velocity_x_bits;
    uint32_t velocity_y_bits;
    uint32_t velocity_z_bits;
    SM64ModernMarioGroundFloorProbeV1 floor;
    int32_t face_yaw;
    uint32_t native_step_scale_bits;
    uint32_t riding_shell;
    uint32_t terrain_sound_addend;
    SM64ModernMarioGroundQuarterProbeV1 quarter_probes[4];
    uint32_t reserved;
} SM64ModernMarioGroundStepInputV1;

typedef struct SM64ModernMarioGroundStepOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t position_x_bits;
    uint32_t position_y_bits;
    uint32_t position_z_bits;
    SM64ModernMarioGroundFloorProbeV1 floor;
    uint32_t wall_present;
    uint32_t wall_surface_id;
    uint32_t result;
    uint32_t quarter_steps;
    uint32_t terrain_sound_addend;
    uint32_t reserved;
} SM64ModernMarioGroundStepOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioGroundStepUpdateFn)(
    void *context,
    const SM64ModernMarioGroundStepInputV1 *input,
    SM64ModernMarioGroundStepOutputV1 *out_output);

typedef struct SM64ModernMarioGroundStepApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioGroundStepUpdateFn update;
} SM64ModernMarioGroundStepApiV1;

// Bounded Mario airborne-step migration. Collision queries remain owned by C
// and cross as immutable quarter-step probes; Swift owns the deterministic
// branch order and scalar Mario state transition. Surface types are carried
// explicitly so burning-wall and hangable-ceiling decisions never infer from
// an absent pointer or a platform-specific float recomputation.
typedef struct SM64ModernMarioAirWallProbeV1 {
    uint32_t present;
    uint32_t surface_id;
    uint32_t surface_type;
    uint32_t normal_x_bits;
    uint32_t normal_z_bits;
    int32_t wall_angle;
    uint32_t reserved;
} SM64ModernMarioAirWallProbeV1;

typedef struct SM64ModernMarioAirQuarterProbeV1 {
    SM64ModernMarioGroundFloorProbeV1 floor;
    uint32_t ceiling_height_bits;
    uint32_t water_level_bits;
    SM64ModernMarioAirWallProbeV1 upper_wall;
    SM64ModernMarioAirWallProbeV1 lower_wall;
    SM64ModernMarioGroundFloorProbeV1 ledge_floor;
    uint32_t ledge_position_x_bits;
    uint32_t ledge_position_y_bits;
    uint32_t ledge_position_z_bits;
    int32_t ledge_floor_angle;
    uint32_t ledge_present;
} SM64ModernMarioAirQuarterProbeV1;

typedef struct SM64ModernMarioAirStepInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t position_x_bits;
    uint32_t position_y_bits;
    uint32_t position_z_bits;
    uint32_t velocity_x_bits;
    uint32_t velocity_y_bits;
    uint32_t velocity_z_bits;
    SM64ModernMarioGroundFloorProbeV1 floor;
    int32_t face_pitch;
    int32_t face_yaw;
    int32_t face_roll;
    int32_t floor_angle;
    uint32_t action;
    uint32_t step_arg;
    uint32_t native_step_scale_bits;
    uint32_t riding_shell;
    uint32_t ceil_present;
    uint32_t ceil_type;
    SM64ModernMarioAirQuarterProbeV1 quarter_probes[4];
    uint32_t reserved;
} SM64ModernMarioAirStepInputV1;

typedef struct SM64ModernMarioAirStepOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t position_x_bits;
    uint32_t position_y_bits;
    uint32_t position_z_bits;
    uint32_t velocity_y_bits;
    SM64ModernMarioGroundFloorProbeV1 floor;
    SM64ModernMarioAirWallProbeV1 wall;
    uint32_t result;
    uint32_t quarter_steps;
    uint32_t flags_or;
    int32_t face_pitch;
    int32_t face_yaw;
    int32_t face_roll;
    int32_t floor_angle;
    uint32_t terrain_sound_addend;
    uint32_t reserved;
} SM64ModernMarioAirStepOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioAirStepUpdateFn)(
    void *context,
    const SM64ModernMarioAirStepInputV1 *input,
    SM64ModernMarioAirStepOutputV1 *out_output);

typedef struct SM64ModernMarioAirStepApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioAirStepUpdateFn update;
} SM64ModernMarioAirStepApiV1;

// Bounded submerged collision reducer. C supplies the single water-step
// floor/ceiling/wall query; Swift owns only the branch result and scalar
// position/floor update. Whirlpool/current effects remain in the C caller.
typedef struct SM64ModernMarioWaterFloorProbeV1 {
    uint32_t present;
    uint32_t surface_id;
    uint32_t height_bits;
} SM64ModernMarioWaterFloorProbeV1;

typedef struct SM64ModernMarioWaterWallProbeV1 {
    uint32_t present;
    uint32_t surface_id;
    uint32_t reserved;
} SM64ModernMarioWaterWallProbeV1;

typedef struct SM64ModernMarioWaterStepInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t position_x_bits;
    uint32_t position_y_bits;
    uint32_t position_z_bits;
    uint32_t next_position_x_bits;
    uint32_t next_position_y_bits;
    uint32_t next_position_z_bits;
    SM64ModernMarioWaterFloorProbeV1 current_floor;
    SM64ModernMarioWaterFloorProbeV1 floor;
    uint32_t ceiling_height_bits;
    SM64ModernMarioWaterWallProbeV1 wall;
    uint32_t reserved;
} SM64ModernMarioWaterStepInputV1;

typedef struct SM64ModernMarioWaterStepOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t position_x_bits;
    uint32_t position_y_bits;
    uint32_t position_z_bits;
    SM64ModernMarioWaterFloorProbeV1 floor;
    uint32_t result;
    uint32_t reserved;
} SM64ModernMarioWaterStepOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioWaterStepUpdateFn)(
    void *context,
    const SM64ModernMarioWaterStepInputV1 *input,
    SM64ModernMarioWaterStepOutputV1 *out_output);

typedef struct SM64ModernMarioWaterStepApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioWaterStepUpdateFn update;
} SM64ModernMarioWaterStepApiV1;

typedef uint32_t SM64ModernMarioBonkSoundKind;
#define SM64_MODERN_MARIO_BONK_SOUND_HIT 0u
#define SM64_MODERN_MARIO_BONK_SOUND_BONK 1u
#define SM64_MODERN_MARIO_BONK_SOUND_METAL_BONK 2u

// Shared scalar counterpart of mario_bonk_reflection. C keeps the actual
// sound dispatch and Mario/object pointers; Swift owns only angle reflection,
// optional speed negation, and the derived horizontal velocity values.
typedef struct SM64ModernMarioBonkInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    int32_t face_yaw;
    uint32_t forward_velocity_bits;
    uint32_t velocity_x_bits;
    uint32_t velocity_z_bits;
    uint32_t wall_present;
    int32_t wall_angle;
    uint32_t negate_speed;
    uint32_t metal_cap;
    uint32_t reserved;
} SM64ModernMarioBonkInputV1;

typedef struct SM64ModernMarioBonkOutputV1 {
    SM64ModernAbiHeader header;
    int32_t face_yaw;
    uint32_t forward_velocity_bits;
    uint32_t velocity_x_bits;
    uint32_t velocity_z_bits;
    SM64ModernMarioBonkSoundKind sound_kind;
    uint32_t reserved;
} SM64ModernMarioBonkOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioBonkUpdateFn)(
    void *context,
    const SM64ModernMarioBonkInputV1 *input,
    SM64ModernMarioBonkOutputV1 *out_output);

typedef struct SM64ModernMarioBonkApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioBonkUpdateFn update;
} SM64ModernMarioBonkApiV1;

typedef uint32_t SM64ModernMarioTerrainImpulseFamily;
#define SM64_MODERN_MARIO_TERRAIN_IMPULSE_MOVING_SAND 1u
#define SM64_MODERN_MARIO_TERRAIN_IMPULSE_HORIZONTAL_WIND 2u

// Scalar counterpart of mario_update_moving_sand and
// mario_update_windy_ground. The C caller retains surface/audio effects and
// applies the returned horizontal velocity; Swift owns only deterministic
// impulse arithmetic.
typedef struct SM64ModernMarioTerrainImpulseInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    SM64ModernMarioTerrainImpulseFamily family;
    uint32_t floor_type;
    int32_t force;
    uint32_t moving_action;
    int32_t face_yaw;
    uint32_t forward_velocity_bits;
    uint32_t global_timer;
    uint32_t velocity_x_bits;
    uint32_t velocity_z_bits;
    uint32_t reserved;
} SM64ModernMarioTerrainImpulseInputV1;

typedef struct SM64ModernMarioTerrainImpulseOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t velocity_x_bits;
    uint32_t velocity_z_bits;
    uint32_t applied;
    uint32_t sound_kind;
    uint32_t reserved;
} SM64ModernMarioTerrainImpulseOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioTerrainImpulseUpdateFn)(
    void *context,
    const SM64ModernMarioTerrainImpulseInputV1 *input,
    SM64ModernMarioTerrainImpulseOutputV1 *out_output);

typedef struct SM64ModernMarioTerrainImpulseApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioTerrainImpulseUpdateFn update;
} SM64ModernMarioTerrainImpulseApiV1;

typedef struct SM64ModernMarioQuicksandInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t floor_type;
    uint32_t riding_shell;
    uint32_t quicksand_depth_bits;
    uint32_t sinking_speed_bits;
    uint32_t reserved;
} SM64ModernMarioQuicksandInputV1;

typedef struct SM64ModernMarioQuicksandOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t quicksand_depth_bits;
    uint32_t action;
    uint32_t action_argument;
    uint32_t update_sound_camera;
    uint32_t reserved;
} SM64ModernMarioQuicksandOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioQuicksandUpdateFn)(
    void *context,
    const SM64ModernMarioQuicksandInputV1 *input,
    SM64ModernMarioQuicksandOutputV1 *out_output);

typedef struct SM64ModernMarioQuicksandApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioQuicksandUpdateFn update;
} SM64ModernMarioQuicksandApiV1;

typedef struct SM64ModernMarioSteepPushInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    int32_t floor_angle;
    int32_t face_yaw;
    uint32_t action;
    uint32_t action_argument;
    uint32_t reserved;
} SM64ModernMarioSteepPushInputV1;

typedef struct SM64ModernMarioSteepPushOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t forward_velocity_bits;
    int32_t face_yaw;
    uint32_t action;
    uint32_t action_argument;
    uint32_t reserved;
} SM64ModernMarioSteepPushOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioSteepPushUpdateFn)(
    void *context,
    const SM64ModernMarioSteepPushInputV1 *input,
    SM64ModernMarioSteepPushOutputV1 *out_output);

typedef struct SM64ModernMarioSteepPushApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioSteepPushUpdateFn update;
} SM64ModernMarioSteepPushApiV1;

typedef struct SM64ModernMarioTerrainSoundInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t floor_present;
    uint32_t floor_type;
    uint32_t floor_height_bits;
    uint32_t water_level_bits;
    uint32_t terrain_type;
    uint32_t is_lava_level;
    uint32_t reserved;
} SM64ModernMarioTerrainSoundInputV1;

typedef struct SM64ModernMarioTerrainSoundOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t terrain_sound_addend;
    uint32_t reserved;
} SM64ModernMarioTerrainSoundOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioTerrainSoundUpdateFn)(
    void *context,
    const SM64ModernMarioTerrainSoundInputV1 *input,
    SM64ModernMarioTerrainSoundOutputV1 *out_output);

typedef struct SM64ModernMarioTerrainSoundApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioTerrainSoundUpdateFn update;
} SM64ModernMarioTerrainSoundApiV1;

typedef struct SM64ModernMarioFloorPredicatesInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t floor_present;
    uint32_t floor_type;
    uint32_t terrain_type;
    uint32_t normal_y_bits;
    int32_t floor_angle;
    int32_t face_yaw;
    uint32_t is_crawling;
    int32_t turn_yaw;
    uint32_t forward_velocity_bits;
    uint32_t reserved;
} SM64ModernMarioFloorPredicatesInputV1;

typedef struct SM64ModernMarioFloorPredicatesOutputV1 {
    SM64ModernAbiHeader header;
    int32_t floor_class;
    uint32_t is_slippery;
    uint32_t is_slope;
    uint32_t is_steep;
    uint32_t facing_downhill;
    uint32_t reserved;
} SM64ModernMarioFloorPredicatesOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioFloorPredicatesUpdateFn)(
    void *context,
    const SM64ModernMarioFloorPredicatesInputV1 *input,
    SM64ModernMarioFloorPredicatesOutputV1 *out_output);

typedef struct SM64ModernMarioFloorPredicatesApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioFloorPredicatesUpdateFn update;
} SM64ModernMarioFloorPredicatesApiV1;

typedef struct SM64ModernMarioForwardVelocityInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t forward_velocity_bits;
    int32_t face_yaw;
    uint32_t reserved;
} SM64ModernMarioForwardVelocityInputV1;

typedef struct SM64ModernMarioForwardVelocityOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t forward_velocity_bits;
    uint32_t slide_velocity_x_bits;
    uint32_t slide_velocity_z_bits;
    uint32_t velocity_x_bits;
    uint32_t velocity_z_bits;
    uint32_t reserved;
} SM64ModernMarioForwardVelocityOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioForwardVelocityUpdateFn)(
    void *context,
    const SM64ModernMarioForwardVelocityInputV1 *input,
    SM64ModernMarioForwardVelocityOutputV1 *out_output);

typedef struct SM64ModernMarioForwardVelocityApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioForwardVelocityUpdateFn update;
} SM64ModernMarioForwardVelocityApiV1;

typedef uint32_t SM64ModernMarioVelocityDerivationFamily;
#define SM64_MODERN_MARIO_VELOCITY_FROM_YAW 1u
#define SM64_MODERN_MARIO_VELOCITY_FROM_PITCH_YAW 2u

typedef struct SM64ModernMarioVelocityDerivationInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    SM64ModernMarioVelocityDerivationFamily family;
    uint32_t forward_velocity_bits;
    int32_t face_pitch;
    int32_t face_yaw;
    uint32_t reserved;
} SM64ModernMarioVelocityDerivationInputV1;

typedef struct SM64ModernMarioVelocityDerivationOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t velocity_x_bits;
    uint32_t velocity_y_bits;
    uint32_t velocity_z_bits;
    uint32_t slide_velocity_x_bits;
    uint32_t slide_velocity_z_bits;
    uint32_t reserved;
} SM64ModernMarioVelocityDerivationOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioVelocityDerivationUpdateFn)(
    void *context,
    const SM64ModernMarioVelocityDerivationInputV1 *input,
    SM64ModernMarioVelocityDerivationOutputV1 *out_output);

typedef struct SM64ModernMarioVelocityDerivationApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioVelocityDerivationUpdateFn update;
} SM64ModernMarioVelocityDerivationApiV1;

typedef uint32_t SM64ModernMarioPunchSoundKind;
#define SM64_MODERN_MARIO_PUNCH_SOUND_NONE 0u
#define SM64_MODERN_MARIO_PUNCH_SOUND_YAH 1u
#define SM64_MODERN_MARIO_PUNCH_SOUND_WAH 2u
#define SM64_MODERN_MARIO_PUNCH_SOUND_HOO 3u

typedef struct SM64ModernMarioPunchInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t moving_action;
    uint32_t action_argument;
    int32_t animation_frame;
    uint32_t animation_at_end;
    uint32_t animation_past_end;
    uint32_t b_pressed;
    uint32_t reserved;
} SM64ModernMarioPunchInputV1;

typedef struct SM64ModernMarioPunchOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t action_argument;
    uint32_t animation_id;
    uint32_t transition_action;
    uint32_t flags;
    uint32_t punch_state;
    uint32_t punch_state_valid;
    SM64ModernMarioPunchSoundKind sound_kind;
    uint32_t reserved;
} SM64ModernMarioPunchOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioPunchUpdateFn)(
    void *context,
    const SM64ModernMarioPunchInputV1 *input,
    SM64ModernMarioPunchOutputV1 *out_output);

typedef struct SM64ModernMarioPunchApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioPunchUpdateFn update;
} SM64ModernMarioPunchApiV1;

typedef uint32_t SM64ModernMarioWallResponseSoundKind;
#define SM64_MODERN_MARIO_WALL_SOUND_NONE 0u
#define SM64_MODERN_MARIO_WALL_SOUND_STEP 1u
#define SM64_MODERN_MARIO_WALL_SOUND_MOVING_SLIDE 2u

typedef struct SM64ModernMarioWallResponseInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t start_position_x_bits;
    uint32_t start_position_z_bits;
    uint32_t position_x_bits;
    uint32_t position_z_bits;
    uint32_t velocity_x_bits;
    uint32_t velocity_y_bits;
    uint32_t velocity_z_bits;
    uint32_t forward_velocity_bits;
    int32_t face_yaw;
    int32_t animation_frame;
    uint32_t animation_past_frame1;
    uint32_t animation_past_frame2;
    uint32_t terrain_sound_addend;
    int32_t floor_slope_pitch;
    uint32_t wall_present;
    int32_t wall_angle;
    uint32_t reserved;
} SM64ModernMarioWallResponseInputV1;

typedef struct SM64ModernMarioWallResponseOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t velocity_x_bits;
    uint32_t velocity_y_bits;
    uint32_t velocity_z_bits;
    uint32_t forward_velocity_bits;
    uint32_t flags;
    uint32_t animation_id;
    int32_t animation_acceleration;
    SM64ModernMarioWallResponseSoundKind sound_kind;
    uint32_t particle_dust;
    uint32_t action_state;
    uint32_t action_argument;
    int32_t gfx_pitch;
    int32_t gfx_yaw;
    int32_t gfx_roll;
    uint32_t reserved;
} SM64ModernMarioWallResponseOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioWallResponseUpdateFn)(
    void *context,
    const SM64ModernMarioWallResponseInputV1 *input,
    SM64ModernMarioWallResponseOutputV1 *out_output);

typedef struct SM64ModernMarioWallResponseApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioWallResponseUpdateFn update;
} SM64ModernMarioWallResponseApiV1;

typedef uint32_t SM64ModernMarioWalkSoundKind;
#define SM64_MODERN_MARIO_WALK_SOUND_NONE 0u
#define SM64_MODERN_MARIO_WALK_SOUND_TERRAIN 1u
#define SM64_MODERN_MARIO_WALK_SOUND_TERRAIN_TIPTOE 2u
#define SM64_MODERN_MARIO_WALK_SOUND_QUICKSAND 3u
#define SM64_MODERN_MARIO_WALK_SOUND_METAL 4u
#define SM64_MODERN_MARIO_WALK_SOUND_METAL_TIPTOE 5u

typedef struct SM64ModernMarioWalkAnimationInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t intended_magnitude_bits;
    uint32_t forward_velocity_bits;
    uint32_t quicksand_depth_bits;
    uint32_t action_timer;
    uint32_t animation_past_frame23;
    uint32_t animation_past_frame1;
    uint32_t animation_past_frame2;
    uint32_t metal_cap;
    int32_t walking_pitch;
    int32_t running_pitch;
    uint32_t reserved;
} SM64ModernMarioWalkAnimationInputV1;

typedef struct SM64ModernMarioWalkAnimationOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t animation_id;
    int32_t animation_acceleration;
    uint32_t action_timer;
    int32_t walking_pitch;
    SM64ModernMarioWalkSoundKind sound_kind;
    int32_t sound_frame1;
    int32_t sound_frame2;
    uint32_t reserved;
} SM64ModernMarioWalkAnimationOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioWalkAnimationUpdateFn)(
    void *context,
    const SM64ModernMarioWalkAnimationInputV1 *input,
    SM64ModernMarioWalkAnimationOutputV1 *out_output);

typedef struct SM64ModernMarioWalkAnimationApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioWalkAnimationUpdateFn update;
} SM64ModernMarioWalkAnimationApiV1;

typedef uint32_t SM64ModernMarioHeldWalkVariant;
#define SM64_MODERN_MARIO_HELD_WALK_LIGHT 0u
#define SM64_MODERN_MARIO_HELD_WALK_HEAVY 1u

typedef struct SM64ModernMarioHeldWalkAnimationInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    SM64ModernMarioHeldWalkVariant variant;
    uint32_t intended_magnitude_bits;
    uint32_t forward_velocity_bits;
    uint32_t quicksand_depth_bits;
    uint32_t action_timer;
    uint32_t animation_past_frame1;
    uint32_t animation_past_frame2;
    uint32_t metal_cap;
    uint32_t reserved;
} SM64ModernMarioHeldWalkAnimationInputV1;

typedef struct SM64ModernMarioHeldWalkAnimationOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t animation_id;
    int32_t animation_acceleration;
    uint32_t action_timer;
    SM64ModernMarioWalkSoundKind sound_kind;
    int32_t sound_frame1;
    int32_t sound_frame2;
    uint32_t reserved;
} SM64ModernMarioHeldWalkAnimationOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioHeldWalkAnimationUpdateFn)(
    void *context,
    const SM64ModernMarioHeldWalkAnimationInputV1 *input,
    SM64ModernMarioHeldWalkAnimationOutputV1 *out_output);

typedef struct SM64ModernMarioHeldWalkAnimationApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioHeldWalkAnimationUpdateFn update;
} SM64ModernMarioHeldWalkAnimationApiV1;

typedef struct SM64ModernMarioSlopeAccelerationInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    int32_t floor_class;
    uint32_t terrain_is_slide;
    uint32_t floor_normal_x_bits;
    uint32_t floor_normal_y_bits;
    uint32_t floor_normal_z_bits;
    int32_t floor_angle;
    int32_t face_yaw;
    uint32_t forward_velocity_bits;
    uint32_t action;
    uint32_t reserved;
} SM64ModernMarioSlopeAccelerationInputV1;

typedef struct SM64ModernMarioSlopeAccelerationOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t forward_velocity_bits;
    int32_t slide_yaw;
    uint32_t slide_velocity_x_bits;
    uint32_t slide_velocity_z_bits;
    uint32_t velocity_x_bits;
    uint32_t velocity_y_bits;
    uint32_t velocity_z_bits;
    uint32_t facing_downhill;
    uint32_t floor_is_slope;
    uint32_t floor_is_steep;
    uint32_t update_moving_sand;
    uint32_t update_windy_ground;
    uint32_t reserved;
} SM64ModernMarioSlopeAccelerationOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioSlopeAccelerationUpdateFn)(
    void *context,
    const SM64ModernMarioSlopeAccelerationInputV1 *input,
    SM64ModernMarioSlopeAccelerationOutputV1 *out_output);

typedef struct SM64ModernMarioSlopeAccelerationApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioSlopeAccelerationUpdateFn update;
} SM64ModernMarioSlopeAccelerationApiV1;

typedef struct SM64ModernMarioSlopeDecelerationInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t coefficient_bits;
    int32_t floor_class;
    uint32_t terrain_is_slide;
    uint32_t floor_normal_x_bits;
    uint32_t floor_normal_y_bits;
    uint32_t floor_normal_z_bits;
    int32_t floor_angle;
    int32_t face_yaw;
    uint32_t forward_velocity_bits;
    uint32_t action;
    uint32_t reserved;
} SM64ModernMarioSlopeDecelerationInputV1;

typedef struct SM64ModernMarioSlopeDecelerationOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t stopped;
    uint32_t forward_velocity_bits;
    int32_t slide_yaw;
    uint32_t slide_velocity_x_bits;
    uint32_t slide_velocity_z_bits;
    uint32_t velocity_x_bits;
    uint32_t velocity_y_bits;
    uint32_t velocity_z_bits;
    uint32_t facing_downhill;
    uint32_t floor_is_slope;
    uint32_t floor_is_steep;
    uint32_t update_moving_sand;
    uint32_t update_windy_ground;
    uint32_t reserved;
} SM64ModernMarioSlopeDecelerationOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioSlopeDecelerationUpdateFn)(
    void *context,
    const SM64ModernMarioSlopeDecelerationInputV1 *input,
    SM64ModernMarioSlopeDecelerationOutputV1 *out_output);

typedef struct SM64ModernMarioSlopeDecelerationApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioSlopeDecelerationUpdateFn update;
} SM64ModernMarioSlopeDecelerationApiV1;

typedef struct SM64ModernMarioDeceleratingSpeedInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t forward_velocity_bits;
    int32_t face_yaw;
    uint32_t velocity_y_bits;
    uint32_t reserved;
} SM64ModernMarioDeceleratingSpeedInputV1;

typedef struct SM64ModernMarioDeceleratingSpeedOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t stopped;
    uint32_t forward_velocity_bits;
    uint32_t velocity_x_bits;
    uint32_t velocity_y_bits;
    uint32_t velocity_z_bits;
    uint32_t update_moving_sand;
    uint32_t update_windy_ground;
    uint32_t reserved;
} SM64ModernMarioDeceleratingSpeedOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioDeceleratingSpeedUpdateFn)(
    void *context,
    const SM64ModernMarioDeceleratingSpeedInputV1 *input,
    SM64ModernMarioDeceleratingSpeedOutputV1 *out_output);

typedef struct SM64ModernMarioDeceleratingSpeedApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioDeceleratingSpeedUpdateFn update;
} SM64ModernMarioDeceleratingSpeedApiV1;

typedef struct SM64ModernMarioShellSpeedInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t intended_magnitude_bits;
    int32_t intended_yaw;
    int32_t face_yaw;
    uint32_t forward_velocity_bits;
    uint32_t floor_is_slow;
    uint32_t floor_normal_y_bits;
    int32_t floor_class;
    uint32_t terrain_is_slide;
    uint32_t floor_normal_x_bits;
    uint32_t floor_normal_z_bits;
    int32_t floor_angle;
    uint32_t action;
    uint32_t reserved;
} SM64ModernMarioShellSpeedInputV1;

typedef struct SM64ModernMarioShellSpeedOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t forward_velocity_bits;
    int32_t face_yaw;
    int32_t slide_yaw;
    uint32_t slide_velocity_x_bits;
    uint32_t slide_velocity_z_bits;
    uint32_t velocity_x_bits;
    uint32_t velocity_y_bits;
    uint32_t velocity_z_bits;
    uint32_t facing_downhill;
    uint32_t floor_is_slope;
    uint32_t floor_is_steep;
    uint32_t update_moving_sand;
    uint32_t update_windy_ground;
    uint32_t reserved;
} SM64ModernMarioShellSpeedOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioShellSpeedUpdateFn)(
    void *context,
    const SM64ModernMarioShellSpeedInputV1 *input,
    SM64ModernMarioShellSpeedOutputV1 *out_output);

typedef struct SM64ModernMarioShellSpeedApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioShellSpeedUpdateFn update;
} SM64ModernMarioShellSpeedApiV1;

typedef struct SM64ModernMarioLandingAccelerationInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t friction_factor_bits;
    int32_t floor_class;
    uint32_t terrain_is_slide;
    uint32_t floor_normal_x_bits;
    uint32_t floor_normal_y_bits;
    uint32_t floor_normal_z_bits;
    int32_t floor_angle;
    int32_t face_yaw;
    uint32_t forward_velocity_bits;
    uint32_t action;
    uint32_t reserved;
} SM64ModernMarioLandingAccelerationInputV1;

typedef struct SM64ModernMarioLandingAccelerationOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t stopped;
    uint32_t forward_velocity_bits;
    int32_t slide_yaw;
    uint32_t slide_velocity_x_bits;
    uint32_t slide_velocity_z_bits;
    uint32_t velocity_x_bits;
    uint32_t velocity_y_bits;
    uint32_t velocity_z_bits;
    uint32_t floor_is_slope;
    uint32_t update_moving_sand;
    uint32_t update_windy_ground;
    uint32_t reserved;
} SM64ModernMarioLandingAccelerationOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioLandingAccelerationUpdateFn)(
    void *context,
    const SM64ModernMarioLandingAccelerationInputV1 *input,
    SM64ModernMarioLandingAccelerationOutputV1 *out_output);

typedef struct SM64ModernMarioLandingAccelerationApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioLandingAccelerationUpdateFn update;
} SM64ModernMarioLandingAccelerationApiV1;

// Value-only gravity reducer boundary. Action/flag/input bitfields are copied
// as fixed-width values; the C owner retains Mario/body-state mutation and
// effects while Swift owns the deterministic vertical-velocity reducer.
typedef struct SM64ModernMarioGravityInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t action;
    uint32_t mario_flags;
    uint32_t input;
    int32_t angle_velocity_y;
    uint32_t velocity_y_bits;
    uint32_t unk_c4_bits;
    uint32_t reserved;
} SM64ModernMarioGravityInputV1;

typedef struct SM64ModernMarioGravityOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t velocity_y_bits;
    uint32_t wing_flutter;
    uint32_t reserved;
} SM64ModernMarioGravityOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioGravityUpdateFn)(
    void *context,
    const SM64ModernMarioGravityInputV1 *input,
    SM64ModernMarioGravityOutputV1 *out_output);

typedef struct SM64ModernMarioGravityApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioGravityUpdateFn update;
} SM64ModernMarioGravityApiV1;

typedef struct SM64ModernMarioVerticalWindInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t action;
    uint32_t floor_type;
    uint32_t position_y_bits;
    uint32_t velocity_y_bits;
    uint32_t reserved;
} SM64ModernMarioVerticalWindInputV1;

typedef struct SM64ModernMarioVerticalWindOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t velocity_y_bits;
    uint32_t active;
    uint32_t reserved;
} SM64ModernMarioVerticalWindOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioVerticalWindUpdateFn)(
    void *context,
    const SM64ModernMarioVerticalWindInputV1 *input,
    SM64ModernMarioVerticalWindOutputV1 *out_output);

typedef struct SM64ModernMarioVerticalWindApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioVerticalWindUpdateFn update;
} SM64ModernMarioVerticalWindApiV1;

typedef struct SM64ModernMarioSlidingInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    int32_t floor_class;
    uint32_t floor_is_slope;
    uint32_t floor_normal_x_bits;
    uint32_t floor_normal_y_bits;
    uint32_t floor_normal_z_bits;
    int32_t intended_yaw;
    uint32_t intended_magnitude_bits;
    int32_t face_yaw;
    int32_t slide_yaw;
    uint32_t forward_velocity_bits;
    uint32_t slide_velocity_x_bits;
    uint32_t slide_velocity_z_bits;
    uint32_t stop_speed_bits;
    uint32_t reserved;
} SM64ModernMarioSlidingInputV1;

typedef struct SM64ModernMarioSlidingOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t stopped;
    int32_t face_yaw;
    int32_t slide_yaw;
    uint32_t forward_velocity_bits;
    uint32_t slide_velocity_x_bits;
    uint32_t slide_velocity_z_bits;
    uint32_t velocity_x_bits;
    uint32_t velocity_y_bits;
    uint32_t velocity_z_bits;
    uint32_t update_moving_sand;
    uint32_t update_windy_ground;
    uint32_t reserved;
} SM64ModernMarioSlidingOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioSlidingUpdateFn)(
    void *context,
    const SM64ModernMarioSlidingInputV1 *input,
    SM64ModernMarioSlidingOutputV1 *out_output);

typedef struct SM64ModernMarioSlidingApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioSlidingUpdateFn update;
} SM64ModernMarioSlidingApiV1;

typedef struct SM64ModernMarioGroundDivePunchInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t b_pressed;
    uint32_t forward_velocity_bits;
    uint32_t stick_magnitude_bits;
    uint32_t velocity_y_bits;
    uint32_t reserved;
} SM64ModernMarioGroundDivePunchInputV1;

typedef struct SM64ModernMarioGroundDivePunchOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t triggered;
    uint32_t action;
    uint32_t action_argument;
    uint32_t velocity_y_bits;
    uint32_t reserved;
} SM64ModernMarioGroundDivePunchOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioGroundDivePunchUpdateFn)(
    void *context,
    const SM64ModernMarioGroundDivePunchInputV1 *input,
    SM64ModernMarioGroundDivePunchOutputV1 *out_output);

typedef struct SM64ModernMarioGroundDivePunchApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioGroundDivePunchUpdateFn update;
} SM64ModernMarioGroundDivePunchApiV1;

typedef struct SM64ModernMarioSlidePredicatesInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t input;
    uint32_t terrain_is_slide;
    uint32_t forward_velocity_bits;
    uint32_t facing_downhill;
    int32_t intended_yaw;
    int32_t face_yaw;
    uint32_t reserved;
} SM64ModernMarioSlidePredicatesInputV1;

typedef struct SM64ModernMarioSlidePredicatesOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t should_begin_sliding;
    uint32_t analog_stick_held_back;
    uint32_t reserved;
} SM64ModernMarioSlidePredicatesOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioSlidePredicatesUpdateFn)(
    void *context,
    const SM64ModernMarioSlidePredicatesInputV1 *input,
    SM64ModernMarioSlidePredicatesOutputV1 *out_output);

typedef struct SM64ModernMarioSlidePredicatesApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioSlidePredicatesUpdateFn update;
} SM64ModernMarioSlidePredicatesApiV1;

typedef struct SM64ModernMarioBeginBrakingInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t action_state;
    uint32_t action_argument;
    uint32_t forward_velocity_bits;
    uint32_t floor_normal_y_bits;
    int32_t face_yaw;
    uint32_t reserved;
} SM64ModernMarioBeginBrakingInputV1;

typedef struct SM64ModernMarioBeginBrakingOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t action;
    uint32_t action_argument;
    int32_t face_yaw;
    uint32_t intent;
    uint32_t reserved;
} SM64ModernMarioBeginBrakingOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioBeginBrakingUpdateFn)(
    void *context,
    const SM64ModernMarioBeginBrakingInputV1 *input,
    SM64ModernMarioBeginBrakingOutputV1 *out_output);

typedef struct SM64ModernMarioBeginBrakingApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioBeginBrakingUpdateFn update;
} SM64ModernMarioBeginBrakingApiV1;

typedef struct SM64ModernMarioTripleJumpSelectorInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t mario_flags;
    uint32_t forward_velocity_bits;
    uint32_t reserved;
} SM64ModernMarioTripleJumpSelectorInputV1;

typedef struct SM64ModernMarioTripleJumpSelectorOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t action;
    uint32_t action_argument;
    uint32_t intent;
    uint32_t reserved;
} SM64ModernMarioTripleJumpSelectorOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioTripleJumpSelectorUpdateFn)(
    void *context,
    const SM64ModernMarioTripleJumpSelectorInputV1 *input,
    SM64ModernMarioTripleJumpSelectorOutputV1 *out_output);

typedef struct SM64ModernMarioTripleJumpSelectorApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioTripleJumpSelectorUpdateFn update;
} SM64ModernMarioTripleJumpSelectorApiV1;

typedef struct SM64ModernMarioYVelocityInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t initial_velocity_y_bits;
    uint32_t forward_velocity_bits;
    uint32_t multiplier_bits;
    uint32_t squish_timer;
    uint32_t quicksand_depth_bits;
    uint32_t reserved;
} SM64ModernMarioYVelocityInputV1;

typedef struct SM64ModernMarioYVelocityOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t velocity_y_bits;
    uint32_t half_speed_applied;
    uint32_t reserved;
} SM64ModernMarioYVelocityOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioYVelocityUpdateFn)(
    void *context,
    const SM64ModernMarioYVelocityInputV1 *input,
    SM64ModernMarioYVelocityOutputV1 *out_output);

typedef struct SM64ModernMarioYVelocityApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioYVelocityUpdateFn update;
} SM64ModernMarioYVelocityApiV1;

typedef struct SM64ModernMarioSteepJumpInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    int32_t face_yaw;
    int32_t floor_angle;
    uint32_t forward_velocity_bits;
    uint32_t reserved;
} SM64ModernMarioSteepJumpInputV1;

typedef struct SM64ModernMarioSteepJumpOutputV1 {
    SM64ModernAbiHeader header;
    uint32_t action;
    int32_t steep_jump_yaw;
    uint32_t forward_velocity_bits;
    int32_t face_yaw;
    uint32_t should_drop_held_object;
    uint32_t reserved;
} SM64ModernMarioSteepJumpOutputV1;

typedef SM64ModernStatus (*SM64ModernMarioSteepJumpUpdateFn)(
    void *context,
    const SM64ModernMarioSteepJumpInputV1 *input,
    SM64ModernMarioSteepJumpOutputV1 *out_output);

typedef struct SM64ModernMarioSteepJumpApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioSteepJumpUpdateFn update;
} SM64ModernMarioSteepJumpApiV1;

// Camera selection/angle migration extension.  The full camera geometry and
// cutscene graph remain an explicit C compatibility bridge; this value-only
// boundary lets Swift own the selection flags and their side effects without
// exposing Camera pointers or Lakitu state across the ABI.
typedef uint32_t SM64ModernCameraCommand;

#define SM64_MODERN_CAMERA_COMMAND_SELECT_ALT_MODE 1u
#define SM64_MODERN_CAMERA_COMMAND_SET_ANGLE 2u
#define SM64_MODERN_CAMERA_COMMAND_TRANSITION_NEXT_STATE 3u
#define SM64_MODERN_CAMERA_COMMAND_TRANSITION_TO_MODE 4u

typedef struct SM64ModernCameraStateV1 {
    SM64ModernAbiHeader header;
    SM64ModernCameraCommand command;
    int32_t argument;
    uint16_t selection_flags;
    uint16_t movement_flags;
    uint16_t sound_flags;
    uint16_t status_flags;
    int16_t mode;
    int16_t default_mode;
    int16_t last_mode;
    int16_t new_mode;
    int32_t transition_frames_left;
    int16_t transition_max;
    int16_t transition_frame;
    int16_t c_up_camera_pitch;
    int16_t mode_offset_yaw;
    int16_t lakitu_distance;
    int16_t lakitu_pitch;
    int16_t area_yaw_change;
    float pan_distance;
    float cannon_y_offset;
    int32_t result;
    uint32_t reserved;
} SM64ModernCameraStateV1;

typedef struct SM64ModernCameraCallbackInputV1 {
    SM64ModernAbiHeader header;
    int16_t mode;
    int16_t face_yaw;
    int16_t face_pitch;
    int16_t mode_offset_yaw;
    int16_t lakitu_pitch;
    int16_t eight_direction_base_yaw;
    int16_t eight_direction_yaw_offset;
    float lakitu_distance;
    float zoom_distance;
    float cannon_y_offset;
    float floor_height;
    float water_height;
    float slope_floor_height;
    float slope_floor_normal_z;
    float pole_object_y;
    float pole_hitbox_height;
    int16_t slope_floor_type;
    uint16_t geometry_flags;
    float camera_distance;
    int16_t camera_pitch;
    int16_t camera_yaw;
    uint16_t c_buttons_pressed;
    int16_t side_button_yaw;
    int16_t behind_mario_sound_timer;
    uint16_t state_flags;
    float camera_position[3];
    float camera_focus[3];
    float mario_position[3];
    float area_center[3];
    // Fixed-camera values are populated only for CAMERA_MODE_FIXED. Keeping
    // the collision result and interpolation inputs scalar makes this seam
    // replayable without exposing Camera, Surface, or Lakitu pointers.
    float fixed_base_position[3];
    float fixed_scale_to_mario;
    float fixed_height_offset;
    float fixed_floor_height;
    float fixed_ceiling_height;
    float fixed_goal_height;
    float fixed_focus_floor_offset;
    uint16_t fixed_flags;
    uint16_t reserved1;
    // Boss-camera values are populated only for CAMERA_MODE_BOSS_FIGHT.
    // The second focus and floor result are snapshots; object and surface
    // pointers never cross the ABI.
    float boss_second_focus[3];
    float boss_focus_distance;
    float boss_floor_height;
    float boss_angle_velocity;
    int16_t boss_yaw;
    int16_t boss_held_state;
    uint16_t boss_flags;
    uint16_t reserved2;
    // Spiral-stairs values are populated only for CAMERA_MODE_SPIRAL_STAIRS.
    float spiral_base_position[3];
    float spiral_focus_floor_offset;
    float spiral_floor_height;
    float spiral_current_floor_height;
    uint16_t spiral_flags;
    uint16_t reserved3;
    // Parallel-tracking values are populated only for a stable first path.
    // Path switching remains on the C fallback until its bounded path-window
    // contract is promoted separately.
    float parallel_path_start[3];
    float parallel_path_end[3];
    float parallel_dist_threshold;
    float parallel_zoom;
    float parallel_mario_floor_offset;
    float parallel_transition_offset[3];
    uint16_t parallel_flags;
    uint16_t reserved4;
    uint32_t reserved;
} SM64ModernCameraCallbackInputV1;

typedef struct SM64ModernCameraCallbackOutputV1 {
    SM64ModernAbiHeader header;
    float focus[3];
    float position[3];
    int16_t camera_yaw;
    int16_t returned_yaw;
    int16_t area_yaw;
    int16_t pitch;
    float distance;
    int16_t side_button_yaw;
    int16_t behind_mario_sound_timer;
    uint32_t flags;
    uint32_t reserved;
} SM64ModernCameraCallbackOutputV1;

// Value-only camera FOV/shake evaluation. The C graph callback owns the
// perspective node and sleeping compatibility flag; Swift owns the finite
// FOV function selection, approach, and shake-state update.
typedef struct SM64ModernCameraFOVInputV1 {
    SM64ModernAbiHeader header;
    uint8_t fov_func;
    uint8_t sleeping;
    uint8_t fixed_mode;
    uint8_t cutscene_active;
    float fov;
    float fov_offset;
    float shake_amplitude;
    int16_t shake_phase;
    int16_t shake_speed;
    int16_t decay;
    uint16_t reserved0;
    uint32_t reserved;
} SM64ModernCameraFOVInputV1;

typedef struct SM64ModernCameraFOVOutputV1 {
    SM64ModernAbiHeader header;
    uint8_t fov_func;
    uint8_t sleeping;
    uint8_t fixed_mode;
    uint8_t cutscene_active;
    float fov;
    float fov_offset;
    float shake_amplitude;
    int16_t shake_phase;
    int16_t shake_speed;
    int16_t decay;
    uint16_t reserved0;
    float presented_fov;
    uint32_t reserved;
} SM64ModernCameraFOVOutputV1;

// Fixed-width cutscene spline snapshot. The C adapter supplies the four
// control points at the current segment; Swift advances only the value state
// and returns the evaluated point.
typedef struct SM64ModernCameraCutsceneSplineInputV1 {
    SM64ModernAbiHeader header;
    int16_t segment;
    float progress;
    int8_t point0_index;
    int8_t point1_index;
    int8_t point2_index;
    int8_t point3_index;
    uint8_t point0_speed;
    uint8_t point1_speed;
    uint8_t point2_speed;
    uint8_t point3_speed;
    float point0[3];
    float point1[3];
    float point2[3];
    float point3[3];
    uint32_t reserved;
} SM64ModernCameraCutsceneSplineInputV1;

typedef struct SM64ModernCameraCutsceneSplineOutputV1 {
    SM64ModernAbiHeader header;
    float point[3];
    int16_t segment;
    float progress;
    uint8_t finished;
    uint8_t reserved0;
    uint16_t reserved1;
    uint32_t reserved;
} SM64ModernCameraCutsceneSplineOutputV1;

// Fixed-width per-shot cutscene clock snapshot. C still chooses and executes
// the authored shot; Swift owns only timer/shot advancement and stop semantics.
typedef struct SM64ModernCameraCutsceneClockInputV1 {
    SM64ModernAbiHeader header;
    int16_t cutscene;
    int16_t shot;
    int16_t timer;
    int16_t shot_duration;
    uint8_t cutscene_active;
    uint8_t reserved0;
    uint16_t reserved1;
    uint32_t reserved;
} SM64ModernCameraCutsceneClockInputV1;

typedef struct SM64ModernCameraCutsceneClockOutputV1 {
    SM64ModernAbiHeader header;
    int16_t cutscene;
    int16_t shot;
    int16_t timer;
    uint8_t stopped;
    uint8_t advanced_shot;
    uint16_t reserved0;
    uint32_t reserved;
} SM64ModernCameraCutsceneClockOutputV1;

#define SM64_MODERN_CAMERA_CALLBACK_OUTPUTS_SWAPPED (1u << 0)
#define SM64_MODERN_CAMERA_CALLBACK_PANS_AHEAD (1u << 1)
// Input geometry_flags bits. Optional values remain finite zeroes when the
// corresponding bit is clear; the owner adapter must not infer a live value.
#define SM64_MODERN_CAMERA_CALLBACK_HAS_WATER_HEIGHT (1u << 0)
#define SM64_MODERN_CAMERA_CALLBACK_HAS_POLE_DATA (1u << 1)
#define SM64_MODERN_CAMERA_CALLBACK_IS_METAL_WATER (1u << 2)
#define SM64_MODERN_CAMERA_CALLBACK_IS_ON_POLE (1u << 3)
#define SM64_MODERN_CAMERA_CALLBACK_HAS_SLOPE_FLOOR (1u << 4)
#define SM64_MODERN_CAMERA_CALLBACK_HAS_FIXED_FLOOR (1u << 5)
#define SM64_MODERN_CAMERA_CALLBACK_HAS_FIXED_CEILING (1u << 6)
#define SM64_MODERN_CAMERA_CALLBACK_FIXED_SMOOTH_MOVEMENT (1u << 7)
#define SM64_MODERN_CAMERA_CALLBACK_HAS_BOSS_FLOOR_HEIGHT (1u << 8)
#define SM64_MODERN_CAMERA_CALLBACK_BOSS_FORCE_HEIGHT (1u << 9)
#define SM64_MODERN_CAMERA_CALLBACK_HAS_SPIRAL_FLOOR_HEIGHT (1u << 0)
#define SM64_MODERN_CAMERA_CALLBACK_PARALLEL_READY (1u << 0)
#define SM64_MODERN_CAMERA_CALLBACK_MARIO_MODE_ACTIVE (1u << 0)
#define SM64_MODERN_CAMERA_CALLBACK_WATER_OR_METAL_ACTION (1u << 1)

typedef SM64ModernStatus (*SM64ModernCameraUpdateFn)(
    void *context,
    const SM64ModernCameraStateV1 *input,
    SM64ModernCameraStateV1 *out_state);
typedef SM64ModernStatus (*SM64ModernCameraEvaluateFn)(
    void *context,
    const SM64ModernCameraCallbackInputV1 *input,
    SM64ModernCameraCallbackOutputV1 *out_output);
typedef SM64ModernStatus (*SM64ModernCameraFOVEvaluateFn)(
    void *context,
    const SM64ModernCameraFOVInputV1 *input,
    SM64ModernCameraFOVOutputV1 *out_output);
typedef SM64ModernStatus (*SM64ModernCameraCutsceneSplineEvaluateFn)(
    void *context,
    const SM64ModernCameraCutsceneSplineInputV1 *input,
    SM64ModernCameraCutsceneSplineOutputV1 *out_output);
typedef SM64ModernStatus (*SM64ModernCameraCutsceneClockEvaluateFn)(
    void *context,
    const SM64ModernCameraCutsceneClockInputV1 *input,
    SM64ModernCameraCutsceneClockOutputV1 *out_output);

typedef struct SM64ModernCameraMigrationApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernCameraUpdateFn update;
    SM64ModernCameraEvaluateFn evaluate;
    SM64ModernCameraFOVEvaluateFn evaluate_fov;
    SM64ModernCameraCutsceneSplineEvaluateFn evaluate_cutscene_spline;
    SM64ModernCameraCutsceneClockEvaluateFn evaluate_cutscene_clock;
} SM64ModernCameraMigrationApiV1;

// Audio sequence migration is intentionally a value-only observer boundary.
// The legacy C sequence player and device-facing PCM path remain compatible
// owners until a later milestone proves full synthesis and audible parity;
// this seam lets Swift consume the exact owner-thread sequence/queue events
// without exposing sequence-player pointers or realtime audio state.
typedef uint32_t SM64ModernAudioSequenceEvent;

#define SM64_MODERN_AUDIO_SEQUENCE_EVENT_TICK 1u
#define SM64_MODERN_AUDIO_SEQUENCE_EVENT_SEQUENCE 2u
#define SM64_MODERN_AUDIO_SEQUENCE_EVENT_QUEUE 3u
#define SM64_MODERN_AUDIO_SEQUENCE_EVENT_SECONDARY 4u
#define SM64_MODERN_AUDIO_SEQUENCE_EVENT_FIRST \
    SM64_MODERN_AUDIO_SEQUENCE_EVENT_TICK
#define SM64_MODERN_AUDIO_SEQUENCE_EVENT_LAST \
    SM64_MODERN_AUDIO_SEQUENCE_EVENT_SECONDARY

typedef struct SM64ModernAudioSequenceEventV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    SM64ModernAudioSequenceEvent event_id;
    uint32_t value_count;
    uint64_t values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY];
    uint32_t reserved;
} SM64ModernAudioSequenceEventV1;

typedef SM64ModernStatus (*SM64ModernAudioSequenceObserveFn)(
    void *context,
    const SM64ModernAudioSequenceEventV1 *event);

typedef struct SM64ModernAudioMigrationApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernAudioSequenceObserveFn observe_sequence_event;
} SM64ModernAudioMigrationApiV1;

typedef struct SM64ModernAudioPCMReceiptV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t frame_count;
    uint32_t sample_rate_hz;
    uint32_t channel_count;
    uint32_t sample_format;
    uint32_t sequence;
    uint32_t reserved;
    uint64_t pcm_hash;
} SM64ModernAudioPCMReceiptV1;

typedef SM64ModernStatus (*SM64ModernAudioPCMObserveFn)(
    void *context,
    const SM64ModernAudioPCMReceiptV1 *receipt);

typedef struct SM64ModernAudioPCMMigrationApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernAudioPCMObserveFn observe_pcm_receipt;
} SM64ModernAudioPCMMigrationApiV1;

// The native owner publishes effects as fixed-width values at the existing
// owner-thread gateways.  This observer never receives C objects, behavior
// pointers, PCM bytes, or AVAudio state; it only receives the exact schema-4
// effect fields that are already about to be recorded.
typedef struct SM64ModernEffectReceiptV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint64_t subject_id;
    uint64_t effect_id;
    uint32_t sequence;
    uint32_t value_count;
    uint32_t flags;
    uint32_t reserved;
    uint64_t values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY];
    uint64_t canonical_hash;
} SM64ModernEffectReceiptV1;

typedef SM64ModernStatus (*SM64ModernEffectObserveFn)(
    void *context,
    const SM64ModernEffectReceiptV1 *receipt);

typedef struct SM64ModernEffectsMigrationApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernEffectObserveFn observe_effect;
} SM64ModernEffectsMigrationApiV1;

// The native text owner publishes only a fixed-width source/text receipt at
// the authored save-menu text writer.  The source path and payload identity
// are deterministic hashes; no C strings, FILE pointers, or save buffers
// cross this observer boundary.
typedef uint32_t SM64ModernTextEventKind;

#define SM64_MODERN_TEXT_EVENT_SAVE_WRITE 1u
#define SM64_MODERN_TEXT_ORACLE_EVENT_LIFECYCLE 5u

typedef struct SM64ModernTextReceiptV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint64_t source_identity;
    uint64_t text_identity;
    uint64_t payload_hash;
    uint32_t event_id;
    uint32_t file_index;
    uint32_t sequence;
    uint32_t reserved;
    uint64_t canonical_hash;
} SM64ModernTextReceiptV1;

typedef SM64ModernStatus (*SM64ModernTextObserveFn)(
    void *context,
    const SM64ModernTextReceiptV1 *receipt);

typedef struct SM64ModernTextMigrationApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernTextObserveFn observe_text;
} SM64ModernTextMigrationApiV1;

// Global-state migration is an owner-thread observer boundary. The C game
// remains authoritative for the legacy timer, level/area/act/course lifecycle,
// and process-global random seed; Swift receives this fixed-width snapshot at
// the exact capture boundary without importing C globals or pointers.
typedef struct SM64ModernGlobalStateSnapshotV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t global_timer;
    uint32_t level_number;
    uint32_t area_index;
    uint32_t act_number;
    uint32_t course_number;
    uint32_t random_seed;
    uint32_t reserved;
} SM64ModernGlobalStateSnapshotV1;

typedef SM64ModernStatus (*SM64ModernGlobalStateObserveFn)(
    void *context,
    const SM64ModernGlobalStateSnapshotV1 *snapshot);

typedef struct SM64ModernGlobalStateMigrationApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernGlobalStateObserveFn observe_snapshot;
} SM64ModernGlobalStateMigrationApiV1;

// Front-end/menu migration is currently a value-only observer boundary.  The
// legacy C menu still owns live menu state, text rendering, save-slot writes,
// and transition side effects; Swift receives the same owner-thread input and
// advances a replayable model without importing C menu pointers or globals.
typedef uint32_t SM64ModernFrontEndScreen;

#define SM64_MODERN_FRONT_END_SCREEN_TITLE 0u
#define SM64_MODERN_FRONT_END_SCREEN_FILE_SELECT 1u
#define SM64_MODERN_FRONT_END_SCREEN_COURSE_SELECT 2u
#define SM64_MODERN_FRONT_END_SCREEN_LEVEL_SELECT 3u
#define SM64_MODERN_FRONT_END_SCREEN_DEMO 4u
#define SM64_MODERN_FRONT_END_SCREEN_GAMEPLAY 5u
#define SM64_MODERN_FRONT_END_SCREEN_CREDITS 6u
#define SM64_MODERN_FRONT_END_SCREEN_ENDING 7u

typedef uint32_t SM64ModernFrontEndTransition;

#define SM64_MODERN_FRONT_END_TRANSITION_NONE 0u
#define SM64_MODERN_FRONT_END_TRANSITION_OPEN_FILE_SELECT 1u
#define SM64_MODERN_FRONT_END_TRANSITION_OPEN_COURSE_SELECT 2u
#define SM64_MODERN_FRONT_END_TRANSITION_START_LEVEL 3u
#define SM64_MODERN_FRONT_END_TRANSITION_OPEN_LEVEL_SELECT 4u
#define SM64_MODERN_FRONT_END_TRANSITION_START_DEMO 5u
#define SM64_MODERN_FRONT_END_TRANSITION_RETURN_TO_TITLE 6u
#define SM64_MODERN_FRONT_END_TRANSITION_OPEN_CREDITS 7u
#define SM64_MODERN_FRONT_END_TRANSITION_OPEN_ENDING 8u

typedef struct SM64ModernFrontEndInputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint8_t advance_legacy_domain;
    uint8_t start_pressed;
    uint8_t confirm_pressed;
    uint8_t back_pressed;
    uint8_t has_activity;
    uint8_t debug_level_select;
    uint8_t demo_complete;
    uint8_t credits_complete;
    uint8_t ending_complete;
    uint8_t demo_count;
    int16_t selection_delta;
    uint32_t reserved;
} SM64ModernFrontEndInputV1;

typedef struct SM64ModernFrontEndOutputV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    SM64ModernFrontEndScreen screen;
    SM64ModernFrontEndTransition transition;
    int32_t selected_file;
    int32_t selected_course;
    int32_t selected_level;
    int32_t demo_index;
    int32_t title_zoom_counter;
    int32_t title_fade_counter;
    uint32_t reserved;
} SM64ModernFrontEndOutputV1;

typedef SM64ModernStatus (*SM64ModernFrontEndEvaluateFn)(
    void *context,
    const SM64ModernFrontEndInputV1 *input,
    SM64ModernFrontEndOutputV1 *out_output);

typedef struct SM64ModernFrontEndMigrationApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernFrontEndEvaluateFn evaluate;
} SM64ModernFrontEndMigrationApiV1;

// Pause/menu snapshots are emitted only from the live C pause renderer. They
// carry copied state and the completed C outcome; Swift can replay and
// fingerprint the reducer without traversing menu globals or display-list
// pointers. C remains the compatibility authority until a later cutover.
typedef struct SM64ModernPauseMenuSnapshotV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    uint32_t state;
    int32_t selection;
    int32_t camera_selection;
    uint32_t text_alpha;
    uint8_t menu_mode_active;
    uint8_t can_exit_course;
    uint8_t confirm_pressed;
    uint8_t reserved0;
    int32_t vertical_selection_delta;
    int32_t horizontal_camera_delta;
    int32_t course_number;
    int32_t course_minimum;
    int32_t course_maximum;
    int32_t outcome;
    uint32_t reserved;
} SM64ModernPauseMenuSnapshotV1;

typedef SM64ModernStatus (*SM64ModernPauseMenuObserveFn)(
    void *context,
    const SM64ModernPauseMenuSnapshotV1 *snapshot);

typedef struct SM64ModernPauseMenuMigrationApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernPauseMenuObserveFn observe;
} SM64ModernPauseMenuMigrationApiV1;

// Optional gameplay-kernel extension. It is installed separately so the
// original migration table remains ABI-stable for existing hosts.
typedef struct SM64ModernMarioGroundSpeedApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernMarioGroundSpeedUpdateFn update;
} SM64ModernMarioGroundSpeedApiV1;

// Optional progression migration extension. The C engine remains the
// compatibility authority; when installed by the Swift authority these
// owner-thread events mirror red-coin, cap-switch, reward, and persistence
// boundaries into the Swift progression runtime.
typedef uint32_t SM64ModernProgressionEventKind;

#define SM64_MODERN_PROGRESSION_EVENT_RED_COIN 1u
#define SM64_MODERN_PROGRESSION_EVENT_CAP_SWITCH 2u
#define SM64_MODERN_PROGRESSION_EVENT_LEVEL_REWARD 3u
#define SM64_MODERN_PROGRESSION_EVENT_SAVE_PERSIST 4u
#define SM64_MODERN_PROGRESSION_EVENT_SAVE_LOAD 5u
#define SM64_MODERN_PROGRESSION_EVENT_SAVE_RELOAD 6u
#define SM64_MODERN_PROGRESSION_EVENT_SAVE_MUTATION 7u

#define SM64_MODERN_PROGRESSION_SAVE_MUTATION_GENERIC 0u
#define SM64_MODERN_PROGRESSION_SAVE_MUTATION_ERASE 1u
#define SM64_MODERN_PROGRESSION_SAVE_MUTATION_COPY 2u
#define SM64_MODERN_PROGRESSION_SAVE_MUTATION_FLAGS 3u
#define SM64_MODERN_PROGRESSION_SAVE_MUTATION_STARS 4u
#define SM64_MODERN_PROGRESSION_SAVE_MUTATION_CANNON 5u
#define SM64_MODERN_PROGRESSION_SAVE_MUTATION_CAP 6u
#define SM64_MODERN_PROGRESSION_SAVE_MUTATION_MENU 7u

#define SM64_MODERN_PROGRESSION_COLLECTION_COURSE_STAR 0u
#define SM64_MODERN_PROGRESSION_COLLECTION_SECRET_STAR 1u
#define SM64_MODERN_PROGRESSION_COLLECTION_KEY_1 2u
#define SM64_MODERN_PROGRESSION_COLLECTION_KEY_2 3u
#define SM64_MODERN_PROGRESSION_COLLECTION_GRAND_STAR 4u

typedef struct SM64ModernProgressionEventV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    SM64ModernProgressionEventKind event_kind;
    uint32_t save_file_index;
    uint32_t course_number;
    uint32_t collection_kind;
    int32_t star_index;
    int32_t coin_score;
    int32_t global_max_coin_score;
    uint32_t cap_switch_index;
    uint32_t flags;
    // Save-mutation payload. These fields are zero for non-mutation events;
    // mutation_kind mirrors the SAVE_MUTATION_* constants while the remaining
    // values carry the exact C operands needed by the Swift value kernel.
    uint32_t mutation_kind;
    uint32_t mutation_operation;
    uint32_t mutation_source_file_index;
    uint32_t mutation_flags;
    uint32_t mutation_course_index;
    int32_t mutation_star_flags;
    uint32_t mutation_level;
    uint32_t mutation_area;
    int32_t mutation_cap_x;
    int32_t mutation_cap_y;
    int32_t mutation_cap_z;
    uint32_t mutation_sound_mode;
} SM64ModernProgressionEventV1;

typedef SM64ModernStatus (*SM64ModernProgressionEventFn)(
    void *context,
    const SM64ModernProgressionEventV1 *event);

typedef struct SM64ModernProgressionMigrationApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernProgressionEventFn record_event;
} SM64ModernProgressionMigrationApiV1;

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

// Optional frame-batch extension for native renderers. The legacy rendering
// callbacks remain the compatibility path; when this extension is installed,
// frame lifecycle and triangle submission are routed through the batch owner.
// Vertex memory is borrowed for the duration of append_triangles only.
typedef struct SM64ModernRenderingBatchApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernRenderFrameFn start_frame;
    SM64ModernRenderDrawTrianglesFn append_triangles;
    SM64ModernRenderFrameFn end_frame;
    SM64ModernRenderFrameFn finish_render;
} SM64ModernRenderingBatchApiV1;

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

// Whole-engine oracle schema 4. These records are fixed-width, pointer-free,
// and canonical across C and Swift. Floating-point values are supplied as
// IEEE-754 bits, save/PCM payloads are represented by deterministic hashes,
// and object/resource identities are stable content or pool IDs.
typedef struct SM64ModernOracleTraceConfigV1 {
    SM64ModernAbiHeader header;
    uint32_t schema_version;
    uint32_t region_code;
    SM64ModernOracleTraceMode mode;
    uint32_t reserved;
    uint64_t build_fingerprint;
    uint64_t content_fingerprint;
    uint64_t timebase_fingerprint;
    uint64_t configuration_fingerprint;
    uint64_t initial_save_fingerprint;
    uint64_t coverage_fingerprint;
} SM64ModernOracleTraceConfigV1;

typedef struct SM64ModernOracleTraceRecordV1 {
    SM64ModernAbiHeader header;
    uint64_t simulation_tick;
    SM64ModernOracleTraceDomain domain;
    SM64ModernOracleTraceRecordKind record_kind;
    uint64_t subject_id;
    uint64_t record_id;
    uint32_t sequence;
    uint32_t value_count;
    uint32_t flags;
    uint32_t reserved;
    uint64_t values[SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY];
    uint64_t canonical_hash;
} SM64ModernOracleTraceRecordV1;

typedef struct SM64ModernOracleCoverageEntryV1 {
    SM64ModernAbiHeader header;
    SM64ModernOracleTraceDomain domain;
    uint32_t flags;
    uint64_t record_id;
} SM64ModernOracleCoverageEntryV1;

typedef SM64ModernStatus (*SM64ModernOracleTraceWriteHeaderFn)(
    void *context,
    const SM64ModernOracleTraceConfigV1 *config);
typedef SM64ModernStatus (*SM64ModernOracleTraceReadHeaderFn)(
    void *context,
    SM64ModernOracleTraceConfigV1 *out_config);
typedef SM64ModernStatus (*SM64ModernOracleTraceWriteRecordFn)(
    void *context,
    const SM64ModernOracleTraceRecordV1 *record);
typedef SM64ModernStatus (*SM64ModernOracleTraceReadRecordFn)(
    void *context,
    SM64ModernOracleTraceRecordV1 *out_record);

typedef struct SM64ModernOracleTraceStreamApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernOracleTraceWriteHeaderFn write_header;
    SM64ModernOracleTraceReadHeaderFn read_header;
    SM64ModernOracleTraceWriteRecordFn write_record;
    SM64ModernOracleTraceReadRecordFn read_record;
} SM64ModernOracleTraceStreamApiV1;

typedef struct SM64ModernOracleTraceResultV1 {
    SM64ModernAbiHeader header;
    SM64ModernOracleTraceMode mode;
    SM64ModernStatus status;
    uint32_t reserved;
    uint64_t expected_records;
    uint64_t actual_records;
    uint64_t matched_records;
    uint64_t expected_hash;
    uint64_t actual_hash;
    uint64_t coverage_fingerprint;
    uint64_t coverage_entries;
} SM64ModernOracleTraceResultV1;

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

typedef struct SM64ModernTimebaseApiV1 {
    SM64ModernAbiHeader header;
    // Configuration is accepted only before lifecycle initialization (or
    // after shutdown); a running world cannot change rate underneath a tick.
    SM64ModernStatus (*configure)(const SM64ModernTimebaseConfigV1 *config);
    SM64ModernStatus (*get_snapshot)(SM64ModernTimebaseSnapshotV1 *out_snapshot);
} SM64ModernTimebaseApiV1;

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
SM64ModernStatus sm64_modern_get_timebase_api(uint32_t requested_version,
                                              uint32_t output_size,
                                              SM64ModernTimebaseApiV1 *out_api);
SM64ModernStatus sm64_modern_apply_cheat_state(
    const SM64ModernCheatStateV1 *state);
SM64ModernStatus sm64_modern_validate_platform_api(const SM64ModernPlatformApiV1 *platform);
SM64ModernStatus sm64_modern_validate_input_api(const SM64ModernInputApiV1 *input);
SM64ModernStatus sm64_modern_install_input_api(const SM64ModernInputApiV1 *input);
void sm64_modern_uninstall_input_api(void);
SM64ModernStatus sm64_modern_input_status(void);
SM64ModernStatus sm64_modern_validate_gameplay_migration_api(
    const SM64ModernGameplayMigrationApiV1 *migration);
SM64ModernStatus sm64_modern_install_gameplay_migration_api(
    const SM64ModernGameplayMigrationApiV1 *migration);
void sm64_modern_uninstall_gameplay_migration_api(void);
SM64ModernStatus sm64_modern_gameplay_migration_status(void);
SM64ModernStatus sm64_modern_validate_mario_ground_speed_api(
    const SM64ModernMarioGroundSpeedApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_ground_speed_api(
    const SM64ModernMarioGroundSpeedApiV1 *api);
void sm64_modern_uninstall_mario_ground_speed_api(void);
SM64ModernStatus sm64_modern_mario_ground_speed_status(void);
SM64ModernStatus sm64_modern_validate_mario_action_api(
    const SM64ModernMarioActionApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_action_api(
    const SM64ModernMarioActionApiV1 *api);
void sm64_modern_uninstall_mario_action_api(void);
SM64ModernStatus sm64_modern_mario_action_status(void);
SM64ModernStatus sm64_modern_validate_mario_action_cancel_api(
    const SM64ModernMarioActionCancelApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_action_cancel_api(
    const SM64ModernMarioActionCancelApiV1 *api);
void sm64_modern_uninstall_mario_action_cancel_api(void);
SM64ModernStatus sm64_modern_mario_action_cancel_status(void);
SM64ModernStatus sm64_modern_validate_mario_ground_step_api(
    const SM64ModernMarioGroundStepApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_ground_step_api(
    const SM64ModernMarioGroundStepApiV1 *api);
void sm64_modern_uninstall_mario_ground_step_api(void);
SM64ModernStatus sm64_modern_mario_ground_step_status(void);
SM64ModernStatus sm64_modern_validate_mario_air_step_api(
    const SM64ModernMarioAirStepApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_air_step_api(
    const SM64ModernMarioAirStepApiV1 *api);
void sm64_modern_uninstall_mario_air_step_api(void);
SM64ModernStatus sm64_modern_mario_air_step_status(void);
SM64ModernStatus sm64_modern_validate_mario_water_step_api(
    const SM64ModernMarioWaterStepApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_water_step_api(
    const SM64ModernMarioWaterStepApiV1 *api);
void sm64_modern_uninstall_mario_water_step_api(void);
SM64ModernStatus sm64_modern_mario_water_step_status(void);
SM64ModernStatus sm64_modern_validate_mario_bonk_api(
    const SM64ModernMarioBonkApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_bonk_api(
    const SM64ModernMarioBonkApiV1 *api);
void sm64_modern_uninstall_mario_bonk_api(void);
SM64ModernStatus sm64_modern_mario_bonk_status(void);
SM64ModernStatus sm64_modern_validate_mario_terrain_impulse_api(
    const SM64ModernMarioTerrainImpulseApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_terrain_impulse_api(
    const SM64ModernMarioTerrainImpulseApiV1 *api);
void sm64_modern_uninstall_mario_terrain_impulse_api(void);
SM64ModernStatus sm64_modern_mario_terrain_impulse_status(void);
SM64ModernStatus sm64_modern_validate_mario_quicksand_api(
    const SM64ModernMarioQuicksandApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_quicksand_api(
    const SM64ModernMarioQuicksandApiV1 *api);
void sm64_modern_uninstall_mario_quicksand_api(void);
SM64ModernStatus sm64_modern_mario_quicksand_status(void);
SM64ModernStatus sm64_modern_validate_mario_steep_push_api(
    const SM64ModernMarioSteepPushApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_steep_push_api(
    const SM64ModernMarioSteepPushApiV1 *api);
void sm64_modern_uninstall_mario_steep_push_api(void);
SM64ModernStatus sm64_modern_mario_steep_push_status(void);
SM64ModernStatus sm64_modern_validate_mario_terrain_sound_api(
    const SM64ModernMarioTerrainSoundApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_terrain_sound_api(
    const SM64ModernMarioTerrainSoundApiV1 *api);
void sm64_modern_uninstall_mario_terrain_sound_api(void);
SM64ModernStatus sm64_modern_mario_terrain_sound_status(void);
SM64ModernStatus sm64_modern_validate_mario_floor_predicates_api(
    const SM64ModernMarioFloorPredicatesApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_floor_predicates_api(
    const SM64ModernMarioFloorPredicatesApiV1 *api);
void sm64_modern_uninstall_mario_floor_predicates_api(void);
SM64ModernStatus sm64_modern_mario_floor_predicates_status(void);
SM64ModernStatus sm64_modern_validate_mario_forward_velocity_api(
    const SM64ModernMarioForwardVelocityApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_forward_velocity_api(
    const SM64ModernMarioForwardVelocityApiV1 *api);
void sm64_modern_uninstall_mario_forward_velocity_api(void);
SM64ModernStatus sm64_modern_mario_forward_velocity_status(void);
SM64ModernStatus sm64_modern_validate_mario_velocity_derivation_api(
    const SM64ModernMarioVelocityDerivationApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_velocity_derivation_api(
    const SM64ModernMarioVelocityDerivationApiV1 *api);
void sm64_modern_uninstall_mario_velocity_derivation_api(void);
SM64ModernStatus sm64_modern_mario_velocity_derivation_status(void);
SM64ModernStatus sm64_modern_validate_mario_punch_api(
    const SM64ModernMarioPunchApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_punch_api(
    const SM64ModernMarioPunchApiV1 *api);
void sm64_modern_uninstall_mario_punch_api(void);
SM64ModernStatus sm64_modern_mario_punch_status(void);
SM64ModernStatus sm64_modern_validate_mario_wall_response_api(
    const SM64ModernMarioWallResponseApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_wall_response_api(
    const SM64ModernMarioWallResponseApiV1 *api);
void sm64_modern_uninstall_mario_wall_response_api(void);
SM64ModernStatus sm64_modern_mario_wall_response_status(void);
SM64ModernStatus sm64_modern_validate_mario_walk_animation_api(
    const SM64ModernMarioWalkAnimationApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_walk_animation_api(
    const SM64ModernMarioWalkAnimationApiV1 *api);
void sm64_modern_uninstall_mario_walk_animation_api(void);
SM64ModernStatus sm64_modern_mario_walk_animation_status(void);
SM64ModernStatus sm64_modern_validate_mario_held_walk_animation_api(
    const SM64ModernMarioHeldWalkAnimationApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_held_walk_animation_api(
    const SM64ModernMarioHeldWalkAnimationApiV1 *api);
void sm64_modern_uninstall_mario_held_walk_animation_api(void);
SM64ModernStatus sm64_modern_mario_held_walk_animation_status(void);
SM64ModernStatus sm64_modern_validate_mario_slope_acceleration_api(
    const SM64ModernMarioSlopeAccelerationApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_slope_acceleration_api(
    const SM64ModernMarioSlopeAccelerationApiV1 *api);
void sm64_modern_uninstall_mario_slope_acceleration_api(void);
SM64ModernStatus sm64_modern_mario_slope_acceleration_status(void);
SM64ModernStatus sm64_modern_validate_mario_slope_deceleration_api(
    const SM64ModernMarioSlopeDecelerationApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_slope_deceleration_api(
    const SM64ModernMarioSlopeDecelerationApiV1 *api);
void sm64_modern_uninstall_mario_slope_deceleration_api(void);
SM64ModernStatus sm64_modern_mario_slope_deceleration_status(void);
SM64ModernStatus sm64_modern_validate_mario_decelerating_speed_api(
    const SM64ModernMarioDeceleratingSpeedApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_decelerating_speed_api(
    const SM64ModernMarioDeceleratingSpeedApiV1 *api);
void sm64_modern_uninstall_mario_decelerating_speed_api(void);
SM64ModernStatus sm64_modern_mario_decelerating_speed_status(void);
SM64ModernStatus sm64_modern_validate_mario_shell_speed_api(
    const SM64ModernMarioShellSpeedApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_shell_speed_api(
    const SM64ModernMarioShellSpeedApiV1 *api);
void sm64_modern_uninstall_mario_shell_speed_api(void);
SM64ModernStatus sm64_modern_mario_shell_speed_status(void);
SM64ModernStatus sm64_modern_validate_mario_landing_acceleration_api(
    const SM64ModernMarioLandingAccelerationApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_landing_acceleration_api(
    const SM64ModernMarioLandingAccelerationApiV1 *api);
void sm64_modern_uninstall_mario_landing_acceleration_api(void);
SM64ModernStatus sm64_modern_mario_landing_acceleration_status(void);
SM64ModernStatus sm64_modern_validate_mario_gravity_api(
    const SM64ModernMarioGravityApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_gravity_api(
    const SM64ModernMarioGravityApiV1 *api);
void sm64_modern_uninstall_mario_gravity_api(void);
SM64ModernStatus sm64_modern_mario_gravity_status(void);
SM64ModernStatus sm64_modern_validate_mario_vertical_wind_api(
    const SM64ModernMarioVerticalWindApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_vertical_wind_api(
    const SM64ModernMarioVerticalWindApiV1 *api);
void sm64_modern_uninstall_mario_vertical_wind_api(void);
SM64ModernStatus sm64_modern_mario_vertical_wind_status(void);
SM64ModernStatus sm64_modern_validate_mario_sliding_api(
    const SM64ModernMarioSlidingApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_sliding_api(
    const SM64ModernMarioSlidingApiV1 *api);
void sm64_modern_uninstall_mario_sliding_api(void);
SM64ModernStatus sm64_modern_mario_sliding_status(void);
SM64ModernStatus sm64_modern_validate_mario_ground_dive_punch_api(
    const SM64ModernMarioGroundDivePunchApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_ground_dive_punch_api(
    const SM64ModernMarioGroundDivePunchApiV1 *api);
void sm64_modern_uninstall_mario_ground_dive_punch_api(void);
SM64ModernStatus sm64_modern_mario_ground_dive_punch_status(void);
SM64ModernStatus sm64_modern_validate_mario_slide_predicates_api(
    const SM64ModernMarioSlidePredicatesApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_slide_predicates_api(
    const SM64ModernMarioSlidePredicatesApiV1 *api);
void sm64_modern_uninstall_mario_slide_predicates_api(void);
SM64ModernStatus sm64_modern_mario_slide_predicates_status(void);
SM64ModernStatus sm64_modern_validate_mario_begin_braking_api(
    const SM64ModernMarioBeginBrakingApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_begin_braking_api(
    const SM64ModernMarioBeginBrakingApiV1 *api);
void sm64_modern_uninstall_mario_begin_braking_api(void);
SM64ModernStatus sm64_modern_mario_begin_braking_status(void);
SM64ModernStatus sm64_modern_validate_mario_triple_jump_selector_api(
    const SM64ModernMarioTripleJumpSelectorApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_triple_jump_selector_api(
    const SM64ModernMarioTripleJumpSelectorApiV1 *api);
void sm64_modern_uninstall_mario_triple_jump_selector_api(void);
SM64ModernStatus sm64_modern_mario_triple_jump_selector_status(void);
SM64ModernStatus sm64_modern_validate_mario_y_velocity_api(
    const SM64ModernMarioYVelocityApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_y_velocity_api(
    const SM64ModernMarioYVelocityApiV1 *api);
void sm64_modern_uninstall_mario_y_velocity_api(void);
SM64ModernStatus sm64_modern_mario_y_velocity_status(void);
SM64ModernStatus sm64_modern_validate_mario_steep_jump_api(
    const SM64ModernMarioSteepJumpApiV1 *api);
SM64ModernStatus sm64_modern_install_mario_steep_jump_api(
    const SM64ModernMarioSteepJumpApiV1 *api);
void sm64_modern_uninstall_mario_steep_jump_api(void);
SM64ModernStatus sm64_modern_mario_steep_jump_status(void);
SM64ModernStatus sm64_modern_validate_camera_migration_api(
    const SM64ModernCameraMigrationApiV1 *migration);
SM64ModernStatus sm64_modern_install_camera_migration_api(
    const SM64ModernCameraMigrationApiV1 *migration);
void sm64_modern_uninstall_camera_migration_api(void);
SM64ModernStatus sm64_modern_camera_migration_status(void);
SM64ModernStatus sm64_modern_camera_update(
    const SM64ModernCameraStateV1 *input,
    SM64ModernCameraStateV1 *out_state);
SM64ModernStatus sm64_modern_camera_evaluate(
    const SM64ModernCameraCallbackInputV1 *input,
    SM64ModernCameraCallbackOutputV1 *out_output);
SM64ModernStatus sm64_modern_camera_evaluate_fov(
    const SM64ModernCameraFOVInputV1 *input,
    SM64ModernCameraFOVOutputV1 *out_output);
SM64ModernStatus sm64_modern_camera_set_authority(uint32_t enabled);
uint32_t sm64_modern_camera_authority_active(void);
SM64ModernStatus sm64_modern_validate_audio_migration_api(
    const SM64ModernAudioMigrationApiV1 *migration);
SM64ModernStatus sm64_modern_install_audio_migration_api(
    const SM64ModernAudioMigrationApiV1 *migration);
void sm64_modern_uninstall_audio_migration_api(void);
SM64ModernStatus sm64_modern_audio_migration_status(void);
SM64ModernStatus sm64_modern_audio_observe_sequence_event(
    uint32_t event_id,
    uint64_t simulation_tick,
    const uint64_t *values,
    uint32_t value_count);
SM64ModernStatus sm64_modern_validate_audio_pcm_migration_api(
    const SM64ModernAudioPCMMigrationApiV1 *migration);
SM64ModernStatus sm64_modern_install_audio_pcm_migration_api(
    const SM64ModernAudioPCMMigrationApiV1 *migration);
void sm64_modern_uninstall_audio_pcm_migration_api(void);
SM64ModernStatus sm64_modern_audio_pcm_migration_status(void);
SM64ModernStatus sm64_modern_audio_observe_pcm_receipt(
    const SM64ModernAudioPCMReceiptV1 *receipt);
SM64ModernStatus sm64_modern_validate_effects_migration_api(
    const SM64ModernEffectsMigrationApiV1 *migration);
SM64ModernStatus sm64_modern_install_effects_migration_api(
    const SM64ModernEffectsMigrationApiV1 *migration);
void sm64_modern_uninstall_effects_migration_api(void);
SM64ModernStatus sm64_modern_effects_migration_status(void);
SM64ModernStatus sm64_modern_effects_observe_receipt(
    const SM64ModernEffectReceiptV1 *receipt);
SM64ModernStatus sm64_modern_validate_text_migration_api(
    const SM64ModernTextMigrationApiV1 *migration);
SM64ModernStatus sm64_modern_install_text_migration_api(
    const SM64ModernTextMigrationApiV1 *migration);
void sm64_modern_uninstall_text_migration_api(void);
SM64ModernStatus sm64_modern_text_migration_status(void);
uint64_t sm64_modern_text_hash_string(const char *value);
SM64ModernStatus sm64_modern_text_record_save_write(
    uint64_t source_identity,
    uint64_t text_identity,
    uint64_t payload_hash,
    uint32_t file_index);
SM64ModernStatus sm64_modern_validate_global_state_migration_api(
    const SM64ModernGlobalStateMigrationApiV1 *migration);
SM64ModernStatus sm64_modern_install_global_state_migration_api(
    const SM64ModernGlobalStateMigrationApiV1 *migration);
void sm64_modern_uninstall_global_state_migration_api(void);
SM64ModernStatus sm64_modern_global_state_migration_status(void);
SM64ModernStatus sm64_modern_global_state_observe_snapshot(
    const SM64ModernGlobalStateSnapshotV1 *snapshot);
SM64ModernStatus sm64_modern_validate_frontend_migration_api(
    const SM64ModernFrontEndMigrationApiV1 *migration);
SM64ModernStatus sm64_modern_install_frontend_migration_api(
    const SM64ModernFrontEndMigrationApiV1 *migration);
void sm64_modern_uninstall_frontend_migration_api(void);
SM64ModernStatus sm64_modern_frontend_migration_status(void);
SM64ModernStatus sm64_modern_frontend_evaluate(
    const SM64ModernFrontEndInputV1 *input,
    SM64ModernFrontEndOutputV1 *out_output);
SM64ModernStatus sm64_modern_validate_pause_menu_migration_api(
    const SM64ModernPauseMenuMigrationApiV1 *migration);
SM64ModernStatus sm64_modern_install_pause_menu_migration_api(
    const SM64ModernPauseMenuMigrationApiV1 *migration);
void sm64_modern_uninstall_pause_menu_migration_api(void);
SM64ModernStatus sm64_modern_pause_menu_migration_status(void);
SM64ModernStatus sm64_modern_pause_menu_observe_snapshot(
    const SM64ModernPauseMenuSnapshotV1 *snapshot);
SM64ModernStatus sm64_modern_validate_progression_migration_api(
    const SM64ModernProgressionMigrationApiV1 *migration);
SM64ModernStatus sm64_modern_install_progression_migration_api(
    const SM64ModernProgressionMigrationApiV1 *migration);
void sm64_modern_uninstall_progression_migration_api(void);
SM64ModernStatus sm64_modern_progression_migration_status(void);
SM64ModernStatus sm64_modern_validate_rendering_api(const SM64ModernRenderingApiV1 *rendering);
SM64ModernStatus sm64_modern_install_rendering_api(const SM64ModernRenderingApiV1 *rendering);
void sm64_modern_uninstall_rendering_api(void);
SM64ModernStatus sm64_modern_rendering_status(void);
SM64ModernStatus sm64_modern_validate_rendering_batch_api(const SM64ModernRenderingBatchApiV1 *batch);
SM64ModernStatus sm64_modern_install_rendering_batch_api(const SM64ModernRenderingBatchApiV1 *batch);
void sm64_modern_uninstall_rendering_batch_api(void);
SM64ModernStatus sm64_modern_rendering_batch_status(void);
SM64ModernStatus sm64_modern_get_gameplay_api(uint32_t requested_version,
                                              uint32_t output_size,
                                              SM64ModernGameplayApiV1 *out_api);
SM64ModernStatus sm64_modern_get_gameplay_parity_api(uint32_t requested_version,
                                                     uint32_t output_size,
                                                     SM64ModernGameplayParityApiV1 *out_api);

// Schema-4 whole-engine oracle trace. This API is owner-thread-only and is
// intentionally separate from the schema-3 gameplay parity service.
void sm64_modern_oracle_trace_reset(void);
SM64ModernStatus sm64_modern_oracle_trace_begin(
    const SM64ModernOracleTraceConfigV1 *config,
    const SM64ModernOracleTraceStreamApiV1 *stream);
SM64ModernStatus sm64_modern_oracle_trace_end(void);
void sm64_modern_oracle_trace_begin_tick(void);
void sm64_modern_oracle_trace_end_tick(void);
SM64ModernStatus sm64_modern_oracle_trace_record(
    SM64ModernOracleTraceDomain domain,
    SM64ModernOracleTraceRecordKind record_kind,
    uint64_t subject_id,
    uint64_t record_id,
    uint32_t flags,
    const uint64_t *values,
    uint32_t value_count);
SM64ModernStatus sm64_modern_oracle_trace_mark_coverage(
    SM64ModernOracleTraceDomain domain,
    uint64_t record_id);
SM64ModernStatus sm64_modern_oracle_trace_get_result(
    SM64ModernOracleTraceResultV1 *out_result);
SM64ModernStatus sm64_modern_oracle_trace_status(void);
uint32_t sm64_modern_oracle_trace_is_active(void);
uint64_t sm64_modern_oracle_trace_simulation_tick(void);
uint32_t sm64_modern_oracle_trace_next_sequence(
    SM64ModernOracleTraceDomain domain);
uint64_t sm64_modern_oracle_trace_hash_record(
    const SM64ModernOracleTraceRecordV1 *record);
uint32_t sm64_modern_oracle_inventory_count(void);
SM64ModernStatus sm64_modern_oracle_inventory_entry(
    uint32_t index,
    SM64ModernOracleCoverageEntryV1 *out_entry);
uint64_t sm64_modern_oracle_inventory_fingerprint(void);
uint64_t sm64_modern_oracle_audio_asset_coverage_fingerprint(void);

#ifdef __cplusplus
}
#endif

#endif // SM64_MODERN_H
