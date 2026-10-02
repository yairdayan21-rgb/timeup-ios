import SwiftUI
import Charts

struct MemberGroupMembersView: View {

    let member: TimeUpMember

    @ObservedObject private var store = TimeUpStore.shared

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
                        "אין חברים בקבוצה",
                        systemImage: "person.3",
                        description: Text(
                            "כאשר חברים יצטרפו לקבוצה הם יופיעו כאן."
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
        .navigationTitle("חברים")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var header: some View {
        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text("חברי הקבוצה")
                .font(.title2)
                .fontWeight(.bold)

            Text("\(groupMembers.count) חברים")
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
                        Text("אתה")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if let progress = store.todayProgress(
                    for: groupMember.id
                ) {
                    Text(
                        "היום: \(formattedMinutes(progress.usageMinutes))"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                } else {
                    Text("אין עדיין נתונים להיום")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            todayStatus(for: groupMember)

            Image(systemName: "chevron.left")
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

                Text("למידה")
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

        if hours == 0 {
            return "\(remaining) דק׳"
        }

        if remaining == 0 {
            return "\(hours) שע׳"
        }

        return "\(hours) שע׳ \(remaining) דק׳"
    }
}


// MARK: - Member Detail

private struct MemberGroupMemberDetailView: View {

    let member: TimeUpMember
    let viewingMember: TimeUpMember

    @ObservedObject private var store = TimeUpStore.shared

    @State private var selectedDays = 14

    private let calendar = Calendar.current

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
                        Text("אתה")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let target = storedMember.dailyTargetMinutes {
                    Text(
                        "יעד נוכחי: \(formattedMinutes(target))"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                } else {
                    Text("אין יעד נוכחי")
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

            Text("טווח")
                .font(.headline)

            Picker(
                "טווח",
                selection: $selectedDays
            ) {
                ForEach(
                    rangeOptions,
                    id: \.self
                ) { days in
                    Text("\(days) ימים")
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
                title: "ממוצע",
                value: averageUsage.map {
                    formattedMinutes($0)
                } ?? "אין נתונים"
            )

            Divider()
                .frame(height: 54)

            summaryItem(
                title: "עמידה ביעד",
                value: successRate.map {
                    "\(Int($0.rounded()))%"
                } ?? "אין נתונים"
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

            Text("זמן מסך מול יעד")
                .font(.headline)

            if progressInRange.isEmpty {

                emptyDataView

            } else {

                Chart(progressInRange) { progress in

                    LineMark(
                        x: .value(
                            "תאריך",
                            progress.date
                        ),
                        y: .value(
                            "זמן מסך",
                            progress.usageMinutes
                        ),
                        series: .value(
                            "סדרה",
                            "זמן מסך"
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
                            "תאריך",
                            progress.date
                        ),
                        y: .value(
                            "זמן מסך",
                            progress.usageMinutes
                        )
                    )
                    .foregroundStyle(
                        Color.accentColor
                    )

                    if let target = progress.targetMinutes {
                        LineMark(
                            x: .value(
                                "תאריך",
                                progress.date
                            ),
                            y: .value(
                                "יעד",
                                target
                            ),
                            series: .value(
                                "סדרה",
                                "יעד"
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
                        "זמן מסך",
                        systemImage: "circle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        Color.accentColor
                    )

                    Label(
                        "יעד",
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

            Text("היסטוריה")
                .font(.headline)
                .padding(.bottom, 12)

            if progressNewestFirst.isEmpty {

                Text("אין נתונים בטווח שנבחר.")
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
                    progress.date.formatted(
                        date: .abbreviated,
                        time: .omitted
                    )
                )
                .fontWeight(.semibold)

                if progress.isLearningDay {

                    Text("יום למידה")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                } else if let target = progress.targetMinutes {

                    Text(
                        "יעד: \(formattedMinutes(target))"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                } else {

                    Text("אין יעד")
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

            Text("למידה")
                .font(.caption)
                .foregroundStyle(.secondary)

        } else if let target = progress.targetMinutes {

            if progress.usageMinutes <= target {

                Label(
                    "בתוך היעד",
                    systemImage: "checkmark.circle.fill"
                )
                .font(.caption)
                .foregroundStyle(.green)

            } else {

                Label(
                    "מעל היעד",
                    systemImage: "xmark.circle.fill"
                )
                .font(.caption)
                .foregroundStyle(.red)
            }

        } else {

            Text("אין יעד")
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

            Text("אין נתונים")
                .font(.headline)

            Text(
                "אין נתוני זמן מסך בטווח שנבחר."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 190)
    }

    // MARK: - Formatting

    private func formattedMinutes(
        _ minutes: Int
    ) -> String {

        let safe = max(minutes, 0)
        let hours = safe / 60
        let remaining = safe % 60

        if hours == 0 {
            return "\(remaining) דק׳"
        }

        if remaining == 0 {
            return "\(hours) שע׳"
        }

        return "\(hours) שע׳ \(remaining) דק׳"
    }

    private func shortTime(
        _ minutes: Int
    ) -> String {

        if minutes < 60 {
            return "\(minutes)ד׳"
        }

        let hours =
            Double(minutes) / 60

        return String(
            format: "%.1fש׳",
            hours
        )
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
}
