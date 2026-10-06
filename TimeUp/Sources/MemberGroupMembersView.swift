import SwiftUI
import Charts

struct MemberGroupMembersView: View {

    let member: TimeUpMember

    @ObservedObject private var store =
        TimeUpStore.shared

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    private var currentMember: TimeUpMember {
        store.member(id: member.id) ?? member
    }

    private var group: TimeUpGroup? {
        store.groups.first {
            $0.id == currentMember.groupID
        }
    }

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
                $0.displayName.localizedCompare(
                    $1.displayName
                ) == .orderedAscending
            }
    }

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 16
            ) {

                header

                if groupMembers.isEmpty {
                    ContentUnavailableView(
                        noMembersText,
                        systemImage: "person.3",
                        description: Text(
                            noMembersDescription
                        )
                    )
                    .frame(
                        maxWidth: .infinity,
                        minHeight: 300
                    )
                } else {
                    membersList
                }
            }
            .padding(16)
        }
        .navigationTitle(membersNavigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var header: some View {
        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text(groupMembersTitle)
                .font(.title2)
                .fontWeight(.bold)

            Text(memberCountText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    // MARK: - Members List

    private var membersList: some View {
        VStack(spacing: 0) {

            ForEach(
                Array(groupMembers.enumerated()),
                id: \.element.id
            ) { index, groupMember in

                NavigationLink {
                    MemberGroupMemberDetailView(
                        member: groupMember,
                        viewingMember: currentMember
                    )
                } label: {
                    memberRow(groupMember)
                }
                .buttonStyle(.plain)

                if index < groupMembers.count - 1 {
                    Divider()
                        .padding(.leading, 58)
                }
            }
        }
        .padding(.horizontal, 16)
        .background {
            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
            .fill(
                Color.secondary.opacity(0.10)
            )
        }
    }

    // MARK: - Member Row

    private func memberRow(
        _ groupMember: TimeUpMember
    ) -> some View {

        HStack(spacing: 12) {

            Image(
                systemName: "person.crop.circle.fill"
            )
            .font(.system(size: 38))
            .foregroundStyle(.secondary)

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                HStack(spacing: 6) {

                    Text(groupMember.displayName)
                        .fontWeight(.semibold)

                    if groupMember.id == currentMember.id {
                        Text(youText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if let progress = store.todayProgress(
                    for: groupMember.id
                ) {
                    Text(
                        todayUsageText(
                            progress.usageMinutes
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                } else {
                    Text(noTodayDataText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            todayStatus(for: groupMember)

            Image(systemName: chevronName)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    // MARK: - Today Status

    @ViewBuilder
    private func todayStatus(
        for groupMember: TimeUpMember
    ) -> some View {

        if let progress = store.todayProgress(
            for: groupMember.id
        ) {

            if progress.isLearningDay {

                Text(learningText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

            } else if let target = progress.targetMinutes {

                if progress.usageMinutes <= target {
                    Image(
                        systemName: "checkmark.circle.fill"
                    )
                    .foregroundStyle(.green)
                } else {
                    Image(
                        systemName: "xmark.circle.fill"
                    )
                    .foregroundStyle(.red)
                }

            } else {
                Image(systemName: "minus.circle")
                    .foregroundStyle(.secondary)
            }

        } else {
            Image(systemName: "minus.circle")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Formatting

    private func formattedMinutes(
        _ minutes: Int
    ) -> String {

        let safe = max(minutes, 0)
        let hours = safe / 60
        let remaining = safe % 60

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

    // MARK: - Localization

    private var membersNavigationTitle: String {
        switch localization.language {
        case .hebrew:
            return "חברים"
        case .english:
            return "Members"
        case .arabic:
            return "الأعضاء"
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

    private var memberCountText: String {
        switch localization.language {
        case .hebrew:
            return "\(groupMembers.count) חברים"
        case .english:
            return "\(groupMembers.count) members"
        case .arabic:
            return "\(groupMembers.count) أعضاء"
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

    private var noMembersDescription: String {
        switch localization.language {
        case .hebrew:
            return "כאשר חברים יצטרפו לקבוצה הם יופיעו כאן."
        case .english:
            return "When members join the group, they will appear here."
        case .arabic:
            return "عندما ينضم أعضاء إلى المجموعة سيظهرون هنا."
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

    private func todayUsageText(
        _ minutes: Int
    ) -> String {
        switch localization.language {
        case .hebrew:
            return "היום: \(formattedMinutes(minutes))"
        case .english:
            return "Today: \(formattedMinutes(minutes))"
        case .arabic:
            return "اليوم: \(formattedMinutes(minutes))"
        }
    }

    private var noTodayDataText: String {
        switch localization.language {
        case .hebrew:
            return "אין עדיין נתונים להיום"
        case .english:
            return "No data for today yet"
        case .arabic:
            return "لا توجد بيانات لليوم بعد"
        }
    }

    private var learningText: String {
        switch localization.language {
        case .hebrew:
            return "למידה"
        case .english:
            return "Learning"
        case .arabic:
            return "تعلّم"
        }
    }

    private var chevronName: String {
        switch localization.language {
        case .english:
            return "chevron.right"
        case .hebrew, .arabic:
            return "chevron.left"
        }
    }
}


// MARK: - Member Detail

private struct MemberGroupMemberDetailView: View {

    let member: TimeUpMember
    let viewingMember: TimeUpMember

    @ObservedObject private var store =
        TimeUpStore.shared

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    @State private var selectedDays = 14

    private let calendar =
        Calendar.current

    private let rangeOptions = [
        7,
        14,
        30
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {

                memberHeader

                rangeSelector

                summaryCard

                historyChart

                historyList
            }
            .padding(16)
        }
        .navigationTitle(member.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Current Stored Member

    private var storedMember: TimeUpMember {
        store.member(id: member.id) ?? member
    }

    // MARK: - Dates

    private var startDate: Date {
        let today = calendar.startOfDay(
            for: Date()
        )

        return calendar.date(
            byAdding: .day,
            value: -(selectedDays - 1),
            to: today
        ) ?? today
    }

    private var endDate: Date {
        calendar.startOfDay(for: Date())
    }

    // MARK: - Progress

    private var progressInRange: [TimeUpDailyProgress] {
        store.progress(for: storedMember.id)
            .filter {
                let date = calendar.startOfDay(
                    for: $0.date
                )

                return date >= startDate &&
                    date <= endDate
            }
            .sorted {
                $0.date < $1.date
            }
    }

    private var progressNewestFirst: [TimeUpDailyProgress] {
        progressInRange.sorted {
            $0.date > $1.date
        }
    }

    // MARK: - Header

    private var memberHeader: some View {
        HStack(spacing: 14) {

            Image(
                systemName: "person.crop.circle.fill"
            )
            .font(.system(size: 58))
            .foregroundStyle(.secondary)

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                HStack(spacing: 7) {

                    Text(storedMember.displayName)
                        .font(.title2)
                        .fontWeight(.bold)

                    if storedMember.id == viewingMember.id {
                        Text(youText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let target = storedMember.dailyTargetMinutes {
                    Text(
                        currentTargetText(
                            target
                        )
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                } else {
                    Text(noCurrentTargetText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    // MARK: - Range

    private var rangeSelector: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text(rangeText)
                .font(.headline)

            Picker(
                rangeText,
                selection: $selectedDays
            ) {
                ForEach(
                    rangeOptions,
                    id: \.self
                ) { days in
                    Text(daysText(days))
                        .tag(days)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(18)
        .background {
            cardBackground
        }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        HStack(spacing: 0) {

            summaryItem(
                title: averageText,
                value: averageUsage.map {
                    formattedMinutes($0)
                } ?? noDataText
            )

            Divider()
                .frame(height: 54)

            summaryItem(
                title: targetSuccessText,
                value: successRate.map {
                    "\(Int($0.rounded()))%"
                } ?? noDataText
            )
        }
        .padding(18)
        .background {
            cardBackground
        }
    }

    private func summaryItem(
        title: String,
        value: String
    ) -> some View {

        VStack(spacing: 5) {

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .monospacedDigit()
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Chart

    private var historyChart: some View {
        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text(screenTimeVsTargetText)
                .font(.headline)

            if progressInRange.isEmpty {

                emptyDataView

            } else {

                Chart(progressInRange) { progress in

                    LineMark(
                        x: .value(
                            dateText,
                            progress.date
                        ),
                        y: .value(
                            screenTimeText,
                            progress.usageMinutes
                        ),
                        series: .value(
                            seriesText,
                            screenTimeText
                        )
                    )
                    .foregroundStyle(
                        Color.accentColor
                    )
                    .interpolationMethod(
                        .catmullRom
                    )

                    PointMark(
                        x: .value(
                            dateText,
                            progress.date
                        ),
                        y: .value(
                            screenTimeText,
                            progress.usageMinutes
                        )
                    )
                    .foregroundStyle(
                        Color.accentColor
                    )

                    if let target = progress.targetMinutes {
                        LineMark(
                            x: .value(
                                dateText,
                                progress.date
                            ),
                            y: .value(
                                targetLabelText,
                                target
                            ),
                            series: .value(
                                seriesText,
                                targetLabelText
                            )
                        )
                        .foregroundStyle(.secondary)
                        .lineStyle(
                            StrokeStyle(
                                lineWidth: 2,
                                dash: [5, 4]
                            )
                        )
                    }
                }
                .chartYAxis {
                    AxisMarks(
                        position: .leading
                    ) { value in

                        AxisGridLine()

                        AxisValueLabel {
                            if let minutes = value.as(Int.self) {
                                Text(
                                    shortTime(minutes)
                                )
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(
                        values: .automatic(
                            desiredCount:
                                selectedDays == 30
                                    ? 5
                                    : 7
                        )
                    ) { _ in

                        AxisGridLine()

                        AxisValueLabel(
                            format:
                                .dateTime
                                .day()
                                .month(.twoDigits)
                        )
                    }
                }
                .frame(height: 250)

                HStack(spacing: 18) {

                    Label(
                        screenTimeText,
                        systemImage: "circle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        Color.accentColor
                    )

                    Label(
                        targetLabelText,
                        systemImage: "minus"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(18)
        .background {
            cardBackground
        }
    }

    // MARK: - History List

    private var historyList: some View {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            Text(historyText)
                .font(.headline)
                .padding(.bottom, 12)

            if progressNewestFirst.isEmpty {

                Text(noDataInRangeText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .center
                    )
                    .padding(.vertical, 30)

            } else {

                ForEach(
                    Array(
                        progressNewestFirst.enumerated()
                    ),
                    id: \.element.id
                ) { index, progress in

                    historyRow(progress)

                    if index <
                        progressNewestFirst.count - 1
                    {
                        Divider()
                    }
                }
            }
        }
        .padding(18)
        .background {
            cardBackground
        }
    }

    private func historyRow(
        _ progress: TimeUpDailyProgress
    ) -> some View {

        HStack(spacing: 12) {

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(
                    formattedDate(
                        progress.date
                    )
                )
                .fontWeight(.semibold)

                if progress.isLearningDay {

                    Text(learningDayText)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                } else if let target = progress.targetMinutes {

                    Text(
                        targetText(
                            target
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                } else {

                    Text(noTargetText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(
                alignment: .trailing,
                spacing: 4
            ) {

                Text(
                    formattedMinutes(
                        progress.usageMinutes
                    )
                )
                .fontWeight(.semibold)
                .monospacedDigit()

                statusLabel(progress)
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - Status

    @ViewBuilder
    private func statusLabel(
        _ progress: TimeUpDailyProgress
    ) -> some View {

        if progress.isLearningDay {

            Text(learningText)
                .font(.caption)
                .foregroundStyle(.secondary)

        } else if let target = progress.targetMinutes {

            if progress.usageMinutes <= target {

                Label(
                    withinTargetText,
                    systemImage: "checkmark.circle.fill"
                )
                .font(.caption)
                .foregroundStyle(.green)

            } else {

                Label(
                    aboveTargetText,
                    systemImage: "xmark.circle.fill"
                )
                .font(.caption)
                .foregroundStyle(.red)
            }

        } else {

            Text(noTargetText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Calculations

    private var averageUsage: Int? {
        let values = progressInRange.map {
            $0.usageMinutes
        }

        guard !values.isEmpty else {
            return nil
        }

        return Int(
            (
                Double(values.reduce(0, +)) /
                Double(values.count)
            ).rounded()
        )
    }

    private var eligibleProgress: [TimeUpDailyProgress] {
        progressInRange.filter {
            !$0.isLearningDay &&
            $0.targetMinutes != nil
        }
    }

    private var successRate: Double? {
        guard !eligibleProgress.isEmpty else {
            return nil
        }

        let successful = eligibleProgress
            .filter {
                $0.achieved
            }
            .count

        return
            Double(successful) /
            Double(eligibleProgress.count) *
            100
    }

    // MARK: - Empty

    private var emptyDataView: some View {
        VStack(spacing: 10) {

            Image(
                systemName: "chart.xyaxis.line"
            )
            .font(.system(size: 36))
            .foregroundStyle(.secondary)

            Text(noDataText)
                .font(.headline)

            Text(noScreenTimeInRangeText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 190)
    }

    // MARK: - Formatting

    private func formattedDate(
        _ date: Date
    ) -> String {

        let formatter =
            DateFormatter()

        formatter.locale =
            localization.language.locale

        formatter.setLocalizedDateFormatFromTemplate(
            "dMMMyyyy"
        )

        return formatter.string(
            from: date
        )
    }

    private func formattedMinutes(
        _ minutes: Int
    ) -> String {

        let safe = max(minutes, 0)
        let hours = safe / 60
        let remaining = safe % 60

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

    private func shortTime(
        _ minutes: Int
    ) -> String {

        if minutes < 60 {
            switch localization.language {
            case .hebrew:
                return "\(minutes)ד׳"
            case .english:
                return "\(minutes)m"
            case .arabic:
                return "\(minutes)د"
            }
        }

        let hours =
            Double(minutes) / 60

        switch localization.language {
        case .hebrew:
            return String(
                format: "%.1fש׳",
                hours
            )

        case .english:
            return String(
                format: "%.1fh",
                hours
            )

        case .arabic:
            return String(
                format: "%.1fس",
                hours
            )
        }
    }

    // MARK: - Card

    private var cardBackground: some View {
        RoundedRectangle(
            cornerRadius: 20,
            style: .continuous
        )
        .fill(
            Color.secondary.opacity(0.10)
        )
    }

    // MARK: - Localization

    private var youText: String {
        switch localization.language {
        case .hebrew: return "אתה"
        case .english: return "You"
        case .arabic: return "أنت"
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

    private var noCurrentTargetText: String {
        switch localization.language {
        case .hebrew: return "אין יעד נוכחי"
        case .english: return "No current target"
        case .arabic: return "لا يوجد هدف حالي"
        }
    }

    private var rangeText: String {
        switch localization.language {
        case .hebrew: return "טווח"
        case .english: return "Range"
        case .arabic: return "النطاق"
        }
    }

    private func daysText(
        _ days: Int
    ) -> String {
        switch localization.language {
        case .hebrew: return "\(days) ימים"
        case .english: return "\(days) days"
        case .arabic: return "\(days) أيام"
        }
    }

    private var averageText: String {
        switch localization.language {
        case .hebrew: return "ממוצע"
        case .english: return "Average"
        case .arabic: return "المتوسط"
        }
    }

    private var targetSuccessText: String {
        switch localization.language {
        case .hebrew: return "עמידה ביעד"
        case .english: return "Target success"
        case .arabic: return "تحقيق الهدف"
        }
    }

    private var noDataText: String {
        switch localization.language {
        case .hebrew: return "אין נתונים"
        case .english: return "No data"
        case .arabic: return "لا توجد بيانات"
        }
    }

    private var screenTimeVsTargetText: String {
        switch localization.language {
        case .hebrew: return "זמן מסך מול יעד"
        case .english: return "Screen time vs. target"
        case .arabic: return "وقت الشاشة مقابل الهدف"
        }
    }

    private var dateText: String {
        switch localization.language {
        case .hebrew: return "תאריך"
        case .english: return "Date"
        case .arabic: return "التاريخ"
        }
    }

    private var screenTimeText: String {
        switch localization.language {
        case .hebrew: return "זמן מסך"
        case .english: return "Screen time"
        case .arabic: return "وقت الشاشة"
        }
    }

    private var seriesText: String {
        switch localization.language {
        case .hebrew: return "סדרה"
        case .english: return "Series"
        case .arabic: return "السلسلة"
        }
    }

    private var targetLabelText: String {
        switch localization.language {
        case .hebrew: return "יעד"
        case .english: return "Target"
        case .arabic: return "الهدف"
        }
    }

    private var historyText: String {
        switch localization.language {
        case .hebrew: return "היסטוריה"
        case .english: return "History"
        case .arabic: return "السجل"
        }
    }

    private var noDataInRangeText: String {
        switch localization.language {
        case .hebrew:
            return "אין נתונים בטווח שנבחר."
        case .english:
            return "There is no data in the selected range."
        case .arabic:
            return "لا توجد بيانات ضمن النطاق المحدد."
        }
    }

    private var learningDayText: String {
        switch localization.language {
        case .hebrew: return "יום למידה"
        case .english: return "Learning day"
        case .arabic: return "يوم تعلّم"
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

    private var noTargetText: String {
        switch localization.language {
        case .hebrew: return "אין יעד"
        case .english: return "No target"
        case .arabic: return "لا يوجد هدف"
        }
    }

    private var learningText: String {
        switch localization.language {
        case .hebrew: return "למידה"
        case .english: return "Learning"
        case .arabic: return "تعلّم"
        }
    }

    private var withinTargetText: String {
        switch localization.language {
        case .hebrew: return "בתוך היעד"
        case .english: return "Within target"
        case .arabic: return "ضمن الهدف"
        }
    }

    private var aboveTargetText: String {
        switch localization.language {
        case .hebrew: return "מעל היעד"
        case .english: return "Above target"
        case .arabic: return "فوق الهدف"
        }
    }

    private var noScreenTimeInRangeText: String {
        switch localization.language {
        case .hebrew:
            return "אין נתוני זמן מסך בטווח שנבחר."
        case .english:
            return "There is no screen-time data in the selected range."
        case .arabic:
            return "لا توجد بيانات وقت شاشة ضمن النطاق المحدد."
        }
    }
}