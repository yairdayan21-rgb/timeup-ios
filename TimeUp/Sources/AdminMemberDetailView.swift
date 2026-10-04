import SwiftUI

struct AdminMemberDetailView: View {

    let group: SupabaseDataStore.TimeUpRemoteGroup
    let member: SupabaseDataStore.TimeUpRemoteUser

    @StateObject private var dataStore = SupabaseDataStore.shared

    @State private var isLoading = false
    @State private var manualHours = 0
    @State private var manualMinutes = 0
    @State private var didLoadManualTarget = false
    @State private var saveMessage: String?

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 20) {

                // MARK: - Member Header

                VStack(spacing: 12) {

                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.secondary)

                    Text(member.displayName ?? "משתמש")
                        .font(.title2.bold())

                    Text(
                        member.role == "admin"
                        ? "מנהל"
                        : "חבר קבוצה"
                    )
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)

                // MARK: - Today's Status

                VStack(alignment: .leading, spacing: 16) {

                    HStack {

                        Text("היום")
                            .font(.headline)

                        Spacer()

                        if isLoading {
                            ProgressView()
                        }
                    }

                    if let result = todayResult {

                        HStack(spacing: 12) {

                            statusCard(
                                title: "זמן מסך",
                                value: formatMinutes(
                                    result.usageMinutes
                                ),
                                icon: "iphone"
                            )

                            statusCard(
                                title: "יעד",
                                value: targetText(result),
                                icon: "target"
                            )
                        }

                        Divider()

                        if result.isLearningDay {

                            Label(
                                "יום למידה",
                                systemImage: "brain.head.profile"
                            )
                            .font(.headline)

                            Text(
                                "היום משמש למדידת זמן המסך לצורך קביעת היעד הראשון. יום זה אינו נספר ברצף."
                            )
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        } else {

                            HStack {

                                Image(
                                    systemName:
                                        result.achieved == true
                                        ? "checkmark.circle.fill"
                                        : "xmark.circle.fill"
                                )
                                .font(.title2)

                                VStack(
                                    alignment: .leading,
                                    spacing: 2
                                ) {

                                    Text(
                                        result.achieved == true
                                        ? "עמד ביעד"
                                        : "לא עמד ביעד"
                                    )
                                    .fontWeight(.semibold)

                                    if let target =
                                        result.targetMinutes {

                                        Text(
                                            statusDescription(
                                                usage: result.usageMinutes,
                                                target: target
                                            )
                                        )
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()
                            }
                        }

                    } else if let target = todayTarget {

                        HStack(spacing: 12) {

                            statusCard(
                                title: "זמן מסך",
                                value: "טרם התקבל",
                                icon: "iphone"
                            )

                            statusCard(
                                title: "יעד",
                                value: formatMinutes(
                                    target.targetMinutes
                                ),
                                icon: "target"
                            )
                        }

                        Divider()

                        Label(
                            "ממתין לנתוני זמן מסך",
                            systemImage: "clock.arrow.circlepath"
                        )
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    } else {

                        ContentUnavailableView(
                            "אין נתונים להיום",
                            systemImage: "iphone.slash",
                            description: Text(
                                "עדיין לא התקבלו נתוני זמן מסך או יעד עבור המשתמש."
                            )
                        )
                    }
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(
                    RoundedRectangle(cornerRadius: 18)
                )

                // MARK: - Manual Target Editor

                if group.goalMethod == "manual" {

                    VStack(
                        alignment: .leading,
                        spacing: 16
                    ) {

                        Label(
                            "יעד אישי",
                            systemImage:
                                "person.crop.circle.badge.checkmark"
                        )
                        .font(.headline)

                        if let currentTargetMinutes {

                            Text(
                                "היעד הנוכחי: \(formatMinutes(currentTargetMinutes))"
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        } else {

                            Text("עדיין לא הוגדר יעד למשתמש.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        Text("הגדרת יעד")
                            .fontWeight(.semibold)

                        HStack(spacing: 16) {

                            VStack(spacing: 6) {

                                Text("שעות")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Stepper(
                                    value: $manualHours,
                                    in: 0...23
                                ) {
                                    Text("\(manualHours)")
                                        .font(.title3.bold())
                                        .monospacedDigit()
                                }
                            }

                            Divider()
                                .frame(height: 45)

                            VStack(spacing: 6) {

                                Text("דקות")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Stepper(
                                    value: $manualMinutes,
                                    in: 0...59
                                ) {
                                    Text("\(manualMinutes)")
                                        .font(.title3.bold())
                                        .monospacedDigit()
                                }
                            }
                        }

                        Text(
                            "יעד חדש: \(formatMinutes(manualTargetTotalMinutes))"
                        )
                        .font(.callout)
                        .foregroundStyle(.secondary)

                        Button {

                            Task {
                                await saveManualTarget()
                            }

                        } label: {

                            HStack {

                                Spacer()

                                if dataStore.isSavingManualTarget {

                                    ProgressView()
                                        .padding(.trailing, 4)

                                    Text("שומר...")

                                } else {

                                    Image(
                                        systemName: "checkmark.circle.fill"
                                    )

                                    Text("שמירת יעד")
                                        .fontWeight(.semibold)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(
                            manualTargetTotalMinutes <= 0 ||
                            dataStore.isSavingManualTarget
                        )

                        if let saveMessage {

                            Text(saveMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .center
                                )
                        }
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 18)
                    )
                }

                // MARK: - History

                VStack(
                    alignment: .leading,
                    spacing: 14
                ) {

                    HStack {

                        Text("היסטוריה")
                            .font(.title3.bold())

                        Spacer()

                        Text(
                            "\(memberResults.count) ימים"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    if memberResults.isEmpty {

                        ContentUnavailableView(
                            "אין היסטוריה עדיין",
                            systemImage: "calendar",
                            description: Text(
                                "לאחר שיתקבלו נתוני זמן מסך, הימים יופיעו כאן."
                            )
                        )
                        .frame(maxWidth: .infinity)

                    } else {

                        ForEach(memberResults) { result in

                            historyRow(result)

                            if result.id != memberResults.last?.id {
                                Divider()
                            }
                        }
                    }
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(
                    RoundedRectangle(cornerRadius: 18)
                )

                // MARK: - Group

                VStack(alignment: .leading, spacing: 12) {

                    Text("קבוצה")
                        .font(.headline)

                    HStack {

                        Text(group.name)

                        Spacer()

                        Text(group.code)
                            .font(
                                .system(
                                    .body,
                                    design: .monospaced
                                )
                            )
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    HStack {

                        Label(
                            goalDescription,
                            systemImage: "target"
                        )

                        Spacer()

                        Label(
                            "\(group.currentStreak)",
                            systemImage: "flame.fill"
                        )
                        .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(
                    RoundedRectangle(cornerRadius: 18)
                )

                // MARK: - Error

                if let error = dataStore.lastError {

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        Label(
                            "לא ניתן להשלים את הפעולה",
                            systemImage:
                                "exclamationmark.triangle"
                        )
                        .fontWeight(.semibold)

                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button("נסה שוב") {

                            Task {
                                await loadData()
                            }
                        }
                    }
                    .padding()
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .background(.thinMaterial)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 18)
                    )
                }
            }
            .padding(20)
        }
        .navigationTitle(
            member.displayName ?? "משתמש"
        )
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await loadData()
        }
        .task {
            await loadData()
        }
    }

    // MARK: - Data

    private var memberResults:
        [SupabaseDataStore.TimeUpRemoteDailyResult] {

        dataStore.dailyResults
            .filter {
                $0.groupID == group.id &&
                $0.userID == member.id
            }
            .sorted {
                $0.resultDate > $1.resultDate
            }
    }

    private var todayResult:
        SupabaseDataStore.TimeUpRemoteDailyResult? {

        memberResults.first {
            $0.resultDate == todayDateKey
        }
    }

    private var todayTarget:
        SupabaseDataStore.TimeUpRemoteDailyTarget? {

        dataStore.dailyTargets.first {
            $0.groupID == group.id &&
            $0.userID == member.id &&
            $0.targetDate == todayDateKey
        }
    }

    private var currentTargetMinutes: Int? {

        if let target = todayTarget {
            return target.targetMinutes
        }

        return todayResult?.targetMinutes
    }

    private var manualTargetTotalMinutes: Int {
        (manualHours * 60) + manualMinutes
    }

    // MARK: - History Row

    private func historyRow(
        _ result: SupabaseDataStore.TimeUpRemoteDailyResult
    ) -> some View {

        HStack(spacing: 14) {

            ZStack {

                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)

                Image(
                    systemName:
                        result.isLearningDay
                        ? "brain.head.profile"
                        : result.achieved == true
                            ? "checkmark"
                            : result.achieved == false
                                ? "xmark"
                                : "clock"
                )
                .fontWeight(.semibold)
            }

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                HStack {

                    Text(
                        displayDate(
                            result.resultDate
                        )
                    )
                    .fontWeight(.semibold)

                    if result.isLearningDay {

                        Text("יום למידה")
                            .font(.caption2)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(.thinMaterial)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 12) {

                    Label(
                        formatMinutes(
                            result.usageMinutes
                        ),
                        systemImage: "iphone"
                    )

                    if let target =
                        result.targetMinutes {

                        Label(
                            formatMinutes(target),
                            systemImage: "target"
                        )
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if !result.isLearningDay {

                Text(
                    result.achieved == true
                    ? "הצלחה"
                    : result.achieved == false
                        ? "חריגה"
                        : "ממתין"
                )
                .font(.caption.bold())
            }
        }
        .padding(.vertical, 5)
    }

    // MARK: - Manual Target

    @MainActor
    private func saveManualTarget() async {

        guard manualTargetTotalMinutes > 0 else {
            return
        }

        saveMessage = nil

        do {

            try await dataStore.setManualTarget(
                group: group,
                userID: member.id,
                targetMinutes:
                    manualTargetTotalMinutes
            )

            saveMessage = "היעד נשמר בהצלחה"

            loadManualTargetIntoEditor(
                force: true
            )

        } catch {

            saveMessage =
                "שמירת היעד נכשלה: \(error.localizedDescription)"
        }
    }

    private func loadManualTargetIntoEditor(
        force: Bool = false
    ) {

        guard
            force || !didLoadManualTarget
        else {
            return
        }

        guard
            let targetMinutes =
                currentTargetMinutes
        else {

            didLoadManualTarget = true
            return
        }

        manualHours =
            targetMinutes / 60

        manualMinutes =
            targetMinutes % 60

        didLoadManualTarget = true
    }

    // MARK: - Status Card

    private func statusCard(
        title: String,
        value: String,
        icon: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Label(
                title,
                systemImage: icon
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.bold())
        }
        .padding()
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(.ultraThinMaterial)
        .clipShape(
            RoundedRectangle(cornerRadius: 14)
        )
    }

    // MARK: - Load

    @MainActor
    private func loadData() async {

        isLoading = true

        await dataStore.loadDailyProgress(
            groupID: group.id
        )

        loadManualTargetIntoEditor()

        isLoading = false
    }

    // MARK: - Date

    private var todayDateKey: String {

        let formatter = DateFormatter()

        formatter.calendar =
            Calendar(identifier: .gregorian)

        formatter.locale =
            Locale(identifier: "en_US_POSIX")

        formatter.timeZone =
            TimeZone(identifier: group.timezone) ??
            TimeZone(identifier: "Asia/Jerusalem") ??
            .current

        formatter.dateFormat = "yyyy-MM-dd"

        return formatter.string(from: Date())
    }

    private func displayDate(
        _ dateString: String
    ) -> String {

        let input = DateFormatter()
        input.calendar =
            Calendar(identifier: .gregorian)
        input.locale =
            Locale(identifier: "en_US_POSIX")
        input.timeZone =
            TimeZone(identifier: group.timezone) ??
            .current
        input.dateFormat = "yyyy-MM-dd"

        guard
            let date = input.date(
                from: dateString
            )
        else {
            return dateString
        }

        let output = DateFormatter()
        output.locale =
            Locale(identifier: "he_IL")
        output.timeZone =
            TimeZone(identifier: group.timezone) ??
            .current
        output.dateFormat = "d MMM yyyy"

        return output.string(from: date)
    }

    // MARK: - Formatting

    private func formatMinutes(
        _ minutes: Int
    ) -> String {

        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours == 0 {
            return "\(remainingMinutes) דק׳"
        }

        if remainingMinutes == 0 {
            return "\(hours) שע׳"
        }

        return
            "\(hours) שע׳ \(remainingMinutes) דק׳"
    }

    private func targetText(
        _ result:
            SupabaseDataStore.TimeUpRemoteDailyResult
    ) -> String {

        guard let target =
                result.targetMinutes else {
            return "ללא יעד"
        }

        return formatMinutes(target)
    }

    private func statusDescription(
        usage: Int,
        target: Int
    ) -> String {

        let difference =
            abs(target - usage)

        if usage <= target {
            return
                "נותרו \(formatMinutes(difference)) עד היעד"
        }

        return
            "חריגה של \(formatMinutes(difference))"
    }

    // MARK: - Goal

    private var goalDescription: String {

        switch group.goalMethod {

        case "personal_percentage":
            return
                "\(group.reductionPercent ?? 0)% פחות מהיום הקודם"

        case "group_average_percentage":
            return
                "\(group.reductionPercent ?? 0)% פחות מהממוצע הקבוצתי"

        case "manual":
            return "יעד אישי"

        default:
            return "יעד קבוצה"
        }
    }
}