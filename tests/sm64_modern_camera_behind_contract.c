#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
static uint64_t h8(uint64_t h, uint8_t v) { h ^= v; return h * FNV_PRIME; }
static uint64_t h16(uint64_t h, uint16_t v) { for (unsigned i = 0; i < 2; ++i) h = h8(h, (uint8_t)(v >> (i * 8u))); return h; }
static uint64_t h32(uint64_t h, uint32_t v) { for (unsigned i = 0; i < 4; ++i) h = h8(h, (uint8_t)(v >> (i * 8u))); return h; }
static uint64_t hf(uint64_t h, float value) { uint32_t bits; memcpy(&bits, &value, sizeof(bits)); return h32(h, bits); }
static uint64_t hi16(uint64_t h, int16_t value) { return h16(h, (uint16_t)value); }

typedef struct {
    float distance, max_distance, focus_y;
    int16_t pitch, yaw, side_yaw, sound_timer, yaw_speed, pitch_inc;
    int16_t goal_pitch, goal_yaw_offset;
    int played_sound;
} Result;

static int16_t approach_s16_asym(int16_t current, int16_t target, int16_t divisor) {
    int32_t value = current;
    if (divisor == 0) return target;
    value -= target;
    value -= value / divisor;
    value += target;
    return (int16_t)value;
}

static int16_t approach_s16_sym(int16_t current, int16_t target, int16_t increment) {
    int32_t step = increment < 0 ? -(int32_t)increment : increment;
    int32_t distance = (int32_t)target - current;
    if (distance > 0) {
        distance -= step;
        return (int16_t)(distance >= 0 ? target - distance : target);
    }
    distance += step;
    return (int16_t)(distance <= 0 ? target - distance : target);
}

static float approach_f32_sym(float current, float target, float increment) {
    float step = increment < 0 ? -increment : increment;
    float distance = target - current;
    if (distance > 0) {
        distance -= step;
        return distance > 0 ? target - distance : target;
    }
    distance += step;
    return distance < 0 ? target - distance : target;
}

static Result update(float distance, int16_t pitch, int16_t yaw, int16_t face_pitch,
                     int16_t mario_yaw, int mario_mode, int water_metal,
                     uint16_t c_buttons, int16_t side_yaw, int16_t sound_timer) {
    Result result;
    result.distance = distance;
    result.max_distance = mario_mode ? 350.0f : 800.0f;
    result.focus_y = mario_mode ? 120.0f : 125.0f;
    result.goal_pitch = (int16_t)(-face_pitch);
    result.goal_yaw_offset = 0;
    result.pitch_inc = water_metal ? 32 : 128;
    result.side_yaw = side_yaw;
    result.sound_timer = sound_timer;
    result.played_sound = 0;
    if (result.distance > result.max_distance) result.distance = result.max_distance;
    int32_t abs_pitch = pitch < 0 ? -(int32_t)pitch : pitch;
    result.yaw_speed = (int16_t)(32 - abs_pitch / 0x200);
    if (result.yaw_speed < 1) result.yaw_speed = 1;
    if (result.yaw_speed > 32) result.yaw_speed = 32;
    if (result.side_yaw != 0) {
        result.side_yaw = approach_s16_sym(result.side_yaw, 0, 1);
        result.yaw_speed = 8;
    }
    if (result.sound_timer != 0) {
        result.goal_pitch = 0;
        result.sound_timer = approach_s16_sym(result.sound_timer, 0, 1);
        result.pitch_inc = 0x800;
    }
    if (c_buttons & 0x0002) {
        if (result.distance < result.max_distance) result.distance = approach_f32_sym(result.distance, result.max_distance, 5);
        result.goal_yaw_offset = (int16_t)-0x3FF8; result.side_yaw = 30; result.yaw_speed = 2; result.played_sound = 1;
    }
    if (c_buttons & 0x0001) {
        if (result.distance < result.max_distance) result.distance = approach_f32_sym(result.distance, result.max_distance, 5);
        result.goal_yaw_offset = (int16_t)0x3FF8; result.side_yaw = 30; result.yaw_speed = 2; result.played_sound = 1;
    }
    if (c_buttons & 0x0004) {
        if (result.distance < result.max_distance) result.distance = approach_f32_sym(result.distance, result.max_distance, 5);
        result.goal_pitch = (int16_t)-0x3000; result.sound_timer = 30; result.pitch_inc = 0x800; result.played_sound = 1;
    }
    if (c_buttons & 0x0008) {
        if (result.distance < result.max_distance) result.distance = approach_f32_sym(result.distance, result.max_distance, 5);
        result.goal_pitch = (int16_t)0x3000; result.sound_timer = 30; result.pitch_inc = 0x800; result.played_sound = 1;
    }
    int16_t target_yaw = (int16_t)((int32_t)mario_yaw + result.goal_yaw_offset);
    result.yaw = approach_s16_asym(yaw, target_yaw, result.yaw_speed);
    result.pitch = approach_s16_sym(pitch, result.goal_pitch, result.pitch_inc);
    if (result.distance < 300.0f) result.distance = 300.0f;
    return result;
}

static uint64_t hash_result(uint64_t h, Result result) {
    h = hf(h, result.distance); h = hi16(h, result.pitch); h = hi16(h, result.yaw);
    h = hf(h, result.max_distance); h = hf(h, result.focus_y);
    h = hi16(h, result.side_yaw); h = hi16(h, result.sound_timer);
    h = hi16(h, result.yaw_speed); h = hi16(h, result.pitch_inc);
    h = hi16(h, result.goal_pitch); h = hi16(h, result.goal_yaw_offset);
    return h8(h, (uint8_t)(result.played_sound != 0));
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_result(fingerprint, update(900, 0x1000, 0x2000, -0x0800, 0x4000, 0, 0, 0, 0, 0));
    fingerprint = hash_result(fingerprint, update(300, 0, 0, 0, 0x4000, 0, 0, 0x0002, 0, 0));
    fingerprint = hash_result(fingerprint, update(340, -0x100, 0x0100, 0x100, 0, 1, 1, 0x0008, 4, 3));
    printf("cameraBehindFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    return 0;
}
