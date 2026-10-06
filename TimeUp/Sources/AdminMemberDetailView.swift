import SwiftUI

struct AdminMemberDetailView: View {

    let group: SupabaseDataStore.TimeUpRemoteGroup
    let member: SupabaseDataStore.TimeUpRemoteUser

    @Environment(\.dismiss) private var dismiss

    @StateObject private var dataStore =
        SupabaseDataStore.shared

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    @State private var isLoading = false
    @State private var manualHours = 0
    @State private var manualMinutes = 0
    @State private var didLoadManualTarget = false
    @State private var saveMessage: String?

    @State private var showRemoveConfirmation = false
    @State private var isRemovingMember = false
    @State private var removeError: String?

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 20
            ) {

                // MARK: - Member Header

                VStack(spacing: 12) {

                    Image(
                        systemName:
                            "person.crop.circle.fill"
                    )
                    .font(
                        .system(size: 72)
                    )
                    .foregroundStyle(
                        .secondary
                    )

                    Text(
                        member.displayName ??
                        genericUserText
                    )
                    .font(.title2.bold())

                    Text(
                        member.role == "admin"
                        ? adminText
                        : groupMemberText
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
                .frame(
                    maxWidth: .infinity
                )
                .padding(.vertical)

                // MARK: - Today's Status

                VStack(
                    alignment: .leading,
                    spacing: 16
                ) {

                    HStack {

                        Text(todayText)
                            .font(.headline)

                        Spacer()

                        if isLoading {
                            ProgressView()
                        }
                    }

                    if let result = todayResult {

                        HStack(spacing: 12) {

                            statusCard(
                                title:
                                    screenTimeText,
                                value:
                                    formatMinutes(
                                        result.usageMinutes
                                    ),
                                icon:
                                    "iphone"
                            )

                            statusCard(
                                title:
                                    targetLabelText,
                                value:
                                    targetText(result),
                                icon:
                                    "target"
                            )
                        }

                        Divider()

                        if result.isLearningDay {

                            Label(
                                learningDayText,
                                systemImage:
                                    "brain.head.profile"
                            )
                            .font(.headline)

                            Text(
                                learningDayDescription
                            )
                            .font(.callout)
                            .foregroundStyle(
                                .secondary
                            )

                        } else {

                            HStack {

                                Image(
                                    systemName:
                                        result.achieved == true
                                        ? "checkmark.circle.fill"
                                        : "xmark.circle.fill"
                                )
                                .font(.title2)

                                VStack(
                                    alignment: .leading,
                                    spacing: 2
                                ) {

                                    Text(
                                        result.achieved == true
                                        ? targetAchievedText
                                        : targetNotAchievedText
                                    )
                                    .fontWeight(
                                        .semibold
                                    )

                                    if let target =
                                        result.targetMinutes {

                                        Text(
                                            statusDescription(
                                                usage:
                                                    result.usageMinutes,
                                                target:
                                                    target
                                            )
                                        )
                                        .font(.caption)
                                        .foregroundStyle(
                                            .secondary
                                        )
                                    }
                                }

                                Spacer()
                            }
                        }

                    } else if let target =
                        todayTarget {

                        HStack(spacing: 12) {

                            statusCard(
                                title:
                                    screenTimeText,
                                value:
                                    notReceivedYetText,
                                icon:
                                    "iphone"
                            )

                            statusCard(
                                title:
                                    targetLabelText,
                                value:
                                    formatMinutes(
                                        target.targetMinutes
                                    ),
                                icon:
                                    "target"
                            )
                        }

                        Divider()

                        Label(
                            waitingForScreenTimeText,
                            systemImage:
                                "clock.arrow.circlepath"
                        )
                        .font(.callout)
                        .foregroundStyle(
                            .secondary
                        )

                    } else {

                        ContentUnavailableView(
                            noDataTodayTitle,
                            systemImage:
                                "iphone.slash",
                            description:
                                Text(
                                    noDataTodayDescription
                                )
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

                // MARK: - Manual Target Editor

                if group.goalMethod ==
                    "manual" {

                    VStack(
                        alignment: .leading,
                        spacing: 16
                    ) {

                        Label(
                            personalTargetText,
                            systemImage:
                                "person.crop.circle.badge.checkmark"
                        )
                        .font(.headline)

                        if let currentTargetMinutes {

                            Text(
                                currentTargetText(
                                    currentTargetMinutes
                                )
                            )
                            .font(.subheadline)
                            .foregroundStyle(
                                .secondary
                            )

                        } else {

                            Text(
                                noTargetDefinedText
                            )
                            .font(.subheadline)
                            .foregroundStyle(
                                .secondary
                            )
                        }

                        Divider()

                        Text(setTargetText)
                            .fontWeight(
                                .semibold
                            )

                        HStack(spacing: 16) {

                            VStack(spacing: 6) {

                                Text(hoursText)
                                    .font(.caption)
                                    .foregroundStyle(
                                        .secondary
                                    )

                                Stepper(
                                    value:
                                        $manualHours,
                                    in: 0...23
                                ) {

                                    Text(
                                        "\(manualHours)"
                                    )
                                    .font(
                                        .title3.bold()
                                    )
                                    .monospacedDigit()
                                }
                            }

                            Divider()
                                .frame(
                                    height: 45
                                )

                            VStack(spacing: 6) {

                                Text(minutesText)
                                    .font(.caption)
                                    .foregroundStyle(
                                        .secondary
                                    )

                                Stepper(
                                    value:
                                        $manualMinutes,
                                    in: 0...59
                                ) {

                                    Text(
                                        "\(manualMinutes)"
                                    )
                                    .font(
                                        .title3.bold()
                                    )
                                    .monospacedDigit()
                                }
                            }
                        }

                        Text(
                            newTargetText(
                                manualTargetTotalMinutes
                            )
                        )
                        .font(.callout)
                        .foregroundStyle(
                            .secondary
                        )

                        Button {

                            Task {
                                await saveManualTarget()
                            }

                        } label: {

                            HStack {

                                Spacer()

                                if dataStore
                                    .isSavingManualTarget {

                                    ProgressView()
                                        .padding(
                                            .trailing,
                                            4
                                        )

                                    Text(savingText)

                                } else {

                                    Image(
                                        systemName:
                                            "checkmark.circle.fill"
                                    )

                                    Text(saveTargetText)
                                        .fontWeight(
                                            .semibold
                                        )
                                }

                                Spacer()
                            }
                            .padding(
                                .vertical,
                                12
                            )
                        }
                        .buttonStyle(
                            .borderedProminent
                        )
                        .disabled(
                            manualTargetTotalMinutes <= 0 ||
                            dataStore.isSavingManualTarget
                        )

                        if let saveMessage {

                            Text(saveMessage)
                                .font(.caption)
                                .foregroundStyle(
                                    .secondary
                                )
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .center
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

                // MARK: - History

                VStack(
                    alignment: .leading,
                    spacing: 14
                ) {

                    HStack {

                        Text(historyText)
                            .font(
                                .title3.bold()
                            )

                        Spacer()

                        Text(
                            daysCountText(
                                memberResults.count
                            )
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )
                    }

                    if memberResults.isEmpty {

                        ContentUnavailableView(
                            noHistoryTitle,
                            systemImage:
                                "calendar",
                            description:
                                Text(
                                    noHistoryDescription
                                )
                        )
                        .frame(
                            maxWidth: .infinity
                        )

                    } else {

                        ForEach(
                            memberResults
                        ) { result in

                            historyRow(result)

                            if result.id !=
                                memberResults.last?.id {

                                Divider()
                            }
                        }
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

                // MARK: - Group

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    Text(groupText)
                        .font(.headline)

                    HStack {

                        Text(group.name)

                        Spacer()

                        Text(group.code)
                            .font(
                                .system(
                                    .body,
                                    design:
                                        .monospaced
                                )
                            )
                            .foregroundStyle(
                                .secondary
                            )
                    }

                    Divider()

                    HStack {

                        Label(
                            goalDescription,
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

                // MARK: - Remove Member

                if canRemoveMember {

                    VStack(
                        alignment: .leading,
                        spacing: 12
                    ) {

                        Text(userManagementText)
                            .font(.headline)

                        Text(
                            removeMemberDescription
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )

                        Button(
                            role: .destructive
                        ) {

                            showRemoveConfirmation =
                                true

                        } label: {

                            HStack {

                                Spacer()

                                if isRemovingMember {

                                    ProgressView()
                                        .padding(
                                            .trailing,
                                            4
                                        )

                                    Text(removingText)

                                } else {

                                    Image(
                                        systemName:
                                            "person.crop.circle.badge.minus"
                                    )

                                    Text(
                                        removeFromGroupText
                                    )
                                    .fontWeight(
                                        .semibold
                                    )
                                }

                                Spacer()
                            }
                            .padding(
                                .vertical,
                                12
                            )
                        }
                        .buttonStyle(
                            .bordered
                        )
                        .disabled(
                            isRemovingMember
                        )

                        if let removeError {

                            Text(removeError)
                                .font(.caption)
                                .foregroundStyle(
                                    .red
                                )
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .leading
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

                // MARK: - Error

                if let error =
                    dataStore.lastError {

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        Label(
                            unableToCompleteText,
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

                        Button(retryText) {

                            Task {
                                await loadData()
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
        .navigationTitle(
            member.displayName ??
            genericUserText
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
        .refreshable {
            await loadData()
        }
        .task {
            await loadData()
        }
        .alert(
            removeConfirmationTitle,
            isPresented:
                $showRemoveConfirmation
        ) {

            Button(
                cancelText,
                role: .cancel
            ) {}

            Button(
                removeText,
                role: .destructive
            ) {

                Task {
                    await removeMember()
                }
            }

        } message: {

            Text(
                removeConfirmationMessage
            )
        }
    }

    // MARK: - Data

    private var memberResults:
        [SupabaseDataStore.TimeUpRemoteDailyResult] {

        dataStore.dailyResults
            .filter {
                $0.groupID == group.id &&
                $0.userID == member.id
            }
            .sorted {
                $0.resultDate >
                $1.resultDate
            }
    }

    private var todayResult:
        SupabaseDataStore.TimeUpRemoteDailyResult? {

        memberResults.first {
            $0.resultDate ==
            todayDateKey
        }
    }

    private var todayTarget:
        SupabaseDataStore.TimeUpRemoteDailyTarget? {

        dataStore.dailyTargets.first {
            $0.groupID == group.id &&
            $0.userID == member.id &&
            $0.targetDate == todayDateKey
        }
    }

    private var currentTargetMinutes:
        Int? {

        if let target = todayTarget {
            return target.targetMinutes
        }

        return todayResult?
            .targetMinutes
    }

    private var manualTargetTotalMinutes:
        Int {

        (manualHours * 60) +
        manualMinutes
    }

    private var canRemoveMember:
        Bool {

        guard let currentUser =
            dataStore.currentUser
        else {
            return false
        }

        return
            currentUser.role == "admin" &&
            currentUser.id != member.id
    }

    // MARK: - History Row

    private func historyRow(
        _ result:
            SupabaseDataStore.TimeUpRemoteDailyResult
    ) -> some View {

        HStack(spacing: 14) {

            ZStack {

                Circle()
                    .fill(
                        .ultraThinMaterial
                    )
                    .frame(
                        width: 44,
                        height: 44
                    )

                Image(
                    systemName:
                        result.isLearningDay
                        ? "brain.head.profile"
                        : result.achieved == true
                            ? "checkmark"
                            : result.achieved == false
                                ? "xmark"
                                : "clock"
                )
                .fontWeight(
                    .semibold
                )
            }

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                HStack {

                    Text(
                        displayDate(
                            result.resultDate
                        )
                    )
                    .fontWeight(
                        .semibold
                    )

                    if result.isLearningDay {

                        Text(
                            learningDayText
                        )
                        .font(.caption2)
                        .padding(
                            .horizontal,
                            7
                        )
                        .padding(
                            .vertical,
                            3
                        )
                        .background(
                            .thinMaterial
                        )
                        .clipShape(
                            Capsule()
                        )
                    }
                }

                HStack(spacing: 12) {

                    Label(
                        formatMinutes(
                            result.usageMinutes
                        ),
                        systemImage:
                            "iphone"
                    )

                    if let target =
                        result.targetMinutes {

                        Label(
                            formatMinutes(
                                target
                            ),
                            systemImage:
                                "target"
                        )
                    }
                }
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }

            Spacer()

            if !result.isLearningDay {

                Text(
                    historyStatusText(
                        result.achieved
                    )
                )
                .font(
                    .caption.bold()
                )
            }
        }
        .padding(
            .vertical,
            5
        )
    }

    // MARK: - Manual Target

    @MainActor
    private func saveManualTarget() async {

        guard
            manualTargetTotalMinutes > 0
        else {
            return
        }

        saveMessage = nil

        do {

            try await dataStore
                .setManualTarget(
                    group: group,
                    userID: member.id,
                    targetMinutes:
                        manualTargetTotalMinutes
                )

            saveMessage =
                targetSavedText

            loadManualTargetIntoEditor(
                force: true
            )

        } catch {

            saveMessage =
                targetSaveFailedText(
                    error.localizedDescription
                )
        }
    }

    private func loadManualTargetIntoEditor(
        force: Bool = false
    ) {

        guard
            force ||
            !didLoadManualTarget
        else {
            return
        }

        guard
            let targetMinutes =
                currentTargetMinutes
        else {

            didLoadManualTarget =
                true

            return
        }

        manualHours =
            targetMinutes / 60

        manualMinutes =
            targetMinutes % 60

        didLoadManualTarget =
            true
    }

    // MARK: - Remove Member

    @MainActor
    private func removeMember() async {

        guard !isRemovingMember
        else {
            return
        }

        isRemovingMember = true
        removeError = nil

        defer {
            isRemovingMember = false
        }

        do {

            try await dataStore
                .removeMemberFromGroup(
                    groupID: group.id,
                    userID: member.id
                )

            dismiss()

        } catch {

            removeError =
                removeFailedText(
                    error.localizedDescription
                )
        }
    }

    // MARK: - Status Card

    private func statusCard(
        title: String,
        value: String,
        icon: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Label(
                title,
                systemImage: icon
            )
            .font(.caption)
            .foregroundStyle(
                .secondary
            )

            Text(value)
                .font(
                    .title3.bold()
                )
        }
        .padding()
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            .ultraThinMaterial
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 14
            )
        )
    }

    // MARK: - Load

    @MainActor
    private func loadData() async {

        isLoading = true

        await dataStore
            .loadDailyProgress(
                groupID: group.id
            )

        loadManualTargetIntoEditor()

        isLoading = false
    }

    // MARK: - Date

    private var todayDateKey:
        String {

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

    private func displayDate(
        _ dateString: String
    ) -> String {

        let input =
            DateFormatter()

        input.calendar =
            Calendar(
                identifier: .gregorian
            )

        input.locale =
            Locale(
                identifier:
                    "en_US_POSIX"
            )

        input.timeZone =
            TimeZone(
                identifier:
                    group.timezone
            ) ??
            .current

        input.dateFormat =
            "yyyy-MM-dd"

        guard
            let date =
                input.date(
                    from: dateString
                )
        else {
            return dateString
        }

        let output =
            DateFormatter()

        output.locale =
            localization
                .language
                .locale

        output.timeZone =
            TimeZone(
                identifier:
                    group.timezone
            ) ??
            .current

        output.setLocalizedDateFormatFromTemplate(
            "dMMMyyyy"
        )

        return output.string(
            from: date
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

    private func targetText(
        _ result:
            SupabaseDataStore.TimeUpRemoteDailyResult
    ) -> String {

        guard let target =
            result.targetMinutes
        else {
            return noTargetText
        }

        return formatMinutes(
            target
        )
    }

    private func statusDescription(
        usage: Int,
        target: Int
    ) -> String {

        let difference =
            abs(target - usage)

        if usage <= target {

            switch localization.language {

            case .hebrew:
                return "נותרו \(formatMinutes(difference)) עד היעד"

            case .english:
                return "\(formatMinutes(difference)) remaining until the target"

            case .arabic:
                return "متبقي \(formatMinutes(difference)) حتى الهدف"
            }
        }

        switch localization.language {

        case .hebrew:
            return "חריגה של \(formatMinutes(difference))"

        case .english:
            return "Exceeded by \(formatMinutes(difference))"

        case .arabic:
            return "تجاوز بمقدار \(formatMinutes(difference))"
        }
    }

    // MARK: - Goal

    private var goalDescription:
        String {

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

            return personalTargetText

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

    private var todayText: String {
        switch localization.language {
        case .hebrew: return "היום"
        case .english: return "Today"
        case .arabic: return "اليوم"
        }
    }

    private var screenTimeText: String {
        switch localization.language {
        case .hebrew: return "זמן מסך"
        case .english: return "Screen time"
        case .arabic: return "وقت الشاشة"
        }
    }

    private var targetLabelText: String {
        switch localization.language {
        case .hebrew: return "יעד"
        case .english: return "Target"
        case .arabic: return "الهدف"
        }
    }

    private var learningDayText: String {
        switch localization.language {
        case .hebrew: return "יום למידה"
        case .english: return "Learning day"
        case .arabic: return "يوم تعلّم"
        }
    }

    private var learningDayDescription: String {
        switch localization.language {
        case .hebrew:
            return "היום משמש למדידת זמן המסך לצורך קביעת היעד הראשון. יום זה אינו נספר ברצף."
        case .english:
            return "Today measures screen time to establish the first target. This day does not count toward the streak."
        case .arabic:
            return "يُستخدم اليوم لقياس وقت الشاشة من أجل تحديد الهدف الأول. هذا اليوم لا يُحتسب ضمن السلسلة."
        }
    }

    private var targetAchievedText: String {
        switch localization.language {
        case .hebrew: return "עמד ביעד"
        case .english: return "Target achieved"
        case .arabic: return "حقق الهدف"
        }
    }

    private var targetNotAchievedText: String {
        switch localization.language {
        case .hebrew: return "לא עמד ביעד"
        case .english: return "Target missed"
        case .arabic: return "لم يحقق الهدف"
        }
    }

    private var notReceivedYetText: String {
        switch localization.language {
        case .hebrew: return "טרם התקבל"
        case .english: return "Not received yet"
        case .arabic: return "لم يتم الاستلام بعد"
        }
    }

    private var waitingForScreenTimeText: String {
        switch localization.language {
        case .hebrew: return "ממתין לנתוני זמן מסך"
        case .english: return "Waiting for screen-time data"
        case .arabic: return "في انتظار بيانات وقت الشاشة"
        }
    }

    private var noDataTodayTitle: String {
        switch localization.language {
        case .hebrew: return "אין נתונים להיום"
        case .english: return "No data for today"
        case .arabic: return "لا توجد بيانات لليوم"
        }
    }

    private var noDataTodayDescription: String {
        switch localization.language {
        case .hebrew:
            return "עדיין לא התקבלו נתוני זמן מסך או יעד עבור המשתמש."
        case .english:
            return "No screen-time data or target has been received for this user yet."
        case .arabic:
            return "لم يتم استلام بيانات وقت الشاشة أو الهدف لهذا المستخدم بعد."
        }
    }

    private var personalTargetText: String {
        switch localization.language {
        case .hebrew: return "יעד אישי"
        case .english: return "Individual target"
        case .arabic: return "هدف شخصي"
        }
    }

    private func currentTargetText(
        _ minutes: Int
    ) -> String {
        switch localization.language {
        case .hebrew:
            return "היעד הנוכחי: \(formatMinutes(minutes))"
        case .english:
            return "Current target: \(formatMinutes(minutes))"
        case .arabic:
            return "الهدف الحالي: \(formatMinutes(minutes))"
        }
    }

    private var noTargetDefinedText: String {
        switch localization.language {
        case .hebrew: return "עדיין לא הוגדר יעד למשתמש."
        case .english: return "No target has been set for this user yet."
        case .arabic: return "لم يتم تحديد هدف لهذا المستخدم بعد."
        }
    }

    private var setTargetText: String {
        switch localization.language {
        case .hebrew: return "הגדרת יעד"
        case .english: return "Set target"
        case .arabic: return "تحديد الهدف"
        }
    }

    private var hoursText: String {
        switch localization.language {
        case .hebrew: return "שעות"
        case .english: return "Hours"
        case .arabic: return "ساعات"
        }
    }

    private var minutesText: String {
        switch localization.language {
        case .hebrew: return "דקות"
        case .english: return "Minutes"
        case .arabic: return "دقائق"
        }
    }

    private func newTargetText(
        _ minutes: Int
    ) -> String {
        switch localization.language {
        case .hebrew:
            return "יעד חדש: \(formatMinutes(minutes))"
        case .english:
            return "New target: \(formatMinutes(minutes))"
        case .arabic:
            return "الهدف الجديد: \(formatMinutes(minutes))"
        }
    }

    private var savingText: String {
        switch localization.language {
        case .hebrew: return "שומר..."
        case .english: return "Saving..."
        case .arabic: return "جارٍ الحفظ..."
        }
    }

    private var saveTargetText: String {
        switch localization.language {
        case .hebrew: return "שמירת יעד"
        case .english: return "Save target"
        case .arabic: return "حفظ الهدف"
        }
    }

    private var historyText: String {
        switch localization.language {
        case .hebrew: return "היסטוריה"
        case .english: return "History"
        case .arabic: return "السجل"
        }
    }

    private func daysCountText(
        _ count: Int
    ) -> String {
        switch localization.language {
        case .hebrew:
            return "\(count) ימים"
        case .english:
            return count == 1 ? "1 day" : "\(count) days"
        case .arabic:
            return "\(count) أيام"
        }
    }

    private var noHistoryTitle: String {
        switch localization.language {
        case .hebrew: return "אין היסטוריה עדיין"
        case .english: return "No history yet"
        case .arabic: return "لا يوجد سجل بعد"
        }
    }

    private var noHistoryDescription: String {
        switch localization.language {
        case .hebrew:
            return "לאחר שיתקבלו נתוני זמן מסך, הימים יופיעו כאן."
        case .english:
            return "Days will appear here after screen-time data is received."
        case .arabic:
            return "ستظهر الأيام هنا بعد استلام بيانات وقت الشاشة."
        }
    }

    private var groupText: String {
        switch localization.language {
        case .hebrew: return "קבוצה"
        case .english: return "Group"
        case .arabic: return "المجموعة"
        }
    }

    private var userManagementText: String {
        switch localization.language {
        case .hebrew: return "ניהול משתמש"
        case .english: return "User management"
        case .arabic: return "إدارة المستخدم"
        }
    }

    private var removeMemberDescription: String {
        switch localization.language {
        case .hebrew:
            return "הסרת המשתמש תוציא אותו מהקבוצה. חשבון המשתמש עצמו לא יימחק."
        case .english:
            return "Removing the user will remove them from the group. Their account will not be deleted."
        case .arabic:
            return "ستؤدي إزالة المستخدم إلى إخراجه من المجموعة. لن يتم حذف حسابه."
        }
    }

    private var removingText: String {
        switch localization.language {
        case .hebrew: return "מסיר..."
        case .english: return "Removing..."
        case .arabic: return "جارٍ الإزالة..."
        }
    }

    private var removeFromGroupText: String {
        switch localization.language {
        case .hebrew: return "הסר מהקבוצה"
        case .english: return "Remove from group"
        case .arabic: return "إزالة من المجموعة"
        }
    }

    private var unableToCompleteText: String {
        switch localization.language {
        case .hebrew: return "לא ניתן להשלים את הפעולה"
        case .english: return "Unable to complete the action"
        case .arabic: return "تعذر إكمال العملية"
        }
    }

    private var retryText: String {
        switch localization.language {
        case .hebrew: return "נסה שוב"
        case .english: return "Try again"
        case .arabic: return "حاول مرة أخرى"
        }
    }

    private var removeConfirmationTitle: String {
        switch localization.language {
        case .hebrew: return "להסיר מהקבוצה?"
        case .english: return "Remove from group?"
        case .arabic: return "إزالة من المجموعة؟"
        }
    }

    private var cancelText: String {
        switch localization.language {
        case .hebrew: return "ביטול"
        case .english: return "Cancel"
        case .arabic: return "إلغاء"
        }
    }

    private var removeText: String {
        switch localization.language {
        case .hebrew: return "הסר"
        case .english: return "Remove"
        case .arabic: return "إزالة"
        }
    }

    private var removeConfirmationMessage: String {

        let name =
            member.displayName ??
            genericUserText

        switch localization.language {
        case .hebrew:
            return "\(name) יוסר מהקבוצה \(group.name). חשבון המשתמש לא יימחק."
        case .english:
            return "\(name) will be removed from \(group.name). The user's account will not be deleted."
        case .arabic:
            return "سيتم إزالة \(name) من مجموعة \(group.name). لن يتم حذف حساب المستخدم."
        }
    }

    private func historyStatusText(
        _ achieved: Bool?
    ) -> String {

        switch achieved {

        case true:
            switch localization.language {
            case .hebrew: return "הצלחה"
            case .english: return "Success"
            case .arabic: return "نجاح"
            }

        case false:
            switch localization.language {
            case .hebrew: return "חריגה"
            case .english: return "Exceeded"
            case .arabic: return "تجاوز"
            }

        case nil:
            switch localization.language {
            case .hebrew: return "ממתין"
            case .english: return "Pending"
            case .arabic: return "قيد الانتظار"
            }
        }
    }

    private var targetSavedText: String {
        switch localization.language {
        case .hebrew: return "היעד נשמר בהצלחה"
        case .english: return "Target saved successfully"
        case .arabic: return "تم حفظ الهدف بنجاح"
        }
    }

    private func targetSaveFailedText(
        _ error: String
    ) -> String {
        switch localization.language {
        case .hebrew:
            return "שמירת היעד נכשלה: \(error)"
        case .english:
            return "Failed to save target: \(error)"
        case .arabic:
            return "فشل حفظ الهدف: \(error)"
        }
    }

    private func removeFailedText(
        _ error: String
    ) -> String {
        switch localization.language {
        case .hebrew:
            return "לא ניתן להסיר את המשתמש: \(error)"
        case .english:
            return "Unable to remove the user: \(error)"
        case .arabic:
            return "تعذر إزالة المستخدم: \(error)"
        }
    }

    private var noTargetText: String {
        switch localization.language {
        case .hebrew: return "ללא יעד"
        case .english: return "No target"
        case .arabic: return "بدون هدف"
        }
    }
}