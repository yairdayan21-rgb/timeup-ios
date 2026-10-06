import SwiftUI
import Charts

struct MemberGroupDashboardView: View {

    let member: TimeUpMember

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

                rangeSelector

                averageTrendCard

                memberComparisonCard

                successRateCard
            }
            .padding(16)
        }
        .navigationTitle(dashboardTitle)
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

            Text(dataRangeText)
                .font(.headline)

            Picker(
                dataRangeText,
                selection:
                    $selectedDays
            ) {

                ForEach(
                    rangeOptions,
                    id: \.self
                ) { days in

                    Text(
                        daysText(days)
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
                    averageTrendTitle
                )
                .font(.headline)

                Text(
                    averageTrendDescription
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
                        averageTrendEmptyText
                )

            } else {

                Chart(
                    averageTrendData
                ) { point in

                    LineMark(
                        x: .value(
                            chartDateText,
                            point.date
                        ),
                        y: .value(
                            chartMinutesText,
                            point.minutes
                        )
                    )
                    .interpolationMethod(
                        .catmullRom
                    )

                    PointMark(
                        x: .value(
                            chartDateText,
                            point.date
                        ),
                        y: .value(
                            chartMinutesText,
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
                    memberComparisonTitle
                )
                .font(.headline)

                Text(
                    memberComparisonDescription
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
                        memberComparisonEmptyText
                )

            } else {

                Chart(
                    memberAverageData
                ) { item in

                    BarMark(
                        x: .value(
                            screenTimeText,
                            item.minutes
                        ),
                        y: .value(
                            memberText,
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
                    successRateTitle
                )
                .font(.headline)

                Text(
                    successRateDescription
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
                            successEntriesText
                        )
                        .font(.title3)
                        .fontWeight(
                            .semibold
                        )

                        Text(
                            successEntriesDescription
                        )
                        .font(.subheadline)
                        .foregroundStyle(
                            .secondary
                        )

                        Text(
                            successCalculationNote
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
                        successRateEmptyText
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

        let startFormatter =
            DateFormatter()

        startFormatter.locale =
            localization.language.locale

        startFormatter.setLocalizedDateFormatFromTemplate(
            "dMMM"
        )

        let endFormatter =
            DateFormatter()

        endFormatter.locale =
            localization.language.locale

        endFormatter.setLocalizedDateFormatFromTemplate(
            "dMMMyyyy"
        )

        return
            "\(startFormatter.string(from: startDate)) – \(endFormatter.string(from: endDate))"
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

        switch localization.language {

        case .hebrew:

            if hours == 0 {
                return "\(remaining) דק׳"
            }

            if remaining == 0 {
                return "\(hours) שע׳"
            }

            return
                "\(hours) שע׳ \(remaining) דק׳"

        case .english:

            if hours == 0 {
                return "\(remaining) min"
            }

            if remaining == 0 {
                return "\(hours) hr"
            }

            return
                "\(hours) hr \(remaining) min"

        case .arabic:

            if hours == 0 {
                return "\(remaining) د"
            }

            if remaining == 0 {
                return "\(hours) س"
            }

            return
                "\(hours) س \(remaining) د"
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

        let value =
            Double(minutes) / 60

        switch localization.language {

        case .hebrew:
            return String(
                format: "%.1fש׳",
                value
            )

        case .english:
            return String(
                format: "%.1fh",
                value
            )

        case .arabic:
            return String(
                format: "%.1fس",
                value
            )
        }
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

            Text(noDataText)
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

    // MARK: - Localization

    private var dashboardTitle: String {
        switch localization.language {
        case .hebrew: return "דשבורד"
        case .english: return "Dashboard"
        case .arabic: return "لوحة البيانات"
        }
    }

    private var dataRangeText: String {
        switch localization.language {
        case .hebrew: return "טווח נתונים"
        case .english: return "Data range"
        case .arabic: return "نطاق البيانات"
        }
    }

    private func daysText(
        _ days: Int
    ) -> String {
        switch localization.language {
        case .hebrew:
            return "\(days) ימים"
        case .english:
            return "\(days) days"
        case .arabic:
            return "\(days) أيام"
        }
    }

    private var averageTrendTitle: String {
        switch localization.language {
        case .hebrew:
            return "מגמת זמן מסך ממוצע קבוצתי"
        case .english:
            return "Group average screen-time trend"
        case .arabic:
            return "اتجاه متوسط وقت الشاشة للمجموعة"
        }
    }

    private var averageTrendDescription: String {
        switch localization.language {
        case .hebrew:
            return "ממוצע זמן המסך של חברי הקבוצה בכל יום"
        case .english:
            return "Average screen time of group members each day"
        case .arabic:
            return "متوسط وقت الشاشة لأعضاء المجموعة كل يوم"
        }
    }

    private var averageTrendEmptyText: String {
        switch localization.language {
        case .hebrew:
            return "אין עדיין מספיק נתוני זמן מסך להצגת המגמה."
        case .english:
            return "There is not enough screen-time data to show the trend yet."
        case .arabic:
            return "لا توجد بيانات كافية عن وقت الشاشة لعرض الاتجاه بعد."
        }
    }

    private var memberComparisonTitle: String {
        switch localization.language {
        case .hebrew:
            return "השוואת זמן מסך בין חברי הקבוצה"
        case .english:
            return "Screen-time comparison between group members"
        case .arabic:
            return "مقارنة وقت الشاشة بين أعضاء المجموعة"
        }
    }

    private var memberComparisonDescription: String {
        switch localization.language {
        case .hebrew:
            return "ממוצע זמן המסך לכל חבר בטווח שנבחר"
        case .english:
            return "Average screen time for each member in the selected range"
        case .arabic:
            return "متوسط وقت الشاشة لكل عضو خلال النطاق المحدد"
        }
    }

    private var memberComparisonEmptyText: String {
        switch localization.language {
        case .hebrew:
            return "אין עדיין מספיק נתונים להשוואה בין חברי הקבוצה."
        case .english:
            return "There is not enough data to compare group members yet."
        case .arabic:
            return "لا توجد بيانات كافية لمقارنة أعضاء المجموعة بعد."
        }
    }

    private var successRateTitle: String {
        switch localization.language {
        case .hebrew:
            return "אחוז עמידה בממוצע הקבוצתי"
        case .english:
            return "Group target success rate"
        case .arabic:
            return "نسبة تحقيق أهداف المجموعة"
        }
    }

    private var successRateDescription: String {
        switch localization.language {
        case .hebrew:
            return "אחוז הרשומות שבהן חברי הקבוצה עמדו ביעד"
        case .english:
            return "Percentage of entries where group members met their target"
        case .arabic:
            return "نسبة السجلات التي حقق فيها أعضاء المجموعة أهدافهم"
        }
    }

    private var successEntriesText: String {
        switch localization.language {
        case .hebrew:
            return "\(successfulEntries) מתוך \(eligibleEntries)"
        case .english:
            return "\(successfulEntries) of \(eligibleEntries)"
        case .arabic:
            return "\(successfulEntries) من \(eligibleEntries)"
        }
    }

    private var successEntriesDescription: String {
        switch localization.language {
        case .hebrew:
            return "עמידות ביעד בטווח שנבחר"
        case .english:
            return "Targets achieved in the selected range"
        case .arabic:
            return "الأهداف المحققة ضمن النطاق المحدد"
        }
    }

    private var successCalculationNote: String {
        switch localization.language {
        case .hebrew:
            return "ימי למידה ורשומות ללא יעד אינם נכללים בחישוב."
        case .english:
            return "Learning days and entries without a target are excluded from the calculation."
        case .arabic:
            return "لا يتم احتساب أيام التعلّم والسجلات التي لا تحتوي على هدف."
        }
    }

    private var successRateEmptyText: String {
        switch localization.language {
        case .hebrew:
            return "אין עדיין מספיק נתונים עם יעד לחישוב אחוז העמידה."
        case .english:
            return "There is not enough target data to calculate the success rate yet."
        case .arabic:
            return "لا توجد بيانات أهداف كافية لحساب نسبة النجاح بعد."
        }
    }

    private var chartDateText: String {
        switch localization.language {
        case .hebrew: return "תאריך"
        case .english: return "Date"
        case .arabic: return "التاريخ"
        }
    }

    private var chartMinutesText: String {
        switch localization.language {
        case .hebrew: return "דקות"
        case .english: return "Minutes"
        case .arabic: return "دقائق"
        }
    }

    private var screenTimeText: String {
        switch localization.language {
        case .hebrew: return "זמן מסך"
        case .english: return "Screen time"
        case .arabic: return "وقت الشاشة"
        }
    }

    private var memberText: String {
        switch localization.language {
        case .hebrew: return "חבר"
        case .english: return "Member"
        case .arabic: return "عضو"
        }
    }

    private var noDataText: String {
        switch localization.language {
        case .hebrew: return "אין נתונים"
        case .english: return "No data"
        case .arabic: return "لا توجد بيانات"
        }
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