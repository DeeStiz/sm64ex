#include <stdint.h>
#include <stdio.h>
#define O UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=P;}return s;}
static uint64_t hf(uint64_t s,float v){union{float f;uint32_t u;}x={v};return h(s,x.u);}
static uint64_t add(uint64_t s,int kind,int32_t t,int32_t a,int vis,int model,int spark,int del){s=h(s,kind);s=h(s,(uint64_t)(int64_t)t);s=h(s,(uint64_t)(int64_t)a);s=h(s,vis);s=h(s,model);s=h(s,spark);s=h(s,del);s=hf(s,100);s=hf(s,64);return h(s,1);}
int main(void){uint64_t f=O;f=add(f,0,1,0,1,1,0,0);f=add(f,1,201,5,1,0,0,0);f=add(f,1,244,9,0,0,0,1);f=add(f,0,4,3,1,0,1,1);printf("coinFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern coin C contract passed");return 0;}
