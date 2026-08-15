#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)
#define CUTSCENE_STOP ((int16_t)0x8000)

static uint64_t h8(uint64_t h, uint8_t value) { h ^= value; return h * FNV_PRIME; }
static uint64_t h16(uint64_t h, uint16_t value) {
    for (unsigned i = 0; i < 2; ++i) h = h8(h, (uint8_t)(value >> (i * 8u)));
    return h;
}
static uint64_t h32(uint64_t h, uint32_t value) {
    for (unsigned i = 0; i < 4; ++i) h = h8(h, (uint8_t)(value >> (i * 8u)));
    return h;
}
static uint64_t hf(uint64_t h, float value) { uint32_t bits; memcpy(&bits, &value, sizeof(bits)); return h32(h, bits); }
static uint64_t hi16(uint64_t h, int16_t value) { return h16(h, (uint16_t)value); }

typedef struct { float x, y, z; } Vec3;
typedef struct { int8_t index; uint8_t speed; Vec3 point; } SplinePoint;
typedef struct { int16_t segment; float progress; } SplineState;
typedef struct { Vec3 point; SplineState state; uint8_t finished; } SplineResult;
typedef struct { int16_t cutscene, shot, timer; } ClockState;
typedef struct { ClockState state; uint8_t stopped, advanced_shot; } ClockResult;
typedef struct {
    int16_t mode;
    float fov, fov_offset, amplitude;
    int16_t phase, speed, decay;
} FovState;
typedef struct { FovState state; float presented; } FovResult;

static Vec3 spline_eval(float u, Vec3 a0, Vec3 a1, Vec3 a2, Vec3 a3) {
    float one_minus_u = 1.f - u;
    float b0 = one_minus_u * one_minus_u * one_minus_u / 6.f;
    float b1 = u * u * u / 2.f - u * u + 0.6666667f;
    float b2 = -u * u * u / 2.f + u * u / 2.f + u / 2.f + 0.16666667f;
    float b3 = u * u * u / 6.f;
    return (Vec3){
        b0 * a0.x + b1 * a1.x + b2 * a2.x + b3 * a3.x,
        b0 * a0.y + b1 * a1.y + b2 * a2.y + b3 * a3.y,
        b0 * a0.z + b1 * a1.z + b2 * a2.z + b3 * a3.z,
    };
}

static SplineResult move_spline(const SplinePoint *points, size_t count, SplineState state) {
    int segment = state.segment;
    float progress = state.progress;
    if (segment < 0) { segment = 0; progress = 0.f; }
    if (points[segment].index == -1 || points[segment + 1].index == -1 || points[segment + 2].index == -1) {
        return (SplineResult){ points[segment].point, { (int16_t)segment, progress }, 1 };
    }
    Vec3 point = spline_eval(progress, points[segment].point, points[segment + 1].point,
                             points[segment + 2].point, points[segment + 3].point);
    float first = points[segment + 1].speed == 0 ? 0.f : 1.f / points[segment + 1].speed;
    float second = points[segment + 2].speed == 0 ? 0.f : 1.f / points[segment + 2].speed;
    progress += (second - first) * progress + first;
    uint8_t finished = 0;
    if (progress >= 1.f) {
        segment++;
        if (points[segment + 3].index == -1) { segment = 0; finished = 1; }
        progress -= 1.f;
    }
    return (SplineResult){ point, { (int16_t)segment, progress }, finished };
}

static ClockResult advance_clock(ClockState state, int16_t duration, int active) {
    ClockState next = state;
    uint8_t advanced = 0;
    uint16_t timer_bits = (uint16_t)state.timer;
    if (active && duration != 0 && (timer_bits & 0x8000u) == 0) {
        if (state.timer < 0x3FFF) next.timer = (int16_t)(state.timer + 1);
        if (next.timer == duration) { next.shot = (int16_t)(state.shot + 1); next.timer = 0; advanced = 1; }
    } else {
        next.shot = 0; next.timer = 0;
    }
    return (ClockResult){ next, (uint8_t)(!active || duration == 0 || (timer_bits & 0x8000u) != 0), advanced };
}

static float approach_sym(float current, float target, float increment) {
    float step = increment < 0.f ? -increment : increment;
    float distance = target - current;
    if (distance > 0.f) { distance -= step; return distance > 0.f ? target - distance : target; }
    distance += step;
    return distance < 0.f ? target - distance : target;
}

static float approach_asym(float current, float target, float increment) {
    if (current < target) return current + increment < target ? current + increment : target;
    return current - increment > target ? current - increment : target;
}

static FovState request_shake(FovState state, int16_t amplitude, int16_t decay, int16_t speed) {
    if (amplitude > 0 && (float)amplitude > state.amplitude) {
        state.amplitude = (float)amplitude; state.decay = decay; state.speed = speed;
    }
    return state;
}

