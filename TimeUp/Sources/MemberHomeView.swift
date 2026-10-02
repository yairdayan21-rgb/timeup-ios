import SwiftUI
import FamilyControls

struct MemberHomeView: View {
    let member: TimeUpMember

    @StateObject private var store = TimeUpStore.shared

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
                    Text("שלום, \(currentMember.displayName)")
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

                VStack(alignment: .leading, spacing: 12) {
                    Label("היעד שלך", systemImage: "target")
                        .font(.headline)

                    if let target = currentMember.dailyTargetMinutes {
                        Text(formattedTarget(target))
                            .font(.system(size: 30, weight: .bold, design: .rounded))

                        if estimatedUsageMinutes <= target {
                            Text("נשארו \(formattedRemaining(target)) עד ליעד")
                                .foregroundStyle(.secondary)
                        } else {
                            Text("היעד היומי עבר")
                                .foregroundStyle(.red)
                                .fontWeight(.semibold)
                        }

                        ProgressView(
                            value: Double(min(estimatedUsageMinutes, target)),
                            total: Double(max(target, 1))
                        )
                    } else {
                        Text("עדיין לא נקבע יעד יומי.")
                            .foregroundStyle(.secondary)

                        Text("TimeUp יתחיל למדוד את היעד ברגע שיוגדר.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18))

                Button {
                    requestScreenTime()
                } label: {
                    HStack {
                        Image(systemName: "hourglass")

                        Text(
                            isRequestingAuthorization
                            ? "מתחבר..."
                            : "חבר את זמן המסך"
                        )
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

            if hasScreenTimeAuthorization {
                startScreenTimeMonitoring()
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(15))
                refreshUsageEstimate()
            }
        }
        .onChange(of: currentMember.dailyTargetMinutes) { _, _ in
            if hasScreenTimeAuthorization {
                startScreenTimeMonitoring()
            }
        }
    }

    private var currentMember: TimeUpMember {
        store.member(id: member.id) ?? member
    }

    private var groupCode: String {
        store.groups.first(
            where: { $0.id == currentMember.groupID }
        )?.code ?? "—"
    }

    private var formattedUsage: String {
        formattedMinutes(estimatedUsageMinutes)
    }

    private func formattedTarget(_ minutes: Int) -> String {
        formattedMinutes(minutes)
    }

    private func formattedRemaining(_ target: Int) -> String {
        let remaining = max(0, target - estimatedUsageMinutes)
        return formattedMinutes(remaining)
    }

    private func formattedMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 {
            return "\(hours) ש׳ \(remainingMinutes) דק׳"
        }

        return "\(remainingMinutes) דק׳"
    }

    private var hasScreenTimeAuthorization: Bool {
        let status = AuthorizationCenter.shared.authorizationStatus

        if status == .approved {
            return true
        }

        if #available(iOS 26.4, *),
           status == .approvedWithDataAccess {
            return true
        }

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

    private func startScreenTimeMonitoring() {
        do {
            try ScreenTimeMonitor.shared.startMonitoring(
                targetMinutes: currentMember.dailyTargetMinutes
            )
        } catch {
            statusText = "לא ניתן להתחיל את מדידת זמן המסך"
        }
    }

    private func requestScreenTime() {
        isRequestingAuthorization = true

        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(
                    for: .individual
                )
            } catch {
                // הסטטוס יוצג לאחר סיום הבקשה.
            }

            await MainActor.run {
                isRequestingAuthorization = false
                refreshAuthorizationStatus()

                if hasScreenTimeAuthorization {
                    startScreenTimeMonitoring()
                    refreshUsageEstimate()
                }
            }
        }
    }
}
