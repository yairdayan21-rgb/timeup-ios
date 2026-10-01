import SwiftUI
import FamilyControls

struct ContentView: View {
    @State private var statusText = "Checking Screen Time..."

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "hourglass")
                .font(.system(size: 60))

            Text("TimeUp")
                .font(.largeTitle)
                .bold()

            Text(statusText)
                .foregroundStyle(.secondary)

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
        }
        .padding()
        .onAppear {
            checkAuthorization()
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
}
