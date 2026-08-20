#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
struct output { float x, y, z, sx, sy, vy, fvel; int32_t angle, timer, yaw; int intangible, del, spawn, sound; };
static uint64_t h8(uint64_t h, uint64_t v) { for (unsigned i=0;i<8;i++){h^=(v>>(i*8u))&UINT64_C(0xff);h*=FNV_PRIME;} return h; }
static uint64_t hf(uint64_t h, float v) { uint32_t b=0; memcpy(&b,&v,sizeof(b)); return h8(h,b); }
static struct output update(float x,float y,float z,int32_t angle,int32_t timer,float fvel,float mx,float water,int interacted) {
    struct output o = {x,y,z,4,4,0,fvel,angle+0x400,timer+1,0,timer<30,0,0,0};
    float sine=(float)sin((double)(int16_t)angle*3.14159265358979323846/32768.0);
    o.sx=sine*0.5f+4;o.sy=-sine*0.5f+4;
    if(o.intangible)o.y+=3; else {o.fvel=o.fvel>=2?2:o.fvel+10;o.y+=0;o.x+=o.fvel;}
    if(interacted||timer>200){o.del=1;o.spawn=30;o.sound=1;}
    if(o.y>water)o.del=1;
    return o;
}
int main(void){
    const struct output o[]={update(0,0,0,0,0,0,0,100,0),update(0,95,0,0,30,0,10,100,0),update(0,0,0,0x8000,201,0,0,100,1)};
    if(o[0].y!=3||o[0].sx!=4||o[0].sy!=4||!o[0].intangible||o[0].del||o[1].x!=10||o[1].fvel!=10||o[1].intangible||o[1].del||o[2].sx!=4.0f||o[2].sy!=4.0f||!o[2].del||o[2].spawn!=30||!o[2].sound)return 1;
    uint64_t h=FNV_OFFSET;for(unsigned i=0;i<3;i++){h=hf(h,o[i].x);h=hf(h,o[i].y);h=hf(h,o[i].z);h=hf(h,o[i].sx);h=hf(h,o[i].sy);h=h8(h,(uint64_t)(int64_t)o[i].angle);h=h8(h,(uint64_t)(int64_t)o[i].timer);h=hf(h,o[i].fvel);h=h8(h,(uint64_t)(int64_t)o[i].yaw);h=h8(h,o[i].intangible);h=h8(h,o[i].del);h=h8(h,(uint64_t)o[i].spawn);h=h8(h,o[i].sound);}
    printf("waterAirBubbleFingerprint=0x%016llx\n",(unsigned long long)h);puts("SM64 Modern water-air bubble C contract passed");return 0;
}
