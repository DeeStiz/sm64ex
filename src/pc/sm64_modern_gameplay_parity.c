#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include "sm64.h"
#include "sm64_modern.h"

#include "behavior_data.h"
#include "engine/behavior_script.h"
#include "game/area.h"
#include "game/camera.h"
#include "game/game_init.h"
#include "game/level_update.h"
#include "game/object_list_processor.h"
#include "level_table.h"
#include "object_fields.h"
#include "sm64_modern_audio_migration.h"
#include "sm64_modern_audio_pcm_migration.h"
#include "sm64_modern_effects_migration.h"
#include "sm64_modern_global_state_migration.h"
#include "sm64_modern_gameplay_migration.h"
#include "sm64_modern_gameplay_parity.h"
#include "sm64_modern_timebase.h"

#define PARITY_FNV_OFFSET UINT64_C(1469598103934665603)
#define PARITY_FNV_PRIME UINT64_C(1099511628211)
#define PARITY_CANDIDATE_RECORD_CAPACITY 4096u
#define PARITY_SUBSYSTEM_STACK_CAPACITY 8u

struct CandidateRecords {
    SM64ModernGameplayTraceRecordV1 records[PARITY_CANDIDATE_RECORD_CAPACITY];
    uint32_t actual_count;
    uint32_t candidate_count;
};

static SM64ModernGameplayParityConfigV1 sConfig;
static SM64ModernGameplayTraceStreamApiV1 sStream;
static SM64ModernGameplayParityResultV1 sResults[SM64_MODERN_GAMEPLAY_SUBSYSTEM_COUNT];
static SM64ModernGameplayDivergenceV1 sDivergences[SM64_MODERN_GAMEPLAY_SUBSYSTEM_COUNT];
static struct CandidateRecords sCandidateRecords[SM64_MODERN_GAMEPLAY_SUBSYSTEM_COUNT];
static SM64ModernAuthority sAuthorities[SM64_MODERN_GAMEPLAY_SUBSYSTEM_COUNT];
static SM64ModernGameplaySubsystem sSubsystemStack[PARITY_SUBSYSTEM_STACK_CAPACITY];
static uint32_t sSubsystemStackDepth;
static uint32_t sSequence[SM64_MODERN_GAMEPLAY_SUBSYSTEM_COUNT];
static uint64_t sSimulationTick;
static SM64ModernStatus sStatus = SM64_MODERN_STATUS_OK;
static bool sSessionActive;
static bool sTickOpen;

static SM64ModernStatus submit_candidate_record(const SM64ModernGameplayTraceRecordV1 *record);

static bool valid_subsystem(SM64ModernGameplaySubsystem subsystem) {
    return subsystem < SM64_MODERN_GAMEPLAY_SUBSYSTEM_COUNT;
}

