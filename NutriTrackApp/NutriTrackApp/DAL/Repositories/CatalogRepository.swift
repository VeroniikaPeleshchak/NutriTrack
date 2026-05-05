import Foundation

class CatalogRepository {
    static let shared = CatalogRepository()
    private init() {}
    
    // MARK: - 1. Отримання всіх продуктів
    func getProducts() async throws -> [ProductDTO] {
        let userId = AuthManager.shared.currentUserId ?? 0
        return try await NetworkManager.shared.fetchData(from: "/api/products?userId=\(userId)")    }
    
    // MARK: - 2. Пошук за назвою
    func searchProducts(query: String) async throws -> [ProductDTO] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }
        let userId = AuthManager.shared.currentUserId ?? 0
        return try await NetworkManager.shared.fetchData(from: "/api/products?search=\(encodedQuery)&userId=\(userId)")    }
    
    // MARK: - 3. Пошук за штрихкодом
    func getProductByBarcode(_ barcode: String) async throws -> ProductDTO? {
        return try await NetworkManager.shared.fetchSingle(from: "/api/products/barcode/\(barcode)")
    }
    
    // MARK: - 4. Створення власної страви
    func saveCustomProduct(_ product: ProductDTO) async throws -> ProductDTO {
        if SyncService.shared.isOnline {
            return try await NetworkManager.shared.sendData(to: "/api/products", method: "POST", data: product)
        } else {
            SyncService.shared.queueOfflineRequest(endpoint: "/api/products", method: "POST", dto: product)
            return product
        }
    }
    
    // MARK: - 5. Оновлення власної страви
    func updateCustomProduct(_ product: ProductDTO) async throws -> ProductDTO {
        guard let id = product.id else { throw NetworkManager.NetworkError.invalidURL }
        
        if SyncService.shared.isOnline {
            return try await NetworkManager.shared.sendData(to: "/api/products/\(id)", method: "PUT", data: product)
        } else {
            SyncService.shared.queueOfflineRequest(endpoint: "/api/products/\(id)", method: "PUT", dto: product)
            return product
        }
    }
    
    func deleteProduct(id: Int) async throws {
        let userId = AuthManager.shared.currentUserId ?? 0
        let endpoint = "/api/products/\(id)?userId=\(userId)"
        
        if SyncService.shared.isOnline {
            try await NetworkManager.shared.sendRequest(to: endpoint, method: "DELETE")
        } else {
            SyncService.shared.queueOfflineRequest(endpoint: endpoint, method: "DELETE")
        }
    }
}
