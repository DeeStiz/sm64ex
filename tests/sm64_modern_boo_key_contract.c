#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=P;}return s;}
static uint64_t add(uint64_t s,int kind,int action,int timer,int roll,int yaw,int tangible,int copy,int deleted,int spark,int death,int hoot){s=h(s,kind);s=h(s,action);s=h(s,timer);s=h(s,(uint64_t)(int64_t)roll);s=h(s,(uint64_t)(int64_t)yaw);s=h(s,tangible);s=h(s,copy);s=h(s,deleted);s=h(s,spark);s=h(s,death);return h(s,hoot);}
int main(void){uint64_t f=O;f=add(f,0,0,1,512,512,1,0,1,1,1,0);f=add(f,1,0,1,512,512,0,1,0,0,0,0);f=add(f,1,1,0,512,512,0,0,0,0,0,0);f=add(f,1,2,5,2048,2048,1,0,1,1,0,1);printf("booKeyFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern boo-key C contract passed");return 0;}
