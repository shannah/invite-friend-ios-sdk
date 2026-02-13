import SwiftUI
import InviteKit

struct SettingsView: View {
    @State private var apiKey: String = "demo-api-key"
    @State private var baseURL: String = "https://api.cn1invite.com"
    @State private var debugMode: Bool = false
    @State private var showingReconfigureAlert = false
    @State private var simulatedAttribution = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("API Configuration")) {
                    TextField("API Key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))

                    TextField("Base URL", text: $baseURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)

                    Button("Apply Configuration") {
                        showingReconfigureAlert = true
                    }
                    .disabled(apiKey.isEmpty || baseURL.isEmpty)
                }

                Section(header: Text("Debug Options")) {
                    Toggle("Debug Logging", isOn: $debugMode)
                }

                Section(header: Text("SDK Information")) {
                    LabeledContent("InviteKit Version", value: "1.0.0")
                    LabeledContent("Platform", value: platformInfo)
                }

                Section(header: Text("Storage Debug")) {
                    Button("Simulate Invite Attribution") {
                        simulateAttribution()
                    }

                    if simulatedAttribution {
                        Text("Attribution simulated! Check the Attribution tab.")
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    Button("Clear All Storage") {
                        InviteKit.clearInvite()
                        simulatedAttribution = false
                    }
                    .foregroundColor(.red)
                }

                Section(header: Text("About")) {
                    Link(destination: URL(string: "https://github.com/anthropics/invite-friend-ios-sdk")!) {
                        Label("GitHub Repository", systemImage: "link")
                    }

                    Link(destination: URL(string: "https://cn1invite.com/docs")!) {
                        Label("Documentation", systemImage: "book")
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Reconfigure SDK", isPresented: $showingReconfigureAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Apply") {
                    reconfigureSDK()
                }
            } message: {
                Text("This will reconfigure the InviteKit SDK with the new API key and base URL.")
            }
        }
    }

    private var platformInfo: String {
        #if os(iOS)
        return "iOS \(UIDevice.current.systemVersion)"
        #elseif os(macOS)
        return "macOS"
        #else
        return "Unknown"
        #endif
    }

    private func reconfigureSDK() {
        guard let url = URL(string: baseURL) else { return }
        InviteKit.configure(apiKey: apiKey, baseURL: url)
    }

    private func simulateAttribution() {
        // Simulate attribution by writing directly to the App Group storage
        // This mimics what CN1InviteKit does in the App Clip
        let suiteName = "group.com.cn1invite.demo.invite"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            print("Failed to access App Group storage")
            return
        }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        defaults.set("demo-referrer-123", forKey: "invite.referrerId")
        defaults.set("demo-code", forKey: "invite.shortCode")
        defaults.set(dateFormatter.string(from: Date()), forKey: "invite.createdAt")
        defaults.set(1, forKey: "invite.version")

        // Encode metadata
        let metadata = ["campaign": "demo", "source": "settings"]
        if let encoded = try? JSONEncoder().encode(metadata) {
            defaults.set(encoded, forKey: "invite.metadata")
        }

        defaults.synchronize()
        simulatedAttribution = true
    }
}

#Preview {
    SettingsView()
}
