import SwiftUI
import FamilyControls

struct ContentView: View {
    @State private var statusText = "Checking Screen Time..."
    @State private var thresholdText = "No Screen Time event received yet"

    private let sharedDefaults = UserDefaults(
        suiteName: "group.com.timeup.shared"
    )

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "hourglass")
                .font(.system(size: 60))

            Text("TimeUp")
                .font(.largeTitle)
                .bold()

            Text(statusText)
                .foregroundStyle(.secondary)

            Text(thresholdText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Connect Screen Time") {
                Task {
                    do {
                        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                        checkAuthorization()
                    } catch {
                        checkAuthorization()
                    }
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Refresh Screen Time Status") {
                readMonitorData()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .onAppear {
            checkAuthorization()
            readMonitorData()
        }
    }

    private func checkAuthorization() {
        switch AuthorizationCenter.shared.authorizationStatus {

        case .approved, .approvedWithDataAccess:
            statusText = "Screen Time connected ✓"

            do {
                try ScreenTimeMonitor.shared.startMonitoring()
            } catch {
                statusText = "Screen Time connected — monitoring failed"
            }

        case .denied:
            statusText = "Screen Time access denied"

        case .notDetermined:
            statusText = "Screen Time is not connected"

        @unknown default:
            statusText = "Unknown authorization status"
        }
    }

    private func readMonitorData() {
        guard let date = sharedDefaults?.object(
            forKey: "lastThresholdReachedAt"
        ) as? Date else {
            thresholdText = "No Screen Time event received yet"
            return
        }

        let eventName = sharedDefaults?.string(
            forKey: "lastThresholdEventName"
        ) ?? "Unknown event"

        thresholdText = """
        Screen Time event received ✓
        \(eventName)
        \(date.formatted(date: .abbreviated, time: .standard))
        """
    }
}
