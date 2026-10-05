import SwiftUI

struct MemberGroupView: View {

    @StateObject private var dataStore =
        SupabaseDataStore.shared

    @StateObject private var chatStore =
        SupabaseChatStore.shared

    @State private var selectedSection:
        GroupSection = .overview

    private enum GroupSection:
        String,
        CaseIterable {

        case overview = "סקירה"
        case detail = "פירוט"
        case dashboard = "Dashboard"
        case members = "חברים"
        case chat = "צ׳אט"
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
                    "לא נמצאה קבוצה",
                    systemImage: "person.3",
                    description: Text(
                        "לא נמצאה חברות פעילה בקבוצה."
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
                                section.rawValue
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
                    "\(memberCount) חברים"
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

                    Text("רצף קבוצתי")
                        .font(.headline)

                    Text(
                        "\(group.currentStreak) ימים"
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
                    ? "הרצף מתחיל כאשר כל חברי הקבוצה עומדים ביעד."
                    : "כל חברי הקבוצה צריכים לעמוד ביעד כדי להמשיך את הרצף."
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

                    Text("המסע הקבוצתי")
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

            return
                "הקבוצה השלימה את היעד"

        } else {

            let remaining =
                max(
                    successDays - streak,
                    0
                )

            return
                "עוד \(remaining) ימים להשלמת היעד"
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

                Text("היום בקבוצה")
                    .font(.headline)

                Spacer()

                Text(
                    Date.now,
                    format:
                        .dateTime
                        .day()
                        .month()
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

                    Text("חברי קבוצה")
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

                    Text("רצף נוכחי")
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
                            ? "כל חברי הקבוצה עמדו ביעד."
                            : "הקבוצה לא עמדה היום ביעד."
                    )
                    .font(.footnote)
                }

            } else {

                Text(
                    "תוצאת היום תיסגר אוטומטית לאחר שכל נתוני השימוש יתקבלו."
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

                Text("חברי הקבוצה")
                    .font(.headline)

                Spacer()

                Button("הצג הכל") {

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
                        "אין חברים בקבוצה",
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
                                "משתמש"
                            )
                            .fontWeight(
                                .semibold
                            )

                            if member.id ==
                                currentUser?.id {

                                Text("אתה")
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

                Text("פירוט קבוצתי")
                    .font(.title2.bold())

                if dataStore
                    .dailyResults
                    .isEmpty {

                    ContentUnavailableView(
                        "אין עדיין נתונים",
                        systemImage:
                            "chart.bar.doc.horizontal",
                        description: Text(
                            "נתוני השימוש של חברי הקבוצה יופיעו כאן."
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

                Text("Dashboard")
                    .font(.title2.bold())

                dashboardCard(
                    title: "רצף קבוצתי",
                    value:
                        "\(group.currentStreak)",
                    subtitle: "ימים"
                )

                dashboardCard(
                    title: "חברי הקבוצה",
                    value:
                        "\(memberCount)",
                    subtitle:
                        "משתמשים"
                )

                dashboardCard(
                    title: "ימי הצלחה",
                    value:
                        "\(group.successDays ?? 7)",
                    subtitle:
                        "יעד המסע"
                )

                if let latest =
                    dataStore
                        .groupDailyResults
                        .first {

                    dashboardCard(
                        title:
                            "ממוצע שימוש",
                        value:
                            formatMinutes(
                                latest
                                    .averageUsageMinutes ??
                                0
                            ),
                        subtitle:
                            "ביום האחרון שנסגר"
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

                Text("חברים")
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
                        "משתמש"
                    )
                    .fontWeight(.semibold)

                    if member.id ==
                        currentUser?.id {

                        Text("• אתה")
                            .font(.caption)
                            .foregroundStyle(
                                .secondary
                            )
                    }
                }

                if let result {

                    if result.isLearningDay {

                        Text(
                            "\(formatMinutes(result.usageMinutes)) • יום למידה"
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
                        "ממתין לנתוני היום"
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

        await chatStore.loadUnreadCount(
            groupID: group.id,
            userID: currentUser.id
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

        if hours == 0 {

            return
                "\(remaining) דק׳"
        }

        if remaining == 0 {

            return
                "\(hours) שע׳"
        }

        return
            "\(hours) שע׳ \(remaining) דק׳"
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
}