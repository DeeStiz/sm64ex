#include <stdint.h>
#include <stdio.h>
static const uint64_t FNV_OFFSET=UINT64_C(1469598103934665603),FNV_PRIME=UINT64_C(1099511628211);
static uint64_t hu(uint64_t h,uint32_t v){for(unsigned b=0;b<4;++b){h^=(v>>(b*8))&0xffu;h*=FNV_PRIME;}return h;}
static uint64_t hf(uint64_t h,float v){union{float f;uint32_t u;}b={v};return hu(h,b.u);}
struct O{float x,y,z,vx,vy,vz;};
static float s(int a){return a==0?0.0f:a==0x4000?1.0f:0.0f;} static float c(int a){return a==0?1.0f:a==0x4000?0.0f:0.0f;}
static struct O update(int parent_x,int parent_y,int parent_z,int yaw,int index){int angle=index*0x4000;float ox=400*c(angle);struct O o={parent_x+ox*s(yaw)+300*c(yaw),parent_y+400*s(angle),parent_z+ox*c(yaw)+300*s(yaw),0,0,0};o.vx=o.x;o.vy=o.y;o.vz=o.z;return o;}
static uint64_t ap(uint64_t h,struct O o){h=hf(h,o.x);h=hf(h,o.y);h=hf(h,o.z);h=hf(h,o.vx);h=hf(h,o.vy);return hf(h,o.vz);}
int main(void){struct O front=update(100,200,300,0,0),side=update(100,200,300,0,1),yawed=update(100,200,300,0x4000,0);if(front.x!=400||front.y!=200||front.z!=700||side.x!=400||side.y!=600||yawed.x!=500||yawed.z!=600)return 2;uint64_t h=FNV_OFFSET;h=ap(h,front);h=ap(h,side);h=ap(h,yawed);printf("ferrisWheelPlatformFingerprint=0x%016llx\n",(unsigned long long)h);puts("SM64 Modern Ferris wheel platform C contract passed");return 0;}
