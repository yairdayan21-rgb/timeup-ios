import Foundation
import Supabase
import Combine

@MainActor
final class SupabaseDataStore: ObservableObject {

    static let shared = SupabaseDataStore()

    @Published private(set) var currentUser: TimeUpRemoteUser?
    @Published private(set) var memberships: [TimeUpRemoteMembership] = []
    @Published private(set) var groups: [TimeUpRemoteGroup] = []

    @Published private(set) var groupMemberships: [TimeUpRemoteMembership] = []
    @Published private(set) var groupMembers: [TimeUpRemoteUser] = []

    @Published private(set) var dailyTargets: [TimeUpRemoteDailyTarget] = []
    @Published private(set) var dailyResults: [TimeUpRemoteDailyResult] = []
    @Published private(set) var groupDailyResults: [TimeUpRemoteGroupDailyResult] = []

    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingGroupMembers = false
    @Published private(set) var isLoadingDailyProgress = false
    @Published private(set) var isSyncingScreenTime = false
    @Published private(set) var lastError: String?

    private let client = SupabaseManager.shared.client

    private let appGroupID =
        "group.com.timeup.shared"

    private let reportedUsageMinutesKey =
        "reportedUsageMinutes"

    private let reportedUsageUpdatedAtKey =
        "reportedUsageUpdatedAt"

    private init() {}

    // MARK: - Models

    public struct TimeUpRemoteUser: Identifiable, Decodable {

        public let id: UUID
        public let authUserID: UUID
        public let email: String?
        public let displayName: String?
        public let role: String

        enum CodingKeys: String, CodingKey {
            case id
            case authUserID = "auth_user_id"
            case email
            case displayName = "display_name"
            case role
        }
    }

    public struct TimeUpRemoteMembership: Identifiable, Decodable {

        public let id: UUID
        public let groupID: UUID
        public let userID: UUID
        public let membershipRole: String
        public let joinedAt: Date?

        enum CodingKeys: String, CodingKey {
            case id
            case groupID = "group_id"
            case userID = "user_id"
            case membershipRole = "membership_role"
            case joinedAt = "joined_at"
        }
    }

    public struct TimeUpRemoteGroup: Identifiable, Decodable {

