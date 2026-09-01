import SwiftUI

// MARK: - Customer Detail View

struct CustomerDetailView: View {
    @EnvironmentObject var vm: CustomerViewModel
    @Environment(\.dismiss) private var dismiss

    let customer: Customer

    @State private var showEdit        = false
    @State private var showDeleteAlert = false

    // Always read from vm for live updates after edit
    private var c: Customer {
        vm.customers.first { $0.id == customer.id } ?? customer
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {

                        // ── Header Card ──────────────────────────────────
                        VStack(spacing: 14) {
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accentGradient)
                                    .frame(width: 80, height: 80)
                                    .shadow(color: AppTheme.accent.opacity(0.5), radius: 12, y: 4)
                                Text(c.initials)
                                    .font(.title.bold())
                                    .foregroundColor(.white)
                            }

                            Text(c.name.isEmpty ? "(Chưa có tên)" : c.name)
                                .font(.title2.bold())
                                .foregroundColor(AppTheme.textPrimary)

                            // Status badge
                            HStack(spacing: 6) {
                                Image(systemName: c.status.icon)
                                Text(c.status.label)
                                    .font(.subheadline.bold())
                            }
                            .foregroundColor(c.status.color)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(c.status.color.opacity(0.13))
                            .cornerRadius(20)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .background(AppTheme.card)
                        .cornerRadius(16)

                        // ── Days Remaining Banner ────────────────────────
                        HStack(spacing: 12) {
                            Image(systemName: c.status == .expired ? "calendar.badge.exclamationmark" : "timer")
                                .font(.title2)
                                .foregroundColor(c.status.color)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(c.status == .expired ? "Đã hết hạn" : "Số ngày còn lại")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                                Text(c.status == .expired
                                     ? expirationAgoText
                                     : "\(c.daysRemaining) ngày")
                                    .font(.title2.bold())
                                    .foregroundColor(c.status.color)
                            }

                            Spacer()

                            Text(c.expirationDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption.weight(.semibold))
                                .foregroundColor(AppTheme.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(c.status.color.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .padding(16)
                        .background(AppTheme.card)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(c.status.color.opacity(0.25), lineWidth: 1)
                        )

                        // ── Contact Info ─────────────────────────────────
                        DetailCard(title: "Thông tin liên hệ") {
                            DetailRow(icon: "bubble.left.fill",  label: "Zalo / Facebook",  value: c.contact)
                        }

                        // ── Transaction Info ─────────────────────────────
                        DetailCard(title: "Thông tin giao dịch") {
                            DetailRow(icon: "person.text.rectangle.fill", label: "Tài khoản", value: c.purchaseAccount)
                            RowDivider()
                            PasswordDetailRow(password: c.password)
                            RowDivider()
                            DetailRow(icon: "calendar",    label: "Thời hạn đến",
                                      value: c.expirationDate.formatted(date: .long, time: .omitted))
                            RowDivider()
                            DetailRow(icon: "clock",       label: "Ngày thêm",
                                      value: c.createdAt.formatted(date: .abbreviated, time: .shortened))
                        }

                        // ── Notes ────────────────────────────────────────
                        if !c.notes.isEmpty {
                            DetailCard(title: "Ghi chú") {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "note.text")
                                        .foregroundColor(AppTheme.accent)
                                        .frame(width: 20)
                                    Text(c.notes)
                                        .font(.body)
                                        .foregroundColor(AppTheme.textPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }

                        // ── Delete Button ────────────────────────────────
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "trash.fill")
                                Text("Xóa khách hàng này")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(AppTheme.red.opacity(0.85))
                            .cornerRadius(14)
                        }
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.bg, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Đóng") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sửa") { showEdit = true }
                        .foregroundColor(AppTheme.accent)
                        .fontWeight(.semibold)
                }
            }
        }
        .tint(AppTheme.accent)
        .sheet(isPresented: $showEdit) {
            AddEditCustomerView(editCustomer: c)
                .environmentObject(vm)
        }
        .alert("Xóa khách hàng?", isPresented: $showDeleteAlert) {
            Button("Hủy", role: .cancel) {}
            Button("Xóa", role: .destructive) {
                Task {
                    await vm.delete(c)
                    dismiss()
                }
            }
        } message: {
            let name = c.name.isEmpty ? "khách hàng này" : c.name
            Text("Bạn có chắc muốn xóa \(name)? Hành động này không thể hoàn tác.")
        }
    }

    private var expirationAgoText: String {
        let days = abs(Calendar.current.dateComponents([.day], from: c.expirationDate, to: Date()).day ?? 0)
        return days == 0 ? "Hôm nay" : "\(days) ngày trước"
    }
}

// MARK: - Supporting Views

struct DetailCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundColor(AppTheme.textMuted)
                .tracking(1)

            VStack(spacing: 10) {
                content
            }
            .padding(14)
            .background(AppTheme.card)
            .cornerRadius(14)
        }
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.accent)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                Text(value)
                    .font(.body)
                    .foregroundColor(AppTheme.textPrimary)
            }
            Spacer()
        }
    }
}

struct RowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(height: 1)
    }
}

// MARK: - Password Row (show / hide)

struct PasswordDetailRow: View {
    let password: String
    @State private var isVisible = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.fill")
                .foregroundColor(AppTheme.accent)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text("Mật khẩu")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                Text(isVisible ? password : String(repeating: "●", count: min(password.count, 10)))
                    .font(.body.monospaced())
                    .foregroundColor(AppTheme.textPrimary)
                    .animation(.easeInOut(duration: 0.2), value: isVisible)
            }
            Spacer()
            Button {
                withAnimation { isVisible.toggle() }
            } label: {
                Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(6)
                    .background(AppTheme.cardAlt)
                    .cornerRadius(6)
            }
        }
    }
}
