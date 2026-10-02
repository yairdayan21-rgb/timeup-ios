import Foundation

struct TimeUpDailyProgress: Identifiable, Codable {
    let id: UUID
    let memberID: UUID
    let date: Date
    let usageMinutes: Int
    let targetMinutes: Int?
    let isLearningDay: Bool
    let achieved: Bool
    let streakAfterDay: Int

    init(
        id: UUID = UUID(),
        memberID: UUID,
        date: Date,
        usageMinutes: Int,
        targetMinutes: Int?,
        isLearningDay: Bool,
        achieved: Bool,
        streakAfterDay: Int
    ) {
        self.id = id
        self.memberID = memberID
        self.date = date
        self.usageMinutes = usageMinutes
        self.targetMinutes = targetMinutes
        self.isLearningDay = isLearningDay
        self.achieved = achieved
        self.streakAfterDay = streakAfterDay
    }
}

enum TimeUpGoalEngine {

    // MARK: - Current Target

    static func targetMinutes(
        for group: TimeUpGroup,
        memberTargetMinutes: Int?,
        previousUsageMinutes: Int?,
        historicalUsageMinutes: [Int]
    ) -> Int? {

        switch group.goalMethod {

        case .manual:
            return memberTargetMinutes

        case .previousDay:
            guard let previousUsageMinutes else {
                return nil
            }

            return reducedTarget(
                from: previousUsageMinutes,
                by: group.reductionPercent ?? 0
            )

        case .adaptiveAverage:
            guard let average = averageUsage(
                from: historicalUsageMinutes
            ) else {
                return nil
            }

            return reducedTarget(
                from: average,
                by: group.reductionPercent ?? 0
            )
        }
    }

    // MARK: - Daily Result

    static func evaluate(
        usageMinutes: Int,
        targetMinutes: Int?,
        currentStreak: Int
    ) -> (
        achieved: Bool,
        streak: Int
    ) {

        guard let targetMinutes else {
            return (
                achieved: false,
                streak: 0
            )
        }

        let achieved = usageMinutes <= targetMinutes

        return (
            achieved: achieved,
            streak: achieved ? currentStreak + 1 : 0
        )
    }

    // MARK: - Tomorrow Target

    static func nextDayTargetMinutes(
        for group: TimeUpGroup,
        todayUsageMinutes: Int,
        todayTargetMinutes: Int?,
        todayAchieved: Bool,
        memberTargetMinutes: Int?,
        historicalUsageMinutes: [Int]
    ) -> Int? {

        switch group.goalMethod {

        // יעד ידני נשאר בדיוק כפי שהמנהל הגדיר אותו.
        case .manual:
            return memberTargetMinutes

        // אם המשתמש הצליח:
        // היעד הבא מחושב מהשימוש האמיתי של היום.
        //
        // אם המשתמש נכשל:
        // לא מעלים ולא מקלים את היעד.
        // מחר נשאר אותו יעד.
        case .previousDay:
            guard todayAchieved else {
                return todayTargetMinutes
            }

            return reducedTarget(
                from: todayUsageMinutes,
                by: group.reductionPercent ?? 0
            )

        // בשיטת הממוצע:
        // בכל יום מחשבים מחדש לפי ממוצע השימוש בפועל.
        //
        // היום הנוכחי מתווסף להיסטוריה אם הוא עדיין
        // לא נמצא ברשימה שהועברה לפונקציה.
        case .adaptiveAverage:
            var usageHistory = historicalUsageMinutes

            if usageHistory.last != todayUsageMinutes {
                usageHistory.append(todayUsageMinutes)
            }

            guard let average = averageUsage(
                from: usageHistory
            ) else {
                return todayTargetMinutes
            }

            return reducedTarget(
                from: average,
                by: group.reductionPercent ?? 0
            )
        }
    }

    // MARK: - Progress Creation

    static func makeDailyProgress(
        memberID: UUID,
        date: Date = Date(),
        usageMinutes: Int,
        targetMinutes: Int?,
        currentStreak: Int,
        isLearningDay: Bool
    ) -> TimeUpDailyProgress {

        // יום למידה אינו נחשב ככישלון.
        // הוא מיועד לאיסוף נתוני בסיס.
        if isLearningDay {
            return TimeUpDailyProgress(
                memberID: memberID,
                date: date,
                usageMinutes: usageMinutes,
                targetMinutes: targetMinutes,
                isLearningDay: true,
                achieved: false,
                streakAfterDay: currentStreak
            )
        }

        let result = evaluate(
            usageMinutes: usageMinutes,
            targetMinutes: targetMinutes,
            currentStreak: currentStreak
        )

        return TimeUpDailyProgress(
            memberID: memberID,
            date: date,
            usageMinutes: usageMinutes,
            targetMinutes: targetMinutes,
            isLearningDay: false,
            achieved: result.achieved,
            streakAfterDay: result.streak
        )
    }

    // MARK: - Helpers

    private static func averageUsage(
        from usageMinutes: [Int]
    ) -> Int? {

        guard !usageMinutes.isEmpty else {
            return nil
        }

        let validValues = usageMinutes.filter {
            $0 >= 0
        }

        guard !validValues.isEmpty else {
            return nil
        }

        let total = validValues.reduce(0, +)

        return Int(
            round(
                Double(total) /
                Double(validValues.count)
            )
        )
    }

    private static func reducedTarget(
        from minutes: Int,
        by percent: Int
    ) -> Int {

        let safeMinutes = max(0, minutes)

        let safePercent = max(
            0,
            min(percent, 100)
        )

        let reduction =
            Double(safePercent) / 100.0

        return max(
            0,
            Int(
                floor(
                    Double(safeMinutes) *
                    (1.0 - reduction)
                )
            )
        )
    }
}
