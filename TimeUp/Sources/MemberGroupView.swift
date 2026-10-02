import SwiftUI

struct MemberGroupView: View {

    let member: TimeUpMember

    @ObservedObject private var store =
        TimeUpStore.shared

    @State private var selectedSection:
        GroupSection = .overview

    private enum GroupSection: String, CaseIterable {
        case overview = "סקירה"
        case detail = "פירוט"
        case dashboard = "Dashboard"
        case members = "חברים"
        case chat = "צ׳אט"
    }

    var body: some View {

        VStack(spacing: 0) {

            sectionPicker

            Divider()

            Group {

                switch selectedSection {

                case .overview:

                    overviewView

                case .detail:

                    MemberGroupDetailView(
                        member: currentMember
                    )

                case .dashboard:

                    comingSoonView(
                        title: "Dashboard",
                        icon: "chart.xyaxis.line",
                        message:
                            "כאן יוצגו הנתונים והגרפים הקבוצתיים."
                    )

                case .members:

                    comingSoonView(
                        title: "חברים",
                        icon: "person.2.fill",
                        message:
                            "כאן יוצגו כל חברי הקבוצה."
                    )

                case .chat:

                    comingSoonView(
                        title: "צ׳אט",
                        icon: "bubble.left.and.bubble.right.fill",
                        message:
                            "כאן יהיה הצ׳אט של הקבוצה."
                    )
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
        }
        .navigationTitle(
            group?.name ?? "הקבוצה"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
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

        return store.members.filter {
            $0.groupID == group.id
        }
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {

        ScrollView(
            .horizontal,
            showsIndicators: false
        ) {

            HStack(spacing: 8) {

                ForEach(
                    GroupSection.allCases,
                    id: \.self
                ) { section in

                    Button {

                        withAnimation(
                            .easeInOut(duration: 0.18)
                        ) {

                            selectedSection =
                                section
                        }

                    } label: {

                        Text(section.rawValue)
                            .font(.subheadline)
                            .fontWeight(
                                selectedSection == section
                                    ? .bold
                                    : .medium
                            )
                            .padding(
                                .horizontal,
                                14
                            )
                            .padding(
                                .vertical,
                                9
                            )
                            .background {

                                if selectedSection == section {

                                    Capsule()
                                        .fill(
                                            Color.accentColor
                                        )

                                } else {

                                    Capsule()
                                        .fill(
                                            Color.secondary
                                                .opacity(0.12)
                                        )
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
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Overview

    private var overviewView: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 20
            ) {

                groupHeader

                groupStreakCard

                journeyCard

                todayStatusCard

                membersPreview
            }
            .padding(16)
        }
    }

    // MARK: - Header

    private var groupHeader: some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text(
                group?.name ?? "הקבוצה שלך"
            )
            .font(.largeTitle)
            .fontWeight(.bold)

            HStack(spacing: 6) {

                Image(
                    systemName: "person.3.fill"
                )

                Text(
                    "\(groupMembers.count) חברים"
                )
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    // MARK: - Group Streak

    private var groupStreakCard: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text("רצף קבוצתי")
                        .font(.headline)

                    Text(
                        "\(groupStreak) ימים"
                    )
                    .font(
                        .system(
                            size: 34,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                }

                Spacer()

                Image(
                    systemName: "flame.fill"
                )
                .font(
                    .system(size: 40)
                )
                .foregroundStyle(.orange)
            }

            Text(
                groupStreak == 0
                    ? "הרצף מתחיל כאשר כל חברי הקבוצה עומדים ביעד."
                    : "כל חברי הקבוצה צריכים לעמוד ביעד כדי להמשיך את הרצף."
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
            .fill(
                Color.secondary
                    .opacity(0.10)
            )
        }
    }

    // MARK: - Journey

    private var journeyCard: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text("המסע הקבוצתי")
                        .font(.headline)

                    Text(
                        journeySubtitle
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Text(
                    "\(min(groupStreak, successDays))/\(successDays)"
                )
                .font(.headline)
                .monospacedDigit()
            }

            ProgressView(
                value: Double(
                    min(
                        groupStreak,
                        successDays
                    )
                ),
                total: Double(
                    max(successDays, 1)
                )
            )

            journeyDays
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

    private var journeyDays: some View {

        LazyVGrid(
            columns: [
                GridItem(
                    .adaptive(
                        minimum: 42,
                        maximum: 48
                    ),
                    spacing: 10
                )
            ],
            spacing: 10
        ) {

            ForEach(
                1...successDays,
                id: \.self
            ) { day in

                ZStack {

                    Circle()
                        .fill(
                            day <= groupStreak
                                ? Color.accentColor
                                : Color.secondary
                                    .opacity(0.14)
                        )
                        .frame(
                            width: 42,
                            height: 42
                        )

                    if day <= groupStreak {

                        Image(
                            systemName: "checkmark"
                        )
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    } else {

                        Text("\(day)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(
                                .secondary
                            )
                    }
                }
            }
        }
    }

    private var journeySubtitle: String {

        if groupStreak >= successDays {

            return "הקבוצה השלימה את היעד"

        } else {

            let remaining =
                max(
                    successDays - groupStreak,
                    0
                )

            return
                "עוד \(remaining) ימים להשלמת היעד"
        }
    }

    // MARK: - Today

    private var todayStatusCard: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack {

                Text("היום בקבוצה")
                    .font(.headline)

                Spacer()

                Text(
                    Date.now,
                    format:
                        .dateTime
                        .day()
                        .month()
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Divider()

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text("חברי קבוצה")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(
                        "\(groupMembers.count)"
                    )
                    .font(.title2)
                    .fontWeight(.bold)
                }

                Spacer()

                VStack(
                    alignment: .trailing,
                    spacing: 4
                ) {

                    Text("רצף נוכחי")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(
                        "\(groupStreak)"
                    )
                    .font(.title2)
                    .fontWeight(.bold)
                }
            }

            Text(
                "היום ייחשב כחלק מהרצף רק לאחר שכל חברי הקבוצה יסיימו את היום ויעמדו ביעד שלהם."
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
            .fill(
                Color.secondary
                    .opacity(0.10)
            )
        }
    }

    // MARK: - Members Preview

    private var membersPreview: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack {

                Text("חברי הקבוצה")
                    .font(.headline)

                Spacer()

                Button("הצג הכל") {

                    selectedSection =
                        .members
                }
                .font(.subheadline)
            }

            if groupMembers.isEmpty {

                ContentUnavailableView(
                    "אין חברים בקבוצה",
                    systemImage: "person.3"
                )

            } else {

                ForEach(
                    Array(
                        groupMembers.prefix(4)
                    )
                ) { groupMember in

                    HStack(spacing: 12) {

                        Image(
                            systemName:
                                "person.crop.circle.fill"
                        )
                        .font(
                            .system(size: 34)
                        )
                        .foregroundStyle(
                            .secondary
                        )

                        VStack(
                            alignment: .leading,
                            spacing: 2
                        ) {

                            Text(
                                groupMember.displayName
                            )
                            .fontWeight(.semibold)

                            if groupMember.id ==
                                currentMember.id
                            {

                                Text("אתה")
                                    .font(.caption)
                                    .foregroundStyle(
                                        .secondary
                                    )
                            }
                        }

                        Spacer()
                    }

                    if groupMember.id !=
                        groupMembers
                            .prefix(4)
                            .last?
                            .id
                    {

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
            .fill(
                Color.secondary
                    .opacity(0.10)
            )
        }
    }

    // MARK: - Current Group Streak

    private var groupStreak: Int {

        let calendar =
            Calendar.current

        let members =
            groupMembers.filter {
                $0.role == .member
            }

        guard !members.isEmpty else {
            return 0
        }

        var streak = 0

        var date =
            calendar.startOfDay(
                for:
                    calendar.date(
                        byAdding: .day,
                        value: -1,
                        to: Date()
                    ) ?? Date()
            )

        while true {

            var allAchieved = true

            for groupMember in members {

                let progress =
                    store.dailyProgress
                        .filter {
                            $0.memberID ==
                                groupMember.id
                        }
                        .first {
                            calendar.isDate(
                                $0.date,
                                inSameDayAs: date
                            )
                        }

                guard
                    let progress,
                    !progress.isLearningDay,
                    progress.achieved
                else {

                    allAchieved = false
                    break
                }
            }

            guard allAchieved else {
                break
            }

            streak += 1

            guard
                let previousDay =
                    calendar.date(
                        byAdding: .day,
                        value: -1,
                        to: date
                    )
            else {
                break
            }

            date =
                calendar.startOfDay(
                    for: previousDay
                )
        }

        return streak
    }

    // MARK: - Success Days

    private var successDays: Int {

        max(
            group?.successDays ?? 7,
            1
        )
    }

    // MARK: - Placeholder

    private func comingSoonView(
        title: String,
        icon: String,
        message: String
    ) -> some View {

        VStack(spacing: 16) {

            Spacer()

            Image(systemName: icon)
                .font(
                    .system(size: 48)
                )
                .foregroundStyle(
                    .secondary
                )

            Text(title)
                .font(.title2)
                .fontWeight(.bold)

            Text(message)
                .foregroundStyle(
                    .secondary
                )
                .multilineTextAlignment(
                    .center
                )
                .padding(.horizontal, 32)

            Spacer()
        }
    }
}