static bool subsystem_enabled(SM64ModernGameplaySubsystem subsystem) {
    return sSessionActive && valid_subsystem(subsystem)
        && (sConfig.subsystem_mask & SM64_MODERN_GAMEPLAY_SUBSYSTEM_MASK(subsystem)) != 0;
}

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (uint32_t byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= PARITY_FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_record(const SM64ModernGameplayTraceRecordV1 *record) {
    uint64_t hash = PARITY_FNV_OFFSET;
    hash = hash_u64(hash, record->envelope.simulation_tick);
    hash = hash_u64(hash, record->envelope.subsystem);
    hash = hash_u64(hash, record->envelope.record_kind);
    hash = hash_u64(hash, record->record_id);
    hash = hash_u64(hash, record->subject_id);
    hash = hash_u64(hash, record->sequence);
    hash = hash_u64(hash, record->value_count);
    for (uint32_t index = 0; index < record->value_count; ++index) {
        hash = hash_u64(hash, record->values[index]);
    }
    return hash;
}

static uint64_t aggregate_hash(uint64_t aggregate, uint64_t record_hash) {
    return hash_u64(aggregate ? aggregate : PARITY_FNV_OFFSET, record_hash);
}

static uint64_t float_bits(f32 value) {
    uint32_t bits;
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

static uint32_t object_slot(const struct Object *object) {
    const uintptr_t begin = (uintptr_t) &gObjectPool[0];
    const uintptr_t end = (uintptr_t) &gObjectPool[OBJECT_POOL_CAPACITY];
    const uintptr_t address = (uintptr_t) object;
    if (!object || address < begin || address >= end
        || (address - begin) % sizeof(gObjectPool[0]) != 0) {
        return 0;
    }
    return (uint32_t) ((address - begin) / sizeof(gObjectPool[0])) + 1u;
}

static uint64_t behavior_name_hash(const char *name) {
    uint64_t hash = PARITY_FNV_OFFSET;
    for (const unsigned char *cursor = (const unsigned char *) name;
         cursor && *cursor;
         ++cursor) {
        hash ^= *cursor;
        hash *= PARITY_FNV_PRIME;
    }
    return hash;
}

static uint64_t behavior_identity(const void *behavior) {
    if (!behavior) {
        return 0;
    }
    // The Swift object bridges use a semantic value-only identity for the
    // authored normal door. Pointer deltas are not stable across Debug and
    // AddressSanitizer data layouts, so preserve the source behavior identity
    // at this owner boundary before falling back to the legacy anchor delta.
    if (behavior == segmented_to_virtual(bhvDoor)) {
        return UINT64_C(0x6268765f64726e); // "bhv_drn" / SM64DoorObjectBridge
    }
    // Decorative pendulum owns a fixed-width source identity for the
    // Castle Inside area-2 route.  Do not expose the linked behavior pointer:
    // its address changes across Debug, ASan, and Release layouts and would
    // make the source-authored object record impossible to pair.
    if (behavior == segmented_to_virtual(bhvDecorativePendulum)) {
        return UINT64_C(0x6268765f647065); // "bhv_dpe" / pendulum bridge
    }
    // The RR Donut Platform route uses the source behavior names as its
    // fixed-width owner identity.  Pointer deltas are not stable across
    // Debug, ASan, and Release link layouts.
    if (behavior == segmented_to_virtual(bhvDonutPlatformSpawner)) {
        return behavior_name_hash("bhvDonutPlatformSpawner");
    }
    if (behavior == segmented_to_virtual(bhvDonutPlatform)) {
        return behavior_name_hash("bhvDonutPlatform");
    }
    // The HMC controllable platform route owns both its authored parent and
    // source-spawned arrow-platform children. Keep these identities semantic
    // so Debug, ASan, and Release traces do not depend on behavior pointers.
    if (behavior == segmented_to_virtual(bhvControllablePlatform)) {
        return behavior_name_hash("bhvControllablePlatform");
    }
    if (behavior == segmented_to_virtual(bhvControllablePlatformSub)) {
        return behavior_name_hash("bhvControllablePlatformSub");
    }
    // These are the authored behavior scripts reached by the canonical
    // effects route. Pointer deltas are not stable across Debug, ASan, and
    // Release link layouts, so publish a semantic source-name identity at
    // the owner boundary. Unknown scripts retain the legacy anchor-relative
    // value and therefore remain fail-closed until their own source identity
    // is qualified.
#define SOURCE_BEHAVIOR_IDENTITY(name) \
    if (behavior == segmented_to_virtual(name)) { \
        return behavior_name_hash(#name); \
    }
    SOURCE_BEHAVIOR_IDENTITY(bhvStaticObject)
    SOURCE_BEHAVIOR_IDENTITY(bhvCannon)
    SOURCE_BEHAVIOR_IDENTITY(bhvCannonBarrel)
    SOURCE_BEHAVIOR_IDENTITY(bhvYoshi)
    SOURCE_BEHAVIOR_IDENTITY(bhvCameraLakitu)
    SOURCE_BEHAVIOR_IDENTITY(bhvYellowCoin)
    SOURCE_BEHAVIOR_IDENTITY(bhvDoorWarp)
    SOURCE_BEHAVIOR_IDENTITY(bhvExclamationBox)
    SOURCE_BEHAVIOR_IDENTITY(bhvRotatingExclamationMark)
    SOURCE_BEHAVIOR_IDENTITY(bhvTree)
    SOURCE_BEHAVIOR_IDENTITY(bhvMessagePanel)
    SOURCE_BEHAVIOR_IDENTITY(bhv1Up)
    SOURCE_BEHAVIOR_IDENTITY(bhvHidden1up)
    SOURCE_BEHAVIOR_IDENTITY(bhvHidden1upTrigger)
    SOURCE_BEHAVIOR_IDENTITY(bhvHidden1upInPoleSpawner)
    SOURCE_BEHAVIOR_IDENTITY(bhvTripletButterfly)
    // Castle Inside area-2's authored Boo may be unloaded while the audio
    // route allocates its source objects. Keep the object-despawn payload
    // source-bound instead of exposing the build-layout-dependent behavior
    // pointer delta.
    SOURCE_BEHAVIOR_IDENTITY(bhvBooInCastle)
    // Castle Inside's authored painting death-warp objects use a BREAK-only
    // script but still participate in actor snapshots. Their owner identity
    // must remain semantic across Debug, ASan, and Release layouts.
    SOURCE_BEHAVIOR_IDENTITY(bhvPaintingDeathWarp)
    // Castle Inside's authored painting star-collect warp objects share the
    // four painting coordinates with the adjacent death-warp objects. Their
    // snapshots are retained separately at the same positions; publish the
    // source behavior name instead of the layout-dependent pointer delta.
    SOURCE_BEHAVIOR_IDENTITY(bhvPaintingStarCollectWarp)
    // Castle Inside area-1's second object at (2816, 1200, -256) is the
    // authored 270-degree death warp. Its source position and yaw distinguish
    // it from the adjacent 90-degree airborne star-collect warp; publish the
    // source behavior name instead of the layout-dependent pointer delta.
    SOURCE_BEHAVIOR_IDENTITY(bhvDeathWarp)
    // Castle Inside area-1's adjacent object at (2816, 1200, -256) is the
    // authored 90-degree airborne star-collect warp. Its shared position with
    // the 270-degree death warp requires source ordering plus yaw provenance;
    // publish the source behavior name instead of the layout-dependent
    // pointer delta.
    SOURCE_BEHAVIOR_IDENTITY(bhvAirborneStarCollectWarp)
    // Castle Inside area-1's authored launch-death warp shares its source
    // position and -135-degree angle with the adjacent launch-star warp.
    // Publish the source behavior name instead of the layout-dependent
    // pointer delta.
    SOURCE_BEHAVIOR_IDENTITY(bhvLaunchDeathWarp)
    // Castle Inside area-1's adjacent launch-star warp shares the authored
    // position and -135-degree angle with the launch-death warp. Publish its
    // source behavior name instead of the layout-dependent pointer delta.
    SOURCE_BEHAVIOR_IDENTITY(bhvLaunchStarCollectWarp)
    // Castle Inside area-1's authored hard-air knock-back warp shares its
    // position with the adjacent airborne/death warp entries. Publish the
    // source behavior name instead of the layout-dependent pointer delta.
    SOURCE_BEHAVIOR_IDENTITY(bhvHardAirKnockBackWarp)
    // Castle Inside area-1's authored airborne-death warp shares its source
    // position with the adjacent airborne and hard-air warp entries. Publish
    // the source behavior name instead of the layout-dependent pointer delta.
    SOURCE_BEHAVIOR_IDENTITY(bhvAirborneDeathWarp)
    // Castle Inside area-1's authored airborne warp shares its source
    // position with the adjacent airborne-death and hard-air warp entries.
    // Publish the source behavior name instead of the layout-dependent
    // pointer delta.
    SOURCE_BEHAVIOR_IDENTITY(bhvAirborneWarp)
    // Castle Inside area-1's two authored instant-active warp entries share
    // one behavior but remain distinct source objects by parameter/order.
    // Publish the source behavior name instead of the layout-dependent
    // pointer delta.
    SOURCE_BEHAVIOR_IDENTITY(bhvInstantActiveWarp)
    // Castle Inside area-1's authored subject-42 warp uses the source
    // behavior name rather than the build-layout-dependent pointer delta.
    SOURCE_BEHAVIOR_IDENTITY(bhvWarp)
    // Castle Inside area-1's second authored eight-star door is the subject-
    // 49 object at the second source entry in levels/castle_inside/script.c.
    // Publish the source behavior name so the full-trace route remains stable
    // across Debug, ASan, and Release behavior-script layouts.
    SOURCE_BEHAVIOR_IDENTITY(bhvStarDoor)
    // Castle Inside area-1's authored macro_yellow_coin_2 entries use
    // bhvOneCoin. Publish its source-name identity so the high-score audio
    // route remains byte-stable across Debug, ASan, and Release layouts.
    SOURCE_BEHAVIOR_IDENTITY(bhvOneCoin)
    // Castle Inside area-1's first authored macro sign is bhvSignOnWall.
    // Publish its source-name identity so the high-score route is stable
    // across Debug, ASan, and Release behavior-script layouts. Unknown
    // scripts still use the legacy anchor-relative fallback below.
    SOURCE_BEHAVIOR_IDENTITY(bhvSignOnWall)
    // Castle Inside's authored floor-trap route reaches both the parent
    // script and its source-spawned child. Keep their owner identities
    // semantic across Debug, ASan, and Release behavior-script layouts;
    // unknown scripts still use the legacy anchor-relative fallback below.
    SOURCE_BEHAVIOR_IDENTITY(bhvFloorTrapInCastle)
    SOURCE_BEHAVIOR_IDENTITY(bhvCastleFloorTrap)
    // Castle Inside area-1's authored Toad message object is the subject-51
    // owner in the high-score audio route. Publish its source behavior name
    // instead of the layout-dependent pointer delta.
    SOURCE_BEHAVIOR_IDENTITY(bhvToadMessage)
    // Castle Inside area-2's authored tank-fish group at (2778, 507, 1255)
    // participates in the audio route's actor snapshots. Publish its source
    // behavior identity so linked-layout deltas cannot cross the Swift seam.
    SOURCE_BEHAVIOR_IDENTITY(bhvTankFishGroup)
    SOURCE_BEHAVIOR_IDENTITY(bhvFishGroup)
    // Castle Inside area-1's fourth authored tank-fish group is subject 55.
    // Publish its source behavior name so the aquarium owner remains stable
    // across Debug, ASan, and Release behavior-script layouts.
    SOURCE_BEHAVIOR_IDENTITY(bhvTankFishGroup)
    // Castle Inside area-1's authored generic fish group is subject 59.
    // Publish its source behavior name so the fish-group owner remains stable
    // across Debug, ASan, and Release behavior-script layouts.
    SOURCE_BEHAVIOR_IDENTITY(bhvFishGroup)
    // The effects route allocates sparkle particles through the authored
    // source behavior. Publish its semantic identity instead of the
    // build-layout-dependent behavior pointer delta.
    SOURCE_BEHAVIOR_IDENTITY(bhvSparkleParticleSpawner)
    SOURCE_BEHAVIOR_IDENTITY(bhvCloud)
    SOURCE_BEHAVIOR_IDENTITY(bhvCloudPart)
    SOURCE_BEHAVIOR_IDENTITY(bhvClockMinuteHand)
    SOURCE_BEHAVIOR_IDENTITY(bhvClockHourHand)
    SOURCE_BEHAVIOR_IDENTITY(bhvTTC2DRotator)
    // Snowman's Land's source-authored Spindrift route uses the semantic
    // behavior name rather than a Debug/ASan/Release pointer delta.
    SOURCE_BEHAVIOR_IDENTITY(bhvSpindrift)
    // Snowman's Land's source-authored Snowman wind route crosses a private
    // value-only receipt seam; keep its actor identity independent of the
    // linked behavior-script layout.
    SOURCE_BEHAVIOR_IDENTITY(bhvSLSnowmanWind)
    // SSL's source-authored Spindel route also crosses a value-only seam;
    // publish its semantic behavior name rather than a linked pointer delta.
    SOURCE_BEHAVIOR_IDENTITY(bhvSpindel)
    // Whomp's Fortress' source-authored King Whomp crosses a private
    // value-only receipt seam. Keep both the King owner and the source star
    // helper's behavior identity semantic across Debug, ASan, and Release;
    // the route receipt separately names the reward child as bhvStar.
    SOURCE_BEHAVIOR_IDENTITY(bhvWhompKingBoss)
    SOURCE_BEHAVIOR_IDENTITY(bhvStar)
    SOURCE_BEHAVIOR_IDENTITY(bhvStarSpawnCoordinates)
    // The WDW express elevator family uses semantic source-name identities;
    // behavior-script pointer deltas differ across Debug, ASan, and Release.
    SOURCE_BEHAVIOR_IDENTITY(bhvWdwExpressElevator)
    SOURCE_BEHAVIOR_IDENTITY(bhvWdwExpressElevatorPlatform)
    // The Bob-omb Battlefield seesaw route uses the same fixed-width
    // semantic identity as its Swift owner bridge. Do not expose the linked
    // behavior-script address through the generic actor boundary.
    if (behavior == segmented_to_virtual(bhvSeesawPlatform)) {
        return UINT64_C(0x006268765f737377);
    }
#undef SOURCE_BEHAVIOR_IDENTITY
    // ASLR moves all linked behavior scripts together; an anchor-relative
    // identity stays stable for the exact build fingerprint in the trace.
    return (uint64_t) ((uintptr_t) behavior - (uintptr_t) bhvMario);
}

static SM64ModernGameplaySubsystem actor_subsystem_for_level(void) {
    switch (gCurrLevelNum) {
        case LEVEL_BOB:
            return SM64_MODERN_GAMEPLAY_SUBSYSTEM_ACTOR_BOBOMB_BATTLEFIELD;
        case LEVEL_JRB:
            return SM64_MODERN_GAMEPLAY_SUBSYSTEM_ACTOR_JOLLY_ROGER_BAY;
        case LEVEL_BOWSER_1:
            return SM64_MODERN_GAMEPLAY_SUBSYSTEM_ACTOR_BOWSER_ONE;
        default:
            return SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL;
    }
}

static SM64ModernGameplaySubsystem current_subsystem(void) {
    if (sSubsystemStackDepth > 0) {
        return sSubsystemStack[sSubsystemStackDepth - 1u];
    }
    if (gCurrentObject && gCurrentObject != gMarioObject) {
        return actor_subsystem_for_level();
    }
    return SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL;
}

static void initialize_result(SM64ModernGameplaySubsystem subsystem) {
    memset(&sResults[subsystem], 0, sizeof(sResults[subsystem]));
    sResults[subsystem].header.abi_version = SM64_MODERN_ABI_VERSION_1;
    sResults[subsystem].header.struct_size = sizeof(sResults[subsystem]);
    sResults[subsystem].subsystem = subsystem;
    sResults[subsystem].authority = SM64_MODERN_AUTHORITY_C;
    sResults[subsystem].status = SM64_MODERN_STATUS_OK;

    memset(&sDivergences[subsystem], 0, sizeof(sDivergences[subsystem]));
    sDivergences[subsystem].header.abi_version = SM64_MODERN_ABI_VERSION_1;
    sDivergences[subsystem].header.struct_size = sizeof(sDivergences[subsystem]);
    sDivergences[subsystem].subsystem = subsystem;
}

static void set_divergence(SM64ModernGameplaySubsystem subsystem,
                           SM64ModernGameplayDivergenceReason reason,
                           const SM64ModernGameplayTraceRecordV1 *expected,
                           const SM64ModernGameplayTraceRecordV1 *actual,
                           uint32_t value_index,
                           bool fatal) {
    if (!valid_subsystem(subsystem)) {
        subsystem = SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL;
    }
    if (sDivergences[subsystem].reason != SM64_MODERN_DIVERGENCE_NONE) {
        return;
    }

    SM64ModernGameplayDivergenceV1 *divergence = &sDivergences[subsystem];
    divergence->reason = reason;
    divergence->simulation_tick = actual ? actual->envelope.simulation_tick
                                         : (expected ? expected->envelope.simulation_tick : sSimulationTick);
    divergence->value_index = value_index;
    if (expected) {
        divergence->expected_kind = expected->envelope.record_kind;
        divergence->expected_record_id = expected->record_id;
        divergence->expected_subject_id = expected->subject_id;
        divergence->expected_sequence = expected->sequence;
        if (value_index < expected->value_count) {
            divergence->expected_value = expected->values[value_index];
        }
    }
    if (actual) {
        divergence->actual_kind = actual->envelope.record_kind;
        divergence->actual_record_id = actual->record_id;
        divergence->actual_subject_id = actual->subject_id;
        divergence->actual_sequence = actual->sequence;
        if (value_index < actual->value_count) {
            divergence->actual_value = actual->values[value_index];
        }
    }
    sResults[subsystem].eligible_for_swift = 0;
    sResults[subsystem].status = SM64_MODERN_STATUS_PARITY_DIVERGED;
    if (fatal) {
        sStatus = SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
}

static SM64ModernGameplayDivergenceReason compare_records(
    const SM64ModernGameplayTraceRecordV1 *expected,
    const SM64ModernGameplayTraceRecordV1 *actual,
    uint32_t *out_value_index) {
    *out_value_index = 0;
    if (expected->envelope.record_kind != actual->envelope.record_kind) {
        return SM64_MODERN_DIVERGENCE_RECORD_KIND;
    }
    if (expected->envelope.subsystem != actual->envelope.subsystem) {
        return SM64_MODERN_DIVERGENCE_SUBSYSTEM;
    }
    if (expected->record_id != actual->record_id) {
        return SM64_MODERN_DIVERGENCE_RECORD_ID;
    }
    if (expected->subject_id != actual->subject_id) {
        return SM64_MODERN_DIVERGENCE_SUBJECT;
    }
    if (expected->sequence != actual->sequence) {
        return SM64_MODERN_DIVERGENCE_SEQUENCE;
    }
    if (expected->value_count != actual->value_count) {
        return SM64_MODERN_DIVERGENCE_VALUE_COUNT;
    }
    for (uint32_t index = 0; index < expected->value_count; ++index) {
        if (expected->values[index] != actual->values[index]) {
            *out_value_index = index;
            return SM64_MODERN_DIVERGENCE_VALUE;
        }
    }
    return SM64_MODERN_DIVERGENCE_NONE;
}

static bool validate_record(const SM64ModernGameplayTraceRecordV1 *record) {
    return record
        && record->envelope.header.abi_version == SM64_MODERN_ABI_VERSION_1
        && record->envelope.header.struct_size >= sizeof(record->envelope)
        && record->envelope.payload_size == sizeof(*record) - sizeof(record->envelope)
        && valid_subsystem(record->envelope.subsystem)
        && record->value_count <= SM64_MODERN_GAMEPLAY_RECORD_VALUE_CAPACITY;
}

static bool validate_record_hash(const SM64ModernGameplayTraceRecordV1 *record) {
    return validate_record(record) && record->canonical_hash == hash_record(record);
}

static SM64ModernGameplayTraceRecordV1 make_record(SM64ModernGameplaySubsystem subsystem,
                                                    SM64ModernGameplayRecordKind kind,
                                                    uint32_t record_id,
                                                    uint32_t subject_id,
                                                    const uint64_t *values,
                                                    uint32_t value_count) {
    SM64ModernGameplayTraceRecordV1 record;
    memset(&record, 0, sizeof(record));
    record.envelope.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    record.envelope.header.struct_size = sizeof(record.envelope);
    record.envelope.simulation_tick = sSimulationTick;
    record.envelope.subsystem = subsystem;
    record.envelope.record_kind = kind;
    record.envelope.payload_size = sizeof(record) - sizeof(record.envelope);
    record.record_id = record_id;
    record.subject_id = subject_id;
    record.sequence = valid_subsystem(subsystem) ? sSequence[subsystem]++ : 0;
    record.value_count = value_count;
    if (values && value_count > 0) {
        memcpy(record.values, values, value_count * sizeof(record.values[0]));
    }
    record.canonical_hash = hash_record(&record);
    return record;
}

static void append_candidate_reference(const SM64ModernGameplayTraceRecordV1 *record) {
    if (sConfig.mode != SM64_MODERN_GAMEPLAY_PARITY_SHADOW
        || record->envelope.record_kind == SM64_MODERN_GAMEPLAY_RECORD_TRACE_HEADER) {
        return;
    }
    struct CandidateRecords *candidate = &sCandidateRecords[record->envelope.subsystem];
    if (candidate->actual_count >= PARITY_CANDIDATE_RECORD_CAPACITY) {
        set_divergence(record->envelope.subsystem,
                       SM64_MODERN_DIVERGENCE_CANDIDATE_MISSING,
                       record,
                       NULL,
                       0,
                       false);
        return;
    }
    candidate->records[candidate->actual_count++] = *record;
}

static void process_actual_record(SM64ModernGameplayTraceRecordV1 *actual) {
    if (!subsystem_enabled(actual->envelope.subsystem) || sStatus != SM64_MODERN_STATUS_OK) {
        return;
    }

    SM64ModernGameplayParityResultV1 *result = &sResults[actual->envelope.subsystem];
    actual->canonical_hash = hash_record(actual);
    result->actual_records++;
    result->actual_hash = aggregate_hash(result->actual_hash, actual->canonical_hash);

    if (sConfig.mode == SM64_MODERN_GAMEPLAY_PARITY_RECORD) {
        const SM64ModernStatus status = sStream.write(sStream.context, actual);
        if (status != SM64_MODERN_STATUS_OK) {
            result->status = status;
            sStatus = status;
        }
        return;
    }

    SM64ModernGameplayTraceRecordV1 expected;
    memset(&expected, 0, sizeof(expected));
    const SM64ModernStatus read_status = sStream.read(sStream.context, &expected);
    if (read_status == SM64_MODERN_STATUS_END_OF_STREAM) {
        set_divergence(actual->envelope.subsystem,
                       SM64_MODERN_DIVERGENCE_RECORD_EXTRA,
                       NULL,
                       actual,
                       0,
                       true);
        return;
    }
    if (read_status != SM64_MODERN_STATUS_OK) {
        result->status = read_status;
        sStatus = read_status;
        return;
    }
    if (!validate_record_hash(&expected)) {
        set_divergence(actual->envelope.subsystem,
                       actual->envelope.record_kind == SM64_MODERN_GAMEPLAY_RECORD_TRACE_HEADER
                           ? SM64_MODERN_DIVERGENCE_TRACE_HEADER
                           : SM64_MODERN_DIVERGENCE_RECORD_KIND,
                       validate_record(&expected) ? &expected : NULL,
                       actual,
                       0,
                       true);
        return;
    }

    SM64ModernGameplaySubsystem result_subsystem = actual->envelope.subsystem;
    result->expected_records++;
    result->expected_hash = aggregate_hash(result->expected_hash, expected.canonical_hash);
    uint32_t value_index;
    const SM64ModernGameplayDivergenceReason reason = compare_records(&expected, actual, &value_index);
    if (reason != SM64_MODERN_DIVERGENCE_NONE) {
        set_divergence(result_subsystem,
                       actual->envelope.record_kind == SM64_MODERN_GAMEPLAY_RECORD_TRACE_HEADER
                           ? SM64_MODERN_DIVERGENCE_TRACE_HEADER : reason,
                       &expected,
                       actual,
                       value_index,
                       true);
        return;
    }
    result->matched_records++;
    append_candidate_reference(actual);
    if (actual->envelope.subsystem != SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL
        && sAuthorities[actual->envelope.subsystem] == SM64_MODERN_AUTHORITY_SHADOW_SWIFT
        && sm64_modern_gameplay_migration_status() == SM64_MODERN_STATUS_OK) {
        SM64ModernGameplayTraceRecordV1 candidate;
        const SM64ModernStatus transform_status = sm64_modern_gameplay_transform_candidate(
            actual, &candidate);
        if (transform_status != SM64_MODERN_STATUS_OK) {
            result->status = transform_status;
            sStatus = transform_status;
            return;
        }
        (void) submit_candidate_record(&candidate);
    }
}

static SM64ModernOracleTraceDomain oracle_domain_for_subsystem(
    SM64ModernGameplaySubsystem subsystem) {
    switch (subsystem) {
        case SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO:
            return SM64_MODERN_ORACLE_DOMAIN_MARIO;
        case SM64_MODERN_GAMEPLAY_SUBSYSTEM_INTERACTION:
            return SM64_MODERN_ORACLE_DOMAIN_INTERACTION;
        case SM64_MODERN_GAMEPLAY_SUBSYSTEM_CAMERA:
            return SM64_MODERN_ORACLE_DOMAIN_CAMERA;
        case SM64_MODERN_GAMEPLAY_SUBSYSTEM_ACTOR_BOBOMB_BATTLEFIELD:
        case SM64_MODERN_GAMEPLAY_SUBSYSTEM_ACTOR_JOLLY_ROGER_BAY:
        case SM64_MODERN_GAMEPLAY_SUBSYSTEM_ACTOR_BOWSER_ONE:
            return SM64_MODERN_ORACLE_DOMAIN_OBJECT;
        case SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL:
        default:
            return SM64_MODERN_ORACLE_DOMAIN_GLOBAL;
    }
}

static void record_oracle_domain_values(SM64ModernOracleTraceDomain domain,
                                         SM64ModernGameplayRecordKind kind,
                                         uint32_t record_id,
                                         uint32_t subject_id,
                                         const uint64_t *values,
                                         uint32_t value_count) {
    if (!sm64_modern_oracle_trace_is_active()) {
        return;
    }

    // Save byte mutation/persistence, render packets, script/behavior events,
    // collision queries, RNG draws, and audio sequencing route through the
    // dedicated schema-4 seams below. Inventory execution closure remains a
    // separate qualification gate.

    SM64ModernOracleTraceRecordKind oracle_kind = SM64_MODERN_ORACLE_RECORD_STATE;
    uint64_t oracle_record_id = record_id;
    if (kind == SM64_MODERN_GAMEPLAY_RECORD_INPUT) {
        domain = SM64_MODERN_ORACLE_DOMAIN_INPUT;
        oracle_kind = SM64_MODERN_ORACLE_RECORD_INPUT;
        // Schema 3 uses record ID zero for the controller sample; schema 4's
        // inventory reserves input ID one so zero remains an invalid sentinel.
        oracle_record_id++;
    } else if (kind == SM64_MODERN_GAMEPLAY_RECORD_EFFECT) {
        domain = SM64_MODERN_ORACLE_DOMAIN_EFFECT;
        oracle_kind = SM64_MODERN_ORACLE_RECORD_EFFECT;
    }

    const SM64ModernStatus coverage_status = sm64_modern_oracle_trace_mark_coverage(
        domain,
        oracle_record_id);
    if (coverage_status != SM64_MODERN_STATUS_OK && sStatus == SM64_MODERN_STATUS_OK) {
        sStatus = coverage_status;
        return;
    }

    const SM64ModernStatus status = sm64_modern_oracle_trace_record(
        domain,
        oracle_kind,
        subject_id,
        oracle_record_id,
        0,
        values,
        value_count);
    if (status != SM64_MODERN_STATUS_OK && sStatus == SM64_MODERN_STATUS_OK) {
        sStatus = status;
    }
}

static void record_oracle_values(SM64ModernGameplaySubsystem subsystem,
                                 SM64ModernGameplayRecordKind kind,
                                 uint32_t record_id,
                                 uint32_t subject_id,
                                 const uint64_t *values,
                                 uint32_t value_count) {
    record_oracle_domain_values(oracle_domain_for_subsystem(subsystem),
                                kind,
                                record_id,
                                subject_id,
                                values,
                                value_count);
}

static void observe_effect_receipt(uint32_t effect_id,
                                   uint32_t subject_id,
                                   const uint64_t *values,
                                   uint32_t value_count) {
    if (!sm64_modern_oracle_trace_is_active()) {
        return;
    }

    SM64ModernEffectReceiptV1 receipt;
    memset(&receipt, 0, sizeof(receipt));
    receipt.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    receipt.header.struct_size = sizeof(receipt);
    receipt.simulation_tick = sm64_modern_oracle_trace_simulation_tick();
    receipt.subject_id = subject_id;
    receipt.effect_id = effect_id;
    receipt.sequence = sm64_modern_oracle_trace_next_sequence(
        SM64_MODERN_ORACLE_DOMAIN_EFFECT);
    receipt.value_count = value_count;
    receipt.flags = 0;
    if (values && value_count > 0u) {
        memcpy(receipt.values, values, value_count * sizeof(receipt.values[0]));
    }

    // Hash the exact schema-4 record that record_oracle_values will create.
    // Swift can therefore validate receipt bytes without trusting a pointer
    // or a separate callback-side channel.
    SM64ModernOracleTraceRecordV1 oracle_record;
    memset(&oracle_record, 0, sizeof(oracle_record));
    oracle_record.simulation_tick = receipt.simulation_tick;
    oracle_record.domain = SM64_MODERN_ORACLE_DOMAIN_EFFECT;
    oracle_record.record_kind = SM64_MODERN_ORACLE_RECORD_EFFECT;
    oracle_record.subject_id = receipt.subject_id;
    oracle_record.record_id = receipt.effect_id;
    oracle_record.sequence = receipt.sequence;
    oracle_record.value_count = receipt.value_count;
    oracle_record.flags = receipt.flags;
    memcpy(oracle_record.values, receipt.values, sizeof(oracle_record.values));
    receipt.canonical_hash = sm64_modern_oracle_trace_hash_record(&oracle_record);

    const SM64ModernStatus status = sm64_modern_effects_observe_receipt(&receipt);
    if (status != SM64_MODERN_STATUS_OK && sStatus == SM64_MODERN_STATUS_OK) {
        sStatus = status;
    }
}

static void record_values(SM64ModernGameplaySubsystem subsystem,
                          SM64ModernGameplayRecordKind kind,
                          uint32_t record_id,
                          uint32_t subject_id,
                          const uint64_t *values,
                          uint32_t value_count) {
    const bool parity_enabled = subsystem_enabled(subsystem);
    const bool oracle_enabled = sm64_modern_oracle_trace_is_active() != 0;
    if ((!parity_enabled && !oracle_enabled) || sStatus != SM64_MODERN_STATUS_OK) {
        return;
    }
    if (value_count > SM64_MODERN_GAMEPLAY_RECORD_VALUE_CAPACITY
        || (value_count > 0 && !values)) {
        sStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        return;
    }
    if (parity_enabled) {
        SM64ModernGameplayTraceRecordV1 record = make_record(subsystem,
                                                             kind,
                                                             record_id,
                                                             subject_id,
                                                             values,
                                                             value_count);
        process_actual_record(&record);
    }
    if (kind == SM64_MODERN_GAMEPLAY_RECORD_EFFECT) {
        observe_effect_receipt(record_id, subject_id, values, value_count);
    }
    record_oracle_values(subsystem, kind, record_id, subject_id, values, value_count);
}

static void record_scalar(SM64ModernGameplaySubsystem subsystem,
                          SM64ModernGameplayField field,
                          uint32_t subject_id,
                          uint64_t value) {
    record_values(subsystem,
                  SM64_MODERN_GAMEPLAY_RECORD_SNAPSHOT,
                  field,
                  subject_id,
                  &value,
                  1);
}

static void finalize_candidate_tick(void) {
    if (sConfig.mode != SM64_MODERN_GAMEPLAY_PARITY_SHADOW || !sTickOpen) {
        return;
    }
    for (uint32_t subsystem = 1; subsystem < SM64_MODERN_GAMEPLAY_SUBSYSTEM_COUNT; ++subsystem) {
        if (!subsystem_enabled(subsystem)) {
            continue;
        }
        if (sAuthorities[subsystem] != SM64_MODERN_AUTHORITY_SHADOW_SWIFT) {
            continue;
        }
        struct CandidateRecords *candidate = &sCandidateRecords[subsystem];
        if (candidate->actual_count > candidate->candidate_count) {
            set_divergence(subsystem,
                           SM64_MODERN_DIVERGENCE_CANDIDATE_MISSING,
                           &candidate->records[candidate->candidate_count],
                           NULL,
                           0,
                           false);
        }
    }
}

void sm64_modern_parity_reset(void) {
    memset(&sConfig, 0, sizeof(sConfig));
    memset(&sStream, 0, sizeof(sStream));
    memset(sCandidateRecords, 0, sizeof(sCandidateRecords));
    memset(sSequence, 0, sizeof(sSequence));
    memset(sSubsystemStack, 0, sizeof(sSubsystemStack));
    sSubsystemStackDepth = 0;
    sSimulationTick = 0;
    sStatus = SM64_MODERN_STATUS_OK;
    sSessionActive = false;
    sTickOpen = false;
    for (uint32_t subsystem = 0; subsystem < SM64_MODERN_GAMEPLAY_SUBSYSTEM_COUNT; ++subsystem) {
        sAuthorities[subsystem] = SM64_MODERN_AUTHORITY_C;
        initialize_result(subsystem);
    }
}

static bool valid_config(const SM64ModernGameplayParityConfigV1 *config,
                         const SM64ModernGameplayTraceStreamApiV1 *stream) {
    return config
        && stream
        && config->header.abi_version == SM64_MODERN_ABI_VERSION_1
        && config->header.struct_size >= sizeof(*config)
        && config->mode >= SM64_MODERN_GAMEPLAY_PARITY_RECORD
        && config->mode <= SM64_MODERN_GAMEPLAY_PARITY_SHADOW
        && config->subsystem_mask != 0
        && (config->subsystem_mask
            & SM64_MODERN_GAMEPLAY_SUBSYSTEM_MASK(SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL)) != 0
        && (config->subsystem_mask & ~SM64_MODERN_GAMEPLAY_SUBSYSTEM_MASK_ALL) == 0
        && stream->header.abi_version == SM64_MODERN_ABI_VERSION_1
        && stream->header.struct_size >= sizeof(*stream)
        && ((config->mode == SM64_MODERN_GAMEPLAY_PARITY_RECORD && stream->write)
            || (config->mode != SM64_MODERN_GAMEPLAY_PARITY_RECORD && stream->read));
}

static SM64ModernStatus begin_session(const SM64ModernGameplayParityConfigV1 *config,
                                      const SM64ModernGameplayTraceStreamApiV1 *stream) {
    if (sSessionActive) {
        return SM64_MODERN_STATUS_INVALID_STATE;
    }
    if (!valid_config(config, stream)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }

    sm64_modern_parity_reset();
    memcpy(&sConfig, config, sizeof(sConfig));
    memcpy(&sStream, stream, sizeof(sStream));
    sSessionActive = true;

    // The build value is deliberately timebase-qualified. Traces captured at
    // different simulation rates must diverge at their first record rather
    // than being compared as if their tick numbers represented equal time.
    const uint64_t timebase_qualified_build = hash_u64(
        sConfig.build_fingerprint,
        sm64_modern_timebase_fingerprint());
    const uint64_t header_values[4] = {
        SM64_MODERN_GAMEPLAY_PARITY_SCHEMA_VERSION,
        timebase_qualified_build,
        sConfig.initial_state_fingerprint,
        sConfig.subsystem_mask,
    };
    SM64ModernGameplayTraceRecordV1 header = make_record(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL,
        SM64_MODERN_GAMEPLAY_RECORD_TRACE_HEADER,
        SM64_MODERN_GAMEPLAY_PARITY_SCHEMA_VERSION,
        0,
        header_values,
        4);
    process_actual_record(&header);
    return sStatus;
}

static SM64ModernStatus end_session(void) {
    if (!sSessionActive) {
        return SM64_MODERN_STATUS_INVALID_STATE;
    }
    finalize_candidate_tick();

    if (sStatus == SM64_MODERN_STATUS_OK
        && sConfig.mode != SM64_MODERN_GAMEPLAY_PARITY_RECORD) {
        SM64ModernGameplayTraceRecordV1 extra;
        memset(&extra, 0, sizeof(extra));
        const SM64ModernStatus read_status = sStream.read(sStream.context, &extra);
        if (read_status == SM64_MODERN_STATUS_OK) {
            const SM64ModernGameplaySubsystem subsystem = validate_record(&extra)
                ? extra.envelope.subsystem : SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL;
            set_divergence(subsystem,
                           SM64_MODERN_DIVERGENCE_RECORD_MISSING,
                           validate_record(&extra) ? &extra : NULL,
                           NULL,
                           0,
                           true);
        } else if (read_status != SM64_MODERN_STATUS_END_OF_STREAM) {
            sStatus = read_status;
        }
    }

    if (sConfig.mode == SM64_MODERN_GAMEPLAY_PARITY_SHADOW) {
        for (uint32_t subsystem = 1; subsystem < SM64_MODERN_GAMEPLAY_SUBSYSTEM_COUNT; ++subsystem) {
            SM64ModernGameplayParityResultV1 *result = &sResults[subsystem];
            result->eligible_for_swift = sAuthorities[subsystem] == SM64_MODERN_AUTHORITY_SHADOW_SWIFT
                && result->status == SM64_MODERN_STATUS_OK
                && result->actual_records > 0
                && result->candidate_records == result->actual_records;
            if (result->status == SM64_MODERN_STATUS_PARITY_DIVERGED
                && sStatus == SM64_MODERN_STATUS_OK) {
                sStatus = SM64_MODERN_STATUS_PARITY_DIVERGED;
            }
        }
    }
    sSessionActive = false;
    sTickOpen = false;
    return sStatus;
}

static SM64ModernStatus get_result(SM64ModernGameplaySubsystem subsystem,
                                   SM64ModernGameplayParityResultV1 *out_result) {
    if (!valid_subsystem(subsystem) || !out_result) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    sResults[subsystem].authority = sAuthorities[subsystem];
    memcpy(out_result, &sResults[subsystem], sizeof(*out_result));
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus get_first_divergence(SM64ModernGameplaySubsystem subsystem,
                                             SM64ModernGameplayDivergenceV1 *out_divergence) {
    if (!valid_subsystem(subsystem) || !out_divergence) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    memcpy(out_divergence, &sDivergences[subsystem], sizeof(*out_divergence));
    return SM64_MODERN_STATUS_OK;
}

static SM64ModernStatus submit_candidate_record(const SM64ModernGameplayTraceRecordV1 *record) {
    if (!sSessionActive || sConfig.mode != SM64_MODERN_GAMEPLAY_PARITY_SHADOW || !validate_record(record)) {
        return SM64_MODERN_STATUS_INVALID_STATE;
    }
    const SM64ModernGameplaySubsystem subsystem = record->envelope.subsystem;
    if (subsystem == SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL || !subsystem_enabled(subsystem)) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (sAuthorities[subsystem] != SM64_MODERN_AUTHORITY_SHADOW_SWIFT) {
        return SM64_MODERN_STATUS_UNSUPPORTED_AUTHORITY;
    }

    struct CandidateRecords *candidate = &sCandidateRecords[subsystem];
    if (candidate->candidate_count >= candidate->actual_count) {
        set_divergence(subsystem,
                       SM64_MODERN_DIVERGENCE_CANDIDATE_EXTRA,
                       NULL,
                       record,
                       0,
                       false);
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }

    const SM64ModernGameplayTraceRecordV1 *expected =
        &candidate->records[candidate->candidate_count++];
    SM64ModernGameplayTraceRecordV1 actual = *record;
    actual.canonical_hash = hash_record(&actual);
    SM64ModernGameplayParityResultV1 *result = &sResults[subsystem];
    result->candidate_records++;
    result->candidate_hash = aggregate_hash(result->candidate_hash, actual.canonical_hash);

    uint32_t value_index;
    const SM64ModernGameplayDivergenceReason reason = compare_records(expected, &actual, &value_index);
    if (reason != SM64_MODERN_DIVERGENCE_NONE) {
        set_divergence(subsystem, reason, expected, &actual, value_index, false);
        return SM64_MODERN_STATUS_PARITY_DIVERGED;
    }
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_get_gameplay_parity_api(uint32_t requested_version,
                                                     uint32_t output_size,
                                                     SM64ModernGameplayParityApiV1 *out_api) {
    const SM64ModernGameplayParityApiV1 api = {
        { SM64_MODERN_ABI_VERSION_1, sizeof(SM64ModernGameplayParityApiV1) },
        begin_session,
        end_session,
        get_result,
        get_first_divergence,
        submit_candidate_record,
    };
    if (!out_api) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (requested_version != SM64_MODERN_ABI_VERSION_1) {
        return SM64_MODERN_STATUS_UNSUPPORTED_VERSION;
    }
    if (output_size < sizeof(api)) {
        return SM64_MODERN_STATUS_BUFFER_TOO_SMALL;
    }
    memcpy(out_api, &api, sizeof(api));
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_gameplay_get_authority(SM64ModernGameplaySubsystem subsystem,
                                                     SM64ModernAuthority *out_authority) {
    if (!valid_subsystem(subsystem) || !out_authority) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    *out_authority = sAuthorities[subsystem];
    return SM64_MODERN_STATUS_OK;
}

SM64ModernStatus sm64_modern_gameplay_set_authority(SM64ModernGameplaySubsystem subsystem,
                                                     SM64ModernAuthority authority) {
    if (!valid_subsystem(subsystem) || authority > SM64_MODERN_AUTHORITY_SWIFT) {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT;
    }
    if (authority == SM64_MODERN_AUTHORITY_C) {
        sAuthorities[subsystem] = authority;
        return SM64_MODERN_STATUS_OK;
    }
    if (subsystem == SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL) {
        return SM64_MODERN_STATUS_UNSUPPORTED_AUTHORITY;
    }
    if (authority == SM64_MODERN_AUTHORITY_SHADOW_SWIFT) {
        if (!sSessionActive || sConfig.mode != SM64_MODERN_GAMEPLAY_PARITY_SHADOW
            || !subsystem_enabled(subsystem)) {
            return SM64_MODERN_STATUS_UNSUPPORTED_AUTHORITY;
        }
        sAuthorities[subsystem] = authority;
        return SM64_MODERN_STATUS_OK;
    }
    if (!sResults[subsystem].eligible_for_swift) {
        return SM64_MODERN_STATUS_UNSUPPORTED_AUTHORITY;
    }
    sAuthorities[subsystem] = authority;
    return SM64_MODERN_STATUS_OK;
}

void sm64_modern_parity_begin_tick(void) {
    const bool oracle_enabled = sm64_modern_oracle_trace_is_active() != 0;
    if ((!sSessionActive && !oracle_enabled) || sStatus != SM64_MODERN_STATUS_OK) {
        return;
    }
    if (sSessionActive) {
        finalize_candidate_tick();
        sSimulationTick++;
        memset(sSequence, 0, sizeof(sSequence));
        memset(sCandidateRecords, 0, sizeof(sCandidateRecords));
        sTickOpen = true;
    }
    if (oracle_enabled) {
        sm64_modern_oracle_trace_begin_tick();
        if (sm64_modern_oracle_trace_status() != SM64_MODERN_STATUS_OK) {
            sStatus = sm64_modern_oracle_trace_status();
        }
    }
}

void sm64_modern_parity_end_tick(void) {
    if (sSessionActive) {
        finalize_candidate_tick();
        sTickOpen = false;
    }
    if (sm64_modern_oracle_trace_is_active()) {
        sm64_modern_oracle_trace_end_tick();
        if (sm64_modern_oracle_trace_status() != SM64_MODERN_STATUS_OK
            && sStatus == SM64_MODERN_STATUS_OK) {
            sStatus = sm64_modern_oracle_trace_status();
        }
    }
}

void sm64_modern_parity_filter_input(OSContPad *pad) {
    const bool oracle_enabled = sm64_modern_oracle_trace_is_active() != 0;
    if (!pad || (!subsystem_enabled(SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL) && !oracle_enabled)
        || sStatus != SM64_MODERN_STATUS_OK) {
        return;
    }

    const uint64_t oracle_values[2] = {
        pad->button,
        (uint64_t) (uint8_t) pad->stick_x
            | ((uint64_t) (uint8_t) pad->stick_y << 8u)
            | ((uint64_t) (uint8_t) pad->ext_stick_x << 16u)
            | ((uint64_t) (uint8_t) pad->ext_stick_y << 24u),
    };

    if (!sSessionActive) {
        record_oracle_values(SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL,
                             SM64_MODERN_GAMEPLAY_RECORD_INPUT,
                             0,
                             0,
                             oracle_values,
                             2);
        return;
    }

    if (sConfig.mode == SM64_MODERN_GAMEPLAY_PARITY_RECORD) {
        record_values(SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL,
                      SM64_MODERN_GAMEPLAY_RECORD_INPUT,
                      0,
                      0,
                      oracle_values,
                      2);
        return;
    }

    SM64ModernGameplayTraceRecordV1 expected;
    memset(&expected, 0, sizeof(expected));
    const SM64ModernStatus read_status = sStream.read(sStream.context, &expected);
    if (read_status != SM64_MODERN_STATUS_OK) {
        if (read_status == SM64_MODERN_STATUS_END_OF_STREAM) {
            set_divergence(SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL,
                           SM64_MODERN_DIVERGENCE_RECORD_EXTRA,
                           NULL,
                           NULL,
                           0,
                           true);
        } else {
            sStatus = read_status;
        }
        return;
    }

    if (!validate_record_hash(&expected)
        || expected.envelope.record_kind != SM64_MODERN_GAMEPLAY_RECORD_INPUT
        || expected.envelope.subsystem != SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL
        || expected.record_id != 0
        || expected.value_count != 2) {
        set_divergence(SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL,
                       SM64_MODERN_DIVERGENCE_RECORD_KIND,
                       &expected,
                       NULL,
                       0,
                       true);
        return;
    }

    const uint64_t packed_axes = expected.values[1];
    pad->button = (u16) expected.values[0];
    pad->stick_x = (s8) (uint8_t) packed_axes;
    pad->stick_y = (s8) (uint8_t) (packed_axes >> 8u);
    pad->ext_stick_x = (s8) (uint8_t) (packed_axes >> 16u);
    pad->ext_stick_y = (s8) (uint8_t) (packed_axes >> 24u);

    SM64ModernGameplayTraceRecordV1 actual = make_record(
        SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL,
        SM64_MODERN_GAMEPLAY_RECORD_INPUT,
        0,
        0,
        expected.values,
        expected.value_count);
    SM64ModernGameplayParityResultV1 *result = &sResults[SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL];
    result->actual_records++;
    result->expected_records++;
    result->actual_hash = aggregate_hash(result->actual_hash, actual.canonical_hash);
    result->expected_hash = aggregate_hash(result->expected_hash, expected.canonical_hash);
    uint32_t value_index;
    const SM64ModernGameplayDivergenceReason reason = compare_records(&expected, &actual, &value_index);
    if (reason == SM64_MODERN_DIVERGENCE_NONE) {
        result->matched_records++;
    } else {
        set_divergence(SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL,
                       reason,
                       &expected,
                       &actual,
                       value_index,
                       true);
    }
    const uint64_t replay_oracle_values[2] = {
        pad->button,
        (uint64_t) (uint8_t) pad->stick_x
            | ((uint64_t) (uint8_t) pad->stick_y << 8u)
            | ((uint64_t) (uint8_t) pad->ext_stick_x << 16u)
            | ((uint64_t) (uint8_t) pad->ext_stick_y << 24u),
    };
    record_oracle_values(SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL,
                         SM64_MODERN_GAMEPLAY_RECORD_INPUT,
                         0,
                         0,
                         replay_oracle_values,
                         2);
}

void sm64_modern_parity_record_test_snapshot(SM64ModernGameplaySubsystem subsystem,
                                              uint32_t field,
                                              uint32_t subject_id,
                                              const uint64_t *values,
                                              uint32_t value_count) {
    record_values(subsystem,
                  SM64_MODERN_GAMEPLAY_RECORD_SNAPSHOT,
                  field,
                  subject_id,
                  values,
                  value_count);
}

u32 sm64_modern_parity_audio_frame_count(u32 high_count, u32 default_count) {
    // Device drain timing is intentionally outside deterministic gameplay.
    // A parity session therefore requests a fixed pre-device PCM quantum.
    return (sSessionActive || sm64_modern_oracle_trace_is_active())
        ? high_count : default_count;
}

static void capture_global_snapshot(void) {
    SM64ModernGlobalStateSnapshotV1 snapshot;
    memset(&snapshot, 0, sizeof(snapshot));
    snapshot.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    snapshot.header.struct_size = sizeof(snapshot);
    snapshot.simulation_tick = sm64_modern_oracle_trace_is_active()
        ? sm64_modern_oracle_trace_simulation_tick()
        : sm64_modern_timebase_simulation_tick();
    snapshot.global_timer = gGlobalTimer;
    snapshot.level_number = (uint16_t) gCurrLevelNum;
    snapshot.area_index = (uint16_t) gCurrAreaIndex;
    snapshot.act_number = (uint16_t) gCurrActNum;
    snapshot.course_number = (uint16_t) gCurrCourseNum;
    snapshot.random_seed = random_seed_get();
    const SM64ModernStatus publication_status =
        sm64_modern_global_state_observe_snapshot(&snapshot);
    if (publication_status != SM64_MODERN_STATUS_OK
        && sStatus == SM64_MODERN_STATUS_OK) {
        sStatus = publication_status;
    }
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL,
                  SM64_MODERN_FIELD_GLOBAL_TIMER, 0, gGlobalTimer);
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL,
                  SM64_MODERN_FIELD_LEVEL, 0, (uint16_t) gCurrLevelNum);
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL,
                  SM64_MODERN_FIELD_AREA, 0, (uint16_t) gCurrAreaIndex);
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL,
                  SM64_MODERN_FIELD_ACT, 0, (uint16_t) gCurrActNum);
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL,
                  SM64_MODERN_FIELD_COURSE, 0, (uint16_t) gCurrCourseNum);
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL,
                  SM64_MODERN_FIELD_RANDOM_SEED, 0, random_seed_get());
}

static void capture_mario_snapshot(void) {
    if (!gMarioState) {
        return;
    }
    const struct MarioState *mario = gMarioState;
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                  SM64_MODERN_FIELD_MARIO_INPUT, 0, mario->input);
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                  SM64_MODERN_FIELD_MARIO_FLAGS, 0, mario->flags);
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                  SM64_MODERN_FIELD_MARIO_PARTICLE_FLAGS, 0, mario->particleFlags);
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                  SM64_MODERN_FIELD_MARIO_ACTION, 0, mario->action);
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                  SM64_MODERN_FIELD_MARIO_PREVIOUS_ACTION, 0, mario->prevAction);
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                  SM64_MODERN_FIELD_MARIO_ACTION_STATE, 0, mario->actionState);
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                  SM64_MODERN_FIELD_MARIO_ACTION_TIMER, 0, mario->actionTimer);
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                  SM64_MODERN_FIELD_MARIO_ACTION_ARGUMENT, 0, mario->actionArg);
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                  SM64_MODERN_FIELD_MARIO_INTENDED_MAGNITUDE, 0, float_bits(mario->intendedMag));
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                  SM64_MODERN_FIELD_MARIO_INTENDED_YAW, 0, (uint16_t) mario->intendedYaw);
    const uint64_t face_angle[3] = {
        (uint16_t) mario->faceAngle[0],
        (uint16_t) mario->faceAngle[1],
        (uint16_t) mario->faceAngle[2],
    };
    record_values(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                  SM64_MODERN_GAMEPLAY_RECORD_SNAPSHOT,
                  SM64_MODERN_FIELD_MARIO_FACE_ANGLE, 0, face_angle, 3);
    const uint64_t position[3] = {
        float_bits(mario->pos[0]), float_bits(mario->pos[1]), float_bits(mario->pos[2]),
    };
    record_values(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                  SM64_MODERN_GAMEPLAY_RECORD_SNAPSHOT,
                  SM64_MODERN_FIELD_MARIO_POSITION, 0, position, 3);
    const uint64_t velocity[3] = {
        float_bits(mario->vel[0]), float_bits(mario->vel[1]), float_bits(mario->vel[2]),
    };
    record_values(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                  SM64_MODERN_GAMEPLAY_RECORD_SNAPSHOT,
                  SM64_MODERN_FIELD_MARIO_VELOCITY, 0, velocity, 3);
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                  SM64_MODERN_FIELD_MARIO_FORWARD_VELOCITY, 0, float_bits(mario->forwardVel));
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                  SM64_MODERN_FIELD_MARIO_HEALTH, 0, (uint16_t) mario->health);
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                  SM64_MODERN_FIELD_MARIO_COINS, 0, (uint16_t) mario->numCoins);
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                  SM64_MODERN_FIELD_MARIO_STARS, 0, (uint16_t) mario->numStars);
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                  SM64_MODERN_FIELD_MARIO_FRAMES_SINCE_A, 0, mario->framesSinceA);
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO,
                  SM64_MODERN_FIELD_MARIO_FRAMES_SINCE_B, 0, mario->framesSinceB);
}

