import SwiftUI

struct MemberGroupChatView: View {

    let group: SupabaseDataStore.TimeUpRemoteGroup

    @StateObject private var dataStore =
        SupabaseDataStore.shared

    @StateObject private var chatStore =
        SupabaseChatStore.shared

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    @State private var messageText: String
    @State private var sendError: String?
    @State private var pendingSuggestion: String?
    @State private var showReplaceDraftConfirmation = false

    @FocusState private var isMessageFieldFocused: Bool

    init(
        group: SupabaseDataStore.TimeUpRemoteGroup,
        initialDraft: String = ""
    ) {
        self.group = group
        _messageText = State(initialValue: initialDraft)
    }

    private enum Encouragement: String, CaseIterable, Identifiable {
        case together
        case walk
        case appreciation

        var id: String {
            rawValue
        }

        var icon: String {
            switch self {
            case .together:
                return "hands.clap"
            case .walk:
                return "figure.walk"
            case .appreciation:
                return "heart"
            }
        }
    }

    private var currentUser: SupabaseDataStore.TimeUpRemoteUser? {
        dataStore.currentUser
    }

    private var messages: [SupabaseChatStore.ChatMessage] {
        chatStore.messages(for: group.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            messagesArea

            Divider()

            encouragementSuggestions

            composer
        }
        .navigationTitle(groupChatTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await openChat()
        }
        .refreshable {
            await refreshChat()
        }
        .onDisappear {
            Task {
                await chatStore.stopRealtime()
            }
        }
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
            Button(okText) {
                sendError = nil
            }
        } message: {
            Text(sendError ?? "")
        }
        .confirmationDialog(
            replaceDraftTitle,
            isPresented: $showReplaceDraftConfirmation,
            titleVisibility: .visible
        ) {
            Button(replaceDraftText) {
                guard let pendingSuggestion else {
                    return
                }

                applySuggestion(pendingSuggestion)
            }

            Button(cancelText, role: .cancel) {
                pendingSuggestion = nil
            }
        } message: {
            Text(replaceDraftDescription)
        }
    }

    // MARK: - Messages Area

    private var messagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    chatHeader

                    if chatStore.isLoading && messages.isEmpty {
                        ProgressView(loadingMessagesText)
                            .padding(.top, 40)

                    } else if messages.isEmpty {
                        emptyChat

                    } else {
                        ForEach(messages) { message in
                            messageRow(message)
                                .id(message.id)
                        }
                    }

                    if let error = chatStore.lastError {
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
            .onChange(of: messages.count) { _, _ in
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
            Image(systemName: "person.3.fill")
                .font(.system(size: 34))
                .foregroundStyle(Color.accentColor)

            Text(group.name)
                .font(.headline)

            Text(
                groupMembersCountText(
                    dataStore.groupMembers.count
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }

    // MARK: - Empty Chat

    private var emptyChat: some View {
        VStack(spacing: 10) {
            Spacer()
                .frame(height: 50)

            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 42))
                .foregroundStyle(.secondary)

            Text(emptyChatTitle)
                .font(.headline)

            Text(emptyChatDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Message Row

    @ViewBuilder
    private func messageRow(
        _ message: SupabaseChatStore.ChatMessage
    ) -> some View {
        let isMine = message.senderID == currentUser?.id

        HStack(alignment: .bottom, spacing: 8) {
            if isMine {
                Spacer(minLength: 55)
            }

            if !isMine {
                avatar(senderID: message.senderID)
            }

            VStack(
                alignment: isMine ? .trailing : .leading,
                spacing: 4
            ) {
                if !isMine {
                    Text(senderName(for: message.senderID))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }

                Text(message.text)
                    .font(.body)
                    .foregroundStyle(
                        isMine ? Color.white : Color.primary
                    )
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                    .background {
                        RoundedRectangle(
                            cornerRadius: 17,
                            style: .continuous
                        )
                        .fill(
                            isMine
                                ? Color.accentColor
                                : Color.secondary.opacity(0.13)
                        )
                    }

                Text(formattedMessageTime(message.createdAt))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
            }

            if !isMine {
                Spacer(minLength: 55)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Sender

    private func senderName(
        for senderID: UUID
    ) -> String {
        if senderID == currentUser?.id {
            return currentUser?.displayName ?? youText
        }

        if let member = dataStore.groupMembers.first(
            where: { $0.id == senderID }
        ) {
            return member.displayName ?? groupMemberText
        }

        return groupMemberText
    }

    private func avatar(
        senderID: UUID
    ) -> some View {
        ZStack {
            Circle()
                .fill(Color.secondary.opacity(0.14))
                .frame(width: 30, height: 30)

            Text(
                initials(
                    from: senderName(for: senderID)
                )
            )
            .font(.caption2)
            .fontWeight(.bold)
        }
    }

    private func initials(
        from name: String
    ) -> String {
        let parts = name
            .split(separator: " ")
            .prefix(2)

        let letters = parts.compactMap {
            $0.first
        }

        guard !letters.isEmpty else {
            return "?"
        }

        return String(letters).uppercased()
    }

    // MARK: - Quick Encouragement

    private var encouragementSuggestions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(quickEncouragementTitle)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Encouragement.allCases) { suggestion in
                        Button {
                            chooseSuggestion(suggestion)
                        } label: {
                            Label(
                                suggestionTitle(suggestion),
                                systemImage: suggestion.icon
                            )
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Color.accentColor.opacity(0.08),
                                in: Capsule()
                            )
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.accentColor)
                        .disabled(
                            currentUser == nil || chatStore.isSending
                        )
                        .accessibilityIdentifier(
                            "encouragement-\(suggestion.rawValue)"
                        )
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 3)
    }

    private func chooseSuggestion(
        _ suggestion: Encouragement
    ) {
        guard currentUser != nil, !chatStore.isSending else {
            return
        }

        let text = suggestionMessage(suggestion)
        let existingText = messageText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if existingText.isEmpty || existingText == text {
            applySuggestion(text)
        } else {
            pendingSuggestion = text
            isMessageFieldFocused = false
            showReplaceDraftConfirmation = true
        }
    }

    private func applySuggestion(
        _ text: String
    ) {
        messageText = text
        pendingSuggestion = nil
        isMessageFieldFocused = true
    }

    private func suggestionTitle(
        _ suggestion: Encouragement
    ) -> String {
        switch suggestion {
        case .together:
            return localized(
                "מצליחים ביחד",
                "Together",
                "ننجح معًا"
            )

        case .walk:
            return localized(
                "הליכה ביחד",
                "Walk together",
                "نمشي معًا"
            )

        case .appreciation:
            return localized(
                "מילה טובה",
                "Appreciation",
                "كلمة طيبة"
            )
        }
    }

    private func suggestionMessage(
        _ suggestion: Encouragement
    ) -> String {
        switch suggestion {
        case .together:
            return localized(
                "בואו נעזור אחד לשני לעמוד ביעד היום. כל רגע בלי מסך עוזר לכולנו!",
                "Let's help each other meet today's target. Every moment away from screens helps us all!",
                "لنساعد بعضنا على تحقيق هدف اليوم. كل لحظة بعيدًا عن الشاشات تساعدنا جميعًا!"
            )

        case .walk:
            return localized(
                "מי מצטרף להליכה בלי מסכים? נעשה משהו טוב לעצמנו ולקבוצה.",
                "Who wants to join a screen-free walk? Let's do something good for ourselves and the group.",
                "من ينضم إلى مشي دون شاشات؟ لنفعل شيئًا جيدًا لأنفسنا وللمجموعة."
            )

        case .appreciation:
            return localized(
                "כיף להיות בקבוצה שעוזרת אחד לשני. תודה שאתם חלק מזה!",
                "It's good to be in a group that supports each other. Thanks for being part of it!",
                "من الجميل أن نكون في مجموعة يدعم أفرادها بعضهم. شكرًا لأنكم جزء منها!"
            )
        }
    }

    // MARK: - Composer

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField(
                messagePlaceholder,
                text: $messageText,
                axis: .vertical
            )
            .lineLimit(1...5)
            .textFieldStyle(.plain)
            .focused($isMessageFieldFocused)
            .disabled(chatStore.isSending)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(
                    cornerRadius: 20,
                    style: .continuous
                )
                .fill(Color.secondary.opacity(0.12))
            }
            .accessibilityIdentifier("chat-message-field")

            Button {
                Task {
                    await sendMessage()
                }
            } label: {
                if chatStore.isSending {
                    ProgressView()
                        .frame(width: 34, height: 34)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(
                            canSend
                                ? Color.accentColor
                                : Color.secondary
                        )
                }
            }
            .buttonStyle(.plain)
            .disabled(!canSend || chatStore.isSending)
            .accessibilityLabel(sendText)
            .accessibilityIdentifier("chat-send-button")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.bar)
    }

    private var canSend: Bool {
        guard currentUser != nil else {
            return false
        }

        let cleanText = messageText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return !cleanText.isEmpty && cleanText.count <= 2000
    }

    // MARK: - Send

    @MainActor
    private func sendMessage() async {
        guard !chatStore.isSending else {
            return
        }

        guard let currentUser else {
            sendError = userNotLoadedText
            return
        }

        guard canSend else {
            return
        }

        let text = messageText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        do {
            try await chatStore.sendMessage(
                groupID: group.id,
                senderID: currentUser.id,
                text: text
            )

            messageText = ""

            await chatStore.markChatAsRead(
                groupID: group.id,
                userID: currentUser.id
            )

        } catch {
            sendError = error.localizedDescription
        }
    }

    // MARK: - Open Chat

    @MainActor
    private func openChat() async {
        async let membersTask: Void =
            dataStore.loadGroupMembers(groupID: group.id)

        async let messagesTask: Void =
            chatStore.loadMessages(groupID: group.id)

        _ = await (membersTask, messagesTask)

        guard let currentUser else {
            return
        }

        await chatStore.markChatAsRead(
            groupID: group.id,
            userID: currentUser.id
        )

        await chatStore.startRealtime(
            groupID: group.id,
            currentUserID: currentUser.id,
            markIncomingAsRead: true
        )
    }

    @MainActor
    private func refreshChat() async {
        await chatStore.loadMessages(groupID: group.id)

        guard let currentUser else {
            return
        }

        await chatStore.markChatAsRead(
            groupID: group.id,
            userID: currentUser.id
        )
    }

    // MARK: - Scroll

    private func scrollToBottom(
        proxy: ScrollViewProxy,
        animated: Bool
    ) {
        guard let lastMessage = messages.last else {
            return
        }

        if animated {
            withAnimation(.easeOut(duration: 0.2)) {
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
        let formatter = DateFormatter()
        formatter.locale = localization.language.locale
        formatter.timeStyle = .short
        formatter.dateStyle = .none

        return formatter.string(from: date)
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

    private func localized(
        _ hebrew: String,
        _ english: String,
        _ arabic: String
    ) -> String {
        switch localization.language {
        case .hebrew:
            return hebrew
        case .english:
            return english
        case .arabic:
            return arabic
        }
    }

    private var quickEncouragementTitle: String {
        localized(
            "עידוד מהיר — בחר, ערוך ושלח",
            "Quick encouragement — choose, edit and send",
            "تشجيع سريع — اختر وعدّل وأرسل"
        )
    }

    private var replaceDraftTitle: String {
        localized(
            "להחליף את הטיוטה?",
            "Replace your draft?",
            "هل تريد استبدال المسودة؟"
        )
    }

    private var replaceDraftDescription: String {
        localized(
            "כבר כתבת הודעה. אפשר לשמור אותה או להחליף אותה בהצעת העידוד.",
            "You already have a draft. You can keep it or replace it with the encouragement suggestion.",
            "لديك مسودة بالفعل. يمكنك الاحتفاظ بها أو استبدالها باقتراح التشجيع."
        )
    }

    private var replaceDraftText: String {
        localized(
            "החלף בהצעה",
            "Use suggestion",
            "استخدم الاقتراح"
        )
    }

    private var cancelText: String {
        localized(
            "ביטול",
            "Cancel",
            "إلغاء"
        )
    }

    private var groupChatTitle: String {
        localized(
            "צ׳אט קבוצתי",
            "Group Chat",
            "دردشة المجموعة"
        )
    }

    private var sendErrorTitle: String {
        localized(
            "לא ניתן לשלוח הודעה",
            "Unable to Send Message",
            "تعذر إرسال الرسالة"
        )
    }

    private var okText: String {
        localized(
            "אישור",
            "OK",
            "موافق"
        )
    }

    private var loadingMessagesText: String {
        localized(
            "טוען הודעות...",
            "Loading messages...",
            "جارٍ تحميل الرسائل..."
        )
    }

    private var emptyChatTitle: String {
        localized(
            "הצ׳אט עדיין ריק",
            "The Chat Is Empty",
            "الدردشة فارغة"
        )
    }

    private var emptyChatDescription: String {
        localized(
            "שלחו את ההודעה הראשונה לקבוצה.",
            "Send the first message to the group.",
            "أرسل أول رسالة إلى المجموعة."
        )
    }

    private var messagePlaceholder: String {
        localized(
            "הודעה לקבוצה...",
            "Message the group...",
            "رسالة إلى المجموعة..."
        )
    }

    private var sendText: String {
        localized(
            "שלח הודעה",
            "Send Message",
            "إرسال الرسالة"
        )
    }

    private var youText: String {
        localized(
            "אתה",
            "You",
            "أنت"
        )
    }

    private var groupMemberText: String {
        localized(
            "חבר קבוצה",
            "Group Member",
            "عضو في المجموعة"
        )
    }

    private var userNotLoadedText: String {
        localized(
            "המשתמש לא נטען.",
            "The user could not be loaded.",
            "تعذر تحميل المستخدم."
        )
    }
}