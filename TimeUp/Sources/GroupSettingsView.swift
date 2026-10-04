import SwiftUI
import Supabase

struct GroupSettingsView: View {

    let group: SupabaseDataStore.TimeUpRemoteGroup

    @Environment(\.dismiss) private var dismiss

    @StateObject private var dataStore =
        SupabaseDataStore.shared

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

            Section("פרטי הקבוצה") {

                TextField(
                    "שם הקבוצה",
                    text: $groupName
                )

                LabeledContent(
                    "קוד קבוצה"
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
                "שיטת קביעת היעדים"
            ) {

                goalMethodButton(
                    method:
                        .personalPercentage,
                    title:
                        "פחות מהיום הקודם",
                    description:
                        "לכל משתמש יעד אישי המבוסס על זמן המסך שלו ביום הקודם."
                )

                goalMethodButton(
                    method:
                        .groupAveragePercentage,
                    title:
                        "פחות מהממוצע הקבוצתי",
                    description:
                        "כל חברי הקבוצה מקבלים יעד זהה המבוסס על ממוצע זמן המסך של הקבוצה."
                )

                goalMethodButton(
                    method:
                        .manual,
                    title:
                        "יעד אישי לכל משתמש",
                    description:
                        "המנהל קובע יעד נפרד לכל חבר בקבוצה."
                )
            }

            // MARK: - Percentage Settings

            if selectedMethod != .manual {

                Section(
                    "הגדרות היעד"
                ) {

                    Stepper(
                        "הפחתה: \(reductionPercent)%",
                        value:
                            $reductionPercent,
                        in: 1...50
                    )

                    Stepper(
                        "\(successDays) ימי הצלחה",
                        value:
                            $successDays,
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
                            "יום הלמידה אינו נספר ברצף. לאחריו מתחיל האתגר עם היעד שנקבע לפי השיטה שנבחרה."
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
                    "יעדים אישיים"
                ) {

                    Label(
                        "היעדים מוגדרים לכל משתמש בנפרד",
                        systemImage:
                            "person.crop.circle.badge.checkmark"
                    )

                    Text(
                        "לאחר השמירה ניתן להיכנס לכל חבר בקבוצה ולקבוע עבורו יעד אישי."
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
                    "שינויים בשיטת היעד אינם משנים את היסטוריית הימים שכבר נרשמה.",
                    systemImage:
                        "clock.arrow.circlepath"
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )

                Text(
                    "היום הנוכחי ממשיך לפי היעד שכבר נקבע לו. השיטה החדשה תשמש לקביעת היעד הבא."
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

                            Text("שומר...")

                        } else {

                            Image(
                                systemName:
                                    "checkmark.circle.fill"
                            )

                            Text(
                                "שמור שינויים"
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
            "הגדרות קבוצה"
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
                "רק מנהל יכול לשנות את הגדרות הקבוצה."

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
                "שמירת ההגדרות נכשלה: \(error.localizedDescription)"
        }
    }

    // MARK: - Helpers

    private var cleanGroupName: String {

        groupName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
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