static void capture_interaction_snapshot(void) {
    if (!gMarioState) {
        return;
    }
    const struct MarioState *mario = gMarioState;
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_INTERACTION,
                  SM64_MODERN_FIELD_INTERACTION_TYPES, 0, mario->collidedObjInteractTypes);
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_INTERACTION,
                  SM64_MODERN_FIELD_INTERACTION_OBJECT, 0, object_slot(mario->interactObj));
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_INTERACTION,
                  SM64_MODERN_FIELD_INTERACTION_HELD_OBJECT, 0, object_slot(mario->heldObj));
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_INTERACTION,
                  SM64_MODERN_FIELD_INTERACTION_USED_OBJECT, 0, object_slot(mario->usedObj));
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_INTERACTION,
                  SM64_MODERN_FIELD_INTERACTION_RIDDEN_OBJECT, 0, object_slot(mario->riddenObj));
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_INTERACTION,
                  SM64_MODERN_FIELD_INTERACTION_HURT_COUNTER, 0, mario->hurtCounter);
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_INTERACTION,
                  SM64_MODERN_FIELD_INTERACTION_HEAL_COUNTER, 0, mario->healCounter);
}

static void capture_camera_snapshot(void) {
    if (!gCamera) {
        return;
    }
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_CAMERA,
                  SM64_MODERN_FIELD_CAMERA_MODE, 0, gCamera->mode);
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_CAMERA,
                  SM64_MODERN_FIELD_CAMERA_DEFAULT_MODE, 0, gCamera->defMode);
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_CAMERA,
                  SM64_MODERN_FIELD_CAMERA_CUTSCENE, 0, gCamera->cutscene);
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_CAMERA,
                  SM64_MODERN_FIELD_CAMERA_YAW, 0, (uint16_t) gCamera->yaw);
    record_scalar(SM64_MODERN_GAMEPLAY_SUBSYSTEM_CAMERA,
                  SM64_MODERN_FIELD_CAMERA_NEXT_YAW, 0, (uint16_t) gCamera->nextYaw);
    const uint64_t focus[3] = {
        float_bits(gCamera->focus[0]), float_bits(gCamera->focus[1]), float_bits(gCamera->focus[2]),
    };
    record_values(SM64_MODERN_GAMEPLAY_SUBSYSTEM_CAMERA,
                  SM64_MODERN_GAMEPLAY_RECORD_SNAPSHOT,
                  SM64_MODERN_FIELD_CAMERA_FOCUS, 0, focus, 3);
    const uint64_t position[3] = {
        float_bits(gCamera->pos[0]), float_bits(gCamera->pos[1]), float_bits(gCamera->pos[2]),
    };
    record_values(SM64_MODERN_GAMEPLAY_SUBSYSTEM_CAMERA,
                  SM64_MODERN_GAMEPLAY_RECORD_SNAPSHOT,
                  SM64_MODERN_FIELD_CAMERA_POSITION, 0, position, 3);
}

