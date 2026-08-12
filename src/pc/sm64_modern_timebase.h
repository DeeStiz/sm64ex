#ifndef SM64_MODERN_TIMEBASE_H
#define SM64_MODERN_TIMEBASE_H

#include <stdbool.h>
#include <stdint.h>

uint64_t sm64_modern_timebase_fingerprint(void);
void sm64_modern_timebase_set_lifecycle_active(bool active);

#endif // SM64_MODERN_TIMEBASE_H
