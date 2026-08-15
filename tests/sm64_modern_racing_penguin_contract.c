#include <stdint.h>
#include <stdio.h>

enum {
    WAIT_FOR_MARIO = 0,
    SHOW_INIT_TEXT = 1,
    PREPARE_FOR_RACE = 2,
    RACE = 3,
    FINISH_RACE = 4,
    SHOW_FINAL_TEXT = 5,
    PATH_REACHED_END = -1,
    MOVE_LANDED = 1 << 0,
    MOVE_ON_GROUND = 1 << 1,
    MOVE_HIT_WALL = 1 << 9
};

typedef struct {
    int32_t action;
    int32_t timer;
    float positionY;
    float marioPositionY;
    int32_t initTextCooldown;
    int canActivateInitialText;
    int32_t initialDialogResponse;
    int raceBeginComplete;
    int32_t pathStatus;
    uint32_t pathWaypointFlags;
    int16_t pathTargetYaw;
    uint32_t moveFlags;
    int animationAtEnd;
    int finalAnimationAtEnd;
    int canActivateFinalText;
    int32_t finalDialogResult;
    int32_t finalTextbox;
    int marioWon;
    int marioCheated;
    float weightedTargetSpeed;
    float forwardVelocity;
    int16_t moveYaw;
    int marioInAirAction;
} Input;

typedef struct {
    int32_t action;
    int32_t initTextCooldown;
    float forwardVelocity;
    float weightedTargetSpeed;
    int16_t moveYaw;
    int16_t angleVelocityYaw;
    int32_t animation;
    float animationSpeed;
    int32_t finalTextbox;
    int marioWon;
    int marioCheated;
    int reachedBottom;
    int resetTimer;
    int setVelocityYValid;
    float setVelocityY;
    int attachRaceObjects;
    int initializePath;
    int playRoughSlideSound;
    int playWalkingSound;
    int playPoundingSound;
    int cameraShakeSmall;
    int spawnSmoke;
    int spawnStar;
    int finalDialogCompleted;
} Output;

static float approach_float(float current, float target, float increment) {
    float distance = target - current;
    if (distance >= 0.0f) {
        return distance > increment ? current + increment : target;
    }
    return distance < -increment ? current - increment : target;
}

static void approach_angle(int16_t current, int16_t target, int16_t increment,
                           int16_t *value, int16_t *delta, int *completed) {
    int16_t start = current;
    int32_t distance = (int32_t) target - (int32_t) current;
    if (distance >= 0) {
        if (distance > (int32_t) increment) {
            *value = (int16_t) (current + increment);
        } else {
            *value = target;
        }
    } else if (distance < -(int32_t) increment) {
        *value = (int16_t) (current - increment);
    } else {
        *value = target;
    }
    *delta = (int16_t) (*value - start);
    *completed = *value == target;
}