static void capture_actor_snapshot(void) {
    const SM64ModernGameplaySubsystem subsystem = actor_subsystem_for_level();
    const bool oracle_enabled = sm64_modern_oracle_trace_is_active() != 0;
    // Castle actors historically remain on the schema-3 GLOBAL subsystem.
    // Keep that authority mapping intact, but retain their object-domain
    // snapshots for the independent schema-4 oracle. Other GLOBAL levels stay
    // trace-silent here, as they did before the Castle route was captured.
    const bool source_oracle_objects = oracle_enabled
        && (gCurrLevelNum == LEVEL_CASTLE || gCurrLevelNum == LEVEL_RR
            || gCurrLevelNum == LEVEL_HMC || gCurrLevelNum == LEVEL_TTC
            || gCurrLevelNum == LEVEL_SL);
    if ((subsystem == SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL && !source_oracle_objects)
        || (!subsystem_enabled(subsystem) && !oracle_enabled)) {
        return;
    }
    for (uint32_t index = 0; index < OBJECT_POOL_CAPACITY; ++index) {
        const struct Object *object = &gObjectPool[index];
        if (object == gMarioObject || !(object->activeFlags & ACTIVE_FLAG_ACTIVE)) {
            continue;
        }
        const uint32_t subject = index + 1u;
        const SM64ModernOracleTraceDomain oracle_domain =
            SM64_MODERN_ORACLE_DOMAIN_OBJECT;
#define RECORD_ACTOR_SCALAR(field, value) \
        do { \
            if (source_oracle_objects) { \
                const uint64_t actor_value = (value); \
                record_oracle_domain_values(oracle_domain, \
                                            SM64_MODERN_GAMEPLAY_RECORD_SNAPSHOT, \
                                            (field), subject, &actor_value, 1); \
            } else { \
                record_scalar(subsystem, (field), subject, (value)); \
            } \
        } while (0)
        RECORD_ACTOR_SCALAR(SM64_MODERN_FIELD_ACTOR_BEHAVIOR,
                            behavior_identity(object->behavior));
        RECORD_ACTOR_SCALAR(SM64_MODERN_FIELD_ACTOR_ACTIVE_FLAGS,
                            object->activeFlags);
        RECORD_ACTOR_SCALAR(SM64_MODERN_FIELD_ACTOR_ACTION,
                            (uint32_t) object->oAction);
        RECORD_ACTOR_SCALAR(SM64_MODERN_FIELD_ACTOR_SUB_ACTION,
                            (uint32_t) object->oSubAction);
        RECORD_ACTOR_SCALAR(SM64_MODERN_FIELD_ACTOR_TIMER,
                            (uint32_t) object->oTimer);
        const uint64_t position[3] = {
            float_bits(object->oPosX), float_bits(object->oPosY), float_bits(object->oPosZ),
        };
        if (source_oracle_objects) {
            record_oracle_domain_values(oracle_domain,
                                        SM64_MODERN_GAMEPLAY_RECORD_SNAPSHOT,
                                        SM64_MODERN_FIELD_ACTOR_POSITION,
                                        subject,
                                        position,
                                        3);
        } else {
            record_values(subsystem, SM64_MODERN_GAMEPLAY_RECORD_SNAPSHOT,
                          SM64_MODERN_FIELD_ACTOR_POSITION, subject, position, 3);
        }
        const uint64_t velocity[3] = {
            float_bits(object->oVelX), float_bits(object->oVelY), float_bits(object->oVelZ),
        };
        if (source_oracle_objects) {
            record_oracle_domain_values(oracle_domain,
                                        SM64_MODERN_GAMEPLAY_RECORD_SNAPSHOT,
                                        SM64_MODERN_FIELD_ACTOR_VELOCITY,
                                        subject,
                                        velocity,
                                        3);
        } else {
            record_values(subsystem, SM64_MODERN_GAMEPLAY_RECORD_SNAPSHOT,
                          SM64_MODERN_FIELD_ACTOR_VELOCITY, subject, velocity, 3);
        }
        const uint64_t angle[3] = {
            (uint32_t) object->oMoveAnglePitch,
            (uint32_t) object->oMoveAngleYaw,
            (uint32_t) object->oMoveAngleRoll,
        };
        if (source_oracle_objects) {
            record_oracle_domain_values(oracle_domain,
                                        SM64_MODERN_GAMEPLAY_RECORD_SNAPSHOT,
                                        SM64_MODERN_FIELD_ACTOR_MOVE_ANGLE,
                                        subject,
                                        angle,
                                        3);
        } else {
            record_values(subsystem, SM64_MODERN_GAMEPLAY_RECORD_SNAPSHOT,
                          SM64_MODERN_FIELD_ACTOR_MOVE_ANGLE, subject, angle, 3);
        }
        RECORD_ACTOR_SCALAR(SM64_MODERN_FIELD_ACTOR_MOVE_FLAGS,
                            object->oMoveFlags);
        RECORD_ACTOR_SCALAR(SM64_MODERN_FIELD_ACTOR_INTERACTION_STATUS,
                            (uint32_t) object->oInteractStatus);
        RECORD_ACTOR_SCALAR(SM64_MODERN_FIELD_ACTOR_HELD_STATE,
                            object->oHeldState);
        RECORD_ACTOR_SCALAR(SM64_MODERN_FIELD_ACTOR_FLAGS,
                            object->oFlags);
        RECORD_ACTOR_SCALAR(SM64_MODERN_FIELD_ACTOR_FORWARD_VELOCITY,
                            float_bits(object->oForwardVel));
        RECORD_ACTOR_SCALAR(SM64_MODERN_FIELD_ACTOR_GRAPH_FLAGS,
                            (uint16_t) object->header.gfx.node.flags);
#undef RECORD_ACTOR_SCALAR
    }
}

