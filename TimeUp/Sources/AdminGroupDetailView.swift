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
                        .font(.system(size: 32, weight: .bold, design: .rounded))

                    HStack(spacing: 8) {
                        Text("קוד קבוצה")

                        Text(group.code)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.secondary)
                }

                // MARK: - Statistics

                HStack(spacing: 12) {
                    statCard(
                        value: "\(store.members(in: group.id).count)",
                        title: "חברים",
                        icon: "person.2.fill"
                    )

                    statCard(
                        value: "\(membersWithTarget)",
                        title: "עם יעד",
                        icon: "target"
                    )

                    statCard(
                        value: "—",
                        title: "רצף קבוצתי",
                        icon: "flame.fill"
                    )
                }

                // MARK: - Goal

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("שיטת היעד", systemImage: "target")
                            .font(.headline)

                        Spacer()

                        NavigationLink {
                            GroupSettingsView(group: $group)
                        } label: {
                            Image(systemName: "gearshape.fill")
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
                        Text("לחץ על חבר כדי להגדיר או לשנות את היעד היומי שלו.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18))

                // MARK: - Members

                VStack(alignment: .leading, spacing: 12) {

                    HStack {
                        Text("חברי הקבוצה")
                            .font(.title3.bold())

                        Spacer()

                        Text("\(store.members(in: group.id).count) חברים")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if store.members(in: group.id).isEmpty {
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
                        ForEach(store.members(in: group.id)) { member in

                            Button {
                                guard group.goalMethod == .manual else {
                                    return
                                }

                                openTargetEditor(for: member)

                            } label: {
                                HStack(spacing: 12) {

                                    Image(systemName: "person.circle.fill")
                                        .font(.title2)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(member.displayName)
                                            .fontWeight(.semibold)

                                        Text(
                                            "הצטרף \(member.joinedAt.formatted(date: .abbreviated, time: .omitted))"
                                        )
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    if let target = member.dailyTargetMinutes {
                                        VStack(alignment: .trailing, spacing: 3) {
                                            Text(formattedTarget(target))
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
                                        Image(systemName: "chevron.left")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .contentShape(Rectangle())
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)

                            Divider()
                        }
                    }
                }

                // MARK: - Analytics

                Button {
                    // Analytics נחבר בהמשך
                } label: {
                    HStack {
                        Image(systemName: "chart.xyaxis.line")

                        Text("Analytics")
                            .fontWeight(.semibold)

                        Spacer()

                        Image(systemName: "chevron.left")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
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

    // MARK: - Target Editor

    private var targetEditor: some View {
        NavigationStack {
            VStack(spacing: 24) {

                VStack(spacing: 6) {
                    Text("יעד זמן מסך יומי")
                        .font(.title2.bold())

                    if let member = editingMember {
                        Text(member.displayName)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 12) {

                    VStack {
                        Text("שעות")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Picker("שעות", selection: $targetHours) {
                            ForEach(0...23, id: \.self) { hour in
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

                        Picker("דקות", selection: $targetMinutes) {
                            ForEach(0..<60, id: \.self) { minute in
                                Text("\(minute)")
                                    .tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                }
                .frame(height: 190)

                Text("יעד: \(formattedTarget(selectedTargetMinutes))")
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
                .disabled(selectedTargetMinutes <= 0)

                if editingMember?.dailyTargetMinutes != nil {
                    Button(role: .destructive) {
                        removeTarget()
                    } label: {
                        Text("הסר יעד")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(24)
            .navigationTitle("הגדרת יעד")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("סגור") {
                        editingMemberID = nil
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Target Logic

    private var editingMember: TimeUpMember? {
        guard let editingMemberID else {
            return nil
        }

        return store.member(id: editingMemberID)
    }

    private var selectedTargetMinutes: Int {
        (targetHours * 60) + targetMinutes
    }

    private var membersWithTarget: Int {
        store.members(in: group.id)
            .filter { $0.dailyTargetMinutes != nil }
            .count
    }

    private func openTargetEditor(for member: TimeUpMember) {
        let currentTarget = member.dailyTargetMinutes ?? 0

        targetHours = currentTarget / 60
        targetMinutes = currentTarget % 60
        editingMemberID = member.id
    }

    private func saveTarget() {
        guard let memberID = editingMemberID else {
            return
        }

        store.setDailyTarget(
            selectedTargetMinutes,
            for: memberID
        )

        editingMemberID = nil
    }

    private func removeTarget() {
        guard let memberID = editingMemberID else {
            return
        }

        store.setDailyTarget(
            nil,
            for: memberID
        )

        editingMemberID = nil
    }

    private func formattedTarget(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 && remainingMinutes > 0 {
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
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
