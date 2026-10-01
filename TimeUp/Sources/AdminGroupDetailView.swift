import SwiftUI

struct AdminGroupDetailView: View {

    @Binding var group: TimeUpGroup

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
                        value: "0",
                        title: "חברים",
                        icon: "person.2.fill"
                    )

                    statCard(
                        value: "0",
                        title: "ביעד היום",
                        icon: "target"
                    )

                    statCard(
                        value: "0",
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

                        Text("0 חברים")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    ContentUnavailableView(
                        "עדיין אין חברים",
                        systemImage: "person.3",
                        description: Text(
                            "שתף את קוד הקבוצה \(group.code) כדי שמשתמשים יוכלו להצטרף."
                        )
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
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
    }

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
