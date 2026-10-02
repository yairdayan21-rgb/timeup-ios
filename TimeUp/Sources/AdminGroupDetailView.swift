import SwiftUI

struct AdminGroupDetailView: View {

    @Binding var group: TimeUpGroup
    @StateObject private var store = TimeUpStore.shared

    @State private var editingMemberID: UUID?
    @State private var targetHours = 0
    @State private var targetMinutes = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {

                // MARK: - Group Header

                VStack(alignment: .leading, spacing: 8) {
                    Text(group.name)
                        .font(
                            .system(
                                size: 32,
                                weight: .bold,
                                design: .rounded
                            )
                        )

                    HStack(spacing: 8) {
                        Text("קוד קבוצה")

                        Text(group.code)
                            .font(
                                .system(
                                    .body,
                                    design: .monospaced
                                )
                            )
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.secondary)
                }

                // MARK: - Group Statistics

                HStack(spacing: 12) {

                    statCard(
                        value: "\(groupMembers.count)",
                        title: "חברים",
                        icon: "person.2.fill"
                    )

                    statCard(
                        value: "\(membersSucceededLastDay)",
                        title: "הצליחו",
                        icon: "checkmark.circle.fill"
                    )

                    statCard(
                        value: "\(groupStreak)",
                        title: "רצף קבוצתי",
                        icon: "flame.fill"
                    )
                }

                // MARK: - Goal

                VStack(alignment: .leading, spacing: 12) {

                    HStack {
                        Label(
                            "שיטת היעד",
                            systemImage: "target"
                        )
                        .font(.headline)

                        Spacer()

                        NavigationLink {
                            GroupSettingsView(
                                group: $group
                            )
                        } label: {
                            Image(
                                systemName: "gearshape.fill"
                            )
                        }
                    }

                    Text(goalTitle)
                        .font(.title3.bold())

                    if group.goalMethod != .manual {

                        HStack {
                            Label(
                                "\(group.reductionPercent ?? 0)% הפחתה",
                                systemImage: "arrow.down.right"
                            )

                            Spacer()

                            Label(
                                "\(group.successDays ?? 0) ימי הצלחה",
                                systemImage: "calendar"
                            )
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        Text(
                            "יום למידה + \(group.successDays ?? 0) ימי הצלחה רצופים"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    } else {

                        Text(
                            "לחץ על חבר כדי להגדיר או לשנות את היעד היומי שלו."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 18
                    )
                )

                // MARK: - Members

                VStack(alignment: .leading, spacing: 12) {

                    HStack {
                        Text("חברי הקבוצה")
                            .font(.title3.bold())

                        Spacer()

                        Text(
                            "\(groupMembers.count) חברים"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    if groupMembers.isEmpty {

                        ContentUnavailableView(
                            "עדיין אין חברים",
                            systemImage: "person.3",
                            description: Text(
                                "שתף את קוד הקבוצה \(group.code) כדי שמשתמשים יוכלו להצטרף."
                            )
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)

                    } else {

                        ForEach(groupMembers) { member in

                            memberRow(member)

                            Divider()
                        }
                    }
                }

                // MARK: - Group Progress

                if !groupMembers.isEmpty {

                    VStack(alignment: .leading, spacing: 14) {

                        Label(
                            "מצב הקבוצה",
                            systemImage: "chart.bar.fill"
                        )
                        .font(.headline)

                        HStack {
                            Text("הצליחו ביום האחרון")

                            Spacer()

                            Text(
                                "\(membersSucceededLastDay) מתוך \(membersWithCompletedDay)"
                            )
                            .fontWeight(.semibold)
                        }

                        HStack {
                            Text("ביום למידה")

                            Spacer()

                            Text(
                                "\(membersInLearningPhase)"
                            )
                            .fontWeight(.semibold)
                        }

                        HStack {
                            Text("עם יעד פעיל")

                            Spacer()

                            Text(
                                "\(membersWithTarget) מתוך \(groupMembers.count)"
                            )
                            .fontWeight(.semibold)
                        }
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 18
                        )
                    )
                }

                // MARK: - Analytics

                Button {
                    // Analytics מפורט נחבר בהמשך.
                } label: {
                    HStack {
                        Image(
                            systemName: "chart.xyaxis.line"
                        )

                        Text("Analytics")
                            .fontWeight(.semibold)

                        Spacer()

                        Image(
                            systemName: "chevron.left"
                        )
                        .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.thinMaterial)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 18
                        )
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .navigationTitle("ניהול קבוצה")
        .navigationBarTitleDisplayMode(.inline)

        .sheet(
            isPresented: Binding(
                get: {
                    editingMemberID != nil
                },
                set: { newValue in
                    if !newValue {
                        editingMemberID = nil
                    }
                }
            )
        ) {
            targetEditor
        }
    }

    // MARK: - Members

    private var groupMembers: [TimeUpMember] {
        store.members(
            in: group.id
        )
    }

    @ViewBuilder
    private func memberRow(
        _ member: TimeUpMember
    ) -> some View {

        Button {

            guard group.goalMethod == .manual else {
                return
            }

            openTargetEditor(
                for: member
            )

        } label: {

            HStack(spacing: 12) {

                // MARK: Member Icon

                ZStack {

                    Image(
                        systemName: "person.circle.fill"
                    )
                    .font(.title2)

                    if let progress =
                        lastProgress(for: member)
                    {
                        Circle()
                            .fill(
                                progressStatusColor(
                                    progress
                                )
                            )
                            .frame(
                                width: 9,
                                height: 9
                            )
                            .offset(
                                x: 10,
                                y: 10
                            )
                    }
                }

                // MARK: Member Information

                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {

                    Text(member.displayName)
                        .fontWeight(.semibold)

                    Text(
                        memberStatusText(member)
                    )
                    .font(.caption)
                    .foregroundStyle(
                        memberStatusColor(member)
                    )

                    Text(
                        "הצטרף \(member.joinedAt.formatted(date: .abbreviated, time: .omitted))"
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // MARK: Member Streak

                if memberStreak(member) > 0 {

                    VStack(spacing: 3) {

                        HStack(spacing: 3) {
                            Image(
                                systemName: "flame.fill"
                            )

                            Text(
                                "\(memberStreak(member))"
                            )
                            .fontWeight(.bold)
                        }

                        Text("רצף")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // MARK: Member Target

                if let target =
                    member.dailyTargetMinutes
                {

                    VStack(
                        alignment: .trailing,
                        spacing: 3
                    ) {

                        Text(
                            formattedTarget(target)
                        )
                        .fontWeight(.semibold)

                        Text("יעד יומי")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                } else if group.goalMethod == .manual {

                    Text("הגדר יעד")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }

                if group.goalMethod == .manual {

                    Image(
                        systemName: "chevron.left"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Member Progress

    private func lastProgress(
        for member: TimeUpMember
    ) -> TimeUpDailyProgress? {

        store.progress(
            for: member.id
        )
        .last
    }

    private func memberStreak(
        _ member: TimeUpMember
    ) -> Int {

        store.currentStreak(
            for: member.id
        )
    }

    private func memberStatusText(
        _ member: TimeUpMember
    ) -> String {

        guard let progress =
            lastProgress(for: member)
        else {
            return "יום למידה / ממתין לנתונים"
        }

        if progress.isLearningDay {
            return "יום למידה הושלם"
        }

        if progress.achieved {
            return "עמד ביעד האחרון"
        }

        return "לא עמד ביעד האחרון"
    }

    private func memberStatusColor(
        _ member: TimeUpMember
    ) -> Color {

        guard let progress =
            lastProgress(for: member)
        else {
            return .secondary
        }

        if progress.isLearningDay {
            return .secondary
        }

        return progress.achieved
            ? .green
            : .red
    }

    private func progressStatusColor(
        _ progress: TimeUpDailyProgress
    ) -> Color {

        if progress.isLearningDay {
            return .orange
        }

        return progress.achieved
            ? .green
            : .red
    }

    // MARK: - Group Statistics

    private var membersWithTarget: Int {

        groupMembers
            .filter {
                $0.dailyTargetMinutes != nil
            }
            .count
    }

    private var membersWithCompletedDay: Int {

        groupMembers
            .filter {
                lastProgress(for: $0) != nil
            }
            .count
    }

    private var membersSucceededLastDay: Int {

        groupMembers
            .compactMap {
                lastProgress(for: $0)
            }
            .filter {
                !$0.isLearningDay &&
                $0.achieved
            }
            .count
    }

    private var membersInLearningPhase: Int {

        groupMembers
            .filter { member in

                let history =
                    store.progress(
                        for: member.id
                    )

                if history.isEmpty {
                    return true
                }

                return history.last?
                    .isLearningDay == true &&
                    history.count == 1
            }
            .count
    }

    // MARK: - Group Streak

    private var groupStreak: Int {

        guard !groupMembers.isEmpty else {
            return 0
        }

        let histories =
            groupMembers.map { member in
                store.progress(
                    for: member.id
                )
                .filter {
                    !$0.isLearningDay
                }
            }

        // עדיין אין מספיק מידע לכל חברי הקבוצה.
        guard histories.allSatisfy(
            { !$0.isEmpty }
        ) else {
            return 0
        }

        let minimumHistoryCount =
            histories.map {
                $0.count
            }
            .min() ?? 0

        guard minimumHistoryCount > 0 else {
            return 0
        }

        var streak = 0

        // סופרים אחורה ימים שבהם כל חברי הקבוצה
        // עמדו ביעד.
        for offset in 0..<minimumHistoryCount {

            let allSucceeded =
                histories.allSatisfy { history in

                    let index =
                        history.count - 1 - offset

                    guard index >= 0 else {
                        return false
                    }

                    return history[index].achieved
                }

            if allSucceeded {
                streak += 1
            } else {
                break
            }
        }

        return streak
    }

    // MARK: - Target Editor

    private var targetEditor: some View {

        NavigationStack {

            VStack(spacing: 24) {

                VStack(spacing: 6) {

                    Text("יעד זמן מסך יומי")
                        .font(.title2.bold())

                    if let member =
                        editingMember
                    {
                        Text(
                            member.displayName
                        )
                        .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 12) {

                    VStack {

                        Text("שעות")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Picker(
                            "שעות",
                            selection: $targetHours
                        ) {

                            ForEach(
                                0...23,
                                id: \.self
                            ) { hour in

                                Text("\(hour)")
                                    .tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                    }

                    VStack {

                        Text("דקות")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Picker(
                            "דקות",
                            selection: $targetMinutes
                        ) {

                            ForEach(
                                0..<60,
                                id: \.self
                            ) { minute in

                                Text("\(minute)")
                                    .tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                }
                .frame(height: 190)

                Text(
                    "יעד: \(formattedTarget(selectedTargetMinutes))"
                )
                .font(.title3.bold())

                Spacer()

                Button {
                    saveTarget()

                } label: {

                    Text("שמור יעד")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    selectedTargetMinutes <= 0
                )

                if editingMember?
                    .dailyTargetMinutes != nil
                {

                    Button(
                        role: .destructive
                    ) {
                        removeTarget()

                    } label: {

                        Text("הסר יעד")
                            .frame(
                                maxWidth: .infinity
                            )
                    }
                }
            }
            .padding(24)
            .navigationTitle("הגדרת יעד")
            .navigationBarTitleDisplayMode(.inline)

            .toolbar {

                ToolbarItem(
                    placement: .cancellationAction
                ) {

                    Button("סגור") {
                        editingMemberID = nil
                    }
                }
            }
        }
        .presentationDetents(
            [.medium, .large]
        )
    }

    // MARK: - Target Logic

    private var editingMember: TimeUpMember? {

        guard let editingMemberID else {
            return nil
        }

        return store.member(
            id: editingMemberID
        )
    }

    private var selectedTargetMinutes: Int {

        (targetHours * 60) +
        targetMinutes
    }

    private func openTargetEditor(
        for member: TimeUpMember
    ) {

        let currentTarget =
            member.dailyTargetMinutes ?? 0

        targetHours =
            currentTarget / 60

        targetMinutes =
            currentTarget % 60

        editingMemberID =
            member.id
    }

    private func saveTarget() {

        guard let memberID =
            editingMemberID
        else {
            return
        }

        store.setDailyTarget(
            selectedTargetMinutes,
            for: memberID
        )

        editingMemberID = nil
    }

    private func removeTarget() {

        guard let memberID =
            editingMemberID
        else {
            return
        }

        store.setDailyTarget(
            nil,
            for: memberID
        )

        editingMemberID = nil
    }

    // MARK: - Formatting

    private func formattedTarget(
        _ minutes: Int
    ) -> String {

        let hours =
            minutes / 60

        let remainingMinutes =
            minutes % 60

        if hours > 0 &&
            remainingMinutes > 0
        {
            return "\(hours) ש׳ \(remainingMinutes) דק׳"
        }

        if hours > 0 {
            return "\(hours) ש׳"
        }

        return "\(remainingMinutes) דק׳"
    }

    // MARK: - Goal

    private var goalTitle: String {

        switch group.goalMethod {

        case .previousDay:
            return "\(group.reductionPercent ?? 0)% פחות מהיום הקודם"

        case .adaptiveAverage:
            return "\(group.reductionPercent ?? 0)% פחות מהממוצע"

        case .manual:
            return "יעד אישי לכל משתמש"
        }
    }

    // MARK: - Stat Card

    private func statCard(
        value: String,
        title: String,
        icon: String
    ) -> some View {

        VStack(spacing: 8) {

            Image(systemName: icon)
                .font(.title3)

            Text(value)
                .font(.title2.bold())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.thinMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }
}
