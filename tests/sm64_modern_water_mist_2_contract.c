#include <stdint.h>
#include <stdio.h>
#include <string.h>
#define H UINT64_C(1469598103934665603)
#define P UINT64_C(1099511628211)
static uint64_t h(uint64_t x,uint64_t v){for(unsigned i=0;i<8;i++){x^=(v>>(i*8u))&0xff;x*=P;}return x;}static uint64_t hf(uint64_t x,float v){uint32_t b=0;memcpy(&b,&v,sizeof(b));return h(x,b);}
int main(void){float x=-40,y=120,z=45;int o=225;if(x!=-40||y!=120||z!=45||o!=225)return 1;uint64_t f=H;f=hf(f,x);f=hf(f,y);f=hf(f,z);f=h(f,(uint64_t)(int64_t)o);printf("waterMist2Fingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern water mist 2 C contract passed");return 0;}
