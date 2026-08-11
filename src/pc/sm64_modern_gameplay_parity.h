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
u32 sm64_modern_parity_audio_frame_count(u32 high_count, u32 default_count);
void sm64_modern_parity_enter_subsystem(SM64ModernGameplaySubsystem subsystem);
void sm64_modern_parity_enter_object_update(const struct Object *object);
void sm64_modern_parity_leave_subsystem(void);
SM64ModernStatus sm64_modern_parity_status(void);

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