void sm64_modern_parity_capture_snapshots(void) {
    if ((!sSessionActive && !sm64_modern_oracle_trace_is_active())
        || sStatus != SM64_MODERN_STATUS_OK) {
        return;
    }
    capture_global_snapshot();
    capture_mario_snapshot();
    capture_interaction_snapshot();
    capture_camera_snapshot();
    capture_actor_snapshot();
}

void sm64_modern_parity_record_sound(s32 sound_bits, const f32 *position) {
    const SM64ModernGameplaySubsystem subsystem = current_subsystem();
    const uint64_t values[4] = {
        (uint32_t) sound_bits,
        position ? float_bits(position[0]) : 0,
        position ? float_bits(position[1]) : 0,
        position ? float_bits(position[2]) : 0,
    };
    record_values(subsystem, SM64_MODERN_GAMEPLAY_RECORD_EFFECT,
                  SM64_MODERN_EFFECT_SOUND, object_slot(gCurrentObject), values, 4);
}

void sm64_modern_parity_record_rumble_start(f32 strength, f32 duration) {
    const uint64_t values[2] = { float_bits(strength), float_bits(duration) };
    record_values(current_subsystem(), SM64_MODERN_GAMEPLAY_RECORD_EFFECT,
                  SM64_MODERN_EFFECT_RUMBLE_START, object_slot(gCurrentObject), values, 2);
}

