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
SM64ModernStatus sm64_modern_progression_migration_active_status(void);

#endif // SM64_MODERN_PROGRESSION_MIGRATION_H
