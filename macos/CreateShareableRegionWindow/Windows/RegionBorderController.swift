import AppKit

@MainActor
final class RegionBorderController {
    private let panel: NSPanel

    init(region: CaptureRegion) {
        let thickness: CGFloat = 4
        let regionFrame = ScreenCoordinates.appKitRect(fromQuartz: region.cgRect)
            .insetBy(dx: -thickness, dy: -thickness)
        panel = NSPanel(
            contentRect: regionFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false)
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = RegionBorderView(frame: CGRect(origin: .zero, size: regionFrame.size))
    }

    func show() {
        panel.orderFrontRegardless()
    }

    func close() {
        panel.orderOut(nil)
        panel.close()
    }
}

private final class RegionBorderView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.systemRed.setStroke()
        let path = NSBezierPath(rect: bounds.insetBy(dx: 2, dy: 2))
        path.lineWidth = 4
        path.stroke()
    }
}
