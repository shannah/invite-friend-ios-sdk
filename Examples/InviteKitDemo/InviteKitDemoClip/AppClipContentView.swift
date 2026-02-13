import SwiftUI
import CN1InviteKit

struct AppClipContentView: View {
    @State private var inviteData: InviteData?
    @State private var processingStatus: ProcessingStatus = .waiting

    enum ProcessingStatus {
        case waiting
        case processing
        case success
        case error(String)
    }

    var body: some View {
        VStack(spacing: 24) {
            // App Icon and Title
            Image(systemName: "link.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("InviteKit Demo")
                .font(.largeTitle)
                .fontWeight(.bold)

            // Status Display
            statusView

            // Invite Details (if available)
            if let invite = inviteData {
                inviteDetailsView(invite)
            }

            Spacer()

            // Download CTA
            VStack(spacing: 12) {
                Text("Get the full app for more features")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button(action: promptFullAppDownload) {
                    Label("Get Full App", systemImage: "arrow.down.app")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 40)
        }
        .padding()
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            handleUserActivity(activity)
        }
        .onOpenURL { url in
            handleInviteURL(url)
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch processingStatus {
        case .waiting:
            VStack(spacing: 8) {
                Image(systemName: "link.badge.plus")
                    .font(.title)
                    .foregroundColor(.secondary)
                Text("Waiting for invite link...")
                    .foregroundColor(.secondary)
            }
            .padding()

        case .processing:
            VStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Processing invite...")
                    .foregroundColor(.secondary)
            }
            .padding()

        case .success:
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.green)
                Text("Invite processed successfully!")
                    .foregroundColor(.green)
            }
            .padding()

        case .error(let message):
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title)
                    .foregroundColor(.red)
                Text(message)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }

    @ViewBuilder
    private func inviteDetailsView(_ invite: InviteData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Invite Details")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Referred by:")
                        .foregroundColor(.secondary)
                    Text(invite.referrerId)
                        .fontWeight(.medium)
                }

                HStack {
                    Text("Invite Code:")
                        .foregroundColor(.secondary)
                    Text(invite.shortCode)
                        .font(.system(.body, design: .monospaced))
                }

                if let metadata = invite.metadata, !metadata.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Additional Info:")
                            .foregroundColor(.secondary)
                        ForEach(Array(metadata.keys.sorted()), id: \.self) { key in
                            Text("\(key): \(metadata[key] ?? "")")
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Actions

    private func handleUserActivity(_ activity: NSUserActivity) {
        guard let url = activity.webpageURL else {
            processingStatus = .error("No URL found in activity")
            return
        }
        handleInviteURL(url)
    }

    private func handleInviteURL(_ url: URL) {
        processingStatus = .processing

        // Parse the invite URL
        guard let invite = CN1InviteKit.parseInviteURL(url) else {
            processingStatus = .error("Invalid invite URL format")
            return
        }

        // Store the invite for the main app
        let stored = CN1InviteKit.storeInvite(invite)

        if stored {
            inviteData = invite
            processingStatus = .success
        } else {
            processingStatus = .error("Failed to store invite data")
        }
    }

    private func promptFullAppDownload() {
        // Get the current window scene and present the overlay
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else {
            return
        }

        CN1InviteKit.presentFullAppOverlay(in: windowScene)
    }
}

#Preview {
    AppClipContentView()
}
