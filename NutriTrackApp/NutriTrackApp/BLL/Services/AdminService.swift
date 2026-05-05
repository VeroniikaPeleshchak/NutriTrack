import Foundation

class AdminService {
    static let shared = AdminService()
    private init() {}
    
    // MARK: - 1. ЗАПИТИ КОРИСТУВАЧІВ
    func getPendingRequests() async throws -> [ProductDTO] {
        return try await AdminRepository.shared.getPendingProducts()
    }
    
    func approveRequest(productId: Int) async throws {
        try await AdminRepository.shared.approveProduct(id: productId)
    }
    
    func rejectRequest(productId: Int) async throws {
        try await AdminRepository.shared.rejectProduct(id: productId)
    }
    
    // MARK: - 2. ЗАГАЛЬНА БАЗА ПРОДУКТІВ
    func getAllProducts() async throws -> [ProductDTO] {
        return try await AdminRepository.shared.getAllProducts()
    }
    
    func addProduct(product: ProductDTO) async throws {
        _ = try await AdminRepository.shared.addProduct(product)
    }
    
    func editProduct(product: ProductDTO) async throws {
        _ = try await AdminRepository.shared.updateProduct(product)
    }
    
    func deleteProduct(productId: Int) async throws {
        try await AdminRepository.shared.deleteProduct(id: productId)
    }

    // MARK: - СТАТИСТИКА
    func getDashboardStats() async throws -> AdminStatsDTO {
        return try await AdminRepository.shared.getDashboardStats()
    }
}
