import Foundation
import Combine
import Supabase

final class SupabaseChatStore: ObservableObject {

    static let shared = SupabaseChatStore()

    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var unreadCounts: [UUID: Int] = [:]

    @Published private(set) var isLoading = false
    @Published private(set) var isSending = false
    @Published private(set) var lastError: String?

    private let client = SupabaseManager.shared.client

    // Foreground chat realtime
    private var realtimeChannel: RealtimeChannelV2?
    private var realtimeTask: Task<Void, Never>?
    private var subscribedGroupID: UUID?

    // Independent unread realtime
    private var unreadRealtimeChannel: RealtimeChannelV2?
    private var unreadRealtimeTask: Task<Void, Never>?
    private var unreadSubscribedGroupID: UUID?
    private var unreadSubscribedUserID: UUID?

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

    // MARK: - Read State

    struct ChatReadState: Codable, Equatable {

        let groupID: UUID
        let userID: UUID
        let lastReadMessageID: UUID?
        let lastReadAt: Date

        enum CodingKeys: String, CodingKey {
            case groupID = "group_id"
            case userID = "user_id"
            case lastReadMessageID = "last_read_message_id"
            case lastReadAt = "last_read_at"
        }
    }

    // MARK: - Message Insert

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

    // MARK: - Read State Upsert

    private struct ReadStateUpsert: Encodable {

        let groupID: UUID
        let userID: UUID
        let lastReadMessageID: UUID
        let lastReadAt: Date

        enum CodingKeys: String, CodingKey {
            case groupID = "group_id"
            case userID = "user_id"
            case lastReadMessageID = "last_read_message_id"
            case lastReadAt = "last_read_at"
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

    // MARK: - Load Unread Count

    @MainActor
    func loadUnreadCount(
        groupID: UUID,
        userID: UUID
    ) async {

        do {

            let readStates: [ChatReadState] =
                try await client
                    .from("group_chat_read_state")
                    .select(
                        "group_id,user_id,last_read_message_id,last_read_at"
                    )
                    .eq(
                        "group_id",
                        value: groupID.uuidString
                    )
                    .eq(
                        "user_id",
                        value: userID.uuidString
                    )
                    .limit(1)
                    .execute()
                    .value

            let groupMessages: [ChatMessage] =
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

            guard let readState =
                    readStates.first else {

                let unread =
                    groupMessages.filter {
                        $0.senderID != userID
                    }.count

                unreadCounts[groupID] =
                    unread

                return
            }

            guard let lastReadMessageID =
                    readState.lastReadMessageID,
                  let lastReadIndex =
                    groupMessages.firstIndex(
                        where: {
                            $0.id ==
                                lastReadMessageID
                        }
                    ) else {

                let unread =
                    groupMessages.filter {
                        $0.senderID != userID
                    }.count

                unreadCounts[groupID] =
                    unread

                return
            }

            let nextIndex =
                groupMessages.index(
                    after: lastReadIndex
                )

            guard nextIndex <
                    groupMessages.endIndex else {

                unreadCounts[groupID] = 0
                return
            }

            let unread =
                groupMessages[
                    nextIndex...
                ]
                .filter {
                    $0.senderID != userID
                }
                .count

            unreadCounts[groupID] =
                unread

        } catch {

            lastError =
                error.localizedDescription
        }
    }

    // MARK: - Unread Count Helper

    func unreadCount(
        for groupID: UUID
    ) -> Int {

        unreadCounts[groupID] ?? 0
    }

    // MARK: - Mark Chat Read

    @MainActor
    func markChatAsRead(
        groupID: UUID,
        userID: UUID
    ) async {

        let groupMessages =
            messages
                .filter {
                    $0.groupID ==
                        groupID
                }
                .sorted {
                    $0.createdAt <
                        $1.createdAt
                }

        guard let lastMessage =
                groupMessages.last else {

            unreadCounts[groupID] = 0
            return
        }

        let payload =
            ReadStateUpsert(
                groupID: groupID,
                userID: userID,
                lastReadMessageID:
                    lastMessage.id,
                lastReadAt: Date()
            )

        do {

            try await client
                .from(
                    "group_chat_read_state"
                )
                .upsert(
                    payload,
                    onConflict:
                        "group_id,user_id"
                )
                .execute()

            unreadCounts[groupID] = 0

        } catch {

            lastError =
                error.localizedDescription
        }
    }

    // MARK: - Foreground Chat Realtime

    @MainActor
    func startRealtime(
        groupID: UUID,
        currentUserID: UUID? = nil,
        markIncomingAsRead: Bool = false
    ) async {

        await stopRealtime()

        subscribedGroupID =
            groupID

        let channel =
            client.realtimeV2.channel(
                "timeup-group-chat-\(groupID.uuidString)"
            )

        realtimeChannel =
            channel

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

                    guard let currentUserID
                    else {
                        continue
                    }

                    if markIncomingAsRead {

                        await self.markChatAsRead(
                            groupID: groupID,
                            userID:
                                currentUserID
                        )

                    } else {

                        await self.loadUnreadCount(
                            groupID: groupID,
                            userID:
                                currentUserID
                        )
                    }
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

    // MARK: - Stop Foreground Chat Realtime

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

    // MARK: - Independent Unread Realtime

    @MainActor
    func startUnreadRealtime(
        groupID: UUID,
        currentUserID: UUID
    ) async {

        if unreadSubscribedGroupID == groupID,
           unreadSubscribedUserID == currentUserID,
           unreadRealtimeChannel != nil {

            await loadUnreadCount(
                groupID: groupID,
                userID: currentUserID
            )

            return
        }

        await stopUnreadRealtime()

        unreadSubscribedGroupID =
            groupID

        unreadSubscribedUserID =
            currentUserID

        await loadUnreadCount(
            groupID: groupID,
            userID: currentUserID
        )

        let channel =
            client.realtimeV2.channel(
                "timeup-group-unread-\(groupID.uuidString)-\(currentUserID.uuidString)"
            )

        unreadRealtimeChannel =
            channel

        let insertions =
            channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "group_messages",
                filter:
                    "group_id=eq.\(groupID.uuidString)"
            )

        unreadRealtimeTask =
            Task { [weak self] in

                guard let self else {
                    return
                }

                for await _ in insertions {

                    guard !Task.isCancelled else {
                        return
                    }

                    await self.loadUnreadCount(
                        groupID: groupID,
                        userID: currentUserID
                    )
                }
            }

        do {

            try await channel.subscribe()

        } catch {

            lastError =
                error.localizedDescription

            unreadRealtimeTask?.cancel()
            unreadRealtimeTask = nil

            unreadRealtimeChannel = nil
            unreadSubscribedGroupID = nil
            unreadSubscribedUserID = nil
        }
    }

    // MARK: - Stop Independent Unread Realtime

    @MainActor
    func stopUnreadRealtime() async {

        unreadRealtimeTask?.cancel()
        unreadRealtimeTask = nil

        if let unreadRealtimeChannel {

            await client.realtimeV2
                .removeChannel(
                    unreadRealtimeChannel
                )
        }

        unreadRealtimeChannel = nil
        unreadSubscribedGroupID = nil
        unreadSubscribedUserID = nil
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

            await markChatAsRead(
                groupID: groupID,
                userID: senderID
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

    // MARK: - Clear

    @MainActor
    func clear() async {

        await stopRealtime()
        await stopUnreadRealtime()

        messages = []
        unreadCounts = [:]
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
            return
                "לא ניתן לשלוח הודעה ריקה."

        case .messageTooLong:
            return
                "הודעה יכולה להכיל עד 2,000 תווים."
        }
    }
}