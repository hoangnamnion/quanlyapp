import SwiftUI

// MARK: - Main List View

struct CustomerListView: View {
    @EnvironmentObject var vm: CustomerViewModel
    @State private var showAdd      = false
    @State private var selectedCustomer: Customer?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Stats row
                    StatsRowView()
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                        .padding(.bottom, 14)

                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppTheme.textSecondary)
                        TextField("Tìm tên, zalo, tài khoản...", text: $vm.searchText)
                            .foregroundColor(AppTheme.textPrimary)
                            .tint(AppTheme.accent)
                        if !vm.searchText.isEmpty {
                            Button { vm.searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppTheme.textMuted)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppTheme.card)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)

                    // Filter chips
                    FilterChipsView()
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)

                    // Customer list or empty state
                    if vm.filteredCustomers.isEmpty {
                        EmptyCustomerView()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(vm.filteredCustomers) { customer in
                                    CustomerCardView(customer: customer)
                                        .onTapGesture { selectedCustomer = customer }
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                Task { await vm.delete(customer) }
                                            } label: {
                                                Label("Xóa", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 100)
                        }
                    }
            }
            // ── Loading overlay ──────────────────────────────────
            if vm.isLoading {
                Color.black.opacity(0.12).ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(AppTheme.accent)
                    .scaleEffect(1.4)
            }
        }
        .navigationTitle("Khách Hàng")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(AppTheme.bg, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppTheme.accentGradient)
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button { Task { await vm.reload() } } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(AppTheme.accent)
                }
                .disabled(vm.isLoading)
            }
        }
        }
        .tint(AppTheme.accent)
        // ── Load from API when view appears ─────────────────────
        .task { await vm.reload() }
        // ── Error alert ──────────────────────────────────────────
        .alert("Thông báo", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.clearError() } }
        )) {
            Button("OK") { vm.clearError() }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .sheet(isPresented: $showAdd) {
            AddEditCustomerView()
                .environmentObject(vm)
        }
        .sheet(item: $selectedCustomer) { customer in
            CustomerDetailView(customer: customer)
                .environmentObject(vm)
        }
    }
}

// MARK: - Stats Row

struct StatsRowView: View {
    @EnvironmentObject var vm: CustomerViewModel

    var body: some View {
        HStack(spacing: 8) {
            StatCard(label: "Tổng",     value: vm.totalCount,        color: AppTheme.accent)
            StatCard(label: "Còn hạn",  value: vm.activeCount,       color: AppTheme.green)
            StatCard(label: "Sắp hết",  value: vm.expiringSoonCount, color: AppTheme.orange)
            StatCard(label: "Hết hạn",  value: vm.expiredCount,      color: AppTheme.red)
        }
    }
}

struct StatCard: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppTheme.card)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Filter Chips

struct FilterChipsView: View {
    @EnvironmentObject var vm: CustomerViewModel

    struct Chip {
        let label: String
        let color: Color
        let filter: CustomerStatus?
    }

    private let chips: [Chip] = [
        Chip(label: "Tất cả",      color: AppTheme.accent, filter: nil),
        Chip(label: "Còn hạn",     color: AppTheme.green,  filter: .active),
        Chip(label: "Sắp hết hạn", color: AppTheme.orange, filter: .expiringSoon),
        Chip(label: "Hết hạn",     color: AppTheme.red,    filter: .expired),
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(chips, id: \.label) { chip in
                    let selected = vm.selectedFilter == chip.filter
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            vm.selectedFilter = selected ? nil : chip.filter
                        }
                    } label: {
                        Text(chip.label)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(selected ? .black : AppTheme.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(selected ? chip.color : AppTheme.card)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(selected ? chip.color : Color.white.opacity(0.08), lineWidth: 1)
                            )
                    }
                    .animation(.easeInOut(duration: 0.2), value: selected)
                }
            }
        }
    }
}

// MARK: - Customer Card

struct CustomerCardView: View {
    let customer: Customer

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(alignment: .top) {
                // Avatar circle
                ZStack {
                    Circle()
                        .fill(AppTheme.accentGradient)
                        .frame(width: 42, height: 42)
                    Text(customer.initials)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(customer.name.isEmpty ? "(Chưa có tên)" : customer.name)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)
                    Text(customer.contact)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                // Status badge
                HStack(spacing: 4) {
                    Image(systemName: customer.status.icon)
                        .font(.caption2)
                    Text(customer.status.label)
                        .font(.caption.bold())
                }
                .foregroundColor(customer.status.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(customer.status.color.opacity(0.13))
                .cornerRadius(8)
            }

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 1)

            // Bottom info
            HStack {
                Label(customer.purchaseAccount, systemImage: "cart.fill")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)

                Spacer()

                Label(daysText, systemImage: "calendar")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(customer.status.color)
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(customer.status.color.opacity(0.18), lineWidth: 1)
        )
    }

    private var daysText: String {
        switch customer.status {
        case .expired:       return "Đã hết hạn"
        case .expiringSoon:  return customer.daysRemaining == 0 ? "Hết hạn hôm nay" : "Còn \(customer.daysRemaining) ngày"
        case .active:        return "Còn \(customer.daysRemaining) ngày"
        }
    }
}

// MARK: - Empty State

struct EmptyCustomerView: View {
    @EnvironmentObject var vm: CustomerViewModel

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "person.3.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AppTheme.accentGradient)
            }

            VStack(spacing: 6) {
                Text(vm.searchText.isEmpty ? "Chưa có khách hàng" : "Không tìm thấy kết quả")
                    .font(.title3.bold())
                    .foregroundColor(AppTheme.textPrimary)
                Text(vm.searchText.isEmpty ? "Nhấn + để thêm khách hàng đầu tiên" : "Thử tìm với từ khóa khác")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}
