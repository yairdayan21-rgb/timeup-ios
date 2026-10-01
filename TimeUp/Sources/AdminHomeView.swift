import SwiftUI

struct AdminHomeView: View {
    @State private var showCreateGroup = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    VStack(alignment: .leading, spacing: 4) {
                        Text("TimeUp")
                            .font(.system(size: 34, weight: .bold, design: .rounded))

                        Text("ניהול הקבוצות שלך")
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        showCreateGroup = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)

                            Text("יצירת קבוצה חדשה")
                                .fontWeight(.semibold)

                            Spacer()

                            Image(systemName: "chevron.left")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("הקבוצות שלי")
                            .font(.title3.bold())

                        ContentUnavailableView(
                            "עדיין אין קבוצות",
                            systemImage: "person.3",
                            description: Text("צור את הקבוצה הראשונה שלך כדי להתחיל.")
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                    }

                    Spacer()
                }
                .padding(20)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // הגדרות מנהל – נחבר בהמשך
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .navigationDestination(isPresented: $showCreateGroup) {
                CreateGroupView()
            }
        }
    }
}
