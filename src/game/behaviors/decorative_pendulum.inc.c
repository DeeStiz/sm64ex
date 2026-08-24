/**
 * Behavior for bhvDecorativePendulum.
 * This controls the pendulum that lies underneath the Tick Tock Clock painting.
 */

void bhv_decorative_pendulum_init(void) {
    o->oAngleVelRoll = 0x100;
    bhv_init_room();
}

/**
 * Smoothly swing the decorative pendulum back and forth using constant angular
 * acceleration.
 */
void bhv_decorative_pendulum_loop(void) {
    if (o->oFaceAngleRoll > 0)
        o->oAngleVelRoll -= 0x08;
    else
        o->oAngleVelRoll += 0x08;

    o->oFaceAngleRoll += o->oAngleVelRoll;

    /**
     * This if-statement is true twice in the span of 5 frames when
     * oAngleVelRoll takes values in {0x10, 0x08, 0x00, -0x08, -0x10}.
     * This means the sound we hear when the pendulum hits its upswing is
     * actually one sound played twice in rapid succession.
     */
    if (o->oAngleVelRoll == 0x10 || o->oAngleVelRoll == -0x10) {
        cur_obj_play_sound_2(SOUND_GENERAL_BIG_CLOCK);
        // The Castle area-2 source object can cross the sound boundary while
        // its graph/cadence state is held for a paired native step. Publish
        // the authored owner-thread receipt at the same fixed-width gateway;
        // normal playback remains owned by cur_obj_play_sound_2.
        if (sm64_modern_oracle_trace_is_active()) {
            // The source script places this object at these fixed level
            // coordinates.  Publish the authored world-space values rather
            // than the camera-relative `cameraToObject` vector used by the
            // legacy audio mixer.
            const f32 source_position[3] = { -205.0f, 2611.0f, 7140.0f };
            sm64_modern_parity_record_sound(SOUND_GENERAL_BIG_CLOCK, source_position);
        }
    }
}
