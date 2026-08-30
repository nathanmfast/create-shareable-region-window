import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: AppModel
    @State private var exclusionsExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose an area, select Create, then share the Shareable Region Window in your meeting.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .bottom, spacing: 12) {
                coordinateField("Left", value: $model.settings.region.x)
                coordinateField("Top", value: $model.settings.region.y)
                coordinateField("Width", value: $model.settings.region.width)
                coordinateField("Height", value: $model.settings.region.height)
                Button("Select area…") {
                    model.selectArea()
                }
            }

            DisclosureGroup(isExpanded: $exclusionsExpanded) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Applications selected here remain visible on your desktop but are omitted from the shared region.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Refresh") {
                            model.refreshApplications()
                        }
                        if !model.settings.excludedBundleIdentifiers.isEmpty {
                            Button("Clear") {
                                model.settings.excludedBundleIdentifiers.removeAll()
                            }
                        }
                    }

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(model.runningApplications) { application in
                                Toggle(
                                    application.name,
                                    isOn: Binding(
                                        get: { model.isExcluded(application) },
                                        set: { model.setExcluded($0, application: application) }))
                            }
                        }
                    }
                    .frame(maxHeight: 160)
                }
                .padding(.top, 8)
            } label: {
                Text("Hide applications (\(model.settings.excludedBundleIdentifiers.count))")
            }

            Toggle("Include mouse pointer", isOn: $model.settings.includeCursor)
            Toggle("Keep Shareable Region Window on top", isOn: $model.settings.topMost)
            Toggle("Show a red border around the shared region", isOn: $model.settings.showRegionBorder)

            if !model.hasScreenCapturePermission {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text("Screen Recording permission is required.")
                    Button("Open Settings") {
                        model.openScreenRecordingSettings()
                    }
                }
                .font(.callout)
            }

            HStack {
                Button("Create") {
                    model.createOutputWindow()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)

                if model.hasOutputWindow {
                    Button("Close shared window") {
                        model.closeOutputWindow()
                    }
                }
            }

            Text(model.status)
                .font(.callout)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .padding(24)
        .frame(width: 620)
    }

    private func coordinateField(_ label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(label, value: value, formatter: Self.numberFormatter)
                .frame(width: 82)
        }
    }

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = false
        return formatter
    }()
}
