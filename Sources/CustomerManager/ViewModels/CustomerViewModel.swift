import Foundation
import Combine

@MainActor
class CustomerViewModel: ObservableObject {
    @Published var customers:      [Customer]      = []
    @Published var searchText:     String          = ""
    @Published var selectedFilter: CustomerStatus? = nil
    @Published var isLoading:      Bool            = false
    @Published var errorMessage:   String?         = nil

    private let service  = CustomerService()
    private let cacheKey = "customers_cache_v2"

    // MARK: - Filtered list

    var filteredCustomers: [Customer] {
        customers
            .filter { c in
                guard !searchText.isEmpty else { return true }
                return c.name.localizedCaseInsensitiveContains(searchText)
                    || c.contact.localizedCaseInsensitiveContains(searchText)
                    || c.purchaseAccount.localizedCaseInsensitiveContains(searchText)
            }
            .filter { c in
                guard let f = selectedFilter else { return true }
                return c.status == f
            }
            .sorted { $0.expirationDate < $1.expirationDate }
    }

    // MARK: - Stats

    var totalCount:        Int { customers.count }
    var activeCount:       Int { customers.filter { $0.status == .active       }.count }
    var expiringSoonCount: Int { customers.filter { $0.status == .expiringSoon }.count }
    var expiredCount:      Int { customers.filter { $0.status == .expired      }.count }

    // MARK: - Init (load cache → view shows instantly, API syncs in background)

    init() {
        loadCache()
    }

    // MARK: - API operations

    /// Load fresh data from Cloudflare KV
    func reload() async {
        isLoading = true
        defer { isLoading = false }
        do {
            customers = try await service.fetchAll()
            saveCache()
        } catch {
            // Keep showing cached data; surface error
            errorMessage = "⚠️ Không thể tải dữ liệu: \(error.localizedDescription)"
        }
    }

    /// Add a new customer
    func add(_ customer: Customer) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let created = try await service.create(customer)
            customers.append(created)
            saveCache()
        } catch {
            errorMessage = "Thêm thất bại: \(error.localizedDescription)"
        }
    }

    /// Update an existing customer
    func update(_ customer: Customer) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let updated = try await service.update(customer)
            if let i = customers.firstIndex(where: { $0.id == updated.id }) {
                customers[i] = updated
                saveCache()
            }
        } catch {
            errorMessage = "Cập nhật thất bại: \(error.localizedDescription)"
        }
    }

    /// Delete a customer
    func delete(_ customer: Customer) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await service.delete(id: customer.id)
            customers.removeAll { $0.id == customer.id }
            saveCache()
        } catch {
            errorMessage = "Xóa thất bại: \(error.localizedDescription)"
        }
    }

    func clearError() { errorMessage = nil }

    // MARK: - Local cache (UserDefaults fallback)

    private func saveCache() {
        if let data = try? CustomerService.encoder.encode(customers) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }

    private func loadCache() {
        guard
            let data    = UserDefaults.standard.data(forKey: cacheKey),
            let decoded = try? CustomerService.decoder.decode([Customer].self, from: data)
        else { return }
        customers = decoded
    }
}
