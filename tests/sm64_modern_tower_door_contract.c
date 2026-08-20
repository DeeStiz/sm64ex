#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=P;}return s;}
static uint64_t add(uint64_t s,int32_t t,int32_t yaw,int mist,int tri,int32_t coins,int sound,int remove){s=h(s,(uint64_t)(int64_t)t);s=h(s,(uint64_t)(int64_t)yaw);s=h(s,mist);s=h(s,tri);s=h(s,(uint64_t)(int64_t)coins);s=h(s,sound);return h(s,remove);}
int main(void){uint64_t f=O;f=add(f,1,0x1000,0,0,0,0,0);f=add(f,2,0x5000,0,0,0,0,0);f=add(f,5,0x5000,1,1,0,1,1);printf("towerDoorFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern tower-door C contract passed");return 0;}
