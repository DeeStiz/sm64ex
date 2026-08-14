#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define ACT_IDLE UINT32_C(0x0c400201)
#define ACT_WALKING UINT32_C(0x04000440)
#define ACT_CROUCHING UINT32_C(0x0c008220)
#define ACT_CROUCH_SLIDE UINT32_C(0x04808459)
#define FLAG_PUNCH UINT32_C(0x00100000)
#define FLAG_KICK UINT32_C(0x00200000)
#define FLAG_TRIP UINT32_C(0x00400000)
struct input { uint8_t moving, at_end, past_end, b; uint32_t arg; int16_t frame; };
struct result { uint32_t arg, transition, flags; uint16_t animation; uint8_t punch_state, sound; };
static uint64_t hash_u8(uint64_t h,uint8_t v){return(h^v)*FNV_PRIME;}
static uint64_t hash_u16(uint64_t h,uint16_t v){for(unsigned i=0;i<2;++i){h^=(v>>(i*8u))&0xffu;h*=FNV_PRIME;}return h;}
static uint64_t hash_u32(uint64_t h,uint32_t v){for(unsigned i=0;i<4;++i){h^=(v>>(i*8u))&0xffu;h*=FNV_PRIME;}return h;}
static uint64_t hash_result(uint64_t h,struct result r){h=hash_u32(h,r.arg);h=hash_u16(h,r.animation);h=hash_u32(h,r.transition);h=hash_u32(h,r.flags);h=hash_u8(h,r.punch_state);return hash_u8(h,r.sound);}
static struct result run(struct input in){
    uint32_t end=in.moving?ACT_WALKING:ACT_IDLE,crouch=in.moving?ACT_CROUCH_SLIDE:ACT_CROUCHING;
    if(in.arg==0||in.arg==1){uint32_t a=in.past_end?2:1;return(struct result){a,UINT32_MAX,in.frame>=2?FLAG_PUNCH:0,in.arg<=1?0x67:0x67,a==2?4:255,in.arg==0?1:0};}
    if(in.arg==2){if(in.at_end)return(struct result){0,end,in.frame<=0?FLAG_PUNCH:0,0x69,255,0};return(struct result){in.b?3:2,UINT32_MAX,in.frame<=0?FLAG_PUNCH:0,0x69,255,0};}
    if(in.arg==3||in.arg==4){uint32_t a=in.past_end?5:4;return(struct result){a,UINT32_MAX,in.frame>0?FLAG_PUNCH:0,0x68, a==5?68:255,in.arg==3?2:0};}
    if(in.arg==5){if(in.at_end)return(struct result){0,end,in.frame<=0?FLAG_PUNCH:0,0x6a,255,0};return(struct result){in.b?6:5,UINT32_MAX,in.frame<=0?FLAG_PUNCH:0,0x6a,255,0};}
    if(in.arg==6)return(struct result){6,in.at_end?end:UINT32_MAX,(in.frame>=0&&in.frame<8)?FLAG_KICK:0,0x66,in.frame==0?134:255,3};
    if(in.arg==9)return(struct result){9,in.at_end?crouch:UINT32_MAX,(in.frame>=2&&in.frame<8)?FLAG_TRIP:0,0x71,255,3};
    return(struct result){0};
}
static struct input in(uint32_t arg,uint8_t moving,int16_t frame,uint8_t at_end,uint8_t past_end,uint8_t b){return(struct input){moving,at_end,past_end,b,arg,frame};}
int main(void){uint64_t h=FNV_OFFSET;
 h=hash_result(h,run(in(0,1,2,0,0,0)));h=hash_result(h,run(in(1,1,3,0,1,0)));h=hash_result(h,run(in(2,1,0,0,0,1)));h=hash_result(h,run(in(2,1,3,1,0,0)));h=hash_result(h,run(in(3,1,1,0,0,0)));h=hash_result(h,run(in(4,1,1,0,1,0)));h=hash_result(h,run(in(6,1,0,0,0,0)));h=hash_result(h,run(in(6,0,8,1,0,0)));h=hash_result(h,run(in(9,0,3,1,0,0)));
 printf("marioPunchSequenceFingerprint=0x%016llx\n",(unsigned long long)h);return 0;}
