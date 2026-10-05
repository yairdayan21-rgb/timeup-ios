import Foundation
import Supabase
import Combine

@MainActor
final class SupabaseRankingStore: ObservableObject {

    static let shared = SupabaseRankingStore()

    @Published private(set) var groupRankings: [GroupRanking] = []
    @Published private(set) var userRankings: [UserRanking] = []

    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingUsers = false

    @Published private(set) var lastError: String?
    @Published private(set) var userRankingError: String?

    private let client =
        SupabaseManager.shared.client

    private init() {}

    // MARK: - Group Ranking Model

    struct GroupRanking:
        Identifiable,
        Decodable {

        let groupID: UUID
        let groupName: String
        let currentStreak: Int
        let averageUsageMinutes: Double?
        let rankingPosition: Int

        var id: UUID {
            groupID
        }

        enum CodingKeys:
            String,
            CodingKey {

            case groupID =
                "group_id"

            case groupName =
                "group_name"

            case currentStreak =
                "current_streak"

            case averageUsageMinutes =
                "average_usage_minutes"

            case rankingPosition =
                "ranking_position"
        }
    }

    // MARK: - User Ranking Model

    struct UserRanking:
        Identifiable,
        Decodable {

        let userID: UUID
        let displayName: String?
        let personalStreak: Int
        let averageUsageMinutes: Double?
        let rankingPosition: Int

        var id: UUID {
            userID
        }

        enum CodingKeys:
            String,
            CodingKey {

            case userID =
                "user_id"

            case displayName =
                "display_name"

            case personalStreak =
                "personal_streak"

            case averageUsageMinutes =
                "average_usage_minutes"

            case rankingPosition =
                "ranking_position"
        }
    }

    // MARK: - Load Group Rankings

    func loadGroupRankings() async {

        isLoading = true
        lastError = nil

        defer {
            isLoading = false
        }

        do {

            let rankings: [GroupRanking] =
                try await client
                    .from(
                        "group_rankings"
                    )
                    .select(
                        """
                        group_id,
                        group_name,
                        current_streak,
                        average_usage_minutes,
                        ranking_position
                        """
                    )
                    .order(
                        "ranking_position",
                        ascending: true
                    )
                    .execute()
                    .value

            groupRankings =
                rankings

        } catch {

            groupRankings = []

            lastError =
                error.localizedDescription
        }
    }

    // MARK: - Load User Rankings
    // Admin only.
    // Supabase RPC verifies is_timeup_admin()
    // before returning individual ranking data.

    func loadUserRankings() async {

        isLoadingUsers = true
        userRankingError = nil

        defer {
            isLoadingUsers = false
        }

        do {

            let rankings: [UserRanking] =
                try await client
                    .rpc(
                        "get_admin_user_rankings"
                    )
                    .execute()
                    .value

            userRankings =
                rankings

        } catch {

            userRankings = []

            userRankingError =
                error.localizedDescription
        }
    }

    // MARK: - Load All Rankings

    func loadAllRankings() async {

        async let groups: Void =
            loadGroupRankings()

        async let users: Void =
            loadUserRankings()

        _ = await (
            groups,
            users
        )
    }

    // MARK: - Group Helpers

    func ranking(
        for groupID: UUID
    ) -> GroupRanking? {

        groupRankings.first {
            $0.groupID ==
                groupID
        }
    }

    func position(
        for groupID: UUID
    ) -> Int? {

        ranking(
            for: groupID
        )?
        .rankingPosition
    }

    // MARK: - User Helpers

    func userRanking(
        for userID: UUID
    ) -> UserRanking? {

        userRankings.first {
            $0.userID ==
                userID
        }
    }

    func userPosition(
        for userID: UUID
    ) -> Int? {

        userRanking(
            for: userID
        )?
        .rankingPosition
    }

    // MARK: - Clear

    func clear() {

        groupRankings = []
        userRankings = []

        lastError = nil
        userRankingError = nil

        isLoading = false
        isLoadingUsers = false
    }
}