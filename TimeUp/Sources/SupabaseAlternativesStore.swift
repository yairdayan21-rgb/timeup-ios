import Foundation
import Supabase
import Combine

@MainActor
final class SupabaseAlternativesStore: ObservableObject {

    static let shared = SupabaseAlternativesStore()

    // MARK: - Published State

    @Published private(set) var alternatives: [Alternative] = []
    @Published private(set) var groupFeed: [GroupFeedItem] = []

    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingFeed = false

    @Published private(set) var completingAlternativeIDs: Set<Int64> = []

    @Published private(set) var alternativesError: String?
    @Published private(set) var feedError: String?

    private let client = SupabaseManager.shared.client

    // MARK: - Realtime

    private var realtimeChannel: RealtimeChannelV2?
    private var realtimeTask: Task<Void, Never>?
    private var subscribedGroupID: UUID?

    private init() {}

    // MARK: - Models

    struct Alternative: Identifiable, Decodable, Equatable {

        let alternativeID: Int64
        let alternativeText: String

        var id: Int64 {
            alternativeID
        }

        enum CodingKeys: String, CodingKey {
            case alternativeID = "alternative_id"
            case alternativeText = "alternative_text"
        }
    }

    struct GroupFeedItem: Identifiable, Decodable, Equatable {

        let completionID: UUID
        let userID: UUID
        let displayName: String
        let alternativeID: Int64
        let alternativeText: String
        let completedAt: Date

        var id: UUID {
            completionID
        }

        enum CodingKeys: String, CodingKey {
            case completionID = "completion_id"
            case userID = "user_id"
            case displayName = "display_name"
            case alternativeID = "alternative_id"
            case alternativeText = "alternative_text"
            case completedAt = "completed_at"
        }
    }

    struct CompletionResult: Decodable {

        let completionID: UUID
        let alternativeID: Int64
        let alternativeText: String
        let completedAt: Date

        enum CodingKeys: String, CodingKey {
            case completionID = "completion_id"
            case alternativeID = "alternative_id"
            case alternativeText = "alternative_text"
            case completedAt = "completed_at"
        }
    }

    // MARK: - RPC Parameters

    private struct GetAlternativesParameters: Encodable {

        let groupID: UUID
        let limit: Int
        let language: String

        enum CodingKeys: String, CodingKey {
            case groupID = "p_group_id"
            case limit = "p_limit"
            case language = "p_language"
        }
    }

    private struct CompleteAlternativeParameters: Encodable {

        let groupID: UUID
        let alternativeID: Int64

        enum CodingKeys: String, CodingKey {
            case groupID = "p_group_id"
            case alternativeID = "p_alternative_id"
        }
    }

    private struct GroupFeedParameters: Encodable {

        let groupID: UUID

        enum CodingKeys: String, CodingKey {
            case groupID = "p_group_id"
        }
    }

    // MARK: - Language

    private var currentLanguageCode: String {

        TimeUpLocalization.shared.language.rawValue
    }

    // MARK: - Initial Load

    func load(
        groupID: UUID
    ) async {

        startRealtime(
            groupID: groupID
        )

        async let alternativesTask: Void =
            loadAlternatives(
                groupID: groupID
            )

        async let feedTask: Void =
            loadGroupFeed(
                groupID: groupID
            )

        _ = await (
            alternativesTask,
            feedTask
        )
    }

    // MARK: - Load Alternatives

    func loadAlternatives(
        groupID: UUID
    ) async {

        isLoading = true
        alternativesError = nil

        defer {
            isLoading = false
        }

        do {

            let result: [Alternative] =
                try await client
                    .rpc(
                        "get_timeup_alternatives",
                        params:
                            GetAlternativesParameters(
                                groupID: groupID,
                                limit: 5,
                                language:
                                    currentLanguageCode
                            )
                    )
                    .execute()
                    .value

            alternatives = result

        } catch {

            alternativesError =
                error.localizedDescription
        }
    }

    // MARK: - Complete Alternative

