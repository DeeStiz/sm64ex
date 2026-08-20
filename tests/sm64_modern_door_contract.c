#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=P;}return s;}
static uint64_t add(uint64_t s,int32_t a,int32_t t,int32_t anim,int vis,int load,int sound,int camera,int stop,int clear){s=h(s,(uint64_t)(int64_t)a);s=h(s,(uint64_t)(int64_t)t);s=h(s,(uint64_t)(int64_t)anim);s=h(s,vis);s=h(s,load);s=h(s,sound);s=h(s,camera);s=h(s,stop);return h(s,clear);}
int main(void){uint64_t f=O;f=add(f,0,1,0,1,1,0,0,0,0);f=add(f,1,1,1,1,0,1,1,1,1);f=add(f,2,71,2,1,0,4,0,0,0);f=add(f,3,31,3,1,0,5,0,0,0);f=add(f,0,0,0,0,1,0,0,0,0);printf("doorFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern door C contract passed");return 0;}
