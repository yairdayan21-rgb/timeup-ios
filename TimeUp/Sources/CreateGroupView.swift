import SwiftUI

struct CreateGroupView: View {

    enum GoalMethod: String, CaseIterable, Identifiable {
        case previousDay
        case adaptiveAverage
        case manual

        var id: String {
            rawValue
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

    @Environment(\.dismiss)
    private var dismiss

    @StateObject private var dataStore =
        SupabaseDataStore.shared

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    @State private var groupName = ""

    @State private var selectedMethod:
        GoalMethod = .previousDay

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

            // MARK: - Group Details

            Section(
                groupDetailsTitle
            ) {

                TextField(
                    groupNamePlaceholder,
                    text: $groupName
                )
            }

            // MARK: - Goal Method

            Section {

                ForEach(
                    GoalMethod.allCases
                ) { method in

                    Button {

                        selectedMethod =
                            method

                    } label: {

                        HStack(
                            spacing: 14
                        ) {

                            Image(
                                systemName:
                                    method.icon
                            )
                            .font(.title3)
                            .frame(
                                width: 30
                            )

                            VStack(
                                alignment: .leading,
                                spacing: 4
                            ) {

                                Text(
                                    title(
                                        for: method
                                    )
                                )
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
                    .buttonStyle(
                        .plain
                    )
                }

            } header: {

                Text(
                    goalMethodHeader
                )
            }

            // MARK: - Percentage Goal

            if selectedMethod !=
                .manual {

                Section(
                    goalProcessTitle
                ) {

                    Stepper(
                        reductionText,
                        value:
                            $reductionPercent,
                        in: 1...50
                    )

                    Stepper(
                        successDaysText,
                        value:
                            $successDays,
                        in: 1...30
                    )

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        Label(
                            learningDayTitle,
                            systemImage:
                                "brain.head.profile"
                        )
                        .fontWeight(
                            .medium
                        )

                        Text(
                            learningDayDescription
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

                // MARK: - Manual Goal

                Section(
                    personalGoalTitle
                ) {

                    Text(
                        personalGoalDescription
                    )
                    .font(.callout)
                    .foregroundStyle(
                        .secondary
                    )
                }
            }

            // MARK: - Create

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
                                ? creatingGroupText
                                : createGroupText
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
            newGroupTitle
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
        .interactiveDismissDisabled(
            dataStore.isCreatingGroup
        )
        .alert(
            unableToCreateTitle,
            isPresented:
                $showError
        ) {

            Button(
                okText,
                role: .cancel
            ) {}

        } message: {

            Text(
                errorMessage ??
                unexpectedErrorText
            )
        }
    }

    // MARK: - Goal Method Text

    private func title(
        for method: GoalMethod
    ) -> String {

        switch method {

        case .previousDay:

            switch localization.language {

            case .hebrew:
                return "פחות מהיום הקודם"

            case .english:
                return "Less than the previous day"

            case .arabic:
                return "أقل من اليوم السابق"
            }

        case .adaptiveAverage:

            switch localization.language {

            case .hebrew:
                return "פחות מהממוצע"

            case .english:
                return "Less than the group average"

            case .arabic:
                return "أقل من متوسط المجموعة"
            }

        case .manual:

            switch localization.language {

            case .hebrew:
                return "יעד אישי לכל משתמש"

            case .english:
                return "Individual target for each user"

            case .arabic:
                return "هدف شخصي لكل مستخدم"
            }
        }
    }

    private func description(
        for method: GoalMethod
    ) -> String {

        switch method {

        case .previousDay:

            switch localization.language {

            case .hebrew:
                return "היעד יורד ב-X% ביחס לשימוש של היום הקודם"

            case .english:
                return "The target is reduced by X% based on each user's previous-day usage"

            case .arabic:
                return "ينخفض الهدف بنسبة X% بناءً على استخدام كل مستخدم في اليوم السابق"
            }

        case .adaptiveAverage:

            switch localization.language {

            case .hebrew:
                return "לכל חברי הקבוצה נקבע יעד זהה לפי ממוצע השימוש הקבוצתי פחות X%"

            case .english:
                return "All group members receive the same target based on the group average minus X%"

            case .arabic:
                return "يحصل جميع أعضاء المجموعة على نفس الهدف بناءً على متوسط استخدام المجموعة ناقص X%"
            }

        case .manual:

            switch localization.language {

            case .hebrew:
                return "המנהל קובע יעד נפרד לכל משתמש"

            case .english:
                return "The admin sets a separate target for each user"

            case .arabic:
                return "يحدد المدير هدفًا منفصلًا لكل مستخدم"
            }
        }
    }

    // MARK: - Create Group

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
                        selectedMethod ==
                            .manual
                            ? nil
                            : reductionPercent,
                    successDays:
                        selectedMethod ==
                            .manual
                            ? nil
                            : successDays
                )

            dismiss()

        } catch {

            errorMessage =
                error.localizedDescription

            showError =
                true
        }
    }

    // MARK: - Localization

    private var groupDetailsTitle: String {

        switch localization.language {

        case .hebrew:
            return "פרטי הקבוצה"

        case .english:
            return "Group details"

        case .arabic:
            return "تفاصيل المجموعة"
        }
    }

    private var groupNamePlaceholder: String {

        switch localization.language {

        case .hebrew:
            return "שם הקבוצה"

        case .english:
            return "Group name"

        case .arabic:
            return "اسم المجموعة"
        }
    }

    private var goalMethodHeader: String {

        switch localization.language {

        case .hebrew:
            return "איך נקבע את היעדים?"

        case .english:
            return "How should targets be set?"

        case .arabic:
            return "كيف يتم تحديد الأهداف؟"
        }
    }

    private var goalProcessTitle: String {

        switch localization.language {

        case .hebrew:
            return "תהליך היעדים"

        case .english:
            return "Target journey"

        case .arabic:
            return "مسار الأهداف"
        }
    }

    private var reductionText: String {

        switch localization.language {

        case .hebrew:
            return "הפחתה: \(reductionPercent)%"

        case .english:
            return "Reduction: \(reductionPercent)%"

        case .arabic:
            return "التخفيض: \(reductionPercent)%"
        }
    }

    private var successDaysText: String {

        switch localization.language {

        case .hebrew:
            return "\(successDays) ימי הצלחה"

        case .english:
            return successDays == 1
                ? "1 success day"
                : "\(successDays) success days"

        case .arabic:
            return "\(successDays) أيام نجاح"
        }
    }

    private var learningDayTitle: String {

        switch localization.language {

        case .hebrew:
            return "יום למידה + \(successDays) ימי הצלחה"

        case .english:
            return "Learning day + \(successDays) success days"

        case .arabic:
            return "يوم تعلّم + \(successDays) أيام نجاح"
        }
    }

    private var learningDayDescription: String {

        switch localization.language {

        case .hebrew:
            return "יום הלמידה אינו נספר. לאחריו המשתמש צריך להשלים \(successDays) ימי הצלחה רצופים. אם הקבוצה לא עומדת ביעד, הספירה מתאפסת. לאחר השלמת התהליך, היעד האחרון הופך ליעד הקבוע."

        case .english:
            return "The learning day does not count toward the streak. After it, the user must complete \(successDays) consecutive successful days. If the group misses its target, the count resets. After completing the journey, the final target becomes the fixed target."

        case .arabic:
            return "يوم التعلّم لا يُحتسب ضمن السلسلة. بعده يجب على المستخدم إكمال \(successDays) أيام نجاح متتالية. إذا لم تحقق المجموعة الهدف، تتم إعادة العد إلى الصفر. بعد إكمال المسار، يصبح الهدف الأخير هو الهدف الثابت."
        }
    }

    private var personalGoalTitle: String {

        switch localization.language {

        case .hebrew:
            return "יעד אישי"

        case .english:
            return "Individual target"

        case .arabic:
            return "هدف شخصي"
        }
    }

    private var personalGoalDescription: String {

        switch localization.language {

        case .hebrew:
            return "לאחר שמשתמש מצטרף לקבוצה, תוכל להגדיר עבורו יעד זמן מסך אישי."

        case .english:
            return "After a user joins the group, you can set an individual screen-time target for them."

        case .arabic:
            return "بعد انضمام المستخدم إلى المجموعة، يمكنك تحديد هدف شخصي لوقت الشاشة له."
        }
    }

    private var creatingGroupText: String {

        switch localization.language {

        case .hebrew:
            return "יוצר קבוצה..."

        case .english:
            return "Creating group..."

        case .arabic:
            return "جارٍ إنشاء المجموعة..."
        }
    }

    private var createGroupText: String {

        switch localization.language {

        case .hebrew:
            return "צור קבוצה"

        case .english:
            return "Create group"

        case .arabic:
            return "إنشاء مجموعة"
        }
    }

    private var newGroupTitle: String {

        switch localization.language {

        case .hebrew:
            return "קבוצה חדשה"

        case .english:
            return "New group"

        case .arabic:
            return "مجموعة جديدة"
        }
    }

    private var unableToCreateTitle: String {

        switch localization.language {

        case .hebrew:
            return "לא ניתן ליצור את הקבוצה"

        case .english:
            return "Unable to create group"

        case .arabic:
            return "تعذر إنشاء المجموعة"
        }
    }

    private var okText: String {

        switch localization.language {

        case .hebrew:
            return "אישור"

        case .english:
            return "OK"

        case .arabic:
            return "موافق"
        }
    }

    private var unexpectedErrorText: String {

        switch localization.language {

        case .hebrew:
            return "אירעה שגיאה לא צפויה."

        case .english:
            return "An unexpected error occurred."

        case .arabic:
            return "حدث خطأ غير متوقع."
        }
    }
}