#include <stdint.h>
#include <stdio.h>

static const uint64_t FNV_OFFSET = UINT64_C(1469598103934665603);
static const uint64_t FNV_PRIME = UINT64_C(1099511628211);
static uint64_t hash_u32(uint64_t h, uint32_t v) { for (unsigned b=0;b<4;++b) { h ^= (v>>(b*8))&0xffu; h*=FNV_PRIME; } return h; }
static uint64_t hash_f32(uint64_t h, float v) { union { float f; uint32_t u; } b={v}; return hash_u32(h,b.u); }
struct Output { int32_t action,timer,seq,move_yaw,vertical,rotation,endpoint; float x,y,z,forward,vx,vz,base; };
static float sine(int32_t a){return a==0?0.0f:(a==0x400?0.098017141f:(a>=0x4000?1.0f:0.0f));}
static struct Output update(int mode,int action,int timer,int seq,float x,float y,float z,float home,float forward,int yaw,int vertical,int rotation,float base,int mario){
    struct Output o={action,timer,seq,yaw,vertical,rotation,0,x,y,z,forward,0,0,base};
    if(action==0){o.seq=0;o.action=1;}else{
        int cmd,dur,next; float target,step;
        if(mode==0){static const int c[]={2,1,1,2,1,1,3},d[]={30,220,30,30,220,30,0},n[]={4,8,12,16,20,24,0};static const float t[]={0,9,0,0,9,0,0},s[]={0,.3f,-.3f,0,.3f,-.3f,0};int k=o.seq/4;cmd=c[k];dur=d[k];next=n[k];target=t[k];step=s[k];}
        else {static const int c[]={4,1,1,2,1,1,3},d[]={0,475,30,30,475,30,0},n[]={4,8,12,16,20,24,0};static const float t[]={0,9,0,0,9,0,0},s[]={0,.3f,-.3f,0,.3f,-.3f,0};int k=o.seq/4;cmd=c[k];dur=d[k];next=n[k];target=t[k];step=s[k];}
        if(cmd==4){o.move_yaw=0;o.forward=0;if(mario){o.seq=next;o.timer=0;}}
        else if(cmd==2){o.forward=target;o.move_yaw=(mode==0&&o.seq==0)?0x4000:(mode==0&&o.seq==12)?-0x4000:(mode==1&&o.seq==12)?0x8000:0;if(timer>dur){o.seq=next;o.timer=0;}}
        else if(cmd==1){o.forward+=step;if(step>=0&&o.forward>target)o.forward=target;if(step<0&&o.forward<target)o.forward=target;if(timer>dur){o.seq=next;o.timer=0;}}
        else{o.forward=0;o.seq=0;}
    }
    o.vx=o.forward*(o.move_yaw==0x4000?1.0f:o.move_yaw==-0x4000?-1.0f:0.0f);o.vz=o.forward*(o.move_yaw==0?1.0f:0.0f);o.x+=o.vx;o.z+=o.vz;
    if(mario){o.vertical+=0x400;if(o.vertical>0x4000)o.vertical=0x4000;}else{o.vertical-=0x400;if(o.vertical<0)o.vertical=0;}
    float off=sine(o.vertical)*-80.0f;o.endpoint=o.vertical==0||o.vertical==0x4000;if(o.endpoint){o.rotation+=0x800;o.base-=sine(o.rotation)*2.0f;}o.y=home+o.base+off;return o;
}
static uint64_t append(uint64_t h,struct Output o){h=hash_u32(h,(uint32_t)o.action);h=hash_u32(h,(uint32_t)o.timer);h=hash_u32(h,(uint32_t)o.seq);h=hash_f32(h,o.x);h=hash_f32(h,o.y);h=hash_f32(h,o.z);h=hash_f32(h,o.forward);h=hash_u32(h,(uint32_t)o.move_yaw);h=hash_f32(h,o.vx);h=hash_f32(h,o.vz);h=hash_u32(h,(uint32_t)o.vertical);h=hash_u32(h,(uint32_t)o.rotation);h=hash_f32(h,o.base);return hash_u32(h,(uint32_t)o.endpoint);}
int main(void){struct Output first=update(0,0,0,0,0,50,0,100,0,0x4000,0,-0x800,0,0),wait=update(0,1,31,0,0,100,0,100,0,0,0,-0x800,0,0),acc=update(0,1,0,4,0,100,0,100,0,0x4000,0,-0x800,0,0),hold=update(1,1,0,0,0,100,0,100,0,0,0,-0x800,0,0),start=update(1,1,0,0,0,100,0,100,0,0,0,-0x800,0,1),top=update(1,1,0,4,0,100,0,100,0,0,0x4000,-0x800,0,1);if(first.action!=1||wait.seq!=4||acc.forward!=.3f||acc.x!=.3f||hold.seq!=0||start.seq!=4||top.y!=20||top.forward!=.3f)return 2;uint64_t h=FNV_OFFSET;h=append(h,first);h=append(h,wait);h=append(h,acc);h=append(h,hold);h=append(h,start);h=append(h,top);printf("lllMovingOctagonalMeshFingerprint=0x%016llx\n",(unsigned long long)h);puts("SM64 Modern LLL moving octagonal mesh C contract passed");return 0;}
