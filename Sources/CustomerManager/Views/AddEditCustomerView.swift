import SwiftUI

// MARK: - Add / Edit Customer View

struct AddEditCustomerView: View {
    @EnvironmentObject var vm: CustomerViewModel
    @Environment(\.dismiss) private var dismiss

    var editCustomer: Customer? // nil = add mode

    // Form state
    @State private var name             = ""
    @State private var contact          = ""
    @State private var purchaseAccount  = ""
    @State private var password         = ""
    @State private var expirationDate   = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var notes            = ""
    @State private var showValidationError = false
    @State private var showPassword        = false

    private var isEditMode: Bool { editCustomer != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {

                        // ─── Mục 1: Tên ───────────────────────────────────
                        FormSection(title: "Thông tin khách hàng") {
                            FormTextField(
                                icon: "person.fill",
                                title: "Tên khách hàng",
                                placeholder: "Nhập tên (không bắt buộc)...",
                                text: $name,
                                required: false
                            )
                            SectionDivider()

                            // ─── Mục 2: Zalo / FB ─────────────────────────
                            FormTextField(
                                icon: "bubble.left.fill",
                                title: "Zalo hoặc Facebook",
                                placeholder: "SĐT Zalo / link FB...",
                                text: $contact,
                                required: true
                            )
                        }

                        // ─── Mục 3: Tài khoản mua ─────────────────────────
                        FormSection(title: "Thông tin giao dịch") {
                            FormTextField(
                                icon: "person.text.rectangle.fill",
                                title: "Tài khoản",
                                placeholder: "Nhập tài khoản...",
                                text: $purchaseAccount,
                                required: true
                            )
                            SectionDivider()

                            FormTextField(
                                icon: "lock.fill",
                                title: "Mật khẩu",
                                placeholder: "Nhập mật khẩu...",
                                text: $password,
                                required: true,
                                isSecure: true
                            )
                            SectionDivider()

                            // ─── Mục 4: Thời hạn ──────────────────────────
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar.badge.clock")
                                        .foregroundColor(AppTheme.accent)
                                        .frame(width: 22)
                                    Text("Thời hạn")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                    RequiredBadge()
                                    Spacer()
                                }
                                DatePicker("", selection: $expirationDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .colorScheme(.dark)
                                    .tint(AppTheme.accent)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 28)
                            }
                        }

                        // ─── Mục 5: Ghi chú ───────────────────────────────
                        FormSection(title: "Ghi chú") {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "note.text")
                                        .foregroundColor(AppTheme.accent)
                                        .frame(width: 22)
                                    Text("Ghi chú")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                }

                                ZStack(alignment: .topLeading) {
                                    if notes.isEmpty {
                                        Text("Thêm ghi chú về khách hàng...")
                                            .foregroundColor(AppTheme.textMuted)
                                            .padding(.top, 2)
                                            .allowsHitTesting(false)
                                    }
                                    TextEditor(text: $notes)
                                        .frame(minHeight: 90)
                                        .scrollContentBackground(.hidden)
                                        .background(Color.clear)
                                        .foregroundColor(AppTheme.textPrimary)
                                        .tint(AppTheme.accent)
                                }
                                .padding(.leading, 4)
                            }
                        }

                        // ─── Validation error ──────────────────────────────
                        if showValidationError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(AppTheme.red)
                                Text("Vui lòng điền Zalo/FB, Tài khoản và Mật khẩu (*)")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.red)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.red.opacity(0.1))
                            .cornerRadius(10)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // ─── Save Button ───────────────────────────────────────────
                        Button { Task { await save() } } {
                            HStack(spacing: 8) {
                                Image(systemName: isEditMode ? "checkmark.circle.fill" : "plus.circle.fill")
                                Text(isEditMode ? "Cập nhật khách hàng" : "Thêm khách hàng")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.accentGradient)
                            .cornerRadius(14)
                            .shadow(color: AppTheme.accent.opacity(0.4), radius: 10, y: 4)
                        }
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
            }
            .navigationTitle(isEditMode ? "Sửa khách hàng" : "Thêm khách hàng")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .onAppear(perform: populate)
        }
        .tint(AppTheme.accent)
    }

    // MARK: - Helpers

    private func populate() {
        guard let c = editCustomer else { return }
        name            = c.name
        contact         = c.contact
        purchaseAccount = c.purchaseAccount
        password        = c.password
        expirationDate  = c.expirationDate
        notes           = c.notes
    }

    private func save() async {
        guard !contact.trimmingCharacters(in: .whitespaces).isEmpty,
              !purchaseAccount.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.trimmingCharacters(in: .whitespaces).isEmpty
        else {
            withAnimation { showValidationError = true }
            return
        }

        var c               = editCustomer ?? Customer()
        c.name              = name.trimmingCharacters(in: .whitespaces)
        c.contact           = contact.trimmingCharacters(in: .whitespaces)
        c.purchaseAccount   = purchaseAccount.trimmingCharacters(in: .whitespaces)
        c.password          = password.trimmingCharacters(in: .whitespaces)
        c.expirationDate    = expirationDate
        c.notes             = notes.trimmingCharacters(in: .whitespaces)

        if isEditMode { await vm.update(c) } else { await vm.add(c) }
        dismiss()
    }
}

// MARK: - Supporting Views

struct FormSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundColor(AppTheme.textMuted)
                .tracking(1)

            VStack(spacing: 12) {
                content
            }
            .padding(14)
            .background(AppTheme.card)
            .cornerRadius(14)
        }
    }
}

struct FormTextField: View {
    let icon: String
    let title: String
    let placeholder: String
    @Binding var text: String
    let required: Bool
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.accent)
                    .frame(width: 20)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.textPrimary)
                if required { RequiredBadge() }
            }
            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(AppTheme.textPrimary)
                    .tint(AppTheme.accent)
                    .padding(.leading, 26)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(AppTheme.textPrimary)
                    .tint(AppTheme.accent)
                    .padding(.leading, 26)
            }
        }
    }
}

struct RequiredBadge: View {
    var body: some View {
        Text("Bắt buộc")
            .font(.caption2.bold())
            .foregroundColor(AppTheme.red)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(AppTheme.red.opacity(0.15))
            .cornerRadius(4)
    }
}

struct SectionDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(height: 1)
    }
}
