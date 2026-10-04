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

        var databaseValue: String {
            switch self {
            case .previousDay:
                return "personal_percentage"
            case .adaptiveAverage:
                return "group_average_percentage"
            case .manual:
                return "manual"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss

    @StateObject private var dataStore =
        SupabaseDataStore.shared

    @State private var groupName = ""
    @State private var selectedMethod: GoalMethod = .previousDay
    @State private var reductionPercent = 5
    @State private var successDays = 7

    @State private var errorMessage: String?
    @State private var showError = false

    private var canCreateGroup: Bool {
        !groupName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty &&
        !dataStore.isCreatingGroup
    }

    var body: some View {

        Form {

            Section("פרטי הקבוצה") {

                TextField(
                    "שם הקבוצה",
                    text: $groupName
                )
            }

            Section {

                ForEach(
                    GoalMethod.allCases
                ) { method in

                    Button {

                        selectedMethod = method

                    } label: {

                        HStack(spacing: 14) {

                            Image(
                                systemName:
                                    method.icon
                            )
                            .font(.title3)
                            .frame(width: 30)

                            VStack(
                                alignment: .leading,
                                spacing: 4
                            ) {

                                Text(method.title)
                                    .fontWeight(
                                        .semibold
                                    )

                                Text(
                                    description(
                                        for: method
                                    )
                                )
                                .font(.caption)
                                .foregroundStyle(
                                    .secondary
                                )
                            }

                            Spacer()

                            if selectedMethod ==
                                method {

                                Image(
                                    systemName:
                                        "checkmark.circle.fill"
                                )
                                .foregroundStyle(
                                    .blue
                                )
                            }
                        }
                        .contentShape(
                            Rectangle()
                        )
                    }
                    .buttonStyle(.plain)
                }

            } header: {

                Text(
                    "איך נקבע את היעדים?"
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

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        Label(
                            "יום למידה + \(successDays) ימי הצלחה",
                            systemImage:
                                "brain.head.profile"
                        )
                        .fontWeight(.medium)

                        Text(
                            "יום הלמידה אינו נספר. לאחריו המשתמש צריך להשלים \(successDays) ימי הצלחה רצופים. אם הקבוצה לא עומדת ביעד, הספירה מתאפסת. לאחר השלמת התהליך, היעד האחרון הופך ליעד הקבוע."
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )
                    }
                    .padding(
                        .vertical,
                        6
                    )
                }

            } else {

                Section("יעד אישי") {

                    Text(
                        "לאחר שמשתמש מצטרף לקבוצה, תוכל להגדיר עבורו יעד זמן מסך אישי."
                    )
                    .font(.callout)
                    .foregroundStyle(
                        .secondary
                    )
                }
            }

            Section {

                Button {

                    Task {
                        await createGroup()
                    }

                } label: {

                    HStack {

                        Spacer()

                        if dataStore
                            .isCreatingGroup {

                            ProgressView()
                        }

                        Text(
                            dataStore
                                .isCreatingGroup
                                ? "יוצר קבוצה..."
                                : "צור קבוצה"
                        )
                        .fontWeight(
                            .semibold
                        )

                        Spacer()
                    }
                }
                .disabled(
                    !canCreateGroup
                )
            }
        }
        .navigationTitle(
            "קבוצה חדשה"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
        .interactiveDismissDisabled(
            dataStore.isCreatingGroup
        )
        .alert(
            "לא ניתן ליצור את הקבוצה",
            isPresented: $showError
        ) {

            Button(
                "אישור",
                role: .cancel
            ) {}

        } message: {

            Text(
                errorMessage ??
                "אירעה שגיאה לא צפויה."
            )
        }
    }

    private func description(
        for method: GoalMethod
    ) -> String {

        switch method {

        case .previousDay:

            return
                "היעד יורד ב-X% ביחס לשימוש של היום הקודם"

        case .adaptiveAverage:

            return
                "לכל חברי הקבוצה נקבע יעד זהה לפי ממוצע השימוש הקבוצתי פחות X%"

        case .manual:

            return
                "המנהל קובע יעד נפרד לכל משתמש"
        }
    }

    private func createGroup() async {

        do {

            try await dataStore
                .createGroup(
                    name:
                        groupName
                            .trimmingCharacters(
                                in:
                                    .whitespacesAndNewlines
                            ),
                    goalMethod:
                        selectedMethod
                            .databaseValue,
                    reductionPercent:
                        selectedMethod == .manual
                            ? nil
                            : reductionPercent,
                    successDays:
                        selectedMethod == .manual
                            ? nil
                            : successDays
                )

            dismiss()

        } catch {

            errorMessage =
                error.localizedDescription

            showError = true
        }
    }
}
