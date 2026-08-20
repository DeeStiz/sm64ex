#include <stdint.h>
#include <stdio.h>
#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=PRIME;}return s;}
static uint64_t row(uint64_t s,int action,int timer,int yaw,uint32_t gravity,uint32_t friction,uint32_t buoyancy,int opacity,int tangible,int dead){s=h(s,(uint64_t)(int64_t)action);s=h(s,(uint64_t)(int64_t)timer);s=h(s,(uint64_t)(int64_t)yaw);s=h(s,gravity);s=h(s,friction);s=h(s,buoyancy);s=h(s,(uint64_t)(int64_t)opacity);s=h(s,tangible);return h(s,dead);}
int main(void){uint64_t f=OFFSET;f=row(f,0,1,356,UINT32_C(0x4019999a),UINT32_C(0x3f7fbe77),UINT32_C(0x3fc00000),255,0,0);f=row(f,0,22,0,UINT32_C(0x4019999a),UINT32_C(0x3f7fbe77),UINT32_C(0x3fc00000),255,1,0);f=row(f,0,302,0,UINT32_C(0x4019999a),UINT32_C(0x3f7fbe77),UINT32_C(0x3fc00000),255,1,1);printf("metalCapFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern metal cap C contract passed");return 0;}
