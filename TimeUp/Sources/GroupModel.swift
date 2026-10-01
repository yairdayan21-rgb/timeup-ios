import Foundation

struct TimeUpGroup: Identifiable, Codable {
    let id: UUID
    var name: String
    let code: String

    var goalMethod: GoalMethod
    var reductionPercent: Int?
    var successDays: Int?

    let createdAt: Date

    enum GoalMethod: String, Codable {
        case previousDay
        case adaptiveAverage
        case manual
    }

    init(
        id: UUID = UUID(),
        name: String,
        code: String,
        goalMethod: GoalMethod,
        reductionPercent: Int? = nil,
        successDays: Int? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.code = code
        self.goalMethod = goalMethod
        self.reductionPercent = reductionPercent
        self.successDays = successDays
        self.createdAt = createdAt
    }
}
