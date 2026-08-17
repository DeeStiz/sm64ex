#ifndef SM64_MODERN_PROGRESSION_MIGRATION_H
#define SM64_MODERN_PROGRESSION_MIGRATION_H

#include "sm64_modern.h"

SM64ModernStatus sm64_modern_progression_record_event(
    SM64ModernProgressionEventKind event_kind,
    uint32_t save_file_index,
    uint32_t course_number,
    uint32_t collection_kind,
    int32_t star_index,
    int32_t coin_score,
    int32_t global_max_coin_score,
    uint32_t cap_switch_index,
    uint32_t flags);

SM64ModernStatus sm64_modern_progression_record_save_mutation(
    uint32_t save_file_index,
    uint32_t mutation_kind,
    uint32_t mutation_operation,
    uint32_t source_file_index,
    uint32_t mutation_flags,
    uint32_t course_index,
    int32_t star_flags,
    uint32_t level,
    uint32_t area,
    int32_t cap_x,
    int32_t cap_y,
    int32_t cap_z,
    uint32_t sound_mode);
SM64ModernStatus sm64_modern_progression_migration_active_status(void);

// The Swift authority may take ownership of the durable save image while the
// C engine continues to consume the normalized in-memory SaveBuffer.  The
// flag is owner-thread-only and is reset when the migration API is removed.
SM64ModernStatus sm64_modern_progression_set_persistence_authority(
    uint32_t enabled);
uint32_t sm64_modern_progression_persistence_authority_active(void);

// Reads the current canonical C slots synchronously on the lifecycle owner
// thread. The helper emits normalized little-endian bytes so Swift can reuse
// the existing checksum/recovery codecs even before C recomputes signatures.
SM64ModernStatus sm64_modern_progression_read_snapshot(
    uint32_t save_file_index,
    uint8_t *save_bytes,
    uint32_t save_capacity,
    uint8_t *menu_bytes,
    uint32_t menu_capacity);

// Replaces both copies of one C save slot and both menu copies from the
// normalized little-endian Swift image.  This is used only by the owner
// thread during Swift-owned load/reload boundaries.
SM64ModernStatus sm64_modern_progression_write_snapshot(
    uint32_t save_file_index,
    const uint8_t *save_bytes,
    uint32_t save_capacity,
    const uint8_t *menu_bytes,
    uint32_t menu_capacity);

#endif // SM64_MODERN_PROGRESSION_MIGRATION_H