static Output update(Input input) {
    Output output = {0};
    output.action = input.action;
    output.initTextCooldown = input.initTextCooldown;
    output.forwardVelocity = input.forwardVelocity;
    output.weightedTargetSpeed = input.weightedTargetSpeed;
    output.moveYaw = input.moveYaw;
    output.animation = 0;
    output.animationSpeed = 1.0f;
    output.finalTextbox = input.finalTextbox;
    output.marioWon = input.marioWon;
    output.marioCheated = input.marioCheated;

    switch (input.action) {
        case WAIT_FOR_MARIO:
            if (input.timer > input.initTextCooldown
                && input.positionY - input.marioPositionY <= 0.0f
                && input.canActivateInitialText) {
                output.action = SHOW_INIT_TEXT;
            }
            break;

        case SHOW_INIT_TEXT:
            if (input.initialDialogResponse == 1) {
                output.attachRaceObjects = 1;
                output.initializePath = 1;
                output.action = PREPARE_FOR_RACE;
                output.setVelocityYValid = 1;
                output.setVelocityY = 60.0f;
            } else if (input.initialDialogResponse == 2) {
                output.action = WAIT_FOR_MARIO;
                output.initTextCooldown = 60;
            }
            break;

        case PREPARE_FOR_RACE: {
            if (input.raceBeginComplete) {
                output.action = RACE;
                output.forwardVelocity = 20.0f;
            }
            int completed;
            approach_angle(input.moveYaw, 0x4000, 2500,
                           &output.moveYaw, &output.angleVelocityYaw, &completed);
            (void) completed;
            break;
        }

        case RACE:
            if (input.pathStatus == PATH_REACHED_END) {
                output.reachedBottom = 1;
                output.action = FINISH_RACE;
            } else {
                float targetSpeed = input.positionY - input.marioPositionY;
                float minSpeed = 70.0f;
                output.playRoughSlideSound = 1;
                if (targetSpeed < 100.0f || (input.pathWaypointFlags & 0x00ff) >= 35) {
                    if ((input.pathWaypointFlags & 0x00ff) >= 35) {
                        minSpeed = 60.0f;
                    }
                    output.weightedTargetSpeed = approach_float(
                        input.weightedTargetSpeed, -500.0f, 100.0f);
                } else {
                    output.weightedTargetSpeed = approach_float(
                        input.weightedTargetSpeed, 1000.0f, 30.0f);
                }
                targetSpeed = 0.1f * (output.weightedTargetSpeed + targetSpeed);
                if (targetSpeed < minSpeed) targetSpeed = minSpeed;
                if (targetSpeed > 150.0f) targetSpeed = 150.0f;
                output.forwardVelocity = approach_float(
                    input.forwardVelocity, targetSpeed, 0.4f);
                output.animation = 1;
                int16_t turnIncrement = (int16_t) (15.0f * output.forwardVelocity);
                int completed;
                approach_angle(input.moveYaw, input.pathTargetYaw, turnIncrement,
                               &output.moveYaw, &output.angleVelocityYaw, &completed);
                (void) completed;
                if (input.animationAtEnd
                    && (input.moveFlags & (MOVE_LANDED | MOVE_ON_GROUND)) != 0) {
                    output.spawnSmoke = 1;
                }
            }
            if (input.marioInAirAction) {
                if (input.timer > 60) output.marioCheated = 1;
            } else {
                output.resetTimer = 1;
            }
            break;

        case FINISH_RACE:
            if (output.forwardVelocity != 0.0f) {
                if (input.timer > 5 && (input.moveFlags & MOVE_HIT_WALL) != 0) {
                    output.playPoundingSound = 1;
                    output.cameraShakeSmall = 1;
                    output.forwardVelocity = 0.0f;
                }
            } else if (input.finalAnimationAtEnd) {
                output.action = SHOW_FINAL_TEXT;
            }
            break;

        case SHOW_FINAL_TEXT:
            if (output.finalTextbox == 0) {
                int completed;
                approach_angle(input.moveYaw, 0, 200,
                               &output.moveYaw, &output.angleVelocityYaw, &completed);
                if (completed) {
                    output.animation = 3;
                    output.forwardVelocity = 0.0f;
                    if (input.canActivateFinalText) {
                        if (output.marioWon) {
                            if (output.marioCheated) {
                                output.finalTextbox = 132;
                                output.marioWon = 0;
                            } else {
                                output.finalTextbox = 56;
                            }
                        } else {
                            output.finalTextbox = 37;
                        }
                    }
                } else {
                    output.animation = 0;
                    output.playWalkingSound = 1;
                    output.forwardVelocity = 4.0f;
                }
            } else if (output.finalTextbox > 0) {
                if (input.finalDialogResult != 0) {
                    output.finalTextbox = -1;
                    output.resetTimer = 1;
                    output.finalDialogCompleted = 1;
                }
            } else if (output.marioWon) {
                output.spawnStar = 1;
                output.marioWon = 0;
            }
            break;
    }
    return output;
}

