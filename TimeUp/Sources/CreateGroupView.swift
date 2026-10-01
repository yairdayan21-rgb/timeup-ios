import SwiftUI

struct CreateGroupView: View {

    enum GoalMethod: String, CaseIterable, Identifiable {
        case previousDay
        case adaptiveAverage
        case manual

        var id: String { rawValue }

        var title: String {
            switch self {
            case .previousDay:
                return "פחות מהיום הקודם"
            case .adaptiveAverage:
                return "פחות מהממוצע"
            case .manual:
                return "יעד אישי לכל משתמש"
            }
        }

        var icon: String {
            switch self {
            case .previousDay:
                return "arrow.down.right"
            case .adaptiveAverage:
                return "chart.line.downtrend.xyaxis"
            case .manual:
                return "person.crop.circle.badge.checkmark"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss

    let onGroupCreated: (TimeUpGroup) -> Void

    @State private var groupName = ""
    @State private var selectedMethod: GoalMethod = .previousDay
    @State private var reductionPercent = 5
    @State private var successDays = 7

    private var canCreateGroup: Bool {
        !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {

            Section("פרטי הקבוצה") {
                TextField("שם הקבוצה", text: $groupName)
            }

            Section {
                ForEach(GoalMethod.allCases) { method in
                    Button {
                        selectedMethod = method
                    } label: {
                        HStack(spacing: 14) {

                            Image(systemName: method.icon)
                                .font(.title3)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(method.title)
                                    .fontWeight(.semibold)

                                Text(description(for: method))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if selectedMethod == method {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

            } header: {
                Text("איך נקבע את היעדים?")
            }

            if selectedMethod != .manual {

                Section("תהליך היעדים") {

                    Stepper(
                        "הפחתה: \(reductionPercent)%",
                        value: $reductionPercent,
                        in: 1...50
                    )

                    Stepper(
                        "\(successDays) ימי הצלחה",
                        value: $successDays,
                        in: 1...30
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Label(
                            "יום למידה + \(successDays) ימי הצלחה",
                            systemImage: "brain.head.profile"
                        )
                        .fontWeight(.medium)

                        Text(
                            "יום הלמידה אינו נספר. לאחריו המשתמש צריך להשלים \(successDays) ימי הצלחה רצופים. אם הוא לא עומד ביעד, הספירה חוזרת ליום 1. לאחר השלמת התהליך, היעד האחרון הופך ליעד הקבוע."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

            } else {

                Section("יעד אישי") {
                    Text(
                        "לאחר שמשתמש מצטרף לקבוצה, תוכל להגדיר עבורו יעד זמן מסך אישי."
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
            }

            Section {
                Button {
                    createGroup()
                } label: {
                    Text("צור קבוצה")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .disabled(!canCreateGroup)
            }
        }
        .navigationTitle("קבוצה חדשה")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func description(for method: GoalMethod) -> String {
        switch method {
        case .previousDay:
            return "היעד יורד ב-X% ביחס ליום הקודם למשך Y ימי הצלחה"

        case .adaptiveAverage:
            return "היעד מחושב מהממוצע האישי פחות X% למשך Y ימי הצלחה"

        case .manual:
            return "המנהל קובע יעד נפרד לכל משתמש"
        }
    }

    private func createGroup() {

        let modelMethod: TimeUpGroup.GoalMethod

        switch selectedMethod {
        case .previousDay:
            modelMethod = .previousDay

        case .adaptiveAverage:
            modelMethod = .adaptiveAverage

        case .manual:
            modelMethod = .manual
        }

        let newGroup = TimeUpGroup(
            name: groupName.trimmingCharacters(in: .whitespacesAndNewlines),
            code: generateGroupCode(),
            goalMethod: modelMethod,
            reductionPercent: selectedMethod == .manual ? nil : reductionPercent,
            successDays: selectedMethod == .manual ? nil : successDays
        )

        onGroupCreated(newGroup)
        dismiss()
    }

    private func generateGroupCode() -> String {
        String(format: "%04d", Int.random(in: 1...9999))
    }
}
