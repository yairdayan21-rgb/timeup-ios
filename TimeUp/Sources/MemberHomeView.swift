import SwiftUI
import FamilyControls
import UserNotifications

struct MemberHomeView: View {

    let member: TimeUpMember

    @StateObject private var store =
        TimeUpStore.shared

    @State private var statusText =
        "זמן המסך עדיין לא מחובר"

    @State private var isRequestingAuthorization =
        false

    @State private var estimatedUsageMinutes =
        0

    private let sharedDefaults =
        UserDefaults(
            suiteName: "group.com.timeup.shared"
        )

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 20
            ) {

                // MARK: - Header

                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {

                    Text(
                        "שלום, \(currentMember.displayName)"
                    )
                    .font(
                        .system(
                            size: 32,
                            weight: .bold,
                            design: .rounded
                        )
                    )

                    Text(
                        "זה היום שלך ב-TimeUp"
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }

                // MARK: - Daily Status

                HStack(spacing: 12) {

                    statusCard(
                        value:
                            "\(currentStreak)",
                        title:
                            "רצף",
                        icon:
                            "flame.fill"
                    )

                    statusCard(
                        value:
                            yesterdayStatusText,
                        title:
                            "אתמול",
                        icon:
                            yesterdayStatusIcon
                    )

                    statusCard(
                        value:
                            "\(completedDaysCount)",
                        title:
                            "ימים",
                        icon:
                            "calendar"
                    )
                }

                // MARK: - Learning Day

                if isCurrentLearningPhase {

                    VStack(
                        alignment: .leading,
                        spacing: 10
                    ) {

                        Label(
                            "יום למידה",
                            systemImage:
                                "brain.head.profile"
                        )
                        .font(.headline)

                        Text(
                            "TimeUp אוסף נתוני שימוש כדי לבנות את היעד הראשון שלך."
                        )
                        .foregroundStyle(
                            .secondary
                        )

                        Text(
                            "היום הזה לא נחשב הצלחה או כישלון ולא מאפס את הרצף."
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )
                    }
                    .padding()
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .background(
                        .thinMaterial
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 18
                        )
                    )
                }

                // MARK: - Screen Time

                VStack(
                    alignment: .leading,
                    spacing: 14
                ) {

                    Label(
                        "זמן מסך היום",
                        systemImage:
                            "hourglass"
                    )
                    .font(.headline)

                    Text(
                        formattedUsage
                    )
                    .font(
                        .system(
                            size: 36,
                            weight: .bold,
                            design: .rounded
                        )
                    )

                    Text(
                        "זמן המסך מתעדכן אוטומטית במהלך היום."
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )

                    Divider()

                    Label(
                        statusText,
                        systemImage:
                            authorizationIcon
                    )
                    .foregroundStyle(
                        authorizationColor
                    )
                }
                .padding()
                .background(
                    .thinMaterial
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 18
                    )
                )

                // MARK: - Daily Target

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    Label(
                        "היעד שלך",
                        systemImage:
                            "target"
                    )
                    .font(.headline)

                    if let target =
                        currentMember
                            .dailyTargetMinutes {

                        Text(
                            formattedTarget(
                                target
                            )
                        )
                        .font(
                            .system(
                                size: 30,
                                weight: .bold,
                                design: .rounded
                            )
                        )

                        if estimatedUsageMinutes <=
                            target {

                            Text(
                                "נשארו \(formattedRemaining(target)) עד ליעד"
                            )
                            .foregroundStyle(
                                .secondary
                            )

                        } else {

                            Text(
                                "היעד היומי עבר"
                            )
                            .foregroundStyle(
                                .red
                            )
                            .fontWeight(
                                .semibold
                            )
                        }

                        ProgressView(
                            value:
                                Double(
                                    min(
                                        estimatedUsageMinutes,
                                        target
                                    )
                                ),
                            total:
                                Double(
                                    max(
                                        target,
                                        1
                                    )
                                )
                        )

                    } else if
                        isCurrentLearningPhase {

                        Text(
                            "היעד הראשון ייקבע לאחר יום הלמידה."
                        )
                        .fontWeight(
                            .semibold
                        )

                        Text(
                            "בינתיים TimeUp מודד את זמן המסך שלך כרגיל."
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )

                    } else {

                        Text(
                            "עדיין לא נקבע יעד יומי."
                        )
                        .foregroundStyle(
                            .secondary
                        )

                        Text(
                            "TimeUp יתחיל למדוד את היעד ברגע שיוגדר."
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )
                    }
                }
                .padding()
                .background(
                    .thinMaterial
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 18
                    )
                )

                // MARK: - Yesterday

                if let yesterdayProgress {

                    VStack(
                        alignment: .leading,
                        spacing: 12
                    ) {

                        Label(
                            "סיכום היום האחרון",
                            systemImage:
                                "clock.arrow.circlepath"
                        )
                        .font(.headline)

                        HStack {

                            Text(
                                "זמן מסך"
                            )

                            Spacer()

                            Text(
                                formattedMinutes(
                                    yesterdayProgress
                                        .usageMinutes
                                )
                            )
                            .fontWeight(
                                .semibold
                            )
                        }

                        if let target =
                            yesterdayProgress
                                .targetMinutes {

                            HStack {

                                Text(
                                    "יעד"
                                )

                                Spacer()

                                Text(
                                    formattedMinutes(
                                        target
                                    )
                                )
                                .fontWeight(
                                    .semibold
                                )
                            }
                        }

                        Divider()

                        if yesterdayProgress
                            .isLearningDay {

                            Label(
                                "יום למידה הושלם",
                                systemImage:
                                    "brain.head.profile"
                            )
                            .fontWeight(
                                .semibold
                            )

                        } else if
                            yesterdayProgress
                                .achieved {

                            Label(
                                "עמדת ביעד",
                                systemImage:
                                    "checkmark.circle.fill"
                            )
                            .foregroundStyle(
                                .green
                            )
                            .fontWeight(
                                .semibold
                            )

                        } else {

                            Label(
                                "היעד לא הושג",
                                systemImage:
                                    "xmark.circle.fill"
                            )
                            .foregroundStyle(
                                .red
                            )
                            .fontWeight(
                                .semibold
                            )
                        }
                    }
                    .padding()
                    .background(
                        .thinMaterial
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 18
                        )
                    )
                }

                // MARK: - Screen Time Connection

                Button {

                    requestScreenTime()

                } label: {

                    HStack {

                        Image(
                            systemName:
                                "hourglass"
                        )

                        Text(
                            isRequestingAuthorization
                            ? "מתחבר..."
                            : hasScreenTimeAuthorization
                                ? "זמן המסך מחובר"
                                : "חבר את זמן המסך"
                        )
                        .fontWeight(
                            .semibold
                        )

                        Spacer()

                        if hasScreenTimeAuthorization {

                            Image(
                                systemName:
                                    "checkmark.circle.fill"
                            )
                        }
                    }
                    .padding()
                    .frame(
                        maxWidth: .infinity
                    )
                }
                .buttonStyle(
                    .borderedProminent
                )
                .disabled(
                    isRequestingAuthorization ||
                    hasScreenTimeAuthorization
                )

                // MARK: - Group

                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {

                    Text(
                        "הקבוצה שלך"
                    )
                    .font(.headline)

                    Text(
                        "קוד קבוצה: \(groupCode)"
                    )
                    .font(
                        .system(
                            .body,
                            design:
                                .monospaced
                        )
                    )
                    .fontWeight(
                        .bold
                    )
                }
                .padding()
                .background(
                    .thinMaterial
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 18
                    )
                )
            }
            .padding(20)
        }
        .background {

            if hasScreenTimeAuthorization {

                ScreenTimeReportView()
            }
        }
        .navigationTitle(
            "TimeUp"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )

        // MARK: - Screen Lifecycle

        .onAppear {

            refreshAuthorizationStatus()
            refreshUsageEstimate()

            if hasScreenTimeAuthorization {

                requestNotificationAuthorization()

                startScreenTimeMonitoring()
            }
        }

        // MARK: - Live Usage Refresh

        .task {

            while !Task.isCancelled {

                try? await Task.sleep(
                    for: .seconds(15)
                )

                refreshUsageEstimate()
            }
        }

        // MARK: - Target Changes

        .onChange(
            of:
                currentMember
                    .dailyTargetMinutes
        ) { _, _ in

            if hasScreenTimeAuthorization {

                startScreenTimeMonitoring()
            }
        }
    }

    // MARK: - Member

    private var currentMember:
        TimeUpMember {

        store.member(
            id: member.id
        ) ?? member
    }

    // MARK: - Progress

    private var memberProgress:
        [TimeUpDailyProgress] {

        store.progress(
            for: currentMember.id
        )
    }

    private var completedDaysCount:
        Int {

        memberProgress.count
    }

    private var currentStreak:
        Int {

        store.currentStreak(
            for: currentMember.id
        )
    }

    private var yesterdayProgress:
        TimeUpDailyProgress? {

        store.previousProgress(
            for: currentMember.id
        )
    }

    private var isCurrentLearningPhase:
        Bool {

        memberProgress.isEmpty
    }

    private var yesterdayStatusText:
        String {

        guard let progress =
            yesterdayProgress
        else {
            return "—"
        }

        if progress.isLearningDay {
            return "למידה"
        }

        return progress.achieved
            ? "הצלחה"
            : "לא הושג"
    }

    private var yesterdayStatusIcon:
        String {

        guard let progress =
            yesterdayProgress
        else {
            return "minus.circle"
        }

        if progress.isLearningDay {

            return
                "brain.head.profile"
        }

        return progress.achieved
            ? "checkmark.circle.fill"
            : "xmark.circle.fill"
    }

    // MARK: - Group

    private var groupCode:
        String {

        store.groups.first(
            where: {
                $0.id ==
                    currentMember.groupID
            }
        )?.code ?? "—"
    }

    // MARK: - Formatting

    private var formattedUsage:
        String {

        formattedMinutes(
            estimatedUsageMinutes
        )
    }

    private func formattedTarget(
        _ minutes: Int
    ) -> String {

        formattedMinutes(
            minutes
        )
    }

    private func formattedRemaining(
        _ target: Int
    ) -> String {

        let remaining =
            max(
                0,
                target -
                    estimatedUsageMinutes
            )

        return formattedMinutes(
            remaining
        )
    }

    private func formattedMinutes(
        _ minutes: Int
    ) -> String {

        let hours =
            minutes / 60

        let remainingMinutes =
            minutes % 60

        if hours > 0 &&
            remainingMinutes > 0 {

            return
                "\(hours) ש׳ \(remainingMinutes) דק׳"
        }

        if hours > 0 {

            return
                "\(hours) ש׳"
        }

        return
            "\(remainingMinutes) דק׳"
    }

    // MARK: - Status Card

    private func statusCard(
        value: String,
        title: String,
        icon: String
    ) -> some View {

        VStack(
            spacing: 7
        ) {

            Image(
                systemName: icon
            )
            .font(.title3)

            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(
                    0.7
                )

            Text(title)
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
        }
        .frame(
            maxWidth: .infinity
        )
        .padding(
            .vertical,
            14
        )
        .background(
            .thinMaterial
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }

    // MARK: - Screen Time Authorization

    private var hasScreenTimeAuthorization:
        Bool {

        let status =
            AuthorizationCenter.shared
                .authorizationStatus

        if status == .approved {
            return true
        }

        if #available(
            iOS 26.4,
            *
        ),
           status ==
            .approvedWithDataAccess {

            return true
        }

        return false
    }

    private var authorizationIcon:
        String {

        if hasScreenTimeAuthorization {

            return
                "checkmark.circle.fill"
        }

        if AuthorizationCenter.shared
            .authorizationStatus ==
            .denied {

            return
                "xmark.circle.fill"
        }

        return "circle"
    }

    private var authorizationColor:
        Color {

        if hasScreenTimeAuthorization {

            return .green
        }

        if AuthorizationCenter.shared
            .authorizationStatus ==
            .denied {

            return .red
        }

        return .secondary
    }

    private func refreshAuthorizationStatus() {

        if hasScreenTimeAuthorization {

            statusText =
                "זמן המסך מחובר ✓"

        } else if
            AuthorizationCenter.shared
                .authorizationStatus ==
            .denied {

            statusText =
                "הגישה לזמן המסך נדחתה"

        } else if
            AuthorizationCenter.shared
                .authorizationStatus ==
            .notDetermined {

            statusText =
                "נדרש אישור לזמן מסך"

        } else {

            statusText =
                "סטטוס זמן מסך לא ידוע"
        }
    }

    // MARK: - Usage

    private func refreshUsageEstimate() {

        if let reportedUsage =
            sharedDefaults?.object(
                forKey:
                    "reportedUsageMinutes"
            ) as? Int {

            estimatedUsageMinutes =
                max(
                    0,
                    reportedUsage
                )

        } else {

            estimatedUsageMinutes =
                sharedDefaults?
                    .integer(
                        forKey:
                            "estimatedUsageMinutes"
                    ) ?? 0
        }
    }

    // MARK: - Monitoring

    private func startScreenTimeMonitoring() {

        do {

            try ScreenTimeMonitor.shared
                .startMonitoring(
                    targetMinutes:
                        currentMember
                            .dailyTargetMinutes
                )

        } catch {

            statusText =
                "לא ניתן להתחיל את מדידת זמן המסך"
        }
    }

    // MARK: - Notifications

    private func requestNotificationAuthorization() {

        UNUserNotificationCenter.current()
            .requestAuthorization(
                options: [
                    .alert,
                    .sound,
                    .badge
                ]
            ) { _, _ in }
    }

    // MARK: - Authorization Request

    private func requestScreenTime() {

        guard
            !isRequestingAuthorization
        else {
            return
        }

        isRequestingAuthorization =
            true

        Task {

            do {

                try await
                    AuthorizationCenter.shared
                        .requestAuthorization(
                            for: .individual
                        )

                await MainActor.run {

                    refreshAuthorizationStatus()
                    refreshUsageEstimate()

                    isRequestingAuthorization =
                        false

                    if hasScreenTimeAuthorization {

                        requestNotificationAuthorization()

                        startScreenTimeMonitoring()
                    }
                }

            } catch {

                await MainActor.run {

                    refreshAuthorizationStatus()

                    isRequestingAuthorization =
                        false
                }
            }
        }
    }
}
