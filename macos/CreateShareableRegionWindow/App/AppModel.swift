import AppKit
import Combine
import CoreGraphics

@MainActor
final class AppModel: ObservableObject {
    @Published var settings: CaptureSettings {
        didSet {
            SettingsStore.save(settings)
            outputWindow?.update(
                topMost: settings.topMost,
                showRegionBorder: settings.showRegionBorder)
        }
    }
    @Published private(set) var runningApplications: [RunningApplicationInfo] = []
    @Published private(set) var status = "Ready"
    @Published private(set) var hasOutputWindow = false

    private var outputWindow: ShareableWindowController?
    private var outputIdentifier: UUID?
    private var selectionController: RegionSelectionController?

    init() {
        settings = SettingsStore.load()
        refreshApplications()
    }

    var hasScreenCapturePermission: Bool {
        CGPreflightScreenCaptureAccess()
    }

    func refreshApplications() {
        let ownIdentifier = Bundle.main.bundleIdentifier
        var applicationsByIdentifier: [String: RunningApplicationInfo] = [:]

        for application in NSWorkspace.shared.runningApplications {
            guard
                application.activationPolicy == .regular,
                let identifier = application.bundleIdentifier,
                identifier != ownIdentifier
            else {
                continue
            }
            let name = application.localizedName ?? identifier
            applicationsByIdentifier[identifier] = RunningApplicationInfo(
                bundleIdentifier: identifier,
                name: name)
        }

        runningApplications = applicationsByIdentifier.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    func isExcluded(_ application: RunningApplicationInfo) -> Bool {
        settings.excludedBundleIdentifiers.contains(application.bundleIdentifier)
    }

    func setExcluded(_ excluded: Bool, application: RunningApplicationInfo) {
        if excluded {
            settings.excludedBundleIdentifiers.insert(application.bundleIdentifier)
        } else {
            settings.excludedBundleIdentifiers.remove(application.bundleIdentifier)
        }
    }

    func selectArea() {
        let controller = RegionSelectionController()
        selectionController = controller
        status = "Drag to select an area; press Escape to cancel"
        controller.present(initialRegion: settings.region) { [weak self] region in
            guard let self else { return }
            selectionController = nil
            guard let region else {
                status = "Selection cancelled"
                return
            }
            settings.region = region
            status = "Selected \(Int(region.width)) × \(Int(region.height)) at \(Int(region.x)), \(Int(region.y))"
        }
    }

    func createOutputWindow() {
        guard settings.region.width >= 16, settings.region.height >= 16 else {
            status = "Select an area at least 16 × 16 points"
            return
        }

        if !CGPreflightScreenCaptureAccess(), !CGRequestScreenCaptureAccess() {
            status = "Grant Screen Recording permission, then select Create again"
            return
        }

        closeOutputWindow()
        let identifier = UUID()
        outputIdentifier = identifier
        let controller = ShareableWindowController(settings: settings) { [weak self] in
            self?.outputDidClose(identifier: identifier)
        }
        outputWindow = controller
        hasOutputWindow = true
        status = "Starting capture…"

        Task { [weak self, weak controller] in
            guard let self, let controller else { return }
            do {
                try await controller.start()
                guard outputIdentifier == identifier else { return }
                let region = settings.region
                status = "Capturing \(Int(region.width)) × \(Int(region.height)) at \(Int(region.x)), \(Int(region.y))"
            } catch {
                guard outputIdentifier == identifier else { return }
                controller.close()
                status = "Capture failed: \(error.localizedDescription)"
            }
        }
    }

    func closeOutputWindow() {
        outputWindow?.close()
        outputWindow = nil
        outputIdentifier = nil
        hasOutputWindow = false
    }

    func openScreenRecordingSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func outputDidClose(identifier: UUID) {
        guard outputIdentifier == identifier else { return }
        outputWindow = nil
        outputIdentifier = nil
        hasOutputWindow = false
        status = "Shareable Region Window closed"
    }
}
