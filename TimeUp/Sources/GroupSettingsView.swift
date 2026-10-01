import SwiftUI

struct GroupSettingsView: View {

    @Environment(\.dismiss) private var dismiss

    @Binding var group: TimeUpGroup

    @State private var selectedMethod: TimeUpGroup.GoalMethod
    @State private var reductionPercent: Int
    @State private var successDays: Int

    init(group: Binding<TimeUpGroup>) {
        self._group = group

        _selectedMethod = State(
            initialValue: group.wrappedValue.goalMethod
        )

        _reductionPercent = State(
            initialValue: group.wrappedValue.reductionPercent ?? 5
        )

        _successDays = State(
            initialValue: group.wrappedValue.successDays ?? 7
        )
    }

    var body: some View {
        Form {

            Section("פרטי הקבוצה") {
                LabeledContent("שם", value: group.name)

                LabeledContent("קוד קבוצה") {
                    Text(group.code)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.bold)
                }
            }

            Section("שיטת קביעת היעדים") {

                goalMethodButton(
                    method: .previousDay,
                    title: "פחות מהיום הקודם",
                    description: "היעד יורד ב-X% ביחס ליום הקודם"
                )

                goalMethodButton(
                    method: .adaptiveAverage,
                    title: "פחות מהממוצע",
                    description: "הממוצע האישי פחות X%"
                )

                goalMethodButton(
                    method: .manual,
                    title: "יעד אישי לכל משתמש",
                    description: "המנהל קובע יעד נפרד לכל חבר בקבוצה"
                )
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
                            "יום הלמידה אינו חלק מ-\(successDays) הימים. אם משתמש לא עומד ביעד במהלך התהליך, הספירה שלו חוזרת ליום 1. לאחר \(successDays) ימי הצלחה רצופים, היעד האחרון הופך ליעד הקבוע שלו."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

            } else {

                Section("יעדים אישיים") {
                    Text(
                        "היעד יוגדר בנפרד עבור כל משתמש בקבוצה."
                    )
                    .foregroundStyle(.secondary)
                }
            }

            Section {
                Button {
                    saveChanges()
                } label: {
                    Text("שמור שינויים")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("הגדרות קבוצה")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func goalMethodButton(
        method: TimeUpGroup.GoalMethod,
        title: String,
        description: String
    ) -> some View {

        Button {
            selectedMethod = method
        } label: {

            HStack {

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .fontWeight(.semibold)

                    Text(description)
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

    private func saveChanges() {

        group.goalMethod = selectedMethod

        if selectedMethod == .manual {
            group.reductionPercent = nil
            group.successDays = nil
        } else {
            group.reductionPercent = reductionPercent
            group.successDays = successDays
        }

        dismiss()
    }
}
