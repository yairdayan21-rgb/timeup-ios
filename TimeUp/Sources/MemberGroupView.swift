import SwiftUI

struct MemberGroupView: View {

    @StateObject private var dataStore =
        SupabaseDataStore.shared

    @StateObject private var chatStore =
        SupabaseChatStore.shared

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    @State private var selectedSection:
        GroupSection = .overview

    private enum GroupSection:
        CaseIterable {

        case overview
        case detail
        case dashboard
        case members
        case chat
    }

    private var group:
        SupabaseDataStore.TimeUpRemoteGroup? {

        dataStore.activeMemberGroup
    }

    private var currentUser:
        SupabaseDataStore.TimeUpRemoteUser? {

        dataStore.currentUser
    }

    private var unreadChatCount: Int {

        guard let group else {
            return 0
        }

        return chatStore.unreadCount(
            for: group.id
        )
    }

    var body: some View {

        Group {

            if let group {

                VStack(spacing: 0) {

                    sectionPicker

                    Divider()

                    Group {

                        switch selectedSection {

                        case .overview:

                            overviewView(
                                group: group
                            )

                        case .detail:

                            groupDetailView(
                                group: group
                            )

                        case .dashboard:

                            dashboardView(
                                group: group
                            )

                        case .members:

                            membersView(
                                group: group
                            )

                        case .chat:

                            MemberGroupChatView(
                                group: group
                            )
                        }
                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                }
                .navigationTitle(
                    group.name
                )
                .navigationBarTitleDisplayMode(
                    .inline
                )
                .task {

                    await loadGroup(
                        group: group
                    )
                }
                .refreshable {

                    await loadGroup(
                        group: group
                    )
                }

            } else {

                ContentUnavailableView(
                    noGroupTitle,
                    systemImage: "person.3",
                    description:
                        Text(
                            noGroupDescription
                        )
                )
            }
        }
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {

        ScrollView(
            .horizontal,
            showsIndicators: false
        ) {

            HStack(spacing: 8) {

                ForEach(
                    GroupSection.allCases,
                    id: \.self
                ) { section in

                    Button {

                        withAnimation(
                            .easeInOut(
                                duration: 0.18
                            )
                        ) {

                            selectedSection =
                                section
                        }

                    } label: {

                        HStack(spacing: 6) {

                            Text(
                                sectionTitle(
                                    section
                                )
                            )

                            if section == .chat &&
                                unreadChatCount > 0 {

                                Text(
                                    unreadChatCount > 99
                                        ? "99+"
                                        : "\(unreadChatCount)"
                                )
                                .font(
                                    .caption2.bold()
                                )
                                .foregroundStyle(
                                    .white
                                )
                                .padding(
                                    .horizontal,
                                    6
                                )
                                .padding(
                                    .vertical,
                                    2
                                )
                                .background {

                                    Capsule()
                                        .fill(
                                            Color.red
                                        )
                                }
                            }
                        }
                        .font(.subheadline)
                        .fontWeight(
                            selectedSection == section
                                ? .bold
                                : .medium
                        )
                        .padding(
                            .horizontal,
                            14
                        )
                        .padding(
                            .vertical,
                            9
                        )
                        .background {

                            if selectedSection ==
                                section {

                                Capsule()
                                    .fill(
                                        Color.accentColor
                                    )

                            } else {

                                Capsule()
                                    .fill(
                                        Color.secondary
                                            .opacity(0.12)
                                    )
                            }
                        }
                        .foregroundStyle(
                            selectedSection == section
                                ? Color.white
                                : Color.primary
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(
                .horizontal,
                16
            )
            .padding(
                .vertical,
                10
            )
        }
    }

    // MARK: - Overview

    private func overviewView(
        group:
            SupabaseDataStore.TimeUpRemoteGroup
    ) -> some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 20
            ) {

                groupHeader(
                    group: group
                )

                groupStreakCard(
                    group: group
                )

                journeyCard(
                    group: group
                )

                todayStatusCard(
                    group: group
                )

                membersPreview(
                    group: group
                )

                if let error =
                    dataStore.lastError {

                    errorCard(error)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Header

    private func groupHeader(
        group:
            SupabaseDataStore.TimeUpRemoteGroup
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text(group.name)
                .font(.largeTitle)
                .fontWeight(.bold)

            HStack(spacing: 6) {

                Image(
                    systemName:
                        "person.3.fill"
                )

                Text(
                    membersCountText(
                        memberCount
                    )
                )
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    // MARK: - Group Streak

    private func groupStreakCard(
        group:
            SupabaseDataStore.TimeUpRemoteGroup
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text(
                        groupStreakTitle
                    )
                    .font(.headline)

                    Text(
                        daysText(
                            group.currentStreak
                        )
                    )
                    .font(
                        .system(
                            size: 34,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                }

                Spacer()

                Image(
                    systemName: "flame.fill"
                )
                .font(
                    .system(size: 40)
                )
                .foregroundStyle(.orange)
            }

            Text(
                group.currentStreak == 0
                    ? streakStartDescription
                    : streakContinueDescription
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(18)
        .background {

            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
            .fill(
                Color.secondary
                    .opacity(0.10)
            )
        }
    }

    // MARK: - Journey

    private func journeyCard(
        group:
            SupabaseDataStore.TimeUpRemoteGroup
    ) -> some View {

        let successDays =
            max(
                group.successDays ?? 7,
                1
            )

        let streak =
            group.currentStreak

        return VStack(
            alignment: .leading,
            spacing: 16
        ) {

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text(
                        groupJourneyTitle
                    )
                    .font(.headline)

                    Text(
                        journeySubtitle(
                            streak: streak,
                            successDays:
                                successDays
                        )
                    )
                    .font(.subheadline)
                    .foregroundStyle(
                        .secondary
                    )
                }

                Spacer()

                Text(
                    "\(min(streak, successDays))/\(successDays)"
                )
                .font(.headline)
                .monospacedDigit()
            }

            ProgressView(
                value: Double(
                    min(
                        streak,
                        successDays
                    )
                ),
                total: Double(
                    successDays
                )
            )

            LazyVGrid(
                columns: [
                    GridItem(
                        .adaptive(
                            minimum: 42,
                            maximum: 48
                        ),
                        spacing: 10
                    )
                ],
                spacing: 10
            ) {

                ForEach(
                    1...successDays,
                    id: \.self
                ) { day in

                    ZStack {

                        Circle()
                            .fill(
                                day <= streak
                                    ? Color.accentColor
                                    : Color.secondary
                                        .opacity(0.14)
                            )
                            .frame(
                                width: 42,
                                height: 42
                            )

                        if day <= streak {

                            Image(
                                systemName:
                                    "checkmark"
                            )
                            .fontWeight(.bold)
                            .foregroundStyle(
                                .white
                            )

                        } else {

                            Text("\(day)")
                                .font(
                                    .subheadline
                                )
                                .fontWeight(
                                    .semibold
                                )
                                .foregroundStyle(
                                    .secondary
                                )
                        }
                    }
                }
            }
        }
        .padding(18)
        .background {

            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
            .fill(
                Color.secondary
                    .opacity(0.10)
            )
        }
    }

    private func journeySubtitle(
        streak: Int,
        successDays: Int
    ) -> String {

        if streak >= successDays {

            switch localization.language {

            case .hebrew:
                return "הקבוצה השלימה את היעד"

            case .english:
                return "The group completed the goal"

            case .arabic:
                return "أكملت المجموعة الهدف"
            }

        } else {

            let remaining =
                max(
                    successDays - streak,
                    0
                )

            switch localization.language {

            case .hebrew:
                return "עוד \(remaining) ימים להשלמת היעד"

            case .english:
                return remaining == 1
                    ? "1 more day to complete the goal"
                    : "\(remaining) more days to complete the goal"

            case .arabic:
                return "متبقي \(remaining) أيام لإكمال الهدف"
            }
        }
    }

    // MARK: - Today

    private func todayStatusCard(
        group:
            SupabaseDataStore.TimeUpRemoteGroup
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack {

                Text(
                    todayInGroupTitle
                )
                .font(.headline)

                Spacer()

                Text(
                    Date.now.formatted(
                        .dateTime
                            .day()
                            .month()
                            .locale(
                                localization
                                    .language
                                    .locale
                            )
                    )
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Divider()

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text(
                        groupMembersTitle
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )

                    Text(
                        "\(memberCount)"
                    )
                    .font(.title2)
                    .fontWeight(.bold)
                }

                Spacer()

                VStack(
                    alignment: .trailing,
                    spacing: 4
                ) {

                    Text(
                        currentStreakTitle
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )

                    Text(
                        "\(group.currentStreak)"
                    )
                    .font(.title2)
                    .fontWeight(.bold)
                }
            }

            if let result =
                todayGroupResult(
                    group: group
                ) {

                Divider()

                HStack(
                    spacing: 10
                ) {

                    Image(
                        systemName:
                            result.succeeded
                                ? "checkmark.circle.fill"
                                : "xmark.circle.fill"
                    )

                    Text(
                        result.succeeded
                            ? groupSucceededTodayText
                            : groupFailedTodayText
                    )
                    .font(.footnote)
                }

            } else {

                Text(
                    pendingResultText
                )
                .font(.footnote)
                .foregroundStyle(
                    .secondary
                )
            }
        }
        .padding(18)
        .background {

            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
            .fill(
                Color.secondary
                    .opacity(0.10)
            )
        }
    }

    // MARK: - Members Preview

    private func membersPreview(
        group:
            SupabaseDataStore.TimeUpRemoteGroup
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack {

                Text(
                    groupMembersTitle
                )
                .font(.headline)

                Spacer()

                Button(
                    showAllText
                ) {

                    selectedSection =
                        .members
                }
                .font(.subheadline)
            }

            if dataStore.groupMembers.isEmpty {

                if dataStore.isLoadingGroupMembers {

                    HStack {

                        Spacer()

                        ProgressView()

                        Spacer()
                    }
                    .padding()

                } else {

                    ContentUnavailableView(
                        noMembersTitle,
                        systemImage:
                            "person.3"
                    )
                }

            } else {

                ForEach(
                    Array(
                        dataStore
                            .groupMembers
                            .prefix(4)
                    )
                ) { member in

                    HStack(
                        spacing: 12
                    ) {

                        Image(
                            systemName:
                                "person.crop.circle.fill"
                        )
                        .font(
                            .system(size: 34)
                        )
                        .foregroundStyle(
                            .secondary
                        )

                        VStack(
                            alignment: .leading,
                            spacing: 2
                        ) {

                            Text(
                                member
                                    .displayName ??
                                genericUserText
                            )
                            .fontWeight(
                                .semibold
                            )

                            if member.id ==
                                currentUser?.id {

                                Text(
                                    youText
                                )
                                .font(
                                    .caption
                                )
                                .foregroundStyle(
                                    .secondary
                                )
                            }
                        }

                        Spacer()
                    }

                    if member.id !=
                        dataStore
                            .groupMembers
                            .prefix(4)
                            .last?
                            .id {

                        Divider()
                    }
                }
            }
        }
        .padding(18)
        .background {

            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
            .fill(
                Color.secondary
                    .opacity(0.10)
            )
        }
    }

    // MARK: - Detail

    private func groupDetailView(
        group:
            SupabaseDataStore.TimeUpRemoteGroup
    ) -> some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 16
            ) {

                Text(
                    groupDetailTitle
                )
                .font(.title2.bold())

                if dataStore
                    .dailyResults
                    .isEmpty {

                    ContentUnavailableView(
                        noDataTitle,
                        systemImage:
                            "chart.bar.doc.horizontal",
                        description:
                            Text(
                                noDataDescription
                            )
                    )

                } else {

                    ForEach(
                        dataStore
                            .groupMembers
                    ) { member in

                        memberProgressCard(
                            member: member,
                            group: group
                        )
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: - Dashboard

    private func dashboardView(
        group:
            SupabaseDataStore.TimeUpRemoteGroup
    ) -> some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 18
            ) {

                Text(
                    dashboardTitle
                )
                .font(.title2.bold())

                dashboardCard(
                    title:
                        groupStreakTitle,
                    value:
                        "\(group.currentStreak)",
                    subtitle:
                        daysLabel
                )

                dashboardCard(
                    title:
                        groupMembersTitle,
                    value:
                        "\(memberCount)",
                    subtitle:
                        usersLabel
                )

                dashboardCard(
                    title:
                        successDaysTitle,
                    value:
                        "\(group.successDays ?? 7)",
                    subtitle:
                        journeyGoalSubtitle
                )

                if let latest =
                    dataStore
                        .groupDailyResults
                        .first {

                    dashboardCard(
                        title:
                            averageUsageTitle,
                        value:
                            formatMinutes(
                                latest
                                    .averageUsageMinutes ??
                                0
                            ),
                        subtitle:
                            lastClosedDaySubtitle
                    )
                }
            }
            .padding(16)
        }
    }

    private func dashboardCard(
        title: String,
        value: String,
        subtitle: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text(title)
                .font(.headline)

            Text(value)
                .font(
                    .system(
                        size: 32,
                        weight: .bold,
                        design: .rounded
                    )
                )

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(18)
        .background {

            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
            .fill(
                Color.secondary
                    .opacity(0.10)
            )
        }
    }

    // MARK: - Members

    private func membersView(
        group:
            SupabaseDataStore.TimeUpRemoteGroup
    ) -> some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 12
            ) {

                Text(
                    membersSectionTitle
                )
                .font(.title2.bold())

                ForEach(
                    dataStore.groupMembers
                ) { member in

                    memberProgressCard(
                        member: member,
                        group: group
                    )
                }
            }
            .padding(16)
        }
    }

    // MARK: - Member Progress

    private func memberProgressCard(
        member:
            SupabaseDataStore.TimeUpRemoteUser,
        group:
            SupabaseDataStore.TimeUpRemoteGroup
    ) -> some View {

        let result =
            todayResult(
                for: member.id,
                group: group
            )

        return HStack(
            spacing: 12
        ) {

            Image(
                systemName:
                    "person.crop.circle.fill"
            )
            .font(
                .system(size: 36)
            )
            .foregroundStyle(.secondary)

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                HStack(
                    spacing: 5
                ) {

                    Text(
                        member.displayName ??
                        genericUserText
                    )
                    .fontWeight(.semibold)

                    if member.id ==
                        currentUser?.id {

                        Text(
                            "• \(youText)"
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )
                    }
                }

                if let result {

                    if result.isLearningDay {

                        Text(
                            "\(formatMinutes(result.usageMinutes)) • \(learningDayText)"
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )

                    } else {

                        Text(
                            result.targetMinutes.map {
                                "\(formatMinutes(result.usageMinutes)) / \(formatMinutes($0))"
                            } ??
                            formatMinutes(
                                result.usageMinutes
                            )
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )
                    }

                } else {

                    Text(
                        waitingForTodayDataText
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                }
            }

            Spacer()

            if let result {

                if result.isLearningDay {

                    Image(
                        systemName: "clock.fill"
                    )
                    .foregroundStyle(
                        .secondary
                    )

                } else if
                    result.achieved == true {

                    Image(
                        systemName:
                            "checkmark.circle.fill"
                    )
                    .foregroundStyle(
                        .green
                    )

                } else if
                    result.achieved == false {

                    Image(
                        systemName:
                            "xmark.circle.fill"
                    )
                    .foregroundStyle(
                        .red
                    )
                }
            }
        }
        .padding(14)
        .background {

            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .fill(
                Color.secondary
                    .opacity(0.10)
            )
        }
    }

    // MARK: - Data Helpers

    private var memberCount: Int {

        dataStore.groupMembers.count
    }

    private func todayResult(
        for userID: UUID,
        group:
            SupabaseDataStore.TimeUpRemoteGroup
    ) -> SupabaseDataStore.TimeUpRemoteDailyResult? {

        dataStore.dailyResults.first {
            $0.groupID == group.id &&
            $0.userID == userID &&
            $0.resultDate ==
                todayDateKey(
                    group: group
                )
        }
    }

    private func todayGroupResult(
        group:
            SupabaseDataStore.TimeUpRemoteGroup
    ) -> SupabaseDataStore.TimeUpRemoteGroupDailyResult? {

        dataStore
            .groupDailyResults
            .first {
                $0.groupID == group.id &&
                $0.resultDate ==
                    todayDateKey(
                        group: group
                    )
            }
    }

    // MARK: - Load

    @MainActor
    private func loadGroup(
        group:
            SupabaseDataStore.TimeUpRemoteGroup
    ) async {

        await dataStore.loadGroupMembers(
            groupID: group.id
        )

        await dataStore.loadDailyProgress(
            groupID: group.id
        )

        guard let currentUser else {
            return
        }

        await chatStore.startUnreadRealtime(
            groupID: group.id,
            currentUserID: currentUser.id
        )
    }

    // MARK: - Date

    private func todayDateKey(
        group:
            SupabaseDataStore.TimeUpRemoteGroup
    ) -> String {

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

        let remaining =
            minutes % 60

        switch localization.language {

        case .hebrew:

            if hours == 0 {
                return "\(remaining) דק׳"
            }

            if remaining == 0 {
                return "\(hours) שע׳"
            }

            return
                "\(hours) שע׳ \(remaining) דק׳"

        case .english:

            if hours == 0 {
                return "\(remaining) min"
            }

            if remaining == 0 {
                return "\(hours) hr"
            }

            return
                "\(hours) hr \(remaining) min"

        case .arabic:

            if hours == 0 {
                return "\(remaining) د"
            }

            if remaining == 0 {
                return "\(hours) س"
            }

            return
                "\(hours) س \(remaining) د"
        }
    }

    // MARK: - Error

    private func errorCard(
        _ error: String
    ) -> some View {

        Label(
            error,
            systemImage:
                "exclamationmark.triangle.fill"
        )
        .font(.footnote)
        .foregroundStyle(.red)
        .padding()
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background {

            RoundedRectangle(
                cornerRadius: 14
            )
            .fill(
                Color.red.opacity(0.08)
            )
        }
    }

    // MARK: - Localization

    private func sectionTitle(
        _ section: GroupSection
    ) -> String {

        switch localization.language {

        case .hebrew:

            switch section {
            case .overview:
                return "סקירה"
            case .detail:
                return "פירוט"
            case .dashboard:
                return "לוח בקרה"
            case .members:
                return "חברים"
            case .chat:
                return "צ׳אט"
            }

        case .english:

            switch section {
            case .overview:
                return "Overview"
            case .detail:
                return "Details"
            case .dashboard:
                return "Dashboard"
            case .members:
                return "Members"
            case .chat:
                return "Chat"
            }

        case .arabic:

            switch section {
            case .overview:
                return "نظرة عامة"
            case .detail:
                return "التفاصيل"
            case .dashboard:
                return "لوحة التحكم"
            case .members:
                return "الأعضاء"
            case .chat:
                return "الدردشة"
            }
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

    private func daysText(
        _ count: Int
    ) -> String {

        switch localization.language {

        case .hebrew:
            return "\(count) ימים"

        case .english:
            return count == 1
                ? "1 day"
                : "\(count) days"

        case .arabic:
            return "\(count) أيام"
        }
    }

    private var noGroupTitle: String {
        switch localization.language {
        case .hebrew:
            return "לא נמצאה קבוצה"
        case .english:
            return "Group Not Found"
        case .arabic:
            return "لم يتم العثور على مجموعة"
        }
    }

    private var noGroupDescription: String {
        switch localization.language {
        case .hebrew:
            return "לא נמצאה חברות פעילה בקבוצה."
        case .english:
            return "No active group membership was found."
        case .arabic:
            return "لم يتم العثور على عضوية نشطة في المجموعة."
        }
    }

    private var groupStreakTitle: String {
        switch localization.language {
        case .hebrew:
            return "רצף קבוצתי"
        case .english:
            return "Group Streak"
        case .arabic:
            return "سلسلة المجموعة"
        }
    }

    private var streakStartDescription: String {
        switch localization.language {
        case .hebrew:
            return "הרצף מתחיל כאשר כל חברי הקבוצה עומדים ביעד."
        case .english:
            return "The streak starts when every group member reaches their goal."
        case .arabic:
            return "تبدأ السلسلة عندما يحقق جميع أعضاء المجموعة هدفهم."
        }
    }

    private var streakContinueDescription: String {
        switch localization.language {
        case .hebrew:
            return "כל חברי הקבוצה צריכים לעמוד ביעד כדי להמשיך את הרצף."
        case .english:
            return "Every group member must reach their goal to keep the streak going."
        case .arabic:
            return "يجب على جميع أعضاء المجموعة تحقيق هدفهم لمواصلة السلسلة."
        }
    }

    private var groupJourneyTitle: String {
        switch localization.language {
        case .hebrew:
            return "המסע הקבוצתי"
        case .english:
            return "Group Journey"
        case .arabic:
            return "رحلة المجموعة"
        }
    }

    private var todayInGroupTitle: String {
        switch localization.language {
        case .hebrew:
            return "היום בקבוצה"
        case .english:
            return "Today in the Group"
        case .arabic:
            return "اليوم في المجموعة"
        }
    }

    private var groupMembersTitle: String {
        switch localization.language {
        case .hebrew:
            return "חברי הקבוצה"
        case .english:
            return "Group Members"
        case .arabic:
            return "أعضاء المجموعة"
        }
    }

    private var currentStreakTitle: String {
        switch localization.language {
        case .hebrew:
            return "רצף נוכחי"
        case .english:
            return "Current Streak"
        case .arabic:
            return "السلسلة الحالية"
        }
    }

    private var groupSucceededTodayText: String {
        switch localization.language {
        case .hebrew:
            return "כל חברי הקבוצה עמדו ביעד."
        case .english:
            return "Every group member reached their goal."
        case .arabic:
            return "حقق جميع أعضاء المجموعة هدفهم."
        }
    }

    private var groupFailedTodayText: String {
        switch localization.language {
        case .hebrew:
            return "הקבוצה לא עמדה היום ביעד."
        case .english:
            return "The group did not reach today's goal."
        case .arabic:
            return "لم تحقق المجموعة هدف اليوم."
        }
    }

    private var pendingResultText: String {
        switch localization.language {
        case .hebrew:
            return "תוצאת היום תיסגר אוטומטית לאחר שכל נתוני השימוש יתקבלו."
        case .english:
            return "Today's result will close automatically after all usage data is received."
        case .arabic:
            return "سيتم إغلاق نتيجة اليوم تلقائيًا بعد استلام جميع بيانات الاستخدام."
        }
    }

    private var showAllText: String {
        switch localization.language {
        case .hebrew:
            return "הצג הכל"
        case .english:
            return "Show All"
        case .arabic:
            return "عرض الكل"
        }
    }

    private var noMembersTitle: String {
        switch localization.language {
        case .hebrew:
            return "אין חברים בקבוצה"
        case .english:
            return "No Group Members"
        case .arabic:
            return "لا يوجد أعضاء في المجموعة"
        }
    }

    private var genericUserText: String {
        switch localization.language {
        case .hebrew:
            return "משתמש"
        case .english:
            return "User"
        case .arabic:
            return "مستخدم"
        }
    }

    private var youText: String {
        switch localization.language {
        case .hebrew:
            return "אתה"
        case .english:
            return "You"
        case .arabic:
            return "أنت"
        }
    }

    private var groupDetailTitle: String {
        switch localization.language {
        case .hebrew:
            return "פירוט קבוצתי"
        case .english:
            return "Group Details"
        case .arabic:
            return "تفاصيل المجموعة"
        }
    }

    private var noDataTitle: String {
        switch localization.language {
        case .hebrew:
            return "אין עדיין נתונים"
        case .english:
            return "No Data Yet"
        case .arabic:
            return "لا توجد بيانات بعد"
        }
    }

    private var noDataDescription: String {
        switch localization.language {
        case .hebrew:
            return "נתוני השימוש של חברי הקבוצה יופיעו כאן."
        case .english:
            return "Group members' usage data will appear here."
        case .arabic:
            return "ستظهر بيانات استخدام أعضاء المجموعة هنا."
        }
    }

    private var dashboardTitle: String {
        switch localization.language {
        case .hebrew:
            return "לוח בקרה"
        case .english:
            return "Dashboard"
        case .arabic:
            return "لوحة التحكم"
        }
    }

    private var daysLabel: String {
        switch localization.language {
        case .hebrew:
            return "ימים"
        case .english:
            return "days"
        case .arabic:
            return "أيام"
        }
    }

    private var usersLabel: String {
        switch localization.language {
        case .hebrew:
            return "משתמשים"
        case .english:
            return "users"
        case .arabic:
            return "مستخدمون"
        }
    }

    private var successDaysTitle: String {
        switch localization.language {
        case .hebrew:
            return "ימי הצלחה"
        case .english:
            return "Success Days"
        case .arabic:
            return "أيام النجاح"
        }
    }

    private var journeyGoalSubtitle: String {
        switch localization.language {
        case .hebrew:
            return "יעד המסע"
        case .english:
            return "journey goal"
        case .arabic:
            return "هدف الرحلة"
        }
    }

    private var averageUsageTitle: String {
        switch localization.language {
        case .hebrew:
            return "ממוצע שימוש"
        case .english:
            return "Average Usage"
        case .arabic:
            return "متوسط الاستخدام"
        }
    }

    private var lastClosedDaySubtitle: String {
        switch localization.language {
        case .hebrew:
            return "ביום האחרון שנסגר"
        case .english:
            return "on the last completed day"
        case .arabic:
            return "في آخر يوم مكتمل"
        }
    }

    private var membersSectionTitle: String {
        switch localization.language {
        case .hebrew:
            return "חברים"
        case .english:
            return "Members"
        case .arabic:
            return "الأعضاء"
        }
    }

    private var learningDayText: String {
        switch localization.language {
        case .hebrew:
            return "יום למידה"
        case .english:
            return "Learning Day"
        case .arabic:
            return "يوم التعلّم"
        }
    }

    private var waitingForTodayDataText: String {
        switch localization.language {
        case .hebrew:
            return "ממתין לנתוני היום"
        case .english:
            return "Waiting for today's data"
        case .arabic:
            return "بانتظار بيانات اليوم"
        }
    }
}