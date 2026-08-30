import AppKit
import CoreGraphics

struct CaptureRegion: Codable, Equatable {
    var displayID: UInt32
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }

    init(displayID: UInt32, rect: CGRect) {
        self.displayID = displayID
        x = rect.origin.x
        y = rect.origin.y
        width = rect.width
        height = rect.height
    }
}

struct CaptureSettings: Codable, Equatable {
    var region: CaptureRegion
    var includeCursor = true
    var topMost = false
    var excludedBundleIdentifiers: Set<String> = []
    var showRegionBorder = false

    static func defaults() -> CaptureSettings {
        guard let screen = NSScreen.screens.first else {
            return CaptureSettings(region: CaptureRegion(
                displayID: 0,
                rect: CGRect(x: 0, y: 0, width: 1920, height: 1080)))
        }

        let displayFrame = ScreenCoordinates.quartzRect(fromAppKit: screen.frame)
        let width = min(1920, displayFrame.width)
        let height = min(1080, displayFrame.height)
        return CaptureSettings(region: CaptureRegion(
            displayID: screen.displayID,
            rect: CGRect(x: displayFrame.minX, y: displayFrame.minY, width: width, height: height)))
    }
}

struct RunningApplicationInfo: Identifiable, Hashable {
    let bundleIdentifier: String
    let name: String

    var id: String { bundleIdentifier }
}

enum ScreenCoordinates {
    private static var mainScreenTop: CGFloat {
        NSScreen.screens.first?.frame.maxY ?? 0
    }

    static func quartzRect(fromAppKit rect: CGRect) -> CGRect {
        CGRect(
            x: rect.minX,
            y: mainScreenTop - rect.maxY,
            width: rect.width,
            height: rect.height)
    }

    static func appKitRect(fromQuartz rect: CGRect) -> CGRect {
        CGRect(
            x: rect.minX,
            y: mainScreenTop - rect.maxY,
            width: rect.width,
            height: rect.height)
    }
}

extension NSScreen {
    var displayID: UInt32 {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
    }
}
