import Foundation

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidURL
    case httpError(Int)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:       return "URL không hợp lệ"
        case .httpError(let c): return "Lỗi server HTTP \(c)"
        case .noData:           return "Không có dữ liệu trả về"
        }
    }
}

// MARK: - Customer Service (Cloudflare KV via Worker API)

struct CustomerService {
    private let base: String

    // Shared date strategies
    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    init(workerURL: String = Config.workerURL) {
        self.base = workerURL.hasSuffix("/") ? String(workerURL.dropLast()) : workerURL
    }

    // ── FETCH ALL ─────────────────────────────────────────────
    func fetchAll() async throws -> [Customer] {
        let url = try url(path: "/customers")
        let (data, resp) = try await URLSession.shared.data(from: url)
        try validate(resp)
        return try CustomerService.decoder.decode([Customer].self, from: data)
    }

    // ── CREATE ────────────────────────────────────────────────
    func create(_ customer: Customer) async throws -> Customer {
        let url = try url(path: "/customers")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try CustomerService.encoder.encode(customer)
        let (data, resp) = try await URLSession.shared.data(for: req)
        try validate(resp)
        return try CustomerService.decoder.decode(Customer.self, from: data)
    }

    // ── UPDATE ────────────────────────────────────────────────
    func update(_ customer: Customer) async throws -> Customer {
        let url = try url(path: "/customers/\(customer.id.uuidString)")
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try CustomerService.encoder.encode(customer)
        let (data, resp) = try await URLSession.shared.data(for: req)
        try validate(resp)
        return try CustomerService.decoder.decode(Customer.self, from: data)
    }

    // ── DELETE ────────────────────────────────────────────────
    func delete(id: UUID) async throws {
        let url = try url(path: "/customers/\(id.uuidString)")
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        let (_, resp) = try await URLSession.shared.data(for: req)
        try validate(resp)
    }

    // ── Helpers ───────────────────────────────────────────────
    private func url(path: String) throws -> URL {
        guard let url = URL(string: base + path) else { throw APIError.invalidURL }
        return url
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { throw APIError.noData }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpError(http.statusCode) }
    }
}
