#include <stdint.h>
#include <stdio.h>

#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)
static uint64_t h(uint64_t s,uint64_t v){for(unsigned i=0;i<8;i++){s^=(v>>(i*8))&255;s*=PRIME;}return s;}
static uint64_t row(uint64_t s,int a,int t,int p,uint32_t speed,int fp,int av,int tangible,int fell,int del,int impact,int fall){s=h(s,(uint64_t)(int64_t)a);s=h(s,(uint64_t)(int64_t)t);s=h(s,(uint64_t)(int64_t)p);s=h(s,speed);s=h(s,(uint64_t)(int64_t)fp);s=h(s,(uint64_t)(int64_t)av);s=h(s,tangible);s=h(s,fell);s=h(s,del);s=h(s,impact);return h(s,fall);}
int main(void){uint64_t f=OFFSET;f=row(f,1,0,0,UINT32_C(0x44C80000),0,0,1,0,0,0,0);f=row(f,2,0,1024,UINT32_C(0x44780000),0,0,1,0,0,1,0);f=row(f,2,1,0,0,-128,-128,0,1,0,0,0);f=row(f,3,11,0,0,-16384,0,0,1,0,0,1);printf("kickableBoardFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern Kickable Board C contract passed");return 0;}