static FovResult update_fov(FovState state, int sleeping, int fixed, int cutscene) {
    float fov = state.fov;
    switch (state.mode) {
        case 1: fov = 45.f; break;
        case 2: { float target = sleeping ? 30.f : 45.f; fov = approach_sym(fov, target, (target - fov) / 30.f); break; }
        case 4: fov = approach_asym(fov, 45.f, 2.f); break;
        case 5: fov = 30.f; break;
        case 6: fov = approach_sym(fov, 20.f, .3f); break;
        case 7: fov = approach_asym(fov, fixed && !cutscene ? 60.f : 45.f, 2.f); break;
        case 9: fov = approach_sym(fov, 80.f, 3.5f); break;
        case 10: fov = approach_sym(fov, 30.f, 1.f); break;
        case 11: fov = approach_sym(fov, 60.f, 1.f); break;
        case 12: fov = approach_sym(fov, 30.f, (30.f - fov) / 60.f); break;
        case 13: fov = 29.f; break;
        default: break;
    }
    float offset = state.fov_offset;
    int16_t phase = state.phase;
    float amplitude = state.amplitude;
    if (amplitude != 0.f) {
        offset = amplitude / 256.f;
        phase = (int16_t)((uint16_t)phase + (uint16_t)state.speed);
        amplitude = approach_sym(amplitude, 0.f, state.decay < 0 ? -(float)state.decay : (float)state.decay);
        if (amplitude == 0.f) phase = 0;
    } else {
        phase = 0;
    }
    FovState next = { state.mode, fov, offset, amplitude, phase, state.speed, state.decay };
    return (FovResult){ next, fov + offset };
}

static uint64_t hash_vec(uint64_t h, Vec3 v) { h = hf(h, v.x); h = hf(h, v.y); return hf(h, v.z); }
static uint64_t hash_spline(uint64_t h, SplineResult result) {
    h = hash_vec(h, result.point); h = hi16(h, result.state.segment); h = hf(h, result.state.progress); return h8(h, result.finished);
}
static uint64_t hash_clock(uint64_t h, ClockResult result) {
    h = hi16(h, result.state.cutscene); h = hi16(h, result.state.shot); h = hi16(h, result.state.timer); h = h8(h, result.stopped); return h8(h, result.advanced_shot);
}
static uint64_t hash_fov(uint64_t h, FovResult result) {
    h = hi16(h, result.state.mode); h = hf(h, result.state.fov); h = hf(h, result.state.fov_offset); h = hf(h, result.state.amplitude);
    h = hi16(h, result.state.phase); h = hi16(h, result.state.speed); h = hi16(h, result.state.decay); return hf(h, result.presented);
}

int main(void) {
    SplinePoint points[] = {
        { 0, 0, { -100.f, -50.f, -200.f } },
        { 1, 4, { 0.f, 0.f, 0.f } },
        { 2, 2, { 100.f, 50.f, 200.f } },
        { 3, 1, { 200.f, 100.f, 400.f } },
        { -1, 0, { 300.f, 150.f, 600.f } },
    };
    uint64_t fingerprint = FNV_OFFSET;
    fingerprint = hash_spline(fingerprint, move_spline(points, 5, (SplineState){ 0, .25f }));
    SplinePoint finish_points[] = {
        { 0, 0, { 0.f, 0.f, 0.f } }, { 1, 1, { 0.f, 0.f, 0.f } },
        { 2, 1, { 0.f, 0.f, 0.f } }, { 3, 1, { 0.f, 0.f, 0.f } },
        { -1, 0, { 0.f, 0.f, 0.f } }
    };
    SplineResult wrapped = move_spline(finish_points, 5, (SplineState){ 0, 0.f });
    fingerprint = hash_spline(fingerprint, wrapped);
    fingerprint = hash_clock(fingerprint, advance_clock((ClockState){ 3, 2, 2 }, 3, 1));
    fingerprint = hash_clock(fingerprint, advance_clock((ClockState){ 3, 2, CUTSCENE_STOP }, 30, 1));
    FovState base = { 1, 40.f, 0.f, 0.f, 0, 0, 0 };
    fingerprint = hash_fov(fingerprint, update_fov(base, 0, 0, 0));
    FovState shaken = request_shake(update_fov(base, 0, 0, 0).state, 0x100, 0x30, (int16_t)0x8000);
    fingerprint = hash_fov(fingerprint, update_fov(shaken, 0, 0, 0));
    fingerprint = hash_fov(fingerprint, update_fov((FovState){ 2, 45.f, 0.f, 0.f, 0, 0, 0 }, 1, 0, 0));
    fingerprint = hash_fov(fingerprint, update_fov((FovState){ 7, 45.f, 0.f, 0.f, 0, 0, 0 }, 0, 1, 0));
    printf("cameraCutsceneFOVFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    return 0;
}
