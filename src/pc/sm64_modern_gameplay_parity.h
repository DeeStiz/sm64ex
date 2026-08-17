#ifndef SM64_MODERN_GAMEPLAY_PARITY_H
#define SM64_MODERN_GAMEPLAY_PARITY_H

#include <ultra64.h>

#include "sm64_modern.h"

struct Object;

void sm64_modern_parity_reset(void);
void sm64_modern_parity_begin_tick(void);
void sm64_modern_parity_end_tick(void);
void sm64_modern_parity_filter_input(OSContPad *pad);
void sm64_modern_parity_capture_snapshots(void);
void sm64_modern_parity_record_sound(s32 sound_bits, const f32 *position);
void sm64_modern_parity_record_rumble_start(f32 strength, f32 duration);
void sm64_modern_parity_record_rumble_stop(void);
void sm64_modern_parity_record_object_spawn(struct Object *parent,
                                             struct Object *object,
                                             s32 model,
                                             const void *behavior);
void sm64_modern_parity_record_object_despawn(struct Object *object);
void sm64_modern_parity_record_pcm(const s16 *samples, u32 frame_count);
// Schema-4 save-byte boundary. The payload is hashed before any platform
// persistence and never exposes the mutable SaveBuffer to Swift.
#define SM64_MODERN_ORACLE_SAVE_EVENT_MUTATION 1u
#define SM64_MODERN_ORACLE_SAVE_EVENT_PERSIST 2u
#define SM64_MODERN_ORACLE_SAVE_EVENT_LOAD 3u
#define SM64_MODERN_ORACLE_SAVE_EVENT_RELOAD 4u
void sm64_modern_parity_record_save_state(uint32_t event_id,
                                          uint32_t file_index,
                                          const void *bytes,
                                          uint32_t byte_count,
                                          uint32_t modified_flags);
#define SM64_MODERN_ORACLE_RNG_EVENT_U16 1u
#define SM64_MODERN_ORACLE_RNG_EVENT_FLOAT 2u
#define SM64_MODERN_ORACLE_RNG_EVENT_SIGN 3u
void sm64_modern_parity_record_rng_draw(uint32_t event_id,
                                        uint64_t value,
                                        uint64_t seed);
#define SM64_MODERN_ORACLE_COLLISION_EVENT_FLOOR 1u
#define SM64_MODERN_ORACLE_COLLISION_EVENT_CEIL 2u
#define SM64_MODERN_ORACLE_COLLISION_EVENT_WALL 3u
#define SM64_MODERN_ORACLE_COLLISION_EVENT_ENVIRONMENT 4u
void sm64_modern_parity_record_collision_query(uint32_t event_id,
                                               const uint64_t *values,
                                               uint32_t value_count);
#define SM64_MODERN_ORACLE_SCRIPT_EVENT_LEVEL_COMMAND 1u
#define SM64_MODERN_ORACLE_SCRIPT_EVENT_BEHAVIOR_COMMAND 2u
#define SM64_MODERN_ORACLE_SCRIPT_EVENT_LEVEL_TRANSITION 3u
#define SM64_MODERN_ORACLE_SCRIPT_EVENT_NATIVE_BEHAVIOR 4u
#define SM64_MODERN_ORACLE_SCRIPT_EVENT_LIFECYCLE 5u
void sm64_modern_parity_record_script_event(uint32_t event_id,
                                            uint64_t subject_id,
                                            const uint64_t *values,
                                            uint32_t value_count);
#define SM64_MODERN_ORACLE_AUDIO_EVENT_TICK \
    SM64_MODERN_AUDIO_SEQUENCE_EVENT_TICK
#define SM64_MODERN_ORACLE_AUDIO_EVENT_SEQUENCE \
    SM64_MODERN_AUDIO_SEQUENCE_EVENT_SEQUENCE
#define SM64_MODERN_ORACLE_AUDIO_EVENT_QUEUE \
    SM64_MODERN_AUDIO_SEQUENCE_EVENT_QUEUE
#define SM64_MODERN_ORACLE_AUDIO_EVENT_SECONDARY \
    SM64_MODERN_AUDIO_SEQUENCE_EVENT_SECONDARY
void sm64_modern_parity_record_audio_sequence(uint32_t event_id,
                                              const uint64_t *values,
                                              uint32_t value_count);
#define SM64_MODERN_ORACLE_RENDER_EVENT_DRAW 1u
#define SM64_MODERN_ORACLE_RENDER_EVENT_FRAME_BEGIN 2u
#define SM64_MODERN_ORACLE_RENDER_EVENT_FRAME_END 3u
#define SM64_MODERN_ORACLE_RENDER_EVENT_FINISH 4u
#define SM64_MODERN_ORACLE_RENDER_EVENT_MARIO_FACE_ROUTE 5u
void sm64_modern_parity_record_render_packet(uint32_t event_id,
                                             const uint64_t *values,
                                             uint32_t value_count);
void sm64_modern_parity_record_mario_face_route(uint32_t route_id);
u32 sm64_modern_parity_audio_frame_count(u32 high_count, u32 default_count);
void sm64_modern_parity_enter_subsystem(SM64ModernGameplaySubsystem subsystem);
void sm64_modern_parity_enter_object_update(const struct Object *object);
void sm64_modern_parity_leave_subsystem(void);
SM64ModernStatus sm64_modern_parity_status(void);
uint64_t sm64_modern_parity_simulation_tick(void);
uint32_t sm64_modern_parity_object_slot(const struct Object *object);
SM64ModernGameplaySubsystem sm64_modern_parity_current_subsystem(void);

// Internal deterministic harness seam. This is deliberately absent from the
// public ABI and exercises the same canonical record path as engine snapshots.
void sm64_modern_parity_record_test_snapshot(SM64ModernGameplaySubsystem subsystem,
                                              uint32_t field,
                                              uint32_t subject_id,
                                              const uint64_t *values,
                                              uint32_t value_count);

SM64ModernStatus sm64_modern_gameplay_get_authority(SM64ModernGameplaySubsystem subsystem,
                                                     SM64ModernAuthority *out_authority);
SM64ModernStatus sm64_modern_gameplay_set_authority(SM64ModernGameplaySubsystem subsystem,
                                                     SM64ModernAuthority authority);

#endif // SM64_MODERN_GAMEPLAY_PARITY_H
