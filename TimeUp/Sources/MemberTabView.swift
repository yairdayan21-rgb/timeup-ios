import SwiftUI
import Supabase

struct MemberTabView: View {

    @StateObject private var dataStore = SupabaseDataStore.shared
    @StateObject private var rankingStore = SupabaseRankingStore.shared
    @StateObject private var alternativesStore = SupabaseAlternativesStore.shared

    @ObservedObject private var localization = TimeUpLocalization.shared
    @ObservedObject private var onboardingCoordinator =
        MemberOnboardingCoordinator.shared

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var selectedTab: MemberTab = .dashboard
    @State private var showProfile = false
    @State private var showGoalExplanation = false

    private enum MemberTab: Hashable {
        case ranking
        case ai
        case group
        case dashboard
    }

    private struct OnboardingContext: Equatable {
        let userID: UUID?
        let groupID: UUID?
        let isLoading: Bool
        let completed: Bool
    }

    private var onboardingContext: OnboardingContext {
        OnboardingContext(
            userID: dataStore.currentUser?.id,
            groupID: dataStore.activeMemberGroup?.id,
            isLoading: dataStore.isLoading,
            completed: dataStore.currentUser?.onboardingCompleted ?? false
        )
    }

    private var canPresentTour: Bool {
        dataStore.currentUser?.role == "member" &&
        dataStore.activeMemberGroup != nil
    }

    var body: some View {
        Group {
            if dataStore.isLoading && dataStore.currentUser == nil {
                loadingView
            } else if let user = dataStore.currentUser {
                memberTabs(user: user)
            } else {
                unavailableView
            }
        }
        .overlayPreferenceValue(
            MemberOnboardingAnchorPreferenceKey.self
        ) { anchors in
            GeometryReader { geometry in
                if onboardingCoordinator.isPresented && canPresentTour {
                    MemberOnboardingTourOverlay(
                        highlightedFrame: anchors[
                            onboardingCoordinator.currentStep
                        ].map {
                            geometry[$0]
                        }
                    )
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .zIndex(100)
                }
            }
        }
        .timeUpLocalization()
        .task {
            if dataStore.currentUser == nil {
                await dataStore.loadCurrentAccount()
            }
        }
        .task(id: onboardingContext) {
            presentFirstTimeTourIfNeeded()
        }
        .onChange(
            of: onboardingCoordinator.isPresented
        ) { _, isPresented in
            guard isPresented else {
                return
            }

            guard canPresentTour else {
                onboardingCoordinator.dismiss()
                return
            }

            showProfile = false
            showGoalExplanation = false
            routeToCurrentTourStep()
        }
        .onChange(
            of: onboardingCoordinator.currentStep
        ) { _, _ in
            routeToCurrentTourStep()
        }
        .onChange(
            of: dataStore.currentUser?.id
        ) { oldID, newID in
            if oldID != nil && oldID != newID {
                onboardingCoordinator.dismiss()
                showProfile = false
                showGoalExplanation = false
                selectedTab = .dashboard
            }
        }
        .onChange(
            of: dataStore.activeMemberGroup?.id
        ) { _, groupID in
            if groupID == nil && !dataStore.isLoading {
                onboardingCoordinator.dismiss()
                showGoalExplanation = false
            }
        }
        .onDisappear {
            onboardingCoordinator.dismiss()
        }
    }

    // MARK: - Onboarding

    private func presentFirstTimeTourIfNeeded() {
        guard !dataStore.isLoading,
              !onboardingCoordinator.isFinishing,
              canPresentTour,
              let user = dataStore.currentUser
        else {
            return
        }

        onboardingCoordinator.presentFirstTimeIfNeeded(user: user)

        if onboardingCoordinator.isPresented {
            showProfile = false
            showGoalExplanation = false
            routeToCurrentTourStep()
        }
    }

    private func routeToCurrentTourStep() {
        guard onboardingCoordinator.isPresented else {
            return
        }

        switch onboardingCoordinator.currentStep {
        case .personalTarget, .alternatives:
            selectedTab = .dashboard

        case .groupStatus, .groupStreak, .groupDetails, .chat:
            selectedTab = .group

        case .ranking:
            selectedTab = .ranking
        }
    }

    private func scrollDashboardForTour(
        using proxy: ScrollViewProxy
    ) {
        guard onboardingCoordinator.isPresented,
              selectedTab == .dashboard
        else {
            return
        }

        let step = onboardingCoordinator.currentStep

        guard step == .personalTarget || step == .alternatives else {
            return
        }

        scrollDashboard(
            to: step.scrollID,
            using: proxy
        )
    }

