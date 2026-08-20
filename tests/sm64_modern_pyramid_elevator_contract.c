#include <stdint.h>
#include <stdio.h>
#include <string.h>
#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
// Four focused state vectors mirror PyramidElevatorBehavior; sine values are
// only exercised at 0x8000 where the canonical table is exactly zero.
struct O { int32_t action; float y,vel; int marker; };
static uint64_t h32(uint64_t h,uint32_t v){for(unsigned b=0;b<4;++b){h^=(v>>(8*b))&255u;h*=FNV_PRIME;}return h;}
static uint32_t bits(float v){uint32_t b;memcpy(&b,&v,4);return b;}
static struct O update(int32_t a,int32_t timer,float y,float home,float vel,int mario){if(a==0&&mario)a=1;else if(a==1&&timer==8)a=2;else if(a==2){vel=-10;y+=vel;if(y<128){y=128;a=3;}}else if(a==3&&timer>=8){y=128;vel=0;}return (struct O){a,y,vel,a==0};}
static void append(uint64_t *h,struct O o){*h=h32(*h,(uint32_t)o.action);*h=h32(*h,bits(o.y));*h=h32(*h,bits(o.vel));*h=h32(*h,(uint32_t)o.marker);}
int main(void){struct O a=update(0,0,4600,4600,0,1),b=update(1,8,4600,4600,0,0),c=update(2,0,130,4600,0,0),d=update(3,8,128,4600,-10,0);uint64_t h=FNV_OFFSET;append(&h,a);append(&h,b);append(&h,c);append(&h,d);printf("pyramidElevatorFingerprint=0x%016llx\n",(unsigned long long)h);printf("SM64 Modern pyramid elevator C contract matched\n");return a.action==1&&b.action==2&&c.y==128&&d.vel==0?0:1;}
