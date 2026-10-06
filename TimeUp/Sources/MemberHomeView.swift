import SwiftUI
import FamilyControls
import UserNotifications

struct MemberHomeView: View {

    let member: TimeUpMember

    @StateObject private var store =
        TimeUpStore.shared

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    @State private var statusText = ""

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
                        greetingText
                    )
                    .font(
                        .system(
                            size: 32,
                            weight: .bold,
                            design: .rounded
                        )
                    )

                    Text(todaySubtitleText)
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
                            streakText,
                        icon:
                            "flame.fill"
                    )

                    statusCard(
                        value:
                            yesterdayStatusText,
                        title:
                            yesterdayText,
                        icon:
                            yesterdayStatusIcon
                    )

                    statusCard(
                        value:
                            "\(completedDaysCount)",
                        title:
                            daysText,
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
                            learningDayText,
                            systemImage:
                                "brain.head.profile"
                        )
                        .font(.headline)

                        Text(
                            learningDayDescriptionText
                        )
                        .foregroundStyle(
                            .secondary
                        )

                        Text(
                            learningDayStreakDescriptionText
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
                        screenTimeTodayText,
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
                        screenTimeUpdatesAutomaticallyText
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
                        yourTargetText,
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
                                remainingUntilTargetText(
                                    target
                                )
                            )
                            .foregroundStyle(
                                .secondary
                            )

                        } else {

                            Text(
                                dailyTargetExceededText
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
                            firstTargetAfterLearningDayText
                        )
                        .fontWeight(
                            .semibold
                        )

                        Text(
                            measuringNormallyText
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )

                    } else {

                        Text(
                            noDailyTargetText
                        )
                        .foregroundStyle(
                            .secondary
                        )

                        Text(
                            targetMeasurementStartText
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
                            lastDaySummaryText,
                            systemImage:
                                "clock.arrow.circlepath"
                        )
                        .font(.headline)

                        HStack {

                            Text(
                                screenTimeText
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
                                    targetText
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
                                learningDayCompletedText,
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
                                targetAchievedText,
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
                                targetNotAchievedText,
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
                                ? connectingText
                                : hasScreenTimeAuthorization
                                    ? screenTimeConnectedText
                                    : connectScreenTimeText
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
                        yourGroupText
                    )
                    .font(.headline)

                    Text(
                        groupCodeText
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

        .onChange(
            of: localization.language
        ) { _, _ in

            refreshAuthorizationStatus()
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
            return learningText
        }

        return progress.achieved
            ? successText
            : notAchievedText
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

        let safeMinutes =
            max(minutes, 0)

        let hours =
            safeMinutes / 60

        let remainingMinutes =
            safeMinutes % 60

        switch localization.language {

        case .hebrew:

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

        case .english:

            if hours > 0 &&
                remainingMinutes > 0 {

                return
                    "\(hours) hr \(remainingMinutes) min"
            }

            if hours > 0 {

                return
                    "\(hours) hr"
            }

            return
                "\(remainingMinutes) min"

        case .arabic:

            if hours > 0 &&
                remainingMinutes > 0 {

                return
                    "\(hours) س \(remainingMinutes) د"
            }

            if hours > 0 {

                return
                    "\(hours) س"
            }

            return
                "\(remainingMinutes) د"
        }
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
                screenTimeConnectedCheckText

        } else if
            AuthorizationCenter.shared
                .authorizationStatus ==
            .denied {

            statusText =
                screenTimeAccessDeniedText

        } else if
            AuthorizationCenter.shared
                .authorizationStatus ==
            .notDetermined {

            statusText =
                screenTimePermissionRequiredText

        } else {

            statusText =
                unknownScreenTimeStatusText
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
                screenTimeMonitoringFailedText
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

    // MARK: - Localization

    private var greetingText: String {

        switch localization.language {
        case .hebrew:
            return "שלום, \(currentMember.displayName)"
        case .english:
            return "Hello, \(currentMember.displayName)"
        case .arabic:
            return "مرحبًا، \(currentMember.displayName)"
        }
    }

    private var todaySubtitleText: String {

        switch localization.language {
        case .hebrew:
            return "זה היום שלך ב-TimeUp"
        case .english:
            return "This is your day in TimeUp"
        case .arabic:
            return "هذا يومك في TimeUp"
        }
    }

    private var streakText: String {

        switch localization.language {
        case .hebrew:
            return "רצף"
        case .english:
            return "Streak"
        case .arabic:
            return "السلسلة"
        }
    }

    private var yesterdayText: String {

        switch localization.language {
        case .hebrew:
            return "אתמול"
        case .english:
            return "Yesterday"
        case .arabic:
            return "أمس"
        }
    }

    private var daysText: String {

        switch localization.language {
        case .hebrew:
            return "ימים"
        case .english:
            return "Days"
        case .arabic:
            return "أيام"
        }
    }

    private var learningDayText: String {

        switch localization.language {
        case .hebrew:
            return "יום למידה"
        case .english:
            return "Learning day"
        case .arabic:
            return "يوم تعلّم"
        }
    }

    private var learningDayDescriptionText: String {

        switch localization.language {
        case .hebrew:
            return "TimeUp אוסף נתוני שימוש כדי לבנות את היעד הראשון שלך."
        case .english:
            return "TimeUp collects usage data to create your first target."
        case .arabic:
            return "يجمع TimeUp بيانات الاستخدام لإنشاء هدفك الأول."
        }
    }

    private var learningDayStreakDescriptionText: String {

        switch localization.language {
        case .hebrew:
            return "היום הזה לא נחשב הצלחה או כישלון ולא מאפס את הרצף."
        case .english:
            return "This day does not count as a success or failure and does not reset the streak."
        case .arabic:
            return "لا يُحتسب هذا اليوم كنجاح أو فشل ولا يعيد ضبط السلسلة."
        }
    }

    private var screenTimeTodayText: String {

        switch localization.language {
        case .hebrew:
            return "זמן מסך היום"
        case .english:
            return "Screen time today"
        case .arabic:
            return "وقت الشاشة اليوم"
        }
    }

    private var screenTimeUpdatesAutomaticallyText: String {

        switch localization.language {
        case .hebrew:
            return "זמן המסך מתעדכן אוטומטית במהלך היום."
        case .english:
            return "Screen time updates automatically throughout the day."
        case .arabic:
            return "يتم تحديث وقت الشاشة تلقائيًا خلال اليوم."
        }
    }

    private var yourTargetText: String {

        switch localization.language {
        case .hebrew:
            return "היעד שלך"
        case .english:
            return "Your target"
        case .arabic:
            return "هدفك"
        }
    }

    private func remainingUntilTargetText(
        _ target: Int
    ) -> String {

        switch localization.language {
        case .hebrew:
            return "נשארו \(formattedRemaining(target)) עד ליעד"
        case .english:
            return "\(formattedRemaining(target)) remaining until your target"
        case .arabic:
            return "متبقي \(formattedRemaining(target)) حتى الهدف"
        }
    }

    private var dailyTargetExceededText: String {

        switch localization.language {
        case .hebrew:
            return "היעד היומי עבר"
        case .english:
            return "Daily target exceeded"
        case .arabic:
            return "تم تجاوز الهدف اليومي"
        }
    }

    private var firstTargetAfterLearningDayText: String {

        switch localization.language {
        case .hebrew:
            return "היעד הראשון ייקבע לאחר יום הלמידה."
        case .english:
            return "Your first target will be set after the learning day."
        case .arabic:
            return "سيتم تحديد هدفك الأول بعد يوم التعلّم."
        }
    }

    private var measuringNormallyText: String {

        switch localization.language {
        case .hebrew:
            return "בינתיים TimeUp מודד את זמן המסך שלך כרגיל."
        case .english:
            return "In the meantime, TimeUp measures your screen time as usual."
        case .arabic:
            return "في هذه الأثناء، يقيس TimeUp وقت الشاشة كالمعتاد."
        }
    }

    private var noDailyTargetText: String {

        switch localization.language {
        case .hebrew:
            return "עדיין לא נקבע יעד יומי."
        case .english:
            return "A daily target has not been set yet."
        case .arabic:
            return "لم يتم تحديد هدف يومي بعد."
        }
    }

    private var targetMeasurementStartText: String {

        switch localization.language {
        case .hebrew:
            return "TimeUp יתחיל למדוד את היעד ברגע שיוגדר."
        case .english:
            return "TimeUp will start tracking the target as soon as it is set."
        case .arabic:
            return "سيبدأ TimeUp بتتبع الهدف بمجرد تحديده."
        }
    }

    private var lastDaySummaryText: String {

        switch localization.language {
        case .hebrew:
            return "סיכום היום האחרון"
        case .english:
            return "Last day summary"
        case .arabic:
            return "ملخص اليوم الأخير"
        }
    }

    private var screenTimeText: String {

        switch localization.language {
        case .hebrew:
            return "זמן מסך"
        case .english:
            return "Screen time"
        case .arabic:
            return "وقت الشاشة"
        }
    }

    private var targetText: String {

        switch localization.language {
        case .hebrew:
            return "יעד"
        case .english:
            return "Target"
        case .arabic:
            return "الهدف"
        }
    }

    private var learningDayCompletedText: String {

        switch localization.language {
        case .hebrew:
            return "יום למידה הושלם"
        case .english:
            return "Learning day completed"
        case .arabic:
            return "اكتمل يوم التعلّم"
        }
    }

    private var targetAchievedText: String {

        switch localization.language {
        case .hebrew:
            return "עמדת ביעד"
        case .english:
            return "You met your target"
        case .arabic:
            return "حققت هدفك"
        }
    }

    private var targetNotAchievedText: String {

        switch localization.language {
        case .hebrew:
            return "היעד לא הושג"
        case .english:
            return "Target not achieved"
        case .arabic:
            return "لم يتم تحقيق الهدف"
        }
    }

    private var connectingText: String {

        switch localization.language {
        case .hebrew:
            return "מתחבר..."
        case .english:
            return "Connecting..."
        case .arabic:
            return "جارٍ الاتصال..."
        }
    }

    private var screenTimeConnectedText: String {

        switch localization.language {
        case .hebrew:
            return "זמן המסך מחובר"
        case .english:
            return "Screen Time connected"
        case .arabic:
            return "تم ربط وقت الشاشة"
        }
    }

    private var connectScreenTimeText: String {

        switch localization.language {
        case .hebrew:
            return "חבר את זמן המסך"
        case .english:
            return "Connect Screen Time"
        case .arabic:
            return "ربط وقت الشاشة"
        }
    }

    private var yourGroupText: String {

        switch localization.language {
        case .hebrew:
            return "הקבוצה שלך"
        case .english:
            return "Your group"
        case .arabic:
            return "مجموعتك"
        }
    }

    private var groupCodeText: String {

        switch localization.language {
        case .hebrew:
            return "קוד קבוצה: \(groupCode)"
        case .english:
            return "Group code: \(groupCode)"
        case .arabic:
            return "رمز المجموعة: \(groupCode)"
        }
    }

    private var learningText: String {

        switch localization.language {
        case .hebrew:
            return "למידה"
        case .english:
            return "Learning"
        case .arabic:
            return "تعلّم"
        }
    }

    private var successText: String {

        switch localization.language {
        case .hebrew:
            return "הצלחה"
        case .english:
            return "Success"
        case .arabic:
            return "نجاح"
        }
    }

    private var notAchievedText: String {

        switch localization.language {
        case .hebrew:
            return "לא הושג"
        case .english:
            return "Not met"
        case .arabic:
            return "لم يتحقق"
        }
    }

    private var screenTimeConnectedCheckText: String {

        switch localization.language {
        case .hebrew:
            return "זמן המסך מחובר ✓"
        case .english:
            return "Screen Time connected ✓"
        case .arabic:
            return "تم ربط وقت الشاشة ✓"
        }
    }

    private var screenTimeAccessDeniedText: String {

        switch localization.language {
        case .hebrew:
            return "הגישה לזמן המסך נדחתה"
        case .english:
            return "Screen Time access denied"
        case .arabic:
            return "تم رفض الوصول إلى وقت الشاشة"
        }
    }

    private var screenTimePermissionRequiredText: String {

        switch localization.language {
        case .hebrew:
            return "נדרש אישור לזמן מסך"
        case .english:
            return "Screen Time permission is required"
        case .arabic:
            return "مطلوب إذن للوصول إلى وقت الشاشة"
        }
    }

    private var unknownScreenTimeStatusText: String {

        switch localization.language {
        case .hebrew:
            return "סטטוס זמן מסך לא ידוע"
        case .english:
            return "Unknown Screen Time status"
        case .arabic:
            return "حالة وقت الشاشة غير معروفة"
        }
    }

    private var screenTimeMonitoringFailedText: String {

        switch localization.language {
        case .hebrew:
            return "לא ניתן להתחיל את מדידת זמן המסך"
        case .english:
            return "Unable to start Screen Time monitoring"
        case .arabic:
            return "تعذر بدء مراقبة وقت الشاشة"
        }
    }
}