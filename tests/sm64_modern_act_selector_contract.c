#include <stdint.h>
#include <stdio.h>

#define FNV_OFFSET UINT64_C(1469598103934665603)
#define FNV_PRIME UINT64_C(1099511628211)

enum {
    MODEL_TRANSPARENT_STAR = 0x79,
    MODEL_STAR = 0x7A,
    STAR_SELECTOR_NOT_SELECTED = 0,
    STAR_SELECTOR_SELECTED = 1,
    STAR_SELECTOR_100_COINS = 2,
};

typedef struct {
    uint32_t model;
    uint8_t type;
    int32_t x;
    int32_t y;
    int32_t z;
    float size;
} SpawnRequest;

typedef struct {
    uint8_t stars;
    int32_t obtainedStars;
    int32_t initialSelectedActNum;
    int32_t visibleStars;
    int32_t selectableStarIndex;
    int32_t selectedActIndex;
    uint8_t selectorTypes[8];
    int32_t selectorTypeCount;
    SpawnRequest requests[8];
    int32_t requestCount;
} Initialization;

typedef struct {
    int32_t selectedActIndex;
    int32_t selectableStarIndex;
    int32_t menuHoldKeyIndex;
    int32_t menuHoldKeyTimer;
    uint8_t selectorTypes[8];
    int32_t selectorTypeCount;
} LoopOutput;

static uint64_t hash_u64(uint64_t seed, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte) {
        seed ^= (value >> (byte * 8u)) & UINT64_C(0xff);
        seed *= FNV_PRIME;
    }
    return seed;
}

static uint64_t hash_i32(uint64_t seed, int32_t value) {
    return hash_u64(seed, (uint64_t)(int64_t)value);
}

static uint64_t hash_float(uint64_t seed, float value) {
    union { float value; uint32_t bits; } representation = { .value = value };
    return hash_u64(seed, representation.bits);
}

static int has_star(uint8_t stars, int32_t index) {
    return (stars & (uint8_t)(UINT8_C(1) << (unsigned)index)) != 0;
}

static void add_request(
    Initialization *output,
    uint32_t model,
    uint8_t type,
    int32_t x,
    int32_t y,
    int32_t z,
    float size
) {
    SpawnRequest *request = &output->requests[output->requestCount++];
    request->model = model;
    request->type = type;
    request->x = x;
    request->y = y;
    request->z = z;
    request->size = size;
}

static Initialization initialize(
    uint8_t stars,
    int32_t obtainedStars,
    int32_t initialSelectedActNum,
    int32_t initialSelectableStarIndex,
    int32_t initialSelectedActIndex
) {
    Initialization output = {
        .stars = stars,
        .obtainedStars = obtainedStars,
        .initialSelectedActNum = initialSelectedActNum,
        .visibleStars = 0,
        .selectableStarIndex = initialSelectableStarIndex,
        .selectedActIndex = initialSelectedActIndex,
        .selectorTypeCount = 0,
        .requestCount = 0,
    };
    int32_t collected = 0;

    while (collected != obtainedStars) {
        const int starCollected = has_star(stars, output.visibleStars);
        if (starCollected) {
            collected++;
        } else if (output.initialSelectedActNum == 0) {
            output.initialSelectedActNum = output.visibleStars + 1;
            output.selectableStarIndex = output.visibleStars;
        }
        add_request(
            &output,
            starCollected ? MODEL_STAR : MODEL_TRANSPARENT_STAR,
            STAR_SELECTOR_NOT_SELECTED,
            0,
            248,
            -300,
            1.0f
        );
        output.visibleStars++;
    }

    if (output.visibleStars == obtainedStars && output.visibleStars != 6) {
        output.initialSelectedActNum = output.visibleStars + 1;
        output.selectableStarIndex = output.visibleStars;
        add_request(
            &output,
            MODEL_TRANSPARENT_STAR,
            STAR_SELECTOR_NOT_SELECTED,
            0,
            248,
            -300,
            1.0f
        );
        output.visibleStars++;
    }

    if (obtainedStars == 6) {
        output.initialSelectedActNum = output.visibleStars;
    }
    if (obtainedStars == 0) {
        output.initialSelectedActNum = 1;
    }
    if (has_star(stars, 6)) {
        add_request(&output, MODEL_STAR, STAR_SELECTOR_100_COINS, 370, 24, -300, 0.8f);
    }

    const int32_t rowOriginX = 75 - output.visibleStars * 75;
    for (int32_t index = 0; index < output.requestCount; ++index) {
        if (index < output.visibleStars) {
            output.requests[index].x = rowOriginX + index * 152;
        }
    }

    output.selectorTypeCount = output.requestCount;
    for (int32_t index = 0; index < output.requestCount; ++index) {
        output.selectorTypes[index] = output.requests[index].type;
    }
    return output;
}

