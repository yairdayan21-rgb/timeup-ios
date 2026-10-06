import SwiftUI

struct MemberGroupChatView: View {

    let group: SupabaseDataStore.TimeUpRemoteGroup

    @StateObject private var dataStore =
        SupabaseDataStore.shared

    @StateObject private var chatStore =
        SupabaseChatStore.shared

    @ObservedObject private var localization =
        TimeUpLocalization.shared

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
        .navigationTitle(
            groupChatTitle
        )
        .navigationBarTitleDisplayMode(
            .inline
        )

        // MARK: - Load + Read State + Realtime

        .task {

            await openChat()
        }

        // MARK: - Pull To Refresh

        .refreshable {

            await refreshChat()
        }

        // MARK: - Stop Realtime

        .onDisappear {

            Task {

                await chatStore.stopRealtime()
            }
        }

        // MARK: - Send Error

        .alert(
            sendErrorTitle,
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

            Button(
                okText
            ) {

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
                            loadingMessagesText
                        )
                        .padding(
                            .top,
                            40
                        )

                    } else if messages.isEmpty {

                        emptyChat

                    } else {

                        ForEach(
                            messages
                        ) { message in

                            messageRow(
                                message
                            )
                            .id(
                                message.id
                            )
                        }
                    }

                    if let error =
                        chatStore.lastError {

                        Text(error)
                            .font(.caption)
                            .foregroundStyle(
                                .red
                            )
                            .padding()
                    }
                }
                .padding(
                    .horizontal,
                    14
                )
                .padding(
                    .vertical,
                    12
                )
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

        VStack(
            spacing: 6
        ) {

            Image(
                systemName:
                    "person.3.fill"
            )
            .font(
                .system(
                    size: 34
                )
            )
            .foregroundStyle(
                Color.accentColor
            )

            Text(
                group.name
            )
            .font(.headline)

            Text(
                groupMembersCountText(
                    dataStore
                        .groupMembers
                        .count
                )
            )
            .font(.caption)
            .foregroundStyle(
                .secondary
            )
        }
        .frame(
            maxWidth: .infinity
        )
        .padding(
            .vertical,
            14
        )
    }

    // MARK: - Empty Chat

    private var emptyChat: some View {

        VStack(
            spacing: 10
        ) {

            Spacer()
                .frame(
                    height: 50
                )

            Image(
                systemName:
                    "bubble.left.and.bubble.right"
            )
            .font(
                .system(
                    size: 42
                )
            )
            .foregroundStyle(
                .secondary
            )

            Text(
                emptyChatTitle
            )
            .font(.headline)

            Text(
                emptyChatDescription
            )
            .font(.subheadline)
            .foregroundStyle(
                .secondary
            )
            .multilineTextAlignment(
                .center
            )
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
                    .fontWeight(
                        .semibold
                    )
                    .foregroundStyle(
                        .secondary
                    )
                    .padding(
                        .horizontal,
                        4
                    )
                }

                Text(
                    message.text
                )
                .font(.body)
                .foregroundStyle(
                    isMine
                        ? Color.white
                        : Color.primary
                )
                .multilineTextAlignment(
                    .leading
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
                    formattedMessageTime(
                        message.createdAt
                    )
                )
                .font(.caption2)
                .foregroundStyle(
                    .tertiary
                )
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
                youText
        }

        if let member =
            dataStore
                .groupMembers
                .first(
                    where: {
                        $0.id ==
                            senderID
                    }
                ) {

            return
                member.displayName ??
                groupMemberText
        }

        return groupMemberText
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
                messagePlaceholder,
                text: $messageText,
                axis: .vertical
            )
            .lineLimit(1...5)
            .textFieldStyle(
                .plain
            )
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
                        .system(
                            size: 34
                        )
                    )
                    .foregroundStyle(
                        canSend
                            ? Color.accentColor
                            : Color.secondary
                    )
                }
            }
            .buttonStyle(
                .plain
            )
            .disabled(
                !canSend ||
                chatStore.isSending
            )
            .accessibilityLabel(
                sendText
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
        .background(
            .bar
        )
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

        guard let currentUser
        else {

            sendError =
                userNotLoadedText

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

            try await chatStore
                .sendMessage(
                    groupID:
                        group.id,
                    senderID:
                        currentUser.id,
                    text:
                        text
                )

            messageText = ""

            await chatStore
                .markChatAsRead(
                    groupID:
                        group.id,
                    userID:
                        currentUser.id
                )

        } catch {

            sendError =
                error.localizedDescription
        }
    }

    // MARK: - Open Chat

    @MainActor
    private func openChat() async {

        async let membersTask: Void =
            dataStore
                .loadGroupMembers(
                    groupID:
                        group.id
                )

        async let messagesTask: Void =
            chatStore
                .loadMessages(
                    groupID:
                        group.id
                )

        _ = await (
            membersTask,
            messagesTask
        )

        guard let currentUser
        else {
            return
        }

        await chatStore
            .markChatAsRead(
                groupID:
                    group.id,
                userID:
                    currentUser.id
            )

        await chatStore
            .startRealtime(
                groupID:
                    group.id,
                currentUserID:
                    currentUser.id,
                markIncomingAsRead:
                    true
            )
    }

    // MARK: - Refresh

    @MainActor
    private func refreshChat() async {

        await chatStore
            .loadMessages(
                groupID:
                    group.id
            )

        guard let currentUser
        else {
            return
        }

        await chatStore
            .markChatAsRead(
                groupID:
                    group.id,
                userID:
                    currentUser.id
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

    // MARK: - Formatting

    private func formattedMessageTime(
        _ date: Date
    ) -> String {

        let formatter =
            DateFormatter()

        formatter.locale =
            localization
                .language
                .locale

        formatter.timeStyle =
            .short

        formatter.dateStyle =
            .none

        return formatter.string(
            from: date
        )
    }

    private func groupMembersCountText(
        _ count: Int
    ) -> String {

        switch localization.language {

        case .hebrew:
            return "\(count) חברים בקבוצה"

        case .english:
            return count == 1
                ? "1 member in the group"
                : "\(count) members in the group"

        case .arabic:
            return "\(count) أعضاء في المجموعة"
        }
    }

    // MARK: - Localization

    private var groupChatTitle: String {

        switch localization.language {

        case .hebrew:
            return "צ׳אט קבוצתי"

        case .english:
            return "Group Chat"

        case .arabic:
            return "دردشة المجموعة"
        }
    }

    private var sendErrorTitle: String {

        switch localization.language {

        case .hebrew:
            return "לא ניתן לשלוח הודעה"

        case .english:
            return "Unable to Send Message"

        case .arabic:
            return "تعذر إرسال الرسالة"
        }
    }

    private var okText: String {

        switch localization.language {

        case .hebrew:
            return "אישור"

        case .english:
            return "OK"

        case .arabic:
            return "موافق"
        }
    }

    private var loadingMessagesText: String {

        switch localization.language {

        case .hebrew:
            return "טוען הודעות..."

        case .english:
            return "Loading messages..."

        case .arabic:
            return "جارٍ تحميل الرسائل..."
        }
    }

    private var emptyChatTitle: String {

        switch localization.language {

        case .hebrew:
            return "הצ׳אט עדיין ריק"

        case .english:
            return "The Chat Is Empty"

        case .arabic:
            return "الدردشة فارغة"
        }
    }

    private var emptyChatDescription: String {

        switch localization.language {

        case .hebrew:
            return "שלחו את ההודעה הראשונה לקבוצה."

        case .english:
            return "Send the first message to the group."

        case .arabic:
            return "أرسل أول رسالة إلى المجموعة."
        }
    }

    private var messagePlaceholder: String {

        switch localization.language {

        case .hebrew:
            return "הודעה לקבוצה..."

        case .english:
            return "Message the group..."

        case .arabic:
            return "رسالة إلى المجموعة..."
        }
    }

    private var sendText: String {

        switch localization.language {

        case .hebrew:
            return "שלח הודעה"

        case .english:
            return "Send Message"

        case .arabic:
            return "إرسال الرسالة"
        }
    }

    private var youText: String {

        switch localization.language {

        case .hebrew:
            return "אתה"

        case .english:
            return "You"

        case .arabic:
            return "أنت"
        }
    }

    private var groupMemberText: String {

        switch localization.language {

        case .hebrew:
            return "חבר קבוצה"

        case .english:
            return "Group Member"

        case .arabic:
            return "عضو في المجموعة"
        }
    }

    private var userNotLoadedText: String {

        switch localization.language {

        case .hebrew:
            return "המשתמש לא נטען."

        case .english:
            return "The user could not be loaded."

        case .arabic:
            return "تعذر تحميل المستخدم."
        }
    }
}