    private func scrollDashboard(
        to scrollID: String,
        using proxy: ScrollViewProxy
    ) {
        if reduceMotion {
            proxy.scrollTo(scrollID, anchor: .top)
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                proxy.scrollTo(scrollID, anchor: .top)
            }
        }
    }

    // MARK: - Tabs

    private func memberTabs(
        user: SupabaseDataStore.TimeUpRemoteUser
    ) -> some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                rankingView
                    .toolbar {
                        profileToolbar
                    }
            }
            .tabItem {
                Label(t(.ranking), systemImage: "trophy")
            }
            .tag(MemberTab.ranking)

            NavigationStack {
                placeholderView(
                    title: t(.ai),
                    icon: "sparkles",
                    message: t(.aiComingSoon)
                )
                .toolbar {
                    profileToolbar
                }
            }
            .tabItem {
                Label(t(.ai), systemImage: "sparkles")
            }
            .tag(MemberTab.ai)

            NavigationStack {
                if dataStore.activeMemberGroup != nil {
                    MemberGroupView()
                        .toolbar {
                            profileToolbar
                        }
                } else {
                    ContentUnavailableView(
                        noActiveGroupTitle,
                        systemImage: "person.3.sequence.fill",
                        description: Text(noActiveGroupDescription)
                    )
                    .toolbar {
                        profileToolbar
                    }
                }
            }
            .tabItem {
                Label(t(.group), systemImage: "person.3")
            }
            .tag(MemberTab.group)

            NavigationStack {
                remoteDashboardView(user: user)
                    .toolbar {
                        profileToolbar
                    }
            }
            .tabItem {
                Label(
                    t(.dashboard),
                    systemImage: "square.grid.2x2.fill"
                )
            }
            .tag(MemberTab.dashboard)
        }
        .sheet(
            isPresented: $showProfile,
            onDismiss: {
                routeToCurrentTourStep()
            }
        ) {
            NavigationStack {
                SupabaseMemberProfileView(user: user)
            }
            .timeUpLocalization()
        }
        .sheet(
            isPresented: $showGoalExplanation
        ) {
            NavigationStack {
                MemberGoalExplanationView(userID: user.id)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .timeUpLocalization()
        }
    }

    // MARK: - Ranking

    private var rankingView: some View {
        Group {
            if rankingStore.isLoading &&
                rankingStore.groupRankings.isEmpty {

                VStack(spacing: 16) {
                    ProgressView()
                    Text(t(.loadingRanking))
                        .foregroundStyle(.secondary)
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
                .memberOnboardingAnchor(.ranking)

            } else if rankingStore.groupRankings.isEmpty {
                ContentUnavailableView(
                    t(.noRanking),
                    systemImage: "trophy",
                    description: Text(
                        rankingStore.lastError ?? t(.rankingWillAppear)
                    )
                )
                .memberOnboardingAnchor(.ranking)

            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(rankingStore.groupRankings) { ranking in
                                if ranking.groupID ==
                                    rankingStore.groupRankings.first?.groupID {

                                    rankingRow(ranking)
                                        .id(
                                            MemberOnboardingStep.ranking.scrollID
                                        )
                                        .memberOnboardingAnchor(.ranking)
                                } else {
                                    rankingRow(ranking)
                                }
                            }
                        }
                        .padding(20)
                    }
                    .onChange(
                        of: onboardingCoordinator.currentStep
                    ) { _, step in
                        if onboardingCoordinator.isPresented &&
                            step == .ranking {

                            proxy.scrollTo(
                                MemberOnboardingStep.ranking.scrollID,
                                anchor: .top
                            )
                        }
                    }
                    .onChange(
                        of: selectedTab
                    ) { _, tab in
                        if onboardingCoordinator.isPresented &&
                            tab == .ranking {

                            proxy.scrollTo(
                                MemberOnboardingStep.ranking.scrollID,
                                anchor: .top
                            )
                        }
                    }
                    .onAppear {
                        if onboardingCoordinator.isPresented &&
                            onboardingCoordinator.currentStep == .ranking {

                            proxy.scrollTo(
                                MemberOnboardingStep.ranking.scrollID,
                                anchor: .top
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle(t(.groupRanking))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await rankingStore.loadGroupRankings()
        }
        .refreshable {
            await rankingStore.loadGroupRankings()
        }
    }

    private func rankingRow(
        _ ranking: SupabaseRankingStore.GroupRanking
    ) -> some View {
        let isMyGroup = dataStore.groups.contains {
            $0.id == ranking.groupID
        }

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 48, height: 48)

                if ranking.rankingPosition <= 3 {
                    Image(
                        systemName: ranking.rankingPosition == 1
                            ? "trophy.fill"
                            : "medal.fill"
                    )
                    .font(.title3)
                } else {
                    Text("\(ranking.rankingPosition)")
                        .font(.headline)
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Text(ranking.groupName)
                        .font(.headline)

                    if isMyGroup {
                        Text(t(.myGroupBadge))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(.thinMaterial, in: Capsule())
                    }
                }

                HStack(spacing: 14) {
                    Label(
                        streakText(ranking.currentStreak),
                        systemImage: "flame.fill"
                    )

                    if let average = ranking.averageUsageMinutes {
                        Label(
                            formattedRankingMinutes(average),
                            systemImage: "iphone"
                        )
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text("#\(ranking.rankingPosition)")
                .font(.title3.bold())
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isMyGroup
                ? Color.secondary.opacity(0.12)
                : Color.secondary.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    private func formattedRankingMinutes(
        _ minutes: Double
    ) -> String {
        formattedDuration(max(0, Int(minutes.rounded())))
    }

    // MARK: - Dashboard

    private func remoteDashboardView(
        user: SupabaseDataStore.TimeUpRemoteUser
    ) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(
                            "\(t(.hello)) \(displayName(for: user))"
                        )
                        .font(.largeTitle.bold())

                        Text(t(.connectedToTimeUp))
                            .foregroundStyle(.secondary)
                    }

                    if let group = dataStore.activeMemberGroup {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label(
                                    t(.myGroup),
                                    systemImage: "person.3.fill"
                                )
                                .font(.headline)

                                Spacer()

                                Label(
                                    "\(dataStore.currentGroupStreak)",
                                    systemImage: "flame.fill"
                                )
                                .font(.headline)
                            }

                            Text(group.name)
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text("\(t(.groupCode)): \(group.code)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .padding()
                        .background(
                            .thinMaterial,
                            in: RoundedRectangle(cornerRadius: 18)
                        )

                        currentUserProgressCard(user: user)
                            .id(
                                MemberOnboardingStep.personalTarget.scrollID
                            )
                            .memberOnboardingAnchor(.personalTarget)

                        suggestedActionCard {
                            scrollDashboard(
                                to: MemberOnboardingStep.alternatives.scrollID,
                                using: proxy
                            )
                        }

                        alternativesSection(groupID: group.id)
                            .id(
                                MemberOnboardingStep.alternatives.scrollID
                            )

                        groupAlternativesFeedSection(groupID: group.id)

                        MemberPersonalProgressView(groupID: group.id)
                            .id(group.id)
                            .disabled(onboardingCoordinator.isPresented)

                    } else {
                        ContentUnavailableView(
                            noActiveGroupTitle,
                            systemImage: "person.3.sequence.fill"
                        )
                    }
                }
                .padding(20)
            }
            .onAppear {
                scrollDashboardForTour(using: proxy)
            }
            .onChange(
                of: onboardingCoordinator.currentStep
            ) { _, _ in
                scrollDashboardForTour(using: proxy)
            }
            .onChange(
                of: onboardingCoordinator.isPresented
            ) { _, _ in
                scrollDashboardForTour(using: proxy)
            }
            .onChange(
                of: selectedTab
            ) { _, _ in
                scrollDashboardForTour(using: proxy)
            }
            .onChange(
                of: alternativesStore.alternatives.count
            ) { _, _ in
                scrollDashboardForTour(using: proxy)
            }
            .onChange(
                of: localization.language
            ) { _, _ in
                scrollDashboardForTour(using: proxy)
            }
        }
        .navigationTitle(t(.dashboard))
        .navigationBarTitleDisplayMode(.inline)
        .task(id: dataStore.activeMemberGroup?.id) {
            guard let group = dataStore.activeMemberGroup else {
                return
            }

            await dataStore.loadDailyProgress(groupID: group.id)
            await dataStore.syncReportedScreenTime()
            await alternativesStore.load(groupID: group.id)
        }
        .onChange(
            of: localization.language
        ) { _, _ in
            guard let group = dataStore.activeMemberGroup else {
                return
            }

            Task {
                await alternativesStore.refreshLanguage(
                    groupID: group.id
                )
            }
        }
        .refreshable {
            guard let group = dataStore.activeMemberGroup else {
                return
            }

            await dataStore.loadDailyProgress(groupID: group.id)
            await dataStore.syncReportedScreenTime()
            await alternativesStore.loadAlternatives(groupID: group.id)
            await alternativesStore.loadGroupFeed(groupID: group.id)
        }
    }

    // MARK: - Suggested Action

    @ViewBuilder
    private func suggestedActionCard(
        action: @escaping () -> Void
    ) -> some View {
        if let alternative = alternativesStore.alternatives.first {
            VStack(alignment: .leading, spacing: 14) {
                Label(
                    localized(
                        "משהו טוב לעשות עכשיו",
                        "Something good to do now",
                        "شيء جيد يمكنك فعله الآن"
                    ),
                    systemImage: "figure.walk"
                )
                .font(.headline)

                Text(alternative.alternativeText)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .fixedSize(horizontal: false, vertical: true)

                Text(
                    localized(
                        "בחר רגע בלי מסך. אחרי שתבצע את הפעילות, תוכל לסמן אותה ברשימת החלופות.",
                        "Take a moment away from screens. After completing the activity, you can check it off in your alternatives.",
                        "خذ استراحة بعيدًا عن الشاشات. بعد إكمال النشاط، يمكنك تحديده في قائمة البدائل."
                    )
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Button(action: action) {
                    Label(
                        localized(
                            "לחלופות שלי",
                            "My alternatives",
                            "بدائلي"
                        ),
                        systemImage: "arrow.down"
                    )
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.borderedProminent)
                .disabled(onboardingCoordinator.isPresented)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color.accentColor.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 18)
            )
        }
    }

    // MARK: - Alternatives

    @ViewBuilder
    private func alternativesSection(
        groupID: UUID
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Label(
                    t(.alternativesTitle),
                    systemImage: "figure.walk"
                )
                .font(.title2.bold())

                Text(t(.alternativesSubtitle))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .memberOnboardingAnchor(.alternatives)

            if alternativesStore.isLoading &&
                alternativesStore.alternatives.isEmpty {

                HStack(spacing: 12) {
                    ProgressView()
                    Text(t(.loadingAlternatives))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 10)

            } else if alternativesStore.alternatives.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label(
                        t(.alternativesFinished),
                        systemImage: "checkmark.circle.fill"
                    )
                    .font(.headline)

                    Text(
                        alternativesStore.alternativesError ??
                        t(.alternativesTomorrow)
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)

            } else {
                VStack(spacing: 10) {
                    ForEach(alternativesStore.alternatives) { alternative in
                        alternativeRow(
                            alternative,
                            groupID: groupID
                        )
                    }
                }
            }

            if let error = alternativesStore.alternativesError,
               !alternativesStore.alternatives.isEmpty {

                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.red)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: 18)
        )
    }

    private func alternativeRow(
        _ alternative: SupabaseAlternativesStore.Alternative,
        groupID: UUID
    ) -> some View {
        let isCompleting = alternativesStore.isCompleting(alternative)

        return Button {
            guard !isCompleting else {
                return
            }

            Task {
                await alternativesStore.complete(
                    alternative,
                    groupID: groupID
                )
            }
        } label: {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(
                            Color.secondary.opacity(0.45),
                            lineWidth: 1.5
                        )
                        .frame(width: 28, height: 28)

                    if isCompleting {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                Text(alternative.alternativeText)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(
                    systemName: localization.language == .english
                        ? "chevron.right"
                        : "chevron.left"
                )
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(
                Color.secondary.opacity(0.07),
                in: RoundedRectangle(cornerRadius: 14)
            )
        }
        .buttonStyle(.plain)
        .disabled(isCompleting)
    }

    // MARK: - Group Alternatives Feed

    @ViewBuilder
    private func groupAlternativesFeedSection(
        groupID: UUID
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(
                    t(.groupActivityToday),
                    systemImage: "person.3.fill"
                )
                .font(.title2.bold())

                Spacer()

                if !alternativesStore.groupFeed.isEmpty {
                    Text("\(alternativesStore.groupFeed.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if alternativesStore.isLoadingFeed &&
                alternativesStore.groupFeed.isEmpty {

                HStack(spacing: 12) {
                    ProgressView()
                    Text(t(.loadingGroupActivity))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)

            } else if alternativesStore.groupFeed.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    Text(t(.noAlternativeCompleted))
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(t(.beFirstInGroup))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)

            } else {
                VStack(spacing: 10) {
                    ForEach(alternativesStore.groupFeed) { item in
                        groupAlternativeFeedRow(item)
                    }
                }
            }

            if let error = alternativesStore.feedError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.red)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: 18)
        )
    }

    private func groupAlternativeFeedRow(
        _ item: SupabaseAlternativesStore.GroupFeedItem
    ) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Color.green)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.displayName)
                    .fontWeight(.semibold)

                Text(item.alternativeText)
                    .font(.subheadline)

                Text(
                    item.completedAt.formatted(
                        date: .omitted,
                        time: .shortened
                    )
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(11)
        .background(
            Color.secondary.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 13)
        )
    }

    // MARK: - Current User Progress

    private func currentUserProgressCard(
        user: SupabaseDataStore.TimeUpRemoteUser
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(
                    t(.myToday),
                    systemImage: "chart.bar.fill"
                )
                .font(.headline)

                Spacer()

                if dataStore.isLearningDay(for: user.id) {
                    Text(t(.learningDay))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(.thinMaterial, in: Capsule())
                }
            }

            remainingTimeView(userID: user.id)

            HStack(spacing: 12) {
                progressValue(
                    title: t(.usage),
                    value: formattedMinutes(
                        dataStore.usageMinutes(for: user.id)
                    ),
                    icon: "iphone"
                )

                progressValue(
                    title: t(.target),
                    value: formattedMinutes(
                        dataStore.targetMinutes(for: user.id)
                    ),
                    icon: "target"
                )
            }

            statusView(userID: user.id)

            Divider()

            Button {
                showGoalExplanation = true
            } label: {
                HStack(spacing: 9) {
                    Image(systemName: "info.circle")

                    Text(
                        localized(
                            "איך נקבע היעד שלי?",
                            "How is my target set?",
                            "كيف يتم تحديد هدفي؟"
                        )
                    )

                    Spacer(minLength: 0)

                    Image(
                        systemName: localization.language == .english
                            ? "chevron.right"
                            : "chevron.left"
                    )
                    .font(.caption)
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.vertical, 3)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)
            .disabled(onboardingCoordinator.isPresented)
            .accessibilityIdentifier("goal-explanation-button")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: 18)
        )
    }

    @ViewBuilder
    private func remainingTimeView(
        userID: UUID
    ) -> some View {
        if !dataStore.isLearningDay(for: userID),
           let target = dataStore.targetMinutes(for: userID),
           let usage = dataStore.usageMinutes(for: userID),
           target > 0,
           usage >= 0 {

            let remaining = max(0, target - usage)
            let exceeded = usage > target

            VStack(alignment: .leading, spacing: 10) {
                Text(
                    exceeded
                        ? localized(
                            "מעבר ליעד היומי",
                            "Above your daily target",
                            "فوق هدفك اليومي"
                        )
                        : localized(
                            "זמן שנותר ליעד",
                            "Time remaining to your target",
                            "الوقت المتبقي حتى هدفك"
                        )
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Text(
                    formattedDuration(
                        exceeded ? usage - target : remaining
                    )
                )
                .font(
                    .system(
                        size: 36,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .monospacedDigit()
                .foregroundStyle(
                    exceeded ? Color.red : Color.primary
                )
                .accessibilityIdentifier("remaining-screen-time")

                ProgressView(
                    value: min(
                        1.0,
                        Double(usage) / Double(target)
                    ),
                    total: 1.0
                )
                .tint(
                    exceeded ? Color.red : Color.accentColor
                )
                .accessibilityLabel(
                    localized(
                        "שימוש מתוך היעד היומי",
                        "Usage against your daily target",
                        "الاستخدام مقارنة بهدفك اليومي"
                    )
                )

                Text(
                    exceeded
                        ? localized(
                            "אפשר לבחור עכשיו פעילות בלי מסך ולהמשיך לצמצם את השימוש.",
                            "Choose a screen-free activity now to keep reducing your usage.",
                            "يمكنك اختيار نشاط دون شاشة الآن لمواصلة تقليل الاستخدام."
                        )
                        : remaining == 0
                            ? localized(
                                "הגעת בדיוק ליעד. זה זמן טוב להניח את הטלפון.",
                                "You have reached your target limit. This is a good time to put your phone down.",
                                "وصلت إلى حد هدفك. هذا وقت مناسب لترك الهاتف."
                            )
                            : localized(
                                "כל רגע בלי מסך עוזר לך ולקבוצה.",
                                "Every moment away from screens helps you and your group.",
                                "كل لحظة بعيدًا عن الشاشات تساعدك وتساعد مجموعتك."
                            )
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Group

    private func remoteGroupView(
        group: SupabaseDataStore.TimeUpRemoteGroup
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .center, spacing: 16) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 46))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.name)
                            .font(.largeTitle.bold())

                        Text("\(t(.groupCode)): \(group.code)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                groupStreakCard
                todayGroupStatusCard
                Divider()
                groupMembersSection
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .navigationTitle(t(.group))
        .navigationBarTitleDisplayMode(.inline)
        .task(id: group.id) {
            await dataStore.loadGroupMembers(groupID: group.id)
            await dataStore.loadDailyProgress(groupID: group.id)
            await dataStore.syncReportedScreenTime()
        }
        .refreshable {
            await dataStore.loadGroupMembers(groupID: group.id)
            await dataStore.loadDailyProgress(groupID: group.id)
            await dataStore.syncReportedScreenTime()
        }
    }

    private var groupStreakCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 58, height: 58)

                Image(systemName: "flame.fill")
                    .font(.system(size: 28))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(t(.groupStreak))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(streakText(dataStore.currentGroupStreak))
                    .font(.title2.bold())
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: 18)
        )
    }

    @ViewBuilder
    private var todayGroupStatusCard: some View {
        if let result = dataStore.groupResult() {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label(
                        t(.groupStatusToday),
                        systemImage: "chart.bar.fill"
                    )
                    .font(.headline)

                    Spacer()

                    Image(
                        systemName: result.succeeded
                            ? "checkmark.circle.fill"
                            : "xmark.circle.fill"
                    )
                    .font(.title2)
                    .foregroundStyle(
                        result.succeeded ? Color.green : Color.red
                    )
                }

                HStack(spacing: 12) {
                    groupMetric(
                        title: t(.completed),
                        value: "\(result.completedMemberCount)/\(result.memberCount)",
                        icon: "person.2.fill"
                    )

                    groupMetric(
                        title: t(.average),
                        value: formattedMinutes(
                            result.averageUsageMinutes
                        ),
                        icon: "chart.bar.xaxis"
                    )
                }

                Label(
                    result.succeeded
                        ? t(.groupAchievedTarget)
                        : t(.groupStillInProgress),
                    systemImage: result.succeeded
                        ? "checkmark.circle.fill"
                        : "clock.fill"
                )
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(
                    result.succeeded ? Color.green : Color.secondary
                )
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                .thinMaterial,
                in: RoundedRectangle(cornerRadius: 18)
            )
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Label(
                    t(.groupStatusToday),
                    systemImage: "clock.fill"
                )
                .font(.headline)

                Text(t(.groupResultPending))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                .thinMaterial,
                in: RoundedRectangle(cornerRadius: 18)
            )
        }
    }

    private func groupMetric(
        title: String,
        value: String,
        icon: String
    ) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.headline)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            Color.secondary.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 12)
        )
    }

    @ViewBuilder
    private var groupMembersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(
                    t(.members),
                    systemImage: "person.2.fill"
                )
                .font(.title2.bold())

                Spacer()

                if !dataStore.groupMembers.isEmpty {
                    Text("\(dataStore.groupMembers.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if dataStore.isLoadingGroupMembers ||
                dataStore.isLoadingDailyProgress {

                HStack(spacing: 12) {
                    ProgressView()
                    Text(t(.loadingGroup))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)

            } else if dataStore.groupMembers.isEmpty {
                ContentUnavailableView(
                    t(.noMembers),
                    systemImage: "person.2.slash",
                    description: Text(noActiveMembersDescription)
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(dataStore.groupMembers) { member in
                        groupMemberRow(member: member)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func groupMemberRow(
        member: SupabaseDataStore.TimeUpRemoteUser
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.secondary.opacity(0.12))
                        .frame(width: 46, height: 46)

                    Image(systemName: "person.fill")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(displayName(for: member))
                            .font(.headline)

                        if member.id == dataStore.currentUser?.id {
                            Text(t(.you))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(
                                    .thinMaterial,
                                    in: Capsule()
                                )
                        }
                    }

                    if dataStore.isLearningDay(for: member.id) {
                        Text(t(.learningDay))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if let membership =
                        dataStore.groupMemberships.first(
                            where: { $0.userID == member.id }
                        ),
                        let joinedAt = membership.joinedAt {

                        Text(joinedText(joinedAt))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
                memberStatusIcon(userID: member.id)
            }

            Divider()

            HStack(spacing: 12) {
                progressValue(
                    title: t(.usage),
                    value: formattedMinutes(
                        dataStore.usageMinutes(for: member.id)
                    ),
                    icon: "iphone"
                )

                progressValue(
                    title: t(.target),
                    value: formattedMinutes(
                        dataStore.targetMinutes(for: member.id)
                    ),
                    icon: "target"
                )
            }
        }
        .padding(14)
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    // MARK: - Progress Components

    private func progressValue(
        title: String,
        value: String,
        icon: String
    ) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.headline)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.headline)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            Color.secondary.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 12)
        )
    }

    @ViewBuilder
    private func memberStatusIcon(
        userID: UUID
    ) -> some View {
        if dataStore.isLearningDay(for: userID) {
            Image(systemName: "book.fill")
                .font(.title3)
        } else if let achieved = dataStore.achieved(for: userID) {
            Image(
                systemName: achieved
                    ? "checkmark.circle.fill"
                    : "xmark.circle.fill"
            )
            .font(.title2)
            .foregroundStyle(achieved ? Color.green : Color.red)
        } else {
            Image(systemName: "clock.fill")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func statusView(
        userID: UUID
    ) -> some View {
        if dataStore.isLearningDay(for: userID) {
            Label(
                t(.learningDay),
                systemImage: "book.fill"
            )
            .font(.subheadline)
            .fontWeight(.semibold)
        } else if let achieved = dataStore.achieved(for: userID) {
            Label(
                achieved ? t(.achievedTarget) : t(.targetNotAchieved),
                systemImage: achieved
                    ? "checkmark.circle.fill"
                    : "xmark.circle.fill"
            )
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(achieved ? Color.green : Color.red)
        } else {
            Label(
                t(.dayInProgress),
                systemImage: "clock.fill"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private func formattedMinutes(
        _ minutes: Int?
    ) -> String {
        guard let minutes else {
            return "—"
        }

        return formattedDuration(max(0, minutes))
    }

    private func formattedDuration(
        _ minutes: Int
    ) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

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

    // MARK: - Profile

    @ToolbarContentBuilder
    private var profileToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showProfile = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 28))
                }
            }
            .disabled(onboardingCoordinator.isPresented)
            .accessibilityLabel(t(.profile))
        }
    }

    // MARK: - States

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text(t(.accountLoading))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var unavailableView: some View {
        ContentUnavailableView(
            t(.accountUnavailable),
            systemImage: "person.crop.circle.badge.exclamationmark",
            description: Text(
                dataStore.lastError ?? t(.tryLoginAgain)
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

            Image(systemName: icon)
                .font(.system(size: 54))

            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func displayName(
        for user: SupabaseDataStore.TimeUpRemoteUser
    ) -> String {
        let name = user.displayName?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return name.isEmpty ? "TimeUp" : name
    }

    // MARK: - Localization Helpers

    private func t(
        _ key: TimeUpText
    ) -> String {
        localization.text(key)
    }

    private func localized(
        _ hebrew: String,
        _ english: String,
        _ arabic: String
    ) -> String {
        switch localization.language {
        case .hebrew:
            return hebrew
        case .english:
            return english
        case .arabic:
            return arabic
        }
    }

    private func streakText(
        _ streak: Int
    ) -> String {
        switch localization.language {
        case .hebrew:
            return "\(streak) ימים"
        case .english:
            return streak == 1 ? "1 day" : "\(streak) days"
        case .arabic:
            return "\(streak) أيام"
        }
    }

    private func joinedText(
        _ date: Date
    ) -> String {
        let formattedDate = date.formatted(
            date: .abbreviated,
            time: .omitted
        )

        switch localization.language {
        case .hebrew:
            return "הצטרף \(formattedDate)"
        case .english:
            return "Joined \(formattedDate)"
        case .arabic:
            return "انضم \(formattedDate)"
        }
    }

    private var noActiveGroupTitle: String {
        localized(
            "אין קבוצה פעילה",
            "No Active Group",
            "لا توجد مجموعة نشطة"
        )
    }

    private var noActiveGroupDescription: String {
        localized(
            "החשבון אינו משויך כרגע לקבוצה פעילה.",
            "Your account is not currently assigned to an active group.",
            "حسابك غير مرتبط حاليًا بمجموعة نشطة."
        )
    }

    private var noActiveMembersDescription: String {
        localized(
            "לא נמצאו חברים פעילים בקבוצה.",
            "No active members were found in the group.",
            "لم يتم العثور على أعضاء نشطين في المجموعة."
        )
    }
}

// MARK: - Goal Explanation

private struct MemberGoalExplanationView: View {

    let userID: UUID

    @Environment(\.dismiss)
    private var dismiss

    @StateObject private var dataStore = SupabaseDataStore.shared
    @ObservedObject private var localization = TimeUpLocalization.shared

    private enum GoalMethod {
        case personal
        case average
        case manual
        case unknown
    }

    private var group: SupabaseDataStore.TimeUpRemoteGroup? {
        dataStore.activeMemberGroup
    }

    private var goalMethod: GoalMethod {
        let raw = dataStore.target(for: userID)?.goalMethod
            ?? group?.goalMethod
            ?? ""

        switch raw {
        case "personal_percentage", "previousDay":
            return .personal
        case "group_average_percentage", "adaptiveAverage":
            return .average
        case "manual":
            return .manual
        default:
            return .unknown
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "target")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.accentColor)

                    Text(methodTitle)
                        .font(.title2.bold())

                    Text(methodDescription)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Label(
                        localized(
                            "המספרים שלך היום",
                            "Your numbers today",
                            "أرقامك اليوم"
                        ),
                        systemImage: "chart.bar"
                    )
                    .font(.headline)

                    metricRow(
                        title: localized(
                            "היעד שלי היום",
                            "My target today",
                            "هدفي اليوم"
                        ),
                        value: formattedMinutes(
                            dataStore.targetMinutes(for: userID)
                        )
                    )

                    Divider()

                    metricRow(
                        title: localized(
                            "השימוש שלי היום",
                            "My usage today",
                            "استخدامي اليوم"
                        ),
                        value: formattedMinutes(
                            dataStore.usageMinutes(for: userID)
                        )
                    )

                    if goalMethod == .personal || goalMethod == .average,
                       let percent = group?.reductionPercent {

                        Divider()

                        metricRow(
                            title: localized(
                                "אחוז ההפחתה שהוגדר בקבוצה כיום",
                                "Current group reduction setting",
                                "نسبة التخفيض المحددة حاليًا للمجموعة"
                            ),
                            value: "\(percent)%"
                        )
                    }
                }
                .padding()
                .background(
                    .thinMaterial,
                    in: RoundedRectangle(cornerRadius: 18)
                )

                if dataStore.isLearningDay(for: userID) {
                    explanationCard(
                        title: localized(
                            "יום הלמידה",
                            "Learning day",
                            "يوم التعلم"
                        ),
                        text: localized(
                            "יום הלמידה מודד את השימוש שלך ומספק נתונים לקביעת היעד הראשון. הוא אינו נספר ברצף הקבוצתי.",
                            "The learning day measures your usage and provides data for your first target. It does not count toward the group streak.",
                            "يقيس يوم التعلم استخدامك ويوفر بيانات لتحديد هدفك الأول. ولا يُحتسب ضمن سلسلة نجاح المجموعة."
                        ),
                        icon: "book"
                    )
                }

                if goalMethod == .personal || goalMethod == .average {
                    explanationCard(
                        title: localized(
                            "מה קורה כשהקבוצה לא מצליחה?",
                            "What if the group does not succeed?",
                            "ماذا يحدث إذا لم تنجح المجموعة؟"
                        ),
                        text: localized(
                            "היעד הקודם נשאר. היעד הבא מתעדכן רק כאשר כל חברי הקבוצה עומדים ביעד שלהם.",
                            "The previous target stays in place. The next target changes only when every group member meets their target.",
                            "يبقى الهدف السابق كما هو. ولا يتغير الهدف التالي إلا عندما يحقق جميع أعضاء المجموعة أهدافهم."
                        ),
                        icon: "arrow.triangle.2.circlepath"
                    )
                }

                explanationCard(
                    title: localized(
                        "מצליחים ביחד",
                        "Succeed together",
                        "ننجح معًا"
                    ),
                    text: localized(
                        "הקבוצה עוזרת לך לעמוד ביעד — ואתה עוזר לקבוצה להצליח. יום הצלחה קבוצתי נספר רק כשכולם עומדים ביעד. אם אחד נכשל, הרצף הקבוצתי מתאפס.",
                        "Your group helps you meet your target, and you help your group succeed. A successful group day counts only when everyone meets their target. If one member fails, the group streak resets.",
                        "تساعدك المجموعة على تحقيق هدفك، وأنت تساعد المجموعة على النجاح. لا يُحتسب يوم نجاح للمجموعة إلا عندما يحقق الجميع أهدافهم. وإذا أخفق أحد الأعضاء، تعود سلسلة المجموعة إلى الصفر."
                    ),
                    icon: "person.3"
                )
            }
            .padding(20)
        }
        .navigationTitle(
            localized(
                "איך נקבע היעד שלי?",
                "How is my target set?",
                "كيف يتم تحديد هدفي؟"
            )
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(
                    localized("סיום", "Done", "تم")
                ) {
                    dismiss()
                }
            }
        }
    }

    private var methodTitle: String {
        switch goalMethod {
        case .personal:
            return localized(
                "יעד לפי השימוש האישי",
                "A target based on your own usage",
                "هدف يعتمد على استخدامك الشخصي"
            )

        case .average:
            return localized(
                "יעד לפי ממוצע הקבוצה",
                "A target based on the group average",
                "هدف يعتمد على متوسط المجموعة"
            )

        case .manual:
            return localized(
                "יעד אישי שהמנהל הגדיר",
                "A personal target set by your admin",
                "هدف شخصي حدده المدير"
            )

        case .unknown:
            return localized(
                "היעד האישי שלך",
                "Your personal target",
                "هدفك الشخصي"
            )
        }
    }

    private var methodDescription: String {
        switch goalMethod {
        case .personal:
            return localized(
                "כשהקבוצה מצליחה ביום מסוים, היעד האישי הבא מחושב לפי השימוש שלך באותו יום, פחות אחוז ההפחתה שהמנהל הגדיר. לכן לכל חבר יכול להיות יעד אחר.",
                "When the group succeeds on a given day, your next personal target is calculated from your own usage that day, minus the reduction percentage set by your admin. Each member can therefore have a different target.",
                "عندما تنجح المجموعة في يوم معين، يُحسب هدفك الشخصي التالي من استخدامك في ذلك اليوم بعد خصم نسبة التخفيض التي حددها المدير. لذلك قد يكون لكل عضو هدف مختلف."
            )

        case .average:
            return localized(
                "כשהקבוצה מצליחה ביום מסוים, מחשבים את ממוצע השימוש בפועל של חברי הקבוצה באותו יום ומפחיתים את האחוז שהמנהל הגדיר. כולם מקבלים אותו יעד, בעיגול כלפי מעלה לדקה שלמה.",
                "When the group succeeds on a given day, the members' actual usage that day is averaged and reduced by the percentage set by your admin. Everyone receives the same target, rounded up to a whole minute.",
                "عندما تنجح المجموعة في يوم معين، يُحسب متوسط الاستخدام الفعلي للأعضاء في ذلك اليوم وتُخصم منه النسبة التي حددها المدير. يحصل الجميع على الهدف نفسه، مع التقريب إلى الأعلى إلى دقيقة كاملة."
            )

        case .manual:
            return localized(
                "המנהל הגדיר לך יעד אישי קבוע. היעד נשאר כפי שהוא עד שהמנהל משנה אותו, גם כאשר הרצף הקבוצתי עולה או מתאפס.",
                "Your admin has set a fixed personal target for you. It stays the same until your admin changes it, even when the group streak increases or resets.",
                "حدد المدير لك هدفًا شخصيًا ثابتًا. ويبقى كما هو حتى يغيره المدير، حتى عندما ترتفع سلسلة نجاح المجموعة أو تعود إلى الصفر."
            )

        case .unknown:
            return localized(
                "פרטי שיטת היעד אינם זמינים כרגע. המספרים המוצגים כאן הם הנתונים שנמצאים בחשבון שלך.",
                "The target method details are currently unavailable. The numbers shown here are the data available in your account.",
                "تفاصيل طريقة تحديد الهدف غير متاحة حاليًا. الأرقام المعروضة هنا هي البيانات المتاحة في حسابك."
            )
        }
    }

    private func metricRow(
        title: String,
        value: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer(minLength: 12)

            Text(value)
                .font(.headline)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        }
    }

    private func explanationCard(
        title: String,
        text: String,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.secondary.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 18)
        )
    }

    private func formattedMinutes(
        _ minutes: Int?
    ) -> String {
        guard let minutes else {
            return "—"
        }

        let safeMinutes = max(0, minutes)
        let hours = safeMinutes / 60
        let remainder = safeMinutes % 60

        if hours == 0 {
            return localized(
                "\(remainder) דק׳",
                "\(remainder) min",
                "\(remainder) د"
            )
        }

        if remainder == 0 {
            return localized(
                "\(hours) שע׳",
                "\(hours) hr",
                "\(hours) س"
            )
        }

        return localized(
            "\(hours) שע׳ \(remainder) דק׳",
            "\(hours) hr \(remainder) min",
            "\(hours) س \(remainder) د"
        )
    }

    private func localized(
        _ hebrew: String,
        _ english: String,
        _ arabic: String
    ) -> String {
        switch localization.language {
        case .hebrew:
            return hebrew
        case .english:
            return english
        case .arabic:
            return arabic
        }
    }
}