static uint64_t hash_u32(uint64_t hash, uint32_t value) {
    for (int byte = 0; byte < 4; ++byte) {
        hash ^= (uint64_t) ((value >> (byte * 8)) & 0xff);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static uint64_t hash_output(uint64_t hash, Output output) {
    hash = hash_u32(hash, (uint32_t) output.action);
    hash = hash_u32(hash, (uint32_t) output.initTextCooldown);
    union { float f; uint32_t u; } forward = { output.forwardVelocity };
    union { float f; uint32_t u; } weighted = { output.weightedTargetSpeed };
    union { float f; uint32_t u; } velocityY = { output.setVelocityY };
    hash = hash_u32(hash, forward.u);
    hash = hash_u32(hash, weighted.u);
    hash = hash_u32(hash, (uint32_t) (uint16_t) output.moveYaw);
    hash = hash_u32(hash, (uint32_t) (uint16_t) output.angleVelocityYaw);
    hash = hash_u32(hash, (uint32_t) output.animation);
    union { float f; uint32_t u; } animationSpeed = { output.animationSpeed };
    hash = hash_u32(hash, animationSpeed.u);
    hash = hash_u32(hash, (uint32_t) output.finalTextbox);
    hash = hash_u32(hash, (uint32_t) output.marioWon);
    hash = hash_u32(hash, (uint32_t) output.marioCheated);
    hash = hash_u32(hash, (uint32_t) output.reachedBottom);
    hash = hash_u32(hash, (uint32_t) output.resetTimer);
    hash = hash_u32(hash, output.setVelocityYValid ? velocityY.u : 0);
    hash = hash_u32(hash, (uint32_t) output.attachRaceObjects);
    hash = hash_u32(hash, (uint32_t) output.initializePath);
    hash = hash_u32(hash, (uint32_t) output.playRoughSlideSound);
    hash = hash_u32(hash, (uint32_t) output.playWalkingSound);
    hash = hash_u32(hash, (uint32_t) output.playPoundingSound);
    hash = hash_u32(hash, (uint32_t) output.cameraShakeSmall);
    hash = hash_u32(hash, (uint32_t) output.spawnSmoke);
    hash = hash_u32(hash, (uint32_t) output.spawnStar);
    return hash_u32(hash, (uint32_t) output.finalDialogCompleted);
}

static Input make_input(int32_t action) {
    Input input = {0};
    input.action = action;
    input.pathStatus = 0;
    return input;
}

int main(void) {
    uint64_t fingerprint = UINT64_C(1469598103934665603);
    Input input;
    Output output;

    input = make_input(WAIT_FOR_MARIO);
    input.timer = 11; input.marioPositionY = 100; input.initTextCooldown = 10;
    input.canActivateInitialText = 1;
    output = update(input); fingerprint = hash_output(fingerprint, output);

    input = make_input(SHOW_INIT_TEXT); input.initialDialogResponse = 1;
    output = update(input); fingerprint = hash_output(fingerprint, output);

    input = make_input(PREPARE_FOR_RACE); input.moveYaw = 0;
    output = update(input); fingerprint = hash_output(fingerprint, output);

    input = make_input(PREPARE_FOR_RACE); input.raceBeginComplete = 1;
    input.moveYaw = output.moveYaw;
    output = update(input); fingerprint = hash_output(fingerprint, output);

    input = make_input(RACE); input.positionY = 500; input.marioPositionY = 300;
    input.pathWaypointFlags = 0x20; input.pathTargetYaw = 6000;
    input.forwardVelocity = output.forwardVelocity; input.moveYaw = output.moveYaw;
    output = update(input); fingerprint = hash_output(fingerprint, output);

    input = make_input(RACE); input.timer = 61; input.positionY = 110; input.marioPositionY = 100;
    input.pathWaypointFlags = 35; input.pathTargetYaw = 6000;
    input.moveFlags = MOVE_ON_GROUND; input.animationAtEnd = 1;
    input.weightedTargetSpeed = output.weightedTargetSpeed;
    input.forwardVelocity = output.forwardVelocity; input.moveYaw = output.moveYaw;
    input.marioInAirAction = 1;
    output = update(input); fingerprint = hash_output(fingerprint, output);

    input = make_input(RACE); input.pathStatus = PATH_REACHED_END;
    input.forwardVelocity = output.forwardVelocity;
    output = update(input); fingerprint = hash_output(fingerprint, output);

    input = make_input(FINISH_RACE); input.timer = 6; input.moveFlags = MOVE_HIT_WALL;
    input.forwardVelocity = output.forwardVelocity;
    output = update(input); fingerprint = hash_output(fingerprint, output);

    input = make_input(FINISH_RACE); input.finalAnimationAtEnd = 1;
    output = update(input); fingerprint = hash_output(fingerprint, output);

    input = make_input(SHOW_FINAL_TEXT); input.moveYaw = 1000;
    input.marioWon = 1; input.marioCheated = 1;
    output = update(input); fingerprint = hash_output(fingerprint, output);

    input = make_input(SHOW_FINAL_TEXT); input.canActivateFinalText = 1;
    input.marioWon = 1; input.marioCheated = 1; input.moveYaw = 0;
    output = update(input); fingerprint = hash_output(fingerprint, output);

    input = make_input(SHOW_FINAL_TEXT); input.finalTextbox = output.finalTextbox;
    input.finalDialogResult = 1;
    output = update(input); fingerprint = hash_output(fingerprint, output);

    input = make_input(SHOW_FINAL_TEXT); input.canActivateFinalText = 1;
    input.marioWon = 1; input.moveYaw = 0;
    output = update(input); fingerprint = hash_output(fingerprint, output);

    input = make_input(SHOW_FINAL_TEXT); input.finalTextbox = output.finalTextbox;
    input.finalDialogResult = 1; input.marioWon = 1;
    output = update(input); fingerprint = hash_output(fingerprint, output);

    input = make_input(SHOW_FINAL_TEXT); input.finalTextbox = -1; input.marioWon = output.marioWon;
    output = update(input); fingerprint = hash_output(fingerprint, output);

    printf("racingPenguinFingerprint=0x%016llx\n", (unsigned long long) fingerprint);
    printf("SM64 Modern racing penguin C contract passed\n");
    return 0;
}
