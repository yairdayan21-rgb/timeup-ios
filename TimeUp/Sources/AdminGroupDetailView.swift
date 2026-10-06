import SwiftUI

struct AdminGroupDetailView: View {

    let group: SupabaseDataStore.TimeUpRemoteGroup

    @StateObject private var dataStore =
        SupabaseDataStore.shared

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    @State private var isRefreshing = false

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 24
            ) {

                // MARK: - Group Header

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    HStack {

                        VStack(
                            alignment: .leading,
                            spacing: 4
                        ) {

                            Text(group.name)
                                .font(
                                    .system(
                                        size: 30,
                                        weight: .bold,
                                        design: .rounded
                                    )
                                )

                            Text(groupCodeText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(
                            systemName: "person.3.fill"
                        )
                        .font(.title2)
                    }

                    Text(group.code)
                        .font(
                            .system(
                                size: 30,
                                weight: .bold,
                                design: .monospaced
                            )
                        )
                        .tracking(5)

                    Divider()

                    HStack {

                        Label(
                            goalDescription,
                            systemImage: "target"
                        )

                        Spacer()

                        Label(
                            "\(group.currentStreak)",
                            systemImage: "flame.fill"
                        )
                    }
                    .font(.subheadline)

                    Text(journeyText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 18
                    )
                )

                // MARK: - Settings

                NavigationLink {

                    GroupSettingsView(
                        group: group
                    )

                } label: {

                    HStack(spacing: 14) {

                        ZStack {

                            Circle()
                                .fill(.thinMaterial)
                                .frame(
                                    width: 46,
                                    height: 46
                                )

                            Image(
                                systemName:
                                    "gearshape.fill"
                            )
                            .foregroundStyle(.secondary)
                        }

                        VStack(
                            alignment: .leading,
                            spacing: 4
                        ) {

                            Text(groupSettingsTitle)
                                .fontWeight(.semibold)

                            Text(
                                groupSettingsDescription
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(
                            systemName: chevronName
                        )
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 16
                        )
                    )
                }
                .buttonStyle(.plain)

                // MARK: - Today's Group Status

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    HStack {

                        Text(todayGroupStatusTitle)
                            .font(.title3.bold())

                        Spacer()

                        if isRefreshing {
                            ProgressView()
                        }
                    }

                    if let todayGroupResult {

                        HStack(spacing: 12) {

                            Image(
                                systemName:
                                    todayGroupResult.succeeded
                                    ? "checkmark.circle.fill"
                                    : "xmark.circle.fill"
                            )
                            .font(.title2)

                            VStack(
                                alignment: .leading,
                                spacing: 3
                            ) {

                                Text(
                                    todayGroupResult.succeeded
                                    ? groupSucceededText
                                    : groupFailedText
                                )
                                .fontWeight(.semibold)

                                Text(
                                    completedMembersText(
                                        completed:
                                            todayGroupResult
                                                .completedMemberCount,
                                        total:
                                            todayGroupResult
                                                .memberCount
                                    )
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(
                                alignment: .trailing,
                                spacing: 3
                            ) {

                                Text(
                                    streakText(
                                        todayGroupResult
                                            .streakAfterDay
                                    )
                                )
                                .fontWeight(.semibold)

                                if let average =
                                    todayGroupResult
                                        .averageUsageMinutes {

                                    Text(
                                        averageText(
                                            average
                                        )
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }

                    } else {

                        HStack(spacing: 12) {

                            Image(
                                systemName: "clock.fill"
                            )
                            .font(.title2)

                            VStack(
                                alignment: .leading,
                                spacing: 3
                            ) {

                                Text(dayNotFinishedTitle)
                                    .fontWeight(.semibold)

                                Text(
                                    dayNotFinishedDescription
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 18
                    )
                )

                // MARK: - Members

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    HStack {

                        Text(groupMembersTitle)
                            .font(.title3.bold())

                        Spacer()

                        Text(
                            membersCountText(
                                dataStore.groupMembers.count
                            )
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    if isRefreshing &&
                        dataStore.groupMembers.isEmpty {

                        HStack {

                            Spacer()

                            ProgressView(
                                loadingMembersText
                            )

                            Spacer()
                        }
                        .padding(.vertical, 30)

                    } else if
                        dataStore.groupMembers.isEmpty {

                        ContentUnavailableView(
                            noMembersTitle,
                            systemImage: "person.3",
                            description:
                                Text(
                                    noMembersDescription
                                )
                        )
                        .frame(
                            maxWidth: .infinity
                        )
                        .padding(.vertical, 20)

                    } else {

                        ForEach(
                            dataStore.groupMembers
                        ) { member in

                            NavigationLink {

                                AdminMemberDetailView(
                                    group: group,
                                    member: member
                                )

                            } label: {

                                memberCard(member)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // MARK: - Error

                if let error =
                    dataStore.lastError {

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        Label(
                            unableToLoadGroupDataText,
                            systemImage:
                                "exclamationmark.triangle"
                        )
                        .fontWeight(.semibold)

                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button(retryText) {

                            Task {
                                await loadGroup()
                            }
                        }
                    }
                    .padding()
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .background(.thinMaterial)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 18
                        )
                    )
                }
            }
            .padding(20)
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await loadGroup()
        }
        .task {
            await loadGroup()
        }
    }

    // MARK: - Member Card

    private func memberCard(
        _ member:
            SupabaseDataStore.TimeUpRemoteUser
    ) -> some View {

        HStack(spacing: 14) {

            ZStack {

                Circle()
                    .fill(.thinMaterial)
                    .frame(
                        width: 46,
                        height: 46
                    )

                Image(
                    systemName: "person.fill"
                )
                .foregroundStyle(.secondary)
            }

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(
                    member.displayName ??
                    genericUserText
                )
                .fontWeight(.semibold)

                if member.role == "admin" {

                    Text(adminText)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                } else {

                    Text(groupMemberText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let result =
                todayResult(
                    for: member.id
                ) {

                VStack(
                    alignment: .trailing,
                    spacing: 3
                ) {

                    Text(
                        formatMinutes(
                            result.usageMinutes
                        )
                    )
                    .font(.subheadline.bold())

                    if result.isLearningDay {

                        Text(learningDayText)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                    } else if
                        result.achieved == true {

                        Label(
                            targetAchievedText,
                            systemImage:
                                "checkmark.circle.fill"
                        )
                        .font(.caption)

                    } else if
                        result.achieved == false {

                        Label(
                            exceededText,
                            systemImage:
                                "xmark.circle.fill"
                        )
                        .font(.caption)

                    } else {

                        Text(waitingText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

            } else {

                Text(waitingForDataText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Image(
                systemName: chevronName
            )
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }

    // MARK: - Today's Data

    private var todayGroupResult:
        SupabaseDataStore
            .TimeUpRemoteGroupDailyResult? {

        dataStore.groupDailyResults.first {
            $0.groupID == group.id &&
            $0.resultDate == todayDateKey
        }
    }

    private func todayResult(
        for userID: UUID
    ) -> SupabaseDataStore
        .TimeUpRemoteDailyResult? {

        dataStore.dailyResults.first {
            $0.groupID == group.id &&
            $0.userID == userID &&
            $0.resultDate == todayDateKey
        }
    }

    // MARK: - Load

    @MainActor
    private func loadGroup() async {

        isRefreshing = true

        await dataStore.loadGroupMembers(
            groupID: group.id
        )

        await dataStore.loadDailyProgress(
            groupID: group.id
        )

        isRefreshing = false
    }

    // MARK: - Date

    private var todayDateKey: String {

        let formatter =
            DateFormatter()

        formatter.calendar =
            Calendar(
                identifier: .gregorian
            )

        formatter.locale =
            Locale(
                identifier:
                    "en_US_POSIX"
            )

        formatter.timeZone =
            TimeZone(
                identifier:
                    group.timezone
            ) ??
            TimeZone(
                identifier:
                    "Asia/Jerusalem"
            ) ??
            .current

        formatter.dateFormat =
            "yyyy-MM-dd"

        return formatter.string(
            from: Date()
        )
    }

    // MARK: - Formatting

    private func formatMinutes(
        _ minutes: Int
    ) -> String {

        let hours =
            minutes / 60

        let remainingMinutes =
            minutes % 60

        switch localization.language {

        case .hebrew:

            if hours == 0 {
                return "\(remainingMinutes) דק׳"
            }

            if remainingMinutes == 0 {
                return "\(hours) שע׳"
            }

            return "\(hours) שע׳ \(remainingMinutes) דק׳"

        case .english:

            if hours == 0 {
                return "\(remainingMinutes) min"
            }

            if remainingMinutes == 0 {
                return "\(hours) hr"
            }

            return "\(hours) hr \(remainingMinutes) min"

        case .arabic:

            if hours == 0 {
                return "\(remainingMinutes) د"
            }

            if remainingMinutes == 0 {
                return "\(hours) س"
            }

            return "\(hours) س \(remainingMinutes) د"
        }
    }

    // MARK: - Goal

    private var goalDescription: String {

        switch group.goalMethod {

        case "personal_percentage":

            switch localization.language {

            case .hebrew:
                return "\(group.reductionPercent ?? 0)% פחות מהיום הקודם"

            case .english:
                return "\(group.reductionPercent ?? 0)% less than the previous day"

            case .arabic:
                return "أقل بنسبة \(group.reductionPercent ?? 0)% من اليوم السابق"
            }

        case "group_average_percentage":

            switch localization.language {

            case .hebrew:
                return "\(group.reductionPercent ?? 0)% פחות מהממוצע הקבוצתי"

            case .english:
                return "\(group.reductionPercent ?? 0)% less than the group average"

            case .arabic:
                return "أقل بنسبة \(group.reductionPercent ?? 0)% من متوسط المجموعة"
            }

        case "manual":

            switch localization.language {

            case .hebrew:
                return "יעד אישי לכל משתמש"

            case .english:
                return "Individual target for each user"

            case .arabic:
                return "هدف شخصي لكل مستخدم"
            }

        default:

            switch localization.language {

            case .hebrew:
                return "יעד קבוצה"

            case .english:
                return "Group target"

            case .arabic:
                return "هدف المجموعة"
            }
        }
    }

    // MARK: - Localization

    private var chevronName: String {
        localization.language == .english
            ? "chevron.right"
            : "chevron.left"
    }

    private var groupCodeText: String {
        switch localization.language {
        case .hebrew: return "קוד קבוצה"
        case .english: return "Group code"
        case .arabic: return "رمز المجموعة"
        }
    }

    private var journeyText: String {
        let days = group.successDays ?? 7

        switch localization.language {
        case .hebrew:
            return "מסלול של \(days) ימי הצלחה"
        case .english:
            return "A \(days)-day success journey"
        case .arabic:
            return "مسار نجاح لمدة \(days) أيام"
        }
    }

    private var groupSettingsTitle: String {
        switch localization.language {
        case .hebrew: return "הגדרות קבוצה"
        case .english: return "Group settings"
        case .arabic: return "إعدادات المجموعة"
        }
    }

    private var groupSettingsDescription: String {
        switch localization.language {
        case .hebrew:
            return "שם, שיטת יעד, אחוז הפחתה ומספר ימי הצלחה"
        case .english:
            return "Name, target method, reduction percentage and success days"
        case .arabic:
            return "الاسم، طريقة الهدف، نسبة التخفيض وعدد أيام النجاح"
        }
    }

    private var todayGroupStatusTitle: String {
        switch localization.language {
        case .hebrew: return "מצב הקבוצה היום"
        case .english: return "Group status today"
        case .arabic: return "حالة المجموعة اليوم"
        }
    }

    private var groupSucceededText: String {
        switch localization.language {
        case .hebrew: return "הקבוצה עמדה ביעד"
        case .english: return "The group achieved its target"
        case .arabic: return "حققت المجموعة هدفها"
        }
    }

    private var groupFailedText: String {
        switch localization.language {
        case .hebrew: return "הקבוצה לא עמדה ביעד"
        case .english: return "The group missed its target"
        case .arabic: return "لم تحقق المجموعة هدفها"
        }
    }

    private func completedMembersText(
        completed: Int,
        total: Int
    ) -> String {

        switch localization.language {
        case .hebrew:
            return "\(completed) מתוך \(total) חברים השלימו"
        case .english:
            return "\(completed) of \(total) members completed"
        case .arabic:
            return "أكمل \(completed) من أصل \(total) أعضاء"
        }
    }

    private func streakText(
        _ streak: Int
    ) -> String {

        switch localization.language {
        case .hebrew: return "רצף \(streak)"
        case .english: return "Streak \(streak)"
        case .arabic: return "السلسلة \(streak)"
        }
    }

    private func averageText(
        _ average: Int
    ) -> String {

        switch localization.language {
        case .hebrew:
            return "ממוצע \(formatMinutes(average))"
        case .english:
            return "Average \(formatMinutes(average))"
        case .arabic:
            return "المتوسط \(formatMinutes(average))"
        }
    }

    private var dayNotFinishedTitle: String {
        switch localization.language {
        case .hebrew: return "היום עדיין לא הסתיים"
        case .english: return "Today is not finished yet"
        case .arabic: return "اليوم لم ينتهِ بعد"
        }
    }

    private var dayNotFinishedDescription: String {
        switch localization.language {
        case .hebrew:
            return "התוצאה הקבוצתית תיסגר אוטומטית לאחר שכל נתוני היום יתקבלו."
        case .english:
            return "The group result will be finalized automatically after all of today's data is received."
        case .arabic:
            return "سيتم إنهاء نتيجة المجموعة تلقائيًا بعد استلام جميع بيانات اليوم."
        }
    }

    private var groupMembersTitle: String {
        switch localization.language {
        case .hebrew: return "חברי הקבוצה"
        case .english: return "Group members"
        case .arabic: return "أعضاء المجموعة"
        }
    }

    private func membersCountText(
        _ count: Int
    ) -> String {

        switch localization.language {
        case .hebrew:
            return "\(count) חברים"
        case .english:
            return count == 1
                ? "1 member"
                : "\(count) members"
        case .arabic:
            return "\(count) أعضاء"
        }
    }

    private var loadingMembersText: String {
        switch localization.language {
        case .hebrew: return "טוען חברים..."
        case .english: return "Loading members..."
        case .arabic: return "جارٍ تحميل الأعضاء..."
        }
    }

    private var noMembersTitle: String {
        switch localization.language {
        case .hebrew: return "אין חברים בקבוצה"
        case .english: return "No members in the group"
        case .arabic: return "لا يوجد أعضاء في المجموعة"
        }
    }

    private var noMembersDescription: String {
        switch localization.language {
        case .hebrew:
            return "כאשר משתמשים יצטרפו לקבוצה הם יופיעו כאן."
        case .english:
            return "Users will appear here when they join the group."
        case .arabic:
            return "سيظهر المستخدمون هنا عند انضمامهم إلى المجموعة."
        }
    }

    private var unableToLoadGroupDataText: String {
        switch localization.language {
        case .hebrew: return "לא ניתן לטעון את נתוני הקבוצה"
        case .english: return "Unable to load group data"
        case .arabic: return "تعذر تحميل بيانات المجموعة"
        }
    }

    private var retryText: String {
        switch localization.language {
        case .hebrew: return "נסה שוב"
        case .english: return "Try again"
        case .arabic: return "حاول مرة أخرى"
        }
    }

    private var genericUserText: String {
        switch localization.language {
        case .hebrew: return "משתמש"
        case .english: return "User"
        case .arabic: return "مستخدم"
        }
    }

    private var adminText: String {
        switch localization.language {
        case .hebrew: return "מנהל"
        case .english: return "Admin"
        case .arabic: return "مدير"
        }
    }

    private var groupMemberText: String {
        switch localization.language {
        case .hebrew: return "חבר קבוצה"
        case .english: return "Group member"
        case .arabic: return "عضو المجموعة"
        }
    }

    private var learningDayText: String {
        switch localization.language {
        case .hebrew: return "יום למידה"
        case .english: return "Learning day"
        case .arabic: return "يوم تعلّم"
        }
    }

    private var targetAchievedText: String {
        switch localization.language {
        case .hebrew: return "עמד ביעד"
        case .english: return "Target achieved"
        case .arabic: return "حقق الهدف"
        }
    }

    private var exceededText: String {
        switch localization.language {
        case .hebrew: return "חריגה"
        case .english: return "Exceeded"
        case .arabic: return "تجاوز الهدف"
        }
    }

    private var waitingText: String {
        switch localization.language {
        case .hebrew: return "ממתין"
        case .english: return "Pending"
        case .arabic: return "قيد الانتظار"
        }
    }

    private var waitingForDataText: String {
        switch localization.language {
        case .hebrew: return "ממתין לנתונים"
        case .english: return "Waiting for data"
        case .arabic: return "في انتظار البيانات"
        }
    }
}