import SwiftUI

struct MemberGroupChatView: View {

    let group: SupabaseDataStore.TimeUpRemoteGroup

    @StateObject private var dataStore =
        SupabaseDataStore.shared

    @StateObject private var chatStore =
        SupabaseChatStore.shared

    @State private var messageText = ""
    @State private var sendError: String?

    @FocusState private var isMessageFieldFocused: Bool

    private var currentUser:
        SupabaseDataStore.TimeUpRemoteUser? {

        dataStore.currentUser
    }

    private var messages:
        [SupabaseChatStore.ChatMessage] {

        chatStore.messages(
            for: group.id
        )
    }

    var body: some View {

        VStack(spacing: 0) {

            messagesArea

            Divider()

            composer
        }
        .navigationTitle("צ׳אט קבוצתי")
        .navigationBarTitleDisplayMode(.inline)
        .task {

            await loadChat()
        }
        .refreshable {

            await loadChat()
        }
        .alert(
            "לא ניתן לשלוח הודעה",
            isPresented: Binding(
                get: {
                    sendError != nil
                },
                set: { newValue in

                    if !newValue {
                        sendError = nil
                    }
                }
            )
        ) {

            Button("אישור") {
                sendError = nil
            }

        } message: {

            Text(
                sendError ?? ""
            )
        }
    }

    // MARK: - Messages Area

