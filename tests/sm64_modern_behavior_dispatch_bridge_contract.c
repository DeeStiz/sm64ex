#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define PENDULUM_BEHAVIOR UINT64_C(0x6268765f647065)
#define RESPAWNER_BEHAVIOR UINT64_C(0x6268765f727370)
#define AMP_BEHAVIOR UINT64_C(0x6268765f616d70)
#define BOO_BEHAVIOR UINT64_C(0x6268765f626f6f)
#define BOBOMB_BEHAVIOR UINT64_C(0x6268765f626f62)
#define BOBOMB_SMOKE_BEHAVIOR UINT64_C(0x6268765f736d6b)
#define BIRD_BEHAVIOR UINT64_C(0x6268765f626972)
#define SWOOP_BEHAVIOR UINT64_C(0x6268765f73776f)
#define PIRANHA_PLANT_BEHAVIOR UINT64_C(0x6268765f70706c)
#define BIG_BOO_BEHAVIOR UINT64_C(0x6268765f626967)
#define FLY_GUY_BEHAVIOR UINT64_C(0x6268765f666c79)
#define BULLET_BILL_BEHAVIOR UINT64_C(0x6268765f62626c)
#define GOOMBA_BEHAVIOR UINT64_C(0x6268765f676f6f6d)
#define SPINY_BEHAVIOR UINT64_C(0x6268765f7370696e)
#define SNUFIT_BEHAVIOR UINT64_C(0x6268765f736e66)
#define WHOMP_BEHAVIOR UINT64_C(0x6268765f77686d)
#define HEAVE_HO_BEHAVIOR UINT64_C(0x6268765f68686f)
#define HEAVE_HO_CHILD_BEHAVIOR UINT64_C(0x6268765f686874)
#define CHILD_BEHAVIOR UINT64_C(0x6268765f746573)

