import SwiftUI

struct AdminHomeView: View {

    @State private var showCreateGroup = false
    @State private var showRanking = false

    @StateObject private var dataStore =
        SupabaseDataStore.shared

    @StateObject private var rankingStore =
        SupabaseRankingStore.shared

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 24
                ) {

                    // MARK: - Header

                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {

                        Text("TimeUp")
                            .font(
                                .system(
                                    size: 34,
                                    weight: .bold,
                                    design: .rounded
                                )
                            )

                        Text(adminSubtitle)
                            .foregroundStyle(
                                .secondary
                            )
                    }

                    // MARK: - Ranking

                    Button {

                        showRanking = true

                    } label: {

                        HStack(
                            spacing: 14
                        ) {

                            Image(
                                systemName:
                                    "trophy.fill"
                            )
                            .font(.title2)

                            VStack(
                                alignment: .leading,
                                spacing: 3
                            ) {

                                Text(rankingText)
                                    .fontWeight(
                                        .semibold
                                    )

                                Text(
                                    groupsAndUsersText
                                )
                                .font(.caption)
                                .foregroundStyle(
                                    .secondary
                                )
                            }

                            Spacer()

                            Image(
                                systemName:
                                    chevronName
                            )
                            .foregroundStyle(
                                .secondary
                            )
                        }
                        .padding()
                        .frame(
                            maxWidth: .infinity
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
                    .buttonStyle(.plain)

                    // MARK: - Create Group

                    Button {

                        showCreateGroup = true

                    } label: {

                        HStack {

                            Image(
                                systemName:
                                    "plus.circle.fill"
                            )
                            .font(.title2)

                            Text(
                                createGroupText
                            )
                            .fontWeight(
                                .semibold
                            )

                            Spacer()

                            Image(
                                systemName:
                                    chevronName
                            )
                            .foregroundStyle(
                                .secondary
                            )
                        }
                        .padding()
                        .frame(
                            maxWidth: .infinity
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
                    .buttonStyle(.plain)

                    // MARK: - Groups

                    VStack(
                        alignment: .leading,
                        spacing: 12
                    ) {

                        Text(myGroupsText)
                            .font(
                                .title3.bold()
                            )

                        if dataStore.isLoading &&
                            dataStore.groups.isEmpty {

                            HStack {

                                Spacer()

                                ProgressView(
                                    loadingGroupsText
                                )

                                Spacer()
                            }
                            .padding(
                                .vertical,
                                40
                            )

                        } else if
                            dataStore.groups.isEmpty {

                            ContentUnavailableView(
                                noGroupsTitle,
                                systemImage:
                                    "person.3",
                                description:
                                    Text(
                                        noGroupsDescription
                                    )
                            )
                            .frame(
                                maxWidth: .infinity
                            )
                            .padding(
                                .vertical,
                                30
                            )

                        } else {

                            ForEach(
                                dataStore.groups
                            ) { group in

                                groupCard(
                                    group: group
                                )
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
                                unableToLoadDataText,
                                systemImage:
                                    "exclamationmark.triangle"
                            )
                            .fontWeight(
                                .semibold
                            )

                            Text(error)
                                .font(.caption)
                                .foregroundStyle(
                                    .secondary
                                )

                            Button(
                                retryText
                            ) {

                                Task {

                                    await dataStore
                                        .loadCurrentAccount()
                                }
                            }
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
                }
                .padding(20)
            }
            .refreshable {

                await dataStore
                    .loadCurrentAccount()

                await rankingStore
                    .loadAllRankings()
            }
            .toolbar {

                ToolbarItem(
                    placement:
                        .topBarTrailing
                ) {

                    Button {

                        Task {

                            await dataStore
                                .loadCurrentAccount()

                            await rankingStore
                                .loadAllRankings()
                        }

                    } label: {

                        Image(
                            systemName:
                                "arrow.clockwise"
                        )
                    }
                    .accessibilityLabel(
                        refreshText
                    )
                }
            }
            .navigationDestination(
                isPresented:
                    $showCreateGroup
            ) {

                CreateGroupView()
            }
            .navigationDestination(
                isPresented:
                    $showRanking
            ) {

                AdminRankingView()
            }
            .task {

                await dataStore
                    .loadCurrentAccount()

                await rankingStore
                    .loadAllRankings()
            }
        }
    }

    // MARK: - Group Card

    private func groupCard(
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

                    Text(group.name)
                        .font(.headline)

                    Text(groupCodeText)
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )
                }

                Spacer()

                Image(
                    systemName:
                        "person.3.fill"
                )
                .font(.title3)
                .foregroundStyle(
                    .secondary
                )
            }

            Text(group.code)
                .font(
                    .system(
                        size: 28,
                        weight: .bold,
                        design: .monospaced
                    )
                )
                .tracking(4)

            Divider()

            HStack(
                spacing: 12
            ) {

                Label(
                    goalDescription(
                        group
                    ),
                    systemImage:
                        "target"
                )

                Spacer()

                Label(
                    "\(group.currentStreak)",
                    systemImage:
                        "flame.fill"
                )
                .foregroundStyle(
                    .secondary
                )

                if group.goalMethod !=
                    "manual" {

                    Text(
                        daysText(
                            group.successDays ?? 7
                        )
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
            }
            .font(.subheadline)
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

    // MARK: - Goal Description

    private func goalDescription(
        _ group:
            SupabaseDataStore.TimeUpRemoteGroup
    ) -> String {

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
                return "יעד אישי"

            case .english:
                return "Personal target"

            case .arabic:
                return "هدف شخصي"
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

    private var adminSubtitle: String {

        switch localization.language {

        case .hebrew:
            return "ניהול הקבוצות שלך"

        case .english:
            return "Manage your groups"

        case .arabic:
            return "إدارة مجموعاتك"
        }
    }

    private var rankingText: String {

        switch localization.language {

        case .hebrew:
            return "דירוג"

        case .english:
            return "Ranking"

        case .arabic:
            return "الترتيب"
        }
    }

    private var groupsAndUsersText: String {

        switch localization.language {

        case .hebrew:
            return "קבוצות ומשתמשים"

        case .english:
            return "Groups and users"

        case .arabic:
            return "المجموعات والمستخدمون"
        }
    }

    private var createGroupText: String {

        switch localization.language {

        case .hebrew:
            return "יצירת קבוצה חדשה"

        case .english:
            return "Create a new group"

        case .arabic:
            return "إنشاء مجموعة جديدة"
        }
    }

    private var myGroupsText: String {

        switch localization.language {

        case .hebrew:
            return "הקבוצות שלי"

        case .english:
            return "My groups"

        case .arabic:
            return "مجموعاتي"
        }
    }

    private var loadingGroupsText: String {

        switch localization.language {

        case .hebrew:
            return "טוען קבוצות..."

        case .english:
            return "Loading groups..."

        case .arabic:
            return "جارٍ تحميل المجموعات..."
        }
    }

    private var noGroupsTitle: String {

        switch localization.language {

        case .hebrew:
            return "עדיין אין קבוצות"

        case .english:
            return "No groups yet"

        case .arabic:
            return "لا توجد مجموعات بعد"
        }
    }

    private var noGroupsDescription: String {

        switch localization.language {

        case .hebrew:
            return "צור את הקבוצה הראשונה שלך כדי להתחיל."

        case .english:
            return "Create your first group to get started."

        case .arabic:
            return "أنشئ مجموعتك الأولى للبدء."
        }
    }

    private var unableToLoadDataText: String {

        switch localization.language {

        case .hebrew:
            return "לא ניתן לטעון את הנתונים"

        case .english:
            return "Unable to load data"

        case .arabic:
            return "تعذر تحميل البيانات"
        }
    }

    private var retryText: String {

        switch localization.language {

        case .hebrew:
            return "נסה שוב"

        case .english:
            return "Try again"

        case .arabic:
            return "حاول مرة أخرى"
        }
    }

    private var refreshText: String {

        switch localization.language {

        case .hebrew:
            return "רענון"

        case .english:
            return "Refresh"

        case .arabic:
            return "تحديث"
        }
    }

    private var groupCodeText: String {

        switch localization.language {

        case .hebrew:
            return "קוד קבוצה"

        case .english:
            return "Group code"

        case .arabic:
            return "رمز المجموعة"
        }
    }

    private func daysText(
        _ days: Int
    ) -> String {

        switch localization.language {

        case .hebrew:
            return "\(days) ימים"

        case .english:
            return days == 1
                ? "1 day"
                : "\(days) days"

        case .arabic:
            return "\(days) يوم"
        }
    }
}

// MARK: - Admin Ranking View

private struct AdminRankingView: View {

    private enum RankingTab:
        CaseIterable,
        Identifiable {

        case groups
        case users

        var id: String {

            switch self {

            case .groups:
                return "groups"

            case .users:
                return "users"
            }
        }
    }

    @State private var selectedTab:
        RankingTab = .groups

    @StateObject private var rankingStore =
        SupabaseRankingStore.shared

    @StateObject private var dataStore =
        SupabaseDataStore.shared

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    var body: some View {

        VStack(
            spacing: 16
        ) {

            Picker(
                rankingTypeText,
                selection:
                    $selectedTab
            ) {

                ForEach(
                    RankingTab.allCases
                ) { tab in

                    Text(
                        title(
                            for: tab
                        )
                    )
                    .tag(tab)
                }
            }
            .pickerStyle(
                .segmented
            )
            .padding(
                .horizontal,
                20
            )
            .padding(
                .top,
                12
            )

            switch selectedTab {

            case .groups:

                groupRankingContent

            case .users:

                userRankingContent
            }
        }
        .navigationTitle(
            rankingText
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
        .task {

            await rankingStore
                .loadAllRankings()
        }
    }

    // MARK: - Group Ranking Content

    @ViewBuilder
    private var groupRankingContent:
        some View {

        if rankingStore.isLoading &&
            rankingStore.groupRankings.isEmpty {

            loadingView(
                text:
                    loadingGroupRankingText
            )

        } else if
            rankingStore.groupRankings.isEmpty {

            ContentUnavailableView(
                noGroupRankingTitle,
                systemImage:
                    "trophy",
                description:
                    Text(
                        rankingStore.lastError ??
                        noGroupRankingDescription
                    )
            )

        } else {

            ScrollView {

                LazyVStack(
                    spacing: 12
                ) {

                    ForEach(
                        rankingStore
                            .groupRankings
                    ) { ranking in

                        groupRankingRow(
                            ranking
                        )
                    }
                }
                .padding(
                    .horizontal,
                    20
                )
                .padding(
                    .bottom,
                    20
                )
            }
            .refreshable {

                await rankingStore
                    .loadGroupRankings()
            }
        }
    }

    // MARK: - User Ranking Content

    @ViewBuilder
    private var userRankingContent:
        some View {

        if rankingStore.isLoadingUsers &&
            rankingStore.userRankings.isEmpty {

            loadingView(
                text:
                    loadingUserRankingText
            )

        } else if
            rankingStore.userRankings.isEmpty {

            ContentUnavailableView(
                noUserRankingTitle,
                systemImage:
                    "person.2",
                description:
                    Text(
                        rankingStore.userRankingError ??
                        noUserRankingDescription
                    )
            )

        } else {

            ScrollView {

                LazyVStack(
                    spacing: 12
                ) {

                    ForEach(
                        rankingStore
                            .userRankings
                    ) { ranking in

                        userRankingRow(
                            ranking
                        )
                    }
                }
                .padding(
                    .horizontal,
                    20
                )
                .padding(
                    .bottom,
                    20
                )
            }
            .refreshable {

                await rankingStore
                    .loadUserRankings()
            }
        }
    }

    // MARK: - Group Row

    private func groupRankingRow(
        _ ranking:
            SupabaseRankingStore.GroupRanking
    ) -> some View {

        let isMyGroup =
            dataStore.groups.contains {
                $0.id ==
                    ranking.groupID
            }

        return HStack(
            spacing: 14
        ) {

            positionIcon(
                position:
                    ranking.rankingPosition
            )

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                HStack(
                    spacing: 7
                ) {

                    Text(
                        ranking.groupName
                    )
                    .font(.headline)

                    if isMyGroup {

                        Text(myGroupText)
                            .font(
                                .caption2
                            )
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
                                in:
                                    Capsule()
                            )
                    }
                }

                HStack(
                    spacing: 14
                ) {

                    Label(
                        daysText(
                            ranking.currentStreak
                        ),
                        systemImage:
                            "flame.fill"
                    )

                    if let average =
                        ranking
                            .averageUsageMinutes {

                        Label(
                            formattedMinutes(
                                average
                            ),
                            systemImage:
                                "iphone"
                        )
                    }
                }
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }

            Spacer()

            Text(
                "#\(ranking.rankingPosition)"
            )
            .font(
                .title3.bold()
            )
        }
        .padding(14)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            isMyGroup
            ? Color.secondary
                .opacity(0.12)
            : Color.secondary
                .opacity(0.06),
            in:
                RoundedRectangle(
                    cornerRadius: 16
                )
        )
    }

    // MARK: - User Row

    private func userRankingRow(
        _ ranking:
            SupabaseRankingStore.UserRanking
    ) -> some View {

        HStack(
            spacing: 14
        ) {

            positionIcon(
                position:
                    ranking.rankingPosition
            )

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                Text(
                    ranking.displayName ??
                    genericUserText
                )
                .font(.headline)

                HStack(
                    spacing: 14
                ) {

                    Label(
                        daysText(
                            ranking.personalStreak
                        ),
                        systemImage:
                            "flame.fill"
                    )

                    if let average =
                        ranking
                            .averageUsageMinutes {

                        Label(
                            formattedMinutes(
                                average
                            ),
                            systemImage:
                                "iphone"
                        )
                    }
                }
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }

            Spacer()

            Text(
                "#\(ranking.rankingPosition)"
            )
            .font(
                .title3.bold()
            )
        }
        .padding(14)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            Color.secondary
                .opacity(0.06),
            in:
                RoundedRectangle(
                    cornerRadius: 16
                )
        )
    }

    // MARK: - Position Icon

    @ViewBuilder
    private func positionIcon(
        position: Int
    ) -> some View {

        ZStack {

            Circle()
                .fill(
                    Color.secondary
                        .opacity(0.12)
                )
                .frame(
                    width: 48,
                    height: 48
                )

            if position <= 3 {

                Image(
                    systemName:
                        position == 1
                        ? "trophy.fill"
                        : "medal.fill"
                )
                .font(.title3)

            } else {

                Text(
                    "\(position)"
                )
                .font(.headline)
            }
        }
    }

    // MARK: - Loading

    private func loadingView(
        text: String
    ) -> some View {

        VStack(
            spacing: 16
        ) {

            ProgressView()

            Text(text)
                .foregroundStyle(
                    .secondary
                )
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }

    // MARK: - Time Format

    private func formattedMinutes(
        _ minutes: Double
    ) -> String {

        let totalMinutes =
            max(
                0,
                Int(
                    minutes.rounded()
                )
            )

        let hours =
            totalMinutes / 60

        let remainingMinutes =
            totalMinutes % 60

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

    // MARK: - Localization

    private func title(
        for tab: RankingTab
    ) -> String {

        switch tab {

        case .groups:

            switch localization.language {

            case .hebrew:
                return "קבוצות"

            case .english:
                return "Groups"

            case .arabic:
                return "المجموعات"
            }

        case .users:

            switch localization.language {

            case .hebrew:
                return "משתמשים"

            case .english:
                return "Users"

            case .arabic:
                return "المستخدمون"
            }
        }
    }

    private var rankingTypeText: String {

        switch localization.language {

        case .hebrew:
            return "סוג דירוג"

        case .english:
            return "Ranking type"

        case .arabic:
            return "نوع الترتيب"
        }
    }

    private var rankingText: String {

        switch localization.language {

        case .hebrew:
            return "דירוג"

        case .english:
            return "Ranking"

        case .arabic:
            return "الترتيب"
        }
    }

    private var loadingGroupRankingText: String {

        switch localization.language {

        case .hebrew:
            return "טוען דירוג קבוצות..."

        case .english:
            return "Loading group ranking..."

        case .arabic:
            return "جارٍ تحميل ترتيب المجموعات..."
        }
    }

    private var noGroupRankingTitle: String {

        switch localization.language {

        case .hebrew:
            return "אין עדיין דירוג קבוצות"

        case .english:
            return "No group ranking yet"

        case .arabic:
            return "لا يوجد ترتيب للمجموعات بعد"
        }
    }

    private var noGroupRankingDescription: String {

        switch localization.language {

        case .hebrew:
            return "הדירוג יופיע כאשר יהיו נתונים לקבוצות."

        case .english:
            return "The ranking will appear when group data is available."

        case .arabic:
            return "سيظهر الترتيب عند توفر بيانات للمجموعات."
        }
    }

    private var loadingUserRankingText: String {

        switch localization.language {

        case .hebrew:
            return "טוען דירוג משתמשים..."

        case .english:
            return "Loading user ranking..."

        case .arabic:
            return "جارٍ تحميل ترتيب المستخدمين..."
        }
    }

    private var noUserRankingTitle: String {

        switch localization.language {

        case .hebrew:
            return "אין עדיין דירוג משתמשים"

        case .english:
            return "No user ranking yet"

        case .arabic:
            return "لا يوجد ترتيب للمستخدمين بعد"
        }
    }

    private var noUserRankingDescription: String {

        switch localization.language {

        case .hebrew:
            return "הדירוג יופיע כאשר יהיו נתוני שימוש למשתמשים."

        case .english:
            return "The ranking will appear when user activity data is available."

        case .arabic:
            return "سيظهر الترتيب عند توفر بيانات استخدام للمستخدمين."
        }
    }

    private var myGroupText: String {

        switch localization.language {

        case .hebrew:
            return "שלי"

        case .english:
            return "Mine"

        case .arabic:
            return "مجموعتي"
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

    private func daysText(
        _ days: Int
    ) -> String {

        switch localization.language {

        case .hebrew:
            return "\(days) ימים"

        case .english:
            return days == 1
                ? "1 day"
                : "\(days) days"

        case .arabic:
            return "\(days) يوم"
        }
    }
}