import Foundation
import SwiftUI

// MARK: - Customer Status

enum CustomerStatus: String, Codable, CaseIterable {
    case active, expiringSoon, expired

    var label: String {
        switch self {
        case .active:       "Còn hạn"
        case .expiringSoon: "Sắp hết hạn"
        case .expired:      "Hết hạn"
        }
    }

    var icon: String {
        switch self {
        case .active:       "checkmark.circle.fill"
        case .expiringSoon: "exclamationmark.circle.fill"
        case .expired:      "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .active:       AppTheme.green
        case .expiringSoon: AppTheme.orange
        case .expired:      AppTheme.red
        }
    }
}

// MARK: - Customer Model

struct Customer: Identifiable, Codable {
    var id: UUID             = UUID()
    var name: String         = ""
    var contact: String      = ""   // Zalo/FB   – Bắt buộc
    var purchaseAccount: String = "" // Tài khoản – Bắt buộc
    var password: String     = ""   // Mật khẩu  – Bắt buộc
    var expirationDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    var notes: String        = ""
    var createdAt: Date      = Date()

    // MARK: Computed

    var status: CustomerStatus {
        let now = Date()
        guard expirationDate > now else { return .expired }
        let soon = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        return expirationDate <= soon ? .expiringSoon : .active
    }

    var daysRemaining: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0)
    }

    var initials: String {
        let parts = name.split(separator: " ")
        guard !parts.isEmpty else { return "?" }
        let first = String(parts.first!.prefix(1))
        let last  = parts.count > 1 ? String(parts.last!.prefix(1)) : ""
        return (first + last).uppercased()
    }
}