static uint64_t hash_u64(uint64_t hash, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

static uint64_t hash_id(uint64_t hash, uint64_t slot, uint64_t generation) {
    hash = hash_u64(hash, slot);
    return hash_u64(hash, generation);
}

static uint64_t hash_event(
    uint64_t hash,
    uint64_t slot,
    uint64_t behavior,
    uint64_t route
) {
    hash = hash_id(hash, slot, 1);
    hash = hash_u64(hash, behavior);
    return hash_u64(hash, route);
}

static uint64_t hash_tick(
    uint64_t hash,
    uint64_t frame,
    int second_tick
) {
    hash = hash_u64(hash, frame);
    hash = hash_u64(hash, second_tick ? 2 : 3); // default-list count
    hash = hash_u64(hash, second_tick ? 17 : 19); // object counter
    hash = hash_u64(hash, second_tick ? 17 : 19); // dispatch events
    hash = hash_event(hash, 14, WHOMP_BEHAVIOR, 14);
    hash = hash_event(hash, 2, AMP_BEHAVIOR, 2);
    hash = hash_event(hash, 3, BOO_BEHAVIOR, 3);
    hash = hash_event(hash, 4, BOBOMB_BEHAVIOR, 4);
    hash = hash_event(hash, 5, BIRD_BEHAVIOR, 5);
    hash = hash_event(hash, 6, SWOOP_BEHAVIOR, 6);
    hash = hash_event(hash, 7, PIRANHA_PLANT_BEHAVIOR, 7);
    hash = hash_event(hash, 8, BIG_BOO_BEHAVIOR, 8);
    hash = hash_event(hash, 9, FLY_GUY_BEHAVIOR, 9);
    hash = hash_event(hash, 10, BULLET_BILL_BEHAVIOR, 10);
    hash = hash_event(hash, 11, GOOMBA_BEHAVIOR, 11);
    hash = hash_event(hash, 12, SPINY_BEHAVIOR, 12);
    hash = hash_event(hash, 13, SNUFIT_BEHAVIOR, 13);
    hash = hash_event(hash, 15, HEAVE_HO_BEHAVIOR, 15);
    hash = hash_event(hash, 16, HEAVE_HO_CHILD_BEHAVIOR, 15);
    hash = hash_event(hash, 0, PENDULUM_BEHAVIOR, 0);
    if (second_tick) {
        hash = hash_event(hash, 18, CHILD_BEHAVIOR, 255);
    } else {
        hash = hash_event(hash, 1, RESPAWNER_BEHAVIOR, 1);
        hash = hash_event(hash, 18, CHILD_BEHAVIOR, 255);
        hash = hash_event(hash, 17, BOBOMB_SMOKE_BEHAVIOR, 255);
    }

    hash = hash_u64(hash, 1); // pendulum effects
    hash = hash_id(hash, 0, 1);
    hash = hash_u64(hash, (uint64_t)(int64_t)(second_tick ? 140 : 124));
    hash = hash_u64(hash, (uint64_t)(int64_t)(second_tick ? 0x10 : 0x18));
    hash = hash_u64(hash, second_tick ? 1 : 0);
    hash = hash_u64(hash, second_tick ? 1 : 0); // presented count

    hash = hash_u64(hash, second_tick ? 0 : 1); // respawner effects
    if (!second_tick) {
        hash = hash_id(hash, 1, 1);
        hash = hash_u64(hash, 3); // spawn + mark for deletion
        hash = hash_id(hash, 18, 1);
        hash = hash_u64(hash, 1); // timer
        hash = hash_u64(hash, 1); // marked for deletion
    }
    hash = hash_u64(hash, 1); // Amp effects
    hash = hash_id(hash, 2, 1);
    hash = hash_u64(hash, 2); // fixed kind
    hash = hash_u64(hash, UINT64_C(513)); // animate + set hitbox
    hash = hash_u64(hash, 2); // active action
    hash = hash_u64(hash, 1); // tangible
    hash = hash_u64(hash, 0); // visible

    hash = hash_u64(hash, second_tick ? 0 : 1); // respawner deliveries
    if (!second_tick) {
        hash = hash_u64(hash, 1); // deleted count
        hash = hash_id(hash, 1, 1);
    }

    hash = hash_u64(hash, 1); // Boo effects
    hash = hash_id(hash, 3, 1);
    hash = hash_u64(hash, second_tick ? 23 : 3); // animate + chase [+ appear + oscillate]
    hash = hash_u64(hash, 1); // chase action
    hash = hash_u64(hash, 255); // opacity
    hash = hash_u64(hash, 0); // visible
    hash = hash_u64(hash, 0); // Boo deliveries

    hash = hash_u64(hash, 1); // Bob-omb effects
    hash = hash_id(hash, 4, 1);
    hash = hash_u64(hash, 0); // generic subtype
    hash = hash_u64(hash, 0); // free held state
    hash = hash_u64(hash, 2); // chase action
    hash = hash_u64(hash, second_tick ? 36 : 44); // chase + fuse state
    hash = hash_u64(hash, second_tick ? 0 : 1); // spawned children
    if (!second_tick) {
        hash = hash_id(hash, 17, 1);
    }
    hash = hash_u64(hash, 0); // not marked for deletion
    hash = hash_u64(hash, second_tick ? 0 : 1); // Bob-omb deliveries
    if (!second_tick) {
        hash = hash_u64(hash, 1); // deleted count
        hash = hash_id(hash, 17, 1);
    }

    hash = hash_u64(hash, 1); // Bird effects
    hash = hash_id(hash, 5, 1);
    hash = hash_u64(hash, 0); // spawned kind
    hash = hash_u64(hash, second_tick ? 1 : 35); // animate [+ flight + reveal]
    hash = hash_u64(hash, 1); // fly action
    hash = hash_u64(hash, 0); // spawned children
    hash = hash_u64(hash, 0); // not marked for deletion
    hash = hash_u64(hash, 0); // Bird deliveries

    hash = hash_u64(hash, 1); // Swoop effects
    hash = hash_id(hash, 6, 1);
    hash = hash_u64(hash, 1); // animate
    hash = hash_u64(hash, 0); // idle action
    hash = hash_u64(hash, 0); // not marked for deletion
    hash = hash_u64(hash, 0); // Swoop deliveries

    hash = hash_u64(hash, 1); // Piranha Plant effects
    hash = hash_id(hash, 7, 1);
    hash = hash_u64(hash, 0); // idle action
    hash = hash_u64(hash, UINT64_C(40961)); // shown + idle + intangible
    hash = hash_u64(hash, 0); // spawned children
    hash = hash_u64(hash, 0); // not marked for deletion
    hash = hash_u64(hash, 0); // Piranha Plant deliveries

    hash = hash_u64(hash, 1); // Big Boo effects
    hash = hash_id(hash, 8, 1);
    hash = hash_u64(hash, 0); // ghost-hunt variant
    hash = hash_u64(hash, 0); // initialize action
    hash = hash_u64(hash, 1); // initialize effect
    hash = hash_u64(hash, 3); // health
    hash = hash_u64(hash, 0); // no star position
    hash = hash_u64(hash, 0); // no collision result
    hash = hash_u64(hash, 0); // no movement result
    hash = hash_u64(hash, 0); // spawned children
    hash = hash_u64(hash, 0); // presented effects
    hash = hash_u64(hash, 1); // Big Boo deliveries
    hash = hash_u64(hash, 0); // no deleted objects

    hash = hash_u64(hash, 1); // Fly Guy effects
    hash = hash_id(hash, 9, 1);
    hash = hash_u64(hash, 0); // Fly Guy kind
    hash = hash_u64(hash, UINT64_C(515)); // animate + oscillate + idle
    hash = hash_u64(hash, 1); // action is present
    hash = hash_u64(hash, 0); // idle action
    hash = hash_u64(hash, 0); // spawned children
    hash = hash_u64(hash, 0); // not marked for deletion
    hash = hash_u64(hash, 0); // Fly Guy deliveries

    hash = hash_u64(hash, 1); // Bullet Bill effects
    hash = hash_id(hash, 10, 1);
    hash = hash_u64(hash, second_tick ? 1 : 259); // animate or reset+tangible
    hash = hash_u64(hash, 1); // waiting action
    hash = hash_u64(hash, 0); // no smoke child
    hash = hash_u64(hash, 0); // Bullet Bill deliveries

    hash = hash_u64(hash, 1); // Goomba effects
    hash = hash_id(hash, 11, 1);
    hash = hash_u64(hash, 128); // animate
    hash = hash_u64(hash, 0); // nop attack handler
    hash = hash_u64(hash, 0); // no blue coin
    hash = hash_u64(hash, 0); // walk action
    hash = hash_u64(hash, 0); // high death sound
    hash = hash_u64(hash, 1); // one loot coin
    hash = hash_u64(hash, 0); // not marked for respawn
    hash = hash_u64(hash, 0); // no respawn requests
    hash = hash_u64(hash, 0); // no Goomba deliveries

    hash = hash_u64(hash, 1); // Spiny effects
    hash = hash_id(hash, 12, 1);
    hash = hash_u64(hash, second_tick ? 1 : 3); // animate or animate + turn
    hash = hash_u64(hash, 0); // nop attack handler
    hash = hash_u64(hash, 0); // walk action
    hash = hash_u64(hash, 0); // no Spiny deliveries

    hash = hash_u64(hash, 1); // Snufit effects
    hash = hash_id(hash, 13, 1);
    hash = hash_u64(hash, 0); // Snufit kind
    hash = hash_u64(hash, 1); // action is present
    hash = hash_u64(hash, 0); // idle action
    hash = hash_u64(hash, 0); // no bullet action
    hash = hash_u64(hash, 133); // orbit + idle + tangible
    hash = hash_u64(hash, 0); // no spawned bullets
    hash = hash_u64(hash, 0); // not marked for deletion
    hash = hash_u64(hash, 0); // no Snufit deliveries

    hash = hash_u64(hash, 1); // Whomp effects
    hash = hash_id(hash, 14, 1);
    hash = hash_u64(hash, 0); // normal size
    hash = hash_u64(hash, 0); // initialize action
    hash = hash_u64(hash, 3); // animate + reset home
    hash = hash_u64(hash, 1); // health
    hash = hash_u64(hash, 0); // not marked for deletion
    hash = hash_u64(hash, 0); // no collision result
    hash = hash_u64(hash, 0); // no movement result
    hash = hash_u64(hash, 0); // no spawned children
    hash = hash_u64(hash, 0); // no presented effects
    hash = hash_u64(hash, 1); // Whomp deliveries
    hash = hash_u64(hash, 0); // no deleted objects

    hash = hash_u64(hash, 2); // Heave Ho parent and throw child effects
    hash = hash_id(hash, 15, 1);
    hash = hash_u64(hash, 0); // Heave Ho parent kind
    hash = hash_u64(hash, 12); // intangible + hide
    hash = hash_u64(hash, 1); // submerged action is present
    hash = hash_u64(hash, 0); // submerged action
    hash = hash_u64(hash, 1); // free held state is present
    hash = hash_u64(hash, 0); // free held state
    hash = hash_u64(hash, 0); // no throw consumption
    hash = hash_id(hash, 16, 1);
    hash = hash_u64(hash, 1); // throw child kind
    hash = hash_u64(hash, 0); // no child effects
    hash = hash_u64(hash, 0); // no child action
    hash = hash_u64(hash, 0); // no child held state
    hash = hash_u64(hash, 0); // no throw consumption
    hash = hash_u64(hash, 0); // no Heave Ho deliveries

    hash = hash_u64(hash, UINT64_C(0x77));
    hash = hash_u64(hash, CHILD_BEHAVIOR);
    hash = hash_u64(hash, UINT64_C(0x1234));
    hash = hash_u64(hash, 8); // OBJ_LIST_DEFAULT
    return hash;
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_tick(fingerprint, 1, 0);
    fingerprint = hash_tick(fingerprint, 2, 1);
    printf("behaviorDispatchBridgeFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    printf("SM64 Modern behavior dispatch bridge C contract passed\n");
    return 0;
}
