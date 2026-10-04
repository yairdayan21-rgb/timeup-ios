import SwiftUI
import Supabase

struct MemberTabView: View {

    @StateObject private var dataStore =
        SupabaseDataStore.shared

    @State private var selectedTab:
        MemberTab = .dashboard

    @State private var showProfile = false

    private enum MemberTab: Hashable {
        case ranking
        case ai
        case group
        case dashboard
    }

    var body: some View {

        Group {

            if dataStore.isLoading &&
                dataStore.currentUser == nil {

                loadingView

            } else if let user =
                dataStore.currentUser {

                memberTabs(
                    user: user
                )

            } else {

                unavailableView
            }
        }
        .task {

            if dataStore.currentUser == nil {

                await dataStore
                    .loadCurrentAccount()
            }
        }
    }

    // MARK: - Tabs

    private func memberTabs(
        user:
            SupabaseDataStore.TimeUpRemoteUser
    ) -> some View {

        TabView(
            selection: $selectedTab
        ) {

            NavigationStack {

                placeholderView(
                    title: "דירוג",
                    icon: "trophy.fill",
                    message:
                        "כאן יוצג הדירוג הגלובלי של הקבוצות הפעילות."
                )
                .toolbar {
                    profileToolbar
                }
            }
            .tabItem {

                Label(
                    "דירוג",
                    systemImage: "trophy"
                )
            }
            .tag(MemberTab.ranking)

            NavigationStack {

                placeholderView(
                    title: "AI",
                    icon: "sparkles",
                    message:
                        "כאן יהיה הצ׳אט האישי שלך עם TimeUp AI."
                )
                .toolbar {
                    profileToolbar
                }
            }
            .tabItem {

                Label(
                    "AI",
                    systemImage: "sparkles"
                )
            }
            .tag(MemberTab.ai)

            NavigationStack {

                if let group =
                    dataStore.activeMemberGroup {

                    remoteGroupView(
                        group: group
                    )
                    .toolbar {
                        profileToolbar
                    }

                } else {

                    ContentUnavailableView(
                        "אין קבוצה פעילה",
                        systemImage:
                            "person.3.sequence.fill",
                        description:
                            Text(
                                "החשבון אינו משויך כרגע לקבוצה פעילה."
                            )
                    )
                    .toolbar {
                        profileToolbar
                    }
                }
            }
            .tabItem {

                Label(
                    "הקבוצה",
                    systemImage: "person.3"
                )
            }
            .tag(MemberTab.group)

            NavigationStack {

                remoteDashboardView(
                    user: user
                )
                .toolbar {
                    profileToolbar
                }
            }
            .tabItem {

                Label(
                    "דשבורד",
                    systemImage:
                        "square.grid.2x2.fill"
                )
            }
            .tag(MemberTab.dashboard)
        }
        .sheet(
            isPresented: $showProfile
        ) {

            NavigationStack {

                SupabaseMemberProfileView(
                    user: user
                )
            }
        }
    }

    // MARK: - Dashboard