static void handle_menu_scrolling(
    int32_t *currentIndex,
    int32_t minIndex,
    int32_t maxIndex,
    int32_t rawStickX,
    int32_t menuHoldKeyIndex,
    int32_t menuHoldKeyTimer,
    int32_t *nextHoldIndex,
    int32_t *nextTimer
) {
    int32_t index = 0;
    if (rawStickX > 60) index += 2;
    if (rawStickX < -60) index += 1;

    int32_t nextIndex = *currentIndex;
    if (((index ^ menuHoldKeyIndex) & index) == 2 && nextIndex != maxIndex) {
        nextIndex++;
    }
    if (((index ^ menuHoldKeyIndex) & index) == 1 && nextIndex != minIndex) {
        nextIndex--;
    }

    int32_t timer = menuHoldKeyTimer;
    int32_t holdIndex = menuHoldKeyIndex;
    if (timer == 10) {
        timer = 8;
        holdIndex = 0;
    } else {
        timer++;
        holdIndex = index;
    }
    if ((index & 3) == 0) timer = 0;

    *currentIndex = nextIndex;
    *nextHoldIndex = holdIndex;
    *nextTimer = timer;
}

static LoopOutput update(
    const Initialization *initial,
    int32_t selectedActIndex,
    int32_t selectableStarIndex,
    int32_t menuHoldKeyIndex,
    int32_t menuHoldKeyTimer,
    int32_t rawStickX,
    const uint8_t *currentSelectorTypes,
    int32_t currentSelectorTypeCount,
    int advanceLegacyDomain
) {
    LoopOutput output = {
        .selectedActIndex = selectedActIndex,
        .selectableStarIndex = selectableStarIndex,
        .menuHoldKeyIndex = menuHoldKeyIndex,
        .menuHoldKeyTimer = menuHoldKeyTimer,
        .selectorTypeCount = currentSelectorTypeCount,
    };
    for (int32_t index = 0; index < output.selectorTypeCount; ++index) {
        output.selectorTypes[index] = currentSelectorTypes[index];
    }
    if (!advanceLegacyDomain) return output;

    const int32_t maxIndex = initial->obtainedStars == 6
        ? initial->visibleStars - 1
        : initial->obtainedStars;
    handle_menu_scrolling(
        &output.selectableStarIndex,
        0,
        maxIndex,
        rawStickX,
        output.menuHoldKeyIndex,
        output.menuHoldKeyTimer,
        &output.menuHoldKeyIndex,
        &output.menuHoldKeyTimer
    );

    if (initial->obtainedStars != 6) {
        output.selectedActIndex = 0;
        int32_t starIndexCounter = output.selectableStarIndex;
        for (int32_t index = 0; index < initial->visibleStars; ++index) {
            if (has_star(initial->stars, index) || index + 1 == initial->initialSelectedActNum) {
                if (starIndexCounter == 0) {
                    output.selectedActIndex = index;
                    break;
                }
                starIndexCounter--;
            }
        }
    } else {
        output.selectedActIndex = output.selectableStarIndex;
    }

    for (int32_t index = 0; index < initial->visibleStars; ++index) {
        output.selectorTypes[index] = output.selectedActIndex == index
            ? STAR_SELECTOR_SELECTED
            : STAR_SELECTOR_NOT_SELECTED;
    }
    return output;
}

static uint64_t hash_initialization(uint64_t seed, const Initialization *output) {
    uint64_t hash = hash_u64(seed, output->stars);
    hash = hash_i32(hash, output->obtainedStars);
    hash = hash_i32(hash, output->initialSelectedActNum);
    hash = hash_i32(hash, output->visibleStars);
    hash = hash_i32(hash, output->selectableStarIndex);
    hash = hash_i32(hash, output->selectedActIndex);
    hash = hash_u64(hash, (uint64_t)output->selectorTypeCount);
    for (int32_t index = 0; index < output->selectorTypeCount; ++index) {
        hash = hash_u64(hash, output->selectorTypes[index]);
    }
    hash = hash_u64(hash, (uint64_t)output->requestCount);
    for (int32_t index = 0; index < output->requestCount; ++index) {
        const SpawnRequest *request = &output->requests[index];
        hash = hash_u64(hash, request->model);
        hash = hash_u64(hash, request->type);
        hash = hash_i32(hash, request->x);
        hash = hash_i32(hash, request->y);
        hash = hash_i32(hash, request->z);
        hash = hash_float(hash, request->size);
    }
    return hash;
}