    func complete(
        _ alternative: Alternative,
        groupID: UUID
    ) async {

        guard
            !completingAlternativeIDs
                .contains(
                    alternative.alternativeID
                )
        else {
            return
        }

        completingAlternativeIDs.insert(
            alternative.alternativeID
        )

        alternativesError = nil

        defer {

            completingAlternativeIDs.remove(
                alternative.alternativeID
            )
        }

        do {

            let _: [CompletionResult] =
                try await client
                    .rpc(
                        "complete_timeup_alternative",
                        params:
                            CompleteAlternativeParameters(
                                groupID: groupID,
                                alternativeID:
                                    alternative.alternativeID
                            )
                    )
                    .execute()
                    .value

            // Remove completed item immediately.

            alternatives.removeAll {
                $0.alternativeID ==
                    alternative.alternativeID
            }

            // Fetch the same current daily list,
            // filling only the missing slot.
            //
            // The selected language affects only the text.
            // It does not change today's selected IDs.

            let currentAlternatives: [Alternative] =
                try await client
                    .rpc(
                        "get_timeup_alternatives",
                        params:
                            GetAlternativesParameters(
                                groupID: groupID,
                                limit: 5,
                                language:
                                    currentLanguageCode
                            )
                    )
                    .execute()
                    .value

            alternatives =
                currentAlternatives

            // Refresh immediately for this member.
            // Other members receive feed changes via Realtime.

            await loadGroupFeed(
                groupID: groupID
            )

        } catch {

            alternativesError =
                error.localizedDescription
        }
    }

    // MARK: - Language Refresh

    func refreshLanguage(
        groupID: UUID
    ) async {

        // This asks Supabase for the same current
        // alternative IDs using the newly selected language.
        //
        // The RPC preserves today's stable suggestions.

        await loadAlternatives(
            groupID: groupID
        )
    }

    // MARK: - Group Feed

    func loadGroupFeed(
        groupID: UUID
    ) async {

        isLoadingFeed = true
        feedError = nil

        defer {
            isLoadingFeed = false
        }

        do {

            let result: [GroupFeedItem] =
                try await client
                    .rpc(
                        "get_timeup_group_alternatives_feed",
                        params:
                            GroupFeedParameters(
                                groupID: groupID
                            )
                    )
                    .execute()
                    .value

            groupFeed = result

        } catch {

            feedError =
                error.localizedDescription
        }
    }

    func refreshFeed(
        groupID: UUID
    ) async {

        await loadGroupFeed(
            groupID: groupID
        )
    }

    // MARK: - Realtime

    func startRealtime(
        groupID: UUID
    ) {

        // Already listening to this group.
        if subscribedGroupID == groupID,
           realtimeChannel != nil {
            return
        }

        stopRealtime()

        subscribedGroupID = groupID

        let channel =
            client.realtimeV2.channel(
                "timeup-alternatives-\(groupID.uuidString)"
            )

        realtimeChannel = channel

        let changes =
            channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "alternative_completions",
                filter:
                    "group_id=eq.\(groupID.uuidString)"
            )

        realtimeTask = Task { [weak self] in

            guard let self else {
                return
            }

            do {

                await channel.subscribe()

                for await _ in changes {

                    guard
                        !Task.isCancelled
                    else {
                        break
                    }

                    await self.loadGroupFeed(
                        groupID: groupID
                    )
                }

            } catch {

                guard
                    !Task.isCancelled
                else {
                    return
                }

                await MainActor.run {

                    self.feedError =
                        error.localizedDescription
                }
            }
        }
    }

    func stopRealtime() {

        realtimeTask?.cancel()
        realtimeTask = nil

        if let channel =
            realtimeChannel {

            Task {

                await channel.unsubscribe()
            }
        }

        realtimeChannel = nil
        subscribedGroupID = nil
    }

    // MARK: - Helpers

    func isCompleting(
        _ alternative: Alternative
    ) -> Bool {

        completingAlternativeIDs.contains(
            alternative.alternativeID
        )
    }

    // MARK: - Clear

    func clear() {

        stopRealtime()

        alternatives = []
        groupFeed = []

        completingAlternativeIDs = []

        alternativesError = nil
        feedError = nil

        isLoading = false
        isLoadingFeed = false
    }
}