    private func remoteDashboardView(
        user:
            SupabaseDataStore.TimeUpRemoteUser
    ) -> some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 24
            ) {

                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {

                    Text(
                        "שלום \(displayName(for: user))"
                    )
                    .font(
                        .largeTitle.bold()
                    )

                    Text(
                        "הנתונים שלך מחוברים ל-TimeUp"
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }

                if let group =
                    dataStore.activeMemberGroup {

                    VStack(
                        alignment: .leading,
                        spacing: 10
                    ) {

                        HStack {

                            Label(
                                "הקבוצה שלי",
                                systemImage:
                                    "person.3.fill"
                            )
                            .font(.headline)

                            Spacer()

                            Label(
                                "\(dataStore.currentGroupStreak)",
                                systemImage:
                                    "flame.fill"
                            )
                            .font(.headline)
                        }

                        Text(group.name)
                            .font(.title2)
                            .fontWeight(
                                .semibold
                            )

                        Text(
                            "קוד קבוצה: \(group.code)"
                        )
                        .font(.footnote)
                        .foregroundStyle(
                            .secondary
                        )
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding()
                    .background(
                        .thinMaterial,
                        in:
                            RoundedRectangle(
                                cornerRadius: 18
                            )
                    )

                    currentUserProgressCard(
                        user: user
                    )

                } else {

                    ContentUnavailableView(
                        "אין קבוצה פעילה",
                        systemImage:
                            "person.3.sequence.fill"
                    )
                }
            }
            .padding(20)
        }
        .navigationTitle("דשבורד")
        .navigationBarTitleDisplayMode(
            .inline
        )
        .task(
            id: dataStore.activeMemberGroup?.id
        ) {

            guard let group =
                dataStore.activeMemberGroup
            else {
                return
            }

            await dataStore.loadDailyProgress(
                groupID: group.id
            )

            await dataStore
                .syncReportedScreenTime()
        }
        .refreshable {

            guard let group =
                dataStore.activeMemberGroup
            else {
                return
            }

            await dataStore.loadDailyProgress(
                groupID: group.id
            )

            await dataStore
                .syncReportedScreenTime()
        }
    }

    // MARK: - Current User Progress

    private func currentUserProgressCard(
        user:
            SupabaseDataStore.TimeUpRemoteUser
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            HStack {

                Label(
                    "היום שלי",
                    systemImage:
                        "chart.bar.fill"
                )
                .font(.headline)

                Spacer()

                if dataStore.isLearningDay(
                    for: user.id
                ) {

                    Text("יום למידה")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(
                            .horizontal,
                            9
                        )
                        .padding(
                            .vertical,
                            5
                        )
                        .background(
                            .thinMaterial,
                            in: Capsule()
                        )
                }
            }

            HStack(spacing: 12) {

                progressValue(
                    title: "שימוש",
                    value:
                        formattedMinutes(
                            dataStore
                                .usageMinutes(
                                    for: user.id
                                )
                        ),
                    icon: "iphone"
                )

                progressValue(
                    title: "יעד",
                    value:
                        formattedMinutes(
                            dataStore
                                .targetMinutes(
                                    for: user.id
                                )
                        ),
                    icon: "target"
                )
            }

            statusView(
                userID: user.id
            )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding()
        .background(
            .thinMaterial,
            in:
                RoundedRectangle(
                    cornerRadius: 18
                )
        )
    }

    // MARK: - Group

    private func remoteGroupView(
        group:
            SupabaseDataStore.TimeUpRemoteGroup
    ) -> some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 20
            ) {

                HStack(
                    alignment: .center,
                    spacing: 16
                ) {

                    Image(
                        systemName:
                            "person.3.fill"
                    )
                    .font(
                        .system(size: 46)
                    )

                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {

                        Text(group.name)
                            .font(
                                .largeTitle.bold()
                            )

                        Text(
                            "קוד קבוצה: \(group.code)"
                        )
                        .font(.footnote)
                        .foregroundStyle(
                            .secondary
                        )
                    }

                    Spacer()
                }

                groupStreakCard

                todayGroupStatusCard

                Divider()

                groupMembersSection
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .padding(20)
        }
        .navigationTitle("הקבוצה")
        .navigationBarTitleDisplayMode(
            .inline
        )
        .task(id: group.id) {

            await dataStore.loadGroupMembers(
                groupID: group.id
            )

            await dataStore.loadDailyProgress(
                groupID: group.id
            )

            await dataStore
                .syncReportedScreenTime()
        }
        .refreshable {

            await dataStore.loadGroupMembers(
                groupID: group.id
            )

            await dataStore.loadDailyProgress(
                groupID: group.id
            )

            await dataStore
                .syncReportedScreenTime()
        }
    }

    // MARK: - Group Streak

    private var groupStreakCard:
        some View {

        HStack(spacing: 16) {

            ZStack {

                Circle()
                    .fill(
                        Color.secondary
                            .opacity(0.12)
                    )
                    .frame(
                        width: 58,
                        height: 58
                    )

                Image(
                    systemName:
                        "flame.fill"
                )
                .font(
                    .system(size: 28)
                )
            }

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text("רצף קבוצתי")
                    .font(.subheadline)
                    .foregroundStyle(
                        .secondary
                    )

                Text(
                    "\(dataStore.currentGroupStreak) ימים"
                )
                .font(.title2.bold())
            }

            Spacer()
        }
        .padding()
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            .thinMaterial,
            in:
                RoundedRectangle(
                    cornerRadius: 18
                )
        )
    }

    // MARK: - Today's Group Status

    @ViewBuilder
    private var todayGroupStatusCard:
        some View {

        if let result =
            dataStore.groupResult() {

            VStack(
                alignment: .leading,
                spacing: 16
            ) {

                HStack {

                    Label(
                        "מצב הקבוצה היום",
                        systemImage:
                            "chart.bar.fill"
                    )
                    .font(.headline)

                    Spacer()

                    Image(
                        systemName:
                            result.succeeded
                            ? "checkmark.circle.fill"
                            : "xmark.circle.fill"
                    )
                    .font(.title2)
                    .foregroundStyle(
                        result.succeeded
                        ? Color.green
                        : Color.red
                    )
                }

                HStack(spacing: 12) {

                    groupMetric(
                        title: "השלימו",
                        value:
                            "\(result.completedMemberCount)/\(result.memberCount)",
                        icon:
                            "person.2.fill"
                    )

                    groupMetric(
                        title: "ממוצע",
                        value:
                            formattedMinutes(
                                result.averageUsageMinutes
                            ),
                        icon:
                            "chart.bar.xaxis"
                    )
                }

                Label(
                    result.succeeded
                    ? "הקבוצה עמדה ביעד"
                    : "הקבוצה עדיין לא השלימה את היעד",
                    systemImage:
                        result.succeeded
                        ? "checkmark.circle.fill"
                        : "clock.fill"
                )
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(
                    result.succeeded
                    ? Color.green
                    : Color.secondary
                )
            }
            .padding()
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(
                .thinMaterial,
                in:
                    RoundedRectangle(
                        cornerRadius: 18
                    )
            )

        } else {

            VStack(
                alignment: .leading,
                spacing: 10
            ) {

                Label(
                    "מצב הקבוצה היום",
                    systemImage:
                        "clock.fill"
                )
                .font(.headline)

                Text(
                    "התוצאה הקבוצתית של היום עדיין לא נקבעה."
                )
                .font(.subheadline)
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
                .thinMaterial,
                in:
                    RoundedRectangle(
                        cornerRadius: 18
                    )
            )
        }
    }

    private func groupMetric(
        title: String,
        value: String,
        icon: String
    ) -> some View {

        HStack(spacing: 9) {

            Image(
                systemName: icon
            )

            VStack(
                alignment: .leading,
                spacing: 2
            ) {

                Text(title)
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )

                Text(value)
                    .font(.headline)
            }

            Spacer(
                minLength: 0
            )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(10)
        .background(
            Color.secondary
                .opacity(0.08),
            in:
                RoundedRectangle(
                    cornerRadius: 12
                )
        )
    }

    // MARK: - Group Members

    @ViewBuilder
    private var groupMembersSection:
        some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack {

                Label(
                    "חברים",
                    systemImage:
                        "person.2.fill"
                )
                .font(.title2.bold())

                Spacer()

                if !dataStore.groupMembers.isEmpty {

                    Text(
                        "\(dataStore.groupMembers.count)"
                    )
                    .font(.subheadline)
                    .foregroundStyle(
                        .secondary
                    )
                }
            }

            if dataStore.isLoadingGroupMembers ||
                dataStore.isLoadingDailyProgress {

                HStack(spacing: 12) {

                    ProgressView()

                    Text(
                        "טוען נתוני קבוצה..."
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
                .padding(
                    .vertical,
                    8
                )

            } else if dataStore.groupMembers.isEmpty {

                ContentUnavailableView(
                    "אין חברים להצגה",
                    systemImage:
                        "person.2.slash",
                    description:
                        Text(
                            "לא נמצאו חברים פעילים בקבוצה."
                        )
                )

            } else {

                VStack(spacing: 12) {

                    ForEach(
                        dataStore.groupMembers
                    ) { member in

                        groupMemberRow(
                            member: member
                        )
                    }
                }
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    private func groupMemberRow(
        member:
            SupabaseDataStore.TimeUpRemoteUser
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack(spacing: 14) {

                ZStack {

                    Circle()
                        .fill(
                            Color.secondary
                                .opacity(0.12)
                        )
                        .frame(
                            width: 46,
                            height: 46
                        )

                    Image(
                        systemName:
                            "person.fill"
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {

                    HStack(spacing: 6) {

                        Text(
                            displayName(
                                for: member
                            )
                        )
                        .font(.headline)

                        if member.id ==
                            dataStore.currentUser?.id {

                            Text("אתה")
                                .font(.caption)
                                .fontWeight(
                                    .semibold
                                )
                                .padding(
                                    .horizontal,
                                    7
                                )
                                .padding(
                                    .vertical,
                                    3
                                )
                                .background(
                                    .thinMaterial,
                                    in: Capsule()
                                )
                        }
                    }

                    if dataStore.isLearningDay(
                        for: member.id
                    ) {

                        Text("יום למידה")
                            .font(.caption)
                            .foregroundStyle(
                                .secondary
                            )

                    } else if let membership =
                        dataStore
                            .groupMemberships
                            .first(
                                where: {
                                    $0.userID ==
                                        member.id
                                }
                            ),
                              let joinedAt =
                        membership.joinedAt {

                        Text(
                            "הצטרף \(joinedAt.formatted(date: .abbreviated, time: .omitted))"
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )
                    }
                }

                Spacer()

                memberStatusIcon(
                    userID: member.id
                )
            }

            Divider()

            HStack(spacing: 12) {

                progressValue(
                    title: "שימוש",
                    value:
                        formattedMinutes(
                            dataStore
                                .usageMinutes(
                                    for: member.id
                                )
                        ),
                    icon: "iphone"
                )

                progressValue(
                    title: "יעד",
                    value:
                        formattedMinutes(
                            dataStore
                                .targetMinutes(
                                    for: member.id
                                )
                        ),
                    icon: "target"
                )
            }
        }
        .padding(14)
        .background(
            .thinMaterial,
            in:
                RoundedRectangle(
                    cornerRadius: 16
                )
        )
    }

    // MARK: - Progress Components

    private func progressValue(
        title: String,
        value: String,
        icon: String
    ) -> some View {

        HStack(spacing: 9) {

            Image(
                systemName: icon
            )
            .font(.headline)

            VStack(
                alignment: .leading,
                spacing: 2
            ) {

                Text(title)
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )

                Text(value)
                    .font(.headline)
            }

            Spacer(
                minLength: 0
            )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(10)
        .background(
            Color.secondary
                .opacity(0.08),
            in:
                RoundedRectangle(
                    cornerRadius: 12
                )
        )
    }

    @ViewBuilder
    private func memberStatusIcon(
        userID: UUID
    ) -> some View {

        if dataStore.isLearningDay(
            for: userID
        ) {

            Image(
                systemName:
                    "book.fill"
            )
            .font(.title3)

        } else if let achieved =
            dataStore.achieved(
                for: userID
            ) {

            Image(
                systemName:
                    achieved
                    ? "checkmark.circle.fill"
                    : "xmark.circle.fill"
            )
            .font(.title2)
            .foregroundStyle(
                achieved
                ? Color.green
                : Color.red
            )

        } else {

            Image(
                systemName:
                    "clock.fill"
            )
            .font(.title3)
            .foregroundStyle(
                .secondary
            )
        }
    }

    @ViewBuilder
    private func statusView(
        userID: UUID
    ) -> some View {

        if dataStore.isLearningDay(
            for: userID
        ) {

            Label(
                "יום למידה",
                systemImage:
                    "book.fill"
            )
            .font(.subheadline)
            .fontWeight(.semibold)

        } else if let achieved =
            dataStore.achieved(
                for: userID
            ) {

            Label(
                achieved
                    ? "עמדת ביעד"
                    : "היעד לא הושג",
                systemImage:
                    achieved
                    ? "checkmark.circle.fill"
                    : "xmark.circle.fill"
            )
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(
                achieved
                ? Color.green
                : Color.red
            )

        } else {

            Label(
                "היום עדיין בתהליך",
                systemImage:
                    "clock.fill"
            )
            .font(.subheadline)
            .foregroundStyle(
                .secondary
            )
        }
    }

    private func formattedMinutes(
        _ minutes: Int?
    ) -> String {

        guard let minutes else {
            return "—"
        }

        let safeMinutes =
            max(0, minutes)

        let hours =
            safeMinutes / 60

        let remainingMinutes =
            safeMinutes % 60

        if hours == 0 {
            return "\(remainingMinutes) דק׳"
        }

        if remainingMinutes == 0 {
            return "\(hours) שע׳"
        }

        return
            "\(hours) שע׳ \(remainingMinutes) דק׳"
    }

    // MARK: - Profile

    @ToolbarContentBuilder
    private var profileToolbar:
        some ToolbarContent {

        ToolbarItem(
            placement: .topBarTrailing
        ) {

            Button {

                showProfile = true

            } label: {

                ZStack {

                    Circle()
                        .fill(
                            Color.secondary
                                .opacity(0.15)
                        )
                        .frame(
                            width: 36,
                            height: 36
                        )

                    Image(
                        systemName:
                            "person.crop.circle.fill"
                    )
                    .font(
                        .system(size: 28)
                    )
                }
            }
            .accessibilityLabel(
                "פרופיל"
            )
        }
    }

    // MARK: - States

    private var loadingView:
        some View {

        VStack(spacing: 16) {

            ProgressView()

            Text(
                "טוען את החשבון..."
            )
            .foregroundStyle(
                .secondary
            )
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }

    private var unavailableView:
        some View {

        ContentUnavailableView(
            "לא ניתן לטעון את החשבון",
            systemImage:
                "person.crop.circle.badge.exclamationmark",
            description:
                Text(
                    dataStore.lastError ??
                    "נסה להתחבר מחדש."
                )
        )
    }

    private func placeholderView(
        title: String,
        icon: String,
        message: String
    ) -> some View {

        VStack(spacing: 18) {

            Spacer()

            Image(
                systemName: icon
            )
            .font(
                .system(size: 54)
            )

            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(message)
                .foregroundStyle(
                    .secondary
                )
                .multilineTextAlignment(
                    .center
                )
                .padding(
                    .horizontal,
                    32
                )

            Spacer()
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(
            .inline
        )
    }

    private func displayName(
        for user:
            SupabaseDataStore.TimeUpRemoteUser
    ) -> String {

        let name =
            user.displayName?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ) ?? ""

        return name.isEmpty
            ? "TimeUp"
            : name
    }
}

// MARK: - Supabase Member Profile

private struct SupabaseMemberProfileView:
    View {

    let user:
        SupabaseDataStore.TimeUpRemoteUser

    @Environment(\.dismiss)
    private var dismiss

    @StateObject private var dataStore =
        SupabaseDataStore.shared

    @State private var isLoggingOut =
        false

    var body: some View {

        List {

            Section {

                VStack(spacing: 14) {

                    Image(
                        systemName:
                            "person.crop.circle.fill"
                    )
                    .font(
                        .system(size: 82)
                    )
                    .foregroundStyle(
                        .secondary
                    )

                    Text(
                        user.displayName ??
                        "TimeUp"
                    )
                    .font(.title2)
                    .fontWeight(.bold)

                    if let email =
                        user.email {

                        Text(email)
                            .font(.footnote)
                            .foregroundStyle(
                                .secondary
                            )
                    }
                }
                .frame(
                    maxWidth: .infinity
                )
                .padding(
                    .vertical,
                    16
                )
            }

            Section {

                NavigationLink {

                    PersonalSettingsView()

                } label: {

                    Label(
                        "הגדרות",
                        systemImage:
                            "gearshape"
                    )
                }
            }

            Section {

                Button(
                    role: .destructive
                ) {

                    logout()

                } label: {

                    HStack {

                        Label(
                            "יציאה מהחשבון",
                            systemImage:
                                "rectangle.portrait.and.arrow.right"
                        )

                        Spacer()

                        if isLoggingOut {

                            ProgressView()
                        }
                    }
                }
                .disabled(isLoggingOut)
            }
        }
        .navigationTitle("פרופיל")
        .navigationBarTitleDisplayMode(
            .inline
        )
        .toolbar {

            ToolbarItem(
                placement: .topBarLeading
            ) {

                Button("סגור") {

                    dismiss()
                }
            }
        }
    }

    private func logout() {

        isLoggingOut = true

        Task {

            do {

                try await
                    SupabaseManager.shared
                        .client
                        .auth
                        .signOut()

                await MainActor.run {

                    dataStore.reset()
                    isLoggingOut = false
                    dismiss()
                }

            } catch {

                await MainActor.run {

                    isLoggingOut = false
                }
            }
        }
    }
}
