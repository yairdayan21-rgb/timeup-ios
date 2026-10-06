import SwiftUI
import Supabase

struct GroupSettingsView: View {

    let group: SupabaseDataStore.TimeUpRemoteGroup

    @Environment(\.dismiss) private var dismiss

    @StateObject private var dataStore =
        SupabaseDataStore.shared

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    @State private var groupName: String
    @State private var selectedMethod: GoalMethod
    @State private var reductionPercent: Int
    @State private var successDays: Int

    @State private var isSaving = false
    @State private var saveError: String?

    private let client =
        SupabaseManager.shared.client

    enum GoalMethod: String, CaseIterable {

        case personalPercentage =
            "personal_percentage"

        case groupAveragePercentage =
            "group_average_percentage"

        case manual =
            "manual"
    }

    init(
        group: SupabaseDataStore.TimeUpRemoteGroup
    ) {

        self.group = group

        _groupName = State(
            initialValue: group.name
        )

        _selectedMethod = State(
            initialValue:
                GoalMethod(
                    rawValue: group.goalMethod
                ) ?? .personalPercentage
        )

        _reductionPercent = State(
            initialValue:
                group.reductionPercent ?? 5
        )

        _successDays = State(
            initialValue:
                group.successDays ?? 7
        )
    }

    var body: some View {

        Form {

            // MARK: - Group Details

            Section(groupDetailsTitle) {

                TextField(
                    groupNamePlaceholder,
                    text: $groupName
                )

                LabeledContent(
                    groupCodeText
                ) {

                    Text(group.code)
                        .font(
                            .system(
                                .body,
                                design: .monospaced
                            )
                        )
                        .fontWeight(.bold)
                }
            }

            // MARK: - Goal Method

            Section(
                goalMethodSectionTitle
            ) {

                goalMethodButton(
                    method:
                        .personalPercentage,
                    title:
                        personalPercentageTitle,
                    description:
                        personalPercentageDescription
                )

                goalMethodButton(
                    method:
                        .groupAveragePercentage,
                    title:
                        groupAverageTitle,
                    description:
                        groupAverageDescription
                )

                goalMethodButton(
                    method:
                        .manual,
                    title:
                        manualTitle,
                    description:
                        manualDescription
                )
            }

            // MARK: - Percentage Settings

            if selectedMethod != .manual {

                Section(
                    targetSettingsTitle
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
                            learningJourneyTitle,
                            systemImage:
                                "brain.head.profile"
                        )
                        .fontWeight(.medium)

                        Text(
                            learningJourneyDescription
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

                Section(
                    individualTargetsTitle
                ) {

                    Label(
                        individualTargetsLabel,
                        systemImage:
                            "person.crop.circle.badge.checkmark"
                    )

                    Text(
                        individualTargetsDescription
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                }
            }

            // MARK: - Change Behavior

            Section {

                Label(
                    historyPreservedText,
                    systemImage:
                        "clock.arrow.circlepath"
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )

                Text(
                    nextTargetChangeText
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }

            // MARK: - Save

            Section {

                Button {

                    Task {
                        await saveChanges()
                    }

                } label: {

                    HStack {

                        Spacer()

                        if isSaving {

                            ProgressView()
                                .padding(
                                    .trailing,
                                    4
                                )

                            Text(savingText)

                        } else {

                            Image(
                                systemName:
                                    "checkmark.circle.fill"
                            )

                            Text(
                                saveChangesText
                            )
                            .fontWeight(
                                .semibold
                            )
                        }

                        Spacer()
                    }
                }
                .disabled(
                    isSaving ||
                    cleanGroupName.isEmpty
                )
            }

            // MARK: - Error

            if let saveError {

                Section {

                    Label(
                        saveError,
                        systemImage:
                            "exclamationmark.triangle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(
            groupSettingsTitle
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
    }

    // MARK: - Goal Method Button

    @ViewBuilder
    private func goalMethodButton(
        method: GoalMethod,
        title: String,
        description: String
    ) -> some View {

        Button {

            selectedMethod = method

        } label: {

            HStack(
                alignment: .center,
                spacing: 12
            ) {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text(title)
                        .fontWeight(
                            .semibold
                        )

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )
                }

                Spacer()

                Image(
                    systemName:
                        selectedMethod == method
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .font(.title3)
            }
            .contentShape(
                Rectangle()
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Save

    @MainActor
    private func saveChanges() async {

        guard !cleanGroupName.isEmpty else {
            return
        }

        guard
            dataStore.currentUser?.role ==
                "admin"
        else {

            saveError =
                adminOnlyErrorText

            return
        }

        isSaving = true
        saveError = nil

        defer {
            isSaving = false
        }

        let payload =
            GroupSettingsUpdate(
                name: cleanGroupName,
                goalMethod:
                    selectedMethod.rawValue,
                reductionPercent:
                    selectedMethod == .manual
                    ? nil
                    : reductionPercent,
                journeyDays:
                    successDays
            )

        do {

            try await client
                .from("groups")
                .update(payload)
                .eq(
                    "id",
                    value:
                        group.id.uuidString
                )
                .execute()

            await dataStore
                .loadCurrentAccount()

            dismiss()

        } catch {

            saveError =
                saveFailedText(
                    error.localizedDescription
                )
        }
    }

    // MARK: - Helpers

    private var cleanGroupName: String {

        groupName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
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

    private var groupCodeText: String {

        switch localization.language {
        case .hebrew:
            return "קוד קבוצה"
        case .english:
            return "Group code"
        case .arabic:
            return "رمز المجموعة"
        }
    }

    private var goalMethodSectionTitle: String {

        switch localization.language {
        case .hebrew:
            return "שיטת קביעת היעדים"
        case .english:
            return "Target method"
        case .arabic:
            return "طريقة تحديد الأهداف"
        }
    }

    private var personalPercentageTitle: String {

        switch localization.language {
        case .hebrew:
            return "פחות מהיום הקודם"
        case .english:
            return "Less than the previous day"
        case .arabic:
            return "أقل من اليوم السابق"
        }
    }

    private var personalPercentageDescription: String {

        switch localization.language {
        case .hebrew:
            return "לכל משתמש יעד אישי המבוסס על זמן המסך שלו ביום הקודם."
        case .english:
            return "Each user gets an individual target based on their screen time from the previous day."
        case .arabic:
            return "يحصل كل مستخدم على هدف شخصي بناءً على وقت الشاشة في اليوم السابق."
        }
    }

    private var groupAverageTitle: String {

        switch localization.language {
        case .hebrew:
            return "פחות מהממוצע הקבוצתי"
        case .english:
            return "Less than the group average"
        case .arabic:
            return "أقل من متوسط المجموعة"
        }
    }

    private var groupAverageDescription: String {

        switch localization.language {
        case .hebrew:
            return "כל חברי הקבוצה מקבלים יעד זהה המבוסס על ממוצע זמן המסך של הקבוצה."
        case .english:
            return "All group members receive the same target based on the group's average screen time."
        case .arabic:
            return "يحصل جميع أعضاء المجموعة على نفس الهدف بناءً على متوسط وقت الشاشة للمجموعة."
        }
    }

    private var manualTitle: String {

        switch localization.language {
        case .hebrew:
            return "יעד אישי לכל משתמש"
        case .english:
            return "Individual target for each user"
        case .arabic:
            return "هدف شخصي لكل مستخدم"
        }
    }

    private var manualDescription: String {

        switch localization.language {
        case .hebrew:
            return "המנהל קובע יעד נפרד לכל חבר בקבוצה."
        case .english:
            return "The admin sets a separate target for each group member."
        case .arabic:
            return "يحدد المدير هدفًا منفصلًا لكل عضو في المجموعة."
        }
    }

    private var targetSettingsTitle: String {

        switch localization.language {
        case .hebrew:
            return "הגדרות היעד"
        case .english:
            return "Target settings"
        case .arabic:
            return "إعدادات الهدف"
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

    private var learningJourneyTitle: String {

        switch localization.language {
        case .hebrew:
            return "יום למידה + \(successDays) ימי הצלחה"
        case .english:
            return "Learning day + \(successDays) success days"
        case .arabic:
            return "يوم تعلّم + \(successDays) أيام نجاح"
        }
    }

    private var learningJourneyDescription: String {

        switch localization.language {
        case .hebrew:
            return "יום הלמידה אינו נספר ברצף. לאחריו מתחיל האתגר עם היעד שנקבע לפי השיטה שנבחרה."
        case .english:
            return "The learning day does not count toward the streak. After it, the challenge begins with the target calculated using the selected method."
        case .arabic:
            return "يوم التعلّم لا يُحتسب ضمن السلسلة. بعده يبدأ التحدي بالهدف الذي يتم تحديده وفق الطريقة المختارة."
        }
    }

    private var individualTargetsTitle: String {

        switch localization.language {
        case .hebrew:
            return "יעדים אישיים"
        case .english:
            return "Individual targets"
        case .arabic:
            return "أهداف شخصية"
        }
    }

    private var individualTargetsLabel: String {

        switch localization.language {
        case .hebrew:
            return "היעדים מוגדרים לכל משתמש בנפרד"
        case .english:
            return "Targets are set separately for each user"
        case .arabic:
            return "يتم تحديد الأهداف لكل مستخدم بشكل منفصل"
        }
    }

    private var individualTargetsDescription: String {

        switch localization.language {
        case .hebrew:
            return "לאחר השמירה ניתן להיכנס לכל חבר בקבוצה ולקבוע עבורו יעד אישי."
        case .english:
            return "After saving, you can open each group member and set an individual target for them."
        case .arabic:
            return "بعد الحفظ، يمكنك الدخول إلى كل عضو في المجموعة وتحديد هدف شخصي له."
        }
    }

    private var historyPreservedText: String {

        switch localization.language {
        case .hebrew:
            return "שינויים בשיטת היעד אינם משנים את היסטוריית הימים שכבר נרשמה."
        case .english:
            return "Changing the target method does not alter previously recorded history."
        case .arabic:
            return "تغيير طريقة الهدف لا يغيّر سجل الأيام التي تم تسجيلها مسبقًا."
        }
    }

    private var nextTargetChangeText: String {

        switch localization.language {
        case .hebrew:
            return "היום הנוכחי ממשיך לפי היעד שכבר נקבע לו. השיטה החדשה תשמש לקביעת היעד הבא."
        case .english:
            return "The current day continues with its existing target. The new method will be used to calculate the next target."
        case .arabic:
            return "يستمر اليوم الحالي وفق الهدف المحدد له بالفعل. سيتم استخدام الطريقة الجديدة لتحديد الهدف التالي."
        }
    }

    private var savingText: String {

        switch localization.language {
        case .hebrew:
            return "שומר..."
        case .english:
            return "Saving..."
        case .arabic:
            return "جارٍ الحفظ..."
        }
    }

    private var saveChangesText: String {

        switch localization.language {
        case .hebrew:
            return "שמור שינויים"
        case .english:
            return "Save changes"
        case .arabic:
            return "حفظ التغييرات"
        }
    }

    private var groupSettingsTitle: String {

        switch localization.language {
        case .hebrew:
            return "הגדרות קבוצה"
        case .english:
            return "Group settings"
        case .arabic:
            return "إعدادات المجموعة"
        }
    }

    private var adminOnlyErrorText: String {

        switch localization.language {
        case .hebrew:
            return "רק מנהל יכול לשנות את הגדרות הקבוצה."
        case .english:
            return "Only an admin can change group settings."
        case .arabic:
            return "يمكن للمدير فقط تغيير إعدادات المجموعة."
        }
    }

    private func saveFailedText(
        _ error: String
    ) -> String {

        switch localization.language {
        case .hebrew:
            return "שמירת ההגדרות נכשלה: \(error)"
        case .english:
            return "Failed to save settings: \(error)"
        case .arabic:
            return "فشل حفظ الإعدادات: \(error)"
        }
    }

    // MARK: - Payload

    private struct GroupSettingsUpdate:
        Encodable {

        let name: String
        let goalMethod: String
        let reductionPercent: Int?
        let journeyDays: Int

        enum CodingKeys:
            String,
            CodingKey {

            case name

            case goalMethod =
                "goal_method"

            case reductionPercent =
                "reduction_percent"

            case journeyDays =
                "journey_days"
        }
    }
}