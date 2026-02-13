import SwiftUI
import InviteKit

struct AttributionView: View {
    @State private var invite: InviteResult?
    @State private var isRecordingEvent = false
    @State private var eventRecorded = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Attribution Status")) {
                    if let invite = invite {
                        attributionDetails(invite)
                    } else {
                        Text("No attribution data found")
                            .foregroundColor(.secondary)
                        Text("Attribution data is stored when a user opens the app via an invite link from the App Clip.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button(action: checkAttribution) {
                        Label("Check for Attribution", systemImage: "arrow.clockwise")
                    }

                    if invite != nil {
                        Button(action: clearAttribution) {
                            Label("Clear Attribution Data", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }

                if let invite = invite {
                    Section(header: Text("Record Event")) {
                        Button(action: { recordEvent(.installed) }) {
                            HStack {
                                if isRecordingEvent {
                                    ProgressView()
                                }
                                Text("Record Install Event")
                            }
                        }
                        .disabled(isRecordingEvent)

                        Button(action: { recordEvent(.attributed) }) {
                            HStack {
                                if isRecordingEvent {
                                    ProgressView()
                                }
                                Text("Record Attribution Event")
                            }
                        }
                        .disabled(isRecordingEvent)

                        if eventRecorded {
                            Text("Event recorded successfully!")
                                .foregroundColor(.green)
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
            .navigationTitle("Attribution")
            .onAppear {
                checkAttribution()
            }
        }
    }

    @ViewBuilder
    private func attributionDetails(_ invite: InviteResult) -> some View {
        LabeledContent("Referrer ID", value: invite.referrerId)
        LabeledContent("Short Code", value: invite.shortCode)
        LabeledContent("Created At", value: invite.createdAt.formatted())

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
    }

    private func checkAttribution() {
        invite = InviteKit.checkForInvite()
        errorMessage = nil
        eventRecorded = false
    }

    private func clearAttribution() {
        InviteKit.clearInvite()
        invite = nil
        errorMessage = nil
        eventRecorded = false
    }

    private func recordEvent(_ eventType: InviteEventType) {
        guard let invite = invite else { return }

        isRecordingEvent = true
        errorMessage = nil
        eventRecorded = false

        Task {
            do {
                try await InviteKit.recordEvent(
                    shortCode: invite.shortCode,
                    eventType: eventType
                )

                await MainActor.run {
                    eventRecorded = true
                    isRecordingEvent = false
                }
            } catch let error as InviteError {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isRecordingEvent = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isRecordingEvent = false
                }
            }
        }
    }
}

#Preview {
    AttributionView()
}
