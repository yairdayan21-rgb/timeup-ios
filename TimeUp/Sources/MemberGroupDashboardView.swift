import SwiftUI
import Charts

struct MemberGroupDashboardView: View {

    let member: TimeUpMember

    @ObservedObject private var store =
        TimeUpStore.shared

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

                rangeSelector

                averageTrendCard

                memberComparisonCard

                successRateCard
            }
            .padding(16)
        }
        .navigationTitle("Dashboard")
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
            $0.id ==
                currentMember.groupID
        }
    }

    // MARK: - Members

    private var groupMembers:
        [TimeUpMember]
    {

        guard let group else {
            return []
        }

        return store.members
            .filter {
                $0.groupID ==
                    group.id &&
                $0.role ==
                    .member
            }
            .sorted {
                $0.displayName
                    .localizedCompare(
                        $1.displayName
                    ) ==
                    .orderedAscending
            }
    }

    // MARK: - Date Range

    private var startDate: Date {

        let today =
            calendar.startOfDay(
                for: Date()
            )

        return calendar.date(
            byAdding: .day,
            value:
                -(selectedDays - 1),
            to: today
        ) ?? today
    }

    private var endDate: Date {

        calendar.startOfDay(
            for: Date()
        )
    }

    private var datesInRange:
        [Date]
    {

        guard selectedDays > 0 else {
            return []
        }

        return (0..<selectedDays)
            .compactMap { offset in

                calendar.date(
                    byAdding: .day,
                    value: offset,
                    to: startDate
                )
            }
            .map {
                calendar.startOfDay(
                    for: $0
                )
            }
    }

    // MARK: - Range Selector

    private var rangeSelector:
        some View
    {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text("טווח נתונים")
                .font(.headline)

            Picker(
                "טווח נתונים",
                selection:
                    $selectedDays
            ) {

                ForEach(
                    rangeOptions,
                    id: \.self
                ) { days in

                    Text(
                        "\(days) ימים"
                    )
                    .tag(days)
                }
            }
            .pickerStyle(.segmented)

            Text(dateRangeText)
                .font(.footnote)
                .foregroundStyle(
                    .secondary
                )
        }
        .padding(18)
        .background {
            cardBackground
        }
    }

    // MARK: - Average Trend

    private var averageTrendCard:
        some View
    {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(
                    "מגמת זמן מסך ממוצע קבוצתי"
                )
                .font(.headline)

                Text(
                    "ממוצע זמן המסך של חברי הקבוצה בכל יום"
                )
                .font(.footnote)
                .foregroundStyle(
                    .secondary
                )
            }

            if averageTrendData
                .isEmpty
            {

                noDataView(
                    text:
                        "אין עדיין מספיק נתוני זמן מסך להצגת המגמה."
                )

            } else {

                Chart(
                    averageTrendData
                ) { point in

                    LineMark(
                        x: .value(
                            "תאריך",
                            point.date
                        ),
                        y: .value(
                            "דקות",
                            point.minutes
                        )
                    )
                    .interpolationMethod(
                        .catmullRom
                    )

                    PointMark(
                        x: .value(
                            "תאריך",
                            point.date
                        ),
                        y: .value(
                            "דקות",
                            point.minutes
                        )
                    )
                }
                .chartYScale(
                    domain:
                        0...averageTrendMaximum
                )
                .chartYAxis {

                    AxisMarks(
                        position: .leading
                    ) { value in

                        AxisGridLine()

                        AxisValueLabel {

                            if let minutes =
                                value.as(
                                    Int.self
                                )
                            {

                                Text(
                                    shortTime(
                                        minutes
                                    )
                                )
                            }
                        }
                    }
                }
                .chartXAxis {

                    AxisMarks(
                        values:
                            .automatic(
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
                                .month(
                                    .twoDigits
                                )
                        )
                    }
                }
                .frame(height: 240)
            }
        }
        .padding(18)
        .background {
            cardBackground
        }
    }

    // MARK: - Member Comparison

    private var memberComparisonCard:
        some View
    {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(
                    "השוואת זמן מסך בין חברי הקבוצה"
                )
                .font(.headline)

                Text(
                    "ממוצע זמן המסך לכל חבר בטווח שנבחר"
                )
                .font(.footnote)
                .foregroundStyle(
                    .secondary
                )
            }

            if memberAverageData
                .isEmpty
            {

                noDataView(
                    text:
                        "אין עדיין מספיק נתונים להשוואה בין חברי הקבוצה."
                )

            } else {

                Chart(
                    memberAverageData
                ) { item in

                    BarMark(
                        x: .value(
                            "זמן מסך",
                            item.minutes
                        ),
                        y: .value(
                            "חבר",
                            item.name
                        )
                    )
                    .annotation(
                        position: .trailing
                    ) {

                        Text(
                            formattedMinutes(
                                item.minutes
                            )
                        )
                        .font(.caption2)
                        .foregroundStyle(
                            .secondary
                        )
                    }
                }
                .chartXScale(
                    domain:
                        0...memberComparisonMaximum
                )
                .chartXAxis {

                    AxisMarks { value in

                        AxisGridLine()

                        AxisValueLabel {

                            if let minutes =
                                value.as(
                                    Int.self
                                )
                            {

                                Text(
                                    shortTime(
                                        minutes
                                    )
                                )
                            }
                        }
                    }
                }
                .frame(
                    height:
                        max(
                            220,
                            CGFloat(
                                memberAverageData
                                    .count
                            ) * 52
                        )
                )
            }
        }
        .padding(18)
        .background {
            cardBackground
        }
    }

    // MARK: - Success Rate

    private var successRateCard:
        some View
    {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(
                    "אחוז עמידה בממוצע הקבוצתי"
                )
                .font(.headline)

                Text(
                    "אחוז הרשומות שבהן חברי הקבוצה עמדו ביעד"
                )
                .font(.footnote)
                .foregroundStyle(
                    .secondary
                )
            }

            if let rate =
                groupSuccessRate
            {

                HStack(
                    alignment: .center,
                    spacing: 18
                ) {

                    ZStack {

                        Circle()
                            .stroke(
                                Color.secondary
                                    .opacity(
                                        0.15
                                    ),
                                lineWidth: 14
                            )

                        Circle()
                            .trim(
                                from: 0,
                                to:
                                    CGFloat(
                                        rate
                                    ) / 100
                            )
                            .stroke(
                                Color.accentColor,
                                style:
                                    StrokeStyle(
                                        lineWidth:
                                            14,
                                        lineCap:
                                            .round
                                    )
                            )
                            .rotationEffect(
                                .degrees(-90)
                            )

                        Text(
                            "\(Int(rate.rounded()))%"
                        )
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                    }
                    .frame(
                        width: 120,
                        height: 120
                    )

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        Text(
                            "\(successfulEntries) מתוך \(eligibleEntries)"
                        )
                        .font(.title3)
                        .fontWeight(
                            .semibold
                        )

                        Text(
                            "עמידות ביעד בטווח שנבחר"
                        )
                        .font(.subheadline)
                        .foregroundStyle(
                            .secondary
                        )

                        Text(
                            "ימי למידה ורשומות ללא יעד אינם נכללים בחישוב."
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )
                    }

                    Spacer(
                        minLength: 0
                    )
                }

            } else {

                noDataView(
                    text:
                        "אין עדיין מספיק נתונים עם יעד לחישוב אחוז העמידה."
                )
            }
        }
        .padding(18)
        .background {
            cardBackground
        }
    }

    // MARK: - Progress In Range

    private var progressInRange:
        [TimeUpDailyProgress]
    {

        let memberIDs =
            Set(
                groupMembers.map {
                    $0.id
                }
            )

        return store.dailyProgress
            .filter { progress in

                guard
                    memberIDs.contains(
                        progress.memberID
                    )
                else {
                    return false
                }

                let date =
                    calendar.startOfDay(
                        for:
                            progress.date
                    )

                return
                    date >= startDate &&
                    date <= endDate
            }
    }

    // MARK: - Average Trend Data

    private var averageTrendData:
        [GroupAveragePoint]
    {

        datesInRange
            .compactMap { date in

                let values =
                    progressInRange
                        .filter {
                            calendar.isDate(
                                $0.date,
                                inSameDayAs:
                                    date
                            )
                        }
                        .map {
                            $0.usageMinutes
                        }

                guard
                    !values.isEmpty
                else {
                    return nil
                }

                let average =
                    Int(
                        (
                            Double(
                                values.reduce(
                                    0,
                                    +
                                )
                            ) /
                            Double(
                                values.count
                            )
                        )
                        .rounded()
                    )

                return GroupAveragePoint(
                    date: date,
                    minutes: average
                )
            }
    }

    // MARK: - Member Average Data

    private var memberAverageData:
        [MemberAveragePoint]
    {

        groupMembers
            .compactMap {
                groupMember in

                let values =
                    progressInRange
                        .filter {
                            $0.memberID ==
                                groupMember.id
                        }
                        .map {
                            $0.usageMinutes
                        }

                guard
                    !values.isEmpty
                else {
                    return nil
                }

                let average =
                    Int(
                        (
                            Double(
                                values.reduce(
                                    0,
                                    +
                                )
                            ) /
                            Double(
                                values.count
                            )
                        )
                        .rounded()
                    )

                return MemberAveragePoint(
                    memberID:
                        groupMember.id,
                    name:
                        groupMember
                            .displayName,
                    minutes:
                        average
                )
            }
            .sorted {
                $0.minutes <
                    $1.minutes
            }
    }

    // MARK: - Success Rate Data

    private var eligibleProgress:
        [TimeUpDailyProgress]
    {

        progressInRange
            .filter {
                !$0.isLearningDay &&
                $0.targetMinutes != nil
            }
    }

    private var eligibleEntries: Int {

        eligibleProgress.count
    }

    private var successfulEntries: Int {

        eligibleProgress
            .filter {
                $0.achieved
            }
            .count
    }

    private var groupSuccessRate:
        Double?
    {

        guard
            eligibleEntries > 0
        else {
            return nil
        }

        return
            (
                Double(
                    successfulEntries
                ) /
                Double(
                    eligibleEntries
                )
            ) * 100
    }

    // MARK: - Chart Scales

    private var averageTrendMaximum:
        Int
    {

        let maximum =
            averageTrendData
                .map {
                    $0.minutes
                }
                .max() ?? 60

        return max(
            60,
            Int(
                Double(maximum) *
                    1.15
            )
        )
    }

    private var memberComparisonMaximum:
        Int
    {

        let maximum =
            memberAverageData
                .map {
                    $0.minutes
                }
                .max() ?? 60

        return max(
            60,
            Int(
                Double(maximum) *
                    1.20
            )
        )
    }

    // MARK: - Formatting

    private var dateRangeText:
        String
    {

        let start =
            startDate.formatted(
                .dateTime
                    .day()
                    .month()
            )

        let end =
            endDate.formatted(
                .dateTime
                    .day()
                    .month()
                    .year()
            )

        return "\(start) – \(end)"
    }

    private func formattedMinutes(
        _ minutes: Int
    ) -> String {

        let safe =
            max(minutes, 0)

        let hours =
            safe / 60

        let remaining =
            safe % 60

        if hours == 0 {
            return "\(remaining) דק׳"
        }

        if remaining == 0 {
            return "\(hours) שע׳"
        }

        return
            "\(hours) שע׳ \(remaining) דק׳"
    }

    private func shortTime(
        _ minutes: Int
    ) -> String {

        if minutes < 60 {
            return "\(minutes)ד׳"
        }

        let value =
            Double(minutes) / 60

        return String(
            format: "%.1fש׳",
            value
        )
    }

    // MARK: - Empty State

    private func noDataView(
        text: String
    ) -> some View {

        VStack(spacing: 12) {

            Image(
                systemName:
                    "chart.bar.xaxis"
            )
            .font(
                .system(size: 36)
            )
            .foregroundStyle(
                .secondary
            )

            Text("אין נתונים")
                .font(.headline)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(
                    .secondary
                )
                .multilineTextAlignment(
                    .center
                )
        }
        .frame(
            maxWidth: .infinity
        )
        .frame(
            minHeight: 180
        )
    }

    // MARK: - Card Background

    private var cardBackground:
        some View
    {

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


// MARK: - Chart Models

private struct GroupAveragePoint:
    Identifiable
{

    let id = UUID()

    let date: Date

    let minutes: Int
}


private struct MemberAveragePoint:
    Identifiable
{

    let memberID: UUID

    let name: String

    let minutes: Int

    var id: UUID {
        memberID
    }
}
