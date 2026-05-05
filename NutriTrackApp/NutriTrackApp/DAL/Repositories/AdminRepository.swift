import Foundation

class AdminRepository {
    static let shared = AdminRepository()
    private init() {}
    
    // MARK: - 1. Статистика дашборду
    func getDashboardStats() async throws -> AdminStatsDTO {
        return try await NetworkManager.shared.fetchSingle(from: "/api/admin/stats")
    }
    
    // MARK: - 2. Модерація запитів
    func getPendingProducts() async throws -> [ProductDTO] {
        return try await NetworkManager.shared.fetchData(from: "/api/admin/products/pending")
    }
    
    func approveProduct(id: Int) async throws {
        try await NetworkManager.shared.sendRequest(to: "/api/admin/products/\(id)/approve", method: "PATCH")
    }
    
    func rejectProduct(id: Int) async throws {
        try await NetworkManager.shared.sendRequest(to: "/api/admin/products/\(id)/reject", method: "PATCH")
    }
    
    // MARK: - 3. Керування глобальною базою
    func getAllProducts() async throws -> [ProductDTO] {
        return try await NetworkManager.shared.fetchData(from: "/api/products")
    }
    
    func addProduct(_ product: ProductDTO) async throws -> ProductDTO {
        return try await NetworkManager.shared.sendData(to: "/api/products", method: "POST", data: product)
    }
    
    func updateProduct(_ product: ProductDTO) async throws -> ProductDTO {
        guard let id = product.id else { throw NetworkManager.NetworkError.invalidURL }
        return try await NetworkManager.shared.sendData(to: "/api/admin/products/\(id)", method: "PUT", data: product)
    }
    
    func deleteProduct(id: Int) async throws {
        try await NetworkManager.shared.sendRequest(to: "/api/admin/products/\(id)", method: "DELETE")
    }
}
