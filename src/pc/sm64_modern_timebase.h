#ifndef SM64_MODERN_TIMEBASE_H
#define SM64_MODERN_TIMEBASE_H

#include <stdbool.h>
#include <stdint.h>

uint64_t sm64_modern_timebase_fingerprint(void);
void sm64_modern_timebase_set_lifecycle_active(bool active);
bool sm64_modern_timebase_lifecycle_active(void);

/*
 * Private cadence contract: inactive and ratio-one lifecycles report legacy
 * safety/boundary/final-step true.  An active ratio above one reports all
 * three false before its first admitted step; the first step is boundary
 * phase 1, and the final held step is phase 0.
 */
void sm64_modern_timebase_begin_simulation_step(void);
bool sm64_modern_timebase_should_advance_legacy_domain(void);
bool sm64_modern_timebase_is_legacy_boundary(void);
bool sm64_modern_timebase_is_legacy_interval_final_step(void);
uint64_t sm64_modern_timebase_simulation_tick(void);
uint64_t sm64_modern_timebase_legacy_tick(void);
uint32_t sm64_modern_timebase_pair_phase(void);

#endif // SM64_MODERN_TIMEBASE_H
