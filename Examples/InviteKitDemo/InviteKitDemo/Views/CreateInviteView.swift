import SwiftUI
import InviteKit

struct CreateInviteView: View {
    @State private var referrerId: String = ""
    @State private var campaignName: String = ""
    @State private var isLoading = false
    @State private var createdInvite: InviteResult?
    @State private var errorMessage: String?
    @State private var showingShareSheet = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Referrer Information")) {
                    TextField("Referrer ID (e.g., user123)", text: $referrerId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Campaign Name (optional)", text: $campaignName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section {
                    Button(action: createInvite) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                            Text(isLoading ? "Creating..." : "Create Invite Link")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(referrerId.isEmpty || isLoading)
                }

                if let invite = createdInvite {
                    Section(header: Text("Created Invite")) {
                        LabeledContent("Short Code", value: invite.shortCode)
                        LabeledContent("Referrer ID", value: invite.referrerId)

                        if let url = invite.inviteURL {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Invite URL")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(url.absoluteString)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                        }

                        if let metadata = invite.metadata, !metadata.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Metadata")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                ForEach(Array(metadata.keys.sorted()), id: \.self) { key in
                                    Text("\(key): \(metadata[key] ?? "")")
                                        .font(.system(.body, design: .monospaced))
                                }
                            }
                        }

                        Button(action: { showingShareSheet = true }) {
                            Label("Share Invite", systemImage: "square.and.arrow.up")
                        }
                    }
                }

                if let error = errorMessage {
                    Section(header: Text("Error")) {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Create Invite")
            .sheet(isPresented: $showingShareSheet) {
                if let url = createdInvite?.inviteURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private func createInvite() {
        isLoading = true
        errorMessage = nil

        var metadata: [String: String]?
        if !campaignName.isEmpty {
            metadata = ["campaign": campaignName]
        }

        Task {
            do {
                let result = try await InviteKit.createInviteLink(
                    referrerId: referrerId,
                    metadata: metadata
                )

                await MainActor.run {
                    createdInvite = result
                    isLoading = false
                }
            } catch let error as InviteError {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    CreateInviteView()
}
