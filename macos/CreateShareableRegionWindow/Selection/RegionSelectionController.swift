import AppKit

@MainActor
final class RegionSelectionController {
    private var panels: [SelectionPanel] = []
    private var completion: ((CaptureRegion?) -> Void)?

    func present(initialRegion: CaptureRegion, completion: @escaping (CaptureRegion?) -> Void) {
        closePanels()
        self.completion = completion

        let initialAppKitRect = ScreenCoordinates.appKitRect(fromQuartz: initialRegion.cgRect)
        for screen in NSScreen.screens {
            let initialSelection: CGRect
            if screen.displayID == initialRegion.displayID {
                let intersection = initialAppKitRect.intersection(screen.frame)
                initialSelection = intersection.isNull
                    ? .zero
                    : intersection.offsetBy(dx: -screen.frame.minX, dy: -screen.frame.minY)
            } else {
                initialSelection = .zero
            }

            let panel = SelectionPanel(
                screen: screen,
                initialSelection: initialSelection,
                selected: { [weak self] localRect in
                    self?.accept(localRect: localRect, on: screen)
                },
                cancelled: { [weak self] in
                    self?.finish(with: nil)
                })
            panels.append(panel)
            panel.orderFrontRegardless()
        }

        panels.first?.makeKey()
    }

    func cancel() {
        finish(with: nil)
    }

    private func accept(localRect: CGRect, on screen: NSScreen) {
        let globalAppKitRect = localRect.offsetBy(dx: screen.frame.minX, dy: screen.frame.minY)
        let quartzRect = ScreenCoordinates.quartzRect(fromAppKit: globalAppKitRect).integral
        finish(with: CaptureRegion(displayID: screen.displayID, rect: quartzRect))
    }

    private func finish(with region: CaptureRegion?) {
        let completion = completion
        self.completion = nil
        closePanels()
        completion?(region)
    }

    private func closePanels() {
        panels.forEach {
            $0.orderOut(nil)
            $0.close()
        }
        panels.removeAll()
    }
}

private final class SelectionPanel: NSPanel {
    init(
        screen: NSScreen,
        initialSelection: CGRect,
        selected: @escaping (CGRect) -> Void,
        cancelled: @escaping () -> Void
    ) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false)

        setFrame(screen.frame, display: true)
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        contentView = SelectionView(
            frame: CGRect(origin: .zero, size: screen.frame.size),
            initialSelection: initialSelection,
            selected: selected,
            cancelled: cancelled)
        acceptsMouseMovedEvents = true
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func makeKey() {
        super.makeKey()
        makeFirstResponder(contentView)
    }
}

private final class SelectionView: NSView {
    private var startPoint: CGPoint?
    private var selection: CGRect
    private let selected: (CGRect) -> Void
    private let cancelled: () -> Void

    init(
        frame: CGRect,
        initialSelection: CGRect,
        selected: @escaping (CGRect) -> Void,
        cancelled: @escaping () -> Void
    ) {
        selection = initialSelection
        self.selected = selected
        self.cancelled = cancelled
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var acceptsFirstResponder: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.black.withAlphaComponent(0.32).setFill()
        bounds.fill()

        guard selection.width > 0, selection.height > 0 else { return }
        NSColor.systemBlue.withAlphaComponent(0.28).setFill()
        selection.fill()
        NSColor.systemBlue.setStroke()
        let outline = NSBezierPath(rect: selection.insetBy(dx: 1.5, dy: 1.5))
        outline.lineWidth = 3
        outline.stroke()

        let text = "\(Int(selection.width)) × \(Int(selection.height))   Release to select · Esc to cancel"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let textSize = (text as NSString).size(withAttributes: attributes)
        let labelOrigin = CGPoint(
            x: selection.minX,
            y: max(0, selection.maxY + 6))
        let labelRect = CGRect(
            x: labelOrigin.x,
            y: min(bounds.maxY - textSize.height - 12, labelOrigin.y),
            width: textSize.width + 14,
            height: textSize.height + 8)
        NSColor(calibratedWhite: 0.08, alpha: 0.9).setFill()
        NSBezierPath(roundedRect: labelRect, xRadius: 4, yRadius: 4).fill()
        (text as NSString).draw(
            at: CGPoint(x: labelRect.minX + 7, y: labelRect.minY + 4),
            withAttributes: attributes)
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeKey()
        window?.makeFirstResponder(self)
        let point = clamped(event.locationInWindow)
        startPoint = point
        selection = .zero
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let startPoint else { return }
        selection = rectangle(from: startPoint, to: clamped(event.locationInWindow))
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let startPoint else { return }
        self.startPoint = nil
        selection = rectangle(from: startPoint, to: clamped(event.locationInWindow))
        needsDisplay = true
        if selection.width >= 16, selection.height >= 16 {
            selected(selection)
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            cancelled()
        } else if event.keyCode == 36, selection.width >= 16, selection.height >= 16 {
            selected(selection)
        } else {
            super.keyDown(with: event)
        }
    }

    private func clamped(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(bounds.minX, point.x), bounds.maxX),
            y: min(max(bounds.minY, point.y), bounds.maxY))
    }

    private func rectangle(from start: CGPoint, to end: CGPoint) -> CGRect {
        CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y))
    }
}
