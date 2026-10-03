import SwiftUI

struct MemberGroupChatView: View {

    let member: TimeUpMember

    @ObservedObject private var store = TimeUpStore.shared

    @State private var messageText = ""

    @FocusState private var isMessageFieldFocused: Bool

    private var currentMember: TimeUpMember {
        store.member(id: member.id) ?? member
    }

    private var group: TimeUpGroup? {
        store.groups.first {
            $0.id == currentMember.groupID
        }
    }

    private var messages: [TimeUpChatMessage] {
        store.messages(
            in: currentMember.groupID
        )
    }

    private var groupMembersCount: Int {
        store.members(
            in: currentMember.groupID
        )
        .filter {
            $0.role == .member
        }
        .count
    }

    var body: some View {

        VStack(spacing: 0) {

            if group == nil {

                ContentUnavailableView(
                    "הקבוצה לא נמצאה",
                    systemImage: "person.3"
                )

            } else {

                messagesArea

                Divider()

                composer
            }
        }
        .navigationTitle("צ׳אט קבוצתי")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            markAsRead()
        }
        .onChange(
            of: store.chatMessages.count
        ) { _, _ in
            markAsRead()
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

                    if messages.isEmpty {

                        emptyChat

                    } else {

                        ForEach(messages) { message in

                            messageRow(message)
                                .id(message.id)
                        }
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
            .font(.system(size: 34))
            .foregroundStyle(
                Color.accentColor
            )

            Text(
                group?.name ?? "הקבוצה"
            )
            .font(.headline)

            Text(
                "\(groupMembersCount) חברים בקבוצה"
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

            Image(
                systemName:
                    "bubble.left.and.bubble.right"
            )
            .font(.system(size: 42))
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
        .frame(maxWidth: .infinity)
    }

    // MARK: - Message Row

    @ViewBuilder
    private func messageRow(
        _ message: TimeUpChatMessage
    ) -> some View {

        let isMine =
            message.senderID ==
            currentMember.id

        HStack(
            alignment: .bottom,
            spacing: 8
        ) {

            if isMine {
                Spacer(minLength: 55)
            }

            if !isMine {
                avatar(for: message)
            }

            VStack(
                alignment:
                    isMine
                        ? .trailing
                        : .leading,
                spacing: 4
            ) {

                if !isMine {

                    Text(message.senderName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }

                Text(message.text)
                    .font(.body)
                    .foregroundStyle(
                        isMine
                            ? Color.white
                            : Color.primary
                    )
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
                                : Color.secondary
                                    .opacity(0.13)
                        )
                    }

                Text(
                    message.sentAt.formatted(
                        date: .omitted,
                        time: .shortened
                    )
                )
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

    // MARK: - Avatar

    private func avatar(
        for message: TimeUpChatMessage
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
                    from: message.senderName
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
                .split(separator: " ")
                .prefix(2)

        let letters =
            parts.compactMap {
                $0.first
            }

        if letters.isEmpty {
            return "?"
        }

        return String(letters)
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
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
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
                sendMessage()
            } label: {

                Image(
                    systemName:
                        "arrow.up.circle.fill"
                )
                .font(.system(size: 34))
                .foregroundStyle(
                    canSend
                        ? Color.accentColor
                        : Color.secondary
                )
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.bar)
    }

    private var canSend: Bool {

        !messageText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
    }

    // MARK: - Send

    private func sendMessage() {

        let text =
            messageText
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        guard !text.isEmpty else {
            return
        }

        store.sendMessage(
            text: text,
            from: currentMember.id
        )

        messageText = ""

        markAsRead()
    }

    // MARK: - Read State

    private func markAsRead() {

        store.markGroupChatAsRead(
            groupID:
                currentMember.groupID,
            by:
                currentMember.id
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
                .easeOut(duration: 0.2)
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
