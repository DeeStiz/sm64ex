import Foundation

/// Model IDs and selector modes used by `bhv_act_selector_init`.
///
/// These are fixed-width values so the menu reducer can be replayed without
/// carrying a C `Object *` or a pointer to the save-file globals.
enum SM64ActSelectorModel: UInt32, Equatable, Sendable {
    case transparentStar = 0x79 // MODEL_TRANSPARENT_STAR
    case star = 0x7A // MODEL_STAR
}

enum SM64ActSelectorType: UInt8, Equatable, Sendable {
    case notSelected = 0 // STAR_SELECTOR_NOT_SELECTED
    case selected = 1 // STAR_SELECTOR_SELECTED
    case oneHundredCoins = 2 // STAR_SELECTOR_100_COINS
}

struct SM64ActSelectorPosition: Equatable, Sendable {
    let x: Int32
    let y: Int32
    let z: Int32
}

struct SM64ActSelectorSpawnRequest: Equatable, Sendable {
    let model: SM64ActSelectorModel
    let type: SM64ActSelectorType
    let position: SM64ActSelectorPosition
    let size: Float
}

struct SM64ActSelectorInitializationInput: Equatable, Sendable {
    let stars: UInt8
    let obtainedStars: Int32
    let initialSelectedActNum: Int32
    let initialSelectableStarIndex: Int32
    let initialSelectedActIndex: Int32

    init(
        stars: UInt8,
        obtainedStars: Int32,
        initialSelectedActNum: Int32 = 0,
        initialSelectableStarIndex: Int32 = 0,
        initialSelectedActIndex: Int32 = 0
    ) {
        self.stars = stars
        self.obtainedStars = obtainedStars
        self.initialSelectedActNum = initialSelectedActNum
        self.initialSelectableStarIndex = initialSelectableStarIndex
        self.initialSelectedActIndex = initialSelectedActIndex
    }
}

struct SM64ActSelectorInitializationOutput: Equatable, Sendable {
    let stars: UInt8
    let obtainedStars: Int32
    let initialSelectedActNum: Int32
    let visibleStars: Int32
    let selectableStarIndex: Int32
    let selectedActIndex: Int32
    let selectorTypes: [SM64ActSelectorType]
    let spawnRequests: [SM64ActSelectorSpawnRequest]
}

struct SM64ActSelectorLoopInput: Equatable, Sendable {
    let stars: UInt8
    let obtainedStars: Int32
    let initialSelectedActNum: Int32
    let visibleStars: Int32
    let selectedActIndex: Int32
    let selectableStarIndex: Int32
    let menuHoldKeyIndex: Int32
    let menuHoldKeyTimer: Int32
    let rawStickX: Int32
    let selectorTypes: [SM64ActSelectorType]
    let advanceLegacyDomain: Bool

    init(
        stars: UInt8,
        obtainedStars: Int32,
        initialSelectedActNum: Int32,
        visibleStars: Int32,
        selectedActIndex: Int32,
        selectableStarIndex: Int32,
        menuHoldKeyIndex: Int32 = 0,
        menuHoldKeyTimer: Int32 = 0,
        rawStickX: Int32 = 0,
        selectorTypes: [SM64ActSelectorType],
        advanceLegacyDomain: Bool = true
    ) {
        self.stars = stars
        self.obtainedStars = obtainedStars
        self.initialSelectedActNum = initialSelectedActNum
        self.visibleStars = visibleStars
        self.selectedActIndex = selectedActIndex
        self.selectableStarIndex = selectableStarIndex
        self.menuHoldKeyIndex = menuHoldKeyIndex
        self.menuHoldKeyTimer = menuHoldKeyTimer
        self.rawStickX = rawStickX
        self.selectorTypes = selectorTypes
        self.advanceLegacyDomain = advanceLegacyDomain
    }
}

struct SM64ActSelectorLoopOutput: Equatable, Sendable {
    let selectedActIndex: Int32
    let selectableStarIndex: Int32
    let menuHoldKeyIndex: Int32
    let menuHoldKeyTimer: Int32
    let selectorTypes: [SM64ActSelectorType]
}

/// Value counterpart of `bhv_act_selector_init` and `bhv_act_selector_loop`.
///
/// Save flags, input, and the legacy menu repeat state are copied into the
/// reducer. The owner bridge owns object lifetimes and turns spawn requests
/// into child objects; this type never reaches into the C object graph.
enum SM64ActSelectorBehavior {
    static func initialize(
        _ input: SM64ActSelectorInitializationInput
    ) -> SM64ActSelectorInitializationOutput {
        precondition((0...6).contains(input.obtainedStars))

        var collected: Int32 = 0
        var visible: Int32 = 0
        var initialSelectedActNum = input.initialSelectedActNum
        var selectableStarIndex = input.initialSelectableStarIndex
        var requests: [SM64ActSelectorSpawnRequest] = []
        requests.reserveCapacity(7)

        while collected != input.obtainedStars {
            let collectedStar = hasStar(input.stars, index: visible)
            if collectedStar {
                collected += 1
            } else if initialSelectedActNum == 0 {
                initialSelectedActNum = visible + 1
                selectableStarIndex = visible
            }

            requests.append(
                request(
                    model: collectedStar ? .star : .transparentStar,
                    type: .notSelected,
                    x: 0,
                    y: 248,
                    z: -300,
                    size: 1
                )
            )
            visible += 1
        }

        if visible == input.obtainedStars && visible != 6 {
            initialSelectedActNum = visible + 1
            selectableStarIndex = visible
            requests.append(
                request(
                    model: .transparentStar,
                    type: .notSelected,
                    x: 0,
                    y: 248,
                    z: -300,
                    size: 1
                )
            )
            visible += 1
        }

        if input.obtainedStars == 6 {
            initialSelectedActNum = visible
        }
        if input.obtainedStars == 0 {
            initialSelectedActNum = 1
        }

        // `star_select.c` centers the row after it knows the final visible
        // count. Keep the layout as a value operation so the owner bridge
        // never has to reconstruct C's menu geometry.
        let rowOriginX = 75 - visible * 75
        for index in requests.indices {
            let current = requests[index]
            requests[index] = request(
                model: current.model,
                type: current.type,
                x: rowOriginX + Int32(index) * 152,
                y: current.position.y,
                z: current.position.z,
                size: current.size
            )
        }

        if hasStar(input.stars, index: 6) {
            requests.append(
                request(
                    model: .star,
                    type: .oneHundredCoins,
                    x: 370,
                    y: 24,
                    z: -300,
                    size: 0.8
                )
            )
        }

        return SM64ActSelectorInitializationOutput(
            stars: input.stars,
            obtainedStars: input.obtainedStars,
            initialSelectedActNum: initialSelectedActNum,
            visibleStars: visible,
            selectableStarIndex: selectableStarIndex,
            selectedActIndex: input.initialSelectedActIndex,
            selectorTypes: requests.map(\.type),
            spawnRequests: requests
        )
    }

