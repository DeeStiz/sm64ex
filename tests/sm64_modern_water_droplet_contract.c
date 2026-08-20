#include <stdint.h>
#include <stdio.h>
#include <string.h>
#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
static uint64_t h8(uint64_t h,uint64_t v){for(unsigned i=0;i<8;i++){h^=(v>>(i*8u))&UINT64_C(0xff);h*=FNV_PRIME;}return h;}static uint64_t hf(uint64_t h,float v){uint32_t b=0;memcpy(&b,&v,sizeof(b));return h8(h,b);}
struct o{float y,vy;int32_t t;int del,splash;};static struct o u(float y,float vy,int32_t t,float w,int inter){struct o o={y+vy-4,vy-4,t+1,0,0};if(o.vy<0){if(w>o.y){o.del=1;o.splash=1;}else if(t>20)o.del=1;}if(w<-10000)o.del=1;if(inter)o.del=1;return o;}
int main(void){struct o a[]={u(0,5,0,100,0),u(0,-1,1,100,0),u(0,-1,21,-100,0)};if(a[0].y!=1||a[0].vy!=1||a[0].del||!a[1].del||!a[1].splash||a[1].y!=-5||!a[2].del||a[2].splash)return 1;uint64_t f=FNV_OFFSET;for(unsigned i=0;i<3;i++){f=hf(f,a[i].y);f=hf(f,a[i].vy);f=h8(f,(uint64_t)(int64_t)a[i].t);f=h8(f,a[i].del);f=h8(f,a[i].splash);}printf("waterDropletFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern water droplet C contract passed");return 0;}
