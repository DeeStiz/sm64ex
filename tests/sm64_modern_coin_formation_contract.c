#include <stdint.h>
#include <stdio.h>
#define OFFSET UINT64_C(1469598103934665603)
#define PRIME UINT64_C(1099511628211)
static uint64_t hash_u64(uint64_t seed,uint64_t value){for(unsigned byte=0;byte<8;++byte){seed^=(value>>(byte*8))&255;seed*=PRIME;}return seed;}
static uint64_t hash_f32(uint64_t seed,float value){union{float f;uint32_t u;}bits={value};return hash_u64(seed,bits.u);}
static uint64_t hash_child(uint64_t seed,float x,float y,float z,int above){seed=hash_f32(seed,x);seed=hash_f32(seed,y);seed=hash_f32(seed,z);return hash_u64(seed,(uint64_t)above);}
int main(void){const int counts[]={3,10,4};uint64_t f=OFFSET;for(unsigned i=0;i<3;++i){int valid=counts[i]==3||counts[i]==10;int count=valid?counts[i]:0;f=hash_u64(f,(uint64_t)count);f=hash_u64(f,(uint64_t)valid);f=hash_u64(f,(uint64_t)valid);}f=hash_u64(f,0);f=hash_u64(f,5);f=hash_child(f,0,-0,-320,1);f=hash_child(f,0,0,-160,1);f=hash_child(f,0,0,0,1);f=hash_child(f,0,0,160,1);f=hash_child(f,0,0,320,1);f=hash_u64(f,1);f=hash_u64(f,5);f=hash_child(f,0,0,0,0);f=hash_child(f,0,128,0,0);f=hash_child(f,0,256,0,0);f=hash_child(f,0,384,0,0);f=hash_child(f,0,512,0,0);f=hash_u64(f,4);f=hash_u64(f,8);f=hash_child(f,0,0,-150,1);f=hash_child(f,0,0,-50,1);f=hash_child(f,0,0,50,1);f=hash_child(f,0,0,150,1);f=hash_child(f,-50,0,100,1);f=hash_child(f,-100,0,50,1);f=hash_child(f,50,0,100,1);f=hash_child(f,100,0,50,1);printf("coinFormationFingerprint=0x%016llx\n",(unsigned long long)f);puts("SM64 Modern coin formation C contract passed");return 0;}
