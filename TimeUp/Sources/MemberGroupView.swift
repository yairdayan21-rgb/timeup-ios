import SwiftUI

struct MemberGroupView: View {

    @StateObject private var dataStore = SupabaseDataStore.shared
    @StateObject private var chatStore = SupabaseChatStore.shared

    @ObservedObject private var localization = TimeUpLocalization.shared
    @ObservedObject private var onboardingCoordinator =
        MemberOnboardingCoordinator.shared

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var selectedSection: GroupSection = .overview
    @State private var pendingChatDraft: String?

    private enum GroupSection: CaseIterable, Hashable {
        case overview
        case detail
        case dashboard
        case members
        case chat
    }

    private var group: SupabaseDataStore.TimeUpRemoteGroup? {
        dataStore.activeMemberGroup
    }

    private var currentUser: SupabaseDataStore.TimeUpRemoteUser? {
        dataStore.currentUser
    }

    private var unreadChatCount: Int {
        guard let group else {
            return 0
        }

        return chatStore.unreadCount(for: group.id)
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
                            overviewView(group: group)

                        case .detail:
                            groupDetailView(group: group)

                        case .dashboard:
                            dashboardView(group: group)

                        case .members:
                            membersView(group: group)

                        case .chat:
                            MemberGroupChatView(
                                group: group,
                                initialDraft: pendingChatDraft ?? ""
                            )
                            .onAppear {
                                // The chat owns its editable draft now.
                                pendingChatDraft = nil
                            }
                        }
                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                }
                .navigationTitle(group.name)
                .navigationBarTitleDisplayMode(.inline)
                .task(id: group.id) {
                    await loadGroup(group: group)
                }
                .refreshable {
                    await loadGroup(group: group)
                }
            } else {
                ContentUnavailableView(
                    noGroupTitle,
                    systemImage: "person.3",
                    description: Text(noGroupDescription)
                )
            }
        }
        .onAppear {
            routeToCurrentTourStep()
        }
        .onChange(
            of: onboardingCoordinator.currentStep
        ) { _, _ in
            routeToCurrentTourStep()
        }
        .onChange(
            of: onboardingCoordinator.isPresented
        ) { _, _ in
            routeToCurrentTourStep()
        }
        .onChange(of: group?.id) { _, _ in
            pendingChatDraft = nil
            selectedSection = .overview
            routeToCurrentTourStep()
        }
        .timeUpLocalization()
    }

    // MARK: - Guided Tour

    private func routeToCurrentTourStep() {
        guard onboardingCoordinator.isPresented else {
            return
        }

        switch onboardingCoordinator.currentStep {
        case .groupStatus, .groupStreak:
            selectedSection = .overview

        case .groupDetails:
            selectedSection = .detail

        case .chat:
            selectedSection = .chat

        case .personalTarget, .alternatives, .ranking:
            break
        }
    }

    private func scrollOverviewForTour(
        using proxy: ScrollViewProxy
    ) {
        guard onboardingCoordinator.isPresented,
              selectedSection == .overview
        else {
            return
        }

        let step = onboardingCoordinator.currentStep

        guard step == .groupStatus || step == .groupStreak else {
            return
        }

        if reduceMotion {
            proxy.scrollTo(step.scrollID, anchor: .top)
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                proxy.scrollTo(step.scrollID, anchor: .top)
            }
        }
    }

    private func scrollDetailsForTour(
        using proxy: ScrollViewProxy
    ) {
        guard onboardingCoordinator.isPresented,
              onboardingCoordinator.currentStep == .groupDetails,
              selectedSection == .detail
        else {
            return
        }

        proxy.scrollTo(
            MemberOnboardingStep.groupDetails.scrollID,
            anchor: .top
        )
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(
                        GroupSection.allCases,
                        id: \.self
                    ) { section in
                        sectionButton(section)
                            .id(section)
                            .anchorPreference(
                                key: MemberOnboardingAnchorPreferenceKey.self,
                                value: .bounds
                            ) { anchor in
                                if section == .chat {
                                    return [.chat: anchor]
                                }

                                return [:]
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .onAppear {
                proxy.scrollTo(selectedSection, anchor: .center)
            }
            .onChange(
                of: selectedSection
            ) { _, section in
                if reduceMotion {
                    proxy.scrollTo(section, anchor: .center)
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(section, anchor: .center)
                    }
                }
            }
            .onChange(
                of: localization.language
            ) { _, _ in
                proxy.scrollTo(selectedSection, anchor: .center)
            }
        }
    }

    private func sectionButton(
        _ section: GroupSection
    ) -> some View {
        Button {
            guard !onboardingCoordinator.isPresented else {
                return
            }

            if reduceMotion {
                selectedSection = section
            } else {
                withAnimation(.easeInOut(duration: 0.18)) {
                    selectedSection = section
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(sectionTitle(section))

                if section == .chat && unreadChatCount > 0 {
                    Text(
                        unreadChatCount > 99
                            ? "99+"
                            : "\(unreadChatCount)"
                    )
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background {
                        Capsule()
                            .fill(Color.red)
                    }
                }
            }
            .font(.subheadline)
            .fontWeight(
                selectedSection == section ? .bold : .medium
            )
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background {
                if selectedSection == section {
                    Capsule()
                        .fill(Color.accentColor)
                } else {
                    Capsule()
                        .fill(Color.secondary.opacity(0.12))
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

    // MARK: - Overview

    private func overviewView(
        group: SupabaseDataStore.TimeUpRemoteGroup
    ) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    groupHeader(group: group)

                    groupStreakCard(group: group)
                        .id(
                            MemberOnboardingStep.groupStreak.scrollID
                        )
                        .memberOnboardingAnchor(.groupStreak)

                    journeyCard(group: group)

                    todayStatusCard(group: group)
                        .id(
                            MemberOnboardingStep.groupStatus.scrollID
                        )
                        .memberOnboardingAnchor(.groupStatus)

                    encouragementCard

                    membersPreview(group: group)

                    if let error = dataStore.lastError {
                        errorCard(error)
                    }
                }
                .padding(16)
            }
            .onAppear {
                scrollOverviewForTour(using: proxy)
            }
            .onChange(
                of: onboardingCoordinator.currentStep
            ) { _, _ in
                scrollOverviewForTour(using: proxy)
            }
            .onChange(
                of: onboardingCoordinator.isPresented
            ) { _, _ in
                scrollOverviewForTour(using: proxy)
            }
            .onChange(
                of: selectedSection
            ) { _, _ in
                scrollOverviewForTour(using: proxy)
            }
            .onChange(
                of: dataStore.isLoadingGroupMembers
            ) { _, _ in
                scrollOverviewForTour(using: proxy)
            }
            .onChange(
                of: dataStore.isLoadingDailyProgress
            ) { _, _ in
                scrollOverviewForTour(using: proxy)
            }
            .onChange(
                of: localization.language
            ) { _, _ in
                scrollOverviewForTour(using: proxy)
            }
        }
    }

    // MARK: - Encouragement

    private var encouragementCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                localized(
                    "עוזרים אחד לשני",
                    "Support each other",
                    "ندعم بعضنا"
                ),
                systemImage: "hands.clap"
            )
            .font(.headline)

            Text(
                localized(
                    "מילה טובה או הזמנה לפעילות בלי מסך יכולים להיות הצעד הבא שלכם ביחד.",
                    "A kind word or an invitation to a screen-free activity can be your next step together.",
                    "قد تكون كلمة طيبة أو دعوة إلى نشاط دون شاشة خطوتكم التالية معًا."
                )
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

            Button {
                openEncouragement(for: nil)
            } label: {
                Label(
                    localized(
                        "לעודד את הקבוצה",
                        "Encourage the group",
                        "شجّع المجموعة"
                    ),
                    systemImage: "bubble.left.and.bubble.right"
                )
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .disabled(
                currentUser == nil ||
                onboardingCoordinator.isPresented
            )
            .accessibilityIdentifier("encourage-group-button")

            Text(
                localized(
                    "ההודעה תיפתח כטיוטה בצ׳אט הקבוצתי. אפשר לערוך אותה לפני השליחה.",
                    "The message opens as a draft in the group chat. You can edit it before sending.",
                    "تُفتح الرسالة كمسودة في دردشة المجموعة. يمكنك تعديلها قبل إرسالها."
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.accentColor.opacity(0.08),
            in: RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
        )
    }

    @ViewBuilder
    private func encourageMemberButton(
        _ member: SupabaseDataStore.TimeUpRemoteUser
    ) -> some View {
        if let currentUser, member.id != currentUser.id {
            Button {
                openEncouragement(for: member)
            } label: {
                Label(
                    localized(
                        "לעודד",
                        "Encourage",
                        "شجّع"
                    ),
                    systemImage: "bubble.left"
                )
                .font(.caption)
                .fontWeight(.semibold)
            }
            .buttonStyle(.bordered)
            .disabled(onboardingCoordinator.isPresented)
            .accessibilityLabel(
                localized(
                    "לעודד את \(memberName(member)) בצ׳אט הקבוצתי",
                    "Encourage \(memberName(member)) in the group chat",
                    "شجّع \(memberName(member)) في دردشة المجموعة"
                )
            )
            .accessibilityIdentifier(
                "encourage-member-\(member.id.uuidString)"
            )
        }
    }

    private func openEncouragement(
        for member: SupabaseDataStore.TimeUpRemoteUser?
    ) {
        guard
            currentUser != nil,
            group != nil,
            !onboardingCoordinator.isPresented
        else {
            return
        }

        if let member {
            let name = memberName(member)

            pendingChatDraft = localized(
                "\(name), אנחנו איתך! רוצה לצאת להליכה בלי מסכים? נעזור אחד לשני לעמוד ביעד.",
                "\(name), we're with you! Want to go for a screen-free walk? Let's help each other meet our targets.",
                "\(name)، نحن معك! هل ترغب في المشي دون شاشات؟ لنساعد بعضنا على تحقيق أهدافنا."
            )
        } else {
            pendingChatDraft = localized(
                "בואו נעזור אחד לשני לעמוד ביעד היום. מי מצטרף לפעילות בלי מסכים?",
                "Let's help each other meet today's targets. Who wants to join a screen-free activity?",
                "لنساعد بعضنا على تحقيق أهداف اليوم. من ينضم إلى نشاط دون شاشات؟"
            )
        }

        selectedSection = .chat
    }

    private func memberName(
        _ member: SupabaseDataStore.TimeUpRemoteUser
    ) -> String {
        let name = member.displayName?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return name.isEmpty ? genericUserText : name
    }

    // MARK: - Header

    private func groupHeader(
        group: SupabaseDataStore.TimeUpRemoteGroup
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(group.name)
                .font(.largeTitle)
                .fontWeight(.bold)

            HStack(spacing: 6) {
                Image(systemName: "person.3.fill")
                Text(membersCountText(memberCount))
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Group Streak

    private func groupStreakCard(
        group: SupabaseDataStore.TimeUpRemoteGroup
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(groupStreakTitle)
                        .font(.headline)

                    Text(daysText(group.currentStreak))
                        .font(
                            .system(
                                size: 34,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                }

                Spacer()

                Image(systemName: "flame.fill")
                    .font(.system(size: 40))
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
            .fill(Color.secondary.opacity(0.10))
        }
    }

    // MARK: - Journey

    private func journeyCard(
        group: SupabaseDataStore.TimeUpRemoteGroup
    ) -> some View {
        let successDays = max(group.successDays ?? 7, 1)
        let streak = group.currentStreak

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(groupJourneyTitle)
                        .font(.headline)

                    Text(
                        journeySubtitle(
                            streak: streak,
                            successDays: successDays
                        )
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(min(streak, successDays))/\(successDays)")
                    .font(.headline)
                    .monospacedDigit()
            }

            ProgressView(
                value: Double(min(streak, successDays)),
                total: Double(successDays)
            )

            LazyVGrid(
                columns: [
                    GridItem(
                        .adaptive(minimum: 42, maximum: 48),
                        spacing: 10
                    )
                ],
                spacing: 10
            ) {
                ForEach(1...successDays, id: \.self) { day in
                    ZStack {
                        Circle()
                            .fill(
                                day <= streak
                                    ? Color.accentColor
                                    : Color.secondary.opacity(0.14)
                            )
                            .frame(width: 42, height: 42)

                        if day <= streak {
                            Image(systemName: "checkmark")
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        } else {
                            Text("\(day)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
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
            .fill(Color.secondary.opacity(0.10))
        }
    }

    private func journeySubtitle(
        streak: Int,
        successDays: Int
    ) -> String {
        if streak >= successDays {
            return localized(
                "הקבוצה השלימה את היעד",
                "The group completed the goal",
                "أكملت المجموعة الهدف"
            )
        }

        let remaining = max(successDays - streak, 0)

        return localized(
            "עוד \(remaining) ימים להשלמת היעד",
            remaining == 1
                ? "1 more day to complete the goal"
                : "\(remaining) more days to complete the goal",
            "متبقي \(remaining) أيام لإكمال الهدف"
        )
    }

    // MARK: - Today

    private func todayStatusCard(
        group: SupabaseDataStore.TimeUpRemoteGroup
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(todayInGroupTitle)
                    .font(.headline)

                Spacer()

                Text(
                    Date.now.formatted(
                        .dateTime
                            .day()
                            .month()
                            .locale(localization.language.locale)
                    )
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(groupMembersTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(memberCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(currentStreakTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(group.currentStreak)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }

            if let result = todayGroupResult(group: group) {
                Divider()

                HStack(spacing: 10) {
                    Image(
                        systemName: result.succeeded
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
                Text(pendingResultText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background {
            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
            .fill(Color.secondary.opacity(0.10))
        }
    }

    // MARK: - Members Preview

    private func membersPreview(
        group: SupabaseDataStore.TimeUpRemoteGroup
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(groupMembersTitle)
                    .font(.headline)

                Spacer()

                Button(showAllText) {
                    guard !onboardingCoordinator.isPresented else {
                        return
                    }

                    selectedSection = .members
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
                        systemImage: "person.3"
                    )
                }
            } else {
                ForEach(
                    Array(dataStore.groupMembers.prefix(4))
                ) { member in
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(
                                member.displayName ?? genericUserText
                            )
                            .fontWeight(.semibold)

                            if member.id == currentUser?.id {
                                Text(youText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        encourageMemberButton(member)
                    }

                    if member.id !=
                        dataStore.groupMembers.prefix(4).last?.id {

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
            .fill(Color.secondary.opacity(0.10))
        }
    }

    // MARK: - Detail

    private func groupDetailView(
        group: SupabaseDataStore.TimeUpRemoteGroup
    ) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(groupDetailTitle)
                        .font(.title2.bold())
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .id(
                            MemberOnboardingStep.groupDetails.scrollID
                        )
                        .memberOnboardingAnchor(.groupDetails)

                    if dataStore.dailyResults.isEmpty {
                        ContentUnavailableView(
                            noDataTitle,
                            systemImage: "chart.bar.doc.horizontal",
                            description: Text(noDataDescription)
                        )
                    } else {
                        ForEach(dataStore.groupMembers) { member in
                            memberProgressCard(
                                member: member,
                                group: group
                            )
                        }
                    }
                }
                .padding(16)
            }
            .onAppear {
                scrollDetailsForTour(using: proxy)
            }
            .onChange(
                of: onboardingCoordinator.currentStep
            ) { _, _ in
                scrollDetailsForTour(using: proxy)
            }
            .onChange(
                of: onboardingCoordinator.isPresented
            ) { _, _ in
                scrollDetailsForTour(using: proxy)
            }
            .onChange(
                of: selectedSection
            ) { _, _ in
                scrollDetailsForTour(using: proxy)
            }
        }
    }

    // MARK: - Dashboard

    private func dashboardView(
        group: SupabaseDataStore.TimeUpRemoteGroup
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(dashboardTitle)
                    .font(.title2.bold())

                dashboardCard(
                    title: groupStreakTitle,
                    value: "\(group.currentStreak)",
                    subtitle: daysLabel
                )

                dashboardCard(
                    title: groupMembersTitle,
                    value: "\(memberCount)",
                    subtitle: usersLabel
                )

                dashboardCard(
                    title: successDaysTitle,
                    value: "\(group.successDays ?? 7)",
                    subtitle: journeyGoalSubtitle
                )

                if let latest = dataStore.groupDailyResults.first {
                    dashboardCard(
                        title: averageUsageTitle,
                        value: formatMinutes(
                            latest.averageUsageMinutes ?? 0
                        ),
                        subtitle: lastClosedDaySubtitle
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
        VStack(alignment: .leading, spacing: 6) {
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background {
            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
            .fill(Color.secondary.opacity(0.10))
        }
    }

    // MARK: - Members

    private func membersView(
        group: SupabaseDataStore.TimeUpRemoteGroup
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(membersSectionTitle)
                    .font(.title2.bold())

                ForEach(dataStore.groupMembers) { member in
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
        member: SupabaseDataStore.TimeUpRemoteUser,
        group: SupabaseDataStore.TimeUpRemoteGroup
    ) -> some View {
        let result = todayResult(
            for: member.id,
            group: group
        )

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        Text(member.displayName ?? genericUserText)
                            .fontWeight(.semibold)

                        if member.id == currentUser?.id {
                            Text("• \(youText)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let result {
                        if result.isLearningDay {
                            Text(
                                "\(formatMinutes(result.usageMinutes)) • \(learningDayText)"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        } else {
                            Text(
                                result.targetMinutes.map {
                                    "\(formatMinutes(result.usageMinutes)) / \(formatMinutes($0))"
                                } ?? formatMinutes(result.usageMinutes)
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    } else {
                        Text(waitingForTodayDataText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let result {
                    if result.isLearningDay {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(.secondary)
                    } else if result.achieved == true {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else if result.achieved == false {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }

            if let currentUser, member.id != currentUser.id {
                HStack {
                    Spacer()
                    encourageMemberButton(member)
                }

                Text(
                    localized(
                        "העידוד נשלח בצ׳אט הקבוצתי.",
                        "Encouragement is shared in the group chat.",
                        "يُشارك التشجيع في دردشة المجموعة."
                    )
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .fill(Color.secondary.opacity(0.10))
        }
    }

    // MARK: - Data Helpers

    private var memberCount: Int {
        dataStore.groupMembers.count
    }

    private func todayResult(
        for userID: UUID,
        group: SupabaseDataStore.TimeUpRemoteGroup
    ) -> SupabaseDataStore.TimeUpRemoteDailyResult? {
        dataStore.dailyResults.first {
            $0.groupID == group.id &&
            $0.userID == userID &&
            $0.resultDate == todayDateKey(group: group)
        }
    }

    private func todayGroupResult(
        group: SupabaseDataStore.TimeUpRemoteGroup
    ) -> SupabaseDataStore.TimeUpRemoteGroupDailyResult? {
        dataStore.groupDailyResults.first {
            $0.groupID == group.id &&
            $0.resultDate == todayDateKey(group: group)
        }
    }

    // MARK: - Load

    @MainActor
    private func loadGroup(
        group: SupabaseDataStore.TimeUpRemoteGroup
    ) async {
        await dataStore.loadGroupMembers(groupID: group.id)
        await dataStore.loadDailyProgress(groupID: group.id)

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
        group: SupabaseDataStore.TimeUpRemoteGroup
    ) -> String {
        let formatter = DateFormatter()

        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone =
            TimeZone(identifier: group.timezone) ??
            TimeZone(identifier: "Asia/Jerusalem") ??
            .current

        formatter.dateFormat = "yyyy-MM-dd"

        return formatter.string(from: Date())
    }

    // MARK: - Formatting

    private func formatMinutes(
        _ minutes: Int
    ) -> String {
        let hours = minutes / 60
        let remaining = minutes % 60

        switch localization.language {
        case .hebrew:
            if hours == 0 {
                return "\(remaining) דק׳"
            }
            if remaining == 0 {
                return "\(hours) שע׳"
            }
            return "\(hours) שע׳ \(remaining) דק׳"

        case .english:
            if hours == 0 {
                return "\(remaining) min"
            }
            if remaining == 0 {
                return "\(hours) hr"
            }
            return "\(hours) hr \(remaining) min"

        case .arabic:
            if hours == 0 {
                return "\(remaining) د"
            }
            if remaining == 0 {
                return "\(hours) س"
            }
            return "\(hours) س \(remaining) د"
        }
    }

    // MARK: - Error

    private func errorCard(
        _ error: String
    ) -> some View {
        Label(
            error,
            systemImage: "exclamationmark.triangle.fill"
        )
        .font(.footnote)
        .foregroundStyle(.red)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.red.opacity(0.08))
        }
    }

    // MARK: - Localization

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

    private func sectionTitle(
        _ section: GroupSection
    ) -> String {
        switch section {
        case .overview:
            return localized("סקירה", "Overview", "نظرة عامة")
        case .detail:
            return localized("פירוט", "Details", "التفاصيل")
        case .dashboard:
            return localized("לוח בקרה", "Dashboard", "لوحة التحكم")
        case .members:
            return localized("חברים", "Members", "الأعضاء")
        case .chat:
            return localized("צ׳אט", "Chat", "الدردشة")
        }
    }

    private func membersCountText(
        _ count: Int
    ) -> String {
        localized(
            "\(count) חברים",
            count == 1 ? "1 member" : "\(count) members",
            "\(count) أعضاء"
        )
    }

    private func daysText(
        _ count: Int
    ) -> String {
        localized(
            "\(count) ימים",
            count == 1 ? "1 day" : "\(count) days",
            "\(count) أيام"
        )
    }

    private var noGroupTitle: String {
        localized(
            "לא נמצאה קבוצה",
            "Group Not Found",
            "لم يتم العثور على مجموعة"
        )
    }

    private var noGroupDescription: String {
        localized(
            "לא נמצאה חברות פעילה בקבוצה.",
            "No active group membership was found.",
            "لم يتم العثور على عضوية نشطة في المجموعة."
        )
    }

    private var groupStreakTitle: String {
        localized(
            "רצף קבוצתי",
            "Group Streak",
            "سلسلة المجموعة"
        )
    }

    private var streakStartDescription: String {
        localized(
            "הרצף מתחיל כאשר כל חברי הקבוצה עומדים ביעד.",
            "The streak starts when every group member reaches their goal.",
            "تبدأ السلسلة عندما يحقق جميع أعضاء المجموعة هدفهم."
        )
    }

    private var streakContinueDescription: String {
        localized(
            "כל חברי הקבוצה צריכים לעמוד ביעד כדי להמשיך את הרצף.",
            "Every group member must reach their goal to keep the streak going.",
            "يجب على جميع أعضاء المجموعة تحقيق هدفهم لمواصلة السلسلة."
        )
    }

    private var groupJourneyTitle: String {
        localized(
            "המסע הקבוצתי",
            "Group Journey",
            "رحلة المجموعة"
        )
    }

    private var todayInGroupTitle: String {
        localized(
            "היום בקבוצה",
            "Today in the Group",
            "اليوم في المجموعة"
        )
    }

    private var groupMembersTitle: String {
        localized(
            "חברי הקבוצה",
            "Group Members",
            "أعضاء المجموعة"
        )
    }

    private var currentStreakTitle: String {
        localized(
            "רצף נוכחי",
            "Current Streak",
            "السلسلة الحالية"
        )
    }

    private var groupSucceededTodayText: String {
        localized(
            "כל חברי הקבוצה עמדו ביעד.",
            "Every group member reached their goal.",
            "حقق جميع أعضاء المجموعة هدفهم."
        )
    }

    private var groupFailedTodayText: String {
        localized(
            "הקבוצה לא עמדה היום ביעד.",
            "The group did not reach today's goal.",
            "لم تحقق المجموعة هدف اليوم."
        )
    }

    private var pendingResultText: String {
        localized(
            "תוצאת היום תיסגר אוטומטית לאחר שכל נתוני השימוש יתקבלו.",
            "Today's result will close automatically after all usage data is received.",
            "سيتم إغلاق نتيجة اليوم تلقائيًا بعد استلام جميع بيانات الاستخدام."
        )
    }

    private var showAllText: String {
        localized("הצג הכל", "Show All", "عرض الكل")
    }

    private var noMembersTitle: String {
        localized(
            "אין חברים בקבוצה",
            "No Group Members",
            "لا يوجد أعضاء في المجموعة"
        )
    }

    private var genericUserText: String {
        localized("משתמש", "User", "مستخدم")
    }

    private var youText: String {
        localized("אתה", "You", "أنت")
    }

    private var groupDetailTitle: String {
        localized(
            "פירוט קבוצתי",
            "Group Details",
            "تفاصيل المجموعة"
        )
    }

    private var noDataTitle: String {
        localized(
            "אין עדיין נתונים",
            "No Data Yet",
            "لا توجد بيانات بعد"
        )
    }

    private var noDataDescription: String {
        localized(
            "נתוני השימוש של חברי הקבוצה יופיעו כאן.",
            "Group members' usage data will appear here.",
            "ستظهر بيانات استخدام أعضاء المجموعة هنا."
        )
    }

    private var dashboardTitle: String {
        localized("לוח בקרה", "Dashboard", "لوحة التحكم")
    }

    private var daysLabel: String {
        localized("ימים", "days", "أيام")
    }

    private var usersLabel: String {
        localized("משתמשים", "users", "مستخدمون")
    }

    private var successDaysTitle: String {
        localized(
            "ימי הצלחה",
            "Success Days",
            "أيام النجاح"
        )
    }

    private var journeyGoalSubtitle: String {
        localized("יעד המסע", "journey goal", "هدف الرحلة")
    }

    private var averageUsageTitle: String {
        localized(
            "ממוצע שימוש",
            "Average Usage",
            "متوسط الاستخدام"
        )
    }

    private var lastClosedDaySubtitle: String {
        localized(
            "ביום האחרון שנסגר",
            "on the last completed day",
            "في آخر يوم مكتمل"
        )
    }

    private var membersSectionTitle: String {
        localized("חברים", "Members", "الأعضاء")
    }

    private var learningDayText: String {
        localized(
            "יום למידה",
            "Learning Day",
            "يوم التعلّم"
        )
    }

    private var waitingForTodayDataText: String {
        localized(
            "ממתין לנתוני היום",
            "Waiting for today's data",
            "بانتظار بيانات اليوم"
        )
    }
}