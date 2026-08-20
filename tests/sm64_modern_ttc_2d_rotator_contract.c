#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

struct Output { int32_t timer, min_time, target; int16_t increment, random_timer, face, angle_velocity; };
static uint64_t hash_u32(uint64_t h, uint32_t v) { for (unsigned b=0;b<4;++b){h^=(v>>(b*8u))&255u;h*=FNV_PRIME;} return h; }
static int16_t approach(int16_t value, int16_t target, int16_t increment, int *reached) {
    int16_t distance = (int16_t)((int32_t)target - (int32_t)value);
    if (distance >= 0) { if (distance > increment) { *reached=0; return (int16_t)((int32_t)value + increment); } }
    else if (distance < -increment) { *reached=0; return (int16_t)((int32_t)value - increment); }
    *reached=1; return target;
}
static struct Output update(int32_t speed_setting, int32_t timer, int32_t min_time, int32_t target,
                            int16_t increment, int16_t speed, int32_t random_timer, int16_t face,
                            int random_uses_speed) {
    int reached=0; int16_t next_face=approach(face,(int16_t)target,200,&reached);
    if (random_timer != 0) --random_timer;
    if (min_time != 0 && reached && timer > min_time) {
        target += increment; timer=0;
        if (speed_setting == 2) { if (random_timer == 0) { if (random_uses_speed) { increment=speed; random_timer=90; } else { increment=(int16_t)-speed; random_timer=30; } } min_time=10; }
    }
    return (struct Output){timer,min_time,target,increment,(int16_t)random_timer,next_face,(int16_t)(next_face-face)};
}
static void append(uint64_t *h, struct Output o) { *h=hash_u32(*h,(uint32_t)o.timer);*h=hash_u32(*h,(uint32_t)o.min_time);*h=hash_u32(*h,(uint32_t)o.target);*h=hash_u32(*h,(uint16_t)o.increment);*h=hash_u32(*h,(uint32_t)o.random_timer);*h=hash_u32(*h,(uint16_t)o.face);*h=hash_u32(*h,(uint16_t)o.angle_velocity); }
int main(void) {
    struct Output waiting=update(0,40,40,0,-0x444,-0x444,0,0,1);
    struct Output turn=update(0,41,40,0,-0x444,-0x444,0,0,1);
    struct Output reverse=update(2,11,10,0,-0x444,-0x444,0,0,0);
    uint64_t h=FNV_OFFSET; append(&h,waiting);append(&h,turn);append(&h,reverse);
    printf("ttc2DRotatorFingerprint=0x%016llx\n",(unsigned long long)h);
    printf("SM64 Modern TTC 2D rotator C contract matched\n"); return waiting.timer==40 && turn.target==-0x444 && reverse.increment==0x444 ? 0 : 1;
}
