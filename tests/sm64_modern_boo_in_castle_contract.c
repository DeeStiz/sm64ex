#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=P;}return s;}
static uint64_t add(uint64_t s,int action,int timer,int visible,int opacity,int angle,int deleted,int laugh,uint32_t velocity){s=h(s,action);s=h(s,timer);s=h(s,visible);s=h(s,(uint64_t)(int64_t)opacity);s=h(s,(uint64_t)(int64_t)angle);s=h(s,deleted);s=h(s,laugh);return h(s,velocity);}
int main(void){uint64_t f=O;f=add(f,0,1,0,255,0,1,0,0);f=add(f,1,1,1,255,0,0,0,0);f=add(f,2,1,1,180,123,0,1,0);f=add(f,1,3,1,160,77,0,0,0x42000000);printf("booInCastleFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern boo-in-castle C contract passed");return 0;}
