import Foundation
import Supabase
import Combine

@MainActor
final class SupabaseRankingStore: ObservableObject {

    static let shared = SupabaseRankingStore()

    @Published private(set) var groupRankings: [GroupRanking] = []
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: String?

    private let client = SupabaseManager.shared.client

    private init() {}

    // MARK: - Model

    struct GroupRanking: Identifiable, Decodable {

        let groupID: UUID
        let groupName: String
        let currentStreak: Int
        let averageUsageMinutes: Double?
        let rankingPosition: Int

        var id: UUID {
            groupID
        }

        enum CodingKeys: String, CodingKey {
            case groupID = "group_id"
            case groupName = "group_name"
            case currentStreak = "current_streak"
            case averageUsageMinutes = "average_usage_minutes"
            case rankingPosition = "ranking_position"
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
                    .from("group_rankings")
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

            groupRankings = rankings

        } catch {

            groupRankings = []
            lastError = error.localizedDescription
        }
    }

    // MARK: - Helpers

    func ranking(
        for groupID: UUID
    ) -> GroupRanking? {

        groupRankings.first {
            $0.groupID == groupID
        }
    }

    func position(
        for groupID: UUID
    ) -> Int? {

        ranking(for: groupID)?
            .rankingPosition
    }

    func clear() {

        groupRankings = []
        lastError = nil
        isLoading = false
    }
}
