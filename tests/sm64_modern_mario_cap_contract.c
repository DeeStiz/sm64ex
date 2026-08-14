#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define MARIO_NORMAL_CAP UINT32_C(0x01)
#define MARIO_VANISH_CAP UINT32_C(0x02)
#define MARIO_METAL_CAP UINT32_C(0x04)
#define MARIO_WING_CAP UINT32_C(0x08)
#define MARIO_CAP_ON_HEAD UINT32_C(0x10)
#define MARIO_CAP_IN_HAND UINT32_C(0x20)
#define TEMPORARY_CAP_MASK (MARIO_VANISH_CAP | MARIO_METAL_CAP | MARIO_WING_CAP)
#define PERSISTENT_CAP_MASK (MARIO_NORMAL_CAP | TEMPORARY_CAP_MASK)

struct state { uint32_t flags; uint32_t action; uint16_t cap_timer; };
struct mutation {
    uint16_t cap_timer;
    uint32_t flags;
    uint32_t render_flags;
    uint8_t did_expire;
    uint8_t fade;
    uint8_t flicker;
};

static uint64_t hash_u8(uint64_t h, uint8_t v) { return (h ^ v) * FNV_PRIME; }
static uint64_t hash_u16(uint64_t h, uint16_t v) {
    for (unsigned i = 0; i < 2; ++i) { h ^= (v >> (i * 8u)) & 0xffu; h *= FNV_PRIME; }
    return h;
}
static uint64_t hash_u32(uint64_t h, uint32_t v) {
    for (unsigned i = 0; i < 4; ++i) { h ^= (v >> (i * 8u)) & 0xffu; h *= FNV_PRIME; }
    return h;
}
static uint64_t hash_mutation(uint64_t h, struct mutation m) {
    h = hash_u16(h, m.cap_timer); h = hash_u32(h, m.flags); h = hash_u32(h, m.render_flags);
    h = hash_u8(h, m.did_expire); h = hash_u8(h, m.fade); return hash_u8(h, m.flicker);
}

static struct mutation initial(struct state *s, unsigned course) {
    uint32_t cap = 0; uint16_t timer = 0;
    switch (course) {
        case 20: cap = MARIO_METAL_CAP; timer = 600; break;
        case 21: cap = MARIO_WING_CAP; timer = 1200; break;
        case 22: cap = MARIO_VANISH_CAP; timer = 600; break;
        default: return (struct mutation){0, s->flags, s->flags, 0, 0, 0};
    }
    s->flags |= cap | MARIO_CAP_ON_HEAD; s->cap_timer = timer;
    return (struct mutation){s->cap_timer, s->flags, s->flags, 0, 0, 0};
}

static struct mutation pickup(struct state *s, uint32_t cap, uint16_t timer) {
    s->flags &= ~MARIO_CAP_ON_HEAD & ~MARIO_CAP_IN_HAND;
    s->flags |= cap;
    if (timer > s->cap_timer) s->cap_timer = timer;
    return (struct mutation){s->cap_timer, s->flags, s->flags, 0, 0, 0};
}

static struct mutation tick(struct state *s) {
    const uint64_t flicker_frames = UINT64_C(0x4444449249255555);
    uint32_t flags = s->flags;
    uint8_t expired = 0, fade = 0, flicker = 0;
    if (s->cap_timer > 0) {
        int pauses = s->action == UINT32_C(0x20001305)
            || s->action == UINT32_C(0x20001306)
            || s->action == UINT32_C(0x00001308)
            || s->action == UINT32_C(0x00001371);
        if (s->cap_timer <= 60 || !pauses) s->cap_timer--;
        if (s->cap_timer == 0) {
            expired = 1;
            s->flags &= ~TEMPORARY_CAP_MASK;
            if ((s->flags & PERSISTENT_CAP_MASK) == 0) s->flags &= ~MARIO_CAP_ON_HEAD;
        }
        fade = s->cap_timer == 0x3c;
        if (s->cap_timer < 0x40 && ((flicker_frames & (UINT64_C(1) << s->cap_timer)) != 0)) {
            flags &= ~TEMPORARY_CAP_MASK;
            if ((flags & PERSISTENT_CAP_MASK) == 0) flags &= ~MARIO_CAP_ON_HEAD;
            flicker = 1;
        }
    }
    return (struct mutation){s->cap_timer, s->flags, flags, expired, fade, flicker};
}

int main(void) {
    uint64_t h = FNV_OFFSET;
    struct state s = {0}; h = hash_mutation(h, initial(&s, 20));
    s = (struct state){0}; h = hash_mutation(h, initial(&s, 21));
    s = (struct state){0}; h = hash_mutation(h, initial(&s, 22));
    s = (struct state){MARIO_METAL_CAP | MARIO_CAP_ON_HEAD, UINT32_C(0x20001305), 100};
    h = hash_mutation(h, tick(&s));
    s = (struct state){MARIO_METAL_CAP | MARIO_CAP_ON_HEAD, 0, 61};
    h = hash_mutation(h, tick(&s));
    s = (struct state){MARIO_METAL_CAP | MARIO_CAP_ON_HEAD, 0, 1};
    h = hash_mutation(h, tick(&s));
    s = (struct state){MARIO_NORMAL_CAP | MARIO_CAP_ON_HEAD, 0, 10};
    h = hash_mutation(h, pickup(&s, MARIO_WING_CAP, 1800));
    printf("marioCapFingerprint=0x%016llx\n", (unsigned long long) h);
    return 0;
}
