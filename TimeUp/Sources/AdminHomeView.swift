import SwiftUI

struct AdminHomeView: View {
    @State private var showCreateGroup = false
    @State private var groups: [TimeUpGroup] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    VStack(alignment: .leading, spacing: 4) {
                        Text("TimeUp")
                            .font(.system(size: 34, weight: .bold, design: .rounded))

                        Text("ניהול הקבוצות שלך")
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        showCreateGroup = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)

                            Text("יצירת קבוצה חדשה")
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

                    VStack(alignment: .leading, spacing: 12) {
                        Text("הקבוצות שלי")
                            .font(.title3.bold())

                        if groups.isEmpty {

                            ContentUnavailableView(
                                "עדיין אין קבוצות",
                                systemImage: "person.3",
                                description: Text(
                                    "צור את הקבוצה הראשונה שלך כדי להתחיל."
                                )
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)

                        } else {

                            ForEach($groups) { $group in
                                groupCard(group: $group)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // הגדרות מנהל – נחבר בהמשך
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .navigationDestination(isPresented: $showCreateGroup) {
                CreateGroupView { newGroup in
                    groups.append(newGroup)
                }
            }
        }
    }

    private func groupCard(
        group: Binding<TimeUpGroup>
    ) -> some View {

        VStack(alignment: .leading, spacing: 14) {

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.wrappedValue.name)
                        .font(.headline)

                    Text("קוד קבוצה")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                NavigationLink {
                    GroupSettingsView(group: group)
                } label: {
                    Image(systemName: "gearshape")
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }

            Text(group.wrappedValue.code)
                .font(
                    .system(
                        size: 28,
                        weight: .bold,
                        design: .monospaced
                    )
                )
                .tracking(4)

            Divider()

            HStack {
                Label(
                    goalDescription(group.wrappedValue),
                    systemImage: "target"
                )

                Spacer()

                if let days = group.wrappedValue.successDays {
                    Text("\(days) ימים")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func goalDescription(
        _ group: TimeUpGroup
    ) -> String {

        switch group.goalMethod {

        case .previousDay:
            return "\(group.reductionPercent ?? 0)% פחות מהיום הקודם"

        case .adaptiveAverage:
            return "\(group.reductionPercent ?? 0)% פחות מהממוצע"

        case .manual:
            return "יעד אישי"
        }
    }
}
