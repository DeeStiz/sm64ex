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

typedef struct SM64ModernCameraMigrationApiV1 {
    SM64ModernAbiHeader header;
    void *context;
    SM64ModernCameraUpdateFn update;
    SM64ModernCameraEvaluateFn evaluate;
    SM64ModernCameraFOVEvaluateFn evaluate_fov;
} SM64ModernCameraMigrationApiV1;

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
uint64_t sm64_modern_oracle_trace_hash_record(
    const SM64ModernOracleTraceRecordV1 *record);
uint32_t sm64_modern_oracle_inventory_count(void);
SM64ModernStatus sm64_modern_oracle_inventory_entry(
    uint32_t index,
    SM64ModernOracleCoverageEntryV1 *out_entry);
uint64_t sm64_modern_oracle_inventory_fingerprint(void);

#ifdef __cplusplus
}
#endif

#endif // SM64_MODERN_H
