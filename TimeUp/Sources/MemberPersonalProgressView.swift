import SwiftUI
import Foundation

struct MemberPersonalProgressView: View {

    let groupID: UUID

    @ObservedObject private var dataStore =
        SupabaseDataStore.shared

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    private var progress: SupabaseDataStore.TimeUpRemoteProgress? {
        guard
            let progress = dataStore.personalProgress,
            progress.groupID == groupID,
            progress.userID == dataStore.currentUser?.id,
            dataStore.activeMemberGroup?.id == groupID
        else {
            return nil
        }

        return progress
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let progress {
                cumulativeCard(progress)
                weeklyCard(progress)

                Text(
                    localized(
                        "ההשוואות מבוססות על שימוש בפועל בימים שהקבוצה סגרה. היום הנוכחי וימים שממתינים לנתונים אינם נכללים בממוצע.",
                        "Comparisons use actual usage from days finalized by your group. Today and days waiting for data are excluded from the average.",
                        "تعتمد المقارنات على الاستخدام الفعلي في الأيام التي أغلقتها المجموعة. ولا يشمل المتوسط اليوم الحالي أو الأيام التي تنتظر بيانات."
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            } else {
                unavailableCard
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .timeUpLocalization()
    }

    // MARK: - Since Learning Day

    private func cumulativeCard(
        _ progress: SupabaseDataStore.TimeUpRemoteProgress
    ) -> some View {
        let summary = progress.cumulative

        return VStack(alignment: .leading, spacing: 18) {
            Label(
                localized(
                    "ההתקדמות שלי",
                    "My progress",
                    "تقدمي"
                ),
                systemImage: "chart.line.uptrend.xyaxis"
            )
            .font(.headline)

            Text(
                localized(
                    "בהשוואה ליום הלמידה",
                    "Compared with your learning day",
                    "مقارنة بيوم التعلم"
                )
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if progress.baseline.confirmed {
                comparisonHeadline(summary.reductionPercent)

                if let baselineMinutes = progress.baseline.usageMinutes {
                    metricRow(
                        title: localized(
                            "השימוש ביום הלמידה",
                            "Learning-day usage",
                            "الاستخدام في يوم التعلم"
                        ),
                        value: duration(Int64(baselineMinutes)),
                        icon: "book"
                    )
                }

                if let baselineDate = progress.baseline.date {
                    Text(
                        localized(
                            "יום הלמידה: \(formattedDate(baselineDate, timezone: progress.timezone))",
                            "Learning day: \(formattedDate(baselineDate, timezone: progress.timezone))",
                            "يوم التعلم: \(formattedDate(baselineDate, timezone: progress.timezone))"
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Divider()

                metricRow(
                    title: localized(
                        "הממוצע היומי מאז",
                        "Daily average since then",
                        "المتوسط اليومي منذ ذلك الحين"
                    ),
                    value: averageDuration(summary.averageUsageMinutes),
                    icon: "iphone"
                )

                Text(measuredDaysText(summary.measuredDays))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if summary.measuredDays > 0 {
                    metricRow(
                        title: localized(
                            "ימים שבהם עמדתי ביעד",
                            "Days I met my target",
                            "الأيام التي حققت فيها هدفي"
                        ),
                        value: "\(summary.achievedDays) / \(summary.measuredDays)",
                        icon: "checkmark.circle"
                    )
                }

                if let count = summary.alternativeCount {
                    metricRow(
                        title: localized(
                            "פעילויות שביצעתי מיום הלמידה",
                            "Activities completed since learning day",
                            "الأنشطة التي أكملتها منذ يوم التعلم"
                        ),
                        value: "\(count)",
                        icon: "figure.walk"
                    )
                }

                if let difference = summary.usageDifferenceMinutes,
                   summary.measuredDays > 0 {

                    Divider()

                    usageDifference(
                        difference,
                        measuredDays: summary.measuredDays
                    )
                }

                if summary.measuredDays == 0 {
                    explanatoryText(
                        localized(
                            "יום הלמידה כבר נמדד. ההתקדמות תופיע לאחר שייסגר יום נוסף עם נתוני שימוש.",
                            "Your learning day has been measured. Progress will appear once another day with usage data is finalized.",
                            "تم قياس يوم التعلم. سيظهر التقدم بعد إغلاق يوم إضافي تتوفر فيه بيانات الاستخدام."
                        )
                    )
                } else if progress.baseline.usageMinutes == 0 {
                    explanatoryText(
                        localized(
                            "השימוש ביום הלמידה היה אפס דקות, ולכן אי אפשר לחשב אחוז שינוי ביחס אליו.",
                            "Learning-day usage was zero minutes, so a percentage change against it cannot be calculated.",
                            "كان الاستخدام في يوم التعلم صفر دقيقة، لذلك لا يمكن حساب نسبة التغير مقارنة به."
                        )
                    )
                }

                groupDetails(
                    closedDays: summary.groupClosedDays,
                    successfulDays: summary.groupSuccessfulDays,
                    activities: summary.groupAlternativeCount,
                    includesLearningDayActivities: true
                )

            } else {
                explanatoryText(
                    localized(
                        "ההתקדמות מתחילה ביום הלמידה. לאחר שיושלם ונקבע היעד הראשון, נוכל להשוות אליו את השימוש שלך בימים הבאים.",
                        "Progress starts with your learning day. Once it is completed and your first target is set, we can compare your usage on subsequent days with it.",
                        "يبدأ التقدم بيوم التعلم. بعد اكتماله وتحديد هدفك الأول، يمكن مقارنة استخدامك في الأيام التالية به."
                    )
                )
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: 20)
        )
    }

    // MARK: - Last Seven Completed Days

    private func weeklyCard(
        _ progress: SupabaseDataStore.TimeUpRemoteProgress
    ) -> some View {
        let summary = progress.weekly

        return VStack(alignment: .leading, spacing: 18) {
            Label(
                localized(
                    "שבעת הימים האחרונים",
                    "The last seven days",
                    "الأيام السبعة الأخيرة"
                ),
                systemImage: "calendar"
            )
            .font(.headline)

            Text(
                "\(formattedDate(summary.periodStart, timezone: progress.timezone)) – \(formattedDate(summary.periodEnd, timezone: progress.timezone))"
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            if let percent = summary.reductionPercent {
                comparisonHeadline(percent)

                Text(
                    localized(
                        "בהשוואה לשימוש ביום הלמידה",
                        "Compared with learning-day usage",
                        "مقارنة بالاستخدام في يوم التعلم"
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            metricRow(
                title: localized(
                    "ממוצע זמן מסך יומי",
                    "Average daily screen time",
                    "متوسط وقت الشاشة اليومي"
                ),
                value: averageDuration(summary.averageUsageMinutes),
                icon: "iphone"
            )

            Text(measuredDaysText(summary.measuredDays))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if summary.measuredDays > 0 {
                metricRow(
                    title: localized(
                        "ימים שבהם עמדתי ביעד",
                        "Days I met my target",
                        "الأيام التي حققت فيها هدفي"
                    ),
                    value: "\(summary.achievedDays) / \(summary.measuredDays)",
                    icon: "checkmark.circle"
                )
            }

            metricRow(
                title: localized(
                    "פעילויות שביצעתי",
                    "Activities I completed",
                    "الأنشطة التي أكملتها"
                ),
                value: "\(summary.alternativeCount)",
                icon: "figure.walk"
            )

            if summary.comparisonDays > 0,
               summary.comparisonDays != summary.measuredDays {

                explanatoryText(
                    localized(
                        "אחוז השינוי מבוסס על \(summary.comparisonDays) ימים בתקופה זו שנמדדו אחרי יום הלמידה.",
                        "The percentage change uses \(summary.comparisonDays) days in this period measured after your learning day.",
                        "تعتمد نسبة التغير على \(summary.comparisonDays) أيام في هذه الفترة تم قياسها بعد يوم التعلم."
                    )
                )
            }

            if summary.measuredDays == 0 {
                explanatoryText(
                    localized(
                        "עדיין אין בתקופה הזו ימים סגורים עם נתוני שימוש אישיים. פעילויות שבוצעו כן מוצגות.",
                        "This period does not yet contain finalized days with your usage data. Completed activities are still shown.",
                        "لا توجد بعد في هذه الفترة أيام مغلقة تتوفر فيها بيانات استخدامك الشخصي. وتظهر الأنشطة المكتملة."
                    )
                )
            }

            groupDetails(
                closedDays: summary.groupClosedDays,
                successfulDays: summary.groupSuccessfulDays,
                activities: summary.groupAlternativeCount,
                includesLearningDayActivities: false
            )
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.secondary.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }

    // MARK: - Comparison

    private func comparisonHeadline(
        _ percent: Double?
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let percent {
                Text(percentageText(percent))
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(comparisonColor(percent))
                    .monospacedDigit()
                    .fixedSize(horizontal: false, vertical: true)

                Text(
                    localized(
                        "זמן מסך בממוצע ליום",
                        "Screen time on an average day",
                        "وقت الشاشة في متوسط اليوم"
                    )
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

            } else {
                Text(
                    localized(
                        "עדיין אין אחוז שינוי לחישוב",
                        "A percentage change is not available yet",
                        "لا تتوفر بعد نسبة تغير قابلة للحساب"
                    )
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func usageDifference(
        _ difference: Int64,
        measuredDays: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(
                localized(
                    "ההפרש המצטבר בזמן המסך",
                    "Cumulative screen-time difference",
                    "الفرق التراكمي في وقت الشاشة"
                )
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Text(differenceText(difference))
                .font(.title3.bold())
                .monospacedDigit()
                .fixedSize(horizontal: false, vertical: true)

            Text(
                localized(
                    "השוואת סך השימוש ב־\(measuredDays) הימים שנמדדו לכמות שהיית משתמש בה אילו בכל אחד מהם השימוש היה כמו ביום הלמידה.",
                    "Your total usage across \(measuredDays) measured days compared with using the same amount as your learning day on each of those days.",
                    "مقارنة إجمالي استخدامك خلال \(measuredDays) أيام مقاسة بالكمية التي كنت ستستخدمها لو كان استخدامك في كل يوم منها مساويًا لاستخدام يوم التعلم."
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Group Metrics

    private func groupDetails(
        closedDays: Int,
        successfulDays: Int,
        activities: Int?,
        includesLearningDayActivities: Bool
    ) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 14) {
                metricRow(
                    title: localized(
                        "ימי הצלחה של הקבוצה",
                        "Successful group days",
                        "أيام نجاح المجموعة"
                    ),
                    value: closedDays > 0
                        ? "\(successfulDays) / \(closedDays)"
                        : "—",
                    icon: "person.3"
                )

                Text(
                    localized(
                        "מתוך הימים שנסגרו בתקופה הזו. זה מספר ימי ההצלחה, ולא הרצף הנוכחי.",
                        "Out of finalized days in this period. This is the number of successful days, rather than the current streak.",
                        "من الأيام المغلقة في هذه الفترة. هذا عدد أيام النجاح، وليس سلسلة النجاح الحالية."
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

                if let activities {
                    metricRow(
                        title: localized(
                            "פעילויות שהקבוצה ביצעה",
                            "Activities completed by the group",
                            "الأنشطة التي أكملتها المجموعة"
                        ),
                        value: "\(activities)",
                        icon: "figure.walk"
                    )
                }

                if includesLearningDayActivities {
                    Text(
                        localized(
                            "ספירת הפעילויות כוללת גם את יום הלמידה.",
                            "Activity counts include the learning day.",
                            "يشمل عدد الأنشطة يوم التعلم أيضًا."
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 12)

        } label: {
            Text(
                localized(
                    "ההתקדמות הקבוצתית",
                    "Group progress",
                    "تقدم المجموعة"
                )
            )
            .font(.subheadline.weight(.semibold))
        }
    }

    // MARK: - Loading and Missing Data

    private var unavailableCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(
                localized(
                    "ההתקדמות שלי",
                    "My progress",
                    "تقدمي"
                ),
                systemImage: "chart.line.uptrend.xyaxis"
            )
            .font(.headline)

            if dataStore.isLoadingPersonalProgress {
                HStack(spacing: 12) {
                    ProgressView()

                    Text(
                        localized(
                            "טוען את נתוני ההתקדמות…",
                            "Loading your progress…",
                            "جارٍ تحميل بيانات تقدمك…"
                        )
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

            } else if dataStore.personalProgressError != nil {
                explanatoryText(
                    localized(
                        "לא ניתן לטעון את ההתקדמות כרגע.",
                        "Your progress could not be loaded right now.",
                        "تعذر تحميل تقدمك حاليًا."
                    )
                )

                Button {
                    Task {
                        await dataStore.loadPersonalProgress(
                            groupID: groupID
                        )
                    }
                } label: {
                    Text(
                        localized(
                            "נסה שוב",
                            "Try again",
                            "حاول مجددًا"
                        )
                    )
                }
                .buttonStyle(.bordered)

            } else {
                explanatoryText(
                    localized(
                        "ההתקדמות תופיע כאן לאחר טעינת נתוני הקבוצה.",
                        "Your progress will appear here once the group data is loaded.",
                        "سيظهر تقدمك هنا بعد تحميل بيانات المجموعة."
                    )
                )
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: 20)
        )
    }

    // MARK: - Shared UI

    private func metricRow(
        title: String,
        value: String,
        icon: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private func explanatoryText(
        _ text: String
    ) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Formatting

    private func measuredDaysText(
        _ count: Int
    ) -> String {
        localized(
            "מבוסס על \(count) ימים סגורים עם נתוני שימוש אישיים.",
            "Based on \(count) finalized days with your usage data.",
            "يستند إلى \(count) أيام مغلقة تتوفر فيها بيانات استخدامك الشخصي."
        )
    }

    private func percentageText(
        _ percent: Double
    ) -> String {
        let value = formattedNumber(abs(percent))

        if percent > 0 {
            return localized(
                "\(value)% פחות",
                "\(value)% less",
                "أقل بنسبة \(value)%"
            )
        }

        if percent < 0 {
            return localized(
                "\(value)% יותר",
                "\(value)% more",
                "أكثر بنسبة \(value)%"
            )
        }

        return localized(
            "ללא שינוי בממוצע",
            "No change in the average",
            "لا تغير في المتوسط"
        )
    }

    private func comparisonColor(
        _ percent: Double
    ) -> Color {
        if percent > 0 {
            return .green
        }

        if percent < 0 {
            return .orange
        }

        return .primary
    }

    private func differenceText(
        _ difference: Int64
    ) -> String {
        if difference > 0 {
            let value = duration(difference)

            return localized(
                "\(value) פחות ביחס ליום הלמידה",
                "\(value) less relative to learning-day usage",
                "\(value) أقل مقارنة باستخدام يوم التعلم"
            )
        }

        if difference < 0 {
            let value = duration(-difference)

            return localized(
                "\(value) יותר ביחס ליום הלמידה",
                "\(value) more relative to learning-day usage",
                "\(value) أكثر مقارنة باستخدام يوم التعلم"
            )
        }

        return localized(
            "ללא הפרש מצטבר",
            "No cumulative difference",
            "لا يوجد فرق تراكمي"
        )
    }

    private func averageDuration(
        _ minutes: Double?
    ) -> String {
        guard let minutes, minutes.isFinite else {
            return "—"
        }

        return duration(Int64(minutes.rounded()))
    }

    private func duration(
        _ minutes: Int64
    ) -> String {
        let hours = minutes / 60
        let remainder = minutes % 60

        if hours == 0 {
            return localized(
                "\(remainder) דק׳",
                "\(remainder) min",
                "\(remainder) د"
            )
        }

        if remainder == 0 {
            return localized(
                "\(hours) שע׳",
                "\(hours) hr",
                "\(hours) س"
            )
        }

        return localized(
            "\(hours) שע׳ \(remainder) דק׳",
            "\(hours) hr \(remainder) min",
            "\(hours) س \(remainder) د"
        )
    }

    private func formattedNumber(
        _ value: Double
    ) -> String {
        let formatter = NumberFormatter()
        formatter.locale = displayLocale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1

        return formatter.string(
            from: NSNumber(value: value)
        ) ?? "\(value)"
    }

    private func formattedDate(
        _ dateString: String,
        timezone: String
    ) -> String {
        let groupTimezone =
            TimeZone(identifier: timezone)
            ?? TimeZone(secondsFromGMT: 0)!

        let parser = DateFormatter()
        parser.calendar = Calendar(identifier: .gregorian)
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = groupTimezone
        parser.dateFormat = "yyyy-MM-dd"
        parser.isLenient = false

        guard let date = parser.date(from: dateString) else {
            return dateString
        }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = displayLocale
        formatter.timeZone = groupTimezone
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        return formatter.string(from: date)
    }

    private var displayLocale: Locale {
        switch localization.language {
        case .hebrew:
            return Locale(identifier: "he_IL")

        case .english:
            return Locale(identifier: "en_US")

        case .arabic:
            return Locale(identifier: "ar")
        }
    }

    // MARK: - Localization

    private func localized(
        _ hebrew: String,
        _ english: String,
        _ arabic: String
    ) -> String {
        switch localization.language {
        case .hebrew:
            return hebrew

        case .english:
            return english

        case .arabic:
            return arabic
        }
    }
}
