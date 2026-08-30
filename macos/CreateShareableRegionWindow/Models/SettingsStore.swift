import Foundation

enum SettingsStore {
    private static let key = "CaptureSettings"

    static func load() -> CaptureSettings {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let settings = try? JSONDecoder().decode(CaptureSettings.self, from: data)
        else {
            return .defaults()
        }
        return settings
    }

    static func save(_ settings: CaptureSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
