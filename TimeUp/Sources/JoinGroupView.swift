import SwiftUI

struct JoinGroupView: View {
    @StateObject private var store = TimeUpStore.shared
    @State private var groupCode = ""
    @State private var displayName = ""
    @State private var showAdminHome = false
    @State private var showMemberHome = false
    @State private var currentMember: TimeUpMember?
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field {
        case displayName
        case groupCode
    }

    private var isReadyToJoin: Bool {
        groupCode.count == 4 &&
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 54))
                    .padding(.top, 32)

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
                    .focused($focusedField, equals: .displayName)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .groupCode
                    }

                TextField("קוד קבוצה", text: $groupCode)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .groupCode)
                    .onChange(of: groupCode) { _, newValue in
                        groupCode = String(newValue.filter { $0.isNumber }.prefix(4))
                        errorMessage = nil
                    }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("join-error")
                }

                Button("המשך") {
                    focusedField = nil
                    join()
                }
                .accessibilityIdentifier("join-button")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .buttonStyle(.borderedProminent)
                .disabled(!isReadyToJoin)

                Text("קוד הקבוצה מתקבל ממנהל הקבוצה")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("סיום") {
                    focusedField = nil
                }
            }
        }
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
