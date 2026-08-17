import Foundation

enum SM64DialogBoxState: UInt8, Equatable, Sendable {
    case opening = 0
    case vertical = 1
    case horizontal = 2
    case closing = 3
}

enum SM64DialogBoxType: UInt8, Equatable, Sendable {
    case rotate = 0
    case zoom = 1
}

struct SM64DialogTickInput: Equatable, Sendable {
    let advanceLegacyDomain: Bool
    let aPressed: Bool
    let bPressed: Bool
    let lastPageStringPosition: Int16
    let linesPerBox: Int16

    init(
        advanceLegacyDomain: Bool = true,
        aPressed: Bool = false,
        bPressed: Bool = false,
        lastPageStringPosition: Int16 = 0,
        linesPerBox: Int16 = 2
    ) {
        self.advanceLegacyDomain = advanceLegacyDomain
        self.aPressed = aPressed
        self.bPressed = bPressed
        self.lastPageStringPosition = lastPageStringPosition
        self.linesPerBox = linesPerBox
    }
}

struct SM64DialogState: Equatable, Sendable {
    private(set) var boxState: SM64DialogBoxState = .opening
    private(set) var boxType: SM64DialogBoxType = .rotate
    private(set) var openTimerHalf: Int32 = 180
    private(set) var scaleHalf: Int32 = 38
    private(set) var scrollOffsetY: Int16 = 0
    private(set) var dialogID: Int16 = -1
    private(set) var textPosition: Int16 = 0
    private(set) var lineNumber: Int8 = 1
    private(set) var lastDialogResponse: Int8 = 0
    private(set) var dialogResponse: Int32 = 0

    mutating func create(
        dialogID: Int16,
        type: SM64DialogBoxType = .rotate,
        withResponse: Bool = false
    ) -> Bool {
        guard self.dialogID == -1 else { return false }
        self.dialogID = dialogID
        self.boxType = type
        if withResponse { lastDialogResponse = 1 }
        return true
    }

    mutating func resetRenderState() {
        boxState = .opening
        openTimerHalf = 180
        scaleHalf = 38
        dialogID = -1
        textPosition = 0
        lastDialogResponse = 0
        dialogResponse = 0
    }

    mutating func tick(_ input: SM64DialogTickInput) -> SM64DialogTickResult {
        guard dialogID != -1 else {
            return result()
        }
        var effect = SM64DialogEffects()
        if input.advanceLegacyDomain {
            switch boxState {
            case .opening:
                if openTimerHalf == 180 {
                    effect.appearanceSound = true
                }
                if boxType == .rotate {
                    openTimerHalf = max(openTimerHalf - 15, 0)
                    scaleHalf = max(scaleHalf - 3, 0)
                } else {
                    openTimerHalf = max(openTimerHalf - 20, 0)
                    scaleHalf = max(scaleHalf - 4, 0)
                }
                if openTimerHalf == 0 {
                    boxState = .vertical
                    lineNumber = 1
                }
            case .vertical:
                openTimerHalf = 0
                if input.aPressed || input.bPressed {
                    if input.lastPageStringPosition == -1 {
                        boxState = .closing
                    } else {
                        boxState = .horizontal
                        effect.nextPageSound = true
                    }
                }
            case .horizontal:
                scrollOffsetY &+= input.linesPerBox &* 2
                let threshold = input.linesPerBox &* 16
                if scrollOffsetY >= threshold {
                    textPosition = input.lastPageStringPosition
                    boxState = .vertical
                    scrollOffsetY = 0
                }
            case .closing:
                if openTimerHalf == 40 {
                    effect.disappearSound = true
                    dialogResponse = Int32(lineNumber)
                    effect.responseChanged = true
                }
                openTimerHalf = min(openTimerHalf + 20, 180)
                scaleHalf = min(scaleHalf + 4, 38)
                if openTimerHalf == 180 {
                    boxState = .opening
                    dialogID = -1
                    textPosition = 0
                    lastDialogResponse = 0
                    dialogResponse = 0
                }
            }
        }
        return result(effects: effect)
    }

    private func result(effects: SM64DialogEffects = SM64DialogEffects()) -> SM64DialogTickResult {
        SM64DialogTickResult(
            state: self,
            lowerBound: boxState == .horizontal ? Int16(scrollOffsetY / 16 + 1) : 1,
            effects: effects
        )
    }
}

struct SM64DialogEffects: Equatable, Sendable {
    var appearanceSound = false
    var nextPageSound = false
    var disappearSound = false
    var responseChanged = false
}

struct SM64DialogTickResult: Equatable, Sendable {
    let state: SM64DialogState
    let lowerBound: Int16
    let effects: SM64DialogEffects
}