void sm64_modern_parity_record_rumble_stop(void) {
    record_values(current_subsystem(), SM64_MODERN_GAMEPLAY_RECORD_EFFECT,
                  SM64_MODERN_EFFECT_RUMBLE_STOP, object_slot(gCurrentObject), NULL, 0);
}

void sm64_modern_parity_record_object_spawn(struct Object *parent,
                                             struct Object *object,
                                             s32 model,
                                             const void *behavior) {
    const uint64_t values[3] = {
        (uint32_t) model,
        behavior_identity(behavior),
        object_slot(parent),
    };
    record_values(current_subsystem(), SM64_MODERN_GAMEPLAY_RECORD_EFFECT,
                  SM64_MODERN_EFFECT_OBJECT_SPAWN, object_slot(object), values, 3);
}

void sm64_modern_parity_record_object_despawn(struct Object *object) {
    const uint64_t behavior = behavior_identity(object ? object->behavior : NULL);
    record_values(current_subsystem(), SM64_MODERN_GAMEPLAY_RECORD_EFFECT,
                  SM64_MODERN_EFFECT_OBJECT_DESPAWN, object_slot(object), &behavior, 1);
}

void sm64_modern_parity_record_pcm(const s16 *samples, u32 frame_count) {
    if (!samples || frame_count == 0) {
        return;
    }
    uint64_t checksum = PARITY_FNV_OFFSET;
    for (uint32_t index = 0; index < frame_count * 2u; ++index) {
        checksum = hash_u64(checksum, (uint16_t) samples[index]);
    }
    const uint64_t values[2] = { frame_count, checksum };
    record_values(SM64_MODERN_GAMEPLAY_SUBSYSTEM_GLOBAL,
                  SM64_MODERN_GAMEPLAY_RECORD_EFFECT,
                  SM64_MODERN_EFFECT_PCM_CHECKSUM, 0, values, 2);

    // Publish only stable owner-thread values. The raw PCM remains local to
    // native synthesis and is handed to the platform immediately afterward;
    // neither this callback nor the Swift consumer sees samples or AVAudio
    // objects. The sequence is captured before the schema-4 record advances
    // the audio-domain counter so the independent Swift decoder can reproduce
    // the exact fixed-width record.
    const bool oracle_active = sm64_modern_oracle_trace_is_active() != 0;
    const uint64_t simulation_tick = oracle_active
        ? sm64_modern_oracle_trace_simulation_tick()
        : sm64_modern_timebase_simulation_tick();
    const uint32_t sequence = oracle_active
        ? sm64_modern_oracle_trace_next_sequence(SM64_MODERN_ORACLE_DOMAIN_AUDIO)
        : 0u;
    const uint64_t oracle_values[5] = {
        frame_count,
        SM64_MODERN_AUDIO_PCM_SAMPLE_RATE_HZ,
        SM64_MODERN_AUDIO_PCM_CHANNEL_COUNT,
        SM64_MODERN_AUDIO_PCM_FORMAT_S16_INTERLEAVED_STEREO,
        checksum,
    };
    if (oracle_active) {
        const SM64ModernStatus oracle_status = sm64_modern_oracle_trace_record(
            SM64_MODERN_ORACLE_DOMAIN_AUDIO,
            SM64_MODERN_ORACLE_RECORD_AUDIO_PCM,
            0,
            SM64_MODERN_ORACLE_AUDIO_EVENT_PCM,
            0,
            oracle_values,
            5);
        if (oracle_status != SM64_MODERN_STATUS_OK
            && sStatus == SM64_MODERN_STATUS_OK) {
            sStatus = oracle_status;
        }
    }

    SM64ModernAudioPCMReceiptV1 receipt;
    memset(&receipt, 0, sizeof(receipt));
    receipt.header.abi_version = SM64_MODERN_ABI_VERSION_1;
    receipt.header.struct_size = sizeof(receipt);
    receipt.simulation_tick = simulation_tick;
    receipt.frame_count = frame_count;
    receipt.sample_rate_hz = SM64_MODERN_AUDIO_PCM_SAMPLE_RATE_HZ;
    receipt.channel_count = SM64_MODERN_AUDIO_PCM_CHANNEL_COUNT;
    receipt.sample_format = SM64_MODERN_AUDIO_PCM_FORMAT_S16_INTERLEAVED_STEREO;
    receipt.sequence = sequence;
    receipt.pcm_hash = checksum;
    const SM64ModernStatus observer_status =
        sm64_modern_audio_observe_pcm_receipt(&receipt);
    if (observer_status != SM64_MODERN_STATUS_OK
        && sStatus == SM64_MODERN_STATUS_OK) {
        sStatus = observer_status;
    }
}

