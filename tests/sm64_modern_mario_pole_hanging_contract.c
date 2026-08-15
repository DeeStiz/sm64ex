#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define NONE32 UINT32_MAX
static uint64_t h8(uint64_t h,uint8_t v){h^=v;return h*FNV_PRIME;}
static uint64_t h16(uint64_t h,uint16_t v){for(unsigned i=0;i<2;++i)h=h8(h,(uint8_t)(v>>(i*8u)));return h;}
static uint64_t h32(uint64_t h,uint32_t v){for(unsigned i=0;i<4;++i)h=h8(h,(uint8_t)(v>>(i*8u)));return h;}
static uint64_t hf(uint64_t h,uint32_t v){return h32(h,v);}
static uint64_t result(uint64_t h,uint8_t variant,uint8_t intent,uint32_t action,
                       uint32_t arg,uint16_t timer,uint16_t anim,uint32_t accel,
                       uint16_t yaw,uint32_t pole,uint16_t poleYaw,uint32_t fwd,
                       uint32_t vx,uint32_t vy,uint32_t vz,uint8_t queue,uint16_t dist,
                       uint8_t reset,uint8_t whoa,uint8_t climb,uint8_t step,
                       uint8_t leaves,uint8_t sync){
    h=h8(h,variant);h=h8(h,intent);h=h32(h,action);h=h32(h,arg);h=h16(h,timer);
    h=h16(h,anim);h=h32(h,accel);h=h16(h,yaw);h=hf(h,pole);h=h16(h,poleYaw);
    h=hf(h,fwd);h=hf(h,vx);h=hf(h,vy);h=hf(h,vz);h=h8(h,queue);h=h16(h,dist);
    h=h8(h,reset);h=h8(h,whoa);h=h8(h,climb);h=h8(h,step);h=h8(h,leaves);return h8(h,sync);
}
int main(void){
    uint64_t h=FNV_OFFSET;
    h=result(h,0,0,NONE32,0,0,0x000D,0,0x1128,0x421B6000,0x0128,
             0,0,0,0,0,0,1,0,1,0,0,1);
    h=result(h,1,0,NONE32,0,0,0x0005,0x00040000,0x1400,0x42280000,0x0100,
             0,0,0,0,0,0,0,0,1,0,1,1);
    h=result(h,2,5,UINT32_C(0x08100340),0,0,0x0006,0,0x1000,0x41A00000,0x0100,
             0,0,0,0,0,0,0,1,0,0,1,1);
    h=result(h,4,10,UINT32_C(0x00100345),0,0,0x000B,0,0x1000,0x41A00000,0,
             0,0,0,0,0,0,0,0,0,0,0,1);
    h=result(h,6,12,UINT32_C(0x00200349),0,0,0,0,0x1000,0x41A00000,0x0100,
             0,0,0,0,0,0,0,0,0,0,0,0);
    h=result(h,7,13,UINT32_C(0x0020054A),1,0,0,0,0x1000,0x41A00000,0x0100,
             0,0,0,0,0,0,0,0,0,0,0,0);
    h=result(h,8,0,NONE32,0,0,0x005C,0,0x1800,0x41A00000,0x0100,
             0x40400000,0x3FD556C7,0,0x401FA465,1,0x001E,0,0,0,1,0,1);
    h=result(h,8,2,UINT32_C(0x0100088C),0,0,0,0,0x1800,0x41A00000,0x0100,
             0x3F800000,0x3F0E39DA,0,0x3F54DB31,0,0,0,0,0,0,0,0);
    printf("marioPoleHangingFingerprint=0x%016llx\n",(unsigned long long)h);return 0;
}