        public let id: UUID
        public let name: String
        public let code: String
        public let goalMethod: String
        public let reductionPercent: Int?
        public let successDays: Int?
        public let currentStreak: Int
        public let timezone: String
        public let createdAt: Date?

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case code = "join_code"
            case goalMethod = "goal_method"
            case reductionPercent = "reduction_percent"
            case successDays = "journey_days"
            case currentStreak = "current_streak"
            case timezone
            case createdAt = "created_at"
        }
    }

    public struct TimeUpRemoteDailyTarget: Identifiable, Decodable {

        public let id: UUID
        public let groupID: UUID
        public let userID: UUID
        public let targetDate: String
        public let targetMinutes: Int
        public let goalMethod: String
        public let createdAt: Date?

        enum CodingKeys: String, CodingKey {
            case id
            case groupID = "group_id"
            case userID = "user_id"
            case targetDate = "target_date"
            case targetMinutes = "target_minutes"
            case goalMethod = "goal_method"
            case createdAt = "created_at"
        }
    }

    public struct TimeUpRemoteDailyResult: Identifiable, Decodable {

        public let id: UUID
        public let groupID: UUID
        public let userID: UUID
        public let resultDate: String
        public let usageMinutes: Int
        public let targetMinutes: Int?
        public let achieved: Bool?
        public let isLearningDay: Bool
        public let source: String?
        public let recordedAt: Date?
        public let updatedAt: Date?

        enum CodingKeys: String, CodingKey {
            case id
            case groupID = "group_id"
            case userID = "user_id"
            case resultDate = "result_date"
            case usageMinutes = "usage_minutes"
            case targetMinutes = "target_minutes"
            case achieved
            case isLearningDay = "is_learning_day"
            case source
            case recordedAt = "recorded_at"
            case updatedAt = "updated_at"
        }
    }

    public struct TimeUpRemoteGroupDailyResult: Identifiable, Decodable {

        public let id: UUID
        public let groupID: UUID
        public let resultDate: String
        public let succeeded: Bool
        public let memberCount: Int
        public let completedMemberCount: Int
        public let averageUsageMinutes: Int?
        public let streakAfterDay: Int

        enum CodingKeys: String, CodingKey {
            case id
            case groupID = "group_id"
            case resultDate = "result_date"
            case succeeded
            case memberCount = "member_count"
            case completedMemberCount = "completed_member_count"
            case averageUsageMinutes = "average_usage_minutes"
            case streakAfterDay = "streak_after_day"
        }
    }

    private struct DailyResultUpsert: Encodable {

        let groupID: UUID
        let userID: UUID
        let resultDate: String
        let usageMinutes: Int
        let targetMinutes: Int?
        let achieved: Bool?
        let isLearningDay: Bool
        let source: String
        let updatedAt: Date

        enum CodingKeys: String, CodingKey {
            case groupID = "group_id"
            case userID = "user_id"
            case resultDate = "result_date"
            case usageMinutes = "usage_minutes"
            case targetMinutes = "target_minutes"
            case achieved
            case isLearningDay = "is_learning_day"
            case source
            case updatedAt = "updated_at"
        }
    }

    // MARK: - Load Current Account

    func loadCurrentAccount() async {

        isLoading = true
        lastError = nil

        defer {
            isLoading = false
        }

        do {

            let session =
                try await client.auth.session

            let authUserID =
                session.user.id

            let users: [TimeUpRemoteUser] =
                try await client
                    .from("users")
                    .select(
                        """
                        id,
                        auth_user_id,
                        email,
                        display_name,
                        role
                        """
                    )
                    .eq(
                        "auth_user_id",
                        value: authUserID.uuidString
                    )
                    .limit(1)
                    .execute()
                    .value

            guard let user = users.first else {

                clearLoadedData()
                lastError = "TIMEUP_USER_NOT_FOUND"
                return
            }

            currentUser = user

            try await loadMemberships(
                for: user.id
            )

        } catch {

            clearLoadedData()

            lastError =
                error.localizedDescription
        }
    }

    // MARK: - Memberships

    private func loadMemberships(
        for userID: UUID
    ) async throws {

        let loadedMemberships:
            [TimeUpRemoteMembership] =
            try await client
                .from("group_memberships")
                .select(
                    """
                    id,
                    group_id,
                    user_id,
                    membership_role,
                    joined_at
                    """
                )
                .eq(
                    "user_id",
                    value: userID.uuidString
                )
                .execute()
                .value

        memberships =
            loadedMemberships

        let groupIDs =
            loadedMemberships.map {
                $0.groupID
            }

        try await loadGroups(
            ids: groupIDs
        )
    }

    // MARK: - Groups

    private func loadGroups(
        ids: [UUID]
    ) async throws {

        guard !ids.isEmpty else {
            groups = []
            return
        }

        var loadedGroups:
            [TimeUpRemoteGroup] = []

        for groupID in ids {

            let result:
                [TimeUpRemoteGroup] =
                try await client
                    .from("groups")
                    .select(
                        """
                        id,
                        name,
                        join_code,
                        goal_method,
                        reduction_percent,
                        journey_days,
                        current_streak,
                        timezone,
                        created_at
                        """
                    )
                    .eq(
                        "id",
                        value: groupID.uuidString
                    )
                    .limit(1)
                    .execute()
                    .value

            if let group = result.first {
                loadedGroups.append(group)
            }
        }

        groups =
            loadedGroups
    }

    // MARK: - Group Members

    func loadGroupMembers(
        groupID: UUID
    ) async {

        isLoadingGroupMembers = true
        lastError = nil

        defer {
            isLoadingGroupMembers = false
        }

        do {

            let loadedMemberships:
                [TimeUpRemoteMembership] =
                try await client
                    .from("group_memberships")
                    .select(
                        """
                        id,
                        group_id,
                        user_id,
                        membership_role,
                        joined_at
                        """
                    )
                    .eq(
                        "group_id",
                        value: groupID.uuidString
                    )
                    .execute()
                    .value

            groupMemberships =
                loadedMemberships

            guard !loadedMemberships.isEmpty else {
                groupMembers = []
                return
            }

            var loadedUsers:
                [TimeUpRemoteUser] = []

            for membership in loadedMemberships {

                let users:
                    [TimeUpRemoteUser] =
                    try await client
                        .from("users")
                        .select(
                            """
                            id,
                            auth_user_id,
                            email,
                            display_name,
                            role
                            """
                        )
                        .eq(
                            "id",
                            value: membership.userID.uuidString
                        )
                        .limit(1)
                        .execute()
                        .value

                if let user = users.first {
                    loadedUsers.append(user)
                }
            }

            groupMembers =
                loadedUsers.sorted {

                    let firstName =
                        $0.displayName ?? ""

                    let secondName =
                        $1.displayName ?? ""

                    return firstName.localizedCompare(
                        secondName
                    ) == .orderedAscending
                }

        } catch {

            groupMemberships = []
            groupMembers = []

            lastError =
                error.localizedDescription
        }
    }
        // MARK: - Daily Progress

    func loadDailyProgress(
        groupID: UUID
    ) async {

        isLoadingDailyProgress = true
        lastError = nil

        defer {
            isLoadingDailyProgress = false
        }

        do {

            async let targetsRequest:
                [TimeUpRemoteDailyTarget] =
                client
                    .from("daily_targets")
                    .select(
                        """
                        id,
                        group_id,
                        user_id,
                        target_date,
                        target_minutes,
                        goal_method,
                        created_at
                        """
                    )
                    .eq(
                        "group_id",
                        value: groupID.uuidString
                    )
                    .execute()
                    .value

            async let resultsRequest:
                [TimeUpRemoteDailyResult] =
                client
                    .from("daily_results")
                    .select(
                        """
                        id,
                        group_id,
                        user_id,
                        result_date,
                        usage_minutes,
                        target_minutes,
                        achieved,
                        is_learning_day,
                        source,
                        recorded_at,
                        updated_at
                        """
                    )
                    .eq(
                        "group_id",
                        value: groupID.uuidString
                    )
                    .execute()
                    .value

            async let groupResultsRequest:
                [TimeUpRemoteGroupDailyResult] =
                client
                    .from("group_daily_results")
                    .select(
                        """
                        id,
                        group_id,
                        result_date,
                        succeeded,
                        member_count,
                        completed_member_count,
                        average_usage_minutes,
                        streak_after_day
                        """
                    )
                    .eq(
                        "group_id",
                        value: groupID.uuidString
                    )
                    .execute()
                    .value

            let (
                loadedTargets,
                loadedResults,
                loadedGroupResults
            ) = try await (
                targetsRequest,
                resultsRequest,
                groupResultsRequest
            )

            dailyTargets =
                loadedTargets

            dailyResults =
                loadedResults

            groupDailyResults =
                loadedGroupResults

        } catch {

            dailyTargets = []
            dailyResults = []
            groupDailyResults = []

            lastError =
                error.localizedDescription
        }
    }

    // MARK: - Screen Time Sync

    func syncReportedScreenTime() async {

        guard !isSyncingScreenTime else {
            return
        }

        guard
            let user = currentUser,
            let group = activeMemberGroup
        else {
            return
        }

        guard
            let defaults = UserDefaults(
                suiteName: appGroupID
            )
        else {
            return
        }

        guard
            defaults.object(
                forKey: reportedUsageMinutesKey
            ) != nil
        else {
            return
        }

        let usageMinutes =
            max(
                0,
                defaults.integer(
                    forKey: reportedUsageMinutesKey
                )
            )

        guard
            let reportedAt =
                defaults.object(
                    forKey: reportedUsageUpdatedAtKey
                ) as? Date
        else {
            return
        }

        guard
            isSameGroupLocalDay(
                reportedAt,
                Date(),
                group: group
            )
        else {
            return
        }

        isSyncingScreenTime = true
        lastError = nil

        defer {
            isSyncingScreenTime = false
        }

        let today =
            databaseDateString(
                from: Date(),
                group: group
            )

        let target =
            dailyTargets.first {
                $0.groupID == group.id &&
                $0.userID == user.id &&
                $0.targetDate == today
            }

        let existingResult =
            dailyResults.first {
                $0.groupID == group.id &&
                $0.userID == user.id &&
                $0.resultDate == today
            }

        let targetMinutes =
            target?.targetMinutes ??
            existingResult?.targetMinutes

        let isLearningDay =
            existingResult?.isLearningDay ??
            (targetMinutes == nil)

        let achieved: Bool?

        if isLearningDay {

            achieved = nil

        } else if let targetMinutes {

            achieved =
                usageMinutes <= targetMinutes

        } else {

            achieved = nil
        }

        let payload =
            DailyResultUpsert(
                groupID: group.id,
                userID: user.id,
                resultDate: today,
                usageMinutes: usageMinutes,
                targetMinutes: targetMinutes,
                achieved: achieved,
                isLearningDay: isLearningDay,
                source: "screen_time",
                updatedAt: Date()
            )

        do {

            try await client
                .from("daily_results")
                .upsert(
                    payload,
                    onConflict:
                        "group_id,user_id,result_date"
                )
                .execute()

            await loadDailyProgress(
                groupID: group.id
            )

        } catch {

            lastError =
                error.localizedDescription
        }
    }

    // MARK: - Daily Helpers

    func target(
        for userID: UUID,
        on date: Date = Date()
    ) -> TimeUpRemoteDailyTarget? {

        guard let group = activeMemberGroup else {
            return nil
        }

        let dateKey =
            databaseDateString(
                from: date,
                group: group
            )

        return dailyTargets.first {
            $0.userID == userID &&
            $0.targetDate == dateKey
        }
    }

    func result(
        for userID: UUID,
        on date: Date = Date()
    ) -> TimeUpRemoteDailyResult? {

        guard let group = activeMemberGroup else {
            return nil
        }

        let dateKey =
            databaseDateString(
                from: date,
                group: group
            )

        return dailyResults.first {
            $0.userID == userID &&
            $0.resultDate == dateKey
        }
    }

    func groupResult(
        on date: Date = Date()
    ) -> TimeUpRemoteGroupDailyResult? {

        guard let group = activeMemberGroup else {
            return nil
        }

        let dateKey =
            databaseDateString(
                from: date,
                group: group
            )

        return groupDailyResults.first {
            $0.resultDate == dateKey
        }
    }

    func latestGroupResult()
        -> TimeUpRemoteGroupDailyResult? {

        groupDailyResults.max {
            $0.resultDate <
            $1.resultDate
        }
    }

    var currentGroupStreak: Int {

        if let group = activeMemberGroup {
            return group.currentStreak
        }

        return latestGroupResult()?
            .streakAfterDay ?? 0
    }

    func targetMinutes(
        for userID: UUID,
        on date: Date = Date()
    ) -> Int? {

        if let result =
            result(
                for: userID,
                on: date
            ),
           let targetMinutes =
            result.targetMinutes {

            return targetMinutes
        }

        return target(
            for: userID,
            on: date
        )?.targetMinutes
    }

    func usageMinutes(
        for userID: UUID,
        on date: Date = Date()
    ) -> Int? {

        result(
            for: userID,
            on: date
        )?.usageMinutes
    }

    func achieved(
        for userID: UUID,
        on date: Date = Date()
    ) -> Bool? {

        result(
            for: userID,
            on: date
        )?.achieved
    }

    func isLearningDay(
        for userID: UUID,
        on date: Date = Date()
    ) -> Bool {

        result(
            for: userID,
            on: date
        )?.isLearningDay ?? false
    }

    // MARK: - Group Timezone

    private func groupTimeZone(
        for group: TimeUpRemoteGroup
    ) -> TimeZone {

        TimeZone(
            identifier: group.timezone
        ) ?? TimeZone(
            identifier: "Asia/Jerusalem"
        ) ?? .current
    }

    private func databaseDateString(
        from date: Date,
        group: TimeUpRemoteGroup
    ) -> String {

        let formatter =
            DateFormatter()

        formatter.calendar =
            Calendar(
                identifier: .gregorian
            )

        formatter.locale =
            Locale(
                identifier: "en_US_POSIX"
            )

        formatter.timeZone =
            groupTimeZone(
                for: group
            )

        formatter.dateFormat =
            "yyyy-MM-dd"

        return formatter.string(
            from: date
        )
    }

    private func isSameGroupLocalDay(
        _ firstDate: Date,
        _ secondDate: Date,
        group: TimeUpRemoteGroup
    ) -> Bool {

        var calendar =
            Calendar(
                identifier: .gregorian
            )

        calendar.timeZone =
            groupTimeZone(
                for: group
            )

        return calendar.isDate(
            firstDate,
            inSameDayAs: secondDate
        )
    }

    // MARK: - Join Group

    @discardableResult
    func joinGroup(
        code: String
    ) async throws -> UUID {

        struct JoinParameters: Encodable {

            let requestedCode: String

            enum CodingKeys:
                String,
                CodingKey {

                case requestedCode =
                    "requested_code"
            }
        }

        let groupID: UUID =
            try await client
                .rpc(
                    "join_timeup_group",
                    params:
                        JoinParameters(
                            requestedCode: code
                        )
                )
                .execute()
                .value

        await loadCurrentAccount()

        return groupID
    }

    // MARK: - Display Name

    func updateDisplayName(
        _ name: String
    ) async throws {

        guard let user = currentUser else {

            throw SupabaseDataStoreError
                .userNotLoaded
        }

        struct DisplayNameUpdate:
            Encodable {

            let displayName: String

            enum CodingKeys:
                String,
                CodingKey {

                case displayName =
                    "display_name"
            }
        }

        try await client
            .from("users")
            .update(
                DisplayNameUpdate(
                    displayName: name
                )
            )
            .eq(
                "id",
                value: user.id.uuidString
            )
            .execute()

        await loadCurrentAccount()
    }

    // MARK: - Helpers

    var activeMemberGroup:
        TimeUpRemoteGroup? {

        guard
            currentUser?.role == "member"
        else {
            return nil
        }

        guard
            let membership =
                memberships.first(
                    where: {
                        $0.membershipRole ==
                            "member"
                    }
                )
        else {
            return nil
        }

        return groups.first(
            where: {
                $0.id ==
                    membership.groupID
            }
        )
    }

    var isAdmin: Bool {
        currentUser?.role == "admin"
    }

    var isMember: Bool {
        currentUser?.role == "member"
    }

    var hasActiveGroup: Bool {
        activeMemberGroup != nil
    }

    // MARK: - Clear Data

    private func clearLoadedData() {

        currentUser = nil
        memberships = []
        groups = []

        groupMemberships = []
        groupMembers = []

        dailyTargets = []
        dailyResults = []
        groupDailyResults = []
    }

    // MARK: - Reset

    func reset() {

        clearLoadedData()

        lastError = nil

        isLoading = false
        isLoadingGroupMembers = false
        isLoadingDailyProgress = false
        isSyncingScreenTime = false
    }
}

// MARK: - Errors

enum SupabaseDataStoreError:
    LocalizedError {

    case userNotLoaded

    var errorDescription: String? {

        switch self {

        case .userNotLoaded:

            return
                "TimeUp user is not loaded."
        }
    }
}