    private var messagesArea: some View {

        ScrollViewReader { proxy in

            ScrollView {

                LazyVStack(
                    spacing: 10
                ) {

                    chatHeader

                    if chatStore.isLoading &&
                        messages.isEmpty {

                        ProgressView(
                            "טוען הודעות..."
                        )
                        .padding(.top, 40)

                    } else if messages.isEmpty {

                        emptyChat

                    } else {

                        ForEach(messages) { message in

                            messageRow(message)
                                .id(message.id)
                        }
                    }

                    if let error =
                        chatStore.lastError {

                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding()
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .onAppear {

                scrollToBottom(
                    proxy: proxy,
                    animated: false
                )
            }
            .onChange(
                of: messages.count
            ) { _, _ in

                scrollToBottom(
                    proxy: proxy,
                    animated: true
                )
            }
        }
    }

    // MARK: - Header

    private var chatHeader: some View {

        VStack(spacing: 6) {

            Image(
                systemName: "person.3.fill"
            )
            .font(
                .system(size: 34)
            )
            .foregroundStyle(
                Color.accentColor
            )

            Text(group.name)
                .font(.headline)

            Text(
                "\(dataStore.groupMembers.count) חברים בקבוצה"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity
        )
        .padding(.vertical, 14)
    }

    // MARK: - Empty Chat

    private var emptyChat: some View {

        VStack(spacing: 10) {

            Spacer()
                .frame(height: 50)

            Image(
                systemName:
                    "bubble.left.and.bubble.right"
            )
            .font(
                .system(size: 42)
            )
            .foregroundStyle(.secondary)

            Text("הצ׳אט עדיין ריק")
                .font(.headline)

            Text(
                "שלחו את ההודעה הראשונה לקבוצה."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(
            maxWidth: .infinity
        )
    }

    // MARK: - Message Row

    @ViewBuilder
    private func messageRow(
        _ message:
            SupabaseChatStore.ChatMessage
    ) -> some View {

        let isMine =
            message.senderID ==
            currentUser?.id

        HStack(
            alignment: .bottom,
            spacing: 8
        ) {

            if isMine {

                Spacer(
                    minLength: 55
                )
            }

            if !isMine {

                avatar(
                    senderID:
                        message.senderID
                )
            }

            VStack(
                alignment:
                    isMine
                        ? .trailing
                        : .leading,
                spacing: 4
            ) {

                if !isMine {

                    Text(
                        senderName(
                            for:
                                message.senderID
                        )
                    )
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(
                        .horizontal,
                        4
                    )
                }

                Text(message.text)
                    .font(.body)
                    .foregroundStyle(
                        isMine
                            ? Color.white
                            : Color.primary
                    )
                    .padding(
                        .horizontal,
                        13
                    )
                    .padding(
                        .vertical,
                        9
                    )
                    .background {

                        RoundedRectangle(
                            cornerRadius: 17,
                            style: .continuous
                        )
                        .fill(
                            isMine
                                ? Color.accentColor
                                : Color.secondary
                                    .opacity(0.13)
                        )
                    }

                Text(
                    message.createdAt.formatted(
                        date: .omitted,
                        time: .shortened
                    )
                )
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(
                    .horizontal,
                    4
                )
            }

            if !isMine {

                Spacer(
                    minLength: 55
                )
            }
        }
        .frame(
            maxWidth: .infinity
        )
    }

    // MARK: - Sender

    private func senderName(
        for senderID: UUID
    ) -> String {

        if senderID ==
            currentUser?.id {

            return
                currentUser?
                    .displayName ??
                "אתה"
        }

        if let member =
            dataStore.groupMembers.first(
                where: {
                    $0.id == senderID
                }
            ) {

            return
                member.displayName ??
                "חבר קבוצה"
        }

        return "חבר קבוצה"
    }

    // MARK: - Avatar

    private func avatar(
        senderID: UUID
    ) -> some View {

        ZStack {

            Circle()
                .fill(
                    Color.secondary
                        .opacity(0.14)
                )
                .frame(
                    width: 30,
                    height: 30
                )

            Text(
                initials(
                    from:
                        senderName(
                            for:
                                senderID
                        )
                )
            )
            .font(.caption2)
            .fontWeight(.bold)
        }
    }

    private func initials(
        from name: String
    ) -> String {

        let parts =
            name
                .split(
                    separator: " "
                )
                .prefix(2)

        let letters =
            parts.compactMap {
                $0.first
            }

        guard !letters.isEmpty
        else {
            return "?"
        }

        return
            String(letters)
                .uppercased()
    }

    // MARK: - Composer

    private var composer: some View {

        HStack(
            alignment: .bottom,
            spacing: 10
        ) {

            TextField(
                "הודעה לקבוצה...",
                text: $messageText,
                axis: .vertical
            )
            .lineLimit(1...5)
            .textFieldStyle(.plain)
            .focused(
                $isMessageFieldFocused
            )
            .padding(
                .horizontal,
                14
            )
            .padding(
                .vertical,
                10
            )
            .background {

                RoundedRectangle(
                    cornerRadius: 20,
                    style: .continuous
                )
                .fill(
                    Color.secondary
                        .opacity(0.12)
                )
            }

            Button {

                Task {
                    await sendMessage()
                }

            } label: {

                if chatStore.isSending {

                    ProgressView()
                        .frame(
                            width: 34,
                            height: 34
                        )

                } else {

                    Image(
                        systemName:
                            "arrow.up.circle.fill"
                    )
                    .font(
                        .system(size: 34)
                    )
                    .foregroundStyle(
                        canSend
                            ? Color.accentColor
                            : Color.secondary
                    )
                }
            }
            .buttonStyle(.plain)
            .disabled(
                !canSend ||
                chatStore.isSending
            )
        }
        .padding(
            .horizontal,
            12
        )
        .padding(
            .vertical,
            9
        )
        .background(.bar)
    }

    private var canSend: Bool {

        guard currentUser != nil
        else {
            return false
        }

        let cleanText =
            messageText
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        return
            !cleanText.isEmpty &&
            cleanText.count <= 2000
    }

    // MARK: - Send

    @MainActor
    private func sendMessage() async {

        guard
            let currentUser
        else {

            sendError =
                "המשתמש לא נטען."

            return
        }

        let text =
            messageText
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        guard !text.isEmpty
        else {
            return
        }

        do {

            try await chatStore.sendMessage(
                groupID: group.id,
                senderID:
                    currentUser.id,
                text: text
            )

            messageText = ""

        } catch {

            sendError =
                error.localizedDescription
        }
    }

    // MARK: - Load

    @MainActor
    private func loadChat() async {

        async let membersTask: Void =
            dataStore.loadGroupMembers(
                groupID: group.id
            )

        async let messagesTask: Void =
            chatStore.loadMessages(
                groupID: group.id
            )

        _ = await (
            membersTask,
            messagesTask
        )
    }

    // MARK: - Scroll

    private func scrollToBottom(
        proxy: ScrollViewProxy,
        animated: Bool
    ) {

        guard
            let lastMessage =
                messages.last
        else {
            return
        }

        if animated {

            withAnimation(
                .easeOut(
                    duration: 0.2
                )
            ) {

                proxy.scrollTo(
                    lastMessage.id,
                    anchor: .bottom
                )
            }

        } else {

            proxy.scrollTo(
                lastMessage.id,
                anchor: .bottom
            )
        }
    }
}