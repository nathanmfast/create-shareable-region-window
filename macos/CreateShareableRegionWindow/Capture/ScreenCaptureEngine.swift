import AppKit
import CoreMedia
import CoreVideo
import IOSurface
import ScreenCaptureKit

enum CaptureEngineError: LocalizedError {
    case displayUnavailable
    case regionOutsideDisplay

    var errorDescription: String? {
        switch self {
        case .displayUnavailable:
            return "The selected display is no longer available. Select the area again."
        case .regionOutsideDisplay:
            return "The selected area must fit entirely on one display."
        }
    }
}

final class CapturedContentView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        layer?.contentsGravity = .resizeAspect
    }

    required init?(coder: NSCoder) {
        nil
    }

    func display(surface: IOSurface) {
        layer?.contents = surface
    }
}

final class ScreenCaptureEngine: NSObject, SCStreamOutput, SCStreamDelegate {
    private let outputQueue = DispatchQueue(
        label: "CreateShareableRegionWindow.ScreenCapture",
        qos: .userInteractive)
    private weak var previewView: CapturedContentView?
    private var stream: SCStream?
    private let stopped: (String) -> Void

    init(previewView: CapturedContentView, stopped: @escaping (String) -> Void) {
        self.previewView = previewView
        self.stopped = stopped
    }

    func start(region: CaptureRegion, includeCursor: Bool, excludedBundleIdentifiers: Set<String>) async throws {
        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true)

        guard let display = content.displays.first(where: { $0.displayID == region.displayID }) else {
            throw CaptureEngineError.displayUnavailable
        }

        let selectedRect = region.cgRect
        guard display.frame.contains(selectedRect) else {
            throw CaptureEngineError.regionOutsideDisplay
        }

        var excludedIdentifiers = excludedBundleIdentifiers
        if let ownBundleIdentifier = Bundle.main.bundleIdentifier {
            excludedIdentifiers.insert(ownBundleIdentifier)
        }
        let excludedApplications = content.applications.filter {
            excludedIdentifiers.contains($0.bundleIdentifier)
        }

        let filter = SCContentFilter(
            display: display,
            excludingApplications: excludedApplications,
            exceptingWindows: [])
        let configuration = SCStreamConfiguration()
        configuration.sourceRect = CGRect(
            x: selectedRect.minX - display.frame.minX,
            y: selectedRect.minY - display.frame.minY,
            width: selectedRect.width,
            height: selectedRect.height)

        let scale = NSScreen.screens
            .first(where: { $0.displayID == region.displayID })?
            .backingScaleFactor ?? 1
        configuration.width = max(1, Int(selectedRect.width * scale))
        configuration.height = max(1, Int(selectedRect.height * scale))
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        configuration.queueDepth = 3
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.showsCursor = includeCursor

        let stream = SCStream(filter: filter, configuration: configuration, delegate: self)
        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: outputQueue)
        self.stream = stream
        try await stream.startCapture()
    }

    func stop() async {
        guard let stream else { return }
        self.stream = nil
        try? await stream.stopCapture()
    }

    func stream(_ stream: SCStream, didStopWithError error: any Error) {
        DispatchQueue.main.async { [stopped] in
            stopped(error.localizedDescription)
        }
    }

    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of outputType: SCStreamOutputType
    ) {
        guard outputType == .screen, sampleBuffer.isValid else { return }
        guard
            let attachments = CMSampleBufferGetSampleAttachmentsArray(
                sampleBuffer,
                createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
            let statusValue = attachments.first?[.status] as? Int,
            SCFrameStatus(rawValue: statusValue) == .complete,
            let pixelBuffer = sampleBuffer.imageBuffer,
            let surfaceReference = CVPixelBufferGetIOSurface(pixelBuffer)?.takeUnretainedValue()
        else {
            return
        }

        let surface = unsafeBitCast(surfaceReference, to: IOSurface.self)
        DispatchQueue.main.async { [weak previewView] in
            previewView?.display(surface: surface)
        }
    }
}
