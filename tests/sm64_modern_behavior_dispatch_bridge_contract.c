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
#define CHUCKYA_BEHAVIOR UINT64_C(0x6268765f63686b)
#define CHUCKYA_ANCHOR_BEHAVIOR UINT64_C(0x6268765f636861)
#define SKEETER_BEHAVIOR UINT64_C(0x6268765f736b65)
#define SKEETER_WAVE_BEHAVIOR UINT64_C(0x6268765f736b77)
#define BULLY_BEHAVIOR UINT64_C(0x6268765f62756c)
#define ENEMY_LAKITU_BEHAVIOR UINT64_C(0x6268765f6c616b)
#define CHAIN_CHOMP_BEHAVIOR UINT64_C(0x6268765f63686d70)
#define CHAIN_CHOMP_SEGMENT_BEHAVIOR UINT64_C(0x6268765f63687367)
#define CHAIN_CHOMP_POST_BEHAVIOR UINT64_C(0x6268765f77707374)
#define CHAIN_CHOMP_GATE_BEHAVIOR UINT64_C(0x6268765f67617465)
#define POKEY_BEHAVIOR UINT64_C(0x6268765f706f6b)
#define POKEY_BODY_BEHAVIOR UINT64_C(0x6268765f7062)
#define SCUTTLEBUG_SPAWNER_BEHAVIOR UINT64_C(0x6268765f736273)
#define SCUTTLEBUG_BEHAVIOR UINT64_C(0x6268765f736275)
#define BOBOMB_BUDDY_BEHAVIOR UINT64_C(0x6268765f626262)
#define BOWSER_SHOCK_WAVE_BEHAVIOR UINT64_C(0x6268765f627377)
#define BOWSER_KEY_BEHAVIOR UINT64_C(0x6268765f6b6579)
#define BOUNCING_FIREBALL_BEHAVIOR UINT64_C(0x6268765f62666972)
#define BOUNCING_FIREBALL_FLAME_BEHAVIOR UINT64_C(0x6268765f62666c6d)
#define KING_BOBOMB_BEHAVIOR UINT64_C(0x6268765f6b626d)
#define SL_WALKING_PENGUIN_BEHAVIOR UINT64_C(0x6268765f736c70)
#define SMALL_PENGUIN_BEHAVIOR UINT64_C(0x6268765f73706e)
#define KOOPA_UNDERWATER_BEHAVIOR UINT64_C(0x6268765f6b7375)
#define BOWSER_KEY_CUTSCENE_COURSE_EXIT UINT64_C(0x6268765f6b637865)
#define EXPLOSION_BEHAVIOR UINT64_C(0x6268765f657870)
#define MONEYBAG_BEHAVIOR UINT64_C(0x6268765f6d6f6e)
#define WATER_BOMB_SPAWNER_BEHAVIOR UINT64_C(0x6268765f776273)
#define WATER_BOMB_BEHAVIOR UINT64_C(0x6268765f77626d)
#define WATER_BOMB_SHADOW_BEHAVIOR UINT64_C(0x6268765f776273)
#define EYEROK_BEHAVIOR UINT64_C(0x62685f657972)
#define EYEROK_HAND_BEHAVIOR UINT64_C(0x62685f686e64)
#define MRI_EYE_BEHAVIOR UINT64_C(0x6268765f6d7269)
#define MRI_BODY_BEHAVIOR UINT64_C(0x6268765f6d7262)
#define MRI_PARTICLE_BEHAVIOR UINT64_C(0x6268765f6d7270)
#define RACING_PENGUIN_BEHAVIOR UINT64_C(0x6268765f727063)
#define YOSHI_BEHAVIOR UINT64_C(0x6268765f797368)
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
    hash = hash_u64(hash, route);
    return hash;
}

