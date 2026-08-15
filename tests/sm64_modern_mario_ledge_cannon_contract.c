#include <stdint.h>
#include <stdio.h>
#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define NONE32 UINT32_MAX
static uint64_t h8(uint64_t h,uint8_t v){h^=v;return h*FNV_PRIME;}
static uint64_t h16(uint64_t h,uint16_t v){for(unsigned i=0;i<2;++i)h=h8(h,(uint8_t)(v>>(i*8u)));return h;}
static uint64_t h32(uint64_t h,uint32_t v){for(unsigned i=0;i<4;++i)h=h8(h,(uint8_t)(v>>(i*8u)));return h;}
static uint64_t result(uint64_t h,uint8_t variant,uint8_t intent,uint32_t action,uint32_t arg,uint8_t state,uint16_t timer,uint16_t anim,uint16_t yaw,uint16_t pitch,uint16_t inputYaw,uint32_t px,uint32_t py,uint32_t pz,uint32_t vx,uint32_t vy,uint32_t vz,uint32_t fwd,uint8_t hide,uint8_t show,uint8_t mark,uint8_t whoa,uint8_t climb,uint8_t land,uint8_t aim,uint8_t queue,uint8_t reset,uint8_t release){
 h=h8(h,variant);h=h8(h,intent);h=h32(h,action);h=h32(h,arg);h=h8(h,state);h=h16(h,timer);h=h16(h,anim);h=h16(h,yaw);h=h16(h,pitch);h=h16(h,inputYaw);h=h32(h,px);h=h32(h,py);h=h32(h,pz);h=h32(h,vx);h=h32(h,vy);h=h32(h,vz);h=h32(h,fwd);h=h8(h,hide);h=h8(h,show);h=h8(h,mark);h=h8(h,whoa);h=h8(h,climb);h=h8(h,land);h=h8(h,aim);h=h8(h,queue);h=h8(h,reset);return h8(h,release);
}
int main(void){uint64_t h=FNV_OFFSET;
 h=result(h,0,4,UINT32_C(0x0000054C),0,0,0x000A,0,0,0x2000,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
 h=result(h,0,3,UINT32_C(0x0000054F),0,0,0x0001,0,0,0x2000,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
 h=result(h,2,6,UINT32_C(0x0800034B),1,0,0,0x001C,0,0x2000,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
 h=result(h,3,0,NONE32,0,
   0,0,0x0034,0,0x2000,0,
   0,0,0, 0,0,0, 0,
   0,0,0,0,0, 1, 0,0,0,0);
 h=result(h,4,0,NONE32,0,1,0,0x0088,0x1000,0x2000,0,0x3F800000,0x43B00000,0x40400000,0,0,0,0,1,0,1,0,0,0,0,0,0,0);
 h=result(h,4,0,NONE32,0,2,0,0x0088,0x2000,0x3000,0,0x41200000,0x41A00000,0x41F00000,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
 h=result(h,4,9,UINT32_C(0x00880898),0,2,0,0x0088,0x2000,0x3000,0,0x4229E317,0x4302DD94,0x4279E317,0,0x42B8C6A1,0,0x421912C8,0,1,0,0,0,0,0,1,0,0);
 printf("marioLedgeCannonFingerprint=0x%016llx\n",(unsigned long long)h);return 0;}
