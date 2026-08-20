#include "sm64_modern.h"

SM64ModernStatus sm64_modern_gameplay_get_authority(
    SM64ModernGameplaySubsystem subsystem,
    SM64ModernAuthority *out_authority) {
    (void) subsystem;
    if (!out_authority) return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    *out_authority = SM64_MODERN_AUTHORITY_SWIFT;
    return SM64_MODERN_STATUS_OK;
}