    static func update(_ input: SM64ActSelectorLoopInput) -> SM64ActSelectorLoopOutput {
        precondition((0...6).contains(input.obtainedStars))
        precondition(input.visibleStars >= 0 && input.visibleStars <= 6)
        precondition(input.selectorTypes.count == Int(input.visibleStars) + (hasStar(input.stars, index: 6) ? 1 : 0))

        guard input.advanceLegacyDomain else {
            return SM64ActSelectorLoopOutput(
                selectedActIndex: input.selectedActIndex,
                selectableStarIndex: input.selectableStarIndex,
                menuHoldKeyIndex: input.menuHoldKeyIndex,
                menuHoldKeyTimer: input.menuHoldKeyTimer,
                selectorTypes: input.selectorTypes
            )
        }

        var selectedActIndex = input.selectedActIndex
        var selectableStarIndex = input.selectableStarIndex
        let scroll = handleMenuScrolling(
            currentIndex: selectableStarIndex,
            minIndex: 0,
            maxIndex: input.obtainedStars == 6 ? input.visibleStars - 1 : input.obtainedStars,
            rawStickX: input.rawStickX,
            menuHoldKeyIndex: input.menuHoldKeyIndex,
            menuHoldKeyTimer: input.menuHoldKeyTimer
        )
        selectableStarIndex = scroll.currentIndex

        if input.obtainedStars != 6 {
            selectedActIndex = 0
            var starIndexCounter = selectableStarIndex
            for index in 0..<input.visibleStars {
                if hasStar(input.stars, index: index) || index + 1 == input.initialSelectedActNum {
                    if starIndexCounter == 0 {
                        selectedActIndex = index
                        break
                    }
                    starIndexCounter -= 1
                }
            }
        } else {
            selectedActIndex = selectableStarIndex
        }

        var selectorTypes = input.selectorTypes
        for index in 0..<input.visibleStars {
            selectorTypes[Int(index)] = selectedActIndex == index ? .selected : .notSelected
        }

        return SM64ActSelectorLoopOutput(
            selectedActIndex: selectedActIndex,
            selectableStarIndex: selectableStarIndex,
            menuHoldKeyIndex: scroll.menuHoldKeyIndex,
            menuHoldKeyTimer: scroll.menuHoldKeyTimer,
            selectorTypes: selectorTypes
        )
    }

    private static func hasStar(_ stars: UInt8, index: Int32) -> Bool {
        precondition((0...7).contains(index))
        return stars & (UInt8(1) << UInt8(index)) != 0
    }

    private static func request(
        model: SM64ActSelectorModel,
        type: SM64ActSelectorType,
        x: Int32,
        y: Int32,
        z: Int32,
        size: Float
    ) -> SM64ActSelectorSpawnRequest {
        SM64ActSelectorSpawnRequest(
            model: model,
            type: type,
            position: SM64ActSelectorPosition(x: x, y: y, z: z),
            size: size
        )
    }

    private static func handleMenuScrolling(
        currentIndex: Int32,
        minIndex: Int32,
        maxIndex: Int32,
        rawStickX: Int32,
        menuHoldKeyIndex: Int32,
        menuHoldKeyTimer: Int32
    ) -> (currentIndex: Int32, menuHoldKeyIndex: Int32, menuHoldKeyTimer: Int32) {
        var index: Int32 = 0
        if rawStickX > 60 { index += 2 }
        if rawStickX < -60 { index += 1 }

        var nextIndex = currentIndex
        if ((index ^ menuHoldKeyIndex) & index) == 2 {
            if nextIndex != maxIndex { nextIndex += 1 }
        }
        if ((index ^ menuHoldKeyIndex) & index) == 1 {
            if nextIndex != minIndex { nextIndex -= 1 }
        }

        var nextTimer = menuHoldKeyTimer
        var nextHoldIndex = menuHoldKeyIndex
        if nextTimer == 10 {
            nextTimer = 8
            nextHoldIndex = 0
        } else {
            nextTimer += 1
            nextHoldIndex = index
        }
        if index & 3 == 0 { nextTimer = 0 }

        return (nextIndex, nextHoldIndex, nextTimer)
    }
}
