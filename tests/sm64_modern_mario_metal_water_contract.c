#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define NONE32 UINT32_MAX
static uint64_t h8(uint64_t h, uint8_t v) { h ^= v; return h * FNV_PRIME; }
static uint64_t h16(uint64_t h, uint16_t v) { for (unsigned i=0;i<2;++i) h=h8(h,(uint8_t)(v>>(i*8u))); return h; }
static uint64_t h32(uint64_t h, uint32_t v) { for (unsigned i=0;i<4;++i) h=h8(h,(uint8_t)(v>>(i*8u))); return h; }
static uint64_t result(uint64_t h, uint8_t variant, uint8_t intent, uint32_t action,
                       uint32_t arg, uint8_t state, uint16_t anim, uint32_t accel,
                       uint16_t yaw, uint16_t pitch, uint16_t roll,
                       uint32_t fwd, uint32_t vx, uint32_t vy, uint32_t vz,
                       uint8_t drop, uint8_t stop, uint8_t slow, uint8_t jump,
                       uint8_t land, uint8_t mist, uint8_t step, uint8_t dust,
                       uint8_t wave) {
    h=h8(h,variant); h=h8(h,intent); h=h32(h,action); h=h32(h,arg); h=h8(h,state);
    h=h16(h,anim); h=h32(h,accel); h=h16(h,yaw); h=h16(h,pitch); h=h16(h,roll);
    h=h32(h,fwd); h=h32(h,vx); h=h32(h,vy); h=h32(h,vz); h=h8(h,drop);
    h=h8(h,stop); h=h8(h,slow); h=h8(h,jump); h=h8(h,land); h=h8(h,mist);
    h=h8(h,step); h=h8(h,dust); return h8(h,wave);
}
int main(void) {
    uint64_t h=FNV_OFFSET;
    h=result(h,0,0,NONE32,0,0,0x00C5,0,0x0800,0x0100,0xFF80,
             0,0,0xC0800000,0,
             0,1,0,0,0,0,0,0,1);
    h=result(h,1,3,UINT32_C(0x080042F0),0,0,0,0,0x0800,0x0100,0xFF80,
             0x41000000,0,0xC0800000,0,
             1,0,0,0,0,0,0,0,0);
    h=result(h,2,0,NONE32,0,0,0x0048,0x00030000,0x1000,0x0100,0xFF80,
             0x414D2288,0x409D00E2,0,0x413D8519,0,0,0,0,0,0,1,1,0);
    h=result(h,3,8,UINT32_C(0x000042F5),1,0,0x0017,0x00020000,0x1000,0x0100,0xFF80,
             0x40A03927,0x3FF54256,0,0x409406E8,0,0,0,0,0,0,0,0,0);
    h=result(h,4,11,UINT32_C(0x000044FA),0,0,0x004D,0,0x0800,0x0100,0xFF80,
             0x412BD35E,0x4006160A,0xC0000000,0x41288629,0,0,0,1,0,1,0,0,0);
    h=result(h,4,15,UINT32_C(0x01000889),1,0,0,0,0x0800,0x0100,0xFF80,
             0x41000000,0,0x40A00000,0,
             0,0,0,0,0,0,0,0,0);
    h=result(h,6,13,UINT32_C(0x000042F6),0,0,0x00A9,0,0x0800,0,0,
             0x40000000,0x3EC7C5C2,0xC0400000,0x3FFB14BE,0,0,1,0,0,0,0,0,0);
    h=result(h,10,3,UINT32_C(0x080042F0),0,0,0x0057,0,0x0800,0x0100,0xFF80,
             0x41000000,0,0xC0800000,0,
             0,1,0,0,1,0,0,0,0);
    printf("marioMetalWaterFingerprint=0x%016llx\n",(unsigned long long)h);
    return 0;
}
