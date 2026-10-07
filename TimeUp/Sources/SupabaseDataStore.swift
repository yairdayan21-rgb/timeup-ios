import Foundation
import Supabase
import Combine
import Security

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
    @Published private(set) var isCreatingGroup = false
    @Published private(set) var isSavingManualTarget = false
    @Published private(set) var isCompletingOnboarding = false
    @Published private(set) var lastError: String?

    private let client = SupabaseManager.shared.client
    private let appGroupID = "group.com.timeup.shared"
    private let reportedUsageMinutesKey = "reportedUsageMinutes"
    private let reportedUsageUpdatedAtKey = "reportedUsageUpdatedAt"

    private init() {}

    // MARK: - Models

    public struct TimeUpRemoteUser: Identifiable, Decodable {

        public let id: UUID
        public let authUserID: UUID
        public let email: String?
        public let displayName: String?
        public let role: String
        public let onboardingCompleted: Bool
        public let onboardingCompletedAt: Date?

        enum CodingKeys: String, CodingKey {
            case id
            case authUserID = "auth_user_id"
            case email
            case displayName = "display_name"
            case role
            case onboardingCompleted = "onboarding_completed"
            case onboardingCompletedAt = "onboarding_completed_at"
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

    private struct SecureJoinResponse: Decodable {

        let success: Bool
        let groupID: UUID?
        let error: String?
        let retryAfterSeconds: Int

        enum CodingKeys: String, CodingKey {
            case success
            case groupID = "group_id"
            case error
            case retryAfterSeconds = "retry_after_seconds"
        }
    }

    // MARK: - Payloads

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

    private struct DailyTargetUpsert: Encodable {

        let groupID: UUID
        let userID: UUID
        let targetDate: String
        let targetMinutes: Int
        let goalMethod: String

        enum CodingKeys: String, CodingKey {
            case groupID = "group_id"
            case userID = "user_id"
            case targetDate = "target_date"
            case targetMinutes = "target_minutes"
            case goalMethod = "goal_method"
        }
    }

    private struct GroupInsert: Encodable {

        let name: String
        let joinCode: String
        let createdBy: UUID
        let goalMethod: String
        let reductionPercent: Int?
        let journeyDays: Int
        let currentStreak: Int
        let timezone: String

        enum CodingKeys: String, CodingKey {
            case name
            case joinCode = "join_code"
            case createdBy = "created_by"
            case goalMethod = "goal_method"
            case reductionPercent = "reduction_percent"
            case journeyDays = "journey_days"
            case currentStreak = "current_streak"
            case timezone
        }
    }

    private struct MembershipInsert: Encodable {

        let groupID: UUID
        let userID: UUID
        let membershipRole: String

        enum CodingKeys: String, CodingKey {
            case groupID = "group_id"
            case userID = "user_id"
            case membershipRole = "membership_role"
        }
    }

    private struct OnboardingCompletionUpdate: Encodable {

        let onboardingCompleted: Bool
        let onboardingCompletedAt: Date

        enum CodingKeys: String, CodingKey {
            case onboardingCompleted = "onboarding_completed"
            case onboardingCompletedAt = "onboarding_completed_at"
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

            let session = try await client.auth.session
            let authUserID = session.user.id

            let users: [TimeUpRemoteUser] =
                try await client
                    .from("users")
                    .select(
                        """
                        id,
                        auth_user_id,
                        email,
                        display_name,
                        role,
                        onboarding_completed,
                        onboarding_completed_at
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
            try await loadMemberships(for: user.id)

        } catch {
            clearLoadedData()
            lastError = error.localizedDescription
        }
    }

    // MARK: - Memberships

    private func loadMemberships(
        for userID: UUID
    ) async throws {

        let loadedMemberships: [TimeUpRemoteMembership] =
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

        memberships = loadedMemberships

        if currentUser?.role == "admin" {

            try await loadAdminGroups(for: userID)

        } else {

            let groupIDs = loadedMemberships.map {
                $0.groupID
            }

            try await loadGroups(ids: groupIDs)
        }
    }

    // MARK: - Admin Groups

    private func loadAdminGroups(
        for adminUserID: UUID
    ) async throws {

        let loadedGroups: [TimeUpRemoteGroup] =
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
                    "created_by",
                    value: adminUserID.uuidString
                )
                .execute()
                .value

        groups = loadedGroups
    }

    // MARK: - Member Groups

    private func loadGroups(
        ids: [UUID]
    ) async throws {

        guard !ids.isEmpty else {
            groups = []
            return
        }

        var loadedGroups: [TimeUpRemoteGroup] = []

        for groupID in ids {

            let result: [TimeUpRemoteGroup] =
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

        groups = loadedGroups
    }

    // MARK: - Secure Group Code

    private func generateSecureGroupCode() throws -> String {

        let alphabet = Array(
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789".utf8
        )

        let codeLength = 8

        // 248 is divisible by 62. Rejecting bytes >= 248
        // avoids bias when mapping random bytes to the alphabet.
        let acceptanceLimit = 248

        for _ in 0..<128 {

            var selectedBytes: [UInt8] = []
            selectedBytes.reserveCapacity(codeLength)

            while selectedBytes.count < codeLength {

                var randomBytes = [UInt8](
                    repeating: 0,
                    count: 32
                )

                let status = randomBytes.withUnsafeMutableBytes {
                    buffer in

                    SecRandomCopyBytes(
                        kSecRandomDefault,
                        buffer.count,
                        buffer.baseAddress!
                    )
                }

                guard status == errSecSuccess else {
                    throw SupabaseDataStoreError
                        .secureCodeGenerationFailed
                }

                for byte in randomBytes {

                    guard Int(byte) < acceptanceLimit else {
                        continue
                    }

                    let index = Int(byte) % alphabet.count
                    selectedBytes.append(alphabet[index])

                    if selectedBytes.count == codeLength {
                        break
                    }
                }
            }

            let hasUppercase = selectedBytes.contains {
                $0 >= 65 && $0 <= 90
            }

            let hasLowercase = selectedBytes.contains {
                $0 >= 97 && $0 <= 122
            }

            let hasDigit = selectedBytes.contains {
                $0 >= 48 && $0 <= 57
            }

            guard
                hasUppercase,
                hasLowercase,
                hasDigit
            else {
                continue
            }

            return String(
                decoding: selectedBytes,
                as: UTF8.self
            )
        }

        throw SupabaseDataStoreError
            .secureCodeGenerationFailed
    }

    // MARK: - Create Group

    @discardableResult
    func createGroup(
        name: String,
        goalMethod: String,
        reductionPercent: Int?,
        successDays: Int?,
        timezone: String = "Asia/Jerusalem"
    ) async throws -> TimeUpRemoteGroup {

        guard let user = currentUser else {
            throw SupabaseDataStoreError.userNotLoaded
        }

        guard user.role == "admin" else {
            throw SupabaseDataStoreError.adminRequired
        }

        let cleanName = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanName.isEmpty else {
            throw SupabaseDataStoreError.invalidGroupName
        }

        isCreatingGroup = true
        lastError = nil

        defer {
            isCreatingGroup = false
        }

        var lastCreationError: Error?

        for _ in 0..<20 {

            do {

                let code = try generateSecureGroupCode()

                let payload = GroupInsert(
                    name: cleanName,
                    joinCode: code,
                    createdBy: user.id,
                    goalMethod: goalMethod,
                    reductionPercent: goalMethod == "manual"
                        ? nil
                        : reductionPercent,
                    journeyDays: successDays ?? 7,
                    currentStreak: 0,
                    timezone: timezone
                )

                let createdGroups: [TimeUpRemoteGroup] =
                    try await client
                        .from("groups")
                        .insert(payload)
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
                        .execute()
                        .value

                guard let createdGroup = createdGroups.first else {
                    throw SupabaseDataStoreError.groupCreationFailed
                }

                do {

                    let membership = MembershipInsert(
                        groupID: createdGroup.id,
                        userID: user.id,
                        membershipRole: "admin"
                    )

                    try await client
                        .from("group_memberships")
                        .insert(membership)
                        .execute()

                } catch {

                    try? await client
                        .from("groups")
                        .delete()
                        .eq(
                            "id",
                            value: createdGroup.id.uuidString
                        )
                        .execute()

                    throw error
                }

                await loadCurrentAccount()
                return createdGroup

            } catch {
                lastCreationError = error
            }
        }

        let finalError =
            lastCreationError
            ?? SupabaseDataStoreError.groupCreationFailed

        lastError = finalError.localizedDescription
        throw finalError
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

            let loadedMemberships: [TimeUpRemoteMembership] =
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

            groupMemberships = loadedMemberships

            guard !loadedMemberships.isEmpty else {
                groupMembers = []
                return
            }

            var loadedUsers: [TimeUpRemoteUser] = []

            for membership in loadedMemberships {

                let users: [TimeUpRemoteUser] =
                    try await client
                        .from("users")
                        .select(
                            """
                            id,
                            auth_user_id,
                            email,
                            display_name,
                            role,
                            onboarding_completed,
                            onboarding_completed_at
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

            groupMembers = loadedUsers.sorted {

                let firstName = $0.displayName ?? ""
                let secondName = $1.displayName ?? ""

                return firstName.localizedCompare(
                    secondName
                ) == .orderedAscending
            }

        } catch {
            groupMemberships = []
            groupMembers = []
            lastError = error.localizedDescription
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

            async let targetsRequest: [TimeUpRemoteDailyTarget] =
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

            async let resultsRequest: [TimeUpRemoteDailyResult] =
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

            async let groupResultsRequest: [TimeUpRemoteGroupDailyResult] =
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

            dailyTargets = loadedTargets
            dailyResults = loadedResults
            groupDailyResults = loadedGroupResults

        } catch {
            dailyTargets = []
            dailyResults = []
            groupDailyResults = []
            lastError = error.localizedDescription
        }
    }

    // MARK: - Manual Target

    func setManualTarget(
        group: TimeUpRemoteGroup,
        userID: UUID,
        targetMinutes: Int
    ) async throws {

        guard let currentUser else {
            throw SupabaseDataStoreError.userNotLoaded
        }

        guard currentUser.role == "admin" else {
            throw SupabaseDataStoreError.adminRequired
        }

        guard group.goalMethod == "manual" else {
            throw SupabaseDataStoreError.manualGroupRequired
        }

        guard targetMinutes > 0 else {
            throw SupabaseDataStoreError.invalidTargetMinutes
        }

        isSavingManualTarget = true
        lastError = nil

        defer {
            isSavingManualTarget = false
        }

        let targetDate = databaseDateString(
            from: Date(),
            group: group
        )

        let payload = DailyTargetUpsert(
            groupID: group.id,
            userID: userID,
            targetDate: targetDate,
            targetMinutes: targetMinutes,
            goalMethod: "manual"
        )

        do {

            try await client
                .from("daily_targets")
                .upsert(
                    payload,
                    onConflict: "group_id,user_id,target_date"
                )
                .execute()

            await loadDailyProgress(groupID: group.id)

        } catch {
            lastError = error.localizedDescription
            throw error
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

        guard let defaults = UserDefaults(
            suiteName: appGroupID
        ) else {
            return
        }

        guard defaults.object(
            forKey: reportedUsageMinutesKey
        ) != nil else {
            return
        }

        let usageMinutes = max(
            0,
            defaults.integer(
                forKey: reportedUsageMinutesKey
            )
        )

        guard let reportedAt = defaults.object(
            forKey: reportedUsageUpdatedAtKey
        ) as? Date else {
            return
        }

        guard isSameGroupLocalDay(
            reportedAt,
            Date(),
            group: group
        ) else {
            return
        }

        isSyncingScreenTime = true
        lastError = nil

        defer {
            isSyncingScreenTime = false
        }

        let today = databaseDateString(
            from: Date(),
            group: group
        )

        let target = dailyTargets.first {
            $0.groupID == group.id
                && $0.userID == user.id
                && $0.targetDate == today
        }

        let existingResult = dailyResults.first {
            $0.groupID == group.id
                && $0.userID == user.id
                && $0.resultDate == today
        }

        let targetMinutes =
            target?.targetMinutes
            ?? existingResult?.targetMinutes

        let isLearningDay =
            existingResult?.isLearningDay
            ?? (targetMinutes == nil)

        let achieved: Bool?

        if isLearningDay {
            achieved = nil
        } else if let targetMinutes {
            achieved = usageMinutes <= targetMinutes
        } else {
            achieved = nil
        }

        let payload = DailyResultUpsert(
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
                    onConflict: "group_id,user_id,result_date"
                )
                .execute()

            await loadDailyProgress(groupID: group.id)

        } catch {
            lastError = error.localizedDescription
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

        let dateKey = databaseDateString(
            from: date,
            group: group
        )

        return dailyTargets.first {
            $0.userID == userID
                && $0.targetDate == dateKey
        }
    }

    func result(
        for userID: UUID,
        on date: Date = Date()
    ) -> TimeUpRemoteDailyResult? {

        guard let group = activeMemberGroup else {
            return nil
        }

        let dateKey = databaseDateString(
            from: date,
            group: group
        )

        return dailyResults.first {
            $0.userID == userID
                && $0.resultDate == dateKey
        }
    }

    func groupResult(
        on date: Date = Date()
    ) -> TimeUpRemoteGroupDailyResult? {

        guard let group = activeMemberGroup else {
            return nil
        }

        let dateKey = databaseDateString(
            from: date,
            group: group
        )

        return groupDailyResults.first {
            $0.resultDate == dateKey
        }
    }

    func latestGroupResult() -> TimeUpRemoteGroupDailyResult? {

        groupDailyResults.max {
            $0.resultDate < $1.resultDate
        }
    }

    var currentGroupStreak: Int {

        if let group = activeMemberGroup {
            return group.currentStreak
        }

        return latestGroupResult()?.streakAfterDay ?? 0
    }

    func targetMinutes(
        for userID: UUID,
        on date: Date = Date()
    ) -> Int? {

        if let result = result(
            for: userID,
            on: date
        ),
           let targetMinutes = result.targetMinutes {
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
        group: groupType
    ) -> String {

        let formatter = DateFormatter()

        formatter.calendar = Calendar(
            identifier: .gregorian
        )

        formatter.locale = Locale(
            identifier: "en_US_POSIX"
        )

        formatter.timeZone = groupTimeZone(for: group)
        formatter.dateFormat = "yyyy-MM-dd"

        return formatter.string(from: date)
    }

    private typealias groupType = TimeUpRemoteGroup

    private func isSameGroupLocalDay(
        _ firstDate: Date,
        _ secondDate: Date,
        group: TimeUpRemoteGroup
    ) -> Bool {

        var calendar = Calendar(
            identifier: .gregorian
        )

        calendar.timeZone = groupTimeZone(for: group)

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

            enum CodingKeys: String, CodingKey {
                case requestedCode = "requested_code"
            }
        }

        let response: SecureJoinResponse =
            try await client
                .rpc(
                    "join_timeup_group_secure",
                    params: JoinParameters(
                        requestedCode: code
                    )
                )
                .execute()
                .value

        guard response.success else {

            throw SupabaseGroupJoinError(
                code: response.error ?? "INVALID_JOIN_RESPONSE",
                retryAfterSeconds: max(
                    0,
                    response.retryAfterSeconds
                )
            )
        }

        guard
            let groupID = response.groupID,
            response.error == nil
        else {

            throw SupabaseGroupJoinError(
                code: "INVALID_JOIN_RESPONSE",
                retryAfterSeconds: 0
            )
        }

        await loadCurrentAccount()
        return groupID
    }

    // MARK: - Remove Group Member

    func removeMemberFromGroup(
        groupID: UUID,
        userID: UUID
    ) async throws {

        guard let currentUser else {
            throw SupabaseDataStoreError.userNotLoaded
        }

        guard currentUser.role == "admin" else {
            throw SupabaseDataStoreError.adminRequired
        }

        guard currentUser.id != userID else {
            throw SupabaseDataStoreError.cannotRemoveSelf
        }

        lastError = nil

        do {

            try await client
                .from("group_memberships")
                .delete()
                .eq(
                    "group_id",
                    value: groupID.uuidString
                )
                .eq(
                    "user_id",
                    value: userID.uuidString
                )
                .execute()

            await loadGroupMembers(groupID: groupID)
            await loadDailyProgress(groupID: groupID)

        } catch {
            lastError = error.localizedDescription
            throw error
        }
    }

    // MARK: - Display Name

    func updateDisplayName(
        _ name: String
    ) async throws {

        guard let user = currentUser else {
            throw SupabaseDataStoreError.userNotLoaded
        }

        struct DisplayNameUpdate: Encodable {

            let displayName: String

            enum CodingKeys: String, CodingKey {
                case displayName = "display_name"
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

    // MARK: - Onboarding

    func completeOnboarding() async throws {

        guard let user = currentUser else {
            throw SupabaseDataStoreError.userNotLoaded
        }

        guard user.role == "member" else {
            return
        }

        isCompletingOnboarding = true
        lastError = nil

        defer {
            isCompletingOnboarding = false
        }

        let completedAt = Date()

        do {

            try await client
                .from("users")
                .update(
                    OnboardingCompletionUpdate(
                        onboardingCompleted: true,
                        onboardingCompletedAt: completedAt
                    )
                )
                .eq(
                    "id",
                    value: user.id.uuidString
                )
                .execute()

            await loadCurrentAccount()

        } catch {
            lastError = error.localizedDescription
            throw error
        }
    }

    // MARK: - Helpers

    var activeMemberGroup: TimeUpRemoteGroup? {

        guard currentUser?.role == "member" else {
            return nil
        }

        guard let membership = memberships.first(
            where: { $0.membershipRole == "member" }
        ) else {
            return nil
        }

        return groups.first(
            where: { $0.id == membership.groupID }
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

    var shouldShowOnboarding: Bool {

        guard let currentUser else {
            return false
        }

        return currentUser.role == "member"
            && !currentUser.onboardingCompleted
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
        isCreatingGroup = false
        isSavingManualTarget = false
        isCompletingOnboarding = false
    }
}

// MARK: - Group Join Error

struct SupabaseGroupJoinError: LocalizedError {

    let code: String
    let retryAfterSeconds: Int

    var errorDescription: String? {
        code
    }
}

// MARK: - Data Store Errors

enum SupabaseDataStoreError: LocalizedError {

    case userNotLoaded
    case adminRequired
    case invalidGroupName
    case groupCreationFailed
    case secureCodeGenerationFailed
    case manualGroupRequired
    case invalidTargetMinutes
    case cannotRemoveSelf

    var errorDescription: String? {

        switch self {

        case .userNotLoaded:
            return "TimeUp user is not loaded."

        case .adminRequired:
            return "Only a TimeUp admin can perform this action."

        case .invalidGroupName:
            return "Group name cannot be empty."

        case .groupCreationFailed:
            return "TimeUp could not create the group."

        case .secureCodeGenerationFailed:
            return "TimeUp could not securely generate a group code. Please try again."

        case .manualGroupRequired:
            return "Manual targets can only be changed in a manual group."

        case .invalidTargetMinutes:
            return "Target minutes must be greater than zero."

        case .cannotRemoveSelf:
            return "An admin cannot remove themselves from the group."
        }
    }
}