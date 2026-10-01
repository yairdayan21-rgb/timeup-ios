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
            guard let previousUsageMinutes else { return nil }
            return reducedTarget(
                from: previousUsageMinutes,
                by: group.reductionPercent ?? 0
            )

        case .adaptiveAverage:
            guard !historicalUsageMinutes.isEmpty else { return nil }
            let average = historicalUsageMinutes.reduce(0, +) / historicalUsageMinutes.count
            return reducedTarget(
                from: average,
                by: group.reductionPercent ?? 0
            )
        }
    }

    static func evaluate(
        usageMinutes: Int,
        targetMinutes: Int?,
        currentStreak: Int
    ) -> (achieved: Bool, streak: Int) {
        guard let targetMinutes else {
            return (false, 0)
        }

        let achieved = usageMinutes <= targetMinutes
        return (achieved, achieved ? currentStreak + 1 : 0)
    }

    private static func reducedTarget(from minutes: Int, by percent: Int) -> Int {
        let reduction = Double(max(0, min(percent, 100))) / 100.0
        return max(0, Int(floor(Double(minutes) * (1.0 - reduction))))
    }
}
