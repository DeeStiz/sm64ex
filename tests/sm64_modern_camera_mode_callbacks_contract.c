#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t h8(uint64_t h, uint8_t value) {
    h ^= value;
    return h * FNV_PRIME;
}

static uint64_t h16(uint64_t h, uint16_t value) {
    for (unsigned index = 0; index < 2; ++index) {
        h = h8(h, (uint8_t)(value >> (index * 8u)));
    }
    return h;
}

static uint64_t h32(uint64_t h, uint32_t value) {
    for (unsigned index = 0; index < 4; ++index) {
        h = h8(h, (uint8_t)(value >> (index * 8u)));
    }
    return h;
}

static uint64_t hf(uint64_t h, float value) {
    uint32_t bits;
    memcpy(&bits, &value, sizeof(bits));
    return h32(h, bits);
}

static uint64_t hi16(uint64_t h, int16_t value) {
    return h16(h, (uint16_t)value);
}

typedef struct {
    int16_t raw_mode;
    uint8_t callback;
    uint8_t pure;
    uint8_t owner_thread;
    uint8_t swapped;
    float distance;
    float position_y;
    float focus_y;
    int16_t pitch;
    uint8_t returns_mario_yaw;
    uint8_t pans_ahead;
} Descriptor;

typedef struct {
    int16_t camera_yaw;
    int16_t returned_yaw;
    int16_t area_yaw;
    int16_t pitch;
    float distance;
    uint8_t swapped;
    uint8_t pans_ahead;
} Result;

static const Descriptor descriptors[] = {
    { 0, 0, 0, 0, 0, 0.f, 0.f, 0.f, 0, 0, 0 },
    { 1, 1, 1, 1, 0, 1000.f, 125.f, 125.f, 0x05B0, 0, 1 },
    { 2, 2, 1, 1, 0, 1000.f, 125.f, 125.f, 0x05B0, 0, 1 },
    { 3, 3, 0, 1, 0, 800.f, 125.f, 125.f, 0x05B0, 0, 1 },
    { 4, 4, 1, 1, 0, 800.f, 125.f, 125.f, 0x05B0, 1, 1 },
    { 5, 0, 0, 0, 0, 0.f, 0.f, 0.f, 0, 0, 0 },
    { 6, 5, 0, 1, 0, 250.f, 125.f, 125.f, 0, 1, 0 },
    { 7, 4, 1, 1, 0, 800.f, 125.f, 125.f, 0x05B0, 1, 1 },
    { 8, 6, 0, 1, 0, 800.f, 125.f, 125.f, 0x05B0, 0, 1 },
    { 9, 7, 1, 1, 0, 800.f, 125.f, 125.f, 0x1555, 1, 0 },
    { 10, 8, 1, 1, 1, 800.f, 125.f, 125.f, 0, 1, 0 },
    { 11, 9, 0, 1, 0, 0.f, 0.f, 0.f, 0, 0, 0 },
    { 12, 10, 0, 1, 0, 0.f, 0.f, 0.f, 0, 0, 0 },
    { 13, 11, 0, 1, 0, 0.f, 0.f, 0.f, 0, 0, 1 },
    { 14, 12, 1, 1, 0, 1000.f, 125.f, 125.f, 0x05B0, 0, 1 },
    { 15, 7, 1, 1, 0, 800.f, 125.f, 125.f, 0x1555, 1, 0 },
    { 16, 4, 1, 1, 0, 800.f, 125.f, 125.f, 0x05B0, 1, 1 },
    { 17, 13, 0, 1, 0, 0.f, 0.f, 0.f, 0, 0, 0 },
    { 18, 0, 0, 0, 0, 0.f, 0.f, 0.f, 0, 0, 0 },
};

static uint64_t hash_descriptor(uint64_t h, Descriptor descriptor) {
    h = hi16(h, descriptor.raw_mode);
    h = h8(h, descriptor.callback);
    h = h8(h, descriptor.pure);
    h = h8(h, descriptor.owner_thread);
    h = h8(h, descriptor.swapped);
    h = hf(h, descriptor.distance);
    h = hf(h, descriptor.position_y);
    h = hf(h, descriptor.focus_y);
    h = hi16(h, descriptor.pitch);
    h = h8(h, descriptor.returns_mario_yaw);
    return h8(h, descriptor.pans_ahead);
}

static uint64_t hash_result(uint64_t h, Result result) {
    h = hi16(h, result.camera_yaw);
    h = hi16(h, result.returned_yaw);
    h = hi16(h, result.area_yaw);
    h = hi16(h, result.pitch);
    h = hf(h, result.distance);
    h = h8(h, result.swapped);
    return h8(h, result.pans_ahead);
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    for (size_t index = 0; index < sizeof(descriptors) / sizeof(descriptors[0]); ++index) {
        fingerprint = hash_descriptor(fingerprint, descriptors[index]);
    }

    fingerprint = hash_result(fingerprint, (Result){
        0x4100, 0x4100, 0x4000, 0x05B0, 1025.f, 0, 1
    });
    fingerprint = hash_result(fingerprint, (Result){
        (int16_t)0xC100, (int16_t)0xC100, 0x4000, 0x05B0, 1025.f, 0, 1
    });
    fingerprint = hash_result(fingerprint, (Result){
        0x3000, 0x3000, 0x3000, 0x05B0, 1005.f, 0, 1
    });
    fingerprint = hash_result(fingerprint, (Result){
        (int16_t)0xE000, 0x6000, (int16_t)0xE000, 0x05B0, 700.f, 0, 1
    });
    fingerprint = hash_result(fingerprint, (Result){
        (int16_t)0xD100, 0x5000, (int16_t)0xD100, 0x1555, 800.f, 0, 0
    });
    fingerprint = hash_result(fingerprint, (Result){
        0x6000, 0x6000, 0x6000, (int16_t)0xF000, 800.f, 1, 0
    });

    printf("cameraModeCallbacksFingerprint=0x%016llx\n",
           (unsigned long long)fingerprint);
    return 0;
}
