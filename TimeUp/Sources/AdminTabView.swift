import SwiftUI

struct AdminTabView: View {

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    var body: some View {

        TabView {

            AdminHomeView()
                .tabItem {
                    Label(
                        homeText,
                        systemImage:
                            "square.grid.2x2.fill"
                    )
                }

            AdminGroupsView()
                .tabItem {
                    Label(
                        groupsText,
                        systemImage:
                            "person.3.fill"
                    )
                }

            AdminAIView()
                .tabItem {
                    Label(
                        "AI",
                        systemImage:
                            "sparkles"
                    )
                }

            AdminQuestionsView()
                .tabItem {
                    Label(
                        questionsText,
                        systemImage:
                            "questionmark.bubble.fill"
                    )
                }
                .badge(0)
        }
    }

    private var homeText: String {

        switch localization.language {
        case .hebrew:
            return "ראשי"
        case .english:
            return "Home"
        case .arabic:
            return "الرئيسية"
        }
    }

    private var groupsText: String {

        switch localization.language {
        case .hebrew:
            return "קבוצות"
        case .english:
            return "Groups"
        case .arabic:
            return "المجموعات"
        }
    }

    private var questionsText: String {

        switch localization.language {
        case .hebrew:
            return "שאלות"
        case .english:
            return "Questions"
        case .arabic:
            return "الأسئلة"
        }
    }
}


// MARK: - Groups

private struct AdminGroupsView: View {

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    var body: some View {

        NavigationStack {

            ContentUnavailableView(
                groupsText,
                systemImage:
                    "person.3.fill",
                description:
                    Text(
                        groupsDescription
                    )
            )
            .navigationTitle(
                groupsText
            )
        }
    }

    private var groupsText: String {

        switch localization.language {
        case .hebrew:
            return "קבוצות"
        case .english:
            return "Groups"
        case .arabic:
            return "المجموعات"
        }
    }

    private var groupsDescription: String {

        switch localization.language {
        case .hebrew:
            return "כאן יוצגו כל הקבוצות שהמנהל יצר."
        case .english:
            return "All groups created by the admin will appear here."
        case .arabic:
            return "ستظهر هنا جميع المجموعات التي أنشأها المدير."
        }
    }
}


// MARK: - AI Assistant

private struct AdminAIView: View {

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    @State private var message = ""

    var body: some View {

        NavigationStack {

            VStack(spacing: 0) {

                Spacer()

                VStack(spacing: 14) {

                    Image(
                        systemName:
                            "sparkles"
                    )
                    .font(
                        .system(size: 48)
                    )

                    Text("TimeUp AI")
                        .font(.title.bold())

                    Text(
                        aiDescription
                    )
                    .foregroundStyle(
                        .secondary
                    )
                    .multilineTextAlignment(
                        .center
                    )
                    .padding(
                        .horizontal
                    )
                }

                Spacer()

                HStack(spacing: 12) {

                    TextField(
                        askTimeUpText,
                        text: $message
                    )
                    .textFieldStyle(
                        .roundedBorder
                    )

                    Button {

                        // AI functionality
                        // will be connected later.

                    } label: {

                        Image(
                            systemName:
                                "arrow.up.circle.fill"
                        )
                        .font(
                            .system(size: 32)
                        )
                    }
                    .disabled(
                        message
                            .trimmingCharacters(
                                in:
                                    .whitespacesAndNewlines
                            )
                            .isEmpty
                    )
                }
                .padding()
            }
            .navigationTitle(
                "AI"
            )
        }
    }

    private var aiDescription: String {

        switch localization.language {
        case .hebrew:
            return "העוזר החכם של המנהל יוכל לענות על שאלות מתוך נתוני TimeUp."
        case .english:
            return "The admin's AI assistant will be able to answer questions using TimeUp data."
        case .arabic:
            return "سيتمكن المساعد الذكي للمدير من الإجابة عن الأسئلة باستخدام بيانات TimeUp."
        }
    }

    private var askTimeUpText: String {

        switch localization.language {
        case .hebrew:
            return "שאל את TimeUp..."
        case .english:
            return "Ask TimeUp..."
        case .arabic:
            return "اسأل TimeUp..."
        }
    }
}


// MARK: - Open Questions

private struct AdminQuestionsView: View {

    @ObservedObject private var localization =
        TimeUpLocalization.shared

    var body: some View {

        NavigationStack {

            ContentUnavailableView(
                noOpenQuestionsText,
                systemImage:
                    "questionmark.bubble",
                description:
                    Text(
                        questionsDescription
                    )
            )
            .navigationTitle(
                questionsTitle
            )
        }
    }

    private var questionsTitle: String {

        switch localization.language {
        case .hebrew:
            return "שאלות"
        case .english:
            return "Questions"
        case .arabic:
            return "الأسئلة"
        }
    }

    private var noOpenQuestionsText: String {

        switch localization.language {
        case .hebrew:
            return "אין שאלות פתוחות"
        case .english:
            return "No open questions"
        case .arabic:
            return "لا توجد أسئلة مفتوحة"
        }
    }

    private var questionsDescription: String {

        switch localization.language {
        case .hebrew:
            return "שאלות שה-AI לא יודע לענות עליהן יופיעו כאן למנהל."
        case .english:
            return "Questions the AI cannot answer will appear here for the admin."
        case .arabic:
            return "الأسئلة التي لا يستطيع الذكاء الاصطناعي الإجابة عنها ستظهر هنا للمدير."
        }
    }
}