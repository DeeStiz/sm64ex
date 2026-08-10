#ifndef SM64_MODERN_LEGACY_H
#define SM64_MODERN_LEGACY_H

#include "sm64_modern.h"

void sm64_modern_make_legacy_platform(SM64ModernPlatformApiV1 *out_platform);
SM64ModernStatus sm64_modern_run_legacy_loop(SM64ModernLifecycleApiV1 *lifecycle);

#endif // SM64_MODERN_LEGACY_H
