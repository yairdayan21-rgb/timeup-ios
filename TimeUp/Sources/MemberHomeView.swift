import SwiftUI
import FamilyControls

struct MemberHomeView: View {
    let member: TimeUpMember

    @State private var statusText = "זמן המסך עדיין לא מחובר"
    @State private var isRequestingAuthorization = false
    @State private var estimatedUsageMinutes = 0

    private let sharedDefaults = UserDefaults(
        suiteName: "group.com.timeup.shared"
    )

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
                    Label("זמן מסך היום", systemImage: "hourglass")
                        .font(.headline)

                    Text(formattedUsage)
                        .font(.system(size: 36, weight: .bold, design: .rounded))

                    Text("המדידה מתעדכנת לפי נקודות הבדיקה של TimeUp.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Divider()

                    Label(statusText, systemImage: authorizationIcon)
                        .foregroundStyle(authorizationColor)
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18))

                VStack(alignment: .leading, spacing: 10) {
                    Label("היעד שלך", systemImage: "target")
                        .font(.headline)

                    Text("היעד היומי יחובר בשלב הבא למנוע ההצלחה והרצף.")
                        .foregroundStyle(.secondary)
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
            refreshUsageEstimate()
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(15))
                refreshUsageEstimate()
            }
        }
    }

    private var groupCode: String {
        TimeUpStore.shared.groups.first(
            where: { $0.id == member.groupID }
        )?.code ?? "—"
    }

    private var formattedUsage: String {
        let hours = estimatedUsageMinutes / 60
        let minutes = estimatedUsageMinutes % 60

        if hours > 0 {
            return "\(hours) ש׳ \(minutes) דק׳"
        }

        return "\(minutes) דק׳"
    }

    private var hasScreenTimeAuthorization: Bool {
        let status = AuthorizationCenter.shared.authorizationStatus
        if status == .approved { return true }
        if #available(iOS 26.4, *), status == .approvedWithDataAccess { return true }
        return false
    }

    private var authorizationIcon: String {
        if hasScreenTimeAuthorization {
            return "checkmark.circle.fill"
        }
        if AuthorizationCenter.shared.authorizationStatus == .denied {
            return "xmark.circle.fill"
        }
        return "circle"
    }

    private var authorizationColor: Color {
        if hasScreenTimeAuthorization {
            return .green
        }
        if AuthorizationCenter.shared.authorizationStatus == .denied {
            return .red
        }
        return .secondary
    }

    private func refreshAuthorizationStatus() {
        if hasScreenTimeAuthorization {
            statusText = "זמן המסך מחובר ✓"
        } else if AuthorizationCenter.shared.authorizationStatus == .denied {
            statusText = "הגישה לזמן המסך נדחתה"
        } else if AuthorizationCenter.shared.authorizationStatus == .notDetermined {
            statusText = "נדרש אישור לזמן מסך"
        } else {
            statusText = "סטטוס זמן מסך לא ידוע"
        }
    }

    private func refreshUsageEstimate() {
        estimatedUsageMinutes = sharedDefaults?.integer(
            forKey: "estimatedUsageMinutes"
        ) ?? 0
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

                if hasScreenTimeAuthorization {
                    try? ScreenTimeMonitor.shared.startMonitoring()
                    refreshUsageEstimate()
                }
            }
        }
    }
}
