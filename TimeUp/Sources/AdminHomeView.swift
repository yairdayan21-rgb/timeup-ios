import SwiftUI

struct AdminHomeView: View {

    @State private var showCreateGroup = false
    @State private var showRanking = false

    @StateObject private var dataStore =
        SupabaseDataStore.shared

    @StateObject private var rankingStore =
        SupabaseRankingStore.shared

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

                        Text("ניהול הקבוצות שלך")
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

                                Text("דירוג")
                                    .fontWeight(
                                        .semibold
                                    )

                                Text(
                                    "קבוצות ומשתמשים"
                                )
                                .font(.caption)
                                .foregroundStyle(
                                    .secondary
                                )
                            }

                            Spacer()

                            Image(
                                systemName:
                                    "chevron.left"
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
                                "יצירת קבוצה חדשה"
                            )
                            .fontWeight(
                                .semibold
                            )

                            Spacer()

                            Image(
                                systemName:
                                    "chevron.left"
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

                        Text("הקבוצות שלי")
                            .font(
                                .title3.bold()
                            )

                        if dataStore.isLoading &&
                            dataStore.groups.isEmpty {

                            HStack {

                                Spacer()

                                ProgressView(
                                    "טוען קבוצות..."
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
                                "עדיין אין קבוצות",
                                systemImage:
                                    "person.3",
                                description:
                                    Text(
                                        "צור את הקבוצה הראשונה שלך כדי להתחיל."
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
                                "לא ניתן לטעון את הנתונים",
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
                                "נסה שוב"
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

                    Text("קוד קבוצה")
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
                        "\(group.successDays ?? 7) ימים"
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

            return
                "\(group.reductionPercent ?? 0)% פחות מהיום הקודם"

        case "group_average_percentage":

            return
                "\(group.reductionPercent ?? 0)% פחות מהממוצע הקבוצתי"

        case "manual":

            return "יעד אישי"

        default:

            return "יעד קבוצה"
        }
    }
}

// MARK: - Admin Ranking View

private struct AdminRankingView: View {

    private enum RankingTab:
        String,
        CaseIterable,
        Identifiable {

        case groups = "קבוצות"
        case users = "משתמשים"

        var id: String {
            rawValue
        }
    }

    @State private var selectedTab:
        RankingTab = .groups

    @StateObject private var rankingStore =
        SupabaseRankingStore.shared

    @StateObject private var dataStore =
        SupabaseDataStore.shared

    var body: some View {

        VStack(
            spacing: 16
        ) {

            Picker(
                "סוג דירוג",
                selection:
                    $selectedTab
            ) {

                ForEach(
                    RankingTab.allCases
                ) { tab in

                    Text(tab.rawValue)
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
            "דירוג"
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
                    "טוען דירוג קבוצות..."
            )

        } else if
            rankingStore.groupRankings.isEmpty {

            ContentUnavailableView(
                "אין עדיין דירוג קבוצות",
                systemImage:
                    "trophy",
                description:
                    Text(
                        rankingStore.lastError ??
                        "הדירוג יופיע כאשר יהיו נתונים לקבוצות."
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
                    "טוען דירוג משתמשים..."
            )

        } else if
            rankingStore.userRankings.isEmpty {

            ContentUnavailableView(
                "אין עדיין דירוג משתמשים",
                systemImage:
                    "person.2",
                description:
                    Text(
                        rankingStore.userRankingError ??
                        "הדירוג יופיע כאשר יהיו נתוני שימוש למשתמשים."
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

                        Text("שלי")
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
                        "\(ranking.currentStreak) ימים",
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
                    "משתמש"
                )
                .font(.headline)

                HStack(
                    spacing: 14
                ) {

                    Label(
                        "\(ranking.personalStreak) ימים",
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

        if hours == 0 {

            return
                "\(remainingMinutes) דק׳"
        }

        if remainingMinutes == 0 {

            return
                "\(hours) שע׳"
        }

        return
            "\(hours) שע׳ \(remainingMinutes) דק׳"
    }
}