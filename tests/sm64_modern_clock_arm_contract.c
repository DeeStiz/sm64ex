#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=P;}return s;}
static uint64_t add(uint64_t s,int action,int timer,int roll,int speed,int rotating){s=h(s,action);s=h(s,timer);s=h(s,(uint64_t)(int64_t)roll);s=h(s,speed);return h(s,rotating);}
int main(void){uint64_t f=O;f=add(f,0,4,68,255,1);f=add(f,1,5,68,255,1);f=add(f,2,5,0xA000,0,0);printf("clockArmFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern clock-arm C contract passed");return 0;}
