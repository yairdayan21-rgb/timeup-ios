import SwiftUI

struct JoinGroupView: View {
    @State private var groupCode = ""
    @State private var showNextScreen = false

    private var isCodeValid: Bool {
        groupCode.count == 4
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

            TextField("0000", text: $groupCode)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .textFieldStyle(.roundedBorder)
                .onChange(of: groupCode) { _, newValue in
                    let digits = newValue.filter { $0.isNumber }
                    groupCode = String(digits.prefix(4))
                }

            Button {
                showNextScreen = true
            } label: {
                Text("המשך")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isCodeValid)

            Spacer()

            Text("קוד הקבוצה מתקבל ממנהל הקבוצה")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
