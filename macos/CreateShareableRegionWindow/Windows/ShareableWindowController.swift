import AppKit

@MainActor
final class ShareableWindowController: NSObject, NSWindowDelegate {
    private let region: CaptureRegion
    private let includeCursor: Bool
    private let excludedBundleIdentifiers: Set<String>
    private let previewView: CapturedContentView
    private let window: ShareableWindow
    private let closed: () -> Void
    private var borderController: RegionBorderController?
    private var hasReportedClose = false

    private lazy var captureEngine = ScreenCaptureEngine(
        previewView: previewView,
        stopped: { [weak self] message in
            self?.captureDidStop(message)
        })

    init(settings: CaptureSettings, closed: @escaping () -> Void) {
        region = settings.region
        includeCursor = settings.includeCursor
        excludedBundleIdentifiers = settings.excludedBundleIdentifiers
        self.closed = closed

        let initialSize = Self.initialWindowSize(for: settings.region)
        previewView = CapturedContentView(frame: CGRect(origin: .zero, size: initialSize))
        window = ShareableWindow(
            contentRect: CGRect(origin: .zero, size: initialSize),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false)
        super.init()

        window.title = "Shareable Region Window"
        window.contentView = previewView
        window.backgroundColor = .black
        window.minSize = NSSize(width: 320, height: 180)
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.sharingType = .readOnly
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.delegate = self
        window.onEscape = { [weak self] in self?.close() }
        update(topMost: settings.topMost, showRegionBorder: settings.showRegionBorder)
    }

    func start() async throws {
        window.center()
        window.makeKeyAndOrderFront(nil)
        try await captureEngine.start(
            region: region,
            includeCursor: includeCursor,
            excludedBundleIdentifiers: excludedBundleIdentifiers)
    }

    func update(topMost: Bool, showRegionBorder: Bool) {
        window.level = topMost ? .floating : .normal

        if showRegionBorder {
            if borderController == nil {
                borderController = RegionBorderController(region: region)
            }
            borderController?.show()
        } else {
            borderController?.close()
            borderController = nil
        }
    }

    func close() {
        window.close()
    }

    func windowWillClose(_ notification: Notification) {
        borderController?.close()
        borderController = nil
        Task { await captureEngine.stop() }
        reportClose()
    }

    private func captureDidStop(_ message: String) {
        guard window.isVisible else { return }
        window.title = "Shareable Region Window — capture stopped"
        let alert = NSAlert()
        alert.messageText = "Screen capture stopped"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.beginSheetModal(for: window)
    }

    private func reportClose() {
        guard !hasReportedClose else { return }
        hasReportedClose = true
        closed()
    }

    private static func initialWindowSize(for region: CaptureRegion) -> NSSize {
        let workingArea = NSScreen.main?.visibleFrame.size ?? NSSize(width: 1280, height: 720)
        let scale = min(
            0.75,
            min(workingArea.width / region.cgRect.width, workingArea.height / region.cgRect.height))
        return NSSize(
            width: max(320, region.cgRect.width * scale),
            height: max(180, region.cgRect.height * scale))
    }
}

private final class ShareableWindow: NSWindow {
    var onEscape: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        onEscape?()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onEscape?()
        } else {
            super.keyDown(with: event)
        }
    }
}