// MARK: - Supabase Member Profile

private struct SupabaseMemberProfileView: View {

    let user: SupabaseDataStore.TimeUpRemoteUser

    @Environment(\.dismiss)
    private var dismiss

    @StateObject private var dataStore = SupabaseDataStore.shared
    @ObservedObject private var localization = TimeUpLocalization.shared

    @State private var isLoggingOut = false

    var body: some View {
        List {
            Section {
                VStack(spacing: 14) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 82))
                        .foregroundStyle(.secondary)

                    Text(user.displayName ?? "TimeUp")
                        .font(.title2)
                        .fontWeight(.bold)

                    if let email = user.email {
                        Text(email)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }

            Section {
                NavigationLink {
                    PersonalSettingsView()
                } label: {
                    Label(
                        localization.text(.settings),
                        systemImage: "gearshape"
                    )
                }
            }

            Section {
                Button(role: .destructive) {
                    logout()
                } label: {
                    HStack {
                        Label(
                            localization.text(.logout),
                            systemImage: "rectangle.portrait.and.arrow.right"
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
        .navigationTitle(localization.text(.profile))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(localization.text(.close)) {
                    dismiss()
                }
            }
        }
    }

    private func logout() {
        isLoggingOut = true

        Task {
            do {
                try await SupabaseManager.shared.client.auth.signOut()

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