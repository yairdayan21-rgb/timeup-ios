import SwiftUI

struct AdminTabView: View {

    var body: some View {
        TabView {

            AdminHomeView()
                .tabItem {
                    Label("ראשי", systemImage: "square.grid.2x2.fill")
                }

            AdminGroupsView()
                .tabItem {
                    Label("קבוצות", systemImage: "person.3.fill")
                }

            AdminAIView()
                .tabItem {
                    Label("AI", systemImage: "sparkles")
                }

            AdminQuestionsView()
                .tabItem {
                    Label("שאלות", systemImage: "questionmark.bubble.fill")
                }
                .badge(0)
        }
    }
}


// MARK: - Groups

private struct AdminGroupsView: View {

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "קבוצות",
                systemImage: "person.3.fill",
                description: Text(
                    "כאן יוצגו כל הקבוצות שהמנהל יצר."
                )
            )
            .navigationTitle("קבוצות")
        }
    }
}


// MARK: - AI Assistant

private struct AdminAIView: View {

    @State private var message = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                Spacer()

                VStack(spacing: 14) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))

                    Text("TimeUp AI")
                        .font(.title.bold())

                    Text(
                        "העוזר החכם של המנהל יוכל לענות על שאלות מתוך נתוני TimeUp."
                    )
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                }

                Spacer()

                HStack(spacing: 12) {

                    TextField(
                        "שאל את TimeUp...",
                        text: $message
                    )
                    .textFieldStyle(.roundedBorder)

                    Button {
                        // נחבר ל-AI בהמשך
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                    }
                    .disabled(
                        message.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    )
                }
                .padding()
            }
            .navigationTitle("AI")
        }
    }
}


// MARK: - Open Questions

private struct AdminQuestionsView: View {

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "אין שאלות פתוחות",
                systemImage: "questionmark.bubble",
                description: Text(
                    "שאלות שה-AI לא יודע לענות עליהן יופיעו כאן למנהל."
                )
            )
            .navigationTitle("שאלות")
        }
    }
}
