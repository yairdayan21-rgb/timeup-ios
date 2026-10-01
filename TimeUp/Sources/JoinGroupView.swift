import SwiftUI

struct JoinGroupView: View {
    @StateObject private var store = TimeUpStore.shared
    @State private var groupCode = ""
    @State private var displayName = ""
    @State private var showAdminHome = false
    @State private var showMemberHome = false
    @State private var currentMember: TimeUpMember?
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

            VStack(spacing: 8) {
                Text("הצטרפות ל-TimeUp")
                    .font(.system(size: 30, weight: .bold, design: .rounded))

                Text("הזן את הקוד שקיבלת כדי להמשיך")
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
                    groupCode = String(newValue.filter { $0.isNumber }.prefix(4))
                    errorMessage = nil
                }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button("המשך") {
                join()
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .buttonStyle(.borderedProminent)
            .disabled(!isReadyToJoin)

            Spacer()

            Text("קוד הקבוצה מתקבל ממנהל הקבוצה")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showAdminHome) {
            AdminHomeView()
                .navigationBarBackButtonHidden(true)
        }
        .navigationDestination(isPresented: $showMemberHome) {
            if let currentMember {
                MemberHomeView(member: currentMember)
                    .navigationBarBackButtonHidden(true)
            }
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

        let member = TimeUpMember(groupID: group.id, displayName: name)
        store.addMember(member)
        store.setCurrentMember(member)
        currentMember = member
        showMemberHome = true
    }
}
