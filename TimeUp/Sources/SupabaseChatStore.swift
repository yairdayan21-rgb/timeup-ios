import Foundation
import Combine
import Supabase

final class SupabaseChatStore: ObservableObject {

    static let shared = SupabaseChatStore()

    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSending = false
    @Published private(set) var lastError: String?

    private let client = SupabaseManager.shared.client

    private var realtimeChannel: RealtimeChannelV2?
    private var realtimeTask: Task<Void, Never>?
    private var subscribedGroupID: UUID?

    private init() {}

    // MARK: - Message Model

    struct ChatMessage: Identifiable, Codable, Equatable {

        let id: UUID
        let groupID: UUID
        let senderID: UUID
        let text: String
        let createdAt: Date

        enum CodingKeys: String, CodingKey {
            case id
            case groupID = "group_id"
            case senderID = "sender_id"
            case text = "message_text"
            case createdAt = "created_at"
        }
    }

    // MARK: - Insert Payload

    private struct MessageInsert: Encodable {

        let groupID: UUID
        let senderID: UUID
        let text: String

        enum CodingKeys: String, CodingKey {
            case groupID = "group_id"
            case senderID = "sender_id"
            case text = "message_text"
        }
    }

    // MARK: - Load Messages

    @MainActor
    func loadMessages(
        groupID: UUID
    ) async {

        isLoading = true
        lastError = nil

        defer {
            isLoading = false
        }

        do {

            let loadedMessages: [ChatMessage] =
                try await client
                    .from("group_messages")
                    .select()
                    .eq(
                        "group_id",
                        value: groupID.uuidString
                    )
                    .order(
                        "created_at",
                        ascending: true
                    )
                    .execute()
                    .value

            messages = loadedMessages

        } catch {

            lastError =
                error.localizedDescription
        }
    }

    // MARK: - Realtime

    @MainActor
    func startRealtime(
        groupID: UUID
    ) async {

        if subscribedGroupID == groupID,
           realtimeChannel != nil {
            return
        }

        await stopRealtime()

        subscribedGroupID = groupID

        let channel =
            client.realtimeV2.channel(
                "timeup-group-chat-\(groupID.uuidString)"
            )

        realtimeChannel = channel

        let insertions =
            channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "group_messages",
                filter:
                    "group_id=eq.\(groupID.uuidString)"
            )

        realtimeTask =
            Task { [weak self] in

                guard let self else {
                    return
                }

                for await _ in insertions {

                    guard !Task.isCancelled else {
                        return
                    }

                    await self.loadMessages(
                        groupID: groupID
                    )
                }
            }

        do {

            try await channel.subscribe()

        } catch {

            lastError =
                error.localizedDescription

            realtimeTask?.cancel()
            realtimeTask = nil

            realtimeChannel = nil
            subscribedGroupID = nil
        }
    }

    @MainActor
    func stopRealtime() async {

        realtimeTask?.cancel()
        realtimeTask = nil

        if let realtimeChannel {

            await client.realtimeV2
                .removeChannel(
                    realtimeChannel
                )
        }

        realtimeChannel = nil
        subscribedGroupID = nil
    }

    // MARK: - Send Message

    @MainActor
    func sendMessage(
        groupID: UUID,
        senderID: UUID,
        text: String
    ) async throws {

        let cleanText =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanText.isEmpty else {
            throw ChatError.emptyMessage
        }

        guard cleanText.count <= 2000 else {
            throw ChatError.messageTooLong
        }

        isSending = true
        lastError = nil

        defer {
            isSending = false
        }

        let payload =
            MessageInsert(
                groupID: groupID,
                senderID: senderID,
                text: cleanText
            )

        do {

            try await client
                .from("group_messages")
                .insert(payload)
                .execute()

            await loadMessages(
                groupID: groupID
            )

        } catch {

            lastError =
                error.localizedDescription

            throw error
        }
    }

    // MARK: - Helpers

    func messages(
        for groupID: UUID
    ) -> [ChatMessage] {

        messages.filter {
            $0.groupID == groupID
        }
    }

    @MainActor
    func clear() async {

        await stopRealtime()

        messages = []
        lastError = nil
    }
}

// MARK: - Errors

enum ChatError: LocalizedError {

    case emptyMessage
    case messageTooLong

    var errorDescription: String? {

        switch self {

        case .emptyMessage:
            return "לא ניתן לשלוח הודעה ריקה."

        case .messageTooLong:
            return "הודעה יכולה להכיל עד 2,000 תווים."
        }
    }
}