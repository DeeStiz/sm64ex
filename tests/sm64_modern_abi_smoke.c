#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "sm64_modern.h"

static int expect_status(const char *operation, SM64ModernStatus actual, SM64ModernStatus expected) {
    if (actual == expected) {
        return 0;
    }

    fprintf(stderr, "%s: expected status %u, got %u\n", operation, expected, actual);
    return 1;
}

static SM64ModernStatus smoke_platform_initialize(void *context, const char *window_title) {
    (void) context;
    (void) window_title;
    return SM64_MODERN_STATUS_OK;
}

static void smoke_platform_shutdown(void *context) {
    (void) context;
}

static uint64_t smoke_platform_thread(void *context) {
    (void) context;
    return 1;
}

int main(void) {
    SM64ModernLifecycleApiV1 lifecycle;
    SM64ModernGameplayApiV1 gameplay;
    SM64ModernPlatformApiV1 platform;
    SM64ModernLifecycleState state = UINT32_MAX;
    SM64ModernAuthority authority = UINT32_MAX;
    int failures = 0;

    memset(&lifecycle, 0, sizeof(lifecycle));
    memset(&gameplay, 0, sizeof(gameplay));
    memset(&platform, 0, sizeof(platform));

    platform.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    platform.header.struct_size = sizeof(platform);
    platform.initialize = smoke_platform_initialize;
    platform.shutdown = smoke_platform_shutdown;
    platform.current_thread = smoke_platform_thread;
    failures += expect_status("platform v1", sm64_modern_validate_platform_api(&platform),
                              SM64_MODERN_STATUS_OK);
    platform.capabilities = 1u << 31;
    failures += expect_status("unknown platform capability", sm64_modern_validate_platform_api(&platform),
                              SM64_MODERN_STATUS_INVALID_ARGUMENT);
    platform.capabilities = 0;
    platform.header.abi_version++;
    failures += expect_status("unsupported platform version", sm64_modern_validate_platform_api(&platform),
                              SM64_MODERN_STATUS_UNSUPPORTED_VERSION);
    platform.header.abi_version = SM64_MODERN_ABI_VERSION_1;

    failures += expect_status("unsupported lifecycle version",
                              sm64_modern_get_lifecycle_api(2, sizeof(lifecycle), &lifecycle),
                              SM64_MODERN_STATUS_UNSUPPORTED_VERSION);
    failures += expect_status("small lifecycle buffer",
                              sm64_modern_get_lifecycle_api(SM64_MODERN_ABI_VERSION_1,
                                                            sizeof(lifecycle) - 1,
                                                            &lifecycle),
                              SM64_MODERN_STATUS_BUFFER_TOO_SMALL);
    failures += expect_status("lifecycle v1",
                              sm64_modern_get_lifecycle_api(SM64_MODERN_ABI_VERSION_1,
                                                            sizeof(lifecycle),
                                                            &lifecycle),
                              SM64_MODERN_STATUS_OK);
    failures += expect_status("cold lifecycle state", lifecycle.get_state(&state), SM64_MODERN_STATUS_OK);
    if (state != SM64_MODERN_LIFECYCLE_COLD) {
        fprintf(stderr, "cold lifecycle state: expected %u, got %u\n",
                SM64_MODERN_LIFECYCLE_COLD, state);
        failures++;
    }
    failures += expect_status("step before initialize", lifecycle.step(), SM64_MODERN_STATUS_INVALID_STATE);
    failures += expect_status("invalid exit reason", lifecycle.request_stop(0),
                              SM64_MODERN_STATUS_INVALID_ARGUMENT);

    failures += expect_status("gameplay v1",
                              sm64_modern_get_gameplay_api(SM64_MODERN_ABI_VERSION_1,
                                                           sizeof(gameplay),
                                                           &gameplay),
                              SM64_MODERN_STATUS_OK);
    failures += expect_status("global authority",
                              gameplay.get_authority(SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL, &authority),
                              SM64_MODERN_STATUS_OK);
    if (authority != SM64_MODERN_AUTHORITY_C) {
        fprintf(stderr, "global authority: expected %u, got %u\n", SM64_MODERN_AUTHORITY_C, authority);
        failures++;
    }
    failures += expect_status("shadow authority unsupported",
                              gameplay.set_authority(SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL,
                                                     SM64_MODERN_AUTHORITY_SHADOW_SWIFT),
                              SM64_MODERN_STATUS_UNSUPPORTED_AUTHORITY);

    if (lifecycle.header.abi_version != SM64_MODERN_ABI_VERSION_1
        || lifecycle.header.struct_size != sizeof(lifecycle)
        || gameplay.header.abi_version != SM64_MODERN_ABI_VERSION_1
        || gameplay.header.struct_size != sizeof(gameplay)) {
        fprintf(stderr, "ABI headers do not describe the returned v1 tables\n");
        failures++;
    }

    if (offsetof(SM64ModernLifecycleConfigV1, header) != 0
        || offsetof(SM64ModernPlatformApiV1, header) != 0
        || offsetof(SM64ModernGameplayRecordEnvelopeV1, header) != 0) {
        fprintf(stderr, "versioned ABI headers must be the first field\n");
        failures++;
    }

    if (failures != 0) {
        return 1;
    }

    printf("SM64 Modern ABI v1 smoke passed\n");
    return 0;
}
