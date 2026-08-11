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

typedef uint32_t SM64ModernAuthority;

#define SM64_MODERN_AUTHORITY_C 0u
#define SM64_MODERN_AUTHORITY_SHADOW_SWIFT 1u
#define SM64_MODERN_AUTHORITY_SWIFT 2u

typedef uint32_t SM64ModernGameplaySubsystem;

// M1 exposes one global gate. Stable subsystem identifiers arrive with the
// concrete snapshot/effect schemas in M6 and M7.
#define SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL 0u

typedef uint32_t SM64ModernGameplayRecordKind;

#define SM64_MODERN_GAMEPLAY_RECORD_SNAPSHOT 1u
#define SM64_MODERN_GAMEPLAY_RECORD_EFFECT 2u

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

// STUB(M6): payload schemas and record streams — add deterministic snapshot
// fields and effect records without exposing the C object graph.

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
// The core copies both versioned input structs during initialize and never
// retains pointers to the caller's configuration storage.

typedef struct SM64ModernGameplayApiV1 {
    SM64ModernAbiHeader header;
    SM64ModernStatus (*get_authority)(SM64ModernGameplaySubsystem subsystem,
                                      SM64ModernAuthority *out_authority);
    SM64ModernStatus (*set_authority)(SM64ModernGameplaySubsystem subsystem,
                                      SM64ModernAuthority authority);
} SM64ModernGameplayApiV1;

SM64ModernStatus sm64_modern_get_lifecycle_api(uint32_t requested_version,
                                               uint32_t output_size,
                                               SM64ModernLifecycleApiV1 *out_api);
SM64ModernStatus sm64_modern_validate_platform_api(const SM64ModernPlatformApiV1 *platform);
SM64ModernStatus sm64_modern_validate_rendering_api(const SM64ModernRenderingApiV1 *rendering);
SM64ModernStatus sm64_modern_install_rendering_api(const SM64ModernRenderingApiV1 *rendering);
void sm64_modern_uninstall_rendering_api(void);
SM64ModernStatus sm64_modern_rendering_status(void);
SM64ModernStatus sm64_modern_get_gameplay_api(uint32_t requested_version,
                                              uint32_t output_size,
                                              SM64ModernGameplayApiV1 *out_api);

#ifdef __cplusplus
}
#endif

#endif // SM64_MODERN_H