static uint64_t hash_tick(
    uint64_t hash,
    uint64_t frame,
    int second_tick
) {
    hash = hash_u64(hash, frame);
    hash = hash_u64(hash, second_tick ? 2 : 3); // default-list count
    hash = hash_u64(hash, second_tick ? 27 : 29); // object counter
    hash = hash_u64(hash, second_tick ? 28 : 30); // dispatch events
    hash = hash_event(hash, 22, ENEMY_LAKITU_BEHAVIOR, 19);
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
    hash = hash_event(hash, 17, CHUCKYA_BEHAVIOR, 16);
    hash = hash_event(hash, 18, CHUCKYA_ANCHOR_BEHAVIOR, 16);
    hash = hash_event(hash, 19, SKEETER_BEHAVIOR, 17);
    hash = hash_event(hash, 20, BULLY_BEHAVIOR, 18);
    hash = hash_event(hash, 21, BULLY_BEHAVIOR, 18);
    hash = hash_event(hash, 23, SPINY_BEHAVIOR, 12);
    hash = hash_event(hash, 25, SKEETER_WAVE_BEHAVIOR, 17);
    hash = hash_event(hash, 26, SKEETER_WAVE_BEHAVIOR, 17);
    hash = hash_event(hash, 27, SKEETER_WAVE_BEHAVIOR, 17);
    hash = hash_event(hash, 28, SKEETER_WAVE_BEHAVIOR, 17);
    hash = hash_event(hash, 0, PENDULUM_BEHAVIOR, 0);
    if (second_tick) {
        hash = hash_event(hash, 29, CHILD_BEHAVIOR, 255);
    } else {
        hash = hash_event(hash, 1, RESPAWNER_BEHAVIOR, 1);
        hash = hash_event(hash, 29, CHILD_BEHAVIOR, 255);
        hash = hash_event(hash, 24, BOBOMB_SMOKE_BEHAVIOR, 255);
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
        hash = hash_id(hash, 29, 1);
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
        hash = hash_id(hash, 24, 1);
    }
    hash = hash_u64(hash, 0); // not marked for deletion
    hash = hash_u64(hash, second_tick ? 0 : 1); // Bob-omb deliveries
    if (!second_tick) {
        hash = hash_u64(hash, 1); // deleted count
        hash = hash_id(hash, 24, 1);
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

    hash = hash_u64(hash, 2); // direct Spiny and Lakitu child effects
    hash = hash_id(hash, 12, 1);
    hash = hash_u64(hash, second_tick ? 1 : 3); // animate or animate + turn
    hash = hash_u64(hash, 0); // nop attack handler
    hash = hash_u64(hash, 0); // walk action
    hash = hash_id(hash, 23, 1);
    hash = hash_u64(hash, 1); // animate
    hash = hash_u64(hash, 0); // nop attack handler
    hash = hash_u64(hash, 1); // held by Lakitu action
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

    hash = hash_u64(hash, 2); // Chuckya parent and anchor effects
    hash = hash_id(hash, 17, 1);
    hash = hash_u64(hash, 0); // Chuckya parent kind
    hash = hash_u64(hash, second_tick ? 3 : 1); // animate [+ move after patrol starts]
    hash = hash_u64(hash, 1); // patrol action is present
    hash = hash_u64(hash, 0); // patrol action
    hash = hash_u64(hash, 1); // throw state is present
    hash = hash_u64(hash, 0); // no throw state
    hash = hash_u64(hash, 0); // no throw consumption
    hash = hash_u64(hash, 0); // not marked for deletion
    hash = hash_id(hash, 18, 1);
    hash = hash_u64(hash, 1); // anchor kind
    hash = hash_u64(hash, 0); // no anchor effects
    hash = hash_u64(hash, 0); // no anchor action
    hash = hash_u64(hash, 0); // no anchor throw state
    hash = hash_u64(hash, 0); // no throw consumption
    hash = hash_u64(hash, 0); // not marked for deletion
    hash = hash_u64(hash, 0); // no Chuckya deliveries

    hash = hash_u64(hash, 5); // Skeeter parent and four waves
    hash = hash_id(hash, 19, 1);
    hash = hash_u64(hash, 0); // parent, not wave
    hash = hash_u64(hash, second_tick ? 1 : 3); // animate [+ spawn waves]
    hash = hash_u64(hash, 0); // idle action
    hash = hash_u64(hash, second_tick ? 0 : 4);
    if (!second_tick) {
        hash = hash_id(hash, 25, 1);
        hash = hash_id(hash, 26, 1);
        hash = hash_id(hash, 27, 1);
        hash = hash_id(hash, 28, 1);
    }
    hash = hash_u64(hash, 0x3f800000U); // parent scale
    hash = hash_u64(hash, 0); // parent animation
    hash = hash_u64(hash, 0); // parent not marked
    for (uint32_t id = 25; id <= 28; ++id) {
        hash = hash_id(hash, id, 1);
        hash = hash_u64(hash, 1); // wave
        hash = hash_u64(hash, 0); // no effects
        hash = hash_u64(hash, 0); // idle action
        hash = hash_u64(hash, 0); // no children
        hash = hash_u64(hash, second_tick ? 0x3e4cccccU : 0x3f000000U);
        hash = hash_u64(hash, 0); // animation
        hash = hash_u64(hash, 0); // not marked
    }
    hash = hash_u64(hash, 0); // no Skeeter deliveries

    hash = hash_u64(hash, 2); // small and big Bully effects
    hash = hash_id(hash, 20, 1);
    hash = hash_u64(hash, 0); // small
    hash = hash_u64(hash, second_tick ? 5 : 13); // animate + chase [+ patrol]
    hash = hash_u64(hash, 1); // chase action
    hash = hash_u64(hash, 0); // not marked
    hash = hash_id(hash, 21, 1);
    hash = hash_u64(hash, 1); // big
    hash = hash_u64(hash, second_tick ? 5 : 13);
    hash = hash_u64(hash, 1); // chase action
    hash = hash_u64(hash, 0); // not marked
    hash = hash_u64(hash, 2); // Bully deliveries
    hash = hash_u64(hash, 0); // small deleted count
    hash = hash_u64(hash, 0); // big deleted count

    hash = hash_u64(hash, 1); // Enemy Lakitu effect
    hash = hash_id(hash, 22, 1);
    hash = hash_u64(hash, second_tick ? 2 : 14); // animate [+ spawn + hold]
    hash = hash_u64(hash, 1); // main action
    hash = hash_u64(hash, 1); // hold Spiny sub-action
    hash = hash_u64(hash, 1); // one Spiny
    if (second_tick) {
        hash = hash_u64(hash, 0); // no new child
    } else {
        hash = hash_u64(hash, 1); // spawned child present
        hash = hash_id(hash, 23, 1);
    }

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

    // Isolated shared-dispatch Chain Chomp parent plus five live segments.
    fingerprint = hash_u64(fingerprint, 1); // scheduler frame
    static const uint64_t chain_counts[13] = {
        0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0
    };
    for (unsigned index = 0; index < 13; ++index) {
        fingerprint = hash_u64(fingerprint, chain_counts[index]);
    }
    fingerprint = hash_u64(fingerprint, 6); // object counter
    fingerprint = hash_u64(fingerprint, 6); // updated count
    for (uint64_t id = 1; id <= 6; ++id) fingerprint = hash_u64(fingerprint, id);
    fingerprint = hash_u64(fingerprint, 0); // unloaded count
    fingerprint = hash_u64(fingerprint, 6); // events
    fingerprint = hash_u64(fingerprint, 1);
    fingerprint = hash_u64(fingerprint, CHAIN_CHOMP_BEHAVIOR);
    fingerprint = hash_u64(fingerprint, 20);
    for (uint64_t id = 2; id <= 6; ++id) {
        fingerprint = hash_u64(fingerprint, id);
        fingerprint = hash_u64(fingerprint, CHAIN_CHOMP_SEGMENT_BEHAVIOR);
        fingerprint = hash_u64(fingerprint, 20);
    }
    fingerprint = hash_u64(fingerprint, 6); // effects
    fingerprint = hash_u64(fingerprint, 1); // parent trace subject
    fingerprint = hash_u64(fingerprint, 0); // chomp kind
    fingerprint = hash_u64(fingerprint, 255); // parent index
    fingerprint = hash_u64(fingerprint, 7); // animate + allocate + turn
    fingerprint = hash_u64(fingerprint, 1); // move action
    fingerprint = hash_u64(fingerprint, 0); // not marked
    for (uint64_t index = 0; index < 5; ++index) {
        fingerprint = hash_u64(fingerprint, index + 2); // segment trace subject
        fingerprint = hash_u64(fingerprint, 1); // segment kind
        fingerprint = hash_u64(fingerprint, index);
        fingerprint = hash_u64(fingerprint, 1); // animate
        fingerprint = hash_u64(fingerprint, 255); // no action
        fingerprint = hash_u64(fingerprint, 0); // not marked
    }
    fingerprint = hash_u64(fingerprint, 0); // deliveries

    // Isolated shared-dispatch Chain Chomp surface post/gate followed by the
    // parent and five metallic segments in the source list order.
    fingerprint = hash_u64(fingerprint, 1); // scheduler frame
    static const uint64_t release_counts[13] = {
        0, 0, 0, 0, 6, 0, 0, 0, 0, 2, 0, 0, 0
    };
    for (unsigned index = 0; index < 13; ++index) {
        fingerprint = hash_u64(fingerprint, release_counts[index]);
    }
    fingerprint = hash_u64(fingerprint, 8); // object counter
    fingerprint = hash_u64(fingerprint, 8); // updated count
    const uint64_t release_updated[] = { 2, 3, 1, 4, 5, 6, 7, 8 };
    for (size_t index = 0; index < sizeof(release_updated) / sizeof(release_updated[0]); ++index) {
        fingerprint = hash_u64(fingerprint, release_updated[index]);
    }
    fingerprint = hash_u64(fingerprint, 0); // unloaded count
    fingerprint = hash_u64(fingerprint, 8); // events
    fingerprint = hash_u64(fingerprint, 2);
    fingerprint = hash_u64(fingerprint, CHAIN_CHOMP_POST_BEHAVIOR);
    fingerprint = hash_u64(fingerprint, 21);
    fingerprint = hash_u64(fingerprint, 3);
    fingerprint = hash_u64(fingerprint, CHAIN_CHOMP_GATE_BEHAVIOR);
    fingerprint = hash_u64(fingerprint, 21);
    fingerprint = hash_u64(fingerprint, 1);
    fingerprint = hash_u64(fingerprint, CHAIN_CHOMP_BEHAVIOR);
    fingerprint = hash_u64(fingerprint, 20);
    for (uint64_t id = 4; id <= 8; ++id) {
        fingerprint = hash_u64(fingerprint, id);
        fingerprint = hash_u64(fingerprint, CHAIN_CHOMP_SEGMENT_BEHAVIOR);
        fingerprint = hash_u64(fingerprint, 20);
    }
    fingerprint = hash_u64(fingerprint, 2); // release effects
    fingerprint = hash_u64(fingerprint, 2); // wooden post trace subject
    fingerprint = hash_u64(fingerprint, 0); // wooden post kind
    fingerprint = hash_u64(fingerprint, 1); // pound sound
    fingerprint = hash_u64(fingerprint, 0); // no coins
    fingerprint = hash_u64(fingerprint, 0); // not marked
    fingerprint = hash_u64(fingerprint, 3); // gate trace subject
    fingerprint = hash_u64(fingerprint, 1); // gate kind
    fingerprint = hash_u64(fingerprint, 0x3e0); // all gate effects
    fingerprint = hash_u64(fingerprint, 0); // no coins
    fingerprint = hash_u64(fingerprint, 1); // marked
    fingerprint = hash_u64(fingerprint, 0); // no release request
    fingerprint = hash_u64(fingerprint, 1); // one owner delivery
    fingerprint = hash_u64(fingerprint, 1); // deleted count
    fingerprint = hash_u64(fingerprint, 3); // deleted gate
    fingerprint = hash_u64(fingerprint, 5); // presented effects
    fingerprint = hash_u64(fingerprint, 6); // Chain Chomp effects
    fingerprint = hash_u64(fingerprint, 1); // parent trace subject
    fingerprint = hash_u64(fingerprint, 0); // chomp kind
    fingerprint = hash_u64(fingerprint, 255); // parent index
    fingerprint = hash_u64(fingerprint, 7); // animate + allocate + turn
    fingerprint = hash_u64(fingerprint, 1); // move action
    fingerprint = hash_u64(fingerprint, 0); // not marked
    for (uint64_t index = 0; index < 5; ++index) {
        fingerprint = hash_u64(fingerprint, index + 4); // segment subject
        fingerprint = hash_u64(fingerprint, 1); // segment kind
        fingerprint = hash_u64(fingerprint, index);
        fingerprint = hash_u64(fingerprint, 1); // animate
        fingerprint = hash_u64(fingerprint, 255); // no action
        fingerprint = hash_u64(fingerprint, 0); // not marked
    }
    fingerprint = hash_u64(fingerprint, 0); // Chain Chomp deliveries

    // Isolated shared-dispatch Pokey parent plus five body parts allocated
    // during the same general-actor traversal.
    fingerprint = hash_u64(fingerprint, 1); // scheduler frame
    static const uint64_t pokey_counts[13] = {
        0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0
    };
    for (unsigned index = 0; index < 13; ++index) {
        fingerprint = hash_u64(fingerprint, pokey_counts[index]);
    }
    fingerprint = hash_u64(fingerprint, 6); // object counter
    fingerprint = hash_u64(fingerprint, 6); // updated count
    for (uint64_t id = 1; id <= 6; ++id) fingerprint = hash_u64(fingerprint, id);
    fingerprint = hash_u64(fingerprint, 0); // unloaded count
    fingerprint = hash_u64(fingerprint, 6); // events
    fingerprint = hash_u64(fingerprint, 1);
    fingerprint = hash_u64(fingerprint, POKEY_BEHAVIOR);
    fingerprint = hash_u64(fingerprint, 22);
    for (uint64_t id = 2; id <= 6; ++id) {
        fingerprint = hash_u64(fingerprint, id);
        fingerprint = hash_u64(fingerprint, POKEY_BODY_BEHAVIOR);
        fingerprint = hash_u64(fingerprint, 22);
    }
    fingerprint = hash_u64(fingerprint, 6); // effects
    fingerprint = hash_u64(fingerprint, 1); // parent trace subject
    fingerprint = hash_u64(fingerprint, 0); // parent kind
    fingerprint = hash_u64(fingerprint, 255); // parent body index
    fingerprint = hash_u64(fingerprint, 7); // animate + spawn + wander
    fingerprint = hash_u64(fingerprint, 5); // five spawned parts
    for (uint64_t id = 2; id <= 6; ++id) fingerprint = hash_u64(fingerprint, id);
    fingerprint = hash_u64(fingerprint, 5); // alive parts
    fingerprint = hash_u64(fingerprint, UINT64_C(0x3f800000));
    fingerprint = hash_u64(fingerprint, 0); // not marked
    for (uint64_t index = 0; index < 5; ++index) {
        fingerprint = hash_u64(fingerprint, index + 2); // body trace subject
        fingerprint = hash_u64(fingerprint, 1); // body kind
        fingerprint = hash_u64(fingerprint, index);
        fingerprint = hash_u64(fingerprint, 1); // animate
        fingerprint = hash_u64(fingerprint, 0); // no children
        fingerprint = hash_u64(fingerprint, 5); // alive parts
        fingerprint = hash_u64(fingerprint, UINT64_C(0x3f800000));
        fingerprint = hash_u64(fingerprint, 0); // not marked
    }
    fingerprint = hash_u64(fingerprint, 0); // deliveries

    // Isolated shared-dispatch Scuttlebug spawner followed by its
    // general-actor child in the same live traversal.
    fingerprint = hash_u64(fingerprint, 32); // scheduler frame
    static const uint64_t scuttlebug_counts[13] = {
        0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0
    };
    for (unsigned index = 0; index < 13; ++index) {
        fingerprint = hash_u64(fingerprint, scuttlebug_counts[index]);
    }
    fingerprint = hash_u64(fingerprint, 1); // object counter
    fingerprint = hash_u64(fingerprint, 2); // updated count
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_id(fingerprint, 1, 1);
    fingerprint = hash_u64(fingerprint, 0); // unloaded count
    fingerprint = hash_u64(fingerprint, 2); // events
    fingerprint = hash_event(fingerprint, 0, SCUTTLEBUG_SPAWNER_BEHAVIOR, 23);
    fingerprint = hash_event(fingerprint, 1, SCUTTLEBUG_BEHAVIOR, 23);
    fingerprint = hash_u64(fingerprint, 2); // effects
    fingerprint = hash_id(fingerprint, 0, 1); // spawner trace subject
    fingerprint = hash_u64(fingerprint, 1); // spawner kind
    fingerprint = hash_u64(fingerprint, 1024); // spawn scuttlebug
    fingerprint = hash_u64(fingerprint, 255); // no action
    fingerprint = hash_u64(fingerprint, 1); // child present
    fingerprint = hash_id(fingerprint, 1, 1);
    fingerprint = hash_u64(fingerprint, 0); // not marked
    fingerprint = hash_id(fingerprint, 1, 1); // child trace subject
    fingerprint = hash_u64(fingerprint, 0); // bug kind
    fingerprint = hash_u64(fingerprint, 1); // animate
    fingerprint = hash_u64(fingerprint, 0); // initialize
    fingerprint = hash_u64(fingerprint, 0); // no child
    fingerprint = hash_u64(fingerprint, 0); // not marked
    fingerprint = hash_u64(fingerprint, 0); // deliveries

    // Isolated shared-dispatch Bob-omb Buddy owner route.
    fingerprint = hash_u64(fingerprint, 1); // scheduler frame
    static const uint64_t buddy_counts[13] = {
        0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0
    };
    for (unsigned index = 0; index < 13; ++index) {
        fingerprint = hash_u64(fingerprint, buddy_counts[index]);
    }
    fingerprint = hash_u64(fingerprint, 1); // object counter
    fingerprint = hash_u64(fingerprint, 1); // updated count
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u64(fingerprint, 0); // unloaded count
    fingerprint = hash_u64(fingerprint, 1); // events
    fingerprint = hash_event(fingerprint, 0, BOBOMB_BUDDY_BEHAVIOR, 24);
    fingerprint = hash_u64(fingerprint, 1); // effects
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u64(fingerprint, 0); // action
    fingerprint = hash_u64(fingerprint, 0); // role
    fingerprint = hash_u64(fingerprint, 0); // cannon status
    fingerprint = hash_u64(fingerprint, 0); // has talked
    fingerprint = hash_u64(fingerprint, 0); // move yaw
    fingerprint = hash_u64(fingerprint, 0); // blink timer
    fingerprint = hash_u64(fingerprint, 0); // walking sound
    fingerprint = hash_u64(fingerprint, 0); // sign sound
    fingerprint = hash_u64(fingerprint, 0); // dialog id
    fingerprint = hash_u64(fingerprint, 0); // dialog requested
    fingerprint = hash_u64(fingerprint, 0); // camera request
    fingerprint = hash_u64(fingerprint, 0); // active time stop
    fingerprint = hash_u64(fingerprint, 0); // clear time stop
    fingerprint = hash_u64(fingerprint, 0); // clear interaction
    fingerprint = hash_u64(fingerprint, UINT64_C(0x453b8000)); // visibility distance
    fingerprint = hash_u64(fingerprint, 0); // no nearest cannon
    fingerprint = hash_u64(fingerprint, 0); // no presented effects
    fingerprint = hash_u64(fingerprint, 1); // deliveries
    fingerprint = hash_u64(fingerprint, 0); // delivered
    fingerprint = hash_u64(fingerprint, 0); // presented
    fingerprint = hash_u64(fingerprint, 0); // spawned
    fingerprint = hash_u64(fingerprint, 0); // deleted
    fingerprint = hash_u64(fingerprint, 0); // rejected

    // Isolated shared-dispatch Bowser shockwave unimportant-list route.
    fingerprint = hash_u64(fingerprint, 1); // scheduler frame
    static const uint64_t shock_counts[13] = {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
    };
    for (unsigned index = 0; index < 13; ++index) {
        fingerprint = hash_u64(fingerprint, shock_counts[index]);
    }
    fingerprint = hash_u64(fingerprint, 1); // object counter
    fingerprint = hash_u64(fingerprint, 1); // updated count
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u64(fingerprint, 0); // unloaded count
    fingerprint = hash_u64(fingerprint, 1); // events
    fingerprint = hash_event(fingerprint, 0, BOWSER_SHOCK_WAVE_BEHAVIOR, 25);
    fingerprint = hash_u64(fingerprint, 1); // effects
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u64(fingerprint, 0); // no effect
    fingerprint = hash_u64(fingerprint, 1); // timer
    fingerprint = hash_u64(fingerprint, 0); // scale
    fingerprint = hash_u64(fingerprint, 255); // opacity
    fingerprint = hash_u64(fingerprint, 0); // no Mario interaction
    fingerprint = hash_u64(fingerprint, 0); // not marked

    // Isolated shared-dispatch Bowser key level-list route.
    fingerprint = hash_u64(fingerprint, 1); // scheduler frame
    static const uint64_t key_counts[13] = {
        0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0
    };
    for (unsigned index = 0; index < 13; ++index) {
        fingerprint = hash_u64(fingerprint, key_counts[index]);
    }
    fingerprint = hash_u64(fingerprint, 1); // object counter
    fingerprint = hash_u64(fingerprint, 1); // updated count
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u64(fingerprint, 0); // unloaded count
    fingerprint = hash_u64(fingerprint, 1); // events
    fingerprint = hash_event(fingerprint, 0, BOWSER_KEY_BEHAVIOR, 26);
    fingerprint = hash_u64(fingerprint, 1); // effects
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u64(fingerprint, 0); // airborne action
    fingerprint = hash_u64(fingerprint, 3); // sparkle particles + spawn
    fingerprint = hash_u64(fingerprint, 1); // timer
    fingerprint = hash_u64(fingerprint, UINT64_C(0x3f000000)); // scale
    fingerprint = hash_u64(fingerprint, 0); // face yaw
    fingerprint = hash_u64(fingerprint, UINT64_C(0xffffffffffffc000)); // face roll
    fingerprint = hash_u64(fingerprint, UINT64_C(0x43250000)); // graph Y offset
    fingerprint = hash_u64(fingerprint, 0); // not tangible
    fingerprint = hash_u64(fingerprint, 0); // not marked

    // Isolated shared-dispatch Bouncing Fireball parent/flame routes. The
    // flame is in the general-actor list and the parent is in the default
    // list, preserving the scheduler's cross-list order.
    fingerprint = hash_u64(fingerprint, 1); // scheduler frame
    static const uint64_t fireball_counts[13] = {
        0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0
    };
    for (unsigned index = 0; index < 13; ++index) {
        fingerprint = hash_u64(fingerprint, fireball_counts[index]);
    }
    fingerprint = hash_u64(fingerprint, 2); // object counter
    fingerprint = hash_u64(fingerprint, 2); // updated count
    fingerprint = hash_id(fingerprint, 1, 1); // flame
    fingerprint = hash_id(fingerprint, 0, 1); // parent
    fingerprint = hash_u64(fingerprint, 0); // unloaded count
    fingerprint = hash_u64(fingerprint, 2); // events
    fingerprint = hash_event(fingerprint, 1, BOUNCING_FIREBALL_FLAME_BEHAVIOR, 27);
    fingerprint = hash_event(fingerprint, 0, BOUNCING_FIREBALL_BEHAVIOR, 27);
    fingerprint = hash_u64(fingerprint, 2); // effects
    fingerprint = hash_id(fingerprint, 1, 1); // flame
    fingerprint = hash_u64(fingerprint, 1); // kind
    fingerprint = hash_u64(fingerprint, 0); // action
    fingerprint = hash_u64(fingerprint, 64); // move
    fingerprint = hash_u64(fingerprint, 0); // no children
    fingerprint = hash_u64(fingerprint, UINT64_C(0x3f800000)); // scale
    fingerprint = hash_u64(fingerprint, 0); // not marked
    fingerprint = hash_id(fingerprint, 0, 1); // parent
    fingerprint = hash_u64(fingerprint, 0); // kind
    fingerprint = hash_u64(fingerprint, 0); // action
    fingerprint = hash_u64(fingerprint, 64); // move
    fingerprint = hash_u64(fingerprint, 0); // no children
    fingerprint = hash_u64(fingerprint, 0); // scale
    fingerprint = hash_u64(fingerprint, 0); // not marked

    // Isolated shared-dispatch King Bob-omb intro route.
    fingerprint = hash_u64(fingerprint, 1); // scheduler frame
    static const uint64_t king_counts[13] = {
        0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0
    };
    for (unsigned index = 0; index < 13; ++index) {
        fingerprint = hash_u64(fingerprint, king_counts[index]);
    }
    fingerprint = hash_u64(fingerprint, 1); // object counter
    fingerprint = hash_u64(fingerprint, 1); // updated count
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u64(fingerprint, 0); // unloaded count
    fingerprint = hash_u64(fingerprint, 1); // events
    fingerprint = hash_event(fingerprint, 0, KING_BOBOMB_BEHAVIOR, 28);
    fingerprint = hash_u64(fingerprint, 1); // effects
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u64(fingerprint, 0); // action
    fingerprint = hash_u64(fingerprint, 1); // subaction
    fingerprint = hash_u64(fingerprint, 66055); // reset/camera/music/intangible/rendering
    fingerprint = hash_u64(fingerprint, 0); // no children
    fingerprint = hash_u64(fingerprint, 1); // presented intents
    fingerprint = hash_u64(fingerprint, 1); // deliveries
    fingerprint = hash_u64(fingerprint, 1); // delivered intents
    fingerprint = hash_u64(fingerprint, 1); // presented intents
    fingerprint = hash_u64(fingerprint, 0); // spawned
    fingerprint = hash_u64(fingerprint, 0); // deleted
    fingerprint = hash_u64(fingerprint, 0); // rejected

    // Isolated shared-dispatch Snowman Land walking penguin route.
    fingerprint = hash_u64(fingerprint, 1); // scheduler frame
    static const uint64_t penguin_counts[13] = {
        0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0
    };
    for (unsigned index = 0; index < 13; ++index) {
        fingerprint = hash_u64(fingerprint, penguin_counts[index]);
    }
    fingerprint = hash_u64(fingerprint, 1); // object counter
    fingerprint = hash_u64(fingerprint, 1); // updated count
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u64(fingerprint, 0); // unloaded count
    fingerprint = hash_u64(fingerprint, 1); // events
    fingerprint = hash_event(fingerprint, 0, SL_WALKING_PENGUIN_BEHAVIOR, 29);
    fingerprint = hash_u64(fingerprint, 1); // effects
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u64(fingerprint, 0); // action
    fingerprint = hash_u64(fingerprint, 0); // current step
    fingerprint = hash_u64(fingerprint, 1); // step timer
    fingerprint = hash_u64(fingerprint, UINT64_C(0x40c00000)); // forward velocity
    fingerprint = hash_u64(fingerprint, 1); // animation
    fingerprint = hash_u64(fingerprint, UINT64_C(0x3f800000)); // animation speed
    fingerprint = hash_u64(fingerprint, 0); // yaw velocity
    fingerprint = hash_u64(fingerprint, 8192); // move yaw
    fingerprint = hash_u64(fingerprint, 0); // no completed turn
    fingerprint = hash_u64(fingerprint, 0); // no collision
    fingerprint = hash_u64(fingerprint, 0); // no movement

    // Isolated shared-dispatch small penguin route.
    fingerprint = hash_u64(fingerprint, 1); // scheduler frame
    static const uint64_t small_penguin_counts[13] = {
        0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0
    };
    for (unsigned index = 0; index < 13; ++index) {
        fingerprint = hash_u64(fingerprint, small_penguin_counts[index]);
    }
    fingerprint = hash_u64(fingerprint, 1); // object counter
    fingerprint = hash_u64(fingerprint, 1); // updated count
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u64(fingerprint, 0); // unloaded count
    fingerprint = hash_u64(fingerprint, 1); // events
    fingerprint = hash_event(fingerprint, 0, SMALL_PENGUIN_BEHAVIOR, 30);
    fingerprint = hash_u64(fingerprint, 1); // effects
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u64(fingerprint, 0); // action
    fingerprint = hash_u64(fingerprint, 1); // timer
    fingerprint = hash_u64(fingerprint, 0); // move yaw
    fingerprint = hash_u64(fingerprint, 0); // forward velocity
    fingerprint = hash_u64(fingerprint, 0); // unknown104
    fingerprint = hash_u64(fingerprint, 0); // unknown108
    fingerprint = hash_u64(fingerprint, 0); // unknown110
    fingerprint = hash_u64(fingerprint, 0); // dive return action
    fingerprint = hash_u64(fingerprint, 0); // link flag
    fingerprint = hash_u64(fingerprint, 3); // idle animation
    fingerprint = hash_u64(fingerprint, 0); // held state
    fingerprint = hash_u64(fingerprint, 0); // angle velocity yaw
    fingerprint = hash_u64(fingerprint, 0); // no reset home
    fingerprint = hash_u64(fingerprint, 0); // no walking sound
    fingerprint = hash_u64(fingerprint, 0); // no dive sound
    fingerprint = hash_u64(fingerprint, 0); // no held yell
    fingerprint = hash_u64(fingerprint, 0); // no unrender
    fingerprint = hash_u64(fingerprint, 0); // no copy
    fingerprint = hash_u64(fingerprint, 0); // no behavior switch
    fingerprint = hash_u64(fingerprint, 0); // no throw
    fingerprint = hash_u64(fingerprint, 0); // no drop
    fingerprint = hash_u64(fingerprint, 0); // no presented effects
    fingerprint = hash_u64(fingerprint, 0); // no collision
    fingerprint = hash_u64(fingerprint, 0); // no movement
    fingerprint = hash_u64(fingerprint, 1); // deliveries
    fingerprint = hash_u64(fingerprint, 0); // delivered
    fingerprint = hash_u64(fingerprint, 0); // presented
    fingerprint = hash_u64(fingerprint, 0); // spawned
    fingerprint = hash_u64(fingerprint, 0); // deleted
    fingerprint = hash_u64(fingerprint, 0); // rejected

    // Isolated shared-dispatch underwater Koopa shell route. The underwater
    // shell lives in the general-actor list and has no transient children on
    // its initial free/tangible callback.
    fingerprint = hash_u64(fingerprint, 1); // scheduler frame
    static const uint64_t koopa_counts[13] = {
        0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0
    };
    for (unsigned index = 0; index < 13; ++index) {
        fingerprint = hash_u64(fingerprint, koopa_counts[index]);
    }
    fingerprint = hash_u64(fingerprint, 1); // object counter
    fingerprint = hash_u64(fingerprint, 1); // updated count
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u64(fingerprint, 0); // unloaded count
    fingerprint = hash_u64(fingerprint, 1); // events
    fingerprint = hash_event(fingerprint, 0, KOOPA_UNDERWATER_BEHAVIOR, 31);
    fingerprint = hash_u64(fingerprint, 1); // effects
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u64(fingerprint, 1); // underwater kind
    fingerprint = hash_u64(fingerprint, 4097); // animate + tangible
    fingerprint = hash_u64(fingerprint, 0); // free action
    fingerprint = hash_u64(fingerprint, 0); // no children
    fingerprint = hash_u64(fingerprint, 0); // not marked
    fingerprint = hash_u64(fingerprint, 0); // no deliveries

    // Isolated shared-dispatch Bowser key course-exit cutscene route.
    fingerprint = hash_u64(fingerprint, 1); // scheduler frame
    static const uint64_t key_cutscene_counts[13] = {
        0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0
    };
    for (unsigned index = 0; index < 13; ++index) {
        fingerprint = hash_u64(fingerprint, key_cutscene_counts[index]);
    }
    fingerprint = hash_u64(fingerprint, 1); // object counter
    fingerprint = hash_u64(fingerprint, 1); // updated count
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u64(fingerprint, 0); // unloaded count
    fingerprint = hash_u64(fingerprint, 1); // events
    fingerprint = hash_event(fingerprint, 0, BOWSER_KEY_CUTSCENE_COURSE_EXIT, 32);
    fingerprint = hash_u64(fingerprint, 1); // effects
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u64(fingerprint, 1); // course-exit kind
    fingerprint = hash_u64(fingerprint, 1); // set animation
    fingerprint = hash_u64(fingerprint, 0); // animation frame
    fingerprint = hash_u64(fingerprint, 1); // animation
    fingerprint = hash_u64(fingerprint, UINT64_C(0x3e4ccccd)); // scale
    fingerprint = hash_u64(fingerprint, 1); // timer
    fingerprint = hash_u64(fingerprint, 0); // not marked

    // Isolated shared-dispatch generic explosion destructive-list route.
    fingerprint = hash_u64(fingerprint, 1); // scheduler frame
    static const uint64_t explosion_counts[13] = {
        0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    };
    for (unsigned index = 0; index < 13; ++index) {
        fingerprint = hash_u64(fingerprint, explosion_counts[index]);
    }
    fingerprint = hash_u64(fingerprint, 1); // object counter
    fingerprint = hash_u64(fingerprint, 1); // updated count
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u64(fingerprint, 0); // unloaded count
    fingerprint = hash_u64(fingerprint, 1); // events
    fingerprint = hash_event(fingerprint, 0, EXPLOSION_BEHAVIOR, 33);
    fingerprint = hash_u64(fingerprint, 1); // effects
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u64(fingerprint, 51); // sound + shake + fade + animate
    fingerprint = hash_u64(fingerprint, 0); // bubble count
    fingerprint = hash_u64(fingerprint, 0); // no smoke
    fingerprint = hash_u64(fingerprint, 1); // timer
    fingerprint = hash_u64(fingerprint, UINT64_C(0x3f800000)); // scale
    fingerprint = hash_u64(fingerprint, 241); // opacity
    fingerprint = hash_u64(fingerprint, 0); // animation state
    fingerprint = hash_u64(fingerprint, 2); // presented intents
    fingerprint = hash_u64(fingerprint, 0); // sound kind
    fingerprint = hash_u64(fingerprint, UINT64_C(0xffffffff802e2081)); // sound value
    fingerprint = hash_u64(fingerprint, 2); // camera-shake kind
    fingerprint = hash_u64(fingerprint, 1); // environmental shake
    fingerprint = hash_u64(fingerprint, 0); // not marked
    fingerprint = hash_u64(fingerprint, 0); // no children
    fingerprint = hash_u64(fingerprint, 1); // deliveries
    fingerprint = hash_u64(fingerprint, 2); // delivered intents
    fingerprint = hash_u64(fingerprint, 2); // presented intents
    fingerprint = hash_u64(fingerprint, 0); // spawned
    fingerprint = hash_u64(fingerprint, 0); // deleted
    fingerprint = hash_u64(fingerprint, 0); // rejected

    // Isolated shared-dispatch Moneybag general-actor route.
    fingerprint = hash_u64(fingerprint, 1); // scheduler frame
    static const uint64_t moneybag_counts[13] = {
        0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0
    };
    for (unsigned index = 0; index < 13; ++index) {
        fingerprint = hash_u64(fingerprint, moneybag_counts[index]);
    }
    fingerprint = hash_u64(fingerprint, 1); // object counter
    fingerprint = hash_u64(fingerprint, 1); // updated count
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u64(fingerprint, 0); // unloaded count
    fingerprint = hash_u64(fingerprint, 1); // events
    fingerprint = hash_event(fingerprint, 0, MONEYBAG_BEHAVIOR, 34);
    fingerprint = hash_u64(fingerprint, 1); // effects
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u64(fingerprint, 0); // visible moneybag
    fingerprint = hash_u64(fingerprint, 5); // death action
    fingerprint = hash_u64(fingerprint, 16); // death effect
    fingerprint = hash_u64(fingerprint, 0); // no children
    fingerprint = hash_u64(fingerprint, 0); // not marked
    fingerprint = hash_u64(fingerprint, 0); // no deliveries

    // Isolated shared-dispatch water-bomb spawner, bomb, and shadow family.
    fingerprint = hash_u64(fingerprint, 1); // scheduler frame
    static const uint64_t water_bomb_counts[13] = {
        0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0
    };
    for (unsigned index = 0; index < 13; ++index) {
        fingerprint = hash_u64(fingerprint, water_bomb_counts[index]);
    }
    fingerprint = hash_u64(fingerprint, 3); // object counter
    fingerprint = hash_u64(fingerprint, 3); // updated count
    for (uint64_t id = 0; id < 3; ++id) fingerprint = hash_id(fingerprint, id, 1);
    fingerprint = hash_u64(fingerprint, 0); // unloaded count
    fingerprint = hash_u64(fingerprint, 3); // events
    fingerprint = hash_event(fingerprint, 0, WATER_BOMB_SPAWNER_BEHAVIOR, 35);
    fingerprint = hash_event(fingerprint, 1, WATER_BOMB_BEHAVIOR, 35);
    fingerprint = hash_event(fingerprint, 2, WATER_BOMB_SHADOW_BEHAVIOR, 35);
    fingerprint = hash_u64(fingerprint, 3); // effects
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u64(fingerprint, 0); // spawner kind
    fingerprint = hash_u64(fingerprint, 3); // animate + spawn bomb
    fingerprint = hash_u64(fingerprint, 0); // no action
    fingerprint = hash_u64(fingerprint, 2); // bomb and shadow children
    fingerprint = hash_id(fingerprint, 1, 1);
    fingerprint = hash_id(fingerprint, 2, 1);
    fingerprint = hash_u64(fingerprint, 0); // not marked
    fingerprint = hash_id(fingerprint, 1, 1);
    fingerprint = hash_u64(fingerprint, 1); // bomb kind
    fingerprint = hash_u64(fingerprint, 5); // animate + landing sound
    fingerprint = hash_u64(fingerprint, 1); // action present
    fingerprint = hash_u64(fingerprint, 2); // drop action
    fingerprint = hash_u64(fingerprint, 0); // no children
    fingerprint = hash_u64(fingerprint, 0); // not marked
    fingerprint = hash_id(fingerprint, 2, 1);
    fingerprint = hash_u64(fingerprint, 2); // shadow kind
    fingerprint = hash_u64(fingerprint, 1); // animate
    fingerprint = hash_u64(fingerprint, 1); // action present
    fingerprint = hash_u64(fingerprint, 2); // parent drop action
    fingerprint = hash_u64(fingerprint, 0); // no children
    fingerprint = hash_u64(fingerprint, 0); // not marked
    fingerprint = hash_u64(fingerprint, 0); // no deliveries

    // Isolated shared-dispatch Eyerok boss and two hand family.
    fingerprint = hash_u64(fingerprint, 1); // scheduler frame
    static const uint64_t eyerok_counts[13] = {
        0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0
    };
    for (unsigned index = 0; index < 13; ++index) {
        fingerprint = hash_u64(fingerprint, eyerok_counts[index]);
    }
    fingerprint = hash_u64(fingerprint, 3); // object counter
    fingerprint = hash_u64(fingerprint, 3); // updated count
    for (uint64_t id = 0; id < 3; ++id) fingerprint = hash_id(fingerprint, id, 1);
    fingerprint = hash_u64(fingerprint, 0); // unloaded count
    fingerprint = hash_u64(fingerprint, 3); // events
    fingerprint = hash_event(fingerprint, 0, EYEROK_BEHAVIOR, 36);
    fingerprint = hash_event(fingerprint, 1, EYEROK_HAND_BEHAVIOR, 36);
    fingerprint = hash_event(fingerprint, 2, EYEROK_HAND_BEHAVIOR, 36);
    fingerprint = hash_u64(fingerprint, 3); // effects
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u64(fingerprint, UINT64_C(0xffff)); // no parent sentinel
    fingerprint = hash_u64(fingerprint, 0); // boss kind
    fingerprint = hash_u64(fingerprint, 0); // side
    fingerprint = hash_u64(fingerprint, 0); // sleep boss action
    fingerprint = hash_u64(fingerprint, 255); // no hand action
    fingerprint = hash_u64(fingerprint, 1); // spawn hands
    fingerprint = hash_u64(fingerprint, 0); // no hand effects
    fingerprint = hash_u64(fingerprint, 0); // no star
    fingerprint = hash_u64(fingerprint, 2); // hand children
    fingerprint = hash_id(fingerprint, 1, 1);
    fingerprint = hash_id(fingerprint, 2, 1);
    fingerprint = hash_u64(fingerprint, 0); // no presentation
    fingerprint = hash_id(fingerprint, 1, 1);
    fingerprint = hash_u64(fingerprint, 0); // parent slot
    fingerprint = hash_u64(fingerprint, 1); // hand kind
    fingerprint = hash_u64(fingerprint, UINT64_MAX); // left side
    fingerprint = hash_u64(fingerprint, 255); // no boss action
    fingerprint = hash_u64(fingerprint, 0); // sleep hand action
    fingerprint = hash_u64(fingerprint, 0); // no boss effects
    fingerprint = hash_u64(fingerprint, 0); // no hand effects
    fingerprint = hash_u64(fingerprint, 0); // no star
    fingerprint = hash_u64(fingerprint, 0); // no children
    fingerprint = hash_u64(fingerprint, 0); // no presentation
    fingerprint = hash_id(fingerprint, 2, 1);
    fingerprint = hash_u64(fingerprint, 0); // parent slot
    fingerprint = hash_u64(fingerprint, 1); // hand kind
    fingerprint = hash_u64(fingerprint, 1); // right side
    fingerprint = hash_u64(fingerprint, 255); // no boss action
    fingerprint = hash_u64(fingerprint, 0); // sleep hand action
    fingerprint = hash_u64(fingerprint, 0); // no boss effects
    fingerprint = hash_u64(fingerprint, 0); // no hand effects
    fingerprint = hash_u64(fingerprint, 0); // no star
    fingerprint = hash_u64(fingerprint, 0); // no children
    fingerprint = hash_u64(fingerprint, 0); // no presentation
    fingerprint = hash_u64(fingerprint, 3); // delivery receipts
    for (unsigned index = 0; index < 3; ++index) {
        fingerprint = hash_u64(fingerprint, 0); // delivered
        fingerprint = hash_u64(fingerprint, 0); // presented
        fingerprint = hash_u64(fingerprint, 0); // spawned
        fingerprint = hash_u64(fingerprint, 0); // deleted
        fingerprint = hash_u64(fingerprint, 0); // rejected
    }

    // Isolated shared-dispatch Mr. I eye and persistent iris family.
    fingerprint = hash_u64(fingerprint, 1); // scheduler frame
    static const uint64_t mr_i_counts[13] = {
        0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0
    };
    for (unsigned index = 0; index < 13; ++index) {
        fingerprint = hash_u64(fingerprint, mr_i_counts[index]);
    }
    fingerprint = hash_u64(fingerprint, 2); // object counter
    fingerprint = hash_u64(fingerprint, 2); // updated count
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_id(fingerprint, 1, 1);
    fingerprint = hash_u64(fingerprint, 0); // unloaded count
    fingerprint = hash_u64(fingerprint, 2); // events
    fingerprint = hash_event(fingerprint, 0, MRI_EYE_BEHAVIOR, 37);
    fingerprint = hash_event(fingerprint, 1, MRI_BODY_BEHAVIOR, 37);
    fingerprint = hash_u64(fingerprint, 2); // effects
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u64(fingerprint, 0); // eye kind
    fingerprint = hash_u64(fingerprint, 0); // idle action
    fingerprint = hash_u64(fingerprint, 255); // no particle action
    fingerprint = hash_u64(fingerprint, 5); // reset home + intangible
    fingerprint = hash_u64(fingerprint, 0); // no children
    fingerprint = hash_u64(fingerprint, 0); // not marked
    fingerprint = hash_id(fingerprint, 1, 1);
    fingerprint = hash_u64(fingerprint, 1); // body kind
    fingerprint = hash_u64(fingerprint, 255); // no eye action
    fingerprint = hash_u64(fingerprint, 255); // no particle action
    fingerprint = hash_u64(fingerprint, 0); // no effects
    fingerprint = hash_u64(fingerprint, 0); // no children
    fingerprint = hash_u64(fingerprint, 0); // not marked
    fingerprint = hash_u64(fingerprint, 0); // no deliveries

    // Isolated shared-dispatch racing-penguin parent route.
    fingerprint = hash_u64(fingerprint, 1); // scheduler frame
    static const uint64_t racing_counts[13] = {
        0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0
    };
    for (unsigned index = 0; index < 13; ++index) {
        fingerprint = hash_u64(fingerprint, racing_counts[index]);
    }
    fingerprint = hash_u64(fingerprint, 1); // object counter
    fingerprint = hash_u64(fingerprint, 1); // updated count
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u64(fingerprint, 0); // unloaded count
    fingerprint = hash_u64(fingerprint, 1); // events
    fingerprint = hash_event(fingerprint, 0, RACING_PENGUIN_BEHAVIOR, 38);
    fingerprint = hash_u64(fingerprint, 1); // effects
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u64(fingerprint, 0); // wait-for-Mario action
    fingerprint = hash_u64(fingerprint, 0); // init text cooldown
    fingerprint = hash_u64(fingerprint, 0); // forward velocity
    fingerprint = hash_u64(fingerprint, 0); // weighted target speed
    fingerprint = hash_u64(fingerprint, 0); // move yaw
    fingerprint = hash_u64(fingerprint, 0); // animation
    fingerprint = hash_u64(fingerprint, 0); // final textbox
    fingerprint = hash_u64(fingerprint, 0); // Mario won
    fingerprint = hash_u64(fingerprint, 0); // Mario cheated
    fingerprint = hash_u64(fingerprint, 0); // reached bottom
    fingerprint = hash_u64(fingerprint, 0); // reset timer
    fingerprint = hash_u64(fingerprint, 0); // no race children
    fingerprint = hash_u64(fingerprint, 0); // no spawned children
    fingerprint = hash_u64(fingerprint, 0); // no presented effects
    fingerprint = hash_u64(fingerprint, 1); // delivery receipts
    fingerprint = hash_u64(fingerprint, 0); // delivered
    fingerprint = hash_u64(fingerprint, 0); // presented
    fingerprint = hash_u64(fingerprint, 0); // spawned
    fingerprint = hash_u64(fingerprint, 0); // deleted
    fingerprint = hash_u64(fingerprint, 0); // rejected

    // Isolated shared-dispatch Yoshi parent route.
    fingerprint = hash_u64(fingerprint, 1); // scheduler frame
    static const uint64_t yoshi_counts[13] = {
        0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0
    };
    for (unsigned index = 0; index < 13; ++index) {
        fingerprint = hash_u64(fingerprint, yoshi_counts[index]);
    }
    fingerprint = hash_u64(fingerprint, 1); // object counter
    fingerprint = hash_u64(fingerprint, 1); // updated count
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u64(fingerprint, 0); // unloaded count
    fingerprint = hash_u64(fingerprint, 1); // events
    fingerprint = hash_event(fingerprint, 0, YOSHI_BEHAVIOR, 39);
    fingerprint = hash_u64(fingerprint, 1); // effects
    fingerprint = hash_id(fingerprint, 0, 1);
    fingerprint = hash_u64(fingerprint, 0); // idle action
    fingerprint = hash_u64(fingerprint, 0); // timer
    fingerprint = hash_u64(fingerprint, 0); // animation
    fingerprint = hash_u64(fingerprint, 0); // dialog ID
    fingerprint = hash_u64(fingerprint, 0); // dialog requested
    fingerprint = hash_u64(fingerprint, 0); // active time stop
    fingerprint = hash_u64(fingerprint, 0); // clear time stop
    fingerprint = hash_u64(fingerprint, 0); // clear interaction
    fingerprint = hash_u64(fingerprint, 0); // walk sound
    fingerprint = hash_u64(fingerprint, 0); // puzzle jingle
    fingerprint = hash_u64(fingerprint, 0); // alert sound
    fingerprint = hash_u64(fingerprint, 0); // extra life sound
    fingerprint = hash_u64(fingerprint, 0); // lives delta
    fingerprint = hash_u64(fingerprint, 0); // special triple jump
    fingerprint = hash_u64(fingerprint, 0); // camera request
    fingerprint = hash_u64(fingerprint, 0); // respawner requested
    fingerprint = hash_u64(fingerprint, 0); // deactivated
    fingerprint = hash_u64(fingerprint, 0); // spawned respawners
    fingerprint = hash_u64(fingerprint, 0); // presented effects
    fingerprint = hash_u64(fingerprint, 1); // delivery receipts
    fingerprint = hash_u64(fingerprint, 0); // delivered
    fingerprint = hash_u64(fingerprint, 0); // presented
    fingerprint = hash_u64(fingerprint, 0); // spawned
    fingerprint = hash_u64(fingerprint, 0); // deleted
    fingerprint = hash_u64(fingerprint, 0); // rejected

    printf("behaviorDispatchBridgeFingerprint=0x%016llx\n",
           (unsigned long long) fingerprint);
    printf("SM64 Modern behavior dispatch bridge C contract passed\n");
    return 0;
}
