import SwiftUI
import FamilyControls

struct MemberHomeView: View {
    let member: TimeUpMember

    @State private var statusText = "זמן המסך עדיין לא מחובר"
    @State private var isRequestingAuthorization = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("שלום, \(member.displayName)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))

                    Text("זה היום שלך ב-TimeUp")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Label("היעד שלך", systemImage: "target")
                        .font(.headline)

                    Text("היעד יופיע כאן לאחר חיבור נתוני זמן המסך.")
                        .foregroundStyle(.secondary)

                    Divider()

                    Label(statusText, systemImage: authorizationIcon)
                        .foregroundStyle(authorizationColor)
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18))

                Button {
                    requestScreenTime()
                } label: {
                    HStack {
                        Image(systemName: "hourglass")
                        Text(isRequestingAuthorization ? "מתחבר..." : "חבר את זמן המסך")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRequestingAuthorization)

                VStack(alignment: .leading, spacing: 10) {
                    Text("הקבוצה שלך")
                        .font(.headline)

                    Text("קוד קבוצה: \(groupCode)")
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.bold)
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .padding(20)
        }
        .navigationTitle("TimeUp")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshAuthorizationStatus()
        }
    }

    private var groupCode: String {
        TimeUpStore.shared.group(forCode: currentGroupCode)?.code ?? "—"
    }

    private var currentGroupCode: String {
        TimeUpStore.shared.groups.first(where: { $0.id == member.groupID })?.code ?? ""
    }

    private var authorizationIcon: String {
        switch AuthorizationCenter.shared.authorizationStatus {
        case .approved, .approvedWithDataAccess:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        default:
            return "circle"
        }
    }

    private var authorizationColor: Color {
        switch AuthorizationCenter.shared.authorizationStatus {
        case .approved, .approvedWithDataAccess:
            return .green
        case .denied:
            return .red
        default:
            return .secondary
        }
    }

    private func refreshAuthorizationStatus() {
        switch AuthorizationCenter.shared.authorizationStatus {
        case .approved, .approvedWithDataAccess:
            statusText = "זמן המסך מחובר ✓"
        case .denied:
            statusText = "הגישה לזמן המסך נדחתה"
        case .notDetermined:
            statusText = "נדרש אישור לזמן מסך"
        @unknown default:
            statusText = "סטטוס זמן מסך לא ידוע"
        }
    }

    private func requestScreenTime() {
        isRequestingAuthorization = true

        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            } catch {
                // הסטטוס יוצג למשתמש לאחר סיום הבקשה.
            }

            await MainActor.run {
                isRequestingAuthorization = false
                refreshAuthorizationStatus()

                if AuthorizationCenter.shared.authorizationStatus == .approved ||
                    AuthorizationCenter.shared.authorizationStatus == .approvedWithDataAccess {
                    try? ScreenTimeMonitor.shared.startMonitoring()
                }
            }
        }
    }
}
