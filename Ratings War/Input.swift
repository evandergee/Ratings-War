import CoreGraphics
import GameController

/// Merges touch sticks, keyboard, and game controllers into one move vector and one fire vector.
final class InputController {
    enum Key {
        case w, a, s, d, up, down, left, right, space, enter
    }

    /// Set by the scene from the on-screen sticks, each with length 0...1.
    var touchMove = CGVector.zero
    var touchFire = CGVector.zero

    private(set) var move = CGVector.zero
    /// Zero, or a unit vector snapped to one of 8 directions.
    private(set) var fire = CGVector.zero

    private var confirmHeld = false
    private var pendingConfirm = false

    #if os(macOS)
    var pressedKeyCodes = Set<UInt16>()
    #endif

    func requestConfirm() {
        pendingConfirm = true
    }

    func consumeConfirm() -> Bool {
        defer { pendingConfirm = false }
        return pendingConfirm
    }

    func poll() {
        var m = touchMove
        var f = touchFire
        var confirm = isDown(.space) || isDown(.enter)

        m.dx += axis(negative: .a, positive: .d)
        m.dy += axis(negative: .s, positive: .w)
        f.dx += axis(negative: .left, positive: .right)
        f.dy += axis(negative: .down, positive: .up)

        if let pad = GCController.current?.extendedGamepad {
            m.dx += CGFloat(pad.leftThumbstick.xAxis.value + pad.dpad.xAxis.value)
            m.dy += CGFloat(pad.leftThumbstick.yAxis.value + pad.dpad.yAxis.value)
            f.dx += CGFloat(pad.rightThumbstick.xAxis.value)
            f.dy += CGFloat(pad.rightThumbstick.yAxis.value)
            // Face buttons fire in their own direction, like the SNES layout.
            f.dx += (pad.buttonB.isPressed ? 1 : 0) - (pad.buttonX.isPressed ? 1 : 0)
            f.dy += (pad.buttonY.isPressed ? 1 : 0) - (pad.buttonA.isPressed ? 1 : 0)
            confirm = confirm || pad.buttonA.isPressed || pad.buttonMenu.isPressed
        }

        let moveLength = m.length
        if moveLength < 0.15 {
            move = .zero
        } else {
            move = moveLength > 1 ? m / moveLength : m
        }
        fire = snappedToEightWays(f)

        if confirm && !confirmHeld {
            pendingConfirm = true
        }
        confirmHeld = confirm
    }

    private func axis(negative: Key, positive: Key) -> CGFloat {
        (isDown(positive) ? 1 : 0) - (isDown(negative) ? 1 : 0)
    }

    private func snappedToEightWays(_ v: CGVector) -> CGVector {
        guard v.length >= 0.3 else { return .zero }
        let step = CGFloat.pi / 4
        let angle = (atan2(v.dy, v.dx) / step).rounded() * step
        return CGVector(dx: cos(angle), dy: sin(angle))
    }

    private func isDown(_ key: Key) -> Bool {
        #if os(macOS)
        let code: UInt16
        switch key {
        case .w: code = 13
        case .a: code = 0
        case .s: code = 1
        case .d: code = 2
        case .up: code = 126
        case .down: code = 125
        case .left: code = 123
        case .right: code = 124
        case .space: code = 49
        case .enter: code = 36
        }
        return pressedKeyCodes.contains(code)
        #else
        let code: GCKeyCode
        switch key {
        case .w: code = .keyW
        case .a: code = .keyA
        case .s: code = .keyS
        case .d: code = .keyD
        case .up: code = .upArrow
        case .down: code = .downArrow
        case .left: code = .leftArrow
        case .right: code = .rightArrow
        case .space: code = .spacebar
        case .enter: code = .returnOrEnter
        }
        return GCKeyboard.coalesced?.keyboardInput?.button(forKeyCode: code)?.isPressed ?? false
        #endif
    }
}

extension CGVector {
    var length: CGFloat {
        (dx * dx + dy * dy).squareRoot()
    }

    static func * (v: CGVector, s: CGFloat) -> CGVector {
        CGVector(dx: v.dx * s, dy: v.dy * s)
    }

    static func / (v: CGVector, s: CGFloat) -> CGVector {
        CGVector(dx: v.dx / s, dy: v.dy / s)
    }
}

extension CGPoint {
    static func + (p: CGPoint, v: CGVector) -> CGPoint {
        CGPoint(x: p.x + v.dx, y: p.y + v.dy)
    }

    static func - (a: CGPoint, b: CGPoint) -> CGVector {
        CGVector(dx: a.x - b.x, dy: a.y - b.y)
    }
}