static uint64_t hash_bytes(const uint8_t *bytes, uint32_t byte_count) {
    uint64_t hash = PARITY_FNV_OFFSET;
    for (uint32_t index = 0; index < byte_count; ++index) {
        hash ^= bytes[index];
        hash *= PARITY_FNV_PRIME;
    }
    return hash;
}

void sm64_modern_parity_record_save_state(uint32_t event_id,
                                          uint32_t file_index,
                                          const void *bytes,
                                          uint32_t byte_count,
                                          uint32_t modified_flags) {
    if (!sm64_modern_oracle_trace_is_active()) {
        return;
    }
    if (event_id < SM64_MODERN_ORACLE_SAVE_EVENT_MUTATION
        || event_id > SM64_MODERN_ORACLE_SAVE_EVENT_RELOAD
        || (!bytes && byte_count > 0u)) {
        if (sStatus == SM64_MODERN_STATUS_OK) {
            sStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
        return;
    }
    const uint64_t values[3] = {
        byte_count,
        hash_bytes((const uint8_t *) bytes, byte_count),
        modified_flags,
    };
    const SM64ModernStatus coverage_status = sm64_modern_oracle_trace_mark_coverage(
        SM64_MODERN_ORACLE_DOMAIN_SAVE,
        event_id);
    if (coverage_status != SM64_MODERN_STATUS_OK && sStatus == SM64_MODERN_STATUS_OK) {
        sStatus = coverage_status;
        return;
    }
    const SM64ModernStatus status = sm64_modern_oracle_trace_record(
        SM64_MODERN_ORACLE_DOMAIN_SAVE,
        SM64_MODERN_ORACLE_RECORD_SAVE_BYTES,
        file_index,
        event_id,
        0,
        values,
        3);
    if (status != SM64_MODERN_STATUS_OK && sStatus == SM64_MODERN_STATUS_OK) {
        sStatus = status;
    }
}

void sm64_modern_parity_record_rng_draw(uint32_t event_id,
                                        uint64_t value,
                                        uint64_t seed) {
    if (!sm64_modern_oracle_trace_is_active()) {
        return;
    }
    if (event_id < SM64_MODERN_ORACLE_RNG_EVENT_U16
        || event_id > SM64_MODERN_ORACLE_RNG_EVENT_SIGN) {
        if (sStatus == SM64_MODERN_STATUS_OK) {
            sStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
        return;
    }
    const uint64_t values[2] = { value, seed };
    const SM64ModernStatus coverage_status = sm64_modern_oracle_trace_mark_coverage(
        SM64_MODERN_ORACLE_DOMAIN_RNG,
        event_id);
    if (coverage_status != SM64_MODERN_STATUS_OK && sStatus == SM64_MODERN_STATUS_OK) {
        sStatus = coverage_status;
        return;
    }
    const SM64ModernStatus status = sm64_modern_oracle_trace_record(
        SM64_MODERN_ORACLE_DOMAIN_RNG,
        SM64_MODERN_ORACLE_RECORD_EVENT,
        0,
        event_id,
        0,
        values,
        2);
    if (status != SM64_MODERN_STATUS_OK && sStatus == SM64_MODERN_STATUS_OK) {
        sStatus = status;
    }
}

void sm64_modern_parity_record_collision_query(uint32_t event_id,
                                               const uint64_t *values,
                                               uint32_t value_count) {
    if (!sm64_modern_oracle_trace_is_active()) {
        return;
    }
    if (event_id < SM64_MODERN_ORACLE_COLLISION_EVENT_FLOOR
        || event_id > SM64_MODERN_ORACLE_COLLISION_EVENT_ENVIRONMENT
        || value_count > SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY
        || (value_count > 0u && !values)) {
        if (sStatus == SM64_MODERN_STATUS_OK) {
            sStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
        return;
    }
    const SM64ModernStatus coverage_status = sm64_modern_oracle_trace_mark_coverage(
        SM64_MODERN_ORACLE_DOMAIN_COLLISION,
        event_id);
    if (coverage_status != SM64_MODERN_STATUS_OK && sStatus == SM64_MODERN_STATUS_OK) {
        sStatus = coverage_status;
        return;
    }
    const SM64ModernStatus status = sm64_modern_oracle_trace_record(
        SM64_MODERN_ORACLE_DOMAIN_COLLISION,
        SM64_MODERN_ORACLE_RECORD_EVENT,
        0,
        event_id,
        0,
        values,
        value_count);
    if (status != SM64_MODERN_STATUS_OK && sStatus == SM64_MODERN_STATUS_OK) {
        sStatus = status;
    }
}

void sm64_modern_parity_record_script_event(uint32_t event_id,
                                            uint64_t subject_id,
                                            const uint64_t *values,
                                            uint32_t value_count) {
    if (!sm64_modern_oracle_trace_is_active()) {
        return;
    }
    if (event_id < SM64_MODERN_ORACLE_SCRIPT_EVENT_LEVEL_COMMAND
        || event_id > SM64_MODERN_ORACLE_SCRIPT_EVENT_LIFECYCLE
        || value_count > SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY
        || (value_count > 0u && !values)) {
        if (sStatus == SM64_MODERN_STATUS_OK) {
            sStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
        return;
    }
    const SM64ModernStatus coverage_status = sm64_modern_oracle_trace_mark_coverage(
        SM64_MODERN_ORACLE_DOMAIN_SCRIPT,
        event_id);
    if (coverage_status != SM64_MODERN_STATUS_OK && sStatus == SM64_MODERN_STATUS_OK) {
        sStatus = coverage_status;
        return;
    }
    const SM64ModernStatus status = sm64_modern_oracle_trace_record(
        SM64_MODERN_ORACLE_DOMAIN_SCRIPT,
        SM64_MODERN_ORACLE_RECORD_EVENT,
        subject_id,
        event_id,
        0,
        values,
        value_count);
    if (status != SM64_MODERN_STATUS_OK && sStatus == SM64_MODERN_STATUS_OK) {
        sStatus = status;
    }
}

void sm64_modern_parity_record_audio_sequence(uint32_t event_id,
                                              const uint64_t *values,
                                              uint32_t value_count) {
    const SM64ModernStatus observer_status =
        sm64_modern_audio_observe_sequence_event(
            event_id, sSimulationTick, values, value_count);
    if (observer_status != SM64_MODERN_STATUS_OK
        && sStatus == SM64_MODERN_STATUS_OK) {
        sStatus = observer_status;
    }
    if (!sm64_modern_oracle_trace_is_active()) {
        return;
    }
    if (event_id < SM64_MODERN_ORACLE_AUDIO_EVENT_TICK
        || event_id > SM64_MODERN_ORACLE_AUDIO_EVENT_SECONDARY
        || value_count > SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY
        || (value_count > 0u && !values)) {
        if (sStatus == SM64_MODERN_STATUS_OK) {
            sStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
        return;
    }
    const SM64ModernStatus coverage_status = sm64_modern_oracle_trace_mark_coverage(
        SM64_MODERN_ORACLE_DOMAIN_AUDIO,
        event_id);
    if (coverage_status != SM64_MODERN_STATUS_OK && sStatus == SM64_MODERN_STATUS_OK) {
        sStatus = coverage_status;
        return;
    }
    const SM64ModernStatus status = sm64_modern_oracle_trace_record(
        SM64_MODERN_ORACLE_DOMAIN_AUDIO,
        SM64_MODERN_ORACLE_RECORD_EVENT,
        0,
        event_id,
        0,
        values,
        value_count);
    if (status != SM64_MODERN_STATUS_OK && sStatus == SM64_MODERN_STATUS_OK) {
        sStatus = status;
    }
}

void sm64_modern_parity_record_render_packet(uint32_t event_id,
                                             const uint64_t *values,
                                             uint32_t value_count) {
    if (!sm64_modern_oracle_trace_is_active()) {
        return;
    }
    if (event_id < SM64_MODERN_ORACLE_RENDER_EVENT_DRAW
        || event_id > SM64_MODERN_ORACLE_RENDER_EVENT_MARIO_FACE_ROUTE
        || value_count > SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY
        || (value_count > 0u && !values)) {
        if (sStatus == SM64_MODERN_STATUS_OK) {
            sStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
        return;
    }
    const SM64ModernStatus coverage_status = sm64_modern_oracle_trace_mark_coverage(
        SM64_MODERN_ORACLE_DOMAIN_RENDER,
        event_id);
    if (coverage_status != SM64_MODERN_STATUS_OK && sStatus == SM64_MODERN_STATUS_OK) {
        sStatus = coverage_status;
        return;
    }
    const SM64ModernStatus status = sm64_modern_oracle_trace_record(
        SM64_MODERN_ORACLE_DOMAIN_RENDER,
        SM64_MODERN_ORACLE_RECORD_RENDER_PACKET,
        0,
        event_id,
        0,
        values,
        value_count);
    if (status != SM64_MODERN_STATUS_OK && sStatus == SM64_MODERN_STATUS_OK) {
        sStatus = status;
    }
}

void sm64_modern_parity_record_mario_face_route(uint32_t route_id) {
    static const uint32_t update_domains[6] = { 1u, 1u, 2u, 2u, 3u, 3u };
    static const uint32_t policy_flags[6] = { 4u, 0u, 7u, 7u, 4u, 0u };
    if (route_id >= 6u) {
        if (sStatus == SM64_MODERN_STATUS_OK) {
            sStatus = SM64_MODERN_STATUS_INVALID_ARGUMENT;
        }
        return;
    }
    const uint64_t values[7] = {
        route_id, route_id, update_domains[route_id], policy_flags[route_id],
        320u, 240u, 2u,
    };
    sm64_modern_parity_record_render_packet(
        SM64_MODERN_ORACLE_RENDER_EVENT_MARIO_FACE_ROUTE, values, 7);
}

void sm64_modern_parity_enter_subsystem(SM64ModernGameplaySubsystem subsystem) {
    if (!valid_subsystem(subsystem) || sSubsystemStackDepth >= PARITY_SUBSYSTEM_STACK_CAPACITY) {
        return;
    }
    sSubsystemStack[sSubsystemStackDepth++] = subsystem;
}

void sm64_modern_parity_enter_object_update(const struct Object *object) {
    sm64_modern_parity_enter_subsystem(object == gMarioObject
        ? SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO : actor_subsystem_for_level());
}

void sm64_modern_parity_leave_subsystem(void) {
    if (sSubsystemStackDepth > 0) {
        sSubsystemStackDepth--;
    }
}

SM64ModernStatus sm64_modern_parity_status(void) {
    return sStatus;
}

uint64_t sm64_modern_parity_simulation_tick(void) {
    return sSimulationTick;
}

uint32_t sm64_modern_parity_object_slot(const struct Object *object) {
    return object_slot(object);
}

SM64ModernGameplaySubsystem sm64_modern_parity_current_subsystem(void) {
    return current_subsystem();
}
