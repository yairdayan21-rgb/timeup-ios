import SwiftUI

struct MemberGroupDetailView: View {

    let member: TimeUpMember

    @ObservedObject private var store =
        TimeUpStore.shared

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
        .navigationTitle("פירוט קבוצתי")
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
                    systemName: "chevron.right"
                )
                .frame(
                    width: 40,
                    height: 40
                )
            }
            .buttonStyle(.bordered)

            Spacer()

            VStack(spacing: 4) {

                Text("תאריך")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(
                    selectedDate.formatted(
                        date: .abbreviated,
                        time: .omitted
                    )
                )
                .font(.headline)
            }

            Spacer()

            Button {

                moveDate(by: 1)

            } label: {

                Image(
                    systemName: "chevron.left"
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

                Text("ממוצע קבוצתי")
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
                    "מבוסס על \(membersWithDataCount) מתוך \(groupMembers.count) חברים עם נתונים ביום זה"
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
                    "אין נתונים",
                    systemImage:
                        "chart.bar.xaxis",
                    description:
                        Text(
                            "עדיין אין נתוני זמן מסך לקבוצה בתאריך הזה."
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

                Text("חברי הקבוצה")
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
                    "אין חברים בקבוצה",
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

                        Text("אתה")
                            .font(.caption2)
                            .foregroundStyle(
                                .secondary
                            )
                    }
                }

                if let progress {

                    Text(
                        "יעד: \(formattedMinutes(progress.targetMinutes))"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )

                } else if let target =
                            groupMember
                                .dailyTargetMinutes
                {

                    Text(
                        "יעד נוכחי: \(formattedMinutes(target))"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )

                } else {

                    Text("אין יעד")
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
                            progress.screenTimeMinutes
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

                Text("אין נתונים")
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

        store.dailyProgress
            .filter {
                $0.memberID ==
                    groupMember.id
            }
            .first {
                calendar.isDate(
                    $0.date,
                    inSameDayAs:
                        selectedDate
                )
            }
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

        return progress.screenTimeMinutes <=
            progress.targetMinutes
            ? .green
            : .red
    }

    @ViewBuilder
    private func statusLabel(
        for progress:
            TimeUpDailyProgress
    ) -> some View {

        if progress.isLearningDay {

            Text("יום למידה")
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )

        } else if
            progress.screenTimeMinutes <=
                progress.targetMinutes
        {

            Label(
                "בתוך היעד",
                systemImage:
                    "checkmark.circle.fill"
            )
            .font(.caption)
            .foregroundStyle(.green)

        } else {

            Label(
                "מעל היעד",
                systemImage:
                    "xmark.circle.fill"
            )
            .font(.caption)
            .foregroundStyle(.red)
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
                $0.screenTimeMinutes
            }

        guard !values.isEmpty else {
            return nil
        }

        let total =
            values.reduce(0, +)

        return Int(
            (Double(total) /
             Double(values.count))
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

    // MARK: - Formatting

    private func formattedMinutes(
        _ minutes: Int
    ) -> String {

        let safeMinutes =
            max(minutes, 0)

        let hours =
            safeMinutes / 60

        let remainingMinutes =
            safeMinutes % 60

        if hours == 0 {

            return "\(remainingMinutes) דק׳"
        }

        if remainingMinutes == 0 {

            return "\(hours) שע׳"
        }

        return
            "\(hours) שע׳ \(remainingMinutes) דק׳"
    }
}
