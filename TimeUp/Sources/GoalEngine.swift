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

        let achieved =
            usageMinutes <= targetMinutes

        return (
            achieved: achieved,
            streak: achieved
                ? currentStreak + 1
                : 0
        )
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

        if isLearningDay {

            return TimeUpDailyProgress(
                memberID: memberID,
                date: date,
                usageMinutes: max(0, usageMinutes),
                targetMinutes: targetMinutes,
                isLearningDay: true,
                achieved: false,
                streakAfterDay: currentStreak
            )
        }

        let result =
            evaluate(
                usageMinutes: max(0, usageMinutes),
                targetMinutes: targetMinutes,
                currentStreak: currentStreak
            )

        return TimeUpDailyProgress(
            memberID: memberID,
            date: date,
            usageMinutes: max(0, usageMinutes),
            targetMinutes: targetMinutes,
            isLearningDay: false,
            achieved: result.achieved,
            streakAfterDay: result.streak
        )
    }

    // MARK: - Group Result

    static func groupAchieved(
        memberIDs: [UUID],
        progress: [TimeUpDailyProgress],
        on date: Date,
        calendar: Calendar = .current
    ) -> Bool {

        guard !memberIDs.isEmpty else {
            return false
        }

        for memberID in memberIDs {

            guard
                let memberProgress =
                    progress.first(where: {
                        $0.memberID == memberID &&
                        calendar.isDate(
                            $0.date,
                            inSameDayAs: date
                        )
                    }),
                !memberProgress.isLearningDay,
                memberProgress.targetMinutes != nil,
                memberProgress.achieved
            else {
                return false
            }
        }

        return true
    }

    // MARK: - Personal Reduced Target

    static func personalReducedTarget(
        usageMinutes: Int,
        reductionPercent: Int
    ) -> Int {

        reducedTarget(
            from: usageMinutes,
            by: reductionPercent
        )
    }

    // MARK: - Group Average Target

    static func groupAverageTarget(
        usageMinutes: [Int],
        reductionPercent: Int
    ) -> Int? {

        guard
            let average =
                averageUsage(
                    from: usageMinutes
                )
        else {
            return nil
        }

        return reducedTarget(
            from: average,
            by: reductionPercent
        )
    }

    // MARK: - Next Target

    static func nextTarget(
        for group: TimeUpGroup,
        member: TimeUpMember,
        todayProgress: TimeUpDailyProgress,
        groupUsageMinutes: [Int],
        groupSucceeded: Bool
    ) -> Int? {

        switch group.goalMethod {

        // ידני:
        // המנהל קובע את היעד.
        // המערכת אינה משנה אותו.
        case .manual:

            return member.dailyTargetMinutes

        // אישי יורד:
        //
        // אם הקבוצה נכשלה,
        // היעד נשאר כפי שהיה היום.
        //
        // אם הקבוצה הצליחה,
        // היעד של המשתמש למחר הוא
        // זמן המסך שלו בפועל פחות X%.
        case .previousDay:

            guard groupSucceeded else {

                return todayProgress
                    .targetMinutes
            }

            return personalReducedTarget(
                usageMinutes:
                    todayProgress
                        .usageMinutes,
                reductionPercent:
                    group.reductionPercent ?? 0
            )

        // ממוצע קבוצתי יורד:
        //
        // אם הקבוצה נכשלה,
        // היעד נשאר כפי שהיה היום.
        //
        // אם הקבוצה הצליחה,
        // מחשבים את ממוצע זמן המסך
        // בפועל של כל חברי הקבוצה,
        // מפחיתים X%,
        // וזה היעד הזהה של כולם למחר.
        case .adaptiveAverage:

            guard groupSucceeded else {

                return todayProgress
                    .targetMinutes
            }

            return groupAverageTarget(
                usageMinutes:
                    groupUsageMinutes,
                reductionPercent:
                    group.reductionPercent ?? 0
            )
        }
    }

    // MARK: - Learning Day Target

    static func learningDayTarget(
        for group: TimeUpGroup,
        member: TimeUpMember,
        memberUsageMinutes: Int,
        groupUsageMinutes: [Int]
    ) -> Int? {

        switch group.goalMethod {

        case .manual:

            return member.dailyTargetMinutes

        case .previousDay:

            return personalReducedTarget(
                usageMinutes:
                    memberUsageMinutes,
                reductionPercent:
                    group.reductionPercent ?? 0
            )

        case .adaptiveAverage:

            return groupAverageTarget(
                usageMinutes:
                    groupUsageMinutes,
                reductionPercent:
                    group.reductionPercent ?? 0
            )
        }
    }

    // MARK: - Helpers

    private static func averageUsage(
        from usageMinutes: [Int]
    ) -> Int? {

        let validValues =
            usageMinutes.filter {
                $0 >= 0
            }

        guard !validValues.isEmpty else {
            return nil
        }

        let total =
            validValues.reduce(
                0,
                +
            )

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

        let safeMinutes =
            max(
                0,
                minutes
            )

        let safePercent =
            max(
                0,
                min(
                    percent,
                    100
                )
            )

        let multiplier =
            1.0 -
            (
                Double(safePercent) /
                100.0
            )

        return max(
            0,
            Int(
                floor(
                    Double(safeMinutes) *
                    multiplier
                )
            )
        )
    }
}
