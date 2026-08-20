#include <stdint.h>
#include <stdio.h>
#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
struct Output { float speed,target; int16_t velocity,face; };
static uint64_t h32(uint64_t h,uint32_t v){for(unsigned b=0;b<4;++b){h^=(v>>(8*b))&255u;h*=FNV_PRIME;}return h;}
static uint32_t bits(float v){uint32_t b;__builtin_memcpy(&b,&v,4);return b;}
static float approach(float v,float t){float step=v>t?-50.0f:50.0f;float n=v+step;return (n-t)*step>=0?t:n;}
static struct Output update(int32_t setting,int32_t dir,float speed,float target,int16_t face,float randomTarget,int reached){
    if(setting==0)speed=200;if(setting==1)speed=400;else if(setting==2){if(reached)target=randomTarget;else speed=approach(speed,target);}int16_t vel=(int16_t)((int32_t)speed*dir);return (struct Output){speed,target,vel,(int16_t)((uint16_t)face+(uint16_t)vel)};
}
static void append(uint64_t *h,struct Output o){*h=h32(*h,bits(o.speed));*h=h32(*h,bits(o.target));*h=h32(*h,(uint16_t)o.velocity);*h=h32(*h,(uint16_t)o.face);}
int main(void){struct Output a=update(0,1,0,0,0,0,0),b=update(1,-1,0,0,0x1000,0,0),c=update(2,1,0,200,0,-400,0),d=update(2,-1,200,200,0,-400,1),e=update(3,1,400,0,0,0,0);uint64_t h=FNV_OFFSET;append(&h,a);append(&h,b);append(&h,c);append(&h,d);append(&h,e);printf("ttcCogFingerprint=0x%016llx\n",(unsigned long long)h);printf("SM64 Modern TTC cog C contract matched\n");return a.speed==200&&b.velocity==-400&&c.speed==50&&d.target==-400&&e.speed==400?0:1;}
