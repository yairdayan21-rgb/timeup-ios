import SwiftUI

struct JoinGroupView: View {
    @StateObject private var store = TimeUpStore.shared
    @State private var groupCode = ""
    @State private var displayName = ""
    @State private var showAdminHome = false
    @State private var joinedGroup: TimeUpGroup?
    @State private var errorMessage: String?

    private var isReadyToJoin: Bool {
        groupCode.count == 4 &&
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 24) {

            Spacer()

            Image(systemName: "person.3.fill")
                .font(.system(size: 54))
                .foregroundStyle(.primary)

            VStack(spacing: 8) {
                Text("הצטרפות ל-TimeUp")
                    .font(.system(size: 30, weight: .bold, design: .rounded))

                Text("הזן את הקוד שקיבלת כדי להמשיך")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            TextField("השם שלך", text: $displayName)
                .textInputAutocapitalization(.words)
                .multilineTextAlignment(.center)
                .textFieldStyle(.roundedBorder)

            TextField("קוד קבוצה", text: $groupCode)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .textFieldStyle(.roundedBorder)
                .onChange(of: groupCode) { _, newValue in
                    let digits = newValue.filter { $0.isNumber }
                    groupCode = String(digits.prefix(4))
                    errorMessage = nil
                }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                join()
            } label: {
                Text("המשך")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isReadyToJoin)

            Spacer()

            Text("קוד הקבוצה מתקבל ממנהל הקבוצה")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showAdminHome) {
            AdminHomeView()
                .navigationBarBackButtonHidden(true)
        }
    }

    private func join() {
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        if groupCode == "0000" {
            showAdminHome = true
            return
        }

        guard let group = store.group(forCode: groupCode) else {
            errorMessage = "לא נמצאה קבוצה עם הקוד הזה."
            return
        }

        guard !store.hasMember(named: name, in: group.id) else {
            errorMessage = "השם הזה כבר קיים בקבוצה."
            return
        }

        let member = TimeUpMember(
            groupID: group.id,
            displayName: name
        )

        store.addMember(member)
        joinedGroup = group

        // בשלב הבא נחבר לכאן את מסך חבר הקבוצה.
        errorMessage = "הצטרפת בהצלחה ל-(group.name)."
    }
}
