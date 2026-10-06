import SwiftUI

struct MemberGroupDetailView: View {

    let member: TimeUpMember

    @ObservedObject private var store =
        TimeUpStore.shared

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    @State private var selectedDate =
        Calendar.current.startOfDay(for: Date())

    private let calendar =
        Calendar.current

    var body: some View {

        ScrollView {

            VStack(spacing: 18) {

                dateSelector

                groupAverageCard

                membersCard
            }
            .padding(16)
        }
        .navigationTitle(groupDetailsTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Current Member

    private var currentMember: TimeUpMember {

        store.member(
            id: member.id
        ) ?? member
    }

    // MARK: - Group

    private var group: TimeUpGroup? {

        store.groups.first {
            $0.id == currentMember.groupID
        }
    }

    // MARK: - Members

    private var groupMembers: [TimeUpMember] {

        guard let group else {
            return []
        }

        return store.members
            .filter {
                $0.groupID == group.id &&
                $0.role == .member
            }
            .sorted {
                $0.displayName
                    .localizedCompare(
                        $1.displayName
                    ) == .orderedAscending
            }
    }

    // MARK: - Date Selector

    private var dateSelector: some View {

        HStack(spacing: 12) {

            Button {

                moveDate(by: -1)

            } label: {

                Image(
                    systemName:
                        previousChevronName
                )
                .frame(
                    width: 40,
                    height: 40
                )
            }
            .buttonStyle(.bordered)

            Spacer()

            VStack(spacing: 4) {

                Text(dateText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(
                    formattedSelectedDate
                )
                .font(.headline)
            }

            Spacer()

            Button {

                moveDate(by: 1)

            } label: {

                Image(
                    systemName:
                        nextChevronName
                )
                .frame(
                    width: 40,
                    height: 40
                )
            }
            .buttonStyle(.bordered)
            .disabled(isToday)
        }
        .padding(14)
        .background {

            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .fill(
                Color.secondary
                    .opacity(0.10)
            )
        }
    }

    // MARK: - Group Average

    private var groupAverageCard: some View {

        VStack(spacing: 10) {

            HStack {

                Image(
                    systemName:
                        "person.3.fill"
                )
                .foregroundStyle(
                    .secondary
                )

                Text(groupAverageTitle)
                    .font(.headline)

                Spacer()
            }

            if let average =
                groupAverageMinutes
            {

                Text(
                    formattedMinutes(
                        average
                    )
                )
                .font(
                    .system(
                        size: 36,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )

                Text(
                    groupAverageDescription
                )
                .font(.footnote)
                .foregroundStyle(
                    .secondary
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )

            } else {

                ContentUnavailableView(
                    noDataText,
                    systemImage:
                        "chart.bar.xaxis",
                    description:
                        Text(
                            noGroupDataDescription
                        )
                )
                .frame(
                    minHeight: 140
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

    // MARK: - Members

    private var membersCard: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            HStack {

                Text(groupMembersTitle)
                    .font(.headline)

                Spacer()

                Text(
                    "\(groupMembers.count)"
                )
                .font(.subheadline)
                .foregroundStyle(
                    .secondary
                )
            }
            .padding(.bottom, 14)

            if groupMembers.isEmpty {

                ContentUnavailableView(
                    noMembersText,
                    systemImage: "person.3"
                )
                .frame(
                    minHeight: 180
                )

            } else {

                ForEach(
                    Array(
                        groupMembers.enumerated()
                    ),
                    id: \.element.id
                ) { index, groupMember in

                    memberRow(
                        groupMember
                    )

                    if index <
                        groupMembers.count - 1
                    {

                        Divider()
                            .padding(
                                .leading,
                                46
                            )
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

    // MARK: - Member Row

    @ViewBuilder
    private func memberRow(
        _ groupMember: TimeUpMember
    ) -> some View {

        let progress =
            progress(
                for: groupMember
            )

        HStack(spacing: 12) {

            Image(
                systemName:
                    "person.crop.circle.fill"
            )
            .font(
                .system(size: 34)
            )
            .foregroundStyle(
                statusColor(
                    for: progress
                )
            )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                HStack(spacing: 6) {

                    Text(
                        groupMember.displayName
                    )
                    .fontWeight(.semibold)

                    if groupMember.id ==
                        currentMember.id
                    {

                        Text(youText)
                            .font(.caption2)
                            .foregroundStyle(
                                .secondary
                            )
                    }
                }

                if let progress {

                    if let target =
                        progress.targetMinutes
                    {

                        Text(
                            targetText(
                                target
                            )
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )

                    } else {

                        Text(noTargetForDayText)
                            .font(.caption)
                            .foregroundStyle(
                                .secondary
                            )
                    }

                } else if let target =
                            groupMember
                                .dailyTargetMinutes
                {

                    Text(
                        currentTargetText(
                            target
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )

                } else {

                    Text(noTargetText)
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )
                }
            }

            Spacer()

            if let progress {

                VStack(
                    alignment: .trailing,
                    spacing: 4
                ) {

                    Text(
                        formattedMinutes(
                            progress.usageMinutes
                        )
                    )
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(
                        statusColor(
                            for: progress
                        )
                    )

                    statusLabel(
                        for: progress
                    )
                }

            } else {

                Text(noDataText)
                    .font(.subheadline)
                    .foregroundStyle(
                        .secondary
                    )
            }
        }
        .padding(
            .vertical,
            12
        )
    }

    // MARK: - Progress

    private func progress(
        for groupMember: TimeUpMember
    ) -> TimeUpDailyProgress? {

        store.progress(
            for: groupMember.id,
            on: selectedDate
        )
    }

    // MARK: - Status

    private func statusColor(
        for progress:
            TimeUpDailyProgress?
    ) -> Color {

        guard let progress else {
            return .secondary
        }

        if progress.isLearningDay {
            return .secondary
        }

        guard let target =
            progress.targetMinutes
        else {
            return .secondary
        }

        return progress.usageMinutes <= target
            ? .green
            : .red
    }

    @ViewBuilder
    private func statusLabel(
        for progress:
            TimeUpDailyProgress
    ) -> some View {

        if progress.isLearningDay {

            Text(learningDayText)
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )

        } else if let target =
                    progress.targetMinutes
        {

            if progress.usageMinutes <= target {

                Label(
                    withinTargetText,
                    systemImage:
                        "checkmark.circle.fill"
                )
                .font(.caption)
                .foregroundStyle(.green)

            } else {

                Label(
                    aboveTargetText,
                    systemImage:
                        "xmark.circle.fill"
                )
                .font(.caption)
                .foregroundStyle(.red)
            }

        } else {

            Text(noTargetText)
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
        }
    }

    // MARK: - Average

    private var progressesForSelectedDate:
        [TimeUpDailyProgress]
    {

        groupMembers.compactMap {
            progress(for: $0)
        }
    }

    private var membersWithDataCount: Int {

        progressesForSelectedDate.count
    }

    private var groupAverageMinutes: Int? {

        let values =
            progressesForSelectedDate.map {
                $0.usageMinutes
            }

        guard !values.isEmpty else {
            return nil
        }

        let total =
            values.reduce(0, +)

        return Int(
            (
                Double(total) /
                Double(values.count)
            )
            .rounded()
        )
    }

    // MARK: - Date Navigation

    private var isToday: Bool {

        calendar.isDateInToday(
            selectedDate
        )
    }

    private func moveDate(
        by days: Int
    ) {

        guard
            let newDate =
                calendar.date(
                    byAdding: .day,
                    value: days,
                    to: selectedDate
                )
        else {
            return
        }

        let normalized =
            calendar.startOfDay(
                for: newDate
            )

        let today =
            calendar.startOfDay(
                for: Date()
            )

        guard normalized <= today else {
            return
        }

        selectedDate = normalized
    }

    // MARK: - Date Formatting

    private var formattedSelectedDate: String {

        let formatter =
            DateFormatter()

        formatter.locale =
            localization.language.locale

        formatter.setLocalizedDateFormatFromTemplate(
            "dMMMyyyy"
        )

        return formatter.string(
            from: selectedDate
        )
    }

    // MARK: - Time Formatting

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

            if hours == 0 {
                return "\(remainingMinutes) דק׳"
            }

            if remainingMinutes == 0 {
                return "\(hours) שע׳"
            }

            return
                "\(hours) שע׳ \(remainingMinutes) דק׳"

        case .english:

            if hours == 0 {
                return "\(remainingMinutes) min"
            }

            if remainingMinutes == 0 {
                return "\(hours) hr"
            }

            return
                "\(hours) hr \(remainingMinutes) min"

        case .arabic:

            if hours == 0 {
                return "\(remainingMinutes) د"
            }

            if remainingMinutes == 0 {
                return "\(hours) س"
            }

            return
                "\(hours) س \(remainingMinutes) د"
        }
    }

    // MARK: - Localization

    private var groupDetailsTitle: String {

        switch localization.language {
        case .hebrew:
            return "פירוט קבוצתי"
        case .english:
            return "Group details"
        case .arabic:
            return "تفاصيل المجموعة"
        }
    }

    private var dateText: String {

        switch localization.language {
        case .hebrew:
            return "תאריך"
        case .english:
            return "Date"
        case .arabic:
            return "التاريخ"
        }
    }

    private var groupAverageTitle: String {

        switch localization.language {
        case .hebrew:
            return "ממוצע קבוצתי"
        case .english:
            return "Group average"
        case .arabic:
            return "متوسط المجموعة"
        }
    }

    private var groupAverageDescription: String {

        switch localization.language {
        case .hebrew:
            return "מבוסס על \(membersWithDataCount) מתוך \(groupMembers.count) חברים עם נתונים ביום זה"

        case .english:
            return "Based on \(membersWithDataCount) of \(groupMembers.count) members with data for this day"

        case .arabic:
            return "استنادًا إلى بيانات \(membersWithDataCount) من أصل \(groupMembers.count) أعضاء في هذا اليوم"
        }
    }

    private var noDataText: String {

        switch localization.language {
        case .hebrew:
            return "אין נתונים"
        case .english:
            return "No data"
        case .arabic:
            return "لا توجد بيانات"
        }
    }

    private var noGroupDataDescription: String {

        switch localization.language {
        case .hebrew:
            return "עדיין אין נתוני זמן מסך לקבוצה בתאריך הזה."
        case .english:
            return "There is no screen-time data for the group on this date yet."
        case .arabic:
            return "لا توجد بيانات وقت شاشة للمجموعة في هذا التاريخ بعد."
        }
    }

    private var groupMembersTitle: String {

        switch localization.language {
        case .hebrew:
            return "חברי הקבוצה"
        case .english:
            return "Group members"
        case .arabic:
            return "أعضاء المجموعة"
        }
    }

    private var noMembersText: String {

        switch localization.language {
        case .hebrew:
            return "אין חברים בקבוצה"
        case .english:
            return "No group members"
        case .arabic:
            return "لا يوجد أعضاء في المجموعة"
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

    private func targetText(
        _ minutes: Int
    ) -> String {

        switch localization.language {
        case .hebrew:
            return "יעד: \(formattedMinutes(minutes))"
        case .english:
            return "Target: \(formattedMinutes(minutes))"
        case .arabic:
            return "الهدف: \(formattedMinutes(minutes))"
        }
    }

    private var noTargetForDayText: String {

        switch localization.language {
        case .hebrew:
            return "אין יעד ליום זה"
        case .english:
            return "No target for this day"
        case .arabic:
            return "لا يوجد هدف لهذا اليوم"
        }
    }

    private func currentTargetText(
        _ minutes: Int
    ) -> String {

        switch localization.language {
        case .hebrew:
            return "יעד נוכחי: \(formattedMinutes(minutes))"
        case .english:
            return "Current target: \(formattedMinutes(minutes))"
        case .arabic:
            return "الهدف الحالي: \(formattedMinutes(minutes))"
        }
    }

    private var noTargetText: String {

        switch localization.language {
        case .hebrew:
            return "אין יעד"
        case .english:
            return "No target"
        case .arabic:
            return "لا يوجد هدف"
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

    private var withinTargetText: String {

        switch localization.language {
        case .hebrew:
            return "בתוך היעד"
        case .english:
            return "Within target"
        case .arabic:
            return "ضمن الهدف"
        }
    }

    private var aboveTargetText: String {

        switch localization.language {
        case .hebrew:
            return "מעל היעד"
        case .english:
            return "Above target"
        case .arabic:
            return "فوق الهدف"
        }
    }

    private var previousChevronName: String {

        switch localization.language {
        case .english:
            return "chevron.left"
        case .hebrew, .arabic:
            return "chevron.right"
        }
    }

    private var nextChevronName: String {

        switch localization.language {
        case .english:
            return "chevron.right"
        case .hebrew, .arabic:
            return "chevron.left"
        }
    }
}