static uint64_t hash_loop(uint64_t seed, const LoopOutput *output) {
    uint64_t hash = hash_i32(seed, output->selectedActIndex);
    hash = hash_i32(hash, output->selectableStarIndex);
    hash = hash_i32(hash, output->menuHoldKeyIndex);
    hash = hash_i32(hash, output->menuHoldKeyTimer);
    hash = hash_u64(hash, (uint64_t)output->selectorTypeCount);
    for (int32_t index = 0; index < output->selectorTypeCount; ++index) {
        hash = hash_u64(hash, output->selectorTypes[index]);
    }
    return hash;
}

int main(void) {
    uint64_t fingerprint = FNV_OFFSET;
    const Initialization first = initialize(0x00, 0, 0, 0, 0);
    const Initialization second = initialize(0x15, 3, 0, 0, 0);
    const Initialization third = initialize(0x3F, 6, 0, 0, 0);
    const Initialization fourth = initialize(0x41, 0, 0, 0, 0);
    const Initialization fifth = initialize(0x05, 2, 4, 3, 1);
    const Initialization *initializations[] = { &first, &second, &third, &fourth, &fifth };
    for (unsigned index = 0; index < sizeof(initializations) / sizeof(initializations[0]); ++index) {
        fingerprint = hash_initialization(fingerprint, initializations[index]);
    }

    const LoopOutput firstScroll = update(
        &second,
        0,
        second.selectableStarIndex,
        0,
        0,
        100,
        second.selectorTypes,
        second.selectorTypeCount,
        1
    );
    const LoopOutput secondScroll = update(
        &second,
        firstScroll.selectedActIndex,
        firstScroll.selectableStarIndex,
        firstScroll.menuHoldKeyIndex,
        firstScroll.menuHoldKeyTimer,
        -100,
        firstScroll.selectorTypes,
        firstScroll.selectorTypeCount,
        1
    );
    const LoopOutput held = update(
        &second,
        secondScroll.selectedActIndex,
        secondScroll.selectableStarIndex,
        secondScroll.menuHoldKeyIndex,
        secondScroll.menuHoldKeyTimer,
        100,
        secondScroll.selectorTypes,
        secondScroll.selectorTypeCount,
        0
    );
    fingerprint = hash_loop(fingerprint, &firstScroll);
    fingerprint = hash_loop(fingerprint, &secondScroll);
    fingerprint = hash_loop(fingerprint, &held);

    // bhv_act_selector_init for stars 0, 2, and 5 creates six visible child
    // records in slots 1..6 (trace subjects 2..7); the loop then selects slot
    // 2 after a right input.  This mirrors the owner bridge's generation-safe
    // parent/child receipt without depending on Swift object internals.
    fingerprint = hash_u64(fingerprint, 1);
    fingerprint = hash_u64(fingerprint, 6);
    for (uint64_t index = 0; index < 6; ++index) {
        fingerprint = hash_u64(fingerprint, index + 2);
        fingerprint = hash_u64(fingerprint, 1);
        fingerprint = hash_u64(
            fingerprint,
            (index == 0 || index == 2 || index == 5) ? MODEL_STAR : MODEL_TRANSPARENT_STAR
        );
    }
    const Initialization bridgeInitialization = initialize(0x25, 3, 0, 0, 0);
    const LoopOutput bridgeFirstScroll = update(
        &bridgeInitialization,
        bridgeInitialization.selectedActIndex,
        bridgeInitialization.selectableStarIndex,
        0,
        0,
        100,
        bridgeInitialization.selectorTypes,
        bridgeInitialization.selectorTypeCount,
        1
    );
    fingerprint = hash_loop(fingerprint, &bridgeFirstScroll);

    printf("actSelectorFingerprint=0x%016llx\n", (unsigned long long)fingerprint);
    puts("SM64 Modern act-selector C contract passed");
    return 0